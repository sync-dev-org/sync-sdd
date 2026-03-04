---
description: "Self-review for SDD framework development (framework-internal use only)"
argument-hint: "[--engine codex|claude|gemini|subagents] [--model <model-name>] [--timeout <seconds>] [--pipeline lead|agent]"
allowed-tools: Bash, Read, Glob, Grep, Write
---

# SDD Framework Self-Review

<instructions>

## Purpose

外部エンジン (Codex CLI / Claude Code headless / Gemini CLI) または SubAgent (Claude Code Agent tool) を使った self-review スキル。4 Agent を並行実行する。

## Step 0: Load Engine Config

### 0.1 Parse Arguments

引数からオーバーライドを抽出:
- `--engine <name>`: エンジン指定 (`codex`, `claude`, `gemini`, `subagents`)
- `--model <name>`: モデル指定 (e.g., `claude-sonnet-4-6`, `gpt-5.3-codex`)
- `--timeout <seconds>`: タイムアウト秒数
- `--pipeline <mode>`: パイプラインモード (`lead`, `agent`)

引数なし → engines.yaml のデフォルトを使用。引数あり → engines.yaml の値を上書き。

例: `/sdd-review-self --engine claude --model claude-sonnet-4-6`
例: `/sdd-review-self --pipeline agent`

### 0.2 Load engines.yaml (Base Config)

1. Read `.sdd/settings/engines.yaml`
   - If absent: copy from `.sdd/settings/templates/engines.yaml` → `.sdd/settings/engines.yaml`, then read. Report: `engines.yaml をデフォルトで作成しました。/sdd-steering engines でカスタマイズ可能です。`
   - If template also absent: use hardcoded defaults (engine: codex, timeout: 900)
2. Load `deny_patterns` → `$DENY_PATTERNS`

### 0.3 Resolve Final Config

優先順位 (高→低): **引数** > `roles.review-self` > `defaults`

| Variable | Resolution |
|----------|-----------|
| `$ENGINE_NAME` | `--engine` arg → `roles.review-self.engine` → `defaults.engine` |
| `$MODEL` | `--model` arg → `roles.review-self.model` → null (engine default) |
| `$TIMEOUT` | `--timeout` arg → `roles.review-self.timeout` → `defaults.timeout` |
| `$TOOLS` | `roles.review-self.tools` → null (full permission) |
| `$PIPELINE` | `--pipeline` arg → `roles.review-self.pipeline` → `agent` |

3. Load engine traits from `engines.{$ENGINE_NAME}` → `install_check`
4. Verify engine available: run `install_check` command; if fails, report and stop

**Per-stage overrides** (agent pipeline only):
If `roles.review-self.stages` exists, resolve per-stage engine/model. Resolution: `stages.{stage}` → base (`$ENGINE_NAME`/`$MODEL`).

| Stage Variable | Resolution |
|---------------|-----------|
| `$PREP_ENGINE` / `$PREP_MODEL` | `stages.prep.{engine,model}` → `$ENGINE_NAME` / `$MODEL` |
| `$INSPECTOR_ENGINE` / `$INSPECTOR_MODEL` | `stages.inspectors.{engine,model}` → `$ENGINE_NAME` / `$MODEL` |
| `$AUDITOR_ENGINE` / `$AUDITOR_MODEL` | `stages.auditor.{engine,model}` → `$ENGINE_NAME` / `$MODEL` |

Build per-stage `$ENGINE_CMD` using Engine-Specific Command Construction (Step 5) with the resolved engine/model.
If a stage uses a different engine from base, verify that engine's `install_check` as well.

In lead pipeline, per-stage overrides are ignored — all stages use base `$ENGINE_CMD`.

5. Determine `$BATCH_SEQ`: Read `$SCOPE_DIR/verdicts.md`, find max `B{N}` → `$BATCH_SEQ` = N+1. If absent → 1. This is used for tmux channel names to prevent cross-batch collisions. (Note: `$SCOPE_DIR` is defined in Steps 1-3 section below.)

6. Report resolved config:
```
Engine: {$ENGINE_NAME} [{$MODEL or "default"}] | Timeout: {$TIMEOUT}s | Pipeline: {$PIPELINE}
  Prep: {$PREP_ENGINE} [{$PREP_MODEL or "default"}]
  Inspectors: {$INSPECTOR_ENGINE} [{$INSPECTOR_MODEL or "default"}]
  Auditor: {$AUDITOR_ENGINE} [{$AUDITOR_MODEL or "default"}]
```
Omit per-stage lines if all stages match base config.

### Pipeline Mode

`$PIPELINE` determines work distribution:
- **lead**: Lead executes Steps 1-3 (prompt construction) and Step 7 (consolidation) inline
- **agent** (default): Prep Agent handles Steps 1-3, Auditor Agent handles Step 7. Lead only orchestrates dispatch and presents results

## Steps 1-3: Prompt Construction

```
$SCOPE_DIR = {{SDD_DIR}}/project/reviews/self
$TPL = .claude/skills/sdd-review-self/refs
```

**Agent Pipeline** (`$PIPELINE=agent`): Steps 1-3 are delegated to the Prep Agent. Skip to [Prep Agent Dispatch](#prep-agent-dispatch), then proceed to Step 4.

**Lead Pipeline** (`$PIPELINE=lead`): Execute Steps 1-3 below inline.

### Step 1: Collect Change Context

1. `git diff HEAD~10..HEAD --stat -- framework/ install.sh` → 変更ファイルリスト
2. `git diff HEAD -- framework/ install.sh` → 未コミット変更

変更なし かつ 未コミット差分なし → "No changes since last review." を報告して停止。

変更内容を分析し `$FOCUS_TARGETS` (3-5 bullet points) を作成。

### Step 2: Prepare

1. `rm -rf $SCOPE_DIR/active && mkdir -p $SCOPE_DIR/active`
   前回の残骸を確実にクリーンアップしてから開始。stale CPF による偽成功を防止。

#### Review Scope

Glob ツールで以下を収集 → `$FILE_LIST`:

```
framework/claude/CLAUDE.md
framework/claude/skills/sdd-*/SKILL.md
framework/claude/skills/sdd-*/refs/*.md
framework/claude/agents/sdd-*.md
framework/claude/settings.json
framework/claude/sdd/settings/rules/*.md
framework/claude/sdd/settings/templates/**/*.md
framework/claude/sdd/settings/templates/**/*.yaml
framework/claude/sdd/settings/scripts/*.sh
install.sh
```

#### Prompt File Construction

**shared + per-agent テンプレート方式**。per-agent プロンプトは事前テンプレートから生成し、Lead のトークン生成コストを削減する。

**shared prompt** (`$SCOPE_DIR/active/shared-prompt.txt`):
Lead が Write で生成する唯一のファイル。全 Agent 共通の内容:
- `$FILE_LIST` (Target Files)
- CPF format specification
- Deny Patterns

```
## Target Files
{$FILE_LIST}

## CPF Format
Write findings in CPF (Compact Pipe-Delimited Format):
- Metadata lines: KEY:VALUE (no space around colon)
- Section header: ISSUES: followed by one record per line
- Issue format: SEVERITY|category|location|description
- Severity codes: C=Critical, H=High, M=Medium, L=Low
- Report ALL severity levels including LOW. A review with zero LOW findings is suspicious — verify you haven't self-filtered.
- Omit empty sections

Report findings in Japanese.

## PROHIBITED COMMANDS (MUST NEVER execute)
{$DENY_PATTERNS を改行区切りで列挙}
```

**per-agent prompts** (`$SCOPE_DIR/active/agent-{N}-{name}.md`):
テンプレートからコピー + `sed` でプレースホルダを置換して生成する。

1. 全テンプレートを active/ にコピー:
   `cp $TPL/agent-*.md $SCOPE_DIR/active/`

2. 全ファイルの `{{SCOPE_DIR}}` を実パスに一括置換:
   `sed -i '' 's|{{SCOPE_DIR}}|{実際の $SCOPE_DIR}|g' $SCOPE_DIR/active/agent-*.md`

3. Agent 2 (agent-2-changes.md) の `{{FOCUS_TARGETS}}` を置換:
   `sed -i '' 's|{{FOCUS_TARGETS}}|{$FOCUS_TARGETS の内容}|g' $SCOPE_DIR/active/agent-2-changes.md`

   **Note**: `{{FOCUS_TARGETS}}` と `{{CACHED_OK}}` の値は sed-safe であること（改行、`&`、`|`、パイプ区切り文字を含まない）。

4. Agent 4 (agent-4-compliance.md) の `{{CACHED_OK}}` を置換:
   `sed -i '' 's|{{CACHED_OK}}|{$CACHED_OK の内容}|g' $SCOPE_DIR/active/agent-4-compliance.md`

**エンジン起動時**: `cat shared-prompt.txt agent-{N}-{name}.md | $ENGINE_CMD` で結合して stdin に渡す。

### Step 3: Build Compliance Cache

Read `$SCOPE_DIR/verdicts.md`.
Find the most recent Agent 4 (Platform Compliance) result within the last 7 days.

If found:
1. Read the archived CPF (`$SCOPE_DIR/B{seq}/agent-4-compliance.cpf`)
2. Extract `COMPLIANT:` セクションの items → `$CACHED_OK` list
3. For each cached item, check if the relevant file has been modified since that review date (use git log)
4. Items with no file changes → remain in `$CACHED_OK`
5. Items with file changes → remove from `$CACHED_OK` (will be re-verified)

If not found or older than 7 days: `$CACHED_OK` = empty.

### Prep Agent Dispatch

**Agent Pipeline のみ**。`$PIPELINE=lead` の場合はこのセクションをスキップ。

1. `rm -rf $SCOPE_DIR/active && mkdir -p $SCOPE_DIR/active`
2. Prep テンプレートを active/ にコピー:
   `cp $TPL/prep.md $SCOPE_DIR/active/prep.md`
3. プレースホルダを置換:
   `sed -i '' 's|{{SCOPE_DIR}}|{実際の $SCOPE_DIR}|g' $SCOPE_DIR/active/prep.md`
   `sed -i '' 's|{{SDD_DIR}}|{実際の {{SDD_DIR}}}|g' $SCOPE_DIR/active/prep.md`
   `sed -i '' 's|{{TPL_DIR}}|{実際の $TPL}|g' $SCOPE_DIR/active/prep.md`
4. Prep Agent を dispatch:
   **SubAgent mode** (`$PREP_ENGINE == "subagents"`):
   Read `$SCOPE_DIR/active/prep.md` の内容 → `Agent(subagent_type="general-purpose", model=$PREP_MODEL_MAPPED, run_in_background=true, prompt=<内容>)`
   完了待ち: `TaskOutput(block=true)`
   **tmux mode** (`$TMUX` 設定あり):
   ```
   tmux send-keys -t {slot_pane_id} 'cat {$SCOPE_DIR}/active/prep.md | {$PREP_ENGINE_CMD}; tmux wait-for -S sdd-{SID}-review-self-prep-B{seq}' Enter
   ```
   send-keys ゾンビ確認: `pgrep -fl "tmux send-keys"` → 検出時はユーザーに報告し kill
   完了待ち: `tmux wait-for sdd-{SID}-review-self-prep-B{seq}` (background)
   **Fallback mode** (上記以外):
   `Bash(run_in_background=true)` で `cat prep.md | $PREP_ENGINE_CMD` を実行。完了待ち。
7. 完了後の検証:
   - `$SCOPE_DIR/active/prep-status.txt` が `NO_CHANGES` → "No changes since last review." を報告して停止
   - 5 ファイル (shared-prompt.txt, agent-1〜4) の存在を確認
   - いずれか欠損 → Prep Agent 失敗。Lead Pipeline にフォールバックして Steps 1-3 を inline 実行
8. Step 4 へ進む

## Step 4: Grid Setup (tmux mode only)

`$ENGINE_NAME == "subagents"` の場合はこのステップをスキップ（Agent ツール dispatch に tmux 不要）。

`$TMUX` が設定されている場合のみ実行:
1. `tmux display-message -p '#{pane_id}'` → `$MY_PANE`
2. SID 取得: Lead pane タイトルから抽出 (`tmux display-message -p '#{pane_title}'` → `sdd-{SID}-lead` → `$SID`)。Lead タイトルが `sdd-*-lead` パターンでない場合 → `date +%H%M%S` で生成し、`tmux select-pane -T 'sdd-{SID}-lead'` で設定。

MultiView グリッド確認:
3. List Panes → `sdd-{SID}-slot-*` を Grep
4. グリッドあり → idle スロットの pane ID リストを取得
5. グリッドなし → `bash {{SDD_DIR}}/settings/scripts/multiview-grid.sh $SID $MY_PANE` で作成。出力から slot pane ID を parse

`$TMUX` 未設定の場合はスキップして Step 5 Fallback mode へ。

## Step 5: Parallel Dispatch (4 Agents)

Apply **One-Shot Command pattern** from `{{SDD_DIR}}/settings/rules/tmux-integration.md`.

4 つの外部エンジンインスタンスを並行起動する。各 Agent:
- Channel = `sdd-{SID}-review-self-{N}-B{seq}` (`$SID` は Step 4 で生成したセッション固有 ID)。スロットの pane title (`sdd-{SID}-slot-{N}`) は変更しない。
- Prompt file = `$SCOPE_DIR/active/agent-{N}-{name}.md`
- CPF file (成果物) = `$SCOPE_DIR/active/agent-{N}-{name}.cpf`

### Engine-Specific Command Construction

Assemble command based on `$ENGINE_NAME`. `$TOOLS` が null の場合は全許可モード、設定されている場合はツール制限モード:

全エンジン共通: stdout はリダイレクトしない — pane に応答テキスト / 進捗が流れる。成果物は CPF ファイルのみ。完了は `tmux wait-for` / background task で検出し、成功判定は CPF ファイル存在チェックで行う。

エンジンバイナリ (`$ENGINE_CMD`) を組み立てる。Inspector dispatch では `$INSPECTOR_ENGINE_CMD` を使用（lead pipeline 時は base `$ENGINE_CMD`）。send-keys では `cat {shared} {agent-N} | $INSPECTOR_ENGINE_CMD` の形でプロンプトを stdin に渡す。

**codex**: `$ENGINE_CMD` =
```
npx -y @openai/codex exec --full-auto [--model $MODEL] -
```

**claude** (`env -u CLAUDECODE` で Lead セッションからのネスト検出を回避): `$ENGINE_CMD` =
```
env -u CLAUDECODE claude -p - --dangerously-skip-permissions [--model $MODEL]
```
ツール制限時: `--dangerously-skip-permissions` を `--allowedTools "$TOOLS"` に置換。

**gemini**: `$ENGINE_CMD` =
```
npx -y @google/gemini-cli -p "Review the project files per the instructions below." --yolo [--model $MODEL]
```
ツール制限時: `--yolo` を `--sandbox` に置換。

`[]` 内は対応する値が設定されている場合のみ付与。

**subagents**: CLI command は不要。Agent ツール (`Agent(subagent_type="general-purpose")`) で dispatch する。
プロンプトは `shared-prompt.txt` + `agent-{N}.md` の内容を Read で読み込み、結合して `prompt` パラメータに渡す。
Model mapping (engines.yaml の model 値 → Agent tool `model` パラメータ):
- `*spark*` or `*haiku*` を含む → `"haiku"`
- `*opus*` を含む → `"opus"`
- その他 → `"sonnet"` (デフォルト)

### Dispatch Mode

**tmux mode** (`$TMUX` 設定あり):
各 Bash 呼び出しを `tmux` で開始することで `Bash(tmux *)` パターンにマッチさせ、承認を不要にする。

MultiView スロットに `send-keys` で agent コマンドを投入する (Hold-and-Release パターン)。idle スロットから 4 つ選択し、各 Agent の command chain を投入:

```
tmux send-keys -t {slot_pane_id} 'cat {shared} {agent-N} | {$INSPECTOR_ENGINE_CMD}; tmux wait-for -S sdd-{SID}-review-self-{N}-B{seq}; tmux wait-for sdd-{SID}-close-B{seq}' Enter
```

**tmux throttle**: 各 `send-keys` の間に `sleep 1` を挟む（tmux が短時間のコマンド連発で詰まるのを防止）。

4 Agent 分の `send-keys` を発行後:
1. send-keys ゾンビ確認: `pgrep -fl "tmux send-keys"` → 検出時はユーザーに報告し kill
2. 4 つの `tmux wait-for sdd-{SID}-review-self-{N}-B{seq}` を background Bash で並行発行し、全 Agent 完了を待つ。各 `wait-for` の間にも `sleep 1` を挟む。

パスは変数を使わずインラインで記述する（`Bash(tmux *)` マッチのため）。

**Fallback mode** (`$TMUX` 未設定 かつ `$ENGINE_NAME != "subagents"`):
4 つの `Bash(run_in_background=true)` で並行実行。CPF はファイル書き出しで取得。

**SubAgent mode** (`$ENGINE_NAME == "subagents"`):
tmux/Bash の代わりに Agent ツールで dispatch。`$TMUX` の有無に関わらずこのモードを使用する。

各 Inspector の dispatch:
1. Read `$SCOPE_DIR/active/shared-prompt.txt` の内容 → `$SHARED`
2. Read `$SCOPE_DIR/active/agent-{N}-{name}.md` の内容 → `$AGENT_N`
3. `Agent(subagent_type="general-purpose", model=$INSPECTOR_MODEL_MAPPED, run_in_background=true, prompt=$SHARED + "\n\n" + $AGENT_N)`

4 Agent を一括 dispatch (単一メッセージで 4 つの Agent tool call を並列発行)。

完了待ち: 各 Agent の TaskOutput(block=true) で完了を待つ。CPF ファイル存在チェックは外部エンジンと同一。

Hold-and-Release は不要 — Agent は完了時に自動的にリソースを解放する。

### Agent Prompts (Templates)

Agent 1-4 のプロンプト内容はテンプレートファイルに定義。変更はテンプレートを編集すること:

| Agent | Template | Placeholders | Pipeline |
|-------|----------|-------------|----------|
| Prep | `$TPL/prep.md` | `{{SCOPE_DIR}}`, `{{SDD_DIR}}`, `{{TPL_DIR}}` | agent only |
| 1 (Flow Integrity) | `$TPL/agent-1-flow.md` | `{{SCOPE_DIR}}` | both |
| 2 (Change-Focused) | `$TPL/agent-2-changes.md` | `{{SCOPE_DIR}}`, `{{FOCUS_TARGETS}}` | both |
| 3 (Consistency) | `$TPL/agent-3-consistency.md` | `{{SCOPE_DIR}}` | both |
| 4 (Compliance) | `$TPL/agent-4-compliance.md` | `{{SCOPE_DIR}}`, `{{CACHED_OK}}` | both |
| Auditor | `$TPL/auditor.md` | `{{SCOPE_DIR}}`, `{{SDD_DIR}}`, `{{ENGINE_INFO}}` | agent only |

全テンプレートで `{{PLACEHOLDER}}` 形式に統一（フレームワーク全体と同じ記法）。Prep テンプレート内で agent テンプレートのプレースホルダーを参照する箇所は文字列分割表記 (`{{SCOPE` + `_DIR}}`) で Lead の sed との衝突を回避。

---

## Step 6: Collect Results

全 Agent 完了後 (tmux wait-for / background task / SubAgent TaskOutput 完了):

1. 各 `$SCOPE_DIR/active/agent-{N}-{name}.cpf` の存在を確認 → 成功/失敗を判定
2. 成功した Agent の CPF ファイルを Read
3. 失敗した Agent (CPF 不在) → SubAgent フォールバック (下記) を試行。フォールバック後も CPF 不在の場合はレポートに注記

### SubAgent Fallback (外部エンジン失敗時)

`$ENGINE_NAME != "subagents"` かつ CPF 未生成の Inspector がある場合に発動。

1. 失敗した Inspector のみを対象にリストアップ
2. 各失敗 Inspector について:
   - Read `$SCOPE_DIR/active/shared-prompt.txt` + `$SCOPE_DIR/active/agent-{N}-{name}.md` の内容を結合
   - `Agent(subagent_type="general-purpose", model="sonnet", run_in_background=true, prompt=<結合内容>)`
3. 全 fallback Agent の TaskOutput(block=true) で完了待ち
4. CPF ファイル存在を再チェック — 成功した Agent の CPF を Read
5. それでも CPF 不在の場合はレポートに注記 (2 回失敗)

`$ENGINE_NAME == "subagents"` の場合はフォールバック先がないため、CPF 不在は即レポートに注記。

### Health Check (tmux mode, subagents 以外)

`pgrep -fl "tmux send-keys"` でゾンビ send-keys プロセスを確認。検出時:
- ユーザーに報告（PID、対象 pane、経過時間）
- ユーザー確認後に `kill {PID}` で除去
- 原因を Error Handling セクションに記録

### Slot Release

SubAgent mode ではスキップ (Agent ツールが自動解放)。tmux mode の場合:
1. `tmux wait-for -S sdd-{SID}-close-B{seq}` → 全 Agent スロットのブロック解除 (Hold-and-Release)
2. command chain 完了後、スロットは idle に戻る（再利用可能）

## Step 7: Consolidation

**Agent Pipeline** (`$PIPELINE=agent`): Step 7 is delegated to the Auditor Agent. Skip to [Auditor Dispatch](#auditor-dispatch), then proceed to Step 8.

**Lead Pipeline** (`$PIPELINE=lead`): Execute Step 7 below inline.

### 7.1 Deduplicate
全 CPF の ISSUES を統合。同一の location + description は重複として 1 件にまとめ、検出 Agent を列挙。

### 7.2 False Positive Check
各 finding について `{{SDD_DIR}}/handover/decisions.md` を確認。意図的な設計決定で説明できるものは FP として除外。

### 7.3 UNCERTAIN Resolution (Agent 4)
Agent 4 (Compliance) の CPF に `UNCERTAIN|...` エントリがある場合、Lead が最終判定する:
1. 対象フィールド/機能を Lead の知識 + 公式ドキュメントで確認
2. 確認できた → FP として除外 (理由を記載)
3. 確認できない → MEDIUM に昇格して finding に含める

### 7.4 Severity Assignment
CPF の severity コードをそのまま使用。重複マージ時は最も高い severity を採用。

- **CRITICAL**: Blocks correct operation. Information loss that prevents Lead from executing a protocol.
- **HIGH**: Inconsistency that could cause Lead to make incorrect decisions.
- **MEDIUM**: Ambiguity or missing detail that may cause confusion but has workarounds.
- **LOW**: Cosmetic, documentation-only, or minor inconsistency.

### Auditor Dispatch

**Agent Pipeline のみ**。`$PIPELINE=lead` の場合はこのセクションをスキップ。

1. Auditor テンプレートを active/ にコピー:
   `cp $TPL/auditor.md $SCOPE_DIR/active/auditor.md`
2. プレースホルダを置換:
   `sed -i '' 's|{{SCOPE_DIR}}|{実際の $SCOPE_DIR}|g' $SCOPE_DIR/active/auditor.md`
   `sed -i '' 's|{{SDD_DIR}}|{実際の {{SDD_DIR}}}|g' $SCOPE_DIR/active/auditor.md`
   `sed -i '' 's|{{ENGINE_INFO}}|{$ENGINE_NAME} [{$MODEL or "default"}]|g' $SCOPE_DIR/active/auditor.md`
3. Auditor を dispatch:
   **SubAgent mode** (`$AUDITOR_ENGINE == "subagents"`):
   Read `$SCOPE_DIR/active/auditor.md` の内容 → `Agent(subagent_type="general-purpose", model=$AUDITOR_MODEL_MAPPED, run_in_background=true, prompt=<内容>)`
   完了待ち: `TaskOutput(block=true)`
   **tmux mode** (`$TMUX` 設定あり):
   ```
   tmux send-keys -t {slot_pane_id} 'cat {$SCOPE_DIR}/active/auditor.md | {$AUDITOR_ENGINE_CMD}; tmux wait-for -S sdd-{SID}-review-self-auditor-B{seq}' Enter
   ```
   完了待ち: `tmux wait-for sdd-{SID}-review-self-auditor-B{seq}` (background)
   **Fallback mode** (上記以外):
   `Bash(run_in_background=true)` で `cat auditor.md | $AUDITOR_ENGINE_CMD` を実行。完了待ち。
5. 完了後の検証:
   - `$SCOPE_DIR/active/report.md` と `$SCOPE_DIR/active/verdict-data.txt` の存在を確認
   - いずれか欠損 → Auditor 失敗。Lead Pipeline にフォールバックして Step 7 を inline 実行
6. `report.md` を Read → Step 8 へ進む

## Step 8: Report Output + Verdict Persistence

### 8.1 Persist Results

1. B{seq} を決定: `$SCOPE_DIR/verdicts.md` の最大バッチ番号 + 1
2. **Lead Pipeline**: consolidated report を `$SCOPE_DIR/active/report.md` に書き出し
   **Agent Pipeline**: Auditor が既に `report.md` を生成済み。`verdict-data.txt` から severity counts と files を読む
3. `$SCOPE_DIR/verdicts.md` にバッチエントリを追記:
   ```
   ## [B{seq}] {ISO-8601} | {ENGINE_NAME} | agents:{completed}/{dispatched}
   C:{n} H:{n} M:{n} L:{n} | FP:{n} eliminated
   Files: {comma-separated list of files with confirmed findings}
   ```
4. Archive: `$SCOPE_DIR/active/` → `$SCOPE_DIR/B{seq}/`

### 8.2 Report to User + Action

Lead の責務はパイプラインモードによらず同一。**提示テンプレートの全フィールドを省略せず出力すること**。

#### Lead 監修 (両パイプライン共通)

1. **FP 判定**: `decisions.md` の全エントリと突合。意図的決定 (USER_DECISION, STEERING_EXCEPTION) で説明できる finding → FP。Auditor が見落とした defer/意図的決定を Lead が補完する
2. **Defer 判定**: 過去に defer 済みの finding が再浮上していないか、decisions.md の該当エントリを引用して確認
3. **最終分類 (A/B)**: 分類基準に照らして検証し、必要に応じて修正

Agent Pipeline では Auditor の `report.md` を監修の入力とする。Lead Pipeline では CPF から直接分類する。いずれの場合も、ユーザーへの提示は以下のテンプレートに従う。

#### 分類基準

**A) 自明な修正** (Auto-fix):
命名不一致、typo、許可漏れ、example 誤り等、判断不要で正解が一意のもの。
→ 一覧表示し、ユーザーの OK 一言で全件修正を実行。

**B) ユーザー判断が必要** (Decision-required):
pre-existing backlog の対処方針、設計レベルの変更、影響範囲が広い修正。
→ 各 finding のフィールドを **すべて埋めて** 提示。「どうしますか？」だけで聞かない。

#### 提示テンプレート (MUST)

Lead はこのテンプレートの全セクション・全フィールドを省略せずユーザーに出力する。要約テーブルへの圧縮は禁止。

```markdown
# SDD Framework Self-Review Report (External Engine)
**Date**: {ISO-8601} | **Engine**: {ENGINE_NAME} [{MODEL}] | **Pipeline**: {lead|agent}
**Agents**: {dispatched} dispatched, {completed} completed

## False Positives Eliminated ({N}件)

| # | Finding | Agent | Reason (decisions.md ref) |
|---|---------|-------|---------------------------|
| 1 | {概要} | {検出Agent} | {FP理由 — D{seq} 参照 or 実動作確認等} |

## A) 自明な修正 ({N}件) — OK で全件修正します

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

## Platform Compliance

| Item | Status | Source |
|------|--------|--------|
| {項目} | {OK/OK (cached)/FP (UNCERTAIN)} | {URL or 確認方法} |
```

## Error Handling

- **Engine not installed**: `install_check` が失敗した場合、エラーメッセージを表示して停止
- **Claude nesting guard**: `CLAUDECODE` 環境変数が設定されている場合 (Lead セッション内)、claude engine は `env -u CLAUDECODE` で起動する必要がある。これなしでは "cannot be launched inside another Claude Code session" エラーで即座に失敗する
- **Agent failure**: レポートに "Agent {N} ({name}) did not complete." と注記。他の Agent の結果は有効
- **Timeout**: `$TIMEOUT` 超過時は部分結果があれば CPF を読む。なければ該当 Agent を失敗扱い
- **CPF not generated**: CPF ファイルが存在しない、または空の場合、SubAgent Fallback を試行 (外部エンジン時のみ)。Fallback 後も不在なら該当 Agent を失敗扱い
- **Slot safety**: MultiView スロットは kill しない。command chain 完了で自動 idle 復帰。Timeout 時はスロットの shell に `C-c` を send-keys で停止
- **SubAgent engine**: `install_check` は常に成功 (`true`)。Agent ツールの dispatch 失敗はフォールバック先がないため即失敗扱い
- **No findings**: Report "No issues detected." with confirmation checklist.
- **Prep Agent failure** (agent pipeline): prompt ファイルが揃わない場合、Lead Pipeline にフォールバックして Steps 1-3 を inline 実行
- **Auditor failure** (agent pipeline): report.md が生成されない場合、Lead Pipeline にフォールバックして Step 7 を inline 実行

</instructions>
