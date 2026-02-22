# Design Subcommand

Phase execution reference. Assumes Single-Spec Roadmap Ensure already completed by router.

Triggered by: `$ARGUMENTS = "design {feature-or-description}"`

## Step 1: Input Mode Detection

1. Parse feature name or description from arguments
2. Determine mode:
   - If spec was **just auto-created** by Single-Spec Roadmap Ensure (phase = `initialized`, no `design.md`) → **New Spec mode**
   - If spec existed before with `design.md` → **Existing Spec mode** (edit/regenerate)
   - If spec existed before without `design.md` (e.g., created by `create` with skeleton only) → **New Spec mode**

## Step 2: Phase Gate

- BLOCK if `spec.yaml.phase` is `blocked`: "{feature} is blocked by {blocked_info.blocked_by}"
- If `spec.yaml.phase` is `implementation-complete`: warn user that re-designing will invalidate existing implementation. Use AskUser to confirm: "Re-designing {feature} will invalidate the current implementation. Use `/sdd-roadmap revise {feature}` for targeted changes, or proceed with full re-design?" If rejected, abort.
- If `spec.yaml.phase` is not one of `initialized`, `design-generated`, `implementation-complete`, `blocked`: BLOCK with "Unknown phase '{phase}' in {feature}/spec.yaml. Manual intervention required."
- Otherwise: no phase restriction

## Step 3: Execute

Spawn Architect via `Task(subagent_type="sdd-architect")` with prompt:
- Feature: {feature}
- Mode: {new|existing}
- User-instructions: {from arguments, or empty}
- **Architect loads its own context** (steering, templates, rules, existing code) autonomously. Do NOT pre-read these files for Architect.

After Architect completion:
1. Verify `design.md` and `research.md` exist. If either is missing: do NOT update spec.yaml. Escalate to user: "Architect failed to produce {missing file}. Retry or investigate."
2. Update spec.yaml:
   - If re-edit (`version_refs.design` is non-null): increment `version` minor
   - Set `version_refs.design` = current `version`
   - Set `phase` = `design-generated`
   - Set `orchestration.last_phase_action` = null (ensures next impl triggers REGENERATE)
   - Update `changelog`

## Step 4: Post-Completion

1. Update relevant steering files if user expressed new requirements or direction changes (`product.md`, `tech.md`, `structure.md`, custom files as applicable)
2. Auto-draft `{{SDD_DIR}}/handover/session.md`
3. Report to user: design.md generated. Next: `/sdd-roadmap review design {feature}` or `/sdd-roadmap impl {feature}`
