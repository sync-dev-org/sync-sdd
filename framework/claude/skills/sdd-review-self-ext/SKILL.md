---
description: "Self-review (external engine): 4-agent parallel review via external engine"
argument-hint: "[--engine codex|claude|gemini] [--model <model-name>] [--timeout <seconds>]"
allowed-tools: Bash, Read, Glob, Grep, Write
---

# SDD Framework Self-Review (External Engine Edition)

<instructions>

## Purpose

外部エンジン (Codex CLI / Claude Code headless / Gemini CLI) を使った self-review スキル。`sdd-review-self` と同じ 4 Agent を外部エンジンで並行外注する。

## Step 0: Load Engine Config

### 0.1 Parse Arguments

引数からオーバーライドを抽出:
- `--engine <name>`: エンジン指定 (`codex`, `claude`, `gemini`)
- `--model <name>`: モデル指定 (e.g., `claude-sonnet-4-6`, `gpt-5.3-codex`)
- `--timeout <seconds>`: タイムアウト秒数

引数なし → engines.yaml のデフォルトを使用。引数あり → engines.yaml の値を上書き。

例: `/sdd-review-self-ext --engine claude --model claude-sonnet-4-6`

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

3. Load engine traits from `engines.{$ENGINE_NAME}` → `install_check`
4. Verify engine available: run `install_check` command; if fails, report and stop
5. Report resolved config: `Engine: {$ENGINE_NAME} | Model: {$MODEL or "default"} | Timeout: {$TIMEOUT}s`

## Step 1: Collect Change Context

1. `git diff HEAD~10..HEAD --stat -- framework/ install.sh` → 変更ファイルリスト
2. `git diff HEAD -- framework/ install.sh` → 未コミット変更

変更なし かつ 未コミット差分なし → "No changes since last review." を報告して停止。

変更内容を分析し `$FOCUS_TARGETS` (3-5 bullet points) を作成。

## Step 2: Prepare

```
$SCOPE_DIR = {{SDD_DIR}}/project/reviews/self-ext
```

1. `rm -rf $SCOPE_DIR/active && mkdir -p $SCOPE_DIR/active`
   前回の残骸を確実にクリーンアップしてから開始。stale CPF による偽成功を防止。

### Review Scope

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
install.sh
```

### Prompt File Construction

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

```
$TPL = {{SDD_DIR}}/settings/templates/review-self-ext
```

1. 全テンプレートを active/ にコピー:
   `cp $TPL/agent-*.md $SCOPE_DIR/active/`

2. 全ファイルの `${SCOPE_DIR}` を実パスに一括置換:
   `sed -i '' 's|${SCOPE_DIR}|{実際の $SCOPE_DIR}|g' $SCOPE_DIR/active/agent-*.md`

3. Agent 2 (agent-2-changes.md) の `${FOCUS_TARGETS}` を置換:
   `sed -i '' 's|${FOCUS_TARGETS}|{$FOCUS_TARGETS の内容}|g' $SCOPE_DIR/active/agent-2-changes.md`

4. Agent 4 (agent-4-compliance.md) の `${CACHED_OK}` を置換:
   `sed -i '' 's|${CACHED_OK}|{$CACHED_OK の内容}|g' $SCOPE_DIR/active/agent-4-compliance.md`

**エンジン起動時**: `cat shared-prompt.txt agent-{N}-{name}.md | $ENGINE_CMD` で結合して stdin に渡す。

## Step 3: Build Compliance Cache

Read `$SCOPE_DIR/verdicts.md`.
Find the most recent Agent 4 (Platform Compliance) result within the last 7 days.

If found:
1. Read the archived CPF (`$SCOPE_DIR/B{seq}/agent-4-compliance.cpf`)
2. Extract `COMPLIANT:` セクションの items → `$CACHED_OK` list
3. For each cached item, check if the relevant file has been modified since that review date (use git log)
4. Items with no file changes → remain in `$CACHED_OK`
5. Items with file changes → remove from `$CACHED_OK` (will be re-verified)

If not found or older than 7 days: `$CACHED_OK` = empty.

## Step 4: Grid Setup (tmux mode only)

`$TMUX` が設定されている場合のみ実行:
1. `tmux display-message -p '#{pane_id}'` → `$MY_PANE`
2. `$SID` = `$MY_PANE` の `%` を除去 (例: `%5` → `5`)

MultiView グリッド確認:
3. List Panes → `sdd-{SID}-slot-*` を Grep
4. グリッドあり → idle スロットの pane ID リストを取得
5. グリッドなし → `bash {{SDD_DIR}}/settings/scripts/multiview-grid.sh $SID $MY_PANE` で作成。出力から slot pane ID を parse

`$TMUX` 未設定の場合はスキップして Step 5 Fallback mode へ。

## Step 5: Parallel Dispatch (4 Agents)

Apply **One-Shot Command pattern** from `{{SDD_DIR}}/settings/rules/tmux-integration.md`.

4 つの外部エンジンインスタンスを並行起動する。各 Agent:
- Channel = `sdd-{SID}-ext-{N}` (`$SID` は Step 4 で生成したセッション固有 ID)。スロットの pane title (`sdd-{SID}-slot-{N}`) は変更しない。
- Prompt file = `$SCOPE_DIR/active/agent-{N}-prompt.txt`
- CPF file (成果物) = `$SCOPE_DIR/active/agent-{N}-{name}.cpf`

### Engine-Specific Command Construction

Assemble command based on `$ENGINE_NAME`. `$TOOLS` が null の場合は全許可モード、設定されている場合はツール制限モード:

全エンジン共通: stdout はリダイレクトしない — pane に応答テキスト / 進捗が流れる。成果物は CPF ファイルのみ。完了は `tmux wait-for` / background task で検出し、成功判定は CPF ファイル存在チェックで行う。

エンジンバイナリ (`$ENGINE_CMD`) を組み立てる。send-keys では `cat {shared} {agent-N} | $ENGINE_CMD` の形でプロンプトを stdin に渡す。

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

### Dispatch Mode

**tmux mode** (`$TMUX` 設定あり):
各 Bash 呼び出しを `tmux` で開始することで `Bash(tmux *)` パターンにマッチさせ、承認を不要にする。

MultiView スロットに `send-keys` で agent コマンドを投入する (Hold-and-Release パターン)。idle スロットから 4 つ選択し、各 Agent の command chain を投入:

```
tmux send-keys -t {slot_pane_id} 'cat {shared} {agent-N} | {$ENGINE_CMD}; tmux wait-for -S sdd-{SID}-ext-{N}; tmux wait-for sdd-{SID}-close' Enter
```

4 Agent 分の `send-keys` を発行後、4 つの `tmux wait-for sdd-{SID}-ext-{N}` を background Bash で並行発行し、全 Agent 完了を待つ。

パスは変数を使わずインラインで記述する（`Bash(tmux *)` マッチのため）。

**Fallback mode** (`$TMUX` 未設定):
4 つの `Bash(run_in_background=true)` で並行実行。CPF はファイル書き出しで取得。

### Agent Prompts (Templates)

Agent 1-4 のプロンプト内容はテンプレートファイルに定義。変更はテンプレートを編集すること:

| Agent | Template | Placeholders |
|-------|----------|-------------|
| 1 (Flow Integrity) | `$TPL/agent-1-flow.md` | `${SCOPE_DIR}` |
| 2 (Change-Focused) | `$TPL/agent-2-changes.md` | `${SCOPE_DIR}`, `${FOCUS_TARGETS}` |
| 3 (Consistency) | `$TPL/agent-3-consistency.md` | `${SCOPE_DIR}` |
| 4 (Compliance) | `$TPL/agent-4-compliance.md` | `${SCOPE_DIR}`, `${CACHED_OK}` |

---

## Step 6: Collect Results

全 Agent 完了後 (tmux wait-for / background task 完了):

1. 各 `$SCOPE_DIR/active/agent-{N}-{name}.cpf` の存在を確認 → 成功/失敗を判定
2. 成功した Agent の CPF ファイルを Read
3. 失敗した Agent (CPF 不在) はレポートに注記

### Slot Release

tmux mode の場合:
1. `tmux wait-for -S sdd-{SID}-close` → 全 Agent スロットのブロック解除 (Hold-and-Release)
2. command chain 完了後、スロットは idle に戻る（再利用可能）

## Step 7: Consolidation

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

## Step 8: Report Output + Verdict Persistence

### 8.1 Persist Results

1. B{seq} を決定: `$SCOPE_DIR/verdicts.md` の最大バッチ番号 + 1
2. consolidated report を `$SCOPE_DIR/active/report.md` に書き出し
3. `$SCOPE_DIR/verdicts.md` にバッチエントリを追記:
   ```
   ## [B{seq}] {ISO-8601} | {ENGINE_NAME} | agents:{completed}/{dispatched}
   C:{n} H:{n} M:{n} L:{n} | FP:{n} eliminated
   Files: {comma-separated list of files with confirmed findings}
   ```
4. Archive: `$SCOPE_DIR/active/` → `$SCOPE_DIR/B{seq}/`

### 8.2 Report to User + Action

Findings を 2 カテゴリに分類して提示:

**A) 自明な修正** (Auto-fix):
命名不一致、typo、許可漏れ、example 誤り等、判断不要で正解が一意のもの。
→ 一覧表示し、ユーザーの OK 一言で全件修正を実行。

**B) ユーザー判断が必要** (Decision-required):
pre-existing backlog の対処方針、設計レベルの変更、影響範囲が広い修正。
→ 各 finding に **影響範囲**、**推奨**、**理由** を添えて提示。ユーザーが個別に判断。

```markdown
# SDD Framework Self-Review Report (External Engine)
**Date**: {ISO-8601} | **Engine**: {ENGINE_NAME} [{MODEL}] | **Agents**: 4 dispatched, {N} completed

## False Positives Eliminated

| Finding | Agent | Reason |
|---|---|---|

## A) 自明な修正 ({N}件) — OK で全件修正します

| ID | Sev | Summary | Fix | Target |
|---|---|---|---|---|

## B) ユーザー判断が必要 ({N}件)

### {ID}: {title}
**Location**: {file}:{line}
**Description**: {description}
**Impact**: {影響範囲と深刻度}
**Recommendation**: {推奨アクション} — {理由}

## Platform Compliance

| Item | Status | Source |
|---|---|---|
```

## Error Handling

- **Engine not installed**: `install_check` が失敗した場合、エラーメッセージを表示して停止
- **Claude nesting guard**: `CLAUDECODE` 環境変数が設定されている場合 (Lead セッション内)、claude engine は `env -u CLAUDECODE` で起動する必要がある。これなしでは "cannot be launched inside another Claude Code session" エラーで即座に失敗する
- **Agent failure**: レポートに "Agent {N} ({name}) did not complete." と注記。他の Agent の結果は有効
- **Timeout**: `$TIMEOUT` 超過時は部分結果があれば CPF を読む。なければ該当 Agent を失敗扱い
- **CPF not generated**: CPF ファイルが存在しない、または空の場合、該当 Agent を失敗扱い
- **Slot safety**: MultiView スロットは kill しない。command chain 完了で自動 idle 復帰。Timeout 時はスロットの shell に `C-c` を send-keys で停止
- **No findings**: Report "No issues detected." with confirmation checklist.

</instructions>
