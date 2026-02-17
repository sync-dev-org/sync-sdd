---
description: Generate implementation tasks for a specification
allowed-tools: Read, Write, Edit, Glob, Grep, SendMessage
argument-hint: <feature-name> [-y]
---

# SDD Tasks (Dispatcher)

<instructions>

## Core Task

Orchestrate task generation for feature **$1** via Coordinator → Planner pipeline.

## Step 1: Phase Gate

1. Read `{{SDD_DIR}}/project/specs/$1/spec.json`
2. Verify `design.md` exists
3. Verify `phase` is `design-generated` or later (BLOCK if `initialized`)

### Version Consistency Check

If `version_refs` present in spec.json:
- If `version_refs.tasks` exists and differs from `version_refs.design`:
  - CONFIRM: "Design updated since last task generation. Regenerate?"
  - If `-y` flag: auto-confirm
  - If user declines: stop

## Step 2: Dispatch to Coordinator

Send instruction to Coordinator:

```
タスク生成 feature={feature}
```

Coordinator will plan and request Planner spawn. Enter Conductor Message Loop: handle Coordinator's typed messages until PIPELINE_COMPLETE.

## Step 3: Post-Completion

After Coordinator reports completion:
1. Update `{{SDD_DIR}}/handover/conductor.md` with current state
2. Report to user:
   - Status: tasks.md generated
   - Task summary (major/sub counts, spec coverage)
   - Next action: `/sdd-impl {feature}` or `/sdd-impl {feature} 1.1`

</instructions>

## Error Handling

- **Missing design.md**: "Missing design.md. Run `/sdd-design $1` first."
- **Wrong phase**: "Phase is '{phase}'. Run `/sdd-design $1` first."
- **Version mismatch**: Prompt user for confirmation (unless `-y`)

think
