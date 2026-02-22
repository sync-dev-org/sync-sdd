---
description: Self-review for SDD framework development (framework-internal use only)
allowed-tools: Task, Bash, Read, Glob, Grep, WebSearch, WebFetch
argument-hint: [--quick]
---

# SDD Framework Self-Review

<instructions>

## Purpose

Thorough self-review tool for SDD framework development. Dispatches 5 review agents in parallel, consolidates results with evidence-based false positive elimination, and outputs a final report. Review only — no modifications.

## Step 1: Mode Detection

```
$ARGUMENTS = ""        → Full review (5 agents)
$ARGUMENTS = "--quick" → Quick review (3 agents: skip compliance + dead code)
```

## Step 2: Collect Change Context

Build dynamic context to inject into each agent prompt:

1. `git log --oneline -20 -- framework/ install.sh` → recent commits
2. `git diff HEAD -- framework/ install.sh` → unstaged changes
3. `git diff --cached -- framework/ install.sh` → staged changes
4. `git diff HEAD~5..HEAD --stat -- framework/ install.sh` → change summary over last 5 commits

Combine into `$CHANGE_CONTEXT`:
```
### Commit History (last 20)
{git log output}

### Uncommitted Changes (diff summary)
{changed file list + key hunks}

### Changed Files (last 5 commits)
{stat output}
```

If no changes exist (clean tree, no recent commits): set `$CHANGE_CONTEXT` to "No recent changes detected."

## Step 3: Review Scope

All agents share the same fixed target set:

```
$REVIEW_SCOPE:
- framework/claude/CLAUDE.md
- framework/claude/skills/sdd-*/SKILL.md
- framework/claude/skills/sdd-*/refs/*.md
- framework/claude/agents/sdd-*.md
- framework/claude/settings.json
- framework/claude/sdd/settings/rules/*.md
- framework/claude/sdd/settings/templates/**/*.md
- install.sh
```

## Step 4: Parallel Review (Phase 1)

Launch review agents via `Task(subagent_type="general-purpose")`. All agents run in background (`run_in_background: true`).

Each agent's prompt = static template + `$REVIEW_SCOPE` as file list + `$CHANGE_CONTEXT` appended.

Required output format for each agent:

```
## {Review Name} Report
### Issues Found
- [CRITICAL] description / file:line
- [HIGH] ...
- [MEDIUM] ...
- [LOW] ...
### Confirmed OK
- check item
### Overall Assessment
```

---

### Agent 1: Flow Integrity

```
You are an SDD framework flow integrity reviewer.

## Task
Verify that sdd-roadmap Router → refs dispatch flow works correctly across all modes.

## Target Files (read ALL)
{$REVIEW_SCOPE}

## Review Criteria
1. Router dispatch completeness: all subcommands route to correct refs
2. Phase gate consistency: phases required by each ref match CLAUDE.md definitions
3. Auto-fix loop: NO-GO/SPEC-UPDATE-NEEDED handling consistent between refs and CLAUDE.md
4. Wave quality gate: wave-level quality gate flow is complete
5. Consensus mode: no contradictions in multi-pipeline parallel execution
6. Verdict persistence: format is consistent across all review types
7. Edge cases: empty roadmap, 1-spec, blocked spec, retry limit exhaustion
8. Read clarity: when Router reads refs is explicitly specified

## Recent Changes
{$CHANGE_CONTEXT}

Pay special attention to changed areas and verify they don't break overall flow integrity.
Report in Japanese.
```

---

### Agent 2: Regression Detection

```
You are an SDD framework regression detection reviewer.

## Task
Verify that recent changes have not caused loss of functionality, protocol definitions, or critical documentation.

## Target Files (read ALL)
{$REVIEW_SCOPE}

## Review Criteria
1. Dangling references: "see X for details" but X does not contain the referenced content
2. Split losses: content that existed before refactoring but was not migrated to any file
3. Protocol completeness: every protocol defined by the framework has complete processing rules in at least one file
4. Template integrity: templates referenced by CLAUDE.md exist and contain matching content
5. Use git log and git diff to identify what changed recently, then verify that content present before the change still exists somewhere after the change

Include a split traceability table.
Report in Japanese.

## Recent Changes
{$CHANGE_CONTEXT}
```

---

### Agent 3: Consistency & Dead Ends

```
You are an SDD framework consistency reviewer.

## Task
Detect contradictions, terminology inconsistencies, unreachable paths, and undefined references across all files.

## Target Files (read ALL)
{$REVIEW_SCOPE}

## Review Criteria
1. Value consistency: phase names, SubAgent names, verdict values, severity codes unified across files
2. Path consistency: file paths, directory names, template variable expansions match across all files
3. Protocol consistency: same protocol is not described differently in multiple files
4. Numeric consistency: retry limits, agent counts, pipeline limits do not contradict
5. Unreachable paths (dead ends): missing phase transitions or error handling gaps
6. Circular references: no cycles in file reference relationships
7. Undefined references: no references to non-existent files, agent names, or phase names

Include a cross-reference matrix.
Report in Japanese.

## Recent Changes
{$CHANGE_CONTEXT}
```

---

### Agent 4: Claude Code Compliance (skipped with --quick)

```
You are a Claude Code official specification reviewer.

## Task
Verify that the SDD framework complies with Claude Code official documentation.

## Target Files (read ALL)
{$REVIEW_SCOPE}

## Official Documentation (use WebSearch/WebFetch)
1. Claude Code SubAgents: Task tool subagent_type, .claude/agents/ YAML frontmatter spec
2. Claude Code Skills: .claude/skills/*/SKILL.md format
3. Claude Code settings.json: valid configuration keys
4. Claude Code agents/: available tool names, model specification

## Review Criteria
1. agents/ YAML frontmatter: valid values for model/tools/description
2. Skills frontmatter: description/allowed-tools/argument-hint compliance
3. Task tool usage: subagent_type parameter
4. settings.json: only valid keys used
5. install.sh: paths match Claude Code expectations
6. Model selection: appropriate model for each role
7. Tool permissions: minimal necessary tools for each agent

Include an official spec compliance table.
Report in Japanese.

## Recent Changes
{$CHANGE_CONTEXT}
```

---

### Agent 5: Dead Code & Unused References (skipped with --quick)

```
You are an SDD framework dead code reviewer.

## Task
Detect unused code, orphaned references, and redundant content across the entire framework.

## Target Files (read ALL)
{$REVIEW_SCOPE}

## Detection Targets
1. Unreferenced agents: defined in agents/ but never dispatched from any SKILL.md or refs
2. Unreferenced templates/rules: exist in templates/ or rules/ but not referenced by any file
3. Unreferenced skills: listed in CLAUDE.md Commands table but no SKILL.md exists, or vice versa
4. Redundant content: identical content duplicated across multiple files
5. Unreachable code paths: conditional branches that can never be reached
6. Remnants of removed concepts: references to concepts deleted or replaced in recent changes
7. Stale comments: TODO, FIXME, empty sections

Include an agent reference matrix and a template reference matrix.
Report in Japanese.

## Recent Changes
{$CHANGE_CONTEXT}

Identify concepts deleted or renamed in the change context and check for their remnants.
```

---

## Step 5: Evidence Research (Phase 2)

All agents complete. Lead consolidates:

### 5.1 Extract and Deduplicate

1. Read all agent results
2. Extract findings into a unified list
3. Merge duplicate findings (same issue reported by multiple agents)
4. Note which agents confirmed vs. which raised unique findings

### 5.2 False Positive Elimination

For each finding, evaluate:

**a. Official documentation check:**
- `WebSearch` for Claude Code official docs on the relevant topic
- `WebFetch` official docs pages to verify exact spec
- Compare finding against official spec

**b. Design intent check:**
- `Read` the relevant framework files to verify context
- Check `{{SDD_DIR}}/handover/decisions.md` for intentional design decisions
- Check `{{SDD_DIR}}/handover/session.md` for session context

**c. Functional impact check:**
- Does the finding actually cause runtime failures?
- Is it a documentation inconsistency only?
- Is it an intentional simplification?

Classify each finding as:
- **Confirmed**: Real issue, evidence supports
- **False positive**: Explained by official spec, design intent, or functional irrelevance (state reason)

### 5.3 Severity Assignment

After false positive removal, assign final severity:
- **CRITICAL**: Blocks correct operation. Information loss that prevents Lead from executing a protocol.
- **HIGH**: Inconsistency that could cause Lead to make incorrect decisions.
- **MEDIUM**: Ambiguity or missing detail that may cause confusion but has workarounds.
- **LOW**: Cosmetic, documentation-only, or minor inconsistency.

## Step 6: Report Output (Phase 3)

Output the final report directly to user (not written to file):

```markdown
# SDD Framework Self-Review Report
**Date**: {date}
**Mode**: {full | quick}
**Agents**: {N} dispatched, {N} completed

---

## False Positives Eliminated

| Finding | Reporting Agent | Elimination Reason |
|---|---|---|

---

## CRITICAL ({N})

### C{N}: {title}
**Location**: {file}:{line}
**Description**: {description}
**Evidence**: {official doc reference or file content}

---

## HIGH ({N})
## MEDIUM ({N})
## LOW ({N})

(same format per finding)

---

## Claude Code Compliance Status

| Item | Status |
|---|---|

(full mode only)

---

## Overall Assessment

{architecture quality, compliance level, key risks, recommendation}

---

## Recommended Fix Priority

| Priority | ID | Summary | Target Files |
|---|---|---|---|
```

## Error Handling

- **Agent failure**: Note in report: "Agent {N} ({name}) did not complete. Findings may be incomplete."
- **WebSearch unavailable**: Skip official doc verification, note: "Official documentation verification skipped."
- **No findings**: Report "No issues detected" with confirmation checklist.

</instructions>
