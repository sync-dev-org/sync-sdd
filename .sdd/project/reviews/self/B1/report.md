# SDD Framework Self-Review Report

**Date**: 2026-02-24
**Mode**: full
**Agents**: 5 dispatched, 5 completed

---

## False Positives Eliminated

| Finding | Reporting Agent | Elimination Reason |
|---|---|---|
| H2: install先CLAUDE.mdに旧SubAgent上限24が残存 | Agent 3 | 開発リポ特有。framework/claude/CLAUDE.mdは正しく更新済み。install先はinstall.sh --updateで更新される対象であり、framework sourceの問題ではない |
| H4: "fast-track pipelines" vs "fast-track lane" 用語揺れ | Agent 3 | CLAUDE.mdは概要（pipelines=複数のパイプライン）、run.mdは実装詳細（lane=実行レーン）。概念レベルで一致しており、Lead誤解リスクは極めて低い |
| H4: crud.mdにIsland spec検出がない | Agent 3 | 設計意図通り。Island specはcreate時ではなくrun時に動的判定する設計（design.md未存在段階ではファイル重複が判定不能）。crud.mdのParallelism Reportに表示しなくても機能に影響なし |
| Advisory items (color, maxTurns, isolation等) | Agent 4 | 機能改善提案であり、仕様違反ではない |

---

## CRITICAL (1)

### C1: run.md Dispatch Loop疑似コードに未定義フェーズ名 `design-reviewed` / `impl-done`
**Location**: `framework/claude/skills/sdd-roadmap/refs/run.md:64-65`
**Reporting Agents**: Agent 1 (C1), Agent 2 (M1), Agent 3 (C1), Agent 5 (L)
**Description**: Dispatch Loop疑似コードが `design-reviewed→Impl, impl-done→Impl Review` と記述。CLAUDE.md定義のフェーズは `initialized`, `design-generated`, `implementation-complete`, `blocked` の4つのみ。同ファイルのReadiness Rulesテーブル・Phase Handlersは正規フェーズ名を使用しており、疑似コード内でのみ不整合。
**Evidence**: design.md Step 3は `design-generated` を設定、impl.md Step 3は `implementation-complete` を設定。`design-reviewed`/`impl-done` を設定するコードは存在しない。

---

## HIGH (2)

### H1: Design Review通過状態の永続化メカニズム未定義
**Location**: `framework/claude/skills/sdd-roadmap/refs/run.md:89`
**Reporting Agent**: Agent 1 (H1), Agent 3 (H1)
**Description**: Readiness RulesのImplementation条件は「Design Review verdict is GO/CONDITIONAL」。Design Review通過後もフェーズは `design-generated` のまま変わらない。パイプライン中断→再開時に「この specはDesign Review済みか」を判定する明示的メカニズムがない。CLAUDE.md Session Resume Step 2aでverdicts.md読込はあるが、run.mdのDispatch Loopからの参照がない。

### H2: Lookahead追跡状態がsession restart/compactで消失する
**Location**: `framework/claude/skills/sdd-roadmap/refs/run.md:101`
**Reporting Agent**: Agent 3 (H3)
**Description**: `lookahead: true` は "internal tracking, NOT in spec.yaml" と規定。spec.yamlに記録せず、session.md auto-draftにもlookahead状態の記録が言及されていない。Pipeline Stop ProtocolやSession Resumeにもlookahead復元手段がない。compact発生時にlookahead状態が失われ、再開時に復元不能。

---

## MEDIUM (3)

### M1: install.sh v0.10.0 migration内に削除済み `/sdd-impl` 参照
**Location**: `install.sh:339,341`
**Reporting Agent**: Agent 5
**Description**: v0.10.0マイグレーションブロック内のコメントに `/sdd-impl` への参照が2箇所残存。v0.22.0でsdd-implは削除済み（sdd-roadmap implに統合）。マイグレーションブロック自体はv0.10.0以前からのアップグレードパスとして機能するが、コメント内のコマンド名が古い。

### M2: Lookahead staleness guardのトリガ記述が不正確
**Location**: `framework/claude/skills/sdd-roadmap/refs/run.md:103`
**Reporting Agent**: Agent 1 (H2)
**Description**: staleness guardは「SPEC-UPDATE-NEEDED → re-design」をトリガとするが、SPEC-UPDATE-NEEDEDはDesign Reviewからは発行されない（run.md:116 "not expected, escalate immediately"）。Wave N内のDesign変更は「NO-GO → Architect re-dispatch」で発生する。トリガ記述が実際のフローと不一致。

### M3: Impl Review NO-GO後のphase設定記述が冗長
**Location**: `framework/claude/skills/sdd-roadmap/refs/run.md:130`
**Reporting Agent**: Agent 1 (M4)
**Description**: NO-GO後のBuilder再dispatch完了時に「set phase = implementation-complete」とあるが、NO-GO受信時点でphaseは既に `implementation-complete`（impl.md Step 3で設定済み）。冗長な記述がphase一時変更を示唆する誤解を招く。

---

## LOW (2)

### L1: Commands数 (6) と実際のskill数 (7) の不一致
**Location**: `framework/claude/CLAUDE.md:141`
**Reporting Agent**: Agent 3 (M4), Agent 5 (L DC-2)
**Description**: `### Commands (6)` だが sdd-review-self を含めると7個。sdd-review-selfはframework-internal用途で、ユーザー向けコマンドリストから除外する設計意図とも読めるが、明示されていない。

### L2: Backfill用語が2つのコンテキストで使用
**Location**: SKILL.md:58 vs crud.md:71
**Reporting Agent**: Agent 1 (M3)
**Description**: Router版は「新spec追加時のwave配置」、crud.md版は「既存roadmapのwave統合最適化」。機能的に正しいが、同一用語で異なるスコープの操作を指す。

---

## Claude Code Compliance Status

| Item | Status |
|---|---|
| agents/ YAML frontmatter | OK — 全23エージェント準拠 |
| Skills frontmatter | OK — 全7スキル準拠 |
| Task tool usage | OK — subagent_type正しく使用 |
| settings.json | OK — 有効キーのみ |
| install.sh paths | OK — 公式期待パス |
| Model selection | OK — opus (T2), sonnet (T3) |
| Tool permissions | OK — 最小権限原則遵守 |

---

## Overall Assessment

フレームワーク全体の品質は良好。新しい並列実行モデル（Design Fan-Out, Spec Stagger, Design Lookahead, Wave Bypass, Foundation-First）はCLAUDE.mdとrefs間で概念的整合性が保たれている。

主要リスクはC1（未定義フェーズ名）のみ。Leadがこの疑似コードを文字通り解釈してspec.yamlに無効なフェーズ値を書き込むと、Phase Gateで全操作がBLOCKされる可能性がある。

H1/H2はStagger/Lookaheadのresume耐性に関わる設計判断。単一セッション内では問題なく動作するが、長時間パイプラインの堅牢性向上には永続化メカニズムの明示が必要。

---

## Recommended Fix Priority

| Priority | ID | Summary | Target Files |
|---|---|---|---|
| 1 | C1 | 疑似コード内フェーズ名を正規名+条件表記に修正 | run.md:64-65 |
| 2 | H1 | Design Review通過判定をverdicts.md参照で明示 | run.md Readiness Rules |
| 3 | H2 | Lookahead状態のsession.md auto-draft記録を追加 | run.md, CLAUDE.md handover |
| 4 | M1 | install.sh migration コメント内の旧コマンド名更新 | install.sh:339,341 |
| 5 | M2 | staleness guardトリガを「design changes (NO-GO → re-design)」に修正 | run.md:103 |
| 6 | M3 | NO-GO後のphase記述を「phase remains implementation-complete」に修正 | run.md:130 |
