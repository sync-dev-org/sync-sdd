---
description: Multi-agent review (design, implementation, or dead code)
allowed-tools: Glob, Read, SendMessage
argument-hint: design|impl|dead-code <feature-name> [--wave N] [--cross-check]
---

# SDD Review (Dispatcher)

<instructions>

## Core Task

Orchestrate multi-agent review via Coordinator → Inspector ×5 + Auditor pipeline.

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

## Step 3: Dispatch to Coordinator

### Design Review

```
設計レビュー feature={feature}
Mode: {single|cross-check|wave-scoped}
Wave: {N} (wave-scoped only)
```

Coordinator will request spawn of:
- 5 design Inspectors (rulebase, testability, architecture, consistency, best-practices)
- 1 design Auditor

### Implementation Review

```
実装レビュー feature={feature}
Mode: {single|cross-check|wave-scoped}
Tasks: {task numbers} (if specified)
Wave: {N} (wave-scoped only)
```

Coordinator will request spawn of:
- 5 impl Inspectors (impl-rulebase, interface, test, quality, impl-consistency)
- 1 impl Auditor

### Dead Code Review

```
デッドコードレビュー
Mode: {full|settings|code|specs|tests}
```

Coordinator will request spawn of:
- 4 dead-code Inspectors (dead-settings, dead-code, dead-specs, dead-tests)
- 1 dead-code Auditor

Enter Conductor Message Loop: handle Coordinator's typed messages until PIPELINE_COMPLETE.

## Step 4: Handle Verdict

After Coordinator reports Auditor's final verdict:

1. Parse CPF output from Auditor
2. Format as human-readable markdown report:
   - Executive Summary (verdict + issue counts by severity)
   - Prioritized Issues table (Critical → High → Medium → Low)
   - Verification Notes (removed false positives, resolved conflicts)
   - Recommended actions based on verdict

3. Display formatted report to user

4. **Auto-Fix Loop** (design/impl review only):
   - If NO-GO or SPEC-UPDATE-NEEDED: Coordinator handles auto-fix (max 3 retries)
   - Report each retry attempt to user
   - If retries exhausted: present final verdict and options to user

5. Pipeline state tracking is handled by Coordinator (updates `coordinator.md` on review completion per Incremental Handover triggers)

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
