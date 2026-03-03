---
description: "Self-review (Codex CLI experiment): 4-agent parallel review via OpenAI Codex"
allowed-tools: Bash, Read, Glob, Grep, Write
---

# SDD Framework Self-Review (Codex Edition)

<instructions>

## Purpose

Codex CLI を使った self-review スキル。`sdd-review-self` と同じ 4 Agent を `codex exec --full-auto` で並行外注する。

## Step 1: Collect Change Context

1. `git diff HEAD~10..HEAD --stat -- framework/ install.sh` → 変更ファイルリスト
2. `git diff HEAD -- framework/ install.sh` → 未コミット変更

変更なし かつ 未コミット差分なし → "No changes since last review." を報告して停止。

変更内容を分析し `$FOCUS_TARGETS` (3-5 bullet points) を作成。

## Step 2: Prepare

```
$SCOPE_DIR = .sdd/project/reviews/self-codex
$CPF_OUTPUT_INSTRUCTION (共通、各 Agent プロンプト末尾に挿入):
```

1. `mkdir -p $SCOPE_DIR/active`

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
install.sh
```

### CPF Output Instruction (全 Agent 共通テンプレート)

各 Agent のプロンプト末尾に以下を挿入する (`{N}`, `{name}` は Agent ごとに置換):

```
## Output Instructions

1. Write your findings in CPF (Compact Pipe-Delimited Format) to: ${SCOPE_DIR}/active/agent-{N}-{name}.cpf
   CPF format:
   - Metadata lines: KEY:VALUE (no space around colon)
   - Section header: ISSUES: followed by one record per line
   - Issue format: SEVERITY|category|location|description
   - Severity codes: C=Critical, H=High, M=Medium, L=Low
   - Omit empty sections
   - Example:
     SCOPE:agent-{N}-{name}
     ISSUES:
     M|category|file.md:42|description

2. Print to stdout ONLY these lines (nothing else):
   CODEX_REVIEW_COMPLETE
   AGENT:{N}
   ISSUES: <number of issues found>
   WRITTEN:${SCOPE_DIR}/active/agent-{N}-{name}.cpf

Report findings in Japanese.
```

## Step 3: Identify Own Pane

tmux ペイン操作の前に、自身の安全を確保する:
1. `tmux display-message -p '#{pane_id}'` → `$MY_PANE`
2. `tmux list-panes -a -F '#{pane_id} #{pane_current_command}'` → 全ペイン一覧を記録

## Step 4: Parallel Dispatch (4 Agents)

Apply **One-Shot Command pattern** from `{{SDD_DIR}}/settings/rules/tmux-integration.md`.

4 つの Codex インスタンスを並行起動する。各 Agent:
- Pane title = Channel = `sdd-codex-agent-{N}`
- Result file = `$SCOPE_DIR/active/agent-{N}-result.txt`
- CPF file = `$SCOPE_DIR/active/agent-{N}-{name}.cpf`

**tmux mode** (`$TMUX` 設定あり):
各 Agent について `tmux split-window` で pane 作成。4 pane を一気に作成した後、4 つの `tmux wait-for` を background Bash で並行発行し、全完了を待つ。

**Fallback mode** (`$TMUX` 未設定):
4 つの `Bash(run_in_background=true)` で並行実行。`-o` の代わりに `2>/dev/null` で stderr を抑制し、stdout を直接受け取る。CPF はファイル書き出しで取得。

---

### Agent 1: Flow Integrity (`sdd-codex-agent-1`)

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
```

---

### Agent 2: Change-Focused Review (`sdd-codex-agent-2`)

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
```

---

### Agent 3: Consistency & Dead Ends (`sdd-codex-agent-3`)

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

${CPF_OUTPUT_INSTRUCTION with N=3, name=consistency}
```

---

### Agent 4: Structural Compliance (`sdd-codex-agent-4`)

```
You are an SDD framework structural compliance reviewer.

## Task
Verify that agent definitions, skill definitions, and permission settings are internally consistent.

## Scope (read these files)
- framework/claude/agents/sdd-*.md (all agent definitions)
- framework/claude/skills/sdd-*/SKILL.md (all skill definitions)
- framework/claude/settings.json

## Review Criteria
1. Agent YAML frontmatter: each agent file has valid frontmatter with model (sonnet/opus/haiku), tools list, and description
2. Skills frontmatter: each skill file has description and allowed-tools
3. Dispatch patterns: subagent_type values used in skill/ref files match actual agent filenames (general-purpose has no file — this is intentional, do not flag)
4. settings.json permissions: Skill() and Agent() entries match actual files on disk
5. Tool consistency: tools listed in agent frontmatter are valid tool names

${CPF_OUTPUT_INSTRUCTION with N=4, name=compliance}
```

---

## Step 5: Collect Results

全 Agent 完了後:

1. 各 `$SCOPE_DIR/active/agent-{N}-result.txt` を Read → 成功/失敗を判定
2. 成功した Agent の CPF ファイルを Read
3. 失敗した Agent はレポートに注記

### Pane Cleanup

tmux mode の場合:
1. `tmux list-panes -a -F '#{pane_id} #{pane_current_command}'` で残存ペインを確認
2. `$MY_PANE` と異なるペインで `sdd-codex-` タイトルのものがあれば kill

## Step 6: Consolidation

### 6.1 Deduplicate
全 CPF の ISSUES を統合。同一の location + description は重複として 1 件にまとめ、検出 Agent を列挙。

### 6.2 False Positive Check
各 finding について `{{SDD_DIR}}/handover/decisions.md` を確認。意図的な設計決定で説明できるものは FP として除外。

### 6.3 Severity Assignment
CPF の severity コードをそのまま使用。重複マージ時は最も高い severity を採用。

## Step 7: Report Output + Verdict Persistence

### 7.1 Persist Results

1. B{seq} を決定: `$SCOPE_DIR/verdicts.md` の最大バッチ番号 + 1
2. consolidated report を `$SCOPE_DIR/active/report.md` に書き出し
3. `$SCOPE_DIR/verdicts.md` にバッチエントリを追記:
   ```
   ## [B{seq}] {ISO-8601} | codex | agents:{completed}/{dispatched}
   C:{n} H:{n} M:{n} L:{n} | FP:{n} eliminated
   Files: {comma-separated list of files with confirmed findings}
   ```
4. Archive: `$SCOPE_DIR/active/` → `$SCOPE_DIR/B{seq}/`

### 7.2 Report to User

```markdown
# SDD Framework Self-Review Report (Codex Edition)
**Date**: {ISO-8601} | **Engine**: Codex CLI | **Agents**: 4 dispatched, {N} completed

## False Positives Eliminated

| Finding | Agent | Reason |
|---|---|---|

## CRITICAL ({N})

### C{N}: {title}
**Location**: {file}:{line}
**Description**: {description}

## HIGH ({N})
## MEDIUM ({N})
## LOW ({N})

(same format per finding, with detecting agent(s) noted)

## Structural Compliance

| Item | Status |
|---|---|

(from Agent 4)

## Overall Assessment

{summary, key risks, recommendation}

## Recommended Fix Priority

| Priority | ID | Summary | Target Files |
|---|---|---|---|
```

## Error Handling

- **Codex 未インストール**: `npx -y @openai/codex` が失敗した場合、エラーメッセージを表示して停止
- **Agent 失敗**: レポートに "Agent {N} ({name}) did not complete." と注記。他の Agent の結果は有効
- **タイムアウト**: 5分超過時は部分結果があれば CPF を読む。なければ該当 Agent を失敗扱い
- **CPF 未生成**: result に CODEX_REVIEW_COMPLETE がない、または CPF ファイルが存在しない場合、該当 Agent を失敗扱い
- **ペイン安全**: kill 操作前に必ず `$MY_PANE` と異なることを確認

</instructions>
