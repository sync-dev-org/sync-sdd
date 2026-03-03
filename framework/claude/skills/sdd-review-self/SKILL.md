---
description: Self-review for SDD framework development (framework-internal use only)
allowed-tools: Agent, Bash, Read, Glob, Grep
---

# SDD Framework Self-Review

<instructions>

## Purpose

Self-review tool for SDD framework development. Dispatches 4 Sonnet review agents in parallel, consolidates results with lightweight false positive elimination. Review only — no modifications.

## Step 1: Collect Change Context

1. `git diff HEAD~10..HEAD --stat -- framework/ install.sh` → changed files list
2. `git diff HEAD -- framework/ install.sh` → uncommitted changes

If no changes and no uncommitted diffs: report "No changes since last review." and stop.

Build `$FOCUS_TARGETS` (3-5 bullet points): analyze the change context and identify the most important areas to verify (e.g., "phase gate logic changed in impl.md — verify consistency with CLAUDE.md", "new agent added — verify frontmatter and dispatch references").

## Step 2: Review Scope

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

## Step 3: Build Compliance Cache

Read `$SCOPE_DIR/verdicts.md` (where `$SCOPE_DIR` = `{{SDD_DIR}}/project/reviews/self/`).
Find the most recent Agent 4 (Platform Compliance) result within the last 7 days.

If found:
1. Read the archived report (`$SCOPE_DIR/B{seq}/agent-4-compliance.md`)
2. Extract `Confirmed OK` items → `$CACHED_OK` list
3. For each cached item, check if the relevant file has been modified since that review date (use git log)
4. Items with no file changes → remain in `$CACHED_OK`
5. Items with file changes → remove from `$CACHED_OK` (will be re-verified)

If not found or older than 7 days: `$CACHED_OK` = empty.

## Step 4: Parallel Review

Create `$SCOPE_DIR/active/` directory. Launch 4 agents in parallel.

Each agent: `Agent(subagent_type="general-purpose", model="sonnet", run_in_background=true)`

Output instruction for all agents: "Write your full report to `{$SCOPE_DIR}/active/agent-{N}-{name}.md` AND return it as your Agent result."

Required output format:
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
9. Revise modes: Single-Spec and Cross-Cutting modes in refs/revise.md route correctly from SKILL.md Detect Mode, with proper escalation paths between modes

Report in Japanese.
```

---

### Agent 2: Change-Focused Review

```
You are an SDD framework change reviewer. Your job is to verify that recent changes have not introduced regressions.

## Task
Run git commands to understand recent changes, then verify integrity.

## Steps
1. Run: `git log --oneline -10 -- framework/ install.sh`
2. Run: `git diff HEAD -- framework/ install.sh` (uncommitted)
3. Run: `git diff HEAD~5..HEAD -- framework/ install.sh` (recent committed changes)
4. Read changed files and their direct dependents from $REVIEW_SCOPE

## Review Criteria
- Dangling references: "see X" but X does not contain the referenced content
- Split losses: content removed from one file but not added to the new location
- Protocol completeness: changed protocols still have complete processing rules
- Template integrity: changed templates still match their references

## Focus Targets (from Lead)
{$FOCUS_TARGETS}

Prioritize the focus targets. Only read files relevant to the changes — do not read unchanged, unrelated files.

## Target Files (reference list — read selectively based on changes)
{$REVIEW_SCOPE}

Report in Japanese.
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
```

---

### Agent 4: Platform Compliance

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
3. Agent tool dispatch patterns: subagent_type matches existing agent definitions
4. settings.json permissions: Skill() and Agent() entries match actual files
5. Tool availability: agents do not reference tools they cannot access

## Official Documentation
Use WebSearch to verify Claude Code official specs for:
- Agent definition format (.claude/agents/*.md YAML frontmatter)
- Skills format (.claude/skills/*/SKILL.md)
- Agent tool parameters (subagent_type, model, run_in_background)
- settings.json permission format

## Cached Verifications (skip WebSearch for these — already verified recently)
{$CACHED_OK}

For cached items: only check if the relevant file has changed. If unchanged, mark as "OK (cached)".
For non-cached items: perform full WebSearch verification.

Include a compliance status table.
Report in Japanese.
```

---

## Step 5: Consolidation

All agents complete. Lead consolidates:

### 5.1 Extract and Deduplicate

1. Read all agent results (from Task output or `$SCOPE_DIR/active/` files)
2. Extract findings into a unified list
3. Merge duplicate findings (same issue reported by multiple agents)

### 5.2 Lightweight False Positive Check

For each finding:
- Check `{{SDD_DIR}}/handover/decisions.md` for intentional design decisions that explain the finding
- If explained by a recorded decision → classify as **False positive** (state decision reference)
- Otherwise → classify as **Confirmed**

No WebSearch/WebFetch by Lead. Agent 4 handles its own platform verification.

### 5.3 Severity Assignment

- **CRITICAL**: Blocks correct operation. Information loss that prevents Lead from executing a protocol.
- **HIGH**: Inconsistency that could cause Lead to make incorrect decisions.
- **MEDIUM**: Ambiguity or missing detail that may cause confusion but has workarounds.
- **LOW**: Cosmetic, documentation-only, or minor inconsistency.

## Step 6: Report Output + Verdict Persistence

### 6.1 Persist Results

1. Determine B{seq}: read `$SCOPE_DIR/verdicts.md`, increment max existing batch number (or start at 1)
2. Write consolidated report to `$SCOPE_DIR/active/report.md`
3. Append batch entry to `$SCOPE_DIR/verdicts.md`:
   ```
   ## [B{seq}] {ISO-8601} | v{version} | agents:{completed}/{dispatched}
   C:{n} H:{n} M:{n} L:{n} | FP:{n} eliminated
   Files: {comma-separated list of files with confirmed findings}
   ```
4. Archive: rename `$SCOPE_DIR/active/` → `$SCOPE_DIR/B{seq}/`

### 6.2 Report to User

```markdown
# SDD Framework Self-Review Report
**Date**: {ISO-8601} | **Agents**: 4 dispatched, {N} completed

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

(same format per finding)

## Platform Compliance

| Item | Status |
|---|---|

(from Agent 4, cached items marked with "(cached)")

## Overall Assessment

{summary, key risks, recommendation}

## Recommended Fix Priority

| Priority | ID | Summary | Target Files |
|---|---|---|---|
```

## Error Handling

- **Agent failure**: Note in report: "Agent {N} ({name}) did not complete. Findings may be incomplete."
- **No findings**: Report "No issues detected." with confirmation checklist.

</instructions>
