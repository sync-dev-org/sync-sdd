---
description: Detect dead code, unused settings, and orphaned specs
allowed-tools: Bash, Glob, Grep, Read, Write, Task, TeamCreate, TeamDelete, SendMessage, TaskCreate, TaskList, TaskUpdate
argument-hint: [--full] [--team] | [--settings] | [--code] | [--specs] | [--tests]
---

# SDD Dead Code Review

<background_information>
- **Mission**: Thoroughly detect dead code, unused settings, orphaned specs, and stale test code
- **Philosophy**:
  - Do NOT follow a checklist mechanically - conduct **autonomous, multi-angle investigation**
  - Create **throwaway Python scripts** for analysis when needed
  - Report anything suspicious - let humans make the final judgment
</background_information>

<instructions>

## Execution Strategy

**CRITICAL**: Launch 4 Explore agents **in parallel**, instructing each to conduct **thorough autonomous exploration**.

For each agent:
- Do NOT provide detailed checklists (inhibits autonomy)
- Provide only the goal and expected thoroughness level
- Encourage Python script creation for analysis
- Let agents discover project structure themselves

---

## Mode Detection

```
$ARGUMENTS = "--full" or ""        → 4 agents in parallel (Subagent mode)
$ARGUMENTS = "--full --team"       → 4 agents in parallel (Agent Team mode)
$ARGUMENTS = "--team"              → 4 agents in parallel (Agent Team mode)
$ARGUMENTS = "--settings"          → Settings only (Subagent mode)
$ARGUMENTS = "--code"              → Code only (Subagent mode)
$ARGUMENTS = "--specs"             → Specs only (Subagent mode)
$ARGUMENTS = "--tests"             → Tests only (Subagent mode)
```

Note: `--team` is only applicable in full mode (all 4 agents). Individual category runs always use Subagent mode.

---

## Execution Flow

### Subagent Execution Flow (default)

#### Phase 1: Parallel Audit Agents

Launch 4 agents **in parallel** via Task tool using the Agent Prompts below.

**CRITICAL**: Launch all 4 Task calls in a SINGLE message for true parallel execution.

#### Phase 2: Verification Agent

After all 4 agents complete, launch verifier:

```
Read and follow the instructions in `.claude/agents/sdd-review-dead-code-verifier.md`.

Agent Results:

## Settings Audit Results
{settings agent output}

## Dead Code Detection Results
{code agent output}

## Spec Alignment Results
{specs agent output}

## Test Code Audit Results
{tests agent output}

Execute verification and return the unified report.
```

#### Phase 3: Display Results

Router transforms verifier's compact output into human-readable report:

1. **Parse verifier output**:
   - Metadata lines: `KEY:VALUE` format (VERDICT)
   - VERIFIED lines: split by `|` → agents, sev, cat, loc, desc
   - REMOVED lines: split by `|` → agent, reason, original
   - RESOLVED lines: split by `|` → agents, resolution, findings
   - NOTES: freeform text lines
   - Missing sections = no findings of that type
   - Agents field: split by `+` for agent list

2. **Format as markdown report** (using the Report Aggregation template below)

3. **Display formatted report** to user

**IMPORTANT**: All formatting logic lives in the router. Agents NEVER produce markdown tables, headers, or human-readable prose in their output.

---

### Agent Team Execution Flow (when --team flag detected)

#### Teammate Roles

All teammates are flat members of the review team. Lead receives only the final report.

| Role | Model | Responsibility |
|------|-------|---------------|
| **Lead** (this router) | Opus | Team creation, final report display. Does NOT process individual findings. |
| **audit-verifier** | Opus | Collects findings from 4 auditors, runs cross-validation, merges results. Sends only final CPF report to Lead. |
| **audit-{category}** ×4 | Sonnet | Independent investigation. Sends findings to audit-verifier (NOT to Lead). |

**Context savings**: Lead never sees raw auditor output. Only the verifier's final report enters Lead's context.

#### Phase 1: Team Creation & Spawn All 5 Teammates

1. **Create team** "sdd-dead-code-review"
2. **Spawn audit-verifier** AND **4 auditors** in a SINGLE message (all 5 in parallel):

   **audit-verifier** (name: `audit-verifier`, model: opus):
   ```
   You are a WORKER agent. Do NOT spawn new teammates or subagents.
   Read `.claude/agents/sdd-review-dead-code-verifier.md` and follow all instructions.

   Your role in this team:
   1. WAIT for 4 auditor teammates to send you their findings
   2. Once all 4 received, broadcast all findings back to all auditors for cross-validation
      (use the cross-domain questions from your Cross-Check Protocol section).
      This is a single round — do NOT request further discussion.
   3. WAIT for 4 REFINED responses
   4. Synthesize: apply the full Verification Process from your agent file
      (cross-domain correlation, false positive check, deduplication, verdict)
   5. Send ONLY the final CPF report to the team lead. Do NOT send intermediate findings.
   ```

   **4 auditors** (name: `audit-{category}`, model: sonnet), each with:
   ```
   You are a WORKER agent. Do NOT spawn new teammates or subagents.
   {Agent Prompt from the corresponding section below}
   After completing your investigation, send your complete findings to 'audit-verifier' (NOT to the team lead).
   Format: Category name, then one finding per line with severity (C/H/M/L), location, and description.
   When audit-verifier sends you all findings for cross-validation, review for cross-domain
   connections and send REFINED findings back to 'audit-verifier'.
   ```

   Teammate names: `audit-settings`, `audit-code`, `audit-specs`, `audit-tests`

#### Phase 2: Wait for Verifier Result

3. **Lead waits** for a single message from `audit-verifier` containing the final CPF report
   - The verifier handles all cross-validation internally (peer-to-peer with auditors)
   - Lead does NOT interact with individual auditors

#### Phase 3: Cleanup & Display

4. **Clean up team**:
   - Send `shutdown_request` to all 5 teammates (`audit-verifier` + 4 auditors)
   - Wait for shutdown approvals, then `TeamDelete`
5. **Display** the verifier's report (parse CPF and format to markdown using Report Aggregation template)

---

## Agent Prompts

### Agent 1: Settings Audit

```
Thoroughly investigate the project's configuration management to detect "dead config".

Goal:
- Find config fields that are defined but never actually consumed
- Verify settings are properly passed from definition to final consumption point

Investigation approach (decide yourself):
1. First discover the project structure (find config files yourself)
2. Identify config classes/modules and extract all fields
3. For each field, thoroughly trace usage through the codebase
4. Create Python scripts for AST analysis or dependency tracing if needed
5. Verify the path "config → intermediate layer → final consumer" is not broken

Expected thoroughness:
- Go beyond simple grep - trace actual code flow
- Pay special attention to parameters with default values (missing passthrough still works)
- Report anything suspicious

Output: Usage status for each field, with detailed explanation for any issues found
```

### Agent 2: Dead Code Detection

```
Thoroughly investigate the project's source code to detect unused code.

Goal:
- Find functions/methods/classes that are defined but never called
- Identify code used only in tests, not in production
- Find code left for "future use" that is actually dead

Investigation approach (decide yourself):
1. First discover the project structure (find source directories yourself)
2. Enumerate all public symbols (functions, classes, methods)
3. Thoroughly search for call sites of each symbol
4. Create Python scripts for AST analysis or call graph generation if needed
5. Compare __all__ exports with actual usage

Expected thoroughness:
- Go beyond simple grep - trace actual call relationships
- Pay special attention to class methods (may be used internally but never called externally)
- Check usage via properties and decorators
- Report anything suspicious

Output: List of unused or suspicious symbols with detailed analysis
```

### Agent 3: Spec Alignment

```
Thoroughly investigate alignment between project specifications and implementation.

Goal:
- Find features specified but not implemented
- Find features implemented but not in specs
- Find specs that have drifted from implementation

Investigation approach (decide yourself):
1. First discover the project structure (find spec directories yourself)
2. Read each spec and understand expected implementation
3. Identify corresponding implementation files and compare with actual code
4. Cross-reference task completion status with actual implementation state
5. Create scripts for automated comparison if needed

Expected thoroughness:
- Compare interface definitions in specs with actual signatures
- Compare dependency diagrams in specs with actual import relationships
- Detect partial or incomplete implementations
- Report anything suspicious

Output: Alignment status for each spec, with detailed explanation for any drift
```

### Agent 4: Test Code Audit

```
Thoroughly investigate the project's test code to detect orphaned test code.

Goal:
- Find fixtures that are defined but never used
- Find tests that test non-existent functionality
- Find tests depending on outdated interfaces

Investigation approach (decide yourself):
1. First discover the project structure (find test directories yourself)
2. Enumerate all fixture definitions and trace their usage
3. Compare test imports with actual source symbols
4. Create Python scripts for fixture dependency analysis if needed
5. Detect unused imports as well

Expected thoroughness:
- Include conftest.py fixtures in the analysis
- Detect duplicate fixtures at class vs module level
- Trace indirect usage (via other fixtures)
- Report anything suspicious

Output: List of orphaned test code with detailed analysis
```

---

## Report Aggregation

Aggregate results from 4 agents into a unified report:

```markdown
# Dead Code Review Report

Generated: {timestamp}
Project: {project_name}

## Executive Summary

| Category | Issues | Critical | Warnings |
|----------|--------|----------|----------|
| Settings | ? | ? | ? |
| Code | ? | ? | ? |
| Specs | ? | ? | ? |
| Tests | ? | ? | ? |

## Verdict
- GO / CONDITIONAL / NO-GO

## Detailed Findings

[Detailed results per category]

## Recommended Actions

[Prioritized action list]
```

</instructions>

## Error Handling

### Agent Failures
- **1 agent fails**: Proceed with results from remaining agents. Mark the failed category as "INCOMPLETE" in the summary table and note: "Agent for {category} failed. Re-run with `--{category}` flag to retry."
- **2+ agents fail**: Report partial results from successful agents. Display warning: "Multiple agents failed ({list}). Results are incomplete. Consider re-running `/sdd-review-dead-code --full`."
- **All agents fail**: Report error and suggest checking project structure or re-running individual categories.

### Partial Results Display
When displaying partial results, use the following in the summary table:
```
| Category | Issues | Critical | Warnings |
|----------|--------|----------|----------|
| Settings | 3 | 0 | 2 |
| Code | INCOMPLETE | - | - |
| Specs | 1 | 0 | 1 |
| Tests | INCOMPLETE | - | - |
```

## Important Notes

- **Portability**: Do NOT hardcode project-specific paths. Agents discover structure themselves.
- **Thoroughness**: Provide goals, not checklists. Encourage autonomous exploration.
- **Tool usage**: Actively encourage Python script creation for analysis.
- **Report suspicious items**: Include uncertain findings - let humans decide.
