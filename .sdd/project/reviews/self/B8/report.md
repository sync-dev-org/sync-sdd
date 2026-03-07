# SDD Framework Self-Review Report
**Date**: 2026-02-24 | **Version**: v1.2.3 | **Agents**: 4 dispatched, 4 completed

## False Positives Eliminated

| Finding | Agent | Reason |
|---|---|---|
| Commands(5) に sdd-review-self 未記載 | Agent 3 | D2: framework-internal 用途として意図的にテーブル外 |
| .claude/settings.json に Skill(sdd-knowledge) 残存 | Agent 2 | install先であり framework ソースではない。`--force` で解消 |
| general-purpose subagent_type に settings.json エントリなし | Agent 3 | platform built-in type。settings.json は custom agents (.claude/agents/) のみ |

## CRITICAL (0)

(なし)

## HIGH (3)

### H1: refs/impl.md Step 4 ステップ番号欠落
**Location**: framework/claude/skills/sdd-roadmap/refs/impl.md:72-73
**Description**: Post-pipeline ステップ番号が `1. Auto-draft` → `3. Report to user` とスキップしており、`2.` が欠落。Lead が手順を順次実行する際に混乱する可能性。
**Agent**: Agent 1 (Flow Integrity)

### H2: revise.md Part B — Design Review での SPEC-UPDATE-NEEDED ハンドリング未記載
**Location**: framework/claude/skills/sdd-roadmap/refs/revise.md:218-221
**Description**: Cross-Cutting Revision の Tier 実行内で Design Review が SPEC-UPDATE-NEEDED を返した場合の処理が明記されていない。refs/run.md では "not expected for design review. If received, escalate immediately." と記載されているが、revise.md の Tier 実行には未反映。
**Agent**: Agent 1 (Flow Integrity)

### H3: revise.md Part B — verdict 保存先パス不明確
**Location**: framework/claude/skills/sdd-roadmap/refs/revise.md:241-243
**Description**: Cross-Cutting Review 後の verdict 保存先が `specs/.cross-cutting/{id}/verdicts.md` であることが Step 8 で明示されていない。Lead が `wave/verdicts.md` に誤って書く可能性。
**Agent**: Agent 1 (Flow Integrity)

## MEDIUM (9)

### M1: SKILL.md Detect Mode — feature名有無の境界条件
**Location**: framework/claude/skills/sdd-roadmap/SKILL.md:34-35
**Description**: `revise [instructions]` (feature名なし) が Cross-Cutting にルーティングされるが、instructions 内に feature 名に似た文字列が含まれる場合の誤検出リスクが曖昧。
**Agent**: Agent 1 (Flow Integrity)

### M2: Dead-Code Review max 3 exception — run.md 未反映
**Location**: framework/claude/CLAUDE.md:169 / framework/claude/skills/sdd-roadmap/refs/run.md:182
**Description**: Dead-Code Review の retry 上限 max 3 が CLAUDE.md のみに記述。run.md:182 にも max 3 はあるが「aggregate cap 6 から除外される Exception」という点が run.md に未反映。
**Agent**: Agent 1 + Agent 3

### M3: review.md Consensus — B{seq} 決定の曖昧さ
**Location**: framework/claude/skills/sdd-roadmap/refs/review.md:90
**Description**: Step 2 の B{seq} 決定が単一パス前提。Consensus 時 (`active-{p}/`) との切り替えが review ref 内で完結しておらず、Router を先読みしないと誤ディレクトリ作成のリスクあり。
**Agent**: Agent 1 (Flow Integrity)

### M4: revise.md Part A — version increment の参照
**Location**: framework/claude/skills/sdd-roadmap/refs/revise.md:71-74
**Description**: spec.yaml version インクリメントが "Execute per refs/design.md" の参照に隠れており、revise フロー上で追跡が困難。
**Agent**: Agent 1 (Flow Integrity)

### M5: revise.md Part A Step 6 — downstream reset の暗示性
**Location**: framework/claude/skills/sdd-roadmap/refs/revise.md:91
**Description**: option (b) "Re-implement" でダウンストリーム spec の `phase = design-generated` / `last_phase_action = null` リセット手順が暗示的にしか読めない。
**Agent**: Agent 1 (Flow Integrity)

### M6: README.md スキル数 7→6 未更新
**Location**: README.md:53
**Description**: `# 7 skills` と記載されているが、sdd-knowledge 削除後の実際のスキル数は 6。
**Agent**: Agent 2 (Change-Focused)

### M7: run.md Impl Review NO-GO — aggregate cap 記述不完全
**Location**: framework/claude/skills/sdd-roadmap/refs/run.md:128
**Description**: Impl Review NO-GO 処理に `(max 5 retries)` とあるが aggregate cap の明示がない。Design Review (l.113) は両方明記しており非対称。l.130 に別行で記載はあるが一貫性に欠ける。
**Agent**: Agent 3 (Consistency)

### M8: Wave QG Cross-Check — retry_count スコープ不明確
**Location**: framework/claude/skills/sdd-roadmap/refs/run.md:170-175
**Description**: Cross-Check NO-GO 時の `retry_count` インクリメントが「どの spec のカウント」かが曖昧。aggregate cap 6 が spec 単位か wave 単位かの説明が不足。
**Agent**: Agent 3 (Consistency)

### M9: sdd-inspector-impl-holistic — Cross-Check Mode 実装ファイル読み込み欠如
**Location**: framework/claude/agents/sdd-inspector-impl-holistic.md:83-84
**Description**: Cross-Check Mode で実装ファイルの明示的読み込み指示がない。他の実装系 Inspector (quality 等) は Cross-Check でも実装ファイルを読むが、holistic だけ非対称。
**Agent**: Agent 3 (Consistency)

## LOW (7)

### L1: run.md Readiness Rules — Impl Review 条件不明示
**Location**: framework/claude/skills/sdd-roadmap/refs/run.md:87
**Description**: Readiness Rules テーブルの Impl Review 条件に `implementation-complete` phase が明示されていない。
**Agent**: Agent 1

### L2: review.md — Cross-cutting {id} 決定方法参照なし
**Location**: framework/claude/skills/sdd-roadmap/refs/review.md:128
**Description**: Cross-cutting review パスの `{id}` 決定方法が review.md 内に説明されていない。refs/revise.md を読まないと不明。
**Agent**: Agent 1

### L3: crud.md — reviews/ パス未定義
**Location**: framework/claude/skills/sdd-roadmap/refs/crud.md:81
**Description**: Delete Mode の削除対象 `{{SDD_DIR}}/project/reviews/` が CLAUDE.md Paths セクションに未定義。
**Agent**: Agent 1

### L4: install.sh — v0.18.0 migration コメント不整合
**Location**: install.sh:362-371
**Description**: v0.18.0 migration コメント "Migrated agents/ → sdd/settings/agents/" が v0.20.0 で逆方向に戻す処理と合わせて保守上の混乱要因。機能的には問題なし。
**Agent**: Agent 3 (downgraded from HIGH)

### L5: sdd-inspector-best-practices — Research Depth と tools 非対称
**Location**: framework/claude/agents/sdd-inspector-best-practices.md
**Description**: `WebSearch`/`WebFetch` を tools に宣言していないが "Research Depth (Autonomous)" セクションが存在。動作上の問題はないが設計文言が不明瞭。
**Agent**: Agent 4

### L6: sdd-handover — argument-hint 空値
**Location**: framework/claude/skills/sdd-handover/SKILL.md:4
**Description**: `argument-hint:` フィールドが空文字列。引数不要のスキルはフィールド省略推奨。
**Agent**: Agent 4

### L7: Task tool model パラメータ (unverified)
**Location**: framework/claude/skills/sdd-review-self/SKILL.md:58
**Description**: Agent 4 が `model="sonnet"` パラメータの既知バグ (GitHub #18873) を報告。ただし Task tool のスキーマに `model` は正式に定義されており、ソース未検証。sdd-review-self のみ影響。
**Agent**: Agent 4 (unverified — 要手動確認)

## Platform Compliance

| Item | Status |
|---|---|
| Agent YAML frontmatter (24個) | PASS |
| Agent model 有効値 (sonnet/opus) | PASS |
| Agent に Task tool 非含有 | PASS |
| Skills frontmatter 形式 (6個) | PASS |
| settings.json Skill()/Task() とファイル整合性 | PASS |
| dispatch subagent_type と実在エージェント一致 | PASS |
| run_in_background=true 一貫使用 | PASS |
| Task tool model パラメータ | WARN (unverified bug report) |
| sdd-inspector-best-practices tools 宣言 | WARN (文言が不明瞭) |
| sdd-handover argument-hint 空値 | WARN (スタイル) |

## Overall Assessment

v1.2.3 のフレームワーク品質は概ね良好。CRITICAL はゼロ。主な改善点は refs/revise.md Part B (Cross-Cutting) のプロトコル明確化。sdd-knowledge 廃止は完全に実行されており、ダングリング参照なし。

## Recommended Fix Priority

| Priority | ID | Summary | Target Files |
|---|---|---|---|
| 1 | H1 | impl.md ステップ番号修正 | refs/impl.md |
| 2 | H2 | revise Part B SPEC-UPDATE-NEEDED handling | refs/revise.md |
| 3 | H3 | revise Part B verdict path 明示化 | refs/revise.md |
| 4 | M6 | README.md スキル数修正 | README.md |
| 5 | M2+M7 | run.md auto-fix counter 記述統一 | refs/run.md |
| 6 | M8 | Cross-Check retry scope 明確化 | refs/run.md |
| 7 | M9 | impl-holistic Cross-Check Mode 修正 | agents/sdd-inspector-impl-holistic.md |
| 8 | M1,M3-M5 | revise/review 明確化 (低リスク) | refs/revise.md, refs/review.md |
| - | L1-L7 | Low priority items | (various) |
