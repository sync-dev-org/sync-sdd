# Revise Mode

Orchestration reference. Execute past-wave spec modifications through the standard pipeline. Lead follows CLAUDE.md §Artifact Ownership and MUST NOT directly edit artifact content.

## Step 1: Validate

1. Verify `roadmap.md` exists
2. Verify `spec.yaml` exists and `phase` is `implementation-complete`
3. Verify spec belongs to a completed wave (wave < current executing wave, or all waves complete)
4. BLOCK if `phase` is `blocked`

## Step 2: Collect Revision Intent

1. If instructions provided in arguments → use directly
2. If not → AskUser: "What changes are needed for {feature}?"
3. Record as `REVISION_INITIATED` in `decisions.md`
4. **Steering update**: If revision intent implies direction changes, update relevant steering files BEFORE spawning Architect (`product.md` for requirements/vision, `tech.md` for technical decisions, `structure.md` for structural changes, custom files as needed). This ensures Architect reads current steering context.

## Step 3: Impact Preview

1. Traverse dependency graph → find all downstream specs with `spec.yaml.roadmap.dependencies` containing {feature}
2. Classify: direct dependents (1-hop) vs transitive dependents (2+ hops)
3. Present to user:
   ```
   Revision target: {feature} (Wave {N})
   Direct dependents: {list or "none"}
   Transitive dependents: {list or "none"}

   Pipeline: Architect → Design Review → TaskGenerator → Builder → Impl Review
   All tasks will be fully re-implemented (no differential).
   Proceed?
   ```
4. On rejection → abort, record `USER_DECISION` in decisions.md

## Step 4: State Transition

1. Reset `orchestration.last_phase_action = null`
2. Reset `orchestration.retry_count = 0`, `orchestration.spec_update_count = 0`
3. Set `phase = design-generated`

## Step 5: Execute Pipeline

Standard pipeline with revision context. References phase execution refs for details.

1. **Design**: Execute per `refs/design.md` with revision context:
   - Feature: {feature}, Mode: existing
   - User-instructions: {REVISION_INSTRUCTIONS from Step 2}. Preserve unaffected design sections. Document changes in '## Revision Notes'.
   After completion: verify design.md, update spec.yaml (phase=design-generated, last_phase_action=null).
2. **Design Review**: Execute per `refs/review.md` (Design Review section).
   Handle verdict per CLAUDE.md counter limits.
3. **Implementation**: Execute per `refs/impl.md`.
   After ALL Builders complete: update spec.yaml (phase=implementation-complete, files_created).
4. **Impl Review**: Execute per `refs/review.md` (Impl Review section).
   Handle verdict per CLAUDE.md counter limits.

Auto-fix loop applies normally (retry_count, spec_update_count).

## Step 6: Downstream Resolution

After revision pipeline completes (spec returns to `implementation-complete`):

1. For each direct dependent spec that is `implementation-complete`:
   - Present to user per-spec:
     a. **Re-review**: Run impl review only (`/sdd-roadmap review impl {dep}`)
     b. **Re-implement**: Reset to `design-generated`, full cascade
     c. **Skip**: Accept current state
   - Record each decision in `decisions.md` as `USER_DECISION`
2. Execute user's choices sequentially
3. For transitive dependents: flag in session.md Warnings section only (user decides in future waves)

## Step 7: Post-Revision

1. Auto-draft `{{SDD_DIR}}/handover/session.md`
2. If roadmap run was in progress: resume from current position
3. Suggest: `/sdd-status` to verify state
