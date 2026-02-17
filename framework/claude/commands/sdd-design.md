---
description: Create comprehensive technical design for a specification
allowed-tools: Bash, Glob, Grep, Read, Write, Edit
argument-hint: <feature-name-or-"description">
---

# SDD Design (Dispatcher)

<instructions>

## Core Task

Orchestrate design generation for feature **$1** by spawning Architect directly.

## Step 1: Input Mode Detection

- **New Spec**: $1 is a quoted description (e.g., `"user authentication"`) → Initialize spec first
- **Existing Spec**: $1 is a feature name (e.g., `auth-flow`) → Edit/regenerate existing design

### New Spec Initialization (New Spec mode only)

1. Generate feature name: Convert description to kebab-case
2. Create spec directory: `{{SDD_DIR}}/project/specs/{feature-name}/`
3. Initialize spec.json from `{{SDD_DIR}}/settings/templates/specs/init.json`
4. Inform user of the generated feature name
5. Continue with the generated feature name

## Step 2: Phase Gate

- If existing spec: verify spec directory and spec.json exist
- No phase restriction for design generation (any phase is valid)

## Step 3: Spawn Architect

1. Spawn Architect with context:
   ```
   Feature: {feature}
   Steering: {{SDD_DIR}}/project/steering/
   Template: {{SDD_DIR}}/settings/templates/specs/
   Mode: {new|existing}
   ```
2. Read Architect's completion report (`ARCHITECT_COMPLETE`)
3. Dismiss Architect
4. Verify `design.md` and `research.md` exist in spec directory
5. Update spec.json:
   - If re-edit (`version_refs.design` is non-null): increment `version` minor
   - Set `version_refs.design` = current `version`, `version_refs.tasks` = null
   - Set `phase` = `design-generated`
   - Update `changelog`

## Step 4: Post-Completion

1. Update `{{SDD_DIR}}/project/steering/product.md` User Intent section if user expressed new requirements during this flow
2. Update `{{SDD_DIR}}/handover/conductor.md` with current state
3. Report to user:
   - Status: design.md generated
   - Discovery type used
   - Next action: `/sdd-review design {feature}` or `/sdd-tasks {feature}`

</instructions>

## Error Handling

- **Missing spec (existing mode)**: "No spec found. Run `/sdd-design \"description\"` to create."
- **Template missing**: "Template missing at `{{SDD_DIR}}/settings/templates/specs/`"
- **Steering missing**: Warn and proceed

think
