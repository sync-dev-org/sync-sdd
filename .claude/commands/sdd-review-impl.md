---
description: Validate implementation against design, specifications, and tasks
allowed-tools: Glob, Read, Task, TeamCreate, TaskCreate, TaskUpdate, TaskList, SendMessage, TeamDelete
argument-hint: [feature-name] [task-numbers] [--team] | --cross-check [--team] | --wave N [--team]
---

# SDD Implementation Review (Router)

<background_information>
- **Mission**: Verify implementation aligns with design (specifications + architecture) and tasks
- **Dual Architecture**:
  - **Subagent mode** (default): Router dispatches to 6 agents (5 parallel + 1 verifier) via Task tool
  - **Agent Team mode** (`--team`): Router creates team with 5 Sonnet teammates + Lead synthesis
- **Context Isolation**: Each agent/teammate runs in separate context window (no cross-contamination)
- **Philosophy**: Each agent has a unique perspective; isolation enables independent discovery
- **Router's Role**: Orchestrate agents/teammates, synthesize (Team mode), display final results
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
$ARGUMENTS = "{feature} {tasks}"       → Single Review, specific tasks (Subagent mode)
$ARGUMENTS = "{feature}"               → Single Review, all completed (Subagent mode)
$ARGUMENTS = "{feature} --team"        → Single Review (Agent Team mode)
$ARGUMENTS = "{feature} {tasks} --team" → Single Review, specific tasks (Agent Team mode)
$ARGUMENTS = "--wave N"                → Wave-Scoped Cross-Check (Subagent mode)
$ARGUMENTS = "--wave N --team"         → Wave-Scoped Cross-Check (Agent Team mode)
$ARGUMENTS = "--cross-check"           → Cross-Check (Subagent mode)
$ARGUMENTS = "--cross-check --team"    → Cross-Check (Agent Team mode)
$ARGUMENTS = ""                        → Cross-Check (Subagent mode)
```

**Note**: `--cross-check` is optional and equivalent to empty arguments. Wave-scoped mode limits scope to specs in waves 1..N.

### Agent Team Mode Detection

If `--team` flag is present in arguments:
1. Remove `--team` from arguments before further processing
2. Display: "Agent Team mode — spawning review team"
3. Skip Subagent Execution Flow, go to **Agent Team Execution Flow** section

---

## Pre-Flight: Validate Target

Before launching agents, validate target existence and parse task scope only:

### Single Spec Mode

1. **Parse Task Scope**:
   - If `$ARGUMENTS` contains task numbers (e.g., `feature 1.1,1.2`): scope to those tasks
   - If only feature name: scope to all completed tasks `[x]` in tasks.md

2. **Validate Spec Exists**:
   - Check `{{KIRO_DIR}}/specs/{feature}/design.md` exists
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

## Agent Team Execution Flow (when --team flag detected)

Skip the Subagent Execution Flow above. Use the following flow instead.

### Team Phase 1: Team Creation & Independent Review

1. **Create team**: `TeamCreate` with team name `sdd-review-impl-{feature}` (or `sdd-review-impl-cross-check`)
2. **Spawn 5 teammates** (model: sonnet) in a SINGLE message, each with `name: "review-{agent-name}"` and prompt:
   ```
   You are a WORKER agent. Do NOT spawn new teammates or subagents.
   Read `.claude/agents/sdd-review-impl-{agent-name}.md` and follow all instructions.
   Feature: {feature} (or "cross-check" / "wave-scoped-cross-check" with Wave: {N})
   Task Scope: {task_scope} (e.g., "1.1, 1.2" or "all completed tasks")
   After completing your review, send your complete CPF output to the team lead.
   Do NOT format as markdown. Use the exact CPF format specified in the agent file.
   ```
   Where `{agent-name}` is: `rulebase`, `explore-interface`, `explore-test`, `explore-quality`, `explore-consistency`
   Teammate names: `review-rulebase`, `review-explore-interface`, `review-explore-test`, `review-explore-quality`, `review-explore-consistency`
3. **Wait** for all 5 teammates to send findings (idle notifications with CPF output)

### Team Phase 2: Cross-Check Broadcast

4. **Collect** all 5 CPF outputs from teammate messages
5. **Broadcast** to all teammates:
   ```
   All review findings are below. Follow the Cross-Check Protocol section in your
   agent instructions. Send REFINED findings back to the team lead.
   This is a single round — do NOT request further discussion.

   == Rulebase Findings ==
   {rulebase CPF}
   == Interface Findings ==
   {interface CPF}
   == Test Findings ==
   {test CPF}
   == Quality Findings ==
   {quality CPF}
   == Consistency Findings ==
   {consistency CPF}
   ```
6. **Wait** for all 5 refined responses (REFINED + CROSS-REF format)

### Team Phase 3: Lead Synthesis

The Lead (this router) performs synthesis directly — no separate verifier agent.

**Step 1: Merge refined findings**
- `confirmed` by 2+ teammates → high confidence, keep
- `withdrawn` → remove from final report
- `upgraded` → use new severity
- `downgraded` → use new severity

**Step 2: Deduplicate**
- Same issue from multiple teammates → single finding, list all agents with `+` separator
- Use CROSS-REF data to identify correlated findings

**Step 3: Resolve contradictions**
Key impl-specific cross-checks:
- Interface says signature mismatch → Does Test show related failures?
- Rulebase says file missing → Does Interface/Quality confirm?
- Test says passing → Does Interface confirm signatures are actually correct?
- Quality says dead code → Does Rulebase show it's not required by any task?

**Step 4: Spec defect detection**
Distinguish spec defects from implementation defects:

| Signal | Classified Phase | Rationale |
|--------|-----------------|-----------|
| Multiple teammates flag same specification as unimplementable | `specifications` | AC is contradictory or impossible |
| Interface finds design contract impossible to implement | `design` | Architecture/interface mismatch |
| Test finds actual behavior contradicts a specification | `specifications` | AC doesn't match real-world behavior |
| Design components reference non-existent spec ID | `design` | Traceability broken |
| AC is ambiguous — implementation chose one interpretation, another is equally valid | `specifications` | AC needs tightening |
| Design specifies interface but no spec requires it (orphan component) | `design` | Over-design without spec backing |

If spec defect detected, classify affected phase (`specifications` or `design`) for SPEC_FEEDBACK.
When ambiguous, prefer `specifications` — fixing the WHAT is safer than fixing the HOW.

**Step 5: Over-implementation check**
Guard against AI complexity bias:
- Code implements features not in design → flag as over-implementation
- Error handling for cases design doesn't specify → downgrade or remove
- Helper/utility extracted for single use → suggest inline
- "Best practice" is not justification for exceeding design scope

**Step 6: Decision suggestions**
Identify implementation choices that are intentional rather than defects:
- Suggest documenting as Decision in `steering/` (project-wide) or `design.md` (feature-specific)

**Step 7: Verdict**
```
IF any Critical issues remain:                           → VERDICT = NO-GO
ELSE IF spec defect detected (root cause is spec):       → VERDICT = SPEC-UPDATE-NEEDED
ELSE IF >3 High OR test failures OR interface mismatches: → VERDICT = CONDITIONAL
ELSE IF only Medium/Low AND tests pass:                  → VERDICT = GO
```
Precedence: NO-GO > SPEC-UPDATE-NEEDED > CONDITIONAL > GO. You MAY override with justification.

**Step 8: Generate CPF output**
```
VERDICT:{GO|CONDITIONAL|NO-GO|SPEC-UPDATE-NEEDED}
SCOPE:{feature} | cross-check | wave-scoped-cross-check
WAVE_SCOPE:{range} (wave-scoped mode only)
SPECS_IN_SCOPE:{spec-a},{spec-b} (wave-scoped mode only)
VERIFIED:
{agents}|{sev}|{category}|{location}|{description}
REMOVED:
{agent}|{reason}|{original issue}
RESOLVED:
{agents}|{resolution}|{conflicting findings}
SPEC_FEEDBACK: (only when VERDICT is SPEC-UPDATE-NEEDED)
{phase}|{spec}|{description}
NOTES:
{synthesis observations}
ROADMAP_ADVISORY: (wave-scoped mode only)
{future wave considerations}
```

**Step 9: Clean up**
- Send `shutdown_request` to each teammate by name:
  ```
  SendMessage(type: "shutdown_request", recipient: "review-rulebase", content: "Review complete")
  SendMessage(type: "shutdown_request", recipient: "review-explore-interface", content: "Review complete")
  ... (all 5 teammates)
  ```
- Wait for shutdown approvals, then `TeamDelete` to clean up team resources

### Team Phase 4: Display Results

Use the **same Phase 3: Display Results** logic as the Subagent flow — parse the CPF output and format as human-readable markdown report.

---

## Error Handling

- **Missing spec**: "Spec '{feature}' not found. Run `/sdd-design \"description\"` first."
- **No tasks.md**: "No tasks found for '{feature}'. Run `/sdd-tasks {feature}` first."
- **No design.md**: Proceed with review (agents will note missing design), warn user
- **No completed tasks**: "No completed tasks found. Run `/sdd-impl {feature}` first."
- **Agent failure** (Subagent mode): Report partial results from successful agents, note which failed
- **Teammate failure** (Team mode): If a teammate fails to respond, proceed with available results, note incomplete review
- **No specs found** (Cross-Check): "No specs found in `{{KIRO_DIR}}/specs/`. Create specs first."
- **Single implementation** (Cross-Check): "Cross-check requires 2+ implementations. Use `/sdd-review-impl {feature}` for single review."
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
- If GO: Implementation validated, proceed to deployment or next feature
- If CONDITIONAL: Address high-priority issues, re-run `/sdd-review-impl {feature}` after fixes
- If NO-GO: Fix critical issues, re-run `/sdd-impl {feature} [tasks]`, then re-review
- If SPEC-UPDATE-NEEDED: The specification itself has defects. Display SPEC_FEEDBACK details prominently:
  - For each feedback entry: "Spec defect in **{phase}** for **{spec}**: {description}"
  - If phase=specifications: "Run `/sdd-design {spec}` to fix specifications, then re-run `/sdd-tasks`"
  - If phase=design: "Run `/sdd-design {spec}` to update design, then re-run `/sdd-tasks`"
  - Do NOT suggest re-implementation until spec is fixed
  - **Note**: This review command does not modify spec.json (reviews are read-only). Phase rollback occurs automatically when run via `/sdd-roadmap-run` (Step 6.5/8T). For standalone use, `/sdd-design {spec}` resets the phase when invoked.

**After Cross-Check / Wave-Scoped Cross-Check**:
- Address cross-feature compatibility issues before integration
- Use consistency findings to align patterns across features
- Re-run `/sdd-review-impl --cross-check` (or `--wave N`) after fixes

</instructions>
