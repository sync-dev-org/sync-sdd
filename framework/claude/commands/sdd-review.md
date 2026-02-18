---
description: Multi-agent review (design, implementation, or dead code)
allowed-tools: Bash, Glob, Grep, Read, Write, Edit, AskUserQuestion
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
$ARGUMENTS = "dead-code"                  → Dead code review (full mode, default)
$ARGUMENTS = "dead-code settings"         → Dead code review (settings only)
$ARGUMENTS = "dead-code code"             → Dead code review (code only)
$ARGUMENTS = "dead-code specs"            → Dead code review (specs only)
$ARGUMENTS = "dead-code tests"            → Dead code review (tests only)
```

If first argument is missing or not one of `design`, `impl`, `dead-code`:
- Error: "Usage: `/sdd-review design|impl|dead-code {feature}`"

## Step 2: Phase Gate

### Design Review
- Verify `{{SDD_DIR}}/project/specs/{feature}/design.md` exists
- No phase restriction
- BLOCK if `spec.yaml.phase` is `blocked`: "{feature} is blocked by {blocked_info.blocked_by}"

### Implementation Review
- Verify `design.md` and `tasks.yaml` exist
- Verify `phase` is `implementation-complete`
- BLOCK if `spec.yaml.phase` is `blocked`: "{feature} is blocked by {blocked_info.blocked_by}"

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
     b. Track counters: `retry_count` for NO-GO (max 3), `spec_update_count` for SPEC-UPDATE-NEEDED (max 2)
     c. Determine fix scope and spawn fix teammates:
        - **NO-GO (design)**: increment `retry_count`, spawn Architect with fix instructions
        - **NO-GO (impl)**: increment `retry_count`, spawn Builder(s) with fix instructions
        - **SPEC-UPDATE-NEEDED**: increment `spec_update_count`. Reset `orchestration.last_phase_action = null`, set `phase = design-generated`. Cascade: spawn Architect (include SPEC_FEEDBACK from Auditor in spawn prompt) → dismiss → spawn TaskGenerator → dismiss → spawn Builder(s). All tasks are fully re-implemented (no differential).
     d. Read fix teammate's completion report
     e. Dismiss fix teammate
     f. Update spec.yaml (version_refs, phase) and auto-draft `{{SDD_DIR}}/handover/session.md`
     g. Re-spawn review pipeline (Step 3) with same review type
     h. If `retry_count` ≥ 3 or `spec_update_count` ≥ 2: present final verdict and options to user

5. **Process STEERING entries** from verdict:
   - CODIFY → apply directly to steering file + append to `decisions.md` with Reason (STEERING_UPDATE)
   - PROPOSE → present to user for approval → append to `decisions.md` (STEERING_UPDATE if approved, STEERING_EXCEPTION or USER_DECISION if rejected)

6. Auto-draft `{{SDD_DIR}}/handover/session.md`

**Auditor context**: When spawning Auditor, include the Steering Exceptions section from `{{SDD_DIR}}/handover/session.md` (if exists) so Auditor can recognize intentional deviations and avoid false-positive flags.

### Next Steps by Verdict

CONDITIONAL = GO (proceed). Remaining issues are tracked but do not block advancement. CONDITIONAL does NOT increment `retry_count`.

**Design Review**:
- GO/CONDITIONAL → `/sdd-impl {feature}`
- NO-GO → Auto-fix loop or manual fix

**Implementation Review**:
- GO/CONDITIONAL → Feature complete
- NO-GO → Auto-fix loop or manual fix
- SPEC-UPDATE-NEEDED → Fix spec first (auto-fix from Architect level)

</instructions>

## Error Handling

- **Missing spec**: "Spec '{feature}' not found. Run `/sdd-design \"description\"` first."
- **Missing design.md**: "Design required. Run `/sdd-design {feature}` first."
- **Wrong phase for impl**: "Phase is '{phase}'. Run `/sdd-impl {feature}` first."
- **Blocked**: "{feature} is blocked by {blocked_info.blocked_by}."
- **No specs found (cross-check)**: "No specs found. Create specs first."
