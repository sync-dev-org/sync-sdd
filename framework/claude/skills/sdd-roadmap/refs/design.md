# Design Subcommand

Phase execution reference. Assumes Single-Spec Roadmap Ensure already completed by router.

Triggered by: `$ARGUMENTS = "design {feature-or-description}"`

## Step 1: Input Mode Detection

1. Parse feature name or description from arguments
2. Determine mode:
   - If spec was **just auto-created** by Single-Spec Roadmap Ensure (phase = `initialized`, no `design.md`) → **New Spec mode**
   - If spec existed before with `design.md` → **Existing Spec mode** (edit/regenerate)
   - If spec existed before without `design.md` (e.g., created by `create` — note: `create` always generates a skeleton `design.md`, but it may be empty/minimal) → **New Spec mode**

## Step 2: Phase Gate

- BLOCK if `spec.yaml.phase` is `blocked`: "{feature} is blocked by {blocked_info.blocked_by}"
- If `spec.yaml.phase` is `implementation-complete`: warn user that re-designing will invalidate existing implementation. Use AskUserQuestion to confirm: "Re-designing {feature} will invalidate the current implementation. Use `/sdd-roadmap revise {feature}` for targeted changes, or proceed with full re-design?" If rejected, abort and record `USER_DECISION` in decisions.md.
- If `spec.yaml.phase` is not one of `initialized`, `design-generated`, `implementation-complete`, `blocked`: BLOCK with "Unknown phase '{phase}' in {feature}/spec.yaml. Manual intervention required."
- Otherwise: no phase restriction

## Step 3: Dependency Sync

If spec involves external SDK/libraries (identifiable from spec name, description, user instructions, or existing design.md):

1. Identify package names from context
2. If not yet in pyproject.toml (or package.json): add to dependency manifest
   - Python: add to extras group + dev dependency group
   - Node: add to dependencies/devDependencies
3. Run install command from `steering/tech.md` Common Commands (`# Install:` line)
4. Verify importability via Bash (e.g., `uv run python -c "import {pkg}"`)
5. Determine SDK source paths: `uv run python -c "import {pkg}; print({pkg}.__file__)"`
6. Include in Architect prompt (Step 4): "Installed SDK source paths: {paths}. Read source for actual API signatures before designing. See design-discovery-full.md Step 3."

If SDK cannot be identified pre-design (abstract spec): skip. Note in Architect prompt: "No pre-installed SDKs for this spec. API signatures from WebSearch should be marked as unverified in research.md."

## Step 4: Execute

Spawn Architect via `Agent(subagent_type="sdd-architect", run_in_background=true)` with prompt:
- Feature: {feature}
- Mode: {new|existing}
- User-instructions: {from arguments, or empty}
- **Architect loads its own context** (steering, templates, rules, existing code) autonomously. Do NOT pre-read these files for Architect.
- If conventions brief path is available (from run.md Step 3): include path in prompt.
- If shared research path is available (from run.md Step 3): include path in prompt.
- If cross-cutting brief path is provided: include brief path in prompt. Architect reads the brief for shared context and focuses on spec-specific design changes rather than re-documenting shared background.

After Architect completion:
1. Verify `design.md` and `research.md` exist. If either is missing: do NOT update spec.yaml. Escalate to user: "Architect failed to produce {missing file}. Retry or investigate."
2. Update spec.yaml:
   - If re-edit (`version_refs.design` is non-null): increment `version` minor
   - Set `version_refs.design` = current `version`
   - Set `phase` = `design-generated`
   - Set `orchestration.last_phase_action` = null (ensures next impl triggers REGENERATE)
   - Update `changelog`

## Step 5: Post-Completion

1. Update relevant steering files if user expressed new requirements or direction changes (`product.md`, `tech.md`, `structure.md`, custom files as applicable)
2. Auto-draft `{{SDD_DIR}}/handover/session.md`
3. Report to user: design.md generated. Next: `/sdd-roadmap review design {feature}` or `/sdd-roadmap impl {feature}`
