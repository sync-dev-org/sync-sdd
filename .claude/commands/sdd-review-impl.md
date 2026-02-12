---
description: Validate implementation against requirements, design, and tasks
allowed-tools: Glob, Read, Task
argument-hint: [feature-name] [task-numbers] | --cross-check | --wave N
---

# SDD Implementation Review (Router)

<background_information>
- **Mission**: Verify implementation aligns with approved requirements, design, and tasks
- **Architecture**: Router dispatches to 6 independent agents via Task tool
- **Context Isolation**: Each agent runs in separate context window (no cross-contamination)
- **Two Phases**:
  - **Phase 1**: 5 review agents run in parallel (rulebase + 4 exploratory)
  - **Phase 2**: Verifier agent cross-checks and synthesizes results
- **Philosophy**: Each agent has a unique perspective; isolation enables independent discovery
- **Router's Role**: Orchestrate agents, display final results (do NOT duplicate verification logic)
</background_information>

<instructions>

## Core Task

Orchestrate comprehensive implementation review by:
1. Gathering context (specs, steering, implementation files)
2. Launching 5 review agents in parallel (data collection)
3. Passing results to verifier agent (cross-check and synthesis)
4. Displaying verifier's unified report (output)

**IMPORTANT**: Router only orchestrates and displays. All verification logic is in the agents.

---

## Mode Detection

```
$ARGUMENTS = "{feature} {tasks}"  → Single Review (specific tasks only)
$ARGUMENTS = "{feature}"          → Single Review (all completed tasks)
$ARGUMENTS = "--wave N"           → Wave-Scoped Cross-Check (waves 1..N)
$ARGUMENTS = "--cross-check"      → Cross-Check (all implemented features)
$ARGUMENTS = ""                   → Cross-Check (auto-detect)
```

**Note**: `--cross-check` is optional and equivalent to empty arguments. Wave-scoped mode limits scope to specs in waves 1..N.

---

## Pre-Flight: Validate Target

Before launching agents, validate target existence and parse task scope only:

### Single Spec Mode

1. **Parse Task Scope**:
   - If `$ARGUMENTS` contains task numbers (e.g., `feature 1.1,1.2`): scope to those tasks
   - If only feature name: scope to all completed tasks `[x]` in tasks.md

2. **Validate Spec Exists**:
   - Check `{{KIRO_DIR}}/specs/{feature}/requirements.md` exists
   - Check `{{KIRO_DIR}}/specs/{feature}/tasks.md` exists
   - If spec not found, report error and stop
   - If no tasks.md, report error and stop

### Cross-Check Mode

1. **Validate Specs Exist**:
   - Glob `{{KIRO_DIR}}/specs/*/spec.json` to confirm specs exist
   - If none found, report error and stop

### Wave-Scoped Cross-Check Mode

1. **Parse Wave Number**:
   - Extract N from `--wave N` argument
   - If N is not a positive integer, report error and stop

2. **Validate Wave Specs Exist**:
   - Glob `{{KIRO_DIR}}/specs/*/spec.json`
   - Read each spec.json, filter where `roadmap.wave <= N`
   - If no specs found for waves 1..N, report error and stop

**IMPORTANT**: Do NOT read file contents here. Each agent loads its own context independently (context isolation principle).

---

## Execution Flow

### Phase 1: Parallel Review Agents

Launch 5 agents **in parallel** using Task tool with `subagent_type: "general-purpose"`:

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Router Process                               │
└──────────────────────────────┬──────────────────────────────────────┘
                               │
              ┌────────────────┼────────────────┐
              │                │                │
              ↓                ↓                ↓
    ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────────┐
    │ Task: rulebase  │ │ Task: interface │ │ Task: test          │
    │ (spec compliance│ │ (contracts)     │ │ (execution/quality) │
    └─────────────────┘ └─────────────────┘ └─────────────────────┘
              ┌────────────────┼────────────────┐
              │                                 │
              ↓                                 ↓
    ┌─────────────────┐               ┌─────────────────────┐
    │ Task: quality   │               │ Task: consistency   │
    │ (code patterns) │               │ (cross-feature)     │
    └─────────────────┘               └─────────────────────┘
```

**Agent Invocation**: For each agent, include in the prompt:
1. The agent's instructions (from `.claude/agents/sdd-review-impl-*.md`)
2. Mode information (feature name + task scope, "cross-check", or "wave-scoped-cross-check" with wave number)

**NOTE**: Do NOT pass context content. Each agent loads its own context independently.

**CRITICAL**: Launch all 5 Task calls in a SINGLE message for true parallel execution.

### Phase 2: Verification Agent

After all 5 agents complete, launch verifier:

```
              ┌────────────────────────────────────────────────────┐
              │ Collect results from 5 agents                       │
              └───────────────────────┬────────────────────────────┘
                                      │
                                      ↓
              ┌────────────────────────────────────────────────────┐
              │ Task: verifier                                      │
              │ - Receives all 5 agent results                      │
              │ - Cross-checks findings                             │
              │ - Produces unified report with GO/COND/NO-GO        │
              └───────────────────────┬────────────────────────────┘
                                      │
                                      ↓
              ┌────────────────────────────────────────────────────┐
              │ Router displays verifier's report                   │
              └────────────────────────────────────────────────────┘
```

### Phase 3: Display Results

Router transforms verifier's compact output into human-readable report:

1. **Parse verifier output**:
   - Metadata lines: `KEY:VALUE` format (VERDICT, SCOPE, WAVE_SCOPE, SPECS_IN_SCOPE)
   - VERIFIED lines: split by `|` → agents, sev, cat, loc, desc
   - REMOVED lines: split by `|` → agent, reason, original
   - RESOLVED lines: split by `|` → agents, resolution, findings
   - SPEC_FEEDBACK lines: split by `|` → phase, spec, description (only when VERDICT is SPEC-UPDATE-NEEDED)
   - NOTES/ROADMAP_ADVISORY: freeform text lines
   - Missing sections = no findings of that type
   - Agents field: split by `+` for agent list

2. **Format as markdown report**:
   - Executive Summary (verdict + issue counts by severity)
   - Prioritized Issues table (Critical → High → Medium → Low)
   - Verification Notes (removed false positives, resolved conflicts)
   - Wave Scope info (if wave-scoped mode)
   - Roadmap advisory (if wave-scoped mode)
   - Recommended actions based on verdict

3. **Display formatted report** to user

**IMPORTANT**: All formatting logic lives in the router. Agents NEVER produce markdown tables, headers, or human-readable prose in their output.

---

## Agent Prompt Templates

### Review Agents (Rulebase + 4 Exploratory)

All 5 review agents use the same minimal prompt format:

**Single Spec or Cross-Check Mode**:
```
Read and follow the instructions in `.claude/agents/sdd-review-impl-{agent-name}.md`.

Feature: {feature} (or "cross-check" for all specs)
Task Scope: {task_scope} (e.g., "1.1, 1.2" or "all completed tasks")

Execute the review and return your findings in the specified format.
```

**Wave-Scoped Cross-Check Mode**:
```
Read and follow the instructions in `.claude/agents/sdd-review-impl-{agent-name}.md`.

Mode: wave-scoped-cross-check
Wave: {N}

Execute the wave-scoped cross-check review and return your findings.
```

Where `{agent-name}` is one of:
- `rulebase`
- `explore-interface`
- `explore-test`
- `explore-quality`
- `explore-consistency`

**IMPORTANT**: Do NOT embed context content in the prompt. Each agent reads its own context files.

### Verifier Agent

```
Read and follow the instructions in `.claude/agents/sdd-review-impl-verifier.md`.

Feature: {feature} (or "cross-check" or "wave-scoped-cross-check")
Wave: {N} (wave-scoped mode only)
Task Scope: {task_scope}

Agent Results:

## Rulebase Review Results
{rulebase agent output}

## Interface Review Results
{interface agent output}

## Test Review Results
{test agent output}

## Quality Review Results
{quality agent output}

## Consistency Review Results
{consistency agent output}

Execute verification and return the unified report.
```

---

## Error Handling

- **Missing spec**: "Spec '{feature}' not found. Run `/sdd-requirements \"description\"` first."
- **No tasks.md**: "No tasks found for '{feature}'. Run `/sdd-tasks {feature}` first."
- **No design.md**: Proceed with review (agents will note missing design), warn user
- **No completed tasks**: "No completed tasks found. Run `/sdd-impl {feature}` first."
- **Agent failure**: Report partial results from successful agents, note which failed
- **No specs found** (Cross-Check): "No specs found in `{{KIRO_DIR}}/specs/`. Create specs first."
- **Single implementation** (Cross-Check): "Cross-check requires 2+ implementations. Use `/sdd-review-impl {feature}` for single review."

---

## Output

Router formats the verifier's compact output into a human-readable markdown report including:
- Executive summary with verdict and issue counts by severity
- Prioritized issues table (Critical → High → Medium → Low)
- Verification notes (removed false positives, resolved conflicts)
- Wave scope info and roadmap advisory (if wave-scoped mode)
- Recommended actions and next steps based on verdict

### Next Steps

**After Single Review**:
- If GO: Implementation validated, proceed to deployment or next feature
- If CONDITIONAL: Address high-priority issues, re-run `/sdd-review-impl {feature}` after fixes
- If NO-GO: Fix critical issues, re-run `/sdd-impl {feature} [tasks]`, then re-review
- If SPEC-UPDATE-NEEDED: The specification itself has defects. Display SPEC_FEEDBACK details prominently:
  - For each feedback entry: "Spec defect in **{phase}** for **{spec}**: {description}"
  - If phase=requirements: "Run `/sdd-requirements {spec}` to update requirements, then re-run `/sdd-design` and `/sdd-tasks`"
  - If phase=design: "Run `/sdd-design {spec}` to update design, then re-run `/sdd-tasks`"
  - Do NOT suggest re-implementation until spec is fixed

**After Cross-Check / Wave-Scoped Cross-Check**:
- Address cross-feature compatibility issues before integration
- Use consistency findings to align patterns across features
- Re-run `/sdd-review-impl --cross-check` (or `--wave N`) after fixes

</instructions>
