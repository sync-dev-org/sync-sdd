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

各 Agent のプロンプトを `$SCOPE_DIR/active/agent-{N}-prompt.txt` に書き出す。
プロンプト末尾に以下を共通で追記:

**CPF Output Instruction** (`{N}`, `{name}` は Agent ごとに置換):

```
## Output Instructions

1. Write your findings in CPF (Compact Pipe-Delimited Format) to: ${SCOPE_DIR}/active/agent-{N}-{name}.cpf
   CPF format:
   - Metadata lines: KEY:VALUE (no space around colon)
   - Section header: ISSUES: followed by one record per line
   - Issue format: SEVERITY|category|location|description
   - Severity codes: C=Critical, H=High, M=Medium, L=Low
   - Report ALL severity levels including LOW. A review with zero LOW findings is suspicious — verify you haven't self-filtered.
   - Omit empty sections
   - Example:
     SCOPE:agent-{N}-{name}
     ISSUES:
     M|category|file.md:42|description

2. After writing the CPF file, print to stdout:
   EXT_REVIEW_COMPLETE
   AGENT:{N}
   ISSUES: <number of issues found>
   WRITTEN:${SCOPE_DIR}/active/agent-{N}-{name}.cpf

Report findings in Japanese.
```

**Deny Patterns** (全 Agent 共通、プロンプト末尾に追記):

```
## PROHIBITED COMMANDS (MUST NEVER execute)
{$DENY_PATTERNS を改行区切りで列挙}
```

## Step 3: Build Compliance Cache

Read `$SCOPE_DIR/verdicts.md`.
Find the most recent Agent 4 (Platform Compliance) result within the last 7 days.

If found:
1. Read the archived report (`$SCOPE_DIR/B{seq}/agent-4-compliance.cpf`)
2. Extract `Confirmed OK` items → `$CACHED_OK` list
3. For each cached item, check if the relevant file has been modified since that review date (use git log)
4. Items with no file changes → remain in `$CACHED_OK`
5. Items with file changes → remove from `$CACHED_OK` (will be re-verified)

If not found or older than 7 days: `$CACHED_OK` = empty.

## Step 4: Identify Own Pane (tmux mode only)

`$TMUX` が設定されている場合のみ実行:
1. `tmux display-message -p '#{pane_id}'` → `$MY_PANE`
2. `tmux list-panes -a -F '#{pane_id} #{pane_current_command}'` → 全ペイン一覧を記録
3. `$SID` = `$MY_PANE` の `%` を除去 (例: `%5` → `5`)。セッション固有 ID として tmux チャネル名に使用

`$TMUX` 未設定の場合はスキップして Step 5 Fallback mode へ。

## Step 5: Parallel Dispatch (4 Agents)

Apply **One-Shot Command pattern** from `{{SDD_DIR}}/settings/rules/tmux-integration.md`.

4 つの外部エンジンインスタンスを並行起動する。各 Agent:
- Pane title = Channel = `sdd-ext-{SID}-{N}` (`$SID` は Step 4 で生成したセッション固有 ID)
- Prompt file = `$SCOPE_DIR/active/agent-{N}-prompt.txt`
- CPF file (成果物) = `$SCOPE_DIR/active/agent-{N}-{name}.cpf`

### Engine-Specific Command Construction

Assemble command based on `$ENGINE_NAME`. `$TOOLS` が null の場合は全許可モード、設定されている場合はツール制限モード:

全エンジン共通: stdout はリダイレクトしない — pane に応答テキスト / 進捗が流れる。成果物は CPF ファイルのみ。完了は `tmux wait-for` / background task で検出し、成功判定は CPF ファイル存在チェックで行う。

**codex** (`npx -y @openai/codex` 経由で起動。stdin でプロンプトを渡す):
```
npx -y @openai/codex exec --full-auto [--model $MODEL] - < $PROMPT_FILE
```

**claude** (`env -u CLAUDECODE` で Lead セッションからのネスト検出を回避):
```
env -u CLAUDECODE claude -p - --dangerously-skip-permissions [--model $MODEL] < $PROMPT_FILE
```
ツール制限時: `--dangerously-skip-permissions` を `--allowedTools "$TOOLS"` に置換。

**gemini** (`npx -y @google/gemini-cli` 経由で起動。`-p` で非対話モード、stdin からプロンプトを追加入力):
```
npx -y @google/gemini-cli -p "Review the project files per the instructions below." --yolo [--model $MODEL] < $PROMPT_FILE
```
ツール制限時: `--yolo` を `--sandbox` に置換。

`[]` 内は対応する値が設定されている場合のみ付与。プロンプトが長い場合はシェル引数制限を避けるため stdin (`< $PROMPT_FILE`) を優先する。

### Dispatch Mode

**tmux mode** (`$TMUX` 設定あり):
各 Bash 呼び出しを `tmux` で開始することで `Bash(tmux *)` パターンにマッチさせ、承認を不要にする:
1. Agent 1: `tmux split-window -h -d -P -F '#{pane_id}' "{cmd1}; tmux wait-for -S sdd-ext-{SID}-1"` → `$P1`
2. Agent 2: `tmux split-window -v -d -t $P1 -P -F '#{pane_id}' "{cmd2}; tmux wait-for -S sdd-ext-{SID}-2"` → `$P2`
3. Agent 3: `tmux split-window -v -d -t $P2 -P -F '#{pane_id}' "{cmd3}; tmux wait-for -S sdd-ext-{SID}-3"` → `$P3`
4. Agent 4: `tmux split-window -v -d -t $P3 -P -F '#{pane_id}' "{cmd4}; tmux wait-for -S sdd-ext-{SID}-4"`
5. `tmux select-layout tiled` → Lead 含む全 5 pane を均等グリッド配置

`tiled` は pane インデックス順に配置するため、Lead (`$MY_PANE`, 最小インデックス) が自動的に左上になる。
各呼び出しの返値 (pane ID) を次の `-t` に使う。パスは変数を使わずインラインで記述する（`Bash(tmux *)` マッチのため）。
4 pane 作成後、4 つの `tmux wait-for` を background Bash で並行発行し、全完了を待つ。

**Fallback mode** (`$TMUX` 未設定):
4 つの `Bash(run_in_background=true)` で並行実行。CPF はファイル書き出しで取得。

---

### Agent 1: Flow Integrity (`sdd-ext-review-1`)

```
You are an SDD framework flow integrity reviewer.

## Task
Verify that sdd-roadmap Router → refs dispatch flow works correctly across all modes.

## Target Files (read ALL)
${FILE_LIST}

## Review Criteria
1. Router dispatch completeness: all subcommands route to correct refs
2. Phase gate consistency: phases required by each ref match CLAUDE.md definitions
3. Auto-fix loop: NO-GO/SPEC-UPDATE-NEEDED handling consistent between refs and CLAUDE.md
4. Wave quality gate: wave-level quality gate flow is complete
5. Consensus mode: no contradictions in multi-pipeline parallel execution
6. Verdict persistence: format is consistent across all review types
7. Edge cases: empty roadmap, 1-spec, blocked spec, retry limit exhaustion
8. Read clarity: when Router reads refs is explicitly specified
9. Revise modes: Single-Spec and Cross-Cutting modes in refs/revise.md route correctly from SKILL.md Detect Mode, with proper escalation paths between modes

${CPF_OUTPUT_INSTRUCTION with N=1, name=flow}
${DENY_PATTERNS_SECTION}
```

---

### Agent 2: Change-Focused Review (`sdd-ext-review-2`)

```
You are an SDD framework change reviewer. Your job is to verify that recent changes have not introduced regressions.

## Task
Run git commands to understand recent changes, then verify integrity.

## Steps
1. Run: git log --oneline -10 -- framework/ install.sh
2. Run: git diff HEAD -- framework/ install.sh (uncommitted)
3. Run: git diff HEAD~5..HEAD -- framework/ install.sh (recent committed changes)
4. Read changed files and their direct dependents from the target file list

## Review Criteria
- Dangling references: "see X" but X does not contain the referenced content
- Split losses: content removed from one file but not added to the new location
- Protocol completeness: changed protocols still have complete processing rules
- Template integrity: changed templates still match their references

## Focus Targets (from Lead)
${FOCUS_TARGETS}

Prioritize the focus targets. Only read files relevant to the changes — do not read unchanged, unrelated files.

## Target Files (reference list — read selectively based on changes)
${FILE_LIST}

${CPF_OUTPUT_INSTRUCTION with N=2, name=change}
${DENY_PATTERNS_SECTION}
```

---

### Agent 3: Consistency & Dead Ends (`sdd-ext-review-3`)

```
You are an SDD framework consistency reviewer.

## Task
Detect contradictions, terminology inconsistencies, unreachable paths, and undefined references across framework definition files.

## Target Files (read ALL)
${FILE_LIST}

## Review Criteria
1. Value consistency: phase names, SubAgent names, verdict values, severity codes unified across files
2. Path consistency: file paths, directory names, template variable expansions match across all files
3. Protocol consistency: same protocol is not described differently in multiple files
4. Numeric consistency: retry limits, agent counts, pipeline limits do not contradict
5. Unreachable paths (dead ends): missing phase transitions or error handling gaps
6. Circular references: no cycles in file reference relationships
7. Undefined references: no references to non-existent files, agent names, or phase names

Note: general-purpose is referenced in dispatch patterns but has no corresponding file in framework/claude/agents/ — this is intentional. Do not flag it as an undefined reference.

Include a cross-reference matrix.

${CPF_OUTPUT_INSTRUCTION with N=3, name=consistency}
${DENY_PATTERNS_SECTION}
```

---

### Agent 4: Platform Compliance (`sdd-ext-review-4`)

```
You are a Claude Code platform compliance reviewer for the SDD framework.

## Task
Verify that SDD framework agents, skills, and Agent tool usage comply with Claude Code platform specifications.

## Scope (read these files)
- framework/claude/agents/sdd-*.md (all agent definitions)
- framework/claude/skills/sdd-*/SKILL.md (all skill definitions)
- framework/claude/settings.json
- framework/claude/CLAUDE.md (SubAgent dispatch sections only)

## Review Criteria
1. Agent YAML frontmatter: valid model (sonnet/opus/haiku), valid tools list, description present
2. Skills frontmatter: description, allowed-tools, argument-hint format
3. Agent tool dispatch patterns: subagent_type matches existing agent definitions (note: general-purpose is a Claude Code built-in — no Agent() entry or file needed)
4. settings.json permissions: Skill() and Agent() entries match actual files (built-in agents like general-purpose are excluded from this check)
5. Tool availability: agents do not reference tools they cannot access

## Official Documentation
Use web search to verify Claude Code official specs for:
- Agent definition format (.claude/agents/*.md YAML frontmatter)
- Skills format (.claude/skills/*/SKILL.md)
- Agent tool parameters (subagent_type, model, run_in_background)
- settings.json permission format

## Compliance Reporting Rules
Use this tri-state system for each compliance item:
- **OK**: verified present in official docs. Cite the source URL.
- **NG**: verified absent AND explicitly contradicted by official docs. You MUST cite the specific documentation URL that contradicts it.
- **UNCERTAIN**: not found in search results, or search results are ambiguous. Do NOT report as NG. Report as: `UNCERTAIN|category|location|description`. Lead will make final determination.

CRITICAL: "Not found in web search" ≠ "Non-compliant". Official documentation may be incomplete or not indexed. When in doubt, use UNCERTAIN.

## Cached Verifications (skip web search for these — already verified recently)
${CACHED_OK}

For cached items: only check if the relevant file has changed. If unchanged, mark as "OK (cached)".
For non-cached items: perform full web search verification.

Include a compliance status table with columns: Item | Status (OK/NG/UNCERTAIN) | Source URL.

${CPF_OUTPUT_INSTRUCTION with N=4, name=compliance}
${DENY_PATTERNS_SECTION}
```

---

## Step 6: Collect Results

全 Agent 完了後 (tmux wait-for / background task 完了):

1. 各 `$SCOPE_DIR/active/agent-{N}-{name}.cpf` の存在を確認 → 成功/失敗を判定
2. 成功した Agent の CPF ファイルを Read
3. 失敗した Agent (CPF 不在) はレポートに注記

### Pane Cleanup

tmux mode の場合:
1. Step 4 で記録した全ペイン一覧と現在のペイン一覧を比較し、新規に追加されたペインを特定
2. **Lead 保護**: kill 対象は `$MY_PANE` と異なる新規ペインのみ。`$MY_PANE` は絶対に kill しない
3. 該当ペインがあれば `tmux kill-pane -t {pane_id}` で kill
4. `tmux select-layout` をリセット（Lead pane が元のフルサイズに戻る）

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

### 8.2 Report to User

```markdown
# SDD Framework Self-Review Report (External Engine)
**Date**: {ISO-8601} | **Engine**: {ENGINE_NAME} [{MODEL}] | **Agents**: 4 dispatched, {N} completed

## False Positives Eliminated

| Finding | Agent | Reason |
|---|---|---|

## CRITICAL ({N})

### C{N}: {title}
**Location**: {file}:{line}
**Description**: {description}
**Evidence**: {reference}

## HIGH ({N})
## MEDIUM ({N})
## LOW ({N})

(same format per finding, with detecting agent(s) noted)

## Platform Compliance

| Item | Status | Source |
|---|---|---|

(from Agent 4. Status: OK/NG/UNCERTAIN→resolved. Cached items marked "(cached)". UNCERTAIN items show Lead's resolution.)

## Overall Assessment

{summary, key risks, recommendation}

## Recommended Fix Priority

| Priority | ID | Summary | Target Files |
|---|---|---|---|
```

## Error Handling

- **Engine not installed**: `install_check` が失敗した場合、エラーメッセージを表示して停止
- **Claude nesting guard**: `CLAUDECODE` 環境変数が設定されている場合 (Lead セッション内)、claude engine は `env -u CLAUDECODE` で起動する必要がある。これなしでは "cannot be launched inside another Claude Code session" エラーで即座に失敗する
- **Agent failure**: レポートに "Agent {N} ({name}) did not complete." と注記。他の Agent の結果は有効
- **Timeout**: `$TIMEOUT` 超過時は部分結果があれば CPF を読む。なければ該当 Agent を失敗扱い
- **CPF not generated**: CPF ファイルが存在しない、または空の場合、該当 Agent を失敗扱い
- **Pane safety**: kill 操作前に必ず `$MY_PANE` と異なることを確認 (tmux mode のみ)
- **No findings**: Report "No issues detected." with confirmation checklist.

</instructions>
