# SDD Framework Self-Review Report
**Date**: 2026-03-07T01:09:42+0900
**Agents**: 6 dispatched (3 fixed + 3 dynamic), 6 completed

## False Positives Eliminated

| Finding | Agent | Reason |
|---|---|---|
| C\|protocol-consistency (verdict-format.md:3) | inspector-consistency | D188: verdict-format.md は Review Pipeline 統一設計の設計仕様書として本セッション新設。既存 SKILL.md との不整合は次セッション実装前の意図的な中間状態 |
| H\|verdict-format-consistency (verdict-format.md:3) | inspector-flow | D188: 同上。SKILL.md/run.md 等のフォーマット参照は次セッションで一括移行予定 |
| H\|path-consistency (run.md:246) | inspector-consistency | D188: wave-{N} パス規則も同一移行の一部。verdict-format.md の wave-{N}/verdicts.yaml 定義は次セッション実装対象 |

## A) 自明な修正 (11件) — OK で全件修正します

| ID | Sev | Location | Summary | Fix |
|---|---|---|---|---|
| A1 | H | framework/claude/sdd/settings/templates/review-self/briefer.md:68 | 7日キャッシュ検索が `inspector-compliance.cpf` 固定のため旧命名アーカイブ (B41以前: `agent-3-compliance.cpf`) を見つけられない | キャッシュ検索をグロブ `*compliance.cpf` またはフォールバック付き二段階検索に変更 |
| A2 | H | install.sh:524 | engines.yaml を `cp` で無条件上書き。D180 は --update/--force 時のみ上書きと規定 | cp を `$UPDATE` または `$FORCE` フラグチェックで条件付け |
| A3 | H | framework/claude/settings.json:5 | `jq`/`env`/`kill` が allow リストにないが sdd-review/sdd-review-self が必須手順として要求 | settings.json の allow リストに `jq`・`env`・`kill` を追加 |
| A4 | M | framework/claude/skills/sdd-start/SKILL.md:3 | Step 7c が AskUserQuestion を明示的ツール呼び出しとして必須化しているが allowed-tools に含められない既知バグがある | Step 7c を AskUserQuestion ツール呼び出しに依存しない記述（出力提示 → ユーザー応答待ち）に書き換え |
| A5 | M | install.sh:572 | `remove_stale` の scripts 対象が `"*"` のため非 .sh ファイル（.md/設定断片）も削除対象になる | 対象を `*.sh` のみに絞る条件を追加 (skills の保護分岐と同様) |
| A6 | M | framework/claude/skills/sdd-review-self/SKILL.md:68 | Step 1 で `$SCOPE_DIR` を参照しているが定義は Step 2 (同ファイル83行目)。手順順序として未定義変数参照 | `$SCOPE_DIR` の定義を Step 1 の参照箇所より前に移動 |
| A7 | L | framework/claude/skills/sdd-roadmap/SKILL.md:123 | Verdict Persistence 手順の列挙が `a,b,c,d,e,g,h` で `f` が欠番 | 欠番を補完するか全体を再採番 |
| A8 | L | framework/claude/skills/sdd-review-self/SKILL.md:254 | "Agent Prompts"/"固定 Agent" 表記が残存。現行 `inspector-*` dispatch 名と不一致 | "Inspector Prompts"/"固定 Inspector" に更新 (D185 Naming Migration 適用) |
| A9 | L | framework/claude/skills/sdd-steering/SKILL.md:4 | D180 で engines モード削除済みだが Step 1 に engines モードの記述が残存。argument-hint と実装が不一致 | Step 1 から engines モード関連記述を削除 |
| A10 | L | README.md:5 | "5 SubAgents" 表記が実運用の多層構成 (Auditor/Inspector/ConventionsScanner 含む) と乖離 | 実態に即した記述に更新 |
| A11 | L | framework/claude/skills/sdd-roadmap/SKILL.md:4 | `revise` の Detect Mode (先頭語マッチで Single-Spec/Cross-Cutting 分岐) が未文書化。同名語を含む指示文の誤判定リスクへの言及なし | argument-hint または SKILL.md 冒頭に Detect Mode の動作仕様と注意事項を追記 |

## B) ユーザー判断が必要 (4件)

### B1: dead-code レビューの保存先スコープ識別子が未定義
**Location**: framework/claude/skills/sdd-roadmap/refs/run.md:256
**Description**: Wave QG では `/sdd-review dead-code` を呼ぶが、`sdd-review` はレビュー結果の保存先を「standalone 実行」と「Wave QG からの呼び出し」で分岐定義している。しかし引数仕様に呼び出しコンテキストを識別するパラメータがなく、ルーティング条件が実装上も仕様上も明示されていない。
**Impact**: 誤スコープへの永続化リスク (Wave QG 配下 vs. standalone 配下)。Wave 完了後の履歴参照・verdict 集計で混入が発生しうる。
**Recommendation**: `sdd-review` に `--context wave` / `--context standalone` オプションを追加し、Wave QG 呼び出し時は明示的に渡す — これにより分岐条件が引数で完結し、曖昧さが排除される。あるいは保存先を統一して分岐自体を廃止する方針も有効。

### B2: Cross-Cutting revise の `{id}` 受け渡し経路が未定義
**Location**: framework/claude/skills/sdd-roadmap/refs/revise.md:255
**Description**: Cross-Cutting 実行で `/sdd-review impl --cross-cutting {specs}` を呼ぶが、`sdd-review` が保存先として前提とする `specs/.cross-cutting/{id}/` の `{id}` がどこから来るかの経路が定義されていない。revise.md が `{id}` を生成・保持する記述もない。
**Impact**: Cross-Cutting review の保存先が未解決のまま実行されると、ディレクトリが確定できず verdict の永続化が失敗する。
**Recommendation**: revise.md に Cross-Cutting ID の生成規則 (例: `cc-{timestamp}` や spec 一覧のハッシュ) を明記し、`/sdd-review` 呼び出し時に `--id {id}` として渡す。

### B3: Wave QG でのカウンタリセットタイミングが未明記
**Location**: framework/claude/skills/sdd-roadmap/refs/run.md:249
**Description**: Wave QG の NO-GO/SPEC-UPDATE-NEEDED 枯渇時エスカレーション (Proceed/Abort/Manual fix) で、CLAUDE.md が定義する「user escalation decision 時の counter reset」の適用タイミングが run.md に明記されていない。エスカレーション後の再開時にカウンタが 0 からリスタートするのか、累積値を引き継ぐのかが不明瞭。
**Impact**: セッション跨ぎの再開時にカウンタ扱いの解釈差が生じ、意図しない早期エスカレーションまたはループ継続が発生しうる。
**Recommendation**: run.md のエスカレーション分岐に「ESCALATION_RESOLVED 後: retry_count/spec_update_count を 0 にリセット」を明記する。CLAUDE.md の "Counter reset triggers" 節と対応づけて一貫性を確保する。

### B4: run.md と sdd-review の相互循環参照
**Location**: framework/claude/skills/sdd-roadmap/refs/run.md:133
**Description**: `run.md` は `/sdd-review` のステップに依存し、`sdd-review` SKILL.md は standalone 説明で `run.md`/`revise.md` を参照するため、仕様参照が相互循環している。片側のみ改訂された場合に解釈差分を誘発する。
**Impact**: 改訂時の更新漏れリスク (中程度)。現状は実害が出ていないが、run.md や sdd-review の大きな変更を繰り返すほど乖離が蓄積する。
**Recommendation**: 参照の方向を一方向に固定する。案1: run.md を sdd-review の "caller 契約" として一方向に参照し、sdd-review は run.md を参照しない。案2: 共有仕様を `rules/review-protocol.md` に切り出し、両者がそれを参照する。

## Platform Compliance

| Item | Status | Source |
|---|---|---|
| agent-frontmatter-model | OK | inspector-compliance |
| skills-frontmatter-description | OK | inspector-compliance |
| skills-frontmatter-allowed-tools | OK | inspector-compliance |
| agent-frontmatter-description | OK | inspector-compliance |
| agent-frontmatter-tools | OK | inspector-compliance |
| skills-frontmatter-argument-hint-format | OK | inspector-compliance |
| agent-tool-subagent-type-general-purpose | OK | inspector-compliance |
| agent-tool-params-model-run_in_background | OK | inspector-compliance |
| agent-tool-dispatch-subagent-type-matches-definitions | OK | inspector-compliance |
| settings-permission-format | OK | inspector-compliance |
| settings-skill-permission-syntax | OK | inspector-compliance |
| settings-agent-skill-entries-match-files | OK | inspector-compliance |
| agent-tool-availability | OK | inspector-compliance |
