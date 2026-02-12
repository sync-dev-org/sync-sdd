---
description: Comprehensive requirements review (rulebase + exploratory)
allowed-tools: Glob, Read, Task
argument-hint: [<feature-name>] [--rulebase-only] | [--explore-only] | [--wave N]
---

# SDD Requirements Review (Router)

<background_information>
- **Mission**: Comprehensive requirements review combining verification and discovery
- **Architecture**: Router dispatches to 6 agents (5 parallel review + 1 sequential verifier) via Task tool
- **Context Isolation**: Each agent runs in separate context window (no cross-contamination)
- **Two Phases**:
  - **Phase 1**: 5 review agents run in parallel (rulebase + 4 exploratory)
  - **Phase 2**: Verifier agent cross-checks and synthesizes results
- **Philosophy**: Rules catch what we KNOW to check; exploration catches what we DON'T
- **Router's Role**: Orchestrate agents, display final results (do NOT duplicate verification logic)
</background_information>

<instructions>

## Core Task

Orchestrate comprehensive requirements review by:
1. Launching 5 review agents in parallel (data collection)
2. Passing results to verifier agent (cross-check and synthesis)
3. Displaying verifier's unified report (output)

**IMPORTANT**: Router only orchestrates and displays. All verification logic is in the verifier agent.

---

## Mode Detection

```
$ARGUMENTS = "{feature}"                 → Full Review (rulebase + explore)
$ARGUMENTS = "{feature} --rulebase-only" → Rulebase only
$ARGUMENTS = "{feature} --explore-only"  → Explore only (4 agents)
$ARGUMENTS = "--wave N"                  → Wave-Scoped Cross-Check (waves 1..N)
$ARGUMENTS = ""                          → Cross-Check mode (all specs)
```

**Note**: Cross-check mode runs all 6 agents across all specs. Wave-scoped mode limits scope to specs in waves 1..N.

---

## Pre-Flight: Validate Target

Before launching agents, validate target existence only:

### Single Spec Mode

1. **Validate Spec Exists**:
   - Check `{{KIRO_DIR}}/specs/{feature}/requirements.md` exists
   - If not found, report error and stop

### Cross-Check Mode

1. **Validate Specs Exist**:
   - Glob `{{KIRO_DIR}}/specs/*/requirements.md` to confirm specs exist
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
    ┌─────────────────┐ ┌─────────────┐ ┌─────────────────────┐
    │ Task: rulebase  │ │ Task:       │ │ Task: contradiction │
    │ (independent    │ │ completeness│ │ (independent        │
    │  context)       │ │ (independent│ │  context)           │
    └─────────────────┘ │  context)   │ └─────────────────────┘
                        └─────────────┘
              ┌────────────────┼────────────────┐
              │                │                │
              ↓                ↓                ↓
    ┌─────────────────┐ ┌─────────────────────────────────────┐
    │ Task: common-   │ │ Task: edge-case                     │
    │ sense           │ │ (independent context)               │
    │ (independent    │ └─────────────────────────────────────┘
    │  context)       │
    └─────────────────┘
```

**Agent Invocation**: For each agent, include in the prompt:
1. The agent's instructions (from `.claude/agents/sdd-review-requirement-*.md`)
2. Mode information (feature name, "cross-check", or "wave-scoped-cross-check" with wave number)

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
              │ - Produces unified report                           │
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
Read and follow the instructions in `.claude/agents/sdd-review-requirement-{agent-name}.md`.

Feature: {feature} (or "cross-check" for all specs)

Execute the review and return your findings in the specified format.
```

**Wave-Scoped Cross-Check Mode**:
```
Read and follow the instructions in `.claude/agents/sdd-review-requirement-{agent-name}.md`.

Mode: wave-scoped-cross-check
Wave: {N}

Execute the wave-scoped cross-check review and return your findings.
```

Where `{agent-name}` is one of:
- `rulebase`
- `explore-completeness`
- `explore-contradiction`
- `explore-common-sense`
- `explore-edge-case`

**IMPORTANT**: Do NOT embed context content in the prompt. Each agent reads its own context files.

### Verifier Agent

```
Read and follow the instructions in `.claude/agents/sdd-review-requirement-verifier.md`.

Feature: {feature} (or "cross-check" or "wave-scoped-cross-check")
Wave: {N} (wave-scoped mode only)

Agent Results:

## Rulebase Review Results
{rulebase agent output}

## Completeness Review Results
{completeness agent output}

## Contradiction Review Results
{contradiction agent output}

## Common Sense Review Results
{common sense agent output}

## Edge Case Review Results
{edge case agent output}

Execute verification and return the unified report.
```

---

## Mode-Specific Behavior

### --rulebase-only
- Launch only the rulebase agent
- Skip verifier (single agent doesn't need cross-check)
- Display rulebase output directly

### --explore-only
- Launch only the 4 exploratory agents in parallel
- Pass to verifier for synthesis
- No formal verdict (exploration is advisory)

### Cross-Check Mode (no feature specified)
- All 5 agents run across ALL specs
- Verifier synthesizes cross-spec findings
- Especially powerful for discovering systemic gaps

### Wave-Scoped Cross-Check Mode (--wave N)
- All 5+1 agents run across specs in waves 1..N only
- Each agent independently resolves wave scope via spec.json
- Specs in future waves (wave > N) are excluded from review
- roadmap.md is readable as advisory context (future plans, not requirements)
- Especially useful during incremental roadmap execution

---

## Error Handling

- **Missing spec**: "Spec '{feature}' not found. Run `/sdd-requirements \"description\"` first."
- **Agent failure**: Report partial results from successful agents, note which failed
- **Timeout**: Set reasonable limits, proceed with available results
- **No specs found** (Cross-Check): "No specs found in `{{KIRO_DIR}}/specs/`. Create specs first."

---

## Output

Router formats the verifier's compact output into a human-readable markdown report including:
- Executive summary with verdict and issue counts by severity
- Prioritized issues table (Critical → High → Medium → Low)
- Verification notes (removed false positives, resolved conflicts)
- Wave scope info and roadmap advisory (if wave-scoped mode)
- Recommended actions and next steps based on verdict

</instructions>
