# SDD Framework Self-Review Report (External Engine)
**Date**: 2026-03-04T01:15:23+0900 | **Engine**: codex [default] | **Agents**: 4 dispatched, 4 completed

## False Positives Eliminated

| Finding | Agent | Reason |
|---|---|---|
| run.md ↔ review.md circular-ref | A3 | 意図的な分離設計。オーケストレーション vs レビュー詳細 |
| argument-hint format UNCERTAIN | A4 | Skills YAML frontmatter の有効なフィールド。書式は自由形式 |
| TaskOutput UNCERTAIN | A4 | Claude Code の正式ツール（システムプロンプトに定義済み） |

## CRITICAL (0)

## HIGH (5)

### H1: SID 命名規則違反 — sdd-review-self-ext pane title
**Location**: framework/claude/skills/sdd-review-self-ext/SKILL.md:166
**Description**: `sdd-ext-{SID}-{N}` は tmux-integration.md の正式命名規則 `sdd-{SID}-{purpose}-{identifier}` に従っていない。Orphan Cleanup の SID 抽出パターンが self-ext pane を認識できず、孤児検出・cleanup が破綻する。
**Agents**: A2
**Fix**: `sdd-ext-{SID}-{N}` → `sdd-{SID}-ext-{N}`

### H2: Cross-Cutting review verdict 永続化パス二重定義
**Location**: framework/claude/skills/sdd-roadmap/refs/review.md:84
**Description**: Cross-Cutting review の scope-dir が `specs/.cross-cutting/{id}/reviews/` で verdict 保存先が `specs/.cross-cutting/{id}/verdicts.md` と別階層。revise.md も後者を前提にしており、review 実行結果の読取先が分岐する。
**Agents**: A1, A3 (merged)
**Status**: Pre-existing (D96 で部分対処済み)

### H3: Cross-Cutting review が wave mode と整合しない
**Location**: framework/claude/skills/sdd-roadmap/refs/revise.md:255
**Description**: Cross-Cutting consistency review が wave-scoped cross-check impl review と同じ仕組みを使う定義だが、wave mode は累積全コードを対象とし Cross-Cutting の対象 spec のみの再検査要件と整合しない。
**Agents**: A1
**Status**: Pre-existing

### H4: Blocked spec が残る wave での QG 定義破綻
**Location**: framework/claude/skills/sdd-roadmap/refs/run.md:239
**Description**: Wave completion 条件が `implementation-complete` or `blocked` を許容するが、直後の Impl Cross-Check は実装済み spec 群を前提にしているため、blocked spec が残る edge case で QG 対象が破綻する。
**Agents**: A1
**Status**: Pre-existing

### H5: Builder の tasks.yaml セクション名不一致
**Location**: framework/claude/agents/sdd-builder.md:31
**Description**: Builder は `execution_plan` セクションを読む前提だが、TaskGenerator 規約は `execution` セクションのみ定義。
**Agents**: A3
**Status**: Needs verification

## MEDIUM (4)

### M1: Web Inspector pane title が SID 命名に未対応
**Location**: framework/claude/skills/sdd-roadmap/refs/review.md:61
**Description**: Web Inspector Server Protocol の pane title が `sdd-devserver-{feature}` 固定で、新しい `sdd-{SID}-{purpose}-{identifier}` 命名に従っていない。
**Agents**: A1

### M2: publish-setup Python: uv 専用手順
**Location**: framework/claude/skills/sdd-publish-setup/SKILL.md:205
**Description**: Step 4 が `[dependency-groups] dev` + `uv sync` を常に要求し、poetry/pip 系で到達不能。
**Agents**: A3
**Status**: Pre-existing

### M3: publish-setup TypeScript: 認証方式二重化
**Location**: framework/claude/skills/sdd-publish-setup/SKILL.md:49
**Description**: OIDC provenance を説明しつつ NPM_TOKEN secret を必須にしており矛盾。
**Agents**: A3
**Status**: Pre-existing

### M4: settings.json に date コマンド許可なし
**Location**: framework/claude/settings.json:43
**Description**: CLAUDE.md は全タイムスタンプを `date` コマンドで取得することを必須化しているが、settings.json の Bash allowlist に `date` がない。
**Agents**: A3

## LOW (2)

### L1: consensus 付き review モードの Usage 不足
**Location**: framework/claude/skills/sdd-roadmap/refs/review.md:16
**Description**: `--consensus N` 付きの review モード入口が Usage に列挙されていない。
**Agents**: A1
**Status**: Pre-existing

### L2: SID example がランダム hex のまま
**Location**: framework/claude/sdd/settings/rules/tmux-integration.md:71
**Description**: One-Shot Command の例 `sdd-a3f7b2c1-ext-1` が、SID を pane ID 数値と定義した説明と矛盾。
**Agents**: A2

## Platform Compliance

| Item | Status | Source |
|---|---|---|
| agent-frontmatter (name, desc, model) | OK (cached) | B3 |
| skill-frontmatter (description) | OK (cached) | B3 |
| argument-hint format | OK | FP: valid free-form field |
| TaskOutput | OK | FP: system prompt tool |
| dispatch (Agent subagent_type, run_in_background) | Needs re-verify (CLAUDE.md changed) | — |
| settings-permission-format | Needs re-verify (settings.json changed) | — |
| settings-skill-agent-parity | Needs re-verify (settings.json changed) | — |

## Overall Assessment

今回のセッション変更（SID 導入、tiled レイアウト）に直接起因する findings は **H1, M1, L2** の 3 件。いずれも命名規則の統一漏れ。H2-H4 は pre-existing backlog。

## Recommended Fix Priority

| Priority | ID | Summary | Target Files |
|---|---|---|---|
| 1 | H1 | SID 命名規則統一 | sdd-review-self-ext/SKILL.md |
| 2 | L2 | SID example 修正 | tmux-integration.md |
| 3 | M1 | Web Inspector pane title SID 対応 | refs/review.md |
| 4 | M4 | settings.json に date 許可追加 | settings.json |
| 5 | H5 | Builder execution_plan 要検証 | sdd-builder.md |
| defer | H2-H4 | Pre-existing backlog | review.md, revise.md, run.md |
| defer | M2-M3 | publish-setup pre-existing | sdd-publish-setup/SKILL.md |
| defer | L1 | Usage 補完 | review.md |
