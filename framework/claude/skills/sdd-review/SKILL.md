---
name: sdd-review
description: "Unified review pipeline for design, impl, and dead-code reviews"
argument-hint: "design|impl <feature> [--cross-check] [--wave N] [--cross-cutting <specs> --id <cc_id>] | dead-code [--context standalone|wave] [--briefer-engine <name>] [--briefer-model <name>] [--briefer-effort <level>] [--inspector-engine <name>] [--inspector-model <name>] [--inspector-effort <level>] [--auditor-engine <name>] [--auditor-model <name>] [--auditor-effort <level>] [--timeout <seconds>]"
allowed-tools: Agent, Bash, Glob, Grep, Read, Write
---

# SDD Review

<instructions>

## Purpose

Design / Implementation / Dead-Code の 3 レビュータイプを統一的に実行するスキル。Inspector 並行 dispatch → Auditor 統合 → Verdict 永続化の一貫パイプラインを提供する。

SubAgent (Claude Code Agent tool) がデフォルト。外部エンジン (Codex / Claude / Gemini) は engines.yaml のデフォルト設定または Skill 引数 (`--inspector-engine` 等) で指定。

## Step 1: Parse Arguments + Load Engine Config

### 1a Parse Arguments

```
$ARGUMENTS = "design {feature}"              → REVIEW_TYPE=design, FEATURE={feature}
$ARGUMENTS = "impl {feature}"                → REVIEW_TYPE=impl, FEATURE={feature}
$ARGUMENTS = "dead-code"                      → REVIEW_TYPE=dead-code, FEATURE=none, CONTEXT=standalone
$ARGUMENTS = "dead-code --context wave"       → REVIEW_TYPE=dead-code, FEATURE=none, CONTEXT=wave
$ARGUMENTS = "dead-code --wave N"             → REVIEW_TYPE=dead-code, FEATURE=none, CONTEXT=wave, WAVE=N
$ARGUMENTS = "design --cross-check"          → REVIEW_TYPE=design, SCOPE=cross-check
$ARGUMENTS = "impl --cross-check"            → REVIEW_TYPE=impl, SCOPE=cross-check
$ARGUMENTS = "design --wave N"               → REVIEW_TYPE=design, SCOPE=wave-N
$ARGUMENTS = "impl --wave N"                 → REVIEW_TYPE=impl, SCOPE=wave-N
$ARGUMENTS = "impl --cross-cutting {spec1,spec2,...} --id {id}" → REVIEW_TYPE=impl, SCOPE=cross-cutting, SPECS_IN_SCOPE={list}, CC_ID={id}
```

オプション:
- `--briefer-engine <name>` / `--briefer-model <name>` / `--briefer-effort <level>`: Briefer エンジン/モデル/effort override
- `--inspector-engine <name>` / `--inspector-model <name>` / `--inspector-effort <level>`: Inspector エンジン/モデル/effort override
- `--auditor-engine <name>` / `--auditor-model <name>` / `--auditor-effort <level>`: Auditor エンジン/モデル/effort override
- `--timeout <seconds>`: タイムアウト

引数エラー → "Usage: `/sdd-review design|impl {feature}` or `/sdd-review design|impl --cross-check` or `/sdd-review design|impl --wave N` or `/sdd-review impl --cross-cutting {specs}` or `/sdd-review dead-code`"

**1-Spec Roadmap guard**: `--cross-check` or `--wave N` で roadmap.md が 1 spec のみ → "Single-spec roadmap — cross-check/wave review has no additional value." で中止。

### 1b Load engines.yaml

1. Read `.sdd/settings/engines.yaml`
   - If absent: all stages fallback to `subagents`, `$DENY_PATTERNS` = empty
2. Load `deny_patterns` → `$DENY_PATTERNS`

### 1c Resolve Final Config

**Level chain 解決** (各ステージ独立):

1. 各ステージの `start_level` を `roles.review.stages.{stage}.start_level` から取得
2. `levels.{start_level}` から `engine`, `model`, `effort` を取得 → ステージのデフォルト値
3. Skill 引数でオーバーライド (引数 > level chain):

| Stage Variable | Resolution (高→低) |
|---------------|-----------|
| `$BRIEFER_ENGINE` / `$BRIEFER_MODEL` / `$BRIEFER_EFFORT` | `--briefer-{engine,model,effort}` → `levels.{start_level}.{engine,model,effort}` |
| `$INSPECTOR_ENGINE` / `$INSPECTOR_MODEL` / `$INSPECTOR_EFFORT` | `--inspector-{engine,model,effort}` → `levels.{start_level}.{engine,model,effort}` |
| `$AUDITOR_ENGINE` / `$AUDITOR_MODEL` / `$AUDITOR_EFFORT` | `--auditor-{engine,model,effort}` → `levels.{start_level}.{engine,model,effort}` |

**共通設定**:

| Variable | Resolution |
|----------|-----------|
| `$TIMEOUT` | `--timeout` → `roles.review.timeout` → 1200 (hardcoded) |
| `$TOOLS` | `roles.review.tools` → null (full permission) |

4. 各ステージの engine について `engines.{engine}.install_check` を実行して可用性を確認
   - `install_check` 失敗 → level chain で次の level へ自動エスカレート。最終的に L0 (subagents) にフォールバック。Report: `{stage}: {engine} not available, escalating to L{N}`
   - claude エンジン使用時: `jq --version` で jq の可用性も確認。不在 → 次 level へ
5. Build per-stage `$ENGINE_CMD` using Engine-Specific Command Construction (後述) with the resolved engine/model/effort

6. Report resolved config:
```
Timeout: {$TIMEOUT}s
  Briefer: {$BRIEFER_ENGINE} [{$BRIEFER_MODEL}] effort:{$BRIEFER_EFFORT}
  Inspectors: {$INSPECTOR_ENGINE} [{$INSPECTOR_MODEL}] effort:{$INSPECTOR_EFFORT}
  Auditor: {$AUDITOR_ENGINE} [{$AUDITOR_MODEL}] effort:{$AUDITOR_EFFORT}
```

## Step 2: Phase Gate

**Design Review**: `design.md` 存在確認。`phase` が `design-generated` or `implementation-complete`。`blocked` → BLOCK。
**Implementation Review**: `design.md` + `tasks.yaml` 存在確認。`phase` が `implementation-complete`。`blocked` → BLOCK。
**Dead-Code Review**: Phase gate なし (codebase 全体)。Roadmap 存在のみ確認。

## Step 3: Inspector Set Resolution

Review type に応じて Inspector リストを決定。テンプレートパス: `$TPL = {{SDD_DIR}}/settings/templates/review`

### Design Review
Fixed (5): `inspector-design-rulebase`, `inspector-design-testability`, `inspector-design-architecture`, `inspector-design-consistency`, `inspector-design-best-practices`
Dynamic (1-4): Briefer が生成 (Step 3b)

Auditor: `auditor`

### Implementation Review
Fixed (5): `inspector-impl-rulebase`, `inspector-impl-interface`, `inspector-impl-test`, `inspector-impl-quality`, `inspector-impl-consistency`

Conditional:
- `inspector-impl-e2e`: `steering/tech.md` Common Commands に `# E2E` + 非空・非 placeholder コマンドが存在する場合
- `inspector-impl-web-e2e` + `inspector-impl-web-visual`: `steering/tech.md` に web stack indicators (React, Next.js, Vue, Angular, Svelte, Express, Django+templates, Rails, FastAPI+frontend 等) が存在する場合

Dynamic (1-4): Briefer が生成 (Step 3b)

Auditor: `auditor`

### Dead-Code Review
Fixed (4): `inspector-dead-settings`, `inspector-dead-code`, `inspector-dead-specs`, `inspector-dead-tests`
Dynamic: なし

Auditor: `auditor`

### 3b: Briefer Dispatch (design / impl のみ)

Dead-code review ではスキップ。

Briefer を dispatch して Dynamic Inspector プロンプトを生成。分岐順序: SubAgent → tmux → background (Inspector/Auditor と統一)。

**SubAgent mode** (`$BRIEFER_ENGINE == "subagents"`):
```
Agent(subagent_type="general-purpose", description="Briefer for {REVIEW_TYPE} review", run_in_background=true, prompt="
Read {$TPL}/briefer.md and execute the instructions.

Review type: {REVIEW_TYPE}
Feature: {FEATURE}
Scope: {SCOPE}
Output directory: {scope-dir}/active/
Template directory: {$TPL}/
Spec directory: .sdd/project/specs/{FEATURE}/
")
```
task-notification で完了を検知。

**tmux mode** (`$BRIEFER_ENGINE != "subagents"` かつ `$TMUX` 設定あり):
idle slot を選択し、`{{SDD_DIR}}/session/state.yaml` の該当 slot を `status: busy` + `agent: briefer`/`engine`/`channel` に更新。pane タイトルを更新: `tmux select-pane -t {pane_id} -T "review/briefer | {$BRIEFER_MODEL}"`
```
tmux send-keys -t {slot_pane_id} 'cat {$TPL}/briefer.md | {$BRIEFER_ENGINE_CMD}; tmux wait-for -S sdd-{SID}-review-briefer-B{seq}' Enter
```
ユーザーに報告: `Briefer dispatched to slot-{N} ({pane_id})`
send-keys ゾンビ確認後、`Bash(run_in_background=true)` で `tmux wait-for sdd-{SID}-review-briefer-B{seq}` を実行。task-notification で完了を検知。完了後、state.yaml の該当 slot を `status: idle` に戻し、`agent`/`engine`/`channel` を除去。pane タイトルをリセット: `tmux select-pane -t {pane_id} -T "sdd-{SID}-slot-{N}"`

**background mode** (上記以外):
`Bash(run_in_background=true)` で `cat {$TPL}/briefer.md | {$BRIEFER_ENGINE_CMD}` を実行。task-notification で完了を検知。

完了後:
1. `{scope-dir}/active/dynamic-manifest.md` の存在を確認
   - 不在 → Briefer 失敗。**Failure Log Capture** (Runtime Escalation Protocol 参照) を実行し、エスカレーション dispatch。L0 も失敗 → "Briefer failed. Proceeding with fixed inspectors only." として動的 Inspector なしで続行
2. Dynamic Inspector 名を Inspector リストに追加 (e.g., `dynamic-1-error-propagation`)
3. **ユーザーに dispatch 一覧を報告**: fixed + dynamic 全 Inspector のリスト (名前 + focus) をテーブル形式で表示
4. Step 5 以降で fixed + dynamic を統一的に dispatch

## Step 4: Scope Directory + B{seq}

Review scope directory を決定:

| Scope | Directory |
|-------|-----------|
| Per-feature (design/impl with feature) | `{{SDD_DIR}}/project/specs/{feature}/reviews/` |
| Dead-code (`$CONTEXT=standalone`) | `{{SDD_DIR}}/project/reviews/dead-code/` |
| Dead-code (`$CONTEXT=wave`) | `{{SDD_DIR}}/project/reviews/wave-{N}/` |
| Cross-check (`--cross-check`) | `{{SDD_DIR}}/project/reviews/cross-check/` |
| Wave-scoped (`--wave N`) | `{{SDD_DIR}}/project/reviews/wave-{N}/` |
| Cross-cutting (`$CC_ID` from `--id`) | `{{SDD_DIR}}/project/specs/.cross-cutting/{CC_ID}/` |

B{seq} 決定: `{scope-dir}/verdicts.yaml` を Read し、最大 batch 番号を +1。なければ 1。

`{scope-dir}/active/` を作成 (既存があれば削除してから再作成): `rm -rf {scope-dir}/active; mkdir -p {scope-dir}/active`

## Step 5: Brief Generation

### 5a Shared Brief

テンプレート `{{SDD_DIR}}/settings/templates/review/inspector-brief.md` を `{scope-dir}/active/shared-brief.md` にコピーし、shared プレースホルダーを sed で展開:

```
sed "s|{{REVIEW_TYPE}}|{value}|g; s|{{FEATURE}}|{value}|g; s|{{SCOPE}}|{value}|g; s|{{VERDICTS_PATH}}|{scope-dir}/verdicts.yaml|g" {template} > {scope-dir}/active/shared-brief.md
```

`{{DENY_PATTERNS}}` 展開: `$DENY_PATTERNS` (Step 1b でロード済み) を改行区切りでフォーマットし、shared-brief.md 内の `{{DENY_PATTERNS}}` を置換。SubAgent mode でも展開する (brief は外部エンジンのみで使用するが、テンプレートの一貫性のため)。

`{{WEB_SERVER_URL}}` は Step 6a で値が確定した後に展開する (web inspector がない場合は空文字で展開)。

### 5b Per-Inspector Output Path

外部エンジン dispatch 時のみ必要。SubAgent mode では dispatch prompt に直接含める。

各 Inspector について `{{OUTPUT_PATH}}` を展開した brief を `{scope-dir}/active/brief-{inspector-name}.md` に生成。**`;` 連結のワンライナー** (for ループ禁止):

```
Bash: sed "s|...|...|g" shared > brief-inspector1.md; sed "s|...|...|g" shared > brief-inspector2.md; ...
```

### 5c Auditor Brief Generation

テンプレート `{{SDD_DIR}}/settings/templates/review/auditor-brief.md` を `{scope-dir}/active/brief-{auditor-name}.md` にコピーし、プレースホルダーを sed で展開:

```
sed "s|{{REVIEW_TYPE}}|{value}|g; s|{{FEATURE}}|{value}|g; s|{{SCOPE}}|{value}|g; s|{{REVIEW_DIR}}|{scope-dir}/active/|g; s|{{VERDICT_PATH}}|{scope-dir}/active/verdict-auditor.yaml|g" {template} > {scope-dir}/active/brief-{auditor-name}.md
```

`{{SELFCHECK_CONTEXT}}` の展開:
- **impl review**: `sed -i '' "s|{{SELFCHECK_CONTEXT}}|Read .sdd/project/specs/{feature}/tasks.yaml for WARN-flagged items as attention points.|g" ...`
- **design / dead-code review**: `sed -i '' "s|{{SELFCHECK_CONTEXT}}||g" ...`

## Step 6: Inspector Dispatch

### 6a Web Server Lifecycle (impl review, web projects only)

Web inspectors (`inspector-impl-web-e2e`, `inspector-impl-web-visual`) を含む場合、Inspector dispatch **前に** dev server を起動。

**Server Lifecycle pattern** (from `{{SDD_DIR}}/settings/rules/lead/tmux-integration.md`):
1. `steering/tech.md` Common Commands の `Dev:` entry からコマンド取得
2. Dev server command がない → skip (web inspectors は "Server URL not accessible" で graceful termination)
3. Server 起動 (tmux pane or background Bash)
4. Ready pattern: `ready`, `localhost`, `listening on`
5. Server URL を記録 → shared-brief の `{{WEB_SERVER_URL}}` を展開:
   ```
   sed -i '' "s|{{WEB_SERVER_URL}}|Web server URL: {url}|g" {scope-dir}/active/shared-brief.md
   ```
   Web inspector がない場合: `sed -i '' "s|{{WEB_SERVER_URL}}||g" ...`

6. Per-inspector brief を再生成 (shared-brief が更新されたため、Step 5b を再実行)

### 6b Grid Setup (tmux mode, 外部エンジン時のみ)

全ステージが subagents の場合はスキップ。

`$TMUX` 設定あり かつ (`$INSPECTOR_ENGINE != "subagents"` or `$AUDITOR_ENGINE != "subagents"`):

1. `printenv TMUX_PANE` → `$MY_PANE`
2. SID + Grid 取得: `{{SDD_DIR}}/session/state.yaml` を Read し、`sid` と `grid` セクション (`window_id`, slot pane_ids) から `$SID` と slot pane ID を取得。state.yaml が存在しない場合 → tmux mode を諦め、全 agent を `Bash(run_in_background=true)` で実行 (background fallback)。
3. Grid 検証: `bash {{SDD_DIR}}/settings/scripts/grid-check.sh {grid.window_id} {all_slot_pane_ids}` — stdout に生存 pane_id を出力、exit 0 = 全 slot 生存, exit 1 = 一部消滅。一部消滅の場合、**Grid を再作成しない** (busy slot で実行中のプロセスを破壊する危険があるため)。idle slot 確定手順: (1) grid-check.sh stdout から生存 pane_id セットを取得 (2) state.yaml の各 slot で `status: idle` のものを抽出 (3) 両者の交差 = 使用可能 idle slot。不足分は `Bash(run_in_background=true)` にフォールバック。

### 6c Inspector Dispatch

分岐順序: SubAgent → tmux → background。

**SubAgent mode** (`$INSPECTOR_ENGINE == "subagents"`):

テンプレートパス: `$TPL = {{SDD_DIR}}/settings/templates/review`

全 Inspector を並行 dispatch (単一メッセージで parallel tool call)。各 task-notification で個別に完了を検知。
```
Agent(subagent_type="general-purpose", description="{inspector-name} review", run_in_background=true, prompt="
Read {$TPL}/{inspector-name}.md and execute the instructions.

Review: {REVIEW_TYPE}
Feature: {FEATURE} | Scope: {SCOPE}
Output: {scope-dir}/active/findings-{inspector-name}.yaml
{additional context}
")
```

追加コンテキスト (該当する場合):
- Wave-scoped: "Read `{verdicts-path}` for previously resolved issues. Do NOT re-flag resolved items."
- Impl review selfcheck: "Read `{spec-dir}/tasks.yaml` for WARN-flagged items as attention points."
- Steering exceptions: "Read `.sdd/session/handover.md`, apply Steering Exceptions as review exemptions."
- Web inspectors: `Web server URL: {url}`

Inspector は self-loading — テンプレート内の指示に従い、自分で steering, design.md, tasks.yaml 等を Read する。

**tmux mode** (`$INSPECTOR_ENGINE != "subagents"` かつ `$TMUX` 設定あり):

MultiView スロットに `send-keys` で agent コマンドを投入 (Hold-and-Release パターン)。idle スロットを選択し、`{{SDD_DIR}}/session/state.yaml` の該当 slot を `status: busy` + `agent`/`engine`/`channel` に更新。pane タイトルを更新: `tmux select-pane -t {pane_id} -T "review/{inspector-name} | {$INSPECTOR_MODEL}"`:
```
tmux send-keys -t {slot_pane_id} 'cat {scope-dir}/active/brief-{name}.md .sdd/settings/templates/review/{name}.md | {$INSPECTOR_ENGINE_CMD}; tmux wait-for -S sdd-{SID}-review-{name}-B{seq}; tmux wait-for sdd-{SID}-close-B{seq}' Enter
```

Staggered parallel dispatch (0.5 秒刻み) で全 Inspector を一括投入:
```
Bash(run_in_background=true): sleep 0.0; tmux send-keys -t {pane1} '...' Enter
Bash(run_in_background=true): sleep 0.5; tmux send-keys -t {pane2} '...' Enter
...
```

dispatch 後、ユーザーにスロット割り当てを報告:
```
Dispatched {N} inspectors to tmux slots:
  slot-{N} ({pane_id}): {inspector-name}
  ...
```

send-keys 完了後:
1. ゾンビ確認: `pgrep -fl "tmux send-keys"` → 検出時はユーザーに報告し kill (exit code 1 = ゾンビなし、正常)
2. 全 Inspector の `tmux wait-for sdd-{SID}-review-{name}-B{seq}` を staggered parallel dispatch で並行待機:
```
Bash(run_in_background=true): tmux wait-for sdd-{SID}-review-{name1}-B{seq}
Bash(run_in_background=true): tmux wait-for sdd-{SID}-review-{name2}-B{seq}
...
```
各 task-notification で個別に完了を検知。全 Inspector 完了まで待つ。TaskOutput は使わない。

**background mode** (上記以外):
```
Bash(run_in_background=true): cat {scope-dir}/active/brief-{name}.md .sdd/settings/templates/review/{name}.md | {$INSPECTOR_ENGINE_CMD}
```
全 Inspector を並列 `Bash(run_in_background=true)` で実行。各 task-notification で個別に完了を検知。

### 6d Wait + Collect

全 Inspector 完了後 (全 task-notification 受信):

1. 各 `{scope-dir}/active/findings-{inspector-name}.yaml` の存在とサイズを確認 (`ls -la`) — **Lead は findings の内容を Read しない**
2. findings YAML 未出力 Inspector → Runtime Escalation Protocol を適用 (L0 まで段階的にエスカレーション)
3. 最終的に未出力の Inspector 名を `$UNAVAILABLE_INSPECTORS` リストに記録 (例: `"impl-test, impl-e2e"`)。全 Inspector 成功時は `"None"`

### 6e Web Server Stop (impl review, web projects only)

全 Inspector 完了後、Auditor dispatch 前に dev server を停止。

### 6f Slot Release (tmux mode)

SubAgent mode ではスキップ。tmux mode:
1. `tmux wait-for -S sdd-{SID}-close-B{seq}` → 全スロットのブロック解除。
2. `{{SDD_DIR}}/session/state.yaml` の該当 slot を `status: idle` に更新し、`agent`/`engine`/`channel` を除去。pane タイトルをリセット: `tmux select-pane -t {pane_id} -T "sdd-{SID}-slot-{N}"`

## Step 7: Auditor Dispatch

Auditor dispatch 前に、Step 5c で生成済みの Auditor brief 内 `{{UNAVAILABLE_INSPECTORS}}` を `$UNAVAILABLE_INSPECTORS` (Step 6d で記録) で展開:
```
sed -i '' "s|{{UNAVAILABLE_INSPECTORS}}|{$UNAVAILABLE_INSPECTORS}|g" {scope-dir}/active/brief-{auditor-name}.md
```

分岐順序: SubAgent → tmux → background。

**SubAgent mode** (`$AUDITOR_ENGINE == "subagents"`):

```
Agent(subagent_type="general-purpose", description="Auditor synthesis", run_in_background=true, prompt="
Read .sdd/settings/templates/review/{auditor-name}.md and execute the instructions.

Review type: {REVIEW_TYPE}
Feature: {FEATURE}
Scope: {SCOPE}

Review directory: {scope-dir}/active/
Read all findings-inspector-*.yaml files from this directory.

Verdict output: {scope-dir}/active/verdict-auditor.yaml
Write your verdict to this path.

Unavailable Inspectors: {$UNAVAILABLE_INSPECTORS}

Read .sdd/session/handover.md, apply Steering Exceptions as review exemptions.
{selfcheck line}
")
```

`{selfcheck line}` (impl review のみ):
`Read .sdd/project/specs/{feature}/tasks.yaml for WARN-flagged items as attention points.`

Auditor は self-loading — テンプレート内の指示に従い、自分で findings-inspector-*.yaml を Read して統合する。task-notification で完了を検知。

**tmux mode** (`$AUDITOR_ENGINE != "subagents"` かつ `$TMUX` 設定あり):
idle スロットを選択し、`{{SDD_DIR}}/session/state.yaml` の該当 slot を `status: busy` + `agent: auditor`/`engine`/`channel` に更新。pane タイトルを更新: `tmux select-pane -t {pane_id} -T "review/auditor | {$AUDITOR_MODEL}"`
```
tmux send-keys -t {slot_pane_id} 'cat {scope-dir}/active/brief-{auditor-name}.md .sdd/settings/templates/review/{auditor-name}.md | {$AUDITOR_ENGINE_CMD}; tmux wait-for -S sdd-{SID}-review-auditor-B{seq}' Enter
```
ユーザーに報告: `Auditor dispatched to slot-{N} ({pane_id})`
`Bash(run_in_background=true)` で `tmux wait-for sdd-{SID}-review-auditor-B{seq}` を実行。task-notification で完了を検知。完了後、state.yaml の該当 slot を `status: idle` に更新し、`agent`/`engine`/`channel` を除去。pane タイトルをリセット: `tmux select-pane -t {pane_id} -T "sdd-{SID}-slot-{N}"`

**background mode** (上記以外):
`Bash(run_in_background=true)` で `cat {scope-dir}/active/brief-{auditor-name}.md .sdd/settings/templates/review/{auditor-name}.md | {$AUDITOR_ENGINE_CMD}` を実行。task-notification で完了を検知。

完了後: `{scope-dir}/active/verdict-auditor.yaml` の存在を確認。未出力 → Runtime Escalation Protocol を適用。

## Engine-Specific Command Construction

各ステージの engine に応じて `$INSPECTOR_ENGINE_CMD` / `$AUDITOR_ENGINE_CMD` を組み立てる。`$TOOLS` が null → 全許可モード、設定あり → ツール制限モード。

stdout はリダイレクトしない — pane に進捗が流れる。成果物は findings/verdict YAML ファイルのみ。

以下 `${STAGE}_MODEL` / `${STAGE}_EFFORT` はそのステージの resolved model / effort。

**codex**:
```
npx -y @openai/codex exec --full-auto [--model ${STAGE}_MODEL] [-c model_reasoning_effort='"${STAGE}_EFFORT"'] -
```

**claude** (`env -u CLAUDECODE` で Lead ネスト検出を回避):
```
env -u CLAUDECODE CLAUDE_CODE_EFFORT_LEVEL=${STAGE}_EFFORT claude -p - --dangerously-skip-permissions --output-format stream-json --verbose --include-partial-messages [--model ${STAGE}_MODEL] | jq -rjf .sdd/settings/scripts/claude-stream-progress.jq
```
ツール制限時: `--dangerously-skip-permissions` を `--allowedTools "$TOOLS"` に置換。

**gemini** (effort 非対応 — 設定ファイル書き換え必須のため除外):
```
npx -y @google/gemini-cli -p "Review the project files per the instructions below." --yolo [--model ${STAGE}_MODEL]
```
ツール制限時: `--yolo` を `--sandbox` に置換。

`[]` 内は対応する値が設定されている場合のみ付与。

**subagents**: CLI command 不要。Agent ツールで dispatch。
Model mapping (engines.yaml の model 値 → Agent tool `model` パラメータ):
- `*spark*` or `*haiku*` を含む → `"haiku"`
- `*opus*` を含む → `"opus"`
- その他 → `"sonnet"` (デフォルト)
Effort mapping (subagents): effort=`high` → プロンプト先頭に `ultrathink` を追加。effort=`medium` → 追加なし。

## Runtime Escalation Protocol

外部エンジンで成果物 (findings YAML / verdict YAML) が未生成の場合に発動。全ステージ (Briefer / Inspector / Auditor) で共通。

### Failure Log Capture

成果物不在を検出した時点で、直ちに diagnostic log を保存:

- **ファイル名**: `{scope-dir}/active/failure-{role}-{name}-{engine}-L{level}.log`
  - 例: `failure-inspector-impl-test-codex-L3.log`, `failure-auditor-claude-L5.log`
  - エスカレーション先も失敗した場合にログが上書きされないよう、engine + level をファイル名に含める
- **tmux mode**: `tmux capture-pane -t {pane_id} -p -S -100` の出力を Write
- **background mode**: TaskOutput ファイルを Read して Write
- **SubAgent mode**: Agent result を Write
- **先頭行**: `timestamp: {ISO-8601}  engine: {engine}  model: {model}  effort: {effort}  level: L{N}  agent: {name}`

### Failure Classification

Failure log の内容から障害タイプを **Lead が判定** する:

**ENGINE_FAILURE** (同一エンジンの上位レベルも同様に失敗する可能性が高い):
- HTTP 5xx (500, 502, 503, 504)
- Rate limit / quota exceeded
- Connection refused / reset / timeout
- API key invalid / authentication error
- "service unavailable", "internal server error"

**LEVEL_FAILURE** (エンジンは機能しているが、モデル/effort の変更で解決できる可能性あり):
- 出力が空 (pane に応答はあるが成果物ファイル未生成)
- YAML 構文エラー
- タスク途中終了 (partial output)

**判定不能** (ログが空、エラー情報なし): **ENGINE_FAILURE として扱う** (保守的判断)

### Escalation Logic

```
ENGINE_FAILURE:
  codex  (L1/L3/L4) → claude L5     (エンジン変更)
  claude (L2/L5/L6/L7) → subagents L0  (エンジン変更)
  subagents (L0)    → 最終失敗

LEVEL_FAILURE:
  L{N} → L{N+1}    (同一チェーン内で次レベル)
  L7   → L0        (チェーン末端、subagents fallback)
  L0   → 最終失敗
```

新しいレベルの engine/model/effort は engines.yaml `levels.L{N}` から解決し、Engine-Specific Command Construction で新しいコマンドを組み立てる。

### User Reporting

エスカレーション発生時、ユーザーに報告:
```
Runtime escalation: {agent-name}
  L{from} ({engine} {model}) → L{to} ({engine} {model})
  Reason: {ENGINE_FAILURE|LEVEL_FAILURE} — {key error from log}
  Log: {failure log path}
```

Also append to `issues.yaml` (auto-issue):
```yaml
- id: "I{next}"
  type: "BUG"
  status: "open"
  severity: "M"
  summary: "Runtime escalation: {agent-name} L{from}→L{to} ({ENGINE_FAILURE|LEVEL_FAILURE})"
  detail: "{key error from log}"
  source: "sdd-review"
  created_at: "{ISO-8601}"
```
If escalation resolves (agent succeeds at new level), update the issue to `status: resolved` with `resolution: "Resolved at L{to}"`.

### Inspector Runtime Escalation

`$INSPECTOR_ENGINE != "subagents"` かつ findings YAML 未生成の Inspector がある場合:
1. 失敗した Inspector のみを対象にリストアップ
2. 各失敗 Inspector について **Failure Log Capture** を実行
3. Failure Classification → Escalation Logic に従い次の dispatch 先を決定
4. 失敗 Inspector を新しいレベルで再 dispatch (成功済み Inspector はそのまま)
   - **tmux/background escalation**: 新レベルの Engine-Specific Command で dispatch
   - **SubAgent escalation (L0)**: `Agent(subagent_type="general-purpose", description="{inspector-name} escalation", run_in_background=true, prompt="Read .sdd/settings/templates/review/{inspector-name}.md and execute. {context brief}")`
5. findings YAML 存在を再チェック
6. まだ失敗 → 再度 Step 2 から (次レベルへ escalation、L0 到達まで)
7. L0 も失敗 → Auditor に "Inspector {name} unavailable" を通知

`$INSPECTOR_ENGINE == "subagents"` (L0) → フォールバック先なし、即失敗扱い。

### Auditor Runtime Escalation

`$AUDITOR_ENGINE != "subagents"` かつ verdict-auditor.yaml 未生成の場合:
1. **Failure Log Capture** を実行
2. Escalation Logic に従い次の dispatch 先を決定
3. SubAgent (L0) の dispatch: `Agent(subagent_type="general-purpose", description="Auditor escalation", run_in_background=true, prompt="Read .sdd/settings/templates/review/{auditor-name}.md and execute. {auditor context}")`
4. L0 も失敗 → "Auditor failed. Manual review required." を報告し停止

## Step 8: Lead Supervision + User Presentation

### 8a Lead 監修

Read `{scope-dir}/active/verdict-auditor.yaml` and apply Lead oversight:

1. **FP 判定**: `decisions.yaml` の `status: active` エントリと突合。意図的決定で説明できる finding → FP。Auditor が見落とした defer/意図的決定を Lead が補完する
2. **Defer 判定**: 過去に defer 済みの finding が再浮上していないか、decisions.yaml の該当エントリおよび `verdicts.yaml` の `tracked` items を引用して確認
3. **最終分類 (A/B)**: Auditor の classification を検証し、必要に応じて修正

#### 分類基準

**A) 自明な修正** (Auto-fix):
命名不一致、typo、許可漏れ、example 誤り等、判断不要で正解が一意のもの。

**B) ユーザー判断が必要** (Decision-required):
pre-existing backlog の対処方針、設計レベルの変更、影響範囲が広い修正。
→ 各 finding のフィールドを **すべて埋めて** 提示。「どうしますか？」だけで聞かない。

4. **verdict.yaml 作成**: Lead のオーバーライドを反映した最終 verdict を `{scope-dir}/active/verdict.yaml` に書き出す (verdict-format.md の Lead Final Verdict スキーマに準拠)

### 8b ユーザー提示

**提示テンプレートの全フィールドを省略せず出力すること**。要約テーブルへの圧縮は禁止。

```markdown
# Review Report: {REVIEW_TYPE} — {FEATURE or SCOPE}
**Date**: {ISO-8601} | **Engines**: briefer:{$BRIEFER_ENGINE} [{$BRIEFER_MODEL}], insp:{$INSPECTOR_ENGINE} [{$INSPECTOR_MODEL}], aud:{$AUDITOR_ENGINE} [{$AUDITOR_MODEL}]
**Agents**: {dispatched} dispatched ({fixed} fixed + {conditional} conditional + {dynamic} dynamic), {completed} completed

## False Positives Eliminated ({N}件)

| # | Finding | Agent | Reason (decisions.yaml ref) |
|---|---------|-------|---------------------------|
| 1 | {概要} | {検出Agent} | {FP理由 — D{seq} 参照 or 実動作確認等} |

## A) 自明な修正 ({N}件)

| ID | Sev | Location | Summary | Fix |
|----|-----|----------|---------|-----|
| A1 | {H/M/L} | {file}:{line} | {何が問題か} | {具体的な修正内容} |

## B) ユーザー判断が必要 ({N}件)

### B1: {title}
- **Severity**: {C/H/M/L}
- **Location**: {file}:{line}
- **Description**: {問題の詳細説明}
- **Impact**: {影響範囲 — どこに波及するか、どの程度深刻か}
- **Options**:
  - (a) {選択肢1} — {トレードオフ}
  - (b) {選択肢2} — {トレードオフ}
- **Recommendation**: {推奨する選択肢} — {推奨理由}
```

### 8c ユーザー判断の受領

ユーザーの回答を待つ:
- **A items**: 全承認 / 個別に却下
- **B items**: 各アイテムに対して approve / defer / reject

却下 (reject) されたアイテムはユーザー確認済み FP として扱う。defer されたアイテムは tracked に追加。

verdict.yaml の `user_decision` フィールドを更新。

**Pipeline mode** (run.md / revise.md から呼ばれた場合): verdict.yaml を返す。Auto-fix は pipeline orchestration が処理。
**Standalone mode**: Step 10 へ。

## Step 9: Verdict Persist + Archive

1. Verdict を `{scope-dir}/verdicts.yaml` に永続化 (verdict-format.md §4 Verdict Index スキーマ準拠):
   a. 既存ファイル Read (なければ `batches: []` で作成)
   b. `date +%Y-%m-%dT%H:%M:%S%z` で timestamp 取得、`.sdd/.version` から version 取得
   c. 新規 batch エントリを `batches` リストに append. `impl --wave N` の場合は `type: "cross-check"` に正規化する:
      ```yaml
      - seq: {N}
        type: "{review-type}"          # design/impl/dead-code/cross-check/cross-cutting (impl --wave N → cross-check)
        scope: "{feature or scope}"
        wave: {N}                      # wave/cross-check only
        date: "{ISO-8601}"
        version: "{version}"
        engines:
          briefer: "{model}"
          inspectors: "{model}"
          auditor: "{model}"
        agents:
          fixed: {N}
          conditional: {N}
          dynamic: {N}
          total: {N}
        counts:
          C: {n}
          H: {n}
          M: {n}
          L: {n}
          FP: {n}
        verdict: "{verdict}"
        disposition: "{disposition}"
        tracked: [...]                 # optional
        resolved: [...]                # optional
      ```
   d. `tracked`: verdict.yaml から M/L の deferred items を転記。同時に deferred items を `issues.yaml` に auto-append (`type: ENHANCEMENT, status: deferred, source: "{review_type} B{seq}"`)
   e. `resolved`: 前 batch の tracked と突合し解決済み items を記載
2. Archive: rename `{scope-dir}/active/` → `{scope-dir}/B{seq}/`

## Step 10: Standalone Verdict Handling

Standalone 呼び出し時 (run/revise pipeline 外):
1. Formatted verdict report を user に表示 (Step 8b で提示済み)
2. **Auto-fix なし**: verdict 報告のみ。Auto-fix loop は pipeline orchestration (run.md / revise.md) のみ
3. **STEERING entries 処理**:
   - `CODIFY|{file}|{decision}` → `steering/{file}` を直接更新 + decisions.yaml に append
   - `PROPOSE|{file}|{decision}` → user に提示。承認 → 更新 + decisions.yaml append。却下 → decisions.yaml append (理由を detail に記載)
4. Auto-draft `{{SDD_DIR}}/session/handover.md`

### Next Steps by Verdict (standalone)
- Design GO/CONDITIONAL → suggest `/sdd-roadmap impl {feature}`
- Impl GO/CONDITIONAL → feature complete
- NO-GO → report findings to user
- SPEC-UPDATE-NEEDED → report to user

## Error Handling

- **Engine not installed**: `install_check` 失敗 → level chain で次 level へ自動エスカレート (Step 1c)、最終的に L0 (subagents) にフォールバック
- **Claude nesting guard**: `env -u CLAUDECODE` で起動。なしでは "cannot be launched inside another Claude Code session" エラー
- **Inspector failure**: findings YAML 不在 → Runtime Escalation Protocol を適用。L0 まで失敗 → "Inspector {name} unavailable" として Auditor に通知。Failure log は `{scope-dir}/active/failure-*.log` に保存
- **Auditor failure**: verdict-auditor.yaml 不在 → Runtime Escalation Protocol を適用。L0 まで失敗 → 停止
- **Timeout**: `$TIMEOUT` 超過時は部分結果を確認。なければ Runtime Escalation Protocol を適用
- **Slot safety**: MultiView スロットは kill しない。Timeout 時は `C-c` を send-keys で停止
- **No findings**: Report "No issues detected." with confirmation checklist
- **Inspector ERROR findings**: C-level findings → Auditor にエラーコンテキスト + C findings を渡す

</instructions>
