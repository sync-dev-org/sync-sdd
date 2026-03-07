# SDD Framework Self-Review Report
**Date**: 2026-03-01 | **Agents**: 4 dispatched, 4 completed

## False Positives Eliminated

| Finding | Agent | Reason |
|---|---|---|
| CLAUDE.md Commands カウント不一致 (6 vs 7) | Agent 4 | CLAUDE.md は意図的にユーザー向け 6 コマンドのみ掲載。sdd-review-self はフレームワーク内部ツールとして正しく除外。ただしこの分析から README の sdd-reboot 欠落を派生指摘として追加 |

## CRITICAL (0)

(該当なし)

## HIGH (1)

### H1: README.md Commands テーブルに `/sdd-reboot` が未掲載
**Location**: README.md:144-151
**Description**: v1.5.0 で追加された `/sdd-reboot` コマンドが README の Commands テーブルに掲載されていない。CLAUDE.md には正しく掲載済み。公開ドキュメントの欠落。
**Evidence**: README には 6 コマンド掲載 (sdd-review-self を含む、sdd-reboot なし)。CLAUDE.md には 6 コマンド掲載 (sdd-reboot を含む、sdd-review-self なし)。README は公開リポなので sdd-reboot + sdd-review-self の 7 コマンドを掲載すべき。
**Source**: Agent 4 指摘から派生 (FP 分析で実態を特定)

## MEDIUM (6)

### M1: Revise モード — Cross-Cutting 移行後のフェーズ前提が未定義
**Location**: refs/revise.md Part A Step 6(d) → Part B Step 2
**Description**: Part A Step 6(d) 経由の Cross-Cutting 合流時、対象 spec の phase がすでに `design-generated` に遷移済みだが、Part B Step 2 の `implementation-complete` 条件との関係が未定義。
**Source**: Agent 1

### M2: Design Lookahead の stale マーク永続化が未定義
**Location**: refs/run.md Step 4 § Design Lookahead
**Description**: Staleness guard の「invalidate lookahead design, mark for re-design」の stale マークが spec.yaml に永続化手段を持たない。セッション再開後にstale 設計が使用されるリスク。
**Source**: Agent 1

### M3: Consensus モード — Archive 実行主体の二重記述
**Location**: SKILL.md § Consensus Mode Step 7 / refs/review.md Step 9
**Description**: `active-{p}/` → `B{seq}/pipeline-{p}/` のアーカイブ処理が Router と review.md の両方に記述され、実行主体が不明瞭。
**Source**: Agent 1

### M4: Analyst `Capabilities found` フィールドのラベル陳腐化
**Location**: framework/claude/agents/sdd-analyst.md:177
**Description**: v1.5.1 で Analyst Step 2 が「Capability Inventory」→「Domain & Requirements Discovery」に変更されたが、Completion Report の `Capabilities found: {count}` フィールドラベルが旧来のまま。`Requirements identified` に更新すべき。
**Source**: Agent 2

### M5: Session Resume の verdicts.md 読み取り範囲が不完全
**Location**: CLAUDE.md:276 (Session Resume Step 2a)
**Description**: `specs/*/reviews/verdicts.md` のみ読み取り、wave-level (`project/reviews/wave/`) や dead-code review 状態が復元されない。spec.yaml が ground truth のため実用影響は限定的。
**Source**: Agent 3

### M6: crud.md Delete Mode での .cross-cutting ディレクトリ未対応
**Location**: refs/crud.md Delete Mode
**Description**: Delete Mode が `specs/.cross-cutting/{id}/` の削除を明示していない。残留アーティファクトの可能性。
**Source**: Agent 3

## LOW (8)

### L1: Release Skill Step 3.1 と 3.2a の CHANGELOG.md スコープ重複
**Location**: framework/claude/skills/sdd-release/SKILL.md:81,85-99
**Description**: Step 3.1 で CHANGELOG を処理し、3.2a でも変更ベースレビューを行うためスコープが重複しうる。3.2a は明示的に README.md を対象としているため実質問題は軽微。
**Source**: Agent 2

### L2: Reboot Phase 4 で `Files to delete` フィールドの使用指示が不在
**Location**: refs/reboot.md Phase 4
**Description**: ANALYST_COMPLETE に `Files to delete: {count}` が追加されたが Phase 4 での使用/無視の指示なし (Phase 9 で analysis-report 参照するため機能的影響なし)。
**Source**: Agent 2

### L3: `over-mocking` カテゴリの CPF ルール未登録
**Location**: framework/claude/agents/sdd-inspector-test.md:213
**Description**: TDD 古典派で追加された `over-mocking` カテゴリが cpf-format.md に正式登録されていない。
**Source**: Agent 2

### L4: Verdict Persistence — Wave QG ヘッダー形式が SKILL.md テンプレートに未反映
**Location**: refs/run.md Step 7a/7b vs SKILL.md § Verdict Persistence
**Description**: 共通テンプレートは `[B{seq}]` 形式のみ。Wave QG の `[W{N}-B{seq}]` 形式が散在。
**Source**: Agent 1

### L5: Cross-Cutting verdicts.md Verdict Persistence が SKILL.md 未参照
**Location**: refs/revise.md Part B Step 8
**Description**: cross-cutting scope の verdict destination が review.md には記載あるが SKILL.md テンプレートには未反映。
**Source**: Agent 1

### L6: revise.md Part B Auto-Fix 上限の明示なし
**Location**: refs/revise.md Part B Step 7
**Description**: run.md Phase Handlers 参照で暗黙適用されるが、revise.md 内での明示がない。
**Source**: Agent 1

### L7: Dead-code Inspector SCOPE の `{feature}` が到達不能
**Location**: Dead-code Inspector agents
**Description**: `review dead-code` は feature 名を取らない設計であり、SCOPE の `{feature}` パターンは実質未使用。
**Source**: Agent 3

### L8: Task→Agent ツールリネーム（後方互換あり）
**Location**: framework/claude/CLAUDE.md:5,32, settings.json:14-39, 各 refs
**Description**: Claude Code v2.1.63 で Task ツールが Agent にリネーム済み。既存の Task(...) 参照はエイリアスとして動作するため機能的問題なし。将来メジャーバージョンで移行検討。
**Source**: Agent 4

## Platform Compliance

| Item | Status |
|---|---|
| Agent YAML frontmatter (26/26) | PASS (cached) |
| Skill YAML frontmatter (6/7) | PASS (cached) |
| sdd-release/SKILL.md frontmatter | PASS (full review) |
| Task dispatch patterns | PASS (cached) |
| SubAgent non-nesting constraint | PASS (cached) |
| settings.json entries | PASS (cached) |
| Tool availability | PASS (cached) |

## Overall Assessment

全体的なフレームワーク整合性は高水準。CRITICAL 問題なし。

**今回の変更 (sdd-release Step 3) に起因する新規指摘**: M4 (Analyst ラベル陳腐化は今回の変更ではなく既存問題)、L1 (CHANGELOG スコープ重複) のみ。L1 は実質的に問題なし (3.2a は README を対象と明示)。

**H1 (sdd-reboot の README 欠落)** は今回の Step 3.2 コンテンツレビュー機能が検出すべき典型例であり、改善の有効性を裏付ける。

**pre-existing backlog**: M1-M3, M5-M6, L2-L8 は過去バッチからの既知項目。

## Recommended Fix Priority

| Priority | ID | Summary | Target Files |
|---|---|---|---|
| 1 | H1 | README に sdd-reboot 追加 | README.md |
| 2 | M4 | Analyst Capabilities found → Requirements identified | sdd-analyst.md |
| 3 | L1 | Step 3.2a スコープ明確化 (README 限定を強調) | sdd-release/SKILL.md |
| — | M1-M3,M5-M6 | Pre-existing backlog | refs/revise.md, run.md, review.md, CLAUDE.md, crud.md |
| — | L2-L8 | Pre-existing backlog | Various |
