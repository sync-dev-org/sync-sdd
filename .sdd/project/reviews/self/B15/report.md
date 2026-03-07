# SDD Framework Self-Review Consolidated Report
**Date**: 2026-02-28 | **Batch**: B15 | **Agents**: 4/4 completed

## Summary
C:0 H:3 M:10 L:4 | FP:3 eliminated | Dedup: 1 merged

---

## False Positives Eliminated (3)

| Finding | Agent | Reason |
|---|---|---|
| settings.json に Task(general-purpose) 未登録 | Agent 3 | `general-purpose` は Claude Code 組み込み subagent_type。skill の `allowed-tools: Task` が許可。実動作確認済み |
| Consensus B{seq} 排他制御未定義 | Agent 1 | Lead はシングルスレッドで verdicts.md を更新。SubAgent は CPF ファイルを書くのみ。排他制御不要 |
| Commands(6) vs skills数(7) 不整合 | Agent 3 | sdd-review-self は内部用ツール。公開コマンド6件は設計意図通り |

## Dedup (1)

| Finding | Agents | Action |
|---|---|---|
| Dead-code counter セッション再開 CLAUDE.md 記述不明確 | Agent 1 + Agent 3 | マージ → M2 |

---

## HIGH (3)

### H1: revise.md Part B Tier Execution — NO-GO フロー参照欠如
**Location**: `refs/revise.md:229,243`
**Agent**: 1 (Flow Integrity)
**Description**: Cross-Cutting Revise の Tier Execution (Step 7) で Design Review NO-GO 時の具体的フロー（Architect 再 dispatch、retry_count increment）への参照がない。「Handle verdicts per CLAUDE.md counter limits」のみで refs/run.md Phase Handlers への参照が欠如。
**Evidence**: run.md Phase Handlers には NO-GO 時の具体的手順があるが、revise.md から参照されていない。

### H2: revise.md Part B — phase 先設定の競合リスク
**Location**: `refs/revise.md:63-65`
**Agent**: 1 (Flow Integrity)
**Description**: Tier Execution Step 1 で `phase = design-generated` を先設定する構造が、Dispatch Loop の Readiness Rule（`phase is design-generated` → Design Review eligible）と競合状態を生む可能性。Architect がまだ実行中でも Design Review が eligible と判定されうる。

### H3: Inspector-Test Section C "isolate" が Classical school と矛盾 ★今回の変更に起因
**Location**: `sdd-inspector-test.md:117`
**Agent**: 2 (Change-Focused)
**Description**: Section C の「Do unit tests properly isolate the unit under test?」は、新たに追加した Classical/Detroit school の原則（内部依存は real instance を使う）と意味的に矛盾。Inspector がこの基準で判定すると、classical school 準拠テストを「隔離不十分」と誤フラグするリスクがある。

---

## MEDIUM (10)

### M1: SKILL.md revise 引数パースの誤判定リスク
**Location**: `SKILL.md(sdd-roadmap):34-35`
**Agent**: 1
**Description**: revise 引数の最初の単語がスペック名と一致 → Single-Spec と判定。自然言語指示の先頭が偶然スペック名と一致した場合の誤判定フォールバック未定義。

### M2: Dead-code counter のセッション再開動作 — CLAUDE.md 記述不明確
**Location**: `CLAUDE.md:177`, `refs/run.md:248`
**Agent**: 1 + 3 (merged)
**Description**: run.md では「in-memory counter, restarts at 0 on session resume」と記述されているが、CLAUDE.md の Counter Reset Triggers からはこの挙動が読み取りにくい。

### M3: Standalone review の PROPOSE STEERING — ブロッキング定義曖昧
**Location**: `refs/review.md:105-117`
**Agent**: 1
**Description**: Pipeline 外の standalone review 実行時に「Blocks pipeline」の意味が未定義。

### M4: sdd-reboot SKILL.md — Iterate 後動作未記載
**Location**: `sdd-reboot/SKILL.md:36-42`
**Agent**: 1
**Description**: Error Handling テーブルに Iterate 選択後の動作が記載されていない（refs/reboot.md Phase 9 には記述あり）。

### M5: conventions-brief.md — mock 境界フィールド欠如 ★今回の変更に関連
**Location**: `conventions-brief.md:27-29`
**Agent**: 2
**Description**: Testing Patterns セクションにモック境界（external only vs internal mock）の観察フィールドがない。Scanner が既存の over-mocking パターンを brief に記録し、Builder がそれを慣例として踏襲するリスク。

### M6: design.md テンプレート — Unit テスト定義なし ★今回の変更に関連
**Location**: `design.md:275`
**Agent**: 2
**Description**: Testing Strategy セクションに Unit テスト定義（real collaborators vs mocked dependencies）の言及がなく、testing.md を採用していないプロジェクトでは Architect の Unit テスト解釈がドリフトしうる。

### M7: Dead Code Inspector CPF SCOPE — wave-scoped 表記なし
**Location**: `sdd-inspector-dead-{code,settings,tests,specs}.md`
**Agent**: 3
**Description**: Dead Code Inspector の Output Format に wave-scoped モードの SCOPE 表記がない（設計上正しいが明示コメントなし）。

### M8: sdd-auditor-dead-code — SCOPE フィールド欠如
**Location**: `sdd-auditor-dead-code.md:145-155`
**Agent**: 3
**Description**: 他の Auditor (design, impl) の出力には SCOPE フィールドがあるが、dead-code Auditor にはない。

### M9: E2E/Visual Inspector — playwright-cli NOTES 文字列不一致
**Location**: `sdd-inspector-e2e.md:116`, `sdd-inspector-visual.md:103`
**Agent**: 3
**Description**: E2E は `SKIPPED|playwright-cli install failed`、Visual は `SKIPPED|playwright-cli unavailable`。文字列ベースパース時に結果が異なる。

### M10: BUILDER_BLOCKED — builder-report Grep スキップ未明示
**Location**: `refs/impl.md:76`
**Agent**: 3
**Description**: Tags > 0 で builder-report を Grep する処理で、BLOCKED 時のスキップ指示がない。

---

## LOW (4)

### L1: refs/design.md — abort 時の USER_DECISION 記録欠如
**Location**: `refs/design.md:18`
**Agent**: 1
**Description**: `implementation-complete` からの設計却下（abort）時に decisions.md への記録指示がない。

### L2: refs/run.md — SPEC-UPDATE-NEEDED カスケード後の cross-check タイミング不明
**Location**: `refs/run.md:241`
**Agent**: 1

### L3: CPF カテゴリ名不統一 ★今回の変更に起因
**Location**: `sdd-inspector-test.md:131 vs :214`
**Agent**: 2
**Description**: 本文 Flag: "Implementation-coupled test" vs CPF 例: `impl-coupled-test`。他フラグはすべて一致だがこの1つだけ異なる。

### L4: $FOCUS_TARGETS 変数展開責任未明示
**Location**: `sdd-review-self/SKILL.md`
**Agent**: 3

---

## Platform Compliance (Agent 4)

| Item | Status |
|---|---|
| sdd-builder.md frontmatter | PASS (full verification) |
| sdd-inspector-test.md frontmatter | PASS (full verification) |
| 他23エージェント定義 | OK (cached from B14) |
| 7スキル定義 | OK (cached from B14) |
| settings.json permissions | OK (cached from B14) |
| Task dispatch patterns | OK (cached from B14) |
| SubAgent non-nesting | OK (cached from B14) |

---

## Overall Assessment

今回の TDD 改善変更（Builder, Inspector-Test, Testing Standards テンプレート）に直接起因する指摘は **H3, M5, M6, L3** の4件。H3（Inspector Section C の "isolate" 矛盾）は即時修正推奨。M5/M6 は波及的な改善で、次回リリースに含めれば十分。

Pre-existing findings (H1, H2, M1-M4, M7-M10, L1-L2, L4) は前回 B14 以前からの既存課題。

## Recommended Fix Priority

| Priority | ID | Summary | Target Files |
|---|---|---|---|
| 1 (即時) | H3 | Section C "isolate" 表現を Classical school と整合 | sdd-inspector-test.md |
| 2 (即時) | L3 | CPF カテゴリ名統一 | sdd-inspector-test.md |
| 3 (推奨) | M5 | conventions-brief.md に mock boundary field 追加 | conventions-brief.md |
| 4 (推奨) | M6 | design.md テンプレートに Unit テスト定義追加 | design.md |
| 5 (次回) | H1 | revise.md Part B NO-GO 参照追加 | refs/revise.md |
| 6 (次回) | H2 | revise.md Part B phase 競合解消 | refs/revise.md |
| 7 (次回) | M2 | CLAUDE.md dead-code counter 記述明確化 | CLAUDE.md |
| 8 (backlog) | M1,M3,M4,M7-M10,L1,L2,L4 | Pre-existing edge cases | 各ファイル |
