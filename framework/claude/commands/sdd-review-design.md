---
description: Strict spec review for test implementer clarity
allowed-tools: Glob, Read, Task, TeamCreate, TaskCreate, TaskUpdate, TaskList, SendMessage, TeamDelete
argument-hint: [feature-name] [--team] | [--cross-check] [--team] | [--wave N] [--team]
---

# SDD Design Review (Router)

<background_information>
- **Mission**: Comprehensive design review combining SDD compliance and exploratory analysis
- **Dual Architecture**:
  - **Subagent mode** (default): Router dispatches to 6 agents (5 parallel + 1 verifier) via Task tool
  - **Agent Team mode** (`--team`): Router creates team with 5 Sonnet reviewers + 1 Sonnet verifier; verifier synthesizes and returns result to Lead
- **Context Isolation**: Each agent/teammate runs in separate context window (no cross-contamination)
- **Philosophy**: Rulebase catches structural violations; exploration catches quality issues
- **Router's Role**: Orchestrate agents/teammates, synthesize (Team mode), display final results
</background_information>

<instructions>

## Core Task

Orchestrate comprehensive design review by:
1. Launching 5 review agents in parallel (data collection)
2. Passing results to verifier agent (cross-check and synthesis)
3. Displaying verifier's unified report (output)

**IMPORTANT**: Router only orchestrates and displays. All verification logic is in the verifier agent.

---

## Mode Detection

```
$ARGUMENTS = "{feature}"              → Single Review (Subagent mode)
$ARGUMENTS = "{feature} --team"       → Single Review (Agent Team mode)
$ARGUMENTS = "--wave N"               → Wave-Scoped Cross-Check (Subagent mode)
$ARGUMENTS = "--wave N --team"        → Wave-Scoped Cross-Check (Agent Team mode)
$ARGUMENTS = "--cross-check"          → Cross-Check (Subagent mode)
$ARGUMENTS = "--cross-check --team"   → Cross-Check (Agent Team mode)
$ARGUMENTS = ""                       → Cross-Check (Subagent mode)
```

**Note**: `--cross-check` is optional and equivalent to empty arguments. Wave-scoped mode limits scope to specs in waves 1..N.

### Agent Team Mode Detection

If `--team` flag is present in arguments:
1. Remove `--team` from arguments before further processing
2. Display: "Agent Team mode — spawning review team"
3. Skip Subagent Execution Flow, go to **Agent Team Execution Flow** section

---

## Pre-Flight: Validate Target

Before launching agents, validate target existence only:

### Single Spec Mode

1. **Validate Spec Exists**:
   - Check `{{KIRO_DIR}}/specs/{feature}/design.md` exists
   - If not found, report error and stop

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

## Subagent Execution Flow (default, without --team)

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
    │ Task: rulebase  │ │ Task:           │ │ Task: architecture  │
    │ (SDD compliance)│ │ testability     │ │ (design quality)    │
    └─────────────────┘ │ (test clarity)  │ └─────────────────────┘
                        └─────────────────┘
              ┌────────────────┼────────────────┐
              │                │                │
              ↓                ↓                ↓
    ┌─────────────────┐ ┌─────────────────────────────────────┐
    │ Task:           │ │ Task: best-practices                │
    │ consistency     │ │ (industry standards)                │
    │ (specs↔design)   │ └─────────────────────────────────────┘
    └─────────────────┘
```

**Agent Invocation**: For each agent, include in the prompt:
1. The agent's instructions (from `.claude/agents/sdd-review-design-*.md`)
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
Read and follow the instructions in `.claude/agents/sdd-review-design-{agent-name}.md`.

Feature: {feature} (or "cross-check" for all specs)

Execute the review and return your findings in the specified format.
```

**Wave-Scoped Cross-Check Mode**:
```
Read and follow the instructions in `.claude/agents/sdd-review-design-{agent-name}.md`.

Mode: wave-scoped-cross-check
Wave: {N}

Execute the wave-scoped cross-check review and return your findings.
```

Where `{agent-name}` is one of:
- `rulebase`
- `explore-testability`
- `explore-architecture`
- `explore-consistency`
- `explore-best-practices`

**IMPORTANT**: Do NOT embed context content in the prompt. Each agent reads its own context files.

### Verifier Agent

```
Read and follow the instructions in `.claude/agents/sdd-review-design-verifier.md`.

Feature: {feature} (or "cross-check" or "wave-scoped-cross-check")
Wave: {N} (wave-scoped mode only)

Agent Results:

## Rulebase Review Results
{rulebase agent output}

## Testability Review Results
{testability agent output}

## Architecture Review Results
{architecture agent output}

## Consistency Review Results
{consistency agent output}

## Best Practices Review Results
{best practices agent output}

Execute verification and return the unified report.
```

---

## Agent Team Execution Flow (when --team flag detected)

Skip the Subagent Execution Flow above. Use the following flow instead.

### Teammate Roles

All teammates are flat members of the review team. Lead receives only the final verdict.

| Role | Model | Responsibility |
|------|-------|---------------|
| **Lead** (this router) | Opus | Team creation, final report display. Does NOT process individual findings. |
| **review-verifier** | Opus | Collects findings from 5 reviewers, runs cross-check, synthesizes verdict. Sends only final CPF report to Lead. |
| **review-{agent-name}** ×5 | Sonnet | Independent review. Sends findings to review-verifier (NOT to Lead). |

**Context savings**: Lead never sees raw reviewer output. Only the verifier's synthesized report enters Lead's context.

### Team Phase 1: Team Creation & Spawn All 6 Teammates

1. **Create team**: `TeamCreate` with team name `sdd-review-design-{feature}` (or `sdd-review-design-cross-check`)
2. **Spawn review-verifier** AND **5 reviewers** in a SINGLE message (all 6 in parallel):

   **review-verifier** (name: `review-verifier`, model: opus):
   ```
   You are a WORKER agent. Do NOT spawn new teammates or subagents.
   Read `.claude/agents/sdd-review-design-verifier.md` and follow all instructions.
   Feature: {feature} (or "cross-check" / "wave-scoped-cross-check" with Wave: {N})

   Your role in this team:
   1. WAIT for 5 reviewer teammates to send you their CPF findings
   2. Once all 5 received, broadcast all findings back to all reviewers for cross-check:
      "All review findings below. Follow Cross-Check Protocol. Send REFINED findings to me.
       This is a single round — do NOT request further discussion.
       == Rulebase Findings ==
       {rulebase CPF}
       == Testability Findings ==
       ... (all 5)"
   3. WAIT for 5 REFINED responses
   4. Synthesize: merge, deduplicate, resolve contradictions, check over-engineering, determine verdict
      (follow all verification steps in your agent file)
   5. Send ONLY the final CPF report to the team lead. Do NOT send intermediate findings.
   ```

   **5 reviewers** (name: `review-{agent-name}`, model: sonnet), each with:
   ```
   You are a WORKER agent. Do NOT spawn new teammates or subagents.
   Read `.claude/agents/sdd-review-design-{agent-name}.md` and follow all instructions.
   Feature: {feature} (or "cross-check" / "wave-scoped-cross-check" with Wave: {N})
   After completing your review, send your complete CPF output to 'review-verifier' (NOT to the team lead).
   Do NOT format as markdown. Use the exact CPF format specified in the agent file.
   When review-verifier sends you all findings for cross-check, follow the Cross-Check Protocol
   in your agent instructions and send REFINED findings back to 'review-verifier'.
   ```
   Where `{agent-name}` is: `rulebase`, `explore-testability`, `explore-architecture`, `explore-consistency`, `explore-best-practices`

### Team Phase 2: Wait for Verifier Result

3. **Lead waits** for a single message from `review-verifier` containing the final CPF report
   - The verifier handles all cross-check orchestration internally (peer-to-peer with reviewers)
   - Lead does NOT interact with individual reviewers

### Team Phase 3: Clean Up & Display

4. **Clean up team**:
   - Send `shutdown_request` to all 6 teammates (`review-verifier` + 5 reviewers)
   - Wait for shutdown approvals, then `TeamDelete`

5. **Display results**: Use the **same Phase 3: Display Results** logic as the Subagent flow — parse the CPF output and format as human-readable markdown report.

---

## Error Handling

- **Missing spec**: "Spec '{feature}' not found. Run `/sdd-design \"description\"` first."
- **No design.md**: Report error - design.md is required
- **Agent failure** (Subagent mode): Report partial results from successful agents, note which failed
- **Teammate failure** (Team mode): If a teammate fails to respond, proceed with available results, note incomplete review
- **No specs found** (Cross-Check): "No specs found in `{{KIRO_DIR}}/specs/`. Create specs first."
- **Agent Team unavailable**: If TeamCreate fails, fall back to Subagent Execution Flow with warning

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
- If GO: Proceed with `/sdd-tasks {feature}` or implementation
- If CONDITIONAL: Address minor issues, optionally re-review
- If NO-GO: Fix critical issues and run `/sdd-review-design {feature}` again

**After Cross-Check / Wave-Scoped Cross-Check**:
- Address any cross-spec conflicts before parallel development
- Use dependency information to sequence implementation

</instructions>
