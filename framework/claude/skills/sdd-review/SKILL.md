---
description: "Unified review pipeline for design, impl, and dead-code reviews"
argument-hint: "design|impl <feature> [--cross-check] [--wave N] | dead-code [--inspector-engine <name>] [--auditor-engine <name>]"
allowed-tools: Agent, Bash, Glob, Grep, Read, Write
---

# SDD Review

<instructions>

## Purpose

Design / Implementation / Dead-Code の 3 レビュータイプを統一的に実行するスキル。Inspector 並行 dispatch → Auditor 統合 → Verdict 永続化の一貫パイプラインを提供する。

SubAgent (Claude Code Agent tool) がデフォルト。外部エンジン (Codex / Claude / Gemini) は engines.yaml でオプトイン。

## Step 0: Parse Arguments + Load Engine Config

### 0.1 Parse Arguments

```
$ARGUMENTS = "design {feature}"              → REVIEW_TYPE=design, FEATURE={feature}
$ARGUMENTS = "impl {feature}"                → REVIEW_TYPE=impl, FEATURE={feature}
$ARGUMENTS = "dead-code"                      → REVIEW_TYPE=dead-code, FEATURE=none
$ARGUMENTS = "design --cross-check"          → REVIEW_TYPE=design, SCOPE=cross-check
$ARGUMENTS = "impl --cross-check"            → REVIEW_TYPE=impl, SCOPE=cross-check
$ARGUMENTS = "design --wave N"               → REVIEW_TYPE=design, SCOPE=wave-N
$ARGUMENTS = "impl --wave N"                 → REVIEW_TYPE=impl, SCOPE=wave-N
```

オプション:
- `--inspector-engine <name>` / `--inspector-model <name>`: Inspector エンジン/モデル override
- `--auditor-engine <name>` / `--auditor-model <name>`: Auditor エンジン/モデル override
- `--timeout <seconds>`: タイムアウト

引数エラー → "Usage: `/sdd-review design|impl {feature}` or `/sdd-review design|impl --cross-check` or `/sdd-review design|impl --wave N` or `/sdd-review dead-code`"

**1-Spec Roadmap guard**: `--cross-check` or `--wave N` で roadmap.md が 1 spec のみ → "Single-spec roadmap — cross-check/wave review has no additional value." で中止。

### 0.2 Load engines.yaml

1. Read `.sdd/settings/engines.yaml`
   - If absent: copy from `.sdd/settings/templates/engines.yaml` → `.sdd/settings/engines.yaml`, then read. Report: `engines.yaml をデフォルトで作成しました。/sdd-steering engines でカスタマイズ可能です。`
   - If template also absent: all stages fallback to `subagents`
2. Load `deny_patterns` → `$DENY_PATTERNS`

### 0.3 Resolve Final Config

**Per-stage 解決** (各ステージ独立):

| Stage Variable | Resolution (高→低) |
|---------------|-----------|
| `$INSPECTOR_ENGINE` / `$INSPECTOR_MODEL` | `--inspector-{engine,model}` → `stages.inspectors.{engine,model}` → **subagents** / null |
| `$AUDITOR_ENGINE` / `$AUDITOR_MODEL` | `--auditor-{engine,model}` → `stages.auditor.{engine,model}` → **subagents** / null |

**共通設定**:

| Variable | Resolution |
|----------|-----------|
| `$TIMEOUT` | `--timeout` → `roles.review.timeout` → 1200 (hardcoded) |
| `$TOOLS` | `roles.review.tools` → null (full permission) |

末尾の **subagents** がフォールバック — engine 未指定時は常に subagents を使用。

3. 各ステージの engine について `engines.{engine}.install_check` を実行して可用性を確認
   - `install_check` 失敗 → そのステージを **subagents にフォールバック**。Report: `{stage}: {engine} not available, falling back to subagents`
   - claude エンジン使用時: `jq --version` で jq の可用性も確認。不在 → subagents にフォールバック
4. Build per-stage `$ENGINE_CMD` using Engine-Specific Command Construction (後述) with the resolved engine/model

5. Report resolved config:
```
Timeout: {$TIMEOUT}s
  Inspectors: {$INSPECTOR_ENGINE} [{$INSPECTOR_MODEL or "default"}]
  Auditor: {$AUDITOR_ENGINE} [{$AUDITOR_MODEL or "default"}]
```

## Step 1: Phase Gate

**Design Review**: `design.md` 存在確認。`phase` が `design-generated` or `implementation-complete`。`blocked` → BLOCK。
**Implementation Review**: `design.md` + `tasks.yaml` 存在確認。`phase` が `implementation-complete`。`blocked` → BLOCK。
**Dead-Code Review**: Phase gate なし (codebase 全体)。Roadmap 存在のみ確認。

## Step 2: Inspector Set Resolution

Review type に応じて Inspector リストを決定:

### Design Review
Base (6): `sdd-inspector-rulebase`, `sdd-inspector-testability`, `sdd-inspector-architecture`, `sdd-inspector-consistency`, `sdd-inspector-best-practices`, `sdd-inspector-holistic`

Auditor: `sdd-auditor-design`

### Implementation Review
Base (6): `sdd-inspector-impl-rulebase`, `sdd-inspector-interface`, `sdd-inspector-test`, `sdd-inspector-quality`, `sdd-inspector-impl-consistency`, `sdd-inspector-impl-holistic`

Conditional:
- `sdd-inspector-e2e`: `steering/tech.md` Common Commands に `# E2E` + 非空・非 placeholder コマンドが存在する場合
- `sdd-inspector-web-e2e` + `sdd-inspector-web-visual`: `steering/tech.md` に web stack indicators (React, Next.js, Vue, Angular, Svelte, Express, Django+templates, Rails, FastAPI+frontend 等) が存在する場合

Auditor: `sdd-auditor-impl`

### Dead-Code Review
Base (4): `sdd-inspector-dead-settings`, `sdd-inspector-dead-code`, `sdd-inspector-dead-specs`, `sdd-inspector-dead-tests`

Auditor: `sdd-auditor-dead-code`

## Step 3: Scope Directory + B{seq}

Review scope directory を決定:

| Scope | Directory |
|-------|-----------|
| Per-feature (design/impl with feature) | `{{SDD_DIR}}/project/specs/{feature}/reviews/` |
| Dead-code (standalone) | `{{SDD_DIR}}/project/reviews/dead-code/` |
| Dead-code (Wave QG context) | `{{SDD_DIR}}/project/reviews/wave/` |
| Cross-check (`--cross-check`) | `{{SDD_DIR}}/project/reviews/cross-check/` |
| Wave-scoped (`--wave N`) | `{{SDD_DIR}}/project/reviews/wave/` |
| Cross-cutting (from revise.md) | `{{SDD_DIR}}/project/specs/.cross-cutting/{id}/` |

B{seq} 決定: `{scope-dir}/verdicts.md` を Read し、最大 batch 番号を +1。なければ 1。

`{scope-dir}/active/` を作成 (既存があれば削除してから再作成)。

## Step 4: Context Preamble Generation

### 4.1 Shared Preamble

テンプレート `{{SDD_DIR}}/settings/templates/review/context-preamble.md` を `{scope-dir}/active/shared-preamble.md` にコピーし、shared プレースホルダーを sed で展開:

```
sed "s|{{REVIEW_TYPE}}|{value}|g; s|{{FEATURE}}|{value}|g; s|{{SCOPE}}|{value}|g; s|{{VERDICTS_PATH}}|{scope-dir}/verdicts.md|g" {template} > {scope-dir}/active/shared-preamble.md
```

`{{WEB_SERVER_URL}}` は Step 5a で値が確定した後に展開する (web inspector がない場合は空文字で展開)。

### 4.2 Per-Inspector Output Path

外部エンジン dispatch 時のみ必要。SubAgent mode では dispatch prompt に直接含める。

各 Inspector について `{{OUTPUT_PATH}}` を展開した preamble を `{scope-dir}/active/preamble-{inspector-name}.md` に生成。**`;` 連結のワンライナー** (for ループ禁止):

```
Bash: sed "s|...|...|g" shared > preamble-inspector1.md; sed "s|...|...|g" shared > preamble-inspector2.md; ...
```

### 4.3 Agent Profile Copy (外部エンジン時のみ)

外部エンジンは Agent ファイルをそのままプロンプトとして使う (テンプレート二重管理回避)。
`$INSPECTOR_ENGINE != "subagents"` の場合、各 Inspector の agent profile を `active/` にコピー:

```
cp .claude/agents/{inspector-name}.md {scope-dir}/active/
```

**複数 Inspector は `;` 連結のワンライナー** (for ループ禁止):
```
Bash: cp .claude/agents/sdd-inspector-rulebase.md {scope-dir}/active/; cp .claude/agents/sdd-inspector-testability.md {scope-dir}/active/; ...
```

Auditor も同様: `$AUDITOR_ENGINE != "subagents"` の場合、同じワンライナーに `cp .claude/agents/{auditor-name}.md {scope-dir}/active/` を追加。

### 4.4 Auditor Preamble Generation

テンプレート `{{SDD_DIR}}/settings/templates/review/auditor-preamble.md` を `{scope-dir}/active/preamble-{auditor-name}.md` にコピーし、プレースホルダーを sed で展開:

```
sed "s|{{REVIEW_TYPE}}|{value}|g; s|{{FEATURE}}|{value}|g; s|{{SCOPE}}|{value}|g; s|{{REVIEW_DIR}}|{scope-dir}/active/|g; s|{{VERDICT_PATH}}|{scope-dir}/active/verdict.cpf|g" {template} > {scope-dir}/active/preamble-{auditor-name}.md
```

`{{SELFCHECK_CONTEXT}}` の展開:
- **impl review**: `sed -i '' "s|{{SELFCHECK_CONTEXT}}|Read .sdd/project/specs/{feature}/tasks.yaml for WARN-flagged items as attention points.|g" ...`
- **design / dead-code review**: `sed -i '' "s|{{SELFCHECK_CONTEXT}}||g" ...`

## Step 5: Inspector Dispatch

### Step 5a: Web Server Lifecycle (impl review, web projects only)

Web inspectors (`sdd-inspector-web-e2e`, `sdd-inspector-web-visual`) を含む場合、Inspector dispatch **前に** dev server を起動。

**Server Lifecycle pattern** (from `{{SDD_DIR}}/settings/rules/tmux-integration.md`):
1. `steering/tech.md` Common Commands の `Dev:` entry からコマンド取得
2. Dev server command がない → skip (web inspectors は "Server URL not accessible" で graceful termination)
3. Server 起動 (tmux pane or background Bash)
4. Ready pattern: `ready`, `localhost`, `listening on`
5. Server URL を記録 → shared-preamble の `{{WEB_SERVER_URL}}` を展開:
   ```
   sed -i '' "s|{{WEB_SERVER_URL}}|Web server URL: {url}|g" {scope-dir}/active/shared-preamble.md
   ```
   Web inspector がない場合: `sed -i '' "s|{{WEB_SERVER_URL}}||g" ...`

6. Per-inspector preamble を再生成 (shared-preamble が更新されたため、Step 4.2 を再実行)

### Step 5b: Grid Setup (tmux mode, 外部エンジン時のみ)

全ステージが subagents の場合はスキップ。

`$TMUX` 設定あり かつ (`$INSPECTOR_ENGINE != "subagents"` or `$AUDITOR_ENGINE != "subagents"`):

1. `printenv TMUX_PANE` → `$MY_PANE`
2. SID 取得: Lead pane タイトルから抽出。`sdd-*-lead` パターンでない場合 → `date +%H%M%S` で生成
3. MultiView グリッド確認: `sdd-{SID}-slot-*` を検索。なければ `bash {{SDD_DIR}}/settings/scripts/multiview-grid.sh $SID $MY_PANE` で作成

### Step 5c: Inspector Dispatch

分岐順序: SubAgent → tmux → background。

**SubAgent mode** (`$INSPECTOR_ENGINE == "subagents"`):

全 Inspector を並行 dispatch (単一メッセージで parallel tool call)。各 task-notification で個別に完了を検知。
```
Agent(subagent_type="sdd-inspector-{name}", run_in_background=true, prompt="{context preamble}")
```

Context preamble (dispatch prompt に直接含める):
```
Review: {REVIEW_TYPE}
Feature: {FEATURE} | Scope: {SCOPE}
Output: {scope-dir}/active/{inspector-name}.cpf
```
追加コンテキスト (該当する場合):
- Wave-scoped: "Read `{verdicts-path}` for previously resolved issues. Do NOT re-flag resolved items."
- Impl review selfcheck: "Read `{spec-dir}/tasks.yaml` for WARN-flagged items as attention points."
- Steering exceptions: "Read `.sdd/handover/session.md`, apply Steering Exceptions as review exemptions."
- Web inspectors: `Web server URL: {url}`

Inspector は self-loading — feature 名と output path を渡せば、自分で steering, design.md, tasks.yaml 等を Read する。

**tmux mode** (`$INSPECTOR_ENGINE != "subagents"` かつ `$TMUX` 設定あり):

MultiView スロットに `send-keys` で agent コマンドを投入 (Hold-and-Release パターン):
```
tmux send-keys -t {slot_pane_id} 'cat {scope-dir}/active/preamble-{name}.md {scope-dir}/active/{name}.md | {$INSPECTOR_ENGINE_CMD}; tmux wait-for -S sdd-{SID}-review-{name}-B{seq}; tmux wait-for sdd-{SID}-close-B{seq}' Enter
```

Staggered parallel dispatch (0.5 秒刻み) で全 Inspector を一括投入:
```
Bash(run_in_background=true): sleep 0.0; tmux send-keys -t {pane1} '...' Enter
Bash(run_in_background=true): sleep 0.5; tmux send-keys -t {pane2} '...' Enter
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
Bash(run_in_background=true): cat {scope-dir}/active/preamble-{name}.md {scope-dir}/active/{name}.md | {$INSPECTOR_ENGINE_CMD}
```
全 Inspector を並列 `Bash(run_in_background=true)` で実行。各 task-notification で個別に完了を検知。

### Step 5d: Wait + Collect

全 Inspector 完了後 (全 task-notification 受信):

1. 各 `{scope-dir}/active/{inspector-name}.cpf` の存在とサイズを確認 (`ls -la`) — **Lead は CPF の内容を Read しない**
2. CPF 未出力 Inspector → SubAgent Fallback (後述) を試行
3. `VERDICT:ERROR` は Auditor context に含める

### Step 5e: Web Server Stop (impl review, web projects only)

全 Inspector 完了後、Auditor dispatch 前に dev server を停止。

### Step 5f: Slot Release (tmux mode)

SubAgent mode ではスキップ。tmux mode:
`tmux wait-for -S sdd-{SID}-close-B{seq}` → 全スロットのブロック解除。

## Step 6: Auditor Dispatch

分岐順序: SubAgent → tmux → background。

**SubAgent mode** (`$AUDITOR_ENGINE == "subagents"`):

```
Agent(subagent_type="sdd-auditor-{type}", run_in_background=true, prompt="
Review type: {REVIEW_TYPE}
Feature: {FEATURE}
Scope: {SCOPE}

Review directory: {scope-dir}/active/
Read all .cpf files from this directory.

Verdict output: {scope-dir}/active/verdict.cpf
Write your verdict to this path.

Read .sdd/handover/session.md, apply Steering Exceptions as review exemptions.
{selfcheck line}
")
```

`{selfcheck line}` (impl review のみ):
`Read .sdd/project/specs/{feature}/tasks.yaml for WARN-flagged items as attention points.`

Auditor は self-loading — review directory パスと verdict output パスを渡せば、自分で .cpf を Read して統合する。task-notification で完了を検知。

**tmux mode** (`$AUDITOR_ENGINE != "subagents"` かつ `$TMUX` 設定あり):
```
tmux send-keys -t {slot_pane_id} 'cat {scope-dir}/active/preamble-{auditor-name}.md {scope-dir}/active/{auditor-name}.md | {$AUDITOR_ENGINE_CMD}; tmux wait-for -S sdd-{SID}-review-auditor-B{seq}' Enter
```
`Bash(run_in_background=true)` で `tmux wait-for sdd-{SID}-review-auditor-B{seq}` を実行。task-notification で完了を検知。

**background mode** (上記以外):
`Bash(run_in_background=true)` で `cat {scope-dir}/active/preamble-{auditor-name}.md {scope-dir}/active/{auditor-name}.md | {$AUDITOR_ENGINE_CMD}` を実行。task-notification で完了を検知。

完了後: `{scope-dir}/active/verdict.cpf` の存在を確認。未出力 → SubAgent Fallback を試行。

## Engine-Specific Command Construction

各ステージの engine に応じて `$INSPECTOR_ENGINE_CMD` / `$AUDITOR_ENGINE_CMD` を組み立てる。`$TOOLS` が null → 全許可モード、設定あり → ツール制限モード。

stdout はリダイレクトしない — pane に進捗が流れる。成果物は CPF ファイルのみ。

**codex**:
```
npx -y @openai/codex exec --full-auto [--model ${STAGE}_MODEL] -
```

**claude** (`env -u CLAUDECODE` で Lead ネスト検出を回避):
```
env -u CLAUDECODE claude -p - --dangerously-skip-permissions --output-format stream-json --verbose --include-partial-messages [--model ${STAGE}_MODEL] | jq -rjf .sdd/settings/scripts/claude-stream-progress.jq
```
ツール制限時: `--dangerously-skip-permissions` を `--allowedTools "$TOOLS"` に置換。

**gemini**:
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

## SubAgent Fallback (外部エンジン失敗時)

外部エンジンで CPF/verdict 未生成の場合に発動。

### Inspector SubAgent Fallback

`$INSPECTOR_ENGINE != "subagents"` かつ CPF 未生成の Inspector がある場合:
1. 失敗 Inspector を `Agent(subagent_type="sdd-inspector-{name}", model="sonnet", run_in_background=true, prompt="{context preamble}")` で再 dispatch。task-notification で完了を検知
2. CPF 存在を再チェック。それでも不在 → Auditor に "Inspector {name} unavailable" を通知

`$INSPECTOR_ENGINE == "subagents"` → フォールバック先なし、即失敗扱い。

### Auditor SubAgent Fallback

`$AUDITOR_ENGINE != "subagents"` かつ verdict.cpf 未生成の場合:
1. `Agent(subagent_type="sdd-auditor-{type}", model="sonnet", run_in_background=true, prompt="{auditor context}")` で再 dispatch。task-notification で完了を検知
2. それでも失敗 → "Auditor failed. Manual review required." を報告し停止

## Step 7: Verdict Read + Persist + Archive

1. Read `{scope-dir}/active/verdict.cpf`
2. Verdict を `{scope-dir}/verdicts.md` に永続化:
   a. 既存ファイル Read (なければ `# Verdicts: {feature}` ヘッダーで作成)
   b. Batch entry header 追加:
      - Per-feature/standalone: `## [B{seq}] {review-type} | {ISO-8601} | v{version}`
      - Wave QG cross-check: `## [W{wave}-B{seq}] ...`
      - Wave QG dead-code: `## [W{wave}-DC-B{seq}] ...`
   c. Raw section (Auditor CPF verbatim)
   d. Disposition (`GO-ACCEPTED`, `CONDITIONAL-TRACKED`, `NO-GO-FIXED`, `SPEC-UPDATE-CASCADED`, `ESCALATED`)
   e. CONDITIONAL: M/L issues → Tracked section
   f. 前 batch に Tracked → compare → `Resolved since B{prev}`
3. Archive: rename `{scope-dir}/active/` → `{scope-dir}/B{seq}/`

## Step 8: Standalone Verdict Handling

Standalone 呼び出し時 (run/revise pipeline 外):
1. Formatted verdict report を user に表示
2. **Auto-fix なし**: verdict 報告のみ。Auto-fix loop は pipeline orchestration (run.md / revise.md) のみ
3. **STEERING entries 処理**:
   - `CODIFY|{file}|{decision}` → `steering/{file}` を直接更新 + decisions.md に STEERING_UPDATE append
   - `PROPOSE|{file}|{decision}` → user に提示。承認 → 更新 + STEERING_UPDATE。却下 → STEERING_EXCEPTION or USER_DECISION
4. Auto-draft `{{SDD_DIR}}/handover/session.md`

### Next Steps by Verdict (standalone)
- Design GO/CONDITIONAL → suggest `/sdd-roadmap impl {feature}`
- Impl GO/CONDITIONAL → feature complete
- NO-GO → report findings to user
- SPEC-UPDATE-NEEDED → report to user

## Error Handling

- **Engine not installed**: `install_check` 失敗 → subagents にフォールバック
- **Claude nesting guard**: `env -u CLAUDECODE` で起動。なしでは "cannot be launched inside another Claude Code session" エラー
- **Inspector failure**: CPF 不在 → SubAgent Fallback 試行。2 回失敗 → "Inspector {name} unavailable" として Auditor に通知
- **Auditor failure**: verdict.cpf 不在 → SubAgent Fallback 試行。2 回失敗 → 停止
- **Timeout**: `$TIMEOUT` 超過時は部分結果を確認。なければ該当 Agent を失敗扱い
- **Slot safety**: MultiView スロットは kill しない。Timeout 時は `C-c` を send-keys で停止
- **No findings**: Report "No issues detected." with confirmation checklist
- **Inspector ERROR CPF**: C-level findings → Auditor にエラーコンテキスト + C findings を渡す

</instructions>
