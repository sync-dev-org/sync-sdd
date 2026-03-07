# SDD Framework Self-Review Report
**Date**: 2026-03-06T11:20:22+0900
**Agents**: 6 dispatched (3 fixed + 3 dynamic), 6 completed

---

## False Positives Eliminated

| Finding | Agent | Reason |
|---|---|---|
| UNCERTAIN\|agent-tool-params\|CLAUDE.md:84 — `run_in_background`/`model` パラメータの仕様準拠性 | Agent-3 (Compliance) | D96: `U-M5 (background: true) は FP — 公式サポートフィールドと確認。保持` として decisions.md に記録済み |
| H\|permissions\|sdd-start/SKILL.md:51 — AskUserQuestion が allowed-tools にない | Dynamic-1 (Session-Start) | D150 + MEMORY.md: AskUserQuestion は allowed-tools に含めてはいけない設計決定（自動承認パスで UI 非表示 → 空回答バグ） |

---

## A) 自明な修正 (11件) — OK で全件修正します

| ID | Sev | Location | Summary | Fix |
|---|---|---|---|---|
| A-01 | M | `framework/claude/skills/sdd-roadmap/SKILL.md:115` | Verdict 永続化参照が `run.md Step 7a/7b` だが実際の Wave QG は Step 8a/8b | `Step 7a/7b` → `Step 8a/8b` に番号修正 |
| A-02 | M | `framework/claude/skills/sdd-roadmap/SKILL.md:117` | Cross-Cutting verdict 永続化参照が `revise.md Part B Step 8` だが実際は Step 9 | `Step 8` → `Step 9` に番号修正 |
| A-03 | M | `framework/claude/skills/sdd-roadmap/refs/run.md:7` | Step 1 に未知 phase の即時 BLOCK 判定が明示されていない（CLAUDE.md は必須化） | Step 1 に「phase が unrecognized の場合は即時 BLOCK」分岐を追記 |
| A-04 | M | `framework/claude/skills/sdd-review-self/SKILL.md:124` | grid-check.sh と state.yaml の突合ロジック（交差 → 利用可能スロット確定）が未記述。busy slot 誤 idle 判定リスク | state.yaml の slot status 読み取り → grid-check.sh 生死 pane_id との交差 → idle スロット確定の手順を明文化 |
| A-05 | L | `framework/claude/skills/sdd-roadmap/SKILL.md:4` | Router の `argument-hint` が `/sdd-review` の engine/model/timeout オプション引き回しを表現していない | argument-hint に `[--engine ENGINE] [--model MODEL] [--timeout SEC]` オプションを追記 |
| A-06 | L | `framework/claude/skills/sdd-roadmap/SKILL.md:59` | Backfill 判定で `roadmap.md` が存在して wave 定義が空の場合の Wave 1 デフォルトが未定義 | 空 wave リストのケースを `Wave 1` をデフォルト配置先として明文化 |
| A-07 | L | `framework/claude/sdd/settings/templates/review-self/agent-3-compliance.md:7` | `framework/claude/agents/...`（検査対象）と `.claude/agents/...`（配置先）の文脈切替が不明確 | 「検査対象はフレームワークソース `framework/`、配置先は `install.sh` によるコピー先 `.claude/`」と注記を追加 |
| A-08 | L | `framework/claude/skills/sdd-start/SKILL.md:2` | 説明文のトリガーが「再開/continue/resume/毎セッション開始」のみ。`compact` と `/clear` が欠落 | `compact` と `/clear` を明示的にトリガー一覧に追記 |
| A-09 | L | `framework/claude/skills/sdd-start/SKILL.md:57-61` | `lead.window_id` と `grid.window_id` が常に同値だが 2 フィールドで管理。乖離時の不整合リスク | 「Lead は Grid と常に同一ウィンドウに存在するため両値は必ず一致する」旨の同値制約注記を追加 |
| A-10 | L | `framework/claude/sdd/settings/rules/tmux-integration.md:161` | `-B{seq}` 分離キーの必須条件が命名規則本文で明文化されていない。省略実装でチャネル衝突リスク | 命名規則に「再実行ごとに `-B{seq}` サフィックスを付与すること（必須）」を明記 |
| A-11 | L | `framework/claude/skills/sdd-review-self/SKILL.md:225` | 「0.5 秒刻み staggered dispatch」と記述しながら直下の例示コマンドに `sleep` プレフィックスがない | 例示コマンドに `sleep 0`, `sleep 0.5`, `sleep 1.0` 等の stagger prefix を追記 |

---

## B) ユーザー判断が必要 (12件)

### B-01: Dead-Code Wave QG のコンテキスト受け渡し規約が未定義
**Location**: `framework/claude/skills/sdd-roadmap/refs/run.md:254`
**Description**: Wave QG の Dead-Code Review 実行が `/sdd-review dead-code` のみで、wave コンテキスト（スコープ、wave 番号、共有ファイルリスト等）の受け渡し規約が未定義。また `sdd-review` 側の dead-code スコープ切替条件が明示されておらず、`project/reviews/dead-code/` に永続化される経路が残っている。
**Impact**: Dead-Code Review が wave スコープを超えた全体スキャンを行い、他 wave で未実装の正常ファイルを dead-code 誤検出する可能性がある。Wave ごとの精度劣化。
**Recommendation**: dead-code 実行時の `--scope wave-{N}` 相当のコンテキスト引き渡しルールを run.md に明記し、`sdd-review` 側の受け取り手順を追加する。または現状の全体スキャン方針を意図的選択として明示する。

### B-02: Auditor/Inspector の実体 SubAgent 定義整合性の確認
**Location**: `framework/claude/CLAUDE.md:24`
**Description**: T2/T3 役割テーブルで Auditor・Inspector を SubAgent として定義しているが、`framework/claude/agents/` に全種の実体 Agent 定義が存在するか、`settings.json` の許可リストとの整合が取れているかの検証が必要。Inspector 種 (design/impl/test/e2e/web-e2e/web-visual/dead-code) および Auditor 種 (design/impl/dead-code) が全て定義されているか確認が必要。
**Impact**: 欠落する Agent 定義がある場合、dispatch 時に `Unknown subagent_type` エラーが発生し、レビューパイプラインが停止する。
**Recommendation**: `framework/claude/agents/` 配下の全 sdd-inspector-*/sdd-auditor-* ファイルと CLAUDE.md テーブルを突合し、欠落があれば追加する。settings.json の許可エントリも合わせて確認する。

### B-03: ツール未導入時の Inspector 判定基準の分裂
**Location**: `framework/claude/sdd/settings/templates/review/sdd-inspector-e2e.md:108`
**Description**: `sdd-inspector-e2e` はツール未導入時（`command not found`）を CRITICAL 扱いで失敗にするが、`sdd-inspector-web-e2e`（183行）と `sdd-inspector-web-visual`（211行）は同種の前提欠落を `VERDICT:GO` でスキップする。同一レビュー群で判定基準が分裂している。
**Impact**: 同じ「ツール未導入」状況でも Inspector によって NO-GO / GO が変わり、Auditor の総合判定が不安定になる。ユーザーの環境差による意図しない NO-GO 多発。
**Recommendation**: 統一方針を決定する — (A) 全 Inspector でツール未導入は `VERDICT:GO`（スキップ）とするか、(B) 前提ツールリストを event 前に検証して一括 BLOCK するか。いずれかを採用してテンプレートを統一する。

### B-04: sdd-review-self の `rm -rf active/` に Bash 許可がない
**Location**: `framework/claude/settings.json:5`
**Description**: `/sdd-review-self` の初期化ステップで `rm -rf $SCOPE_DIR/active` を実行するが、settings.json の許可リストに `Bash(rm *)` が存在せず、権限ブロックが発生する。
**Impact**: レビュー開始時の active/ クリーンアップが実行不能。前回のstale CPF が残存したまま次回レビューが実行され、findings が汚染される。
**Recommendation**: settings.json の Bash 許可リストに `rm` または `rm -rf .sdd/project/reviews/self/active` のスコープを追加する。または active/ クリーンアップを Bash でなく別の方法（Write で上書き等）に変更する。

### B-05: ConventionsScanner の待機方式が task-notification と不整合
**Location**: `framework/claude/skills/sdd-roadmap/refs/run.md:41`
**Description**: `run_in_background=true` で起動した ConventionsScanner に対し `WRITTEN:{path}` 応答待ちを明記しており、dispatch-loop が前提とする task-notification ベース待機と矛盾している。D162 で TaskOutput を全廃し notification ベースに統一済みだが、run.md:41 の記述が旧プロトコルのまま残存。
**Impact**: `WRITTEN:{path}` を Task result として待機する実装に戻ると、並列進行が停止し完了検知レースが再発する（D159 のインシデント再現）。
**Recommendation**: run.md:41 の ConventionsScanner 完了待機を `WRITTEN:{path}` → task-notification 受信後にファイル読み取りする記述に修正する。

### B-06: compliance テンプレートの OK/NG/UNCERTAIN と CPF severity 規約の整合
**Location**: `framework/claude/sdd/settings/templates/review-self/agent-3-compliance.md:27`
**Description**: CPF 基本仕様（`cpf-format.md:14`）は ISSUES の Severity を C/H/M/L に統一しているが、compliance テンプレートは `OK/NG/UNCERTAIN` を ISSUES 行として要求している（D99 で意図的に設計）。共通パーサー前提と衝突しうる。
**Impact**: Auditor が CPF ISSUES 行を C/H/M/L でパースしようとした場合、compliance の `OK/NG/UNCERTAIN` 行を正しく処理できないリスク。現状の Auditor（claude-sonnet-4-6）は手動パース可能だが、将来の自動化で問題になりうる。
**Recommendation**: (A) cpf-format.md に compliance 向けの `OK/NG/UNCERTAIN` 例外を追記して仕様化する、または (B) compliance テンプレートを C/H/M/L + citation footnote 形式に統一する。D99 で意図的設計済みのため変更コストは低い。

### B-07: engines.yaml 欠如時の prep.md フォールバック未定義
**Location**: `framework/claude/sdd/settings/templates/review-self/prep.md:38`
**Description**: Step 3 で `.sdd/settings/engines.yaml` を必須読取するが、ファイル欠如時（未インストール/削除等）の生成・フォールバック手順がテンプレート内にない。単体実行時に停止する。
**Impact**: `engines.yaml` が存在しない環境（新規インストール直後、手動削除後等）で Prep が停止し、全 Inspector が dispatch されない。
**Recommendation**: prep.md Step 3 に「engines.yaml が存在しない場合は `install.sh` を再実行するか、デフォルトエンジン設定にフォールバックする」旨を追記する。または install.sh が engines.yaml を必ず生成することを保証する記述を追加する。

### B-08: 通常 install 時に旧 sdd-resume ディレクトリが残留する可能性
**Location**: `install.sh:537`
**Description**: stale skill の除去が `--update`/`--force` 時のみ実行される。既存環境で `--update`/`--force` なしの通常インストールを再実行した場合、旧 `sdd-resume` ディレクトリが `.claude/skills/sdd-resume/` として残留し、新 `sdd-start` と並存する。
**Impact**: 既存ユーザーが更新時に `--force` を忘れると旧スキルが残存する。MEMORY.md には「毎回 `--local --force` 必須」とあるが、エンドユーザーへの周知が不十分。
**Recommendation**: (A) install.sh の stale 除去ロジックを通常インストール時にも適用する、または (B) README/インストール手順に「アップグレード時は必ず `--force` を指定すること」を明記する。

### B-09: multiview-grid.sh のグリッド再利用判定が pane タイトルに依存
**Location**: `framework/claude/sdd/settings/scripts/multiview-grid.sh:13-23`
**Description**: グリッド再利用判定が `sdd-${SID}-slot-` pane タイトルに依存している。フレームワーク原則「pane タイトルは装飾のみ、ロジック依存禁止」（D167）と矛盾。通常は sdd-start が grid-check.sh（state.yaml ベース）を先に実行するためこのパスには到達しないが、state.yaml 破損/欠損時に multiview-grid.sh が直接呼ばれた場合に Claude Code のタイトル上書きで誤判定しうる。
**Impact**: 直接呼び出し時に既存グリッドを認識できず不要な再作成が発生。通常フローでは発生しない低確率リスク。
**Recommendation**: multiview-grid.sh のタイトル依存判定を削除し、引数で SID を受け取る形式に変更して state.yaml ベースの判定に統一する、または「このスクリプトは sdd-start 経由でのみ呼び出すこと」を明確にコメントで警告する。

### B-10: multiview-grid.sh の list-panes がウィンドウスコープなし
**Location**: `framework/claude/sdd/settings/scripts/multiview-grid.sh:13`
**Description**: `tmux list-panes` に `-t @{window_id}` スコープ指定がなく、current window のみ検索する。Lead が grid と異なるウィンドウにいる場合、既存スロットを検出できず不要な再作成が発生する。通常は Lead と grid は同一ウィンドウにあるべきで発生しないが、ウィンドウ再配置後等のエッジケースで問題になりうる。
**Impact**: 低確率エッジケース。ただし誤った再作成で busy slot が破壊されると実行中 Agent が終了する。
**Recommendation**: list-panes に `-t @${WINDOW_ID}` スコープを追加し、state.yaml から window_id を受け取る形式に変更する。B-09 と合わせて修正するとスコープ整合が取れる。

### B-11: Task result 読取と task-notification 待機の規約境界が不明確
**Location**: `framework/claude/CLAUDE.md:34`
**Description**: 同一文書内で「Lead は Task result を読む」（line 34）と「完了検知は task-notification」（line 84）が併記され、「待機トリガー = task-notification」「成果物読取 = Task result or ファイル読み取り」の役割境界が不明確。`/sdd-review` 系実装で待機手段の解釈が分岐する余地がある。
**Impact**: 新規スキル実装者が Task result ポーリングに戻す実装をした場合、Race Condition が再発する（D159 インシデント）。
**Recommendation**: CLAUDE.md に「完了待機 = task-notification のみ。Task result は通知受信後に Lead が読む補助情報。polling 禁止」と明確に記述する。

### B-12: orphan-detect.sh が busy/idle を区別しない
**Location**: `framework/claude/sdd/settings/scripts/orphan-detect.sh:11-14`
**Description**: primary モードは state.yaml の全 pane_id のうち MY_PANE 以外の live pane を出力するが、busy/idle の区別をしない。sdd-start の文脈では全て orphan 扱いで正しいが、将来 orphan-detect が他のコンテキストから呼ばれた場合に busy pane を誤って orphan 報告するリスクがある。現時点では sdd-start 専用のため実害なし。
**Impact**: 現状実害なし。将来コンテキスト拡大時に busy pane を誤 kill するリスク。
**Recommendation**: (A) スクリプト冒頭に「このスクリプトは sdd-start 専用」の警告コメントを追記する（低コスト）、または (B) busy/idle フィルタオプションを追加する。

---

## Platform Compliance

| Item | Status | Source |
|---|---|---|
| agent-frontmatter-model | OK | https://docs.anthropic.com/en/docs/claude-code/sub-agents |
| agent-frontmatter-tools | OK | https://docs.anthropic.com/en/docs/claude-code/settings#tools-available-to-claude |
| agent-frontmatter-description | OK | https://docs.anthropic.com/en/docs/claude-code/sub-agents |
| skills-frontmatter-description-and-allowed-tools | OK | https://docs.anthropic.com/en/docs/claude-code/skills |
| skills-frontmatter-argument-hint-format | OK | https://docs.anthropic.com/en/docs/claude-code/skills |
| dispatch-subagent-type-to-existing-agents | OK | https://docs.anthropic.com/en/docs/claude-code/sub-agents |
| settings-permission-format-skill-agent | OK | https://docs.anthropic.com/en/docs/claude-code/settings#tool-specific-permission-rules |
| settings-skill-agent-entries-vs-files | OK | https://docs.anthropic.com/en/docs/claude-code/settings#tool-specific-permission-rules |
| agent-tool-availability-vs-declared-tools | OK | https://docs.anthropic.com/en/docs/claude-code/settings#tools-available-to-claude |
| agent-tool-params (run_in_background, model) | FP/OK | D96 decisions.md — 公式サポートフィールドと確認済み |
