---
description: Comprehensive requirements review (rulebase + exploratory)
allowed-tools: Glob, Read, Task
argument-hint: [<feature-name>] [--rulebase-only] | [--explore-only]
---

# SDD Requirements Review (Router)

<background_information>
- **Mission**: Comprehensive requirements review combining verification and discovery
- **Architecture**: Router dispatches to 6 independent agents via Task tool
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
$ARGUMENTS = ""                          → Cross-Check mode (all specs)
```

**Note**: Cross-check mode runs all 6 agents across all specs.

---

## Pre-Flight: Load Context

Before launching agents, gather context to pass to them:

### Single Spec Mode

1. **Target Spec**:
   - Read `{{KIRO_DIR}}/specs/{feature}/requirements.md`
   - Read `{{KIRO_DIR}}/specs/{feature}/spec.json` for metadata

2. **Steering Context**:
   - Read entire `{{KIRO_DIR}}/steering/` directory
   - Extract: product goals, user personas, technical constraints

3. **Related Specs** (if any):
   - Glob `{{KIRO_DIR}}/specs/*/requirements.md`
   - Identify specs that might interact with target

### Cross-Check Mode

1. **All Specs**:
   - Glob `{{KIRO_DIR}}/specs/*/requirements.md` to list all specs
   - Read ALL requirements.md files
   - Read ALL spec.json files for metadata and dependencies

2. **Steering Context**:
   - Read entire `{{KIRO_DIR}}/steering/` directory

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
2. The gathered context (requirements, steering, related specs)
3. Mode information (feature name or "cross-check")

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

Router displays the verifier's output directly. Do NOT modify or summarize.

---

## Agent Prompt Templates

### Rulebase Agent

```
Read and follow the instructions in `.claude/agents/sdd-review-requirement-rulebase.md`.

Feature: {feature} (or "cross-check" for all specs)

Context:
- Requirements: {requirements content}
- Steering: {steering content}
- Spec metadata: {spec.json content}

Execute the review and return your findings in the specified format.
```

### Completeness Agent

```
Read and follow the instructions in `.claude/agents/sdd-review-requirement-explore-completeness.md`.

Feature: {feature} (or "cross-check" for all specs)

Context:
- Requirements: {requirements content}
- Steering: {steering content}
- Related specs: {related specs if any}

Execute the review and return your findings in the specified format.
```

### Contradiction Agent

```
Read and follow the instructions in `.claude/agents/sdd-review-requirement-explore-contradiction.md`.

Feature: {feature} (or "cross-check" for all specs)

Context:
- Requirements: {requirements content}
- Steering: {steering content}
- Related specs: {related specs if any}

Execute the review and return your findings in the specified format.
```

### Common Sense Agent

```
Read and follow the instructions in `.claude/agents/sdd-review-requirement-explore-common-sense.md`.

Feature: {feature} (or "cross-check" for all specs)

Context:
- Requirements: {requirements content}
- Steering: {steering content}

Execute the review and return your findings in the specified format.
```

### Edge Case Agent

```
Read and follow the instructions in `.claude/agents/sdd-review-requirement-explore-edge-case.md`.

Feature: {feature} (or "cross-check" for all specs)

Context:
- Requirements: {requirements content}
- Technical constraints: {tech.md content}

Execute the review and return your findings in the specified format.
```

### Verifier Agent

```
Read and follow the instructions in `.claude/agents/sdd-review-requirement-verifier.md`.

Feature: {feature} (or "cross-check" for all specs)

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

---

## Error Handling

- **Missing spec**: "Spec '{feature}' not found. Run `/sdd-requirements \"description\"` first."
- **Agent failure**: Report partial results from successful agents, note which failed
- **Timeout**: Set reasonable limits, proceed with available results
- **No specs found** (Cross-Check): "No specs found in `{{KIRO_DIR}}/specs/`. Create specs first."

---

## Output

Display the verifier's unified report directly. The report includes:
- Executive summary with verdicts
- Prioritized issues (Critical → High → Medium → Low)
- Verification notes (contradictions resolved, false positives removed)
- Raw agent reports in collapsible sections
- Recommended actions
- Next steps based on verdict

</instructions>
