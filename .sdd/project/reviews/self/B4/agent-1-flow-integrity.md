# Flow Integrity Review Report

## Issues Found

### [MEDIUM] M1: CLAUDE.md Artifact Ownership - revise コマンドが Single-Spec のみ記載

**Location**: `framework/claude/CLAUDE.md:64`
**Description**: Artifact Ownership セクションで「completed specs」に対する変更ルートが `/sdd-roadmap revise {feature}` のみ記載されている。Cross-Cutting revise mode (`/sdd-roadmap revise [instructions]`) への言及がない。複数 spec にまたがる変更をユーザーが要求した場合、Lead は Single-Spec revise に誘導してしまい、Cross-Cutting mode の存在を見落とす可能性がある。

**推奨修正**: CLAUDE.md L64 付近に `- Use `/sdd-roadmap revise` (without feature name) for cross-cutting changes across multiple specs` を追加。

---

### [MEDIUM] M2: Architect エージェント定義に cross-cutting brief の言及なし

**Location**: `framework/claude/agents/sdd-architect.md`
**Description**: refs/design.md (L29) と refs/revise.md Part B Step 7 では「cross-cutting brief path を Architect prompt に含める」と規定しているが、Architect エージェント定義自体には brief の存在・読み方・利用方法について一切記載がない。Architect の Input セクションには Feature name, Mode, User-instructions のみ列挙されている。

brief path が prompt に含まれた場合、Architect は brief.md を Read して参照するよう自律的に動作する「べき」だが、エージェント定義に明示されていないため動作が不安定になるリスクがある。

**推奨修正**: sdd-architect.md の Input セクションに `- **Cross-cutting brief**: path to shared context brief (optional, for cross-cutting revisions)` を追加し、Step 1 の Load Context に brief.md の読み込みステップを追加。

---

### [LOW] L1: sdd-review-self SKILL.md の Agent 1 プロンプトに criteria #9 が欠如

**Location**: `framework/claude/skills/sdd-review-self/SKILL.md` (Agent 1: Flow Integrity)
**Description**: 本レビュータスクのプロンプトには criteria #9 "New revise modes" が含まれているが、これは動的注入された $CHANGE_CONTEXT ベースの指示であり、sdd-review-self SKILL.md のテンプレート本体には criteria #8 までしか定義されていない。今後の self-review 実行時に Cross-Cutting revise mode のフロー整合性がレビュー対象から漏れる。

**推奨修正**: sdd-review-self SKILL.md Agent 1 の Review Criteria に `9. Revise modes: Single-Spec and Cross-Cutting modes in refs/revise.md route correctly from SKILL.md Detect Mode` を追加。

---

### [LOW] L2: sdd-status に cross-cutting revision の状態表示サポートなし

**Location**: `framework/claude/skills/sdd-status/SKILL.md`
**Description**: `specs/.cross-cutting/{id}/` ディレクトリに保存される cross-cutting brief と verdicts が sdd-status の表示対象に含まれていない。Cross-cutting revision が進行中または完了後に `/sdd-status` を実行しても、その状態が表示されない。

これは機能欠落というよりは将来の改善項目。revise.md Post-Completion で `/sdd-status` の実行を推奨している (L253) ことを考えると、status 側でも表示できることが望ましい。

**推奨修正**: sdd-status SKILL.md に cross-cutting revision の状態表示を追加するか、少なくとも `specs/.cross-cutting/` の存在を検知して通知する。

---

### [LOW] L3: Cross-Cutting Mode の counter reset が暗黙的

**Location**: `framework/claude/CLAUDE.md:173`, `framework/claude/skills/sdd-roadmap/refs/revise.md` Part B Step 7
**Description**: CLAUDE.md の counter reset triggers に `/sdd-roadmap revise` start が含まれている。これは Single-Spec Mode (Part A Step 4) では明示的に `Reset orchestration.retry_count = 0, spec_update_count = 0` と書かれている。Cross-Cutting Mode (Part B Step 7) でも各 tier の State Transition で同様に reset が記載されているため整合性はある。

ただし、CLAUDE.md の counter reset trigger 記載が `/sdd-roadmap revise` start とだけ書かれており、Cross-Cutting mode の場合は tier ごとに reset が発生する点が暗黙的。tier 間で counter が引き継がれるかどうかの誤解を招く可能性がある。

**影響度**: 低。refs/revise.md Step 7 で明示されているため、実運用上の問題は小さい。

---

## Confirmed OK

### 1. Router dispatch completeness (全サブコマンドのルーティング)

**PASS**: SKILL.md Detect Mode で全サブコマンドが正しくルーティングされている。

| Subcommand | Router 行き先 | ref ファイル | 確認状態 |
|---|---|---|---|
| `design {feature}` | Design Subcommand | refs/design.md | OK |
| `impl {feature} [tasks]` | Impl Subcommand | refs/impl.md | OK |
| `review design\|impl\|dead-code` | Review Subcommand | refs/review.md | OK |
| `review --consensus N` | Review Subcommand | refs/review.md | OK |
| `review --cross-check` | Review Subcommand | refs/review.md | OK |
| `review --wave N` | Review Subcommand | refs/review.md | OK |
| `run [--gate] [--consensus N]` | Run Mode | refs/run.md | OK |
| `revise {feature} [instructions]` | Revise Mode (Single-Spec) | refs/revise.md Part A | OK |
| `revise [instructions]` | Revise Mode (Cross-Cutting) | refs/revise.md Part B | OK |
| `create [-y]` | Create Mode | refs/crud.md | OK |
| `update` | Update Mode | refs/crud.md | OK |
| `delete` | Delete Mode | refs/crud.md | OK |
| `-y` | Auto-detect | SKILL.md 内 | OK |
| `""` (empty) | Auto-detect | SKILL.md 内 | OK |

Execution Reference セクション (L96-105) で ref ファイルの読み込みタイミングが明示されている。Revise は refs/revise.md が内部で Mode Detection を行う。

### 2. Phase gate consistency

**PASS**: 各 ref の Phase Gate が CLAUDE.md の Phase-Driven Workflow 定義と整合している。

| Phase | Design | Impl | Review Design | Review Impl | Revise |
|---|---|---|---|---|---|
| `initialized` | OK (proceed) | BLOCK | N/A | N/A | BLOCK |
| `design-generated` | OK (re-edit) | OK (proceed) | OK | BLOCK | BLOCK |
| `implementation-complete` | Warn+confirm | OK (re-run) | N/A | OK | OK (proceed) |
| `blocked` | BLOCK | BLOCK | BLOCK | BLOCK | BLOCK |

- CLAUDE.md 定義フェーズ: `initialized` -> `design-generated` -> `implementation-complete` (+ `blocked`)
- refs/design.md: `blocked` で BLOCK、`implementation-complete` で warn+confirm (revise 推奨)、unknown phase で BLOCK。
- refs/impl.md: `blocked` で BLOCK、`design-generated` で proceed、`implementation-complete` で re-execution 可能、other で BLOCK。
- refs/review.md: design review は `design-generated` + design.md 存在チェック、impl review は `implementation-complete` チェック。
- refs/revise.md Part A: `implementation-complete` のみ proceed。Part B: `implementation-complete` のみ eligible。

### 3. Auto-fix loop (NO-GO / SPEC-UPDATE-NEEDED)

**PASS**: CLAUDE.md と refs 間の auto-fix ループ定義が整合している。

| 項目 | CLAUDE.md | refs/run.md | 整合性 |
|---|---|---|---|
| retry_count max | 5 (NO-GO) | 5 (Phase Handlers, Wave QG) | OK |
| spec_update_count max | 2 (SPEC-UPDATE-NEEDED) | 2 (Phase Handlers) | OK |
| aggregate cap | 6 | run.md で暗黙的 (5+2 > 6 → escalate) | OK |
| dead-code NO-GO max | 3 | 3 (Step 7b) | OK |
| CONDITIONAL = GO | Yes | Yes (counters NOT reset) | OK |
| Counter NOT reset on GO/CONDITIONAL | Yes | Yes (明示) | OK |

refs/revise.md Part A Step 5: "Handle verdict per CLAUDE.md counter limits" — 正しく CLAUDE.md に委任。
refs/revise.md Part B Step 7: "Auto-fix loop applies per spec (standard counter limits)" — 正しく CLAUDE.md に委任。
refs/revise.md Part B Step 8: "Max 5 retries (aggregate cap 6)" — CLAUDE.md と整合。

### 4. Wave Quality Gate

**PASS**: refs/run.md Step 7 の Wave QG フローが完全。

- Step 7a: Impl Cross-Check Review (wave-scoped) → verdict persistence to project/reviews/wave/verdicts.md
- Step 7b: Dead Code Review → verdict persistence to project/reviews/wave/verdicts.md
- Step 7c: Post-gate (counter reset, knowledge flush, commit)
- 1-Spec Roadmap: Skip Wave QG (SKILL.md L87-90 + run.md Step 7 L162)
- Wave completion condition: all specs `implementation-complete` or `blocked` (L164)
- Escalation on exhaustion: 3 options (proceed/abort/manual fix) (L171-174)

### 5. Consensus Mode

**PASS**: Consensus Mode の定義に矛盾なし。

- SKILL.md Shared Protocols に Consensus Mode protocol が定義 (L111-127)
- review.md L90: `--consensus N` は SKILL.md の Consensus Mode protocol を参照
- run.md L118, L134: Phase Handlers で `--consensus N` は Router 参照
- N=1 default: active/ (no `-{p}` suffix), B{seq}/ にアーカイブ (L126-127)
- threshold: ceil(N*0.6) (L113)

### 6. Verdict Persistence

**PASS**: フォーマットが全レビュータイプで一貫している。

- SKILL.md Verdict Persistence Format (L130-138): 統一フォーマット定義
- review.md Step 8: `{scope-dir}/verdicts.md` に persist
- Verdict Destination by Review Type (review.md L122-128): 5 つのパス全て `verdicts.md` パターン
- run.md Step 7: `project/reviews/wave/verdicts.md` に persist (header format: `[W{wave}-B{seq}]`, `[W{wave}-DC-B{seq}]`)
- revise.md Part B Step 8: `specs/.cross-cutting/{id}/verdicts.md` に persist
- Archive: `active/` -> `B{seq}/` (review.md L88-89)
- CPF format: 全 Auditor が同一の CPF 形式で出力

### 7. Edge Cases

**PASS**: 主要エッジケースがカバーされている。

| Edge Case | 処理場所 | 処理内容 |
|---|---|---|
| Empty roadmap | SKILL.md L73-82 | lifecycle subcommand → auto-create; dead-code/cross-check → BLOCK |
| 1-spec roadmap | SKILL.md L84-90 | Skip Wave QG, cross-check, dead-code; commit format `{feature}: {summary}` |
| Blocked spec | CLAUDE.md L72-73, design.md L17, impl.md L10, revise.md L29 | BLOCK with message |
| Retry limit exhaustion | run.md L171-174 (cross-check), L182 (dead-code), CLAUDE.md L170-171 | Escalate to user |
| Aggregate cap (6) | CLAUDE.md L170, run.md L130 | Total cycles check |
| Inspector failure | review.md L118, L79 | Retry/skip/proceed with available results |
| Architect failure | design.md L32-33 | Do NOT update spec.yaml, escalate |
| Builder blocked | impl.md L56 | Classify cause, reorder/escalate |
| DAG cycle | run.md L10 | BLOCK with cycle path |

### 8. Read clarity (ref 読み込みタイミング)

**PASS**: SKILL.md L96-105 の Execution Reference セクションで明示。

```
After mode detection and roadmap ensure, Read the reference file for the detected mode:
- Design → Read refs/design.md
- Impl → Read refs/impl.md
...
Then follow the instructions in the loaded file.
```

各 ref ファイルが「Assumes Single-Spec Roadmap Ensure already completed by router」(design.md L3, impl.md L3, review.md L3) と前提を明記。

### 9. New revise modes (Single-Spec + Cross-Cutting)

**PASS**: SKILL.md Detect Mode から refs/revise.md への dispatch は正しく機能する。

- SKILL.md L34: `"revise {feature} [instructions]"` -> Revise Mode (Single-Spec)
- SKILL.md L35: `"revise [instructions]"` -> Revise Mode (Cross-Cutting)
- refs/revise.md Mode Detection: feature name の有無で Part A / Part B に分岐
- Escalation: Part A Step 3 → 2+ affected specs → Part B Step 2 へ join
- Part A Step 6 option (d) → Part B Step 2 へ join
- argument-hint: `revise [feature] [instructions]` (optional feature) — 正しい

Cross-Cutting Mode の内部フロー:
- Step 1-3: Intent collection, Impact Analysis, Restructuring Check
- Step 4: Cross-Cutting Design Brief (specs/.cross-cutting/{id}/brief.md)
- Step 5: AUDIT triage
- Step 6: Tier planning (topological sort)
- Step 7: Tier execution (refs/design.md + refs/review.md + refs/impl.md 参照)
- Step 8: Cross-Cutting Consistency Review
- Step 9: Post-Completion (commit format: `cross-cutting: {summary}`)

refs/design.md L29 に cross-cutting brief path サポートが追加済み。
CLAUDE.md に Cross-Cutting Parallelism, cross-cutting commit format, REVISION_INITIATED cross-cutting 注記が追加済み。

---

## Inspector/Auditor Agent 数の整合性確認

### Design Review (6 Inspectors + 1 Auditor)

| CLAUDE.md 記載 | review.md 記載 | Agent ファイル | 一致 |
|---|---|---|---|
| "6 design" (L26) | 6 design Inspectors (L25) | rulebase, testability, architecture, consistency, best-practices, holistic | OK (6個) |
| - | Design Auditor: sdd-auditor-design (L26) | sdd-auditor-design.md | OK |

### Impl Review (6+2 Inspectors + 1 Auditor)

| CLAUDE.md 記載 | review.md 記載 | Agent ファイル | 一致 |
|---|---|---|---|
| "6 impl +2 web" (L26) | 6 standard + 2 web (L33-34) | impl-rulebase, interface, test, quality, impl-consistency, impl-holistic | OK (6個) |
| "+2 web" | sdd-inspector-e2e, sdd-inspector-visual (L34) | sdd-inspector-e2e.md, sdd-inspector-visual.md | OK (2個) |
| - | Impl Auditor: sdd-auditor-impl (L35) | sdd-auditor-impl.md | OK |

sdd-auditor-impl.md: "up to 8 independent review agents" (L12) — 6 standard + 2 web = 8 max. OK.

### Dead-Code Review (4 Inspectors + 1 Auditor)

| CLAUDE.md 記載 | review.md 記載 | Agent ファイル | 一致 |
|---|---|---|---|
| "4 dead-code" (L26) | 4 dead-code Inspectors (L44) | dead-settings, dead-code, dead-specs, dead-tests | OK (4個) |
| - | Dead-code Auditor: sdd-auditor-dead-code (L45) | sdd-auditor-dead-code.md | OK |

### 全 Agent 合計: 24個

Inspectors: 6 (design) + 6 (impl) + 2 (web) + 4 (dead-code) = 18
Auditors: 3 (design, impl, dead-code)
Others: architect, builder, taskgenerator = 3
Total: 24 OK (ls コマンドの結果と一致)

---

## Overall Assessment

sdd-roadmap Router から各 ref への dispatch フローは全体的に堅牢で整合性が高い。新たに追加された Cross-Cutting revise mode は refs/revise.md 内で適切に構造化されており、Mode Detection、Escalation パス、SKILL.md Detect Mode との接続が正しく設計されている。

**主要リスク**:
- Architect エージェント定義に cross-cutting brief のサポートが明示されていない (M2) — Architect が brief.md を読まない場合、cross-cutting revision の品質が低下する可能性がある。
- CLAUDE.md の Artifact Ownership セクションが Single-Spec revise のみを案内している (M1) — ユーザーガイダンスの不足。

**アーキテクチャ品質**: 高。refs 分離による関心の分離が徹底されており、各ファイルの責務が明確。Tier-based execution model は run.md の Dispatch Loop パターンを適切に再利用している。

**未変更エリアの整合性**: 既存の run.md, impl.md, review.md, crud.md, design.md のフローに破壊的変更はなく、今回の差分は追加的変更のみ。CLAUDE.md の `See sdd-roadmap refs/run.md Step 3-4` が Cross-Cutting Parallelism の記述に置き換えられたが、refs/run.md への他の参照 (L82, L174) が残っているため情報ロスはない。ただし Parallel Execution Model セクションから dispatch loop details への直接リンクが失われた点は minor。
