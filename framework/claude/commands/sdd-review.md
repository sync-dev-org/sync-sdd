---
description: Multi-agent review (design, implementation, or dead code)
allowed-tools: Bash, Glob, Grep, Read, Write, Edit
argument-hint: design|impl|dead-code <feature-name> [--wave N] [--cross-check]
---

# SDD Review (Dispatcher)

<instructions>

## Core Task

Orchestrate multi-agent review by spawning Inspectors and Auditor directly.

## Step 1: Parse Arguments

```
$ARGUMENTS = "design {feature}"           → Design review (single spec)
$ARGUMENTS = "design --cross-check"       → Design review (all specs)
$ARGUMENTS = "design --wave N"            → Design review (wave-scoped)
$ARGUMENTS = "impl {feature}"             → Implementation review (single spec)
$ARGUMENTS = "impl {feature} {tasks}"     → Implementation review (specific tasks)
$ARGUMENTS = "impl --cross-check"         → Implementation review (all specs)
$ARGUMENTS = "impl --wave N"              → Implementation review (wave-scoped)
$ARGUMENTS = "dead-code"                  → Dead code review
$ARGUMENTS = "dead-code --full"           → Dead code review (full mode)
```

If first argument is missing or not one of `design`, `impl`, `dead-code`:
- Error: "Usage: `/sdd-review design|impl|dead-code {feature}`"

## Step 2: Phase Gate

### Design Review
- Verify `{{SDD_DIR}}/project/specs/{feature}/design.md` exists
- No phase restriction

### Implementation Review
- Verify `design.md` and `tasks.md` exist
- Verify `phase` is `tasks-generated` or `implementation-complete`

### Dead Code Review
- No phase gate (operates on entire codebase)

## Step 3: Spawn Review Pipeline

### Design Review

Spawn 5 design Inspectors + 1 design Auditor:
- `sdd-inspector-rulebase` (sonnet): "Feature: {feature}, Report to: sdd-auditor-design"
- `sdd-inspector-testability` (sonnet): "Feature: {feature}, Report to: sdd-auditor-design"
- `sdd-inspector-architecture` (sonnet): "Feature: {feature}, Report to: sdd-auditor-design"
- `sdd-inspector-consistency` (sonnet): "Feature: {feature}, Report to: sdd-auditor-design"
- `sdd-inspector-best-practices` (sonnet): "Feature: {feature}, Report to: sdd-auditor-design"
- `sdd-auditor-design` (opus): "Feature: {feature}, Expect: 5 Inspector results via SendMessage"

Inspectors send CPF results directly to Auditor via SendMessage.
Read Auditor's verdict from completion output. Dismiss all review teammates.

### Implementation Review

Spawn 5 impl Inspectors + 1 impl Auditor:
- `sdd-inspector-impl-rulebase` (sonnet): "Feature: {feature}, Report to: sdd-auditor-impl"
- `sdd-inspector-interface` (sonnet): "Feature: {feature}, Report to: sdd-auditor-impl"
- `sdd-inspector-test` (sonnet): "Feature: {feature}, Report to: sdd-auditor-impl"
- `sdd-inspector-quality` (sonnet): "Feature: {feature}, Report to: sdd-auditor-impl"
- `sdd-inspector-impl-consistency` (sonnet): "Feature: {feature}, Report to: sdd-auditor-impl"
- `sdd-auditor-impl` (opus): "Feature: {feature}, Expect: 5 Inspector results via SendMessage"

Inspectors send CPF results directly to Auditor via SendMessage.
Read Auditor's verdict from completion output. Dismiss all review teammates.

### Dead Code Review

Parse Mode from arguments (default: `full`):

| Mode | Inspectors |
|------|-----------|
| `full` (default) | dead-settings, dead-code, dead-specs, dead-tests |
| `settings` | dead-settings |
| `code` | dead-code |
| `specs` | dead-specs |
| `tests` | dead-tests |

Spawn selected dead-code Inspectors + `sdd-auditor-dead-code` (opus).
Read Auditor's verdict from completion output. Dismiss all review teammates.

## Step 4: Handle Verdict

1. Parse CPF output from Auditor
2. Format as human-readable markdown report:
   - Executive Summary (verdict + issue counts by severity)
   - Prioritized Issues table (Critical → High → Medium → Low)
   - Verification Notes (removed false positives, resolved conflicts)
   - Recommended actions based on verdict

3. Display formatted report to user

4. **Auto-Fix Loop** (design/impl review only):
   - If NO-GO or SPEC-UPDATE-NEEDED:
     a. Extract fix instructions from Auditor's verdict
     b. Track retry count (max 3)
     c. Determine fix scope and spawn fix teammates:
        - **NO-GO (design)**: spawn Architect with fix instructions
        - **NO-GO (impl)**: spawn Builder(s) with fix instructions
        - **SPEC-UPDATE-NEEDED**: cascade: spawn Architect → dismiss → spawn Planner → dismiss → spawn Builder(s)
     d. Read fix teammate's completion report
     e. Dismiss fix teammate
     f. Update spec.json (version_refs, phase) and `{{SDD_DIR}}/handover/conductor.md`
     g. Re-spawn review pipeline (Step 3) with same review type
     h. If 3 retries exhausted: present final verdict and options to user

5. **Process STEERING entries** from verdict:
   - CODIFY → apply directly to steering file + append to log.md
   - PROPOSE → present to user for approval

6. Update `{{SDD_DIR}}/handover/conductor.md` with review results

### Next Steps by Verdict

**Design Review**:
- GO → `/sdd-tasks {feature}`
- CONDITIONAL → Address issues, optionally re-review
- NO-GO → Auto-fix loop or manual fix

**Implementation Review**:
- GO → Feature complete
- CONDITIONAL → Address issues
- NO-GO → Auto-fix loop or manual fix
- SPEC-UPDATE-NEEDED → Fix spec first (auto-fix from Architect level)

</instructions>

## Error Handling

- **Missing spec**: "Spec '{feature}' not found. Run `/sdd-design \"description\"` first."
- **Missing design.md**: "Design required. Run `/sdd-design {feature}` first."
- **Wrong phase for impl**: "Phase is '{phase}'. Run `/sdd-tasks {feature}` first."
- **No specs found (cross-check)**: "No specs found. Create specs first."
