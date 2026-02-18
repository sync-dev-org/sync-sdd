---
description: Generate implementation tasks for a specification
allowed-tools: Read, Write, Edit, Glob, Grep
argument-hint: <feature-name> [-y]
---

# SDD Tasks (Dispatcher)

<instructions>

## Core Task

Orchestrate task generation for feature **$1** by spawning Planner directly.

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

## Step 2: Spawn Planner

1. Spawn Planner with context:
   ```
   Feature: {feature}
   Design: {{SDD_DIR}}/project/specs/{feature}/design.md
   Research: {{SDD_DIR}}/project/specs/{feature}/research.md (if exists)
   Template: {{SDD_DIR}}/settings/templates/specs/tasks.md
   ```
2. Read Planner's completion report (`PLANNER_COMPLETE`)
3. Dismiss Planner
4. Verify `tasks.md` exists
5. Update spec.json:
   - Set `version_refs.tasks` = current `version`
   - Set `phase` = `tasks-generated`
   - Update `changelog`

## Step 3: Post-Completion

1. Auto-draft `{{SDD_DIR}}/handover/session.md`
2. Report to user:
   - Status: tasks.md generated
   - Task summary (major/sub counts, spec coverage)
   - Next action: `/sdd-impl {feature}` or `/sdd-impl {feature} 1.1`

</instructions>

## Error Handling

- **Missing design.md**: "Missing design.md. Run `/sdd-design $1` first."
- **Wrong phase**: "Phase is '{phase}'. Run `/sdd-design $1` first."
- **Version mismatch**: Prompt user for confirmation (unless `-y`)
