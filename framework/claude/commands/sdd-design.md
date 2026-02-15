---
description: Create comprehensive technical design for a specification
allowed-tools: Bash, Glob, Grep, Read, Write, Edit, SendMessage
argument-hint: <feature-name-or-"description">
---

# SDD Design (Dispatcher)

<instructions>

## Core Task

Orchestrate design generation for feature **$1** via Coordinator → Architect pipeline.

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

## Step 3: Dispatch to Coordinator

Send instruction to Coordinator:

```
設計生成 feature={feature}
Mode: {new|existing}
```

Coordinator will plan and request Architect spawn. Follow Coordinator's spawn requests mechanically.

## Step 4: Post-Completion

After Coordinator reports completion:
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
