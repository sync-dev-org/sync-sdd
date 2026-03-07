# Flow Integrity Report

## 全体概要

sdd-roadmap Router から refs への dispatch フローを全モードにわたり検証した。未コミットの変更（Parallel Execution Model 追加、Foundation-First wave scheduling、Parallel Dispatch Loop、Island Spec Detection、Backfill check）に重点を置いて確認。

---

## Issues Found

### [CRITICAL] C1: run.md Dispatch Loop に未定義フェーズ名 `design-reviewed` と `impl-done` を使用

**Location**: `framework/claude/skills/sdd-roadmap/refs/run.md:65`

**Description**: Step 4 Parallel Dispatch Loop の Dispatch Loop 疑似コード内で、フェーズ遷移を以下のように記述している:

```
design-reviewed→Impl, impl-done→Impl Review
```

しかし CLAUDE.md (line 153) は正式なフェーズを以下の 4 つのみ定義している:

```
Phases: `initialized` → `design-generated` → `implementation-complete` (also: `blocked`)
```

`design-reviewed` と `impl-done` はフレームワーク全体のどこにも正式フェーズとして定義されていない。これらはフレームワーク内で **この 1 箇所のみ** で使用されている。

**Impact**: Lead がこの疑似コードに従って Dispatch Loop を実行する際、`design-reviewed` や `impl-done` を spec.yaml の phase フィールドに書き込もうとする可能性がある。Phase Gate (`CLAUDE.md:73`) で「Unknown phase」として BLOCK される、あるいは後続の refs (design.md, impl.md, review.md) の Phase Gate 条件と合致しなくなる。

**Recommended Fix**: 疑似コードを既存の正式フェーズとコンテキスト状態（verdict 結果等）に基づく遷移判定に修正する。例:

```
initialized→Design, design-generated (after Design Review GO/CONDITIONAL)→Impl,
implementation-complete (after all Builders complete, before Impl Review)→Impl Review
```

あるいは、Phase Handlers セクションの記述と一貫させるなら、Readiness Rules テーブルがすでに正しい条件を記述しているので、疑似コード内のフェーズ名を公式なものに統一する。

---

### [HIGH] H1: Readiness Rules の Implementation 条件 — 「Design Review verdict is GO/CONDITIONAL」の状態表現が曖昧

**Location**: `framework/claude/skills/sdd-roadmap/refs/run.md:89`

**Description**: Readiness Rules テーブルの Implementation 条件は「Design Review verdict is GO/CONDITIONAL」となっているが、この状態がどこに永続化されるかが不明確。

- spec.yaml の `phase` は Design Review 後も `design-generated` のまま（Design Review は phase を変更しない — review.md にはフェーズ更新指示がない）
- verdict 結果は `verdicts.md` に保存される
- `orchestration.last_phase_action` もこの遷移をトラッキングしない

Lead は verdict 結果を自身のコンテキストで保持しているため単一セッション内では問題ないが、**パイプライン中断・再開時** に「この spec は Design Review を通過したか」を判定する仕組みが明示されていない。

**Impact**: Pipeline Stop Protocol で中断→再開した場合、`design-generated` のままの spec が Design Review 済みかどうかを判定できず、不要な再レビューが発生するか、レビュー未実施のまま Impl に進む可能性がある。

**Recommended Fix**: 以下のいずれか:
1. `orchestration.last_phase_action` に `design-reviewed` 等の値を追加して verdict 通過状態を記録
2. `verdicts.md` の最新バッチを読むことで Design Review 通過を判定するロジックを run.md に明記
3. Pipeline Stop Protocol の Session Resume で verdicts.md を読む手順を追加（CLAUDE.md line 271 の Step 2a で部分的に対応済みだが、run.md からの明示的な参照がない）

---

### [HIGH] H2: Design Lookahead の staleness guard — 再設計後の lookahead 無効化トリガが不明確

**Location**: `framework/claude/skills/sdd-roadmap/refs/run.md:103-104`

**Description**: Design Lookahead の staleness guard は以下を規定:

> If a Wave N spec's design changes (SPEC-UPDATE-NEEDED → re-design), check if any lookahead spec depends on it. If yes: invalidate lookahead design, mark for re-design after Wave N QG

しかし:
1. SPEC-UPDATE-NEEDED は **Design Review からは発行されない**（run.md line 116: "not expected for design review. If received, escalate immediately."）。従って Wave N 内の Design 変更は SPEC-UPDATE-NEEDED ではなく **NO-GO → Architect re-dispatch** で発生する。
2. NO-GO 起因の Design 変更に対する staleness guard の適用は明示されていない。

**Impact**: Wave N の spec が Design Review NO-GO → 再設計された場合に、その spec に依存する lookahead spec の design が無効化されない可能性がある。

**Recommended Fix**: staleness guard のトリガを「Wave N spec's design changes (NO-GO → re-design by Architect)」に修正するか、NO-GO ケースも含む包括的な記述に変更する。

---

### [MEDIUM] M1: Wave QG Cross-Check Review の verdict 保存先 — `reviews/wave/` vs `reviews/cross-check/` の使い分け

**Location**: `framework/claude/skills/sdd-roadmap/refs/run.md:170` vs `framework/claude/skills/sdd-roadmap/refs/review.md:52-53,104-105`

**Description**:

- run.md Step 7a は Wave QG の Impl Cross-Check Review の verdict を `reviews/wave/verdicts.md` に保存すると規定
- review.md は `--cross-check` の scope directory を `reviews/cross-check/` と規定し、`--wave N` を `reviews/wave/` と規定
- run.md の Wave QG は「wave-scoped context」として review を実行するため、`reviews/wave/` が正しい

これ自体は整合しているが、**run.md の Wave QG Cross-Check は `--cross-check` ではなく `--wave N` 相当の review** であることが暗黙的にしか表現されていない。「Impl Cross-Check Review (wave-scoped)」という名称が `--cross-check` フラグと混同される余地がある。

**Impact**: Lead が Wave QG で `--cross-check` 相当の全スコープレビューを実行してしまうリスク（低）。

**Recommended Fix**: run.md Step 7a の記述を「wave-scoped impl review (equivalent to `review impl --wave {N}`)」と明示する。

---

### [MEDIUM] M2: Island Spec の fast-track パイプラインで Design Review/Impl Review の verdict 保存先が未規定

**Location**: `framework/claude/skills/sdd-roadmap/refs/run.md:34-40`

**Description**: Island Spec は「1-Spec Roadmap Optimizations apply」とあるが、verdict の保存先は通常の per-feature ディレクトリ (`specs/{feature}/reviews/verdicts.md`) になるはず。しかし、fast-track lane の記述はパイプライン全体の概要のみで、verdict persistence の詳細を refs/review.md に委譲している。

refs/review.md の Step 1 が scope directory を正しく判定するので **実際の動作は正しい** が、island spec 固有の明示的な記述がないため、特殊ケースの扱いが暗黙的。

**Impact**: 低い。実運用では review.md の汎用ロジックが正しく処理する。

---

### [MEDIUM] M3: Backfill Check (SKILL.md) と Backfill Optimization (crud.md Update Mode) の関係が不明確

**Location**: `framework/claude/skills/sdd-roadmap/SKILL.md:58-67` vs `framework/claude/skills/sdd-roadmap/refs/crud.md:71`

**Description**:

- Router の Single-Spec Roadmap Ensure に「Backfill check」が追加された（design subcommand で新 spec 追加時）
- crud.md Update Mode に「Backfill optimization」が追加された

両者は概念的に類似（既存 wave へ spec を統合する最適化）だが:
1. Router の Backfill check は「highest incomplete wave where adding causes no conflict」を探す
2. crud.md の Backfill optimization は「specs can be consolidated into fewer waves while respecting dependency constraints」

両者の一貫性は維持されているが、「Backfill」という同じ用語が 2 つの異なるコンテキストで使われている。Router 版は「追加」、crud.md 版は「統合」。

**Impact**: 概念的な混乱の可能性（低）。Router の backfill は新 spec の wave 配置、crud.md の backfill は既存ロードマップの最適化と、スコープが異なることが暗黙的に理解可能。

---

### [MEDIUM] M4: run.md の Impl Review completion — NO-GO 後の Builder 再 dispatch 時に `phase = implementation-complete` を再設定する記述の曖昧さ

**Location**: `framework/claude/skills/sdd-roadmap/refs/run.md:130`

**Description**:

> **NO-GO** → increment `retry_count`. Dispatch Builder(s) with fix instructions. After Builder completes: set `phase = implementation-complete`, update `implementation.files_created`. Re-run Impl Review (max 5 retries)

NO-GO 後に Builder を再 dispatch した後「set `phase = implementation-complete`」とあるが、NO-GO 受信時点で phase はすでに `implementation-complete`（impl.md Step 3 で設定済み）のはず。つまりこの記述は冗長であり、紛らわしい。

「phase が変わらない」のか「一度変更されて再設定される」のかが不明確。

**Impact**: 実害は小さい（phase は同じ値のまま）が、Lead が「NO-GO で phase が一時的に別の値になる」と誤解する可能性がある。

**Recommended Fix**: 「phase remains `implementation-complete`; update `implementation.files_created` with any file changes」のように明示する。

---

## Confirmed OK

### 1. Router Dispatch Completeness
全サブコマンドが正しい ref にルーティングされている:
- `design` → `refs/design.md`
- `impl` → `refs/impl.md`
- `review` → `refs/review.md`
- `run` → `refs/run.md`
- `revise` → `refs/revise.md`
- `create`/`update`/`delete` → `refs/crud.md`
- `-y` → auto-detect (run or create)

### 2. Phase Gate Consistency (C1 以外)
design.md, impl.md, review.md, revise.md の各 Phase Gate は CLAUDE.md 定義と一貫:
- `initialized` → design 可能
- `design-generated` → impl 可能
- `implementation-complete` → review 可能、revise 可能
- `blocked` → 全操作 BLOCK

### 3. Auto-Fix Counter Limits
CLAUDE.md と run.md で完全一致:
- `retry_count`: max 5 (NO-GO)
- `spec_update_count`: max 2 (SPEC-UPDATE-NEEDED)
- Aggregate cap: 6
- Dead-Code: max 3 retries
- CONDITIONAL = GO（カウンター非増加）
- Counter reset: wave completion, user escalation, revise start

### 4. Wave Quality Gate Flow
run.md Step 7 のフローは完全:
1. Cross-Check Review → verdict handling
2. Dead Code Review → verdict handling
3. Post-gate (counter reset, knowledge flush, commit)
1-Spec Roadmap: Step 7 skip → Post-gate 直行

### 5. Consensus Mode
Router (SKILL.md) の Consensus Mode プロトコルは review.md と矛盾なし:
- `active-{p}/` ディレクトリ命名
- N 個の Inspector + Auditor パイプライン
- Threshold ⌈N×0.6⌉
- Archive: `B{seq}/pipeline-{p}/`

### 6. Verdict Persistence Format
Router (SKILL.md) の Verdict Persistence Format は review.md の各 review type で一貫して参照。形式統一:
- `## [B{seq}] {review-type} | {timestamp} | v{version} | runs:{N} | threshold:{K}/{N}`
- Wave QG: `[W{wave}-B{seq}]`, Dead-Code: `[W{wave}-DC-B{seq}]`

### 7. Edge Cases
- **Empty roadmap**: 適切にハンドリング（lifecycle subcommand で auto-create、run/update/revise で BLOCK）
- **1-spec roadmap**: 最適化（Wave QG skip, cross-check skip, commit format）が一貫
- **Blocked spec**: Phase Gate で一貫して BLOCK
- **Retry limit exhaustion**: Blocking Protocol (Step 6) で downstream cascade → user escalation

### 8. Read Clarity
Router は明確に「After mode detection and roadmap ensure, Read the reference file for the detected mode」と指定。各 ref は「Phase execution reference. Assumes Single-Spec Roadmap Ensure already completed by router.」で前提を明示。

### 9. Parallel Execution Model 整合性 (NEW)

CLAUDE.md の新セクション「Parallel Execution Model」と run.md/crud.md の詳細実装の対応:

| CLAUDE.md 項目 | 詳細実装場所 | 整合性 |
|---|---|---|
| Wave Scheduling (Foundation-First) | crud.md Step 4 | OK |
| Design Fan-Out | run.md Step 4 Readiness Rules + Design Fan-Out | OK |
| Spec Stagger | run.md Step 4 Dispatch Loop | OK |
| Design Lookahead | run.md Step 4 Design Lookahead | OK |
| Wave Bypass | run.md Step 3 Island Spec Detection | OK |
| Builder parallelism | impl.md Step 3 | OK |
| Inspector parallelism | review.md Review Execution Flow Step 4 | OK |

### 10. Foundation-First Consistency (NEW)
CLAUDE.md は `refs/crud.md` を参照しており、crud.md Create Mode Step 4b-e に Foundation-First の詳細実装がある。run.md は wave 実行時に crud.md の scheduling 結果を使用する設計であり、run.md 自体に Foundation-First ロジックがないのは正しい（planning vs execution の分離）。

### 11. SubAgent Limit 変更
CLAUDE.md の変更:
- 旧: 「Concurrent SubAgent limit: 24」
- 新: 「No framework-imposed SubAgent limit. Platform manages concurrent execution.」

run.md / review.md にはもともと具体的な上限数への参照がなかったため、矛盾は発生していない。

---

## Overall Assessment

全体的な Router → refs dispatch フローの integrity は高い。主要な問題は **C1（未定義フェーズ名の使用）** の 1 件で、これは run.md Step 4 の新しい Dispatch Loop 疑似コードで導入された。公式フェーズ (`initialized`, `design-generated`, `implementation-complete`, `blocked`) のみ使用するよう修正が必要。

H1 と H2 は再開時の状態判定と staleness guard のエッジケースに関するもので、single-session 内では問題なく動作するが、堅牢性向上のために明示化を推奨。

新しい並列実行モデル（Design Fan-Out, Spec Stagger, Design Lookahead, Wave Bypass, Foundation-First）は CLAUDE.md と refs 間で概念的整合性が保たれている。crud.md の Foundation-First は planning フェーズ、run.md の並列ディスパッチは execution フェーズという責務分離が適切。

Backfill check（Router 側）と Backfill optimization（crud.md Update Mode）の並存は機能的に正しいが、用語の一貫性に注意が必要。
