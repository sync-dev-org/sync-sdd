# SDD Framework Self-Review Report
**Date**: 2026-03-05T01:39:29+0900 | **Engine**: codex [gpt-5.3-codex], auditor:claude-sonnet-4-6 | **Pipeline**: agent
**Agents**: 4 dispatched, 4 completed

## False Positives Eliminated

| Finding | Agent | Reason |
|---|---|---|
| M\|protocol-consistency\|CLAUDE.md:316 — Bash cat/sed 禁止と sdd-review-self SKILL.md:90/:282 の競合 | Agent-3 | D117 USER_DECISION: "sdd-review-self-ext テンプレート化 + sed 解禁" — sed は settings.json で auto-approved の意図的例外。STEERING_EXCEPTION として許容済み |

## A) 自明な修正 (5件) — OK で全件修正します

| ID | Sev | Location | Summary | Fix |
|---|---|---|---|---|
| A-1 | HIGH | framework/claude/skills/sdd-roadmap/SKILL.md:70 | `review impl --cross-check` と `review design --wave N` が単一Spec enrollment例外から漏れている | 例外リストに `review impl --cross-check` と `review design --wave N` を追加 |
| A-2 | HIGH | framework/claude/skills/sdd-roadmap/SKILL.md:72 | roadmap未作成時のBLOCK条件にも同モードが漏れており、通常enrollment分岐へ誤流入しうる | BLOCK例外リストに同2モードを追加 |
| A-3 | MEDIUM | install.sh:349 | 移行メッセージが `tasks.md` 再生成を案内しているが、現行実装の正とするファイルは `tasks.yaml` | `tasks.md` → `tasks.yaml` に修正 |
| A-4 | LOW | framework/claude/skills/sdd-roadmap/refs/revise.md:27 | Part A Step 1 で `phase=implementation-complete` 必須を先に要求した後、同Stepで `blocked` を別途BLOCKしており条件が冗長 | 重複している `blocked` チェックを削除または統合 |
| A-5 | LOW | framework/claude/skills/sdd-steering/SKILL.md:82 | `tech.md/structure.md` が単一パス表記で記述されており、実体の2ファイル参照として曖昧 | `tech.md` と `structure.md` の2ファイルを明示する表記に修正 |

## B) ユーザー判断が必要 (3件)

### B-1: sdd-review-self Inspector dispatch が $ENGINE_NAME 基準のまま
**Location**: framework/claude/skills/sdd-review-self/SKILL.md:142
**Description**: per-stage engine override (`inspectors.engine` 個別設定) を導入しているが、Inspector の dispatch 判定ロジックが依然 `$ENGINE_NAME` 変数による大域判定になっている。個別 Inspector に異なるエンジンを設定した場合、SubAgent/外部CLI の選択とフォールバック条件が正しく動作しない。
**Impact**: per-stage engine override (D128で確定済み機能) の恩恵が Inspector に伝わらない。複数エンジン混在構成で誤ルーティングが発生する。HEIGHTの問題だが、現時点の engines.yaml デフォルトは Inspector を単一エンジン (codex) に統一しているため顕在化しにくい。
**Recommendation**: Inspector dispatch ループを `$ENGINE_NAME` ではなく per-inspector エンジン設定を参照する形に修正する — ただし設計変更を伴うため、まず該当コード (SKILL.md:142付近) を精査してから修正範囲を確定することを推奨

### B-2: run.md の orphan spec (roadmap有・spec.yaml無) を静かに無視
**Location**: framework/claude/skills/sdd-roadmap/refs/run.md:7
**Description**: Run Step 1 で `roadmap.md` と全 `spec.yaml` を読むが、roadmap に登録されているのに `spec.yaml` が存在しないエントリ (orphan) を明示的に検出・停止しない。空roadmap以外の欠損ケースで実行対象が静かにスキップされ、パイプラインが不完全なまま進行する余地がある。
**Impact**: orphan エントリが存在するとログ・エラーなしでスキップされるため、ユーザーが実行漏れに気づきにくい。ただし orphan は基本的に不正状態 (spec.yaml 手動削除等) に限られ、正常運用では発生しにくい。
**Recommendation**: (1) orphan 検出を追加してWARN出力 + ユーザー確認を求める、または (2) 現状維持 (「不正状態は運用ルール側で防止」) — いずれも合理的。影響範囲が限定的なため defer も可

### B-3: multiview-grid.sh の再利用判定がスロット完全性を検証していない
**Location**: framework/claude/sdd/settings/scripts/multiview-grid.sh:14
**Description**: 既存グリッドの再利用判定が `pane COUNT == 12` の件数のみで行われており、スロット 1..12 の完全性（重複タイトル・欠番・空 pane_id）を検証していない。不整合な状態のグリッドを再利用した場合、後続 dispatch が空 pane_id を受け取って失敗する余地がある。
**Impact**: グリッド作成が途中で失敗・強制終了した場合に発生しうる。正常な12-pane グリッドなら問題なし。multiview-grid.sh は D115でのみ設計変更済み。D122でテンプレート化が完了しており、grid.sh の冪等性はD132で対処済みのため、この細部は残存バグの可能性がある。
**Recommendation**: 件数チェックに加えてタイトル一致検証 (全12スロットのタイトルが期待値通りか) を追加する — または「pane数が12なら正常とみなす」運用ルールを明示してWON'T FIXとする

## Platform Compliance

| Item | Status | Source |
|---|---|---|
| agent-frontmatter-fields | OK | https://docs.anthropic.com/en/docs/claude-code/sub-agents |
| agent-model-values | OK | https://docs.anthropic.com/en/docs/claude-code/sub-agents |
| agent-tool-dispatch-patterns | OK | https://docs.anthropic.com/en/docs/claude-code/sub-agents |
| agent-tool-parameters-subagent_type | OK | https://docs.anthropic.com/en/docs/claude-code/sub-agents |
| settings-permission-format | OK | https://docs.anthropic.com/en/docs/claude-code/settings#permissions |
| settings-agent-skill-entry-match | OK | https://docs.anthropic.com/en/docs/claude-code/settings#permissions |
| tool-availability-names | OK | https://docs.anthropic.com/en/docs/claude-code/settings#tools-available-to-claude |
| skills-frontmatter-description | OK | https://docs.anthropic.com/en/docs/claude-code/skills |
| skills-frontmatter-allowed-tools | OK | https://docs.anthropic.com/en/docs/claude-code/skills |
| skills-frontmatter-argument-hint | OK | https://docs.anthropic.com/en/docs/claude-code/skills |
| skills-frontmatter-optional-fields | OK | https://docs.anthropic.com/en/docs/claude-code/skills |
