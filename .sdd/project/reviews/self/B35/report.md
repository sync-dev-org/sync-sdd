# SDD Framework Self-Review Report
**Date**: 2026-03-05T01:06:35+0900 | **Engine**: codex [gpt-5.3-codex] | **Pipeline**: agent
**Agents**: 4 dispatched, 4 completed

## False Positives Eliminated

| Finding | Agent | Reason |
|---|---|---|
| L\|revise-routing\|sdd-roadmap/SKILL.md:32 — Cross-Cutting強制フラグなし | Agent 1 | D17: `revise` の 2 モード統合設計通り。feature 名有無で Single-Spec / Cross-Cutting を自動判定し、Step3 で事後昇格する設計が確定済み |

## A) 自明な修正 (12件) — OK で全件修正します

| ID | Sev | Location | Summary | Fix |
|---|---|---|---|---|
| F01 | HIGH | framework/claude/skills/sdd-review-self/SKILL.md:3 | allowed-tools に `Agent` がないが本文 183/250/293/333/385 行で `Agent(...)` 実行が必須化されており、tooling contract が破綻 | frontmatter の `allowed-tools` に `Agent` を追加 |
| F04 | MED | framework/claude/sdd/settings/templates/review-self/agent-4-compliance.md:40 | `COMPLIANCE_TABLE` セクション指定と同ファイル 43 行の `COMPLIANT` セクション指定が競合し、キャッシュ抽出セクション名が一意に定まらない | 40 行の `COMPLIANCE_TABLE` を `COMPLIANT` に統一 |
| F05 | MED | framework/claude/skills/sdd-review-self/SKILL.md:96 | lead pipeline が `git diff HEAD~10..HEAD` 固定のため、コミット数 <10 のリポジトリで失敗する。Prep テンプレート側は `min(count,10)` に更新済みで不一致 | `HEAD~10` を `HEAD~$(git rev-list --count HEAD \| awk '{if($1<10)print $1;else print 10}')` 相当に修正（またはPrep側と同じ `min(count,10)` ロジックに統一） |
| F07 | MED | framework/claude/skills/sdd-roadmap/refs/revise.md:76 | Single-Spec revise の上限到達時の fix/skip/abort 相当の分岐が run.md ほど明示されておらず、停止/再開フローが曖昧 | run.md の自動修正ループ停止条件（max 5 retry / aggregate cap 6）を revise.md にも明示追記 |
| F08 | MED | framework/claude/skills/sdd-roadmap/refs/review.md:20 | `--wave`/`--cross-check` 実行時の blocked spec 除外条件が review.md に記載なし（run.md:238 では除外必須） | run.md:238 と同等の「blocked spec はスキップ」条件を review.md Phase Gate に追記 |
| F12 | MED | framework/claude/skills/sdd-handover/SKILL.md:1 | frontmatter に `argument-hint` がなく、description/allowed-tools/argument-hint 構成を満たしていない | frontmatter に `argument-hint: ""` または適切なヒント文字列を追加 |
| F13 | MED | framework/claude/skills/sdd-publish-setup/SKILL.md:1 | frontmatter に `argument-hint` がなく、description/allowed-tools/argument-hint 構成を満たしていない | frontmatter に `argument-hint: ""` または適切なヒント文字列を追加 |
| F14 | LOW | framework/claude/skills/sdd-roadmap/refs/run.md:136 | Dispatch Loop の Review Decomposition が「review.md step1-4 実行」と書くが step1 は CLI 引数解析であり run 内部イベント入力との対応が不明確 | 「review.md step2-4 実行」に修正（または step1 の内部マッピングを明示） |
| F15 | LOW | framework/claude/skills/sdd-roadmap/SKILL.md:70 | Single-Spec Roadmap Ensure の例外表記が `review --cross-check` / `review --wave N` となっており Detect Mode の正規形 `review design|impl --...` と文法がずれている | 正規形 `review design --cross-check` / `review impl --wave N` 等の形式に修正 |
| F16 | LOW | framework/claude/sdd/settings/templates/review-self/agent-1-flow.md:12 | Review Criteria に Consensus mode 検証が残っているが、sdd-roadmap から `--consensus` 系仕様は D129 で削除済み | Consensus mode 検証項目をテンプレートから削除 |
| F17 | LOW | framework/claude/skills/sdd-status/SKILL.md:47 | Review history 出力項目に `runs` を要求しているが現行 Verdict Persistence ヘッダー定義に `runs` フィールドは存在しない（D71 M-BL2 で省略決定済み） | `runs` フィールド参照を削除 |
| F18 | LOW | framework/claude/CLAUDE.md:240 | `**Manual polish** (/sdd-handover)` 見出しが重複しており手順参照の一貫性を下げる | 重複見出しを削除 |

## B) ユーザー判断が必要 (6件)

### F02: Wave QG SPEC-UPDATE-NEEDED 上限到達時のエスカレーション手順欠落
**Location**: framework/claude/skills/sdd-roadmap/refs/run.md:249
**Description**: Wave QG の SPEC-UPDATE-NEEDED 分岐に、`spec_update_count` max 2 / aggregate cap 6 到達時の停止条件と明示的なエスカレーション手順が記載されていない。CLAUDE.md の Auto-Fix Counter Limits には上限が定義されているが、run.md 側に対応する分岐フローが欠落しており、反復再実行が無制限化する解釈余地がある。
**Impact**: 上限到達時の挙動が不定義なため、Lead が誤って反復ループに入り続けるリスクがある。HIGH severity。
**Recommendation**: CLAUDE.md の上限定義と対応する明示的エスカレーション手順（「上限到達時は user escalation → skip or abort を選択」）を run.md SPEC-UPDATE-NEEDED 分岐に追記する — CLAUDE.md との整合性を保ちつつ run.md を単一の実行プロトコル参照にするため。

### F03: sdd-review-self Prep Agent の改行処理手順欠落
**Location**: framework/claude/skills/sdd-review-self/SKILL.md:159
**Description**: `{{FOCUS_TARGETS}}`/`{{CACHED_OK}}` の改行時に Prep Agent が `agent-{N}.md` を生成すると定義されているが、現行 Prep テンプレートは `focus-targets.txt`/`cached-ok.txt` のみを生成する。agent pipeline の改行プレースホルダー処理手順が欠落しており、pipeline モードで Prep → Agent の引き継ぎが機能しない可能性がある。
**Impact**: agent pipeline で改行プレースホルダーが処理されないと、Agent が空の対象リストまたは不正なプロンプトを受け取る。HIGH severity。
**Recommendation**: Prep テンプレートに `agent-{N}.md` 生成ステップを追加するか、SKILL.md の改行処理記述を `focus-targets.txt`/`cached-ok.txt` を参照する形式に修正する — 現行 Prep テンプレートの実装に合わせることが最短パス。

### F06: sdd-review-self Review Scope から refs/*.md が除外されている
**Location**: framework/claude/skills/sdd-review-self/SKILL.md:113
**Description**: lead pipeline / Prep テンプレートの Review Scope が `framework/claude/skills/sdd-*/SKILL.md` のみを対象にしており、`framework/claude/skills/sdd-roadmap/refs/*.md`（run/review/revise/impl 等の主要プロトコル）が収集されない。一方 Prep テンプレート側では `refs/*.md` が含まれるため、pipeline モードとPrepモードでレビュー対象範囲が乖離する。
**Impact**: run.md/review.md 等の主要プロトコルの整合性検査がlead pipeline で欠落する。今回のAgent 1 発見（F02/F07/F08）は refs/*.md 対象だったが、lead pipeline では拾えない状態。MEDIUM severity。
**Recommendation**: lead pipeline の Review Scope に `framework/claude/skills/sdd-*/refs/*.md` を追加する — refs/*.md はSKILL.mdの実行詳細を格納しており、SKILL.mdとの整合性検査に不可欠。ただしスキャン対象拡大によりコスト増加があるため、スコープ絞り込み（roadmap/refs/*.md のみ等）も検討可。

### F09: Auto-Detect Reset のルーティング先未定義
**Location**: framework/claude/skills/sdd-roadmap/SKILL.md:44
**Description**: Auto-Detect の選択肢に `Reset` があるが、Detect Mode 表および Execution Reference に Reset の正式ルーティング先（delete + create 連鎖、またはその他の操作）が定義されていない。
**Impact**: Lead が Reset を検出した際の動作が不定義のため、ユーザーが Reset を意図した操作をしても適切にルーティングされない可能性がある。MEDIUM severity。
**Recommendation**: Reset のルーティング先を明示する（例：「delete → create の連鎖」または「確認後 delete のみ」等）。あるいは Auto-Detect 選択肢から Reset を削除してユーザーに明示的コマンド入力を求める方針を採用する — 現状では誤ルーティングの可能性があるため、いずれかの方針確定が必要。

### F10: Verdict header の wave/cross-check/dead-code における version 基準の曖昧さ
**Location**: framework/claude/skills/sdd-roadmap/SKILL.md:114
**Description**: Verdict header の基準が `v{version}` 前提だが、wave/cross-check/dead-code の project-level review は単一 spec の version を持たず、review.md/run.md 側の記録形式と解釈が分岐しうる。
**Impact**: project-level review の Verdict ヘッダーが不定形になり、sdd-status や他ツールでの参照時に解釈エラーが起きる可能性がある。MEDIUM severity。
**Recommendation**: project-level review（wave/cross-check/dead-code）の Verdict header 形式を明示する（例：wave の場合は `wave-{N}`、cross-check は `cross-{id}`、dead-code は `dead-code` を version フィールドに使用）— フォーマット統一により参照の一貫性を確保。

### F11: sdd-inspector-impl-rulebase の VERDICT enum 内部不一致
**Location**: framework/claude/agents/sdd-inspector-impl-rulebase.md:124
**Description**: 出力フォーマット定義（124行）では `VERDICT: {GO|CONDITIONAL|NO-GO}` に限定しているが、エラーハンドリング例（156行）では `VERDICT: ERROR` を要求しており、同一ファイル内で判定値の契約が矛盾している。
**Impact**: Inspector が ERROR を返した場合に Auditor が想定外の verdict 値を受け取り、集計処理が不定動作になりうる。MEDIUM severity。
**Recommendation**: 2択: (a) `VERDICT` を `{GO|CONDITIONAL|NO-GO|ERROR}` の 4 値に拡張し、Auditor 側でも ERROR を処理するよう更新する、または (b) エラー時は `VERDICT: NO-GO` + `ERROR:` セクションで詳細を伝達する形式に統一する — (b) の方が Auditor 変更範囲が小さい。

## Platform Compliance

| Item | Status | Source |
|---|---|---|
| agent-frontmatter-fields | COMPLIANT | Agent 4 (cached:B34) |
| agent-model-values | COMPLIANT | Agent 4 (cached:B34) |
| agent-tool-dispatch-patterns | COMPLIANT | Agent 4 (cached:B34) |
| settings-permission-format | COMPLIANT | Agent 4 (cached:B34) |
| settings-agent-skill-entry-match | COMPLIANT | Agent 4 (cached:B34) |
| tool-availability-names | COMPLIANT | Agent 4 (cached:B34) |
| agent-tool-parameters-subagent_type | COMPLIANT | Agent 4 (cached:B34) |
| sdd-review-self allowed-tools (Agent) | NON-COMPLIANT | F01 — auto-fix対象 |
| skills-frontmatter (argument-hint) | NON-COMPLIANT | F12, F13 — auto-fix対象 |
