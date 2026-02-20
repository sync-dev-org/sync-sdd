---
description: Create comprehensive technical design for a specification
allowed-tools: Bash, Glob, Grep, Read, Write, Edit, AskUserQuestion
argument-hint: <feature-name-or-"description">
---

# SDD Design (Dispatcher)

<instructions>

## Core Task

Orchestrate design generation by spawning Architect as a teammate (`TeammateTool`). Parse `$ARGUMENTS` as the feature name or description.

## Step 1: Input Mode Detection

1. Parse feature name from `$ARGUMENTS` (the full argument string)
2. Check if `{{SDD_DIR}}/project/specs/{feature}/spec.yaml` exists
2. **If exists** → Existing Spec mode (edit/regenerate)
3. **If not** → New Spec mode (initialize from description)

Input examples:
- `/sdd-design "user authentication"` → New (description → generate feature name)
- `/sdd-design auth-flow` → Existing if `specs/auth-flow/spec.yaml` exists, New otherwise

### New Spec Initialization (New Spec mode only)

1. Generate feature name: Convert description to kebab-case
2. Create spec directory: `{{SDD_DIR}}/project/specs/{feature-name}/`
3. Initialize spec.yaml from `{{SDD_DIR}}/settings/templates/specs/init.yaml`
4. Inform user of the generated feature name
5. Continue with the generated feature name

## Step 2: Phase Gate

- If existing spec: verify spec directory and spec.yaml exist
- BLOCK if `spec.yaml.phase` is `blocked`: "{feature} is blocked by {blocked_info.blocked_by}"
- If `spec.yaml.phase` is `implementation-complete` AND `spec.yaml.roadmap` is non-null: BLOCK with "{feature} is part of an active roadmap. Use `/sdd-roadmap revise {feature}` to modify past-wave specs through the proper pipeline."
- If `spec.yaml.phase` is `implementation-complete` AND `spec.yaml.roadmap` is null: warn user that re-designing will invalidate existing implementation. Use AskUser to confirm: "Re-designing {feature} will invalidate the current implementation. Proceed?" If rejected, abort.
- Otherwise: no phase restriction for design generation

## Step 3: Spawn Architect

1. Spawn Architect via `TeammateTool` with context:
   ```
   Feature: {feature}
   Mode: {new|existing}
   User-instructions: {additional user instructions, or empty string if none}
   ```
   **Architect loads its own context** (steering, templates, rules, existing code) autonomously in Step 1-2. Do NOT pre-read these files for Architect.
2. Read Architect's completion report (`ARCHITECT_COMPLETE`)
3. Dismiss Architect
4. Verify `design.md` and `research.md` exist in spec directory
5. Update spec.yaml:
   - If re-edit (`version_refs.design` is non-null): increment `version` minor
   - Set `version_refs.design` = current `version`
   - Set `phase` = `design-generated`
   - Set `orchestration.last_phase_action` = null
   - Update `changelog`

## Step 4: Post-Completion

1. Update `{{SDD_DIR}}/project/steering/product.md` User Intent section if user expressed new requirements during this flow
2. Auto-draft `{{SDD_DIR}}/handover/session.md`
3. Report to user:
   - Status: design.md generated
   - Discovery type used
   - Next action: `/sdd-review design {feature}` or `/sdd-impl {feature}`

</instructions>

## Error Handling

- **Missing spec (existing mode)**: "No spec found. Run `/sdd-design \"description\"` to create."
- **Template missing**: "Template missing at `{{SDD_DIR}}/settings/templates/specs/`"
- **Steering missing**: Warn and proceed
