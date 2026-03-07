# Revise Mode

Orchestration reference. Two modes: **Single-Spec** (targeted revision of one spec) and **Cross-Cutting** (coordinated revision across multiple specs). Lead follows CLAUDE.md §Artifact Ownership and MUST NOT directly edit artifact content.

## Mode Detection

```
Arguments parsing (Lead checks first word after "revise" against existing spec names):
  "revise <feature> [instructions]"  → feature matches known spec name → Single-Spec Mode (Part A)
  "revise [instructions]"            → no feature name match           → Cross-Cutting Mode (Part B)

Escalation:
  Single-Spec Mode Step 3 detects 2+ affected specs → propose switch to Cross-Cutting Mode
  User accepts → join Part B Step 2 with pre-populated target spec
  User declines → continue Single-Spec Mode
```

---

## Part A: Single-Spec Mode

Execute past-wave spec modifications through the standard pipeline.

### Step 1: Validate

1. Verify `roadmap.md` exists
2. Verify `spec.yaml` exists and `phase` is `implementation-complete`
3. Verify spec belongs to a completed wave (wave < current executing wave, or all waves complete)
4. If phase is `blocked`: BLOCK with "{feature} is blocked by {blocked_info.blocked_by}"
5. If phase is unrecognized: BLOCK with "Unknown phase ''{phase}''"

### Step 2: Collect Revision Intent

1. If instructions provided in arguments → use directly
2. If not → AskUser: "What changes are needed for {feature}?"
3. Record as `REVISION_INITIATED` in `decisions.yaml`
4. **Steering update**: If revision intent implies direction changes, update relevant steering files BEFORE spawning Architect (`product.md` for requirements/vision, `tech.md` for technical decisions, `structure.md` for structural changes, custom files as needed). This ensures Architect reads current steering context.

### Step 3: Impact Preview

1. Traverse dependency graph → find all downstream specs with `spec.yaml.roadmap.dependencies` containing {feature}
2. Classify: direct dependents (1-hop) vs transitive dependents (2+ hops)
3. **Cross-cutting escalation**: If 2+ specs are affected (target + dependents), propose:
   ```
   This change affects {N} specs ({list}).
   Switch to cross-cutting mode for coordinated revision? [Yes / No, single-spec only]
   ```
   - User accepts → record `DIRECTION_CHANGE` in decisions.yaml, join Part B Step 2 with revision intent and target spec pre-populated (Step 4 has NOT executed — target spec's phase is still `implementation-complete`, eligible for Part B classification). Skip Part B Step 1 (REVISION_INITIATED already recorded in Part A Step 2).
   - User declines → continue single-spec flow below
4. Present to user:
   ```
   Revision target: {feature} (Wave {N})
   Direct dependents: {list or "none"}
   Transitive dependents: {list or "none"}

   Pipeline: Architect → Design Review → TaskGenerator → Builder → Impl Review
   All tasks will be fully re-implemented (no differential).
   Proceed?
   ```
5. On rejection → abort, record `USER_DECISION` in decisions.yaml

### Step 4: State Transition

1. Reset `orchestration.last_phase_action = null`
2. Reset `orchestration.retry_count = 0`, `orchestration.spec_update_count = 0`
3. Set `phase = design-generated`

### Step 5: Execute Pipeline

Standard pipeline with revision context. References phase execution refs for details.

1. **Design**: Execute per `design.md` with revision context:
   - Feature: {feature}, Mode: existing
   - User-instructions: {REVISION_INSTRUCTIONS from Step 2}. Preserve unaffected design sections. Document changes in '## Revision Notes'.
   After completion: verify design.md, update spec.yaml (increment `version`, phase=design-generated, last_phase_action=null).
2. **Design Review**: Execute via `/sdd-review design {feature}`.
   Handle verdict per CLAUDE.md counter limits.
3. **Implementation**: Execute per `impl.md` (Steps 1-3).
   After ALL Builders complete: update spec.yaml (phase=implementation-complete, files_created).
4. **Impl Review**: Execute via `/sdd-review impl {feature}`.
   Handle verdict per CLAUDE.md counter limits.

Auto-fix loop applies normally (retry_count, spec_update_count).

### Step 6: Downstream Resolution

After revision pipeline completes (spec returns to `implementation-complete`):

1. For each direct dependent spec that is `implementation-complete`:
   - Present to user per-spec:
     a. **Re-review**: Run impl review only (`/sdd-roadmap review impl {dep}`)
     b. **Re-implement**: Reset `phase=design-generated`, `last_phase_action=null`, full cascade (Architect re-designs against updated upstream → Design Review → TaskGenerator → Builder → Impl Review)
     c. **Skip**: Accept current state
     d. **Cross-cutting revision**: Switch to cross-cutting mode for coordinated downstream revision
   - Record each decision in `decisions.yaml` as `USER_DECISION`
2. If option (d) selected → record `DIRECTION_CHANGE` in decisions.yaml, join Part B Step 2 with completed target spec + affected dependents pre-populated
3. Otherwise: execute user's choices sequentially
4. For transitive dependents: flag in handover.md Warnings section only (user decides in future waves)

### Step 7: Post-Revision

1. Auto-draft `{{SDD_DIR}}/session/handover.md`
2. If roadmap run was in progress (any non-revised spec has phase != `implementation-complete`): resume via `refs/run.md` dispatch loop from current spec.yaml state
3. Suggest: `/sdd-status` to verify state

---

## Part B: Cross-Cutting Mode

Coordinated revision across multiple specs for changes that span Wave/Spec boundaries.

### Step 1: Collect Intent

1. Receive change description from user (e.g., "position field: int → fractional indexing string")
   - If joining from Part A: use revision intent already collected
2. Record `REVISION_INITIATED` in `decisions.yaml` with note: `(cross-cutting)`
3. **Steering update**: If intent implies direction changes, update relevant steering files BEFORE proceeding (`product.md`, `tech.md`, `structure.md`, custom files as needed)

### Step 2: Impact Analysis

Scan all specs to classify impact:

1. Read all `spec.yaml` files (only `implementation-complete` phase is eligible for revision). `blocked` specs are excluded from revision but reported to user: "Spec {name} is blocked by {blocked_by} — excluded from cross-cutting scope but may be affected."
2. For each eligible spec, read `design.md` + `implementation.files_created`
3. Classify each spec based on change intent:
   - **FULL**: Design components directly affected by the change (needs design + impl pipeline)
   - **AUDIT**: Dependency relationship exists but contract may not change (needs lightweight check)
   - **SKIP**: No relationship to the change
4. Present classification to user:
   ```
   Cross-cutting revision: "{change description}"

   FULL (design + impl pipeline):
     - {spec-a} (Wave {N}) — {reason}
     - {spec-b} (Wave {M}) — {reason}

   AUDIT (impact check needed):
     - {spec-c} (Wave {K}) — {reason}

   SKIP:
     - {spec-d}, {spec-e}

   Proceed? [Confirm / Modify / Abort]
   ```
5. User may override classifications (promote AUDIT→FULL, demote FULL→AUDIT, etc.)
6. On abort → record `USER_DECISION` in decisions.yaml, stop

### Step 3: Restructuring Check

Determine if Wave/Spec structure changes are needed:

1. **New Spec needed**: If the change introduces a new capability → propose spec creation, use crud.md Create logic for spec initialization + roadmap update
2. **Spec split/merge**: If change makes existing spec scope inappropriate → apply crud.md Update Mode restructuring logic
3. **Wave reorder**: If dependency changes alter topological order → recalculate wave assignments
4. Record any structural changes as `DIRECTION_CHANGE` in decisions.yaml
5. If no structural changes needed → proceed to Step 4

### Step 3.5: Cross-Cutting ID

`$CC_ID` を生成。format: `{kebab-case-revision-name}` (e.g., `fractional-indexing`)。以降の全ステップでこの `CC_ID` を使用する。

### Step 4: Cross-Cutting Design Brief

Create a shared context document to eliminate redundant work across Architects:

1. Lead creates `specs/.cross-cutting/{CC_ID}/brief.md`
2. Brief contents:
   - **Background**: Why this change is needed
   - **Technical Details**: Specific technical change (e.g., "position: INTEGER → TEXT, using fractional indexing with base62 keys")
   - **Scope**: List of FULL specs and expected impact per spec
   - **Design Constraints**: Shared constraints all specs must follow (e.g., "sort by TEXT column using lexicographic ordering")
3. This brief is passed to each Architect via prompt → Architects reference it instead of independently researching the same background

### Step 5: Triage — AUDIT Specs

For each AUDIT-classified spec, perform lightweight verification:

1. Lead reads the design brief (Step 4) and the spec's `design.md`
2. Determine:
   - **Change not needed**: Contract/interface is unchanged → demote to SKIP. Record `USER_DECISION` in decisions.yaml with justification
   - **Change needed**: Interface or behavior is affected → promote to FULL
3. Present triage results to user for confirmation

### Step 6: Auto-Demotion Check

After triage, if only 1 FULL spec remains (all others are SKIP): automatically demote to Single-Spec Mode. Resume from Part A Step 4 (state transition → pipeline execution) with the single FULL spec as the target. Record `DIRECTION_CHANGE` in decisions.yaml: "Cross-Cutting demoted to Single-Spec: only {spec} classified as FULL."

### Step 7: Execution Tier Planning

Build a tier-based execution plan from the FULL specs:

1. Extract dependency subgraph containing only FULL specs
2. Topological sort → assign tiers:
   - **Tier 1**: FULL specs with no dependencies on other FULL specs
   - **Tier 2**: FULL specs depending on Tier 1 FULL specs
   - **Tier N**: Continue until all FULL specs assigned
3. Same-tier specs execute in parallel
4. Present plan to user:
   ```
   Execution Plan:
     Tier 1: {spec-a}
     Tier 2: {spec-b}
     Tier 3: {spec-c} + {spec-d} (parallel)

     Total: {N} specs, {M} tiers
   ```
5. On user confirmation → proceed to execution

### Step 8: Tier Execution

Execute each tier sequentially. Within a tier, specs at the same phase run in parallel. Each phase completes for all specs before advancing to the next (NOT a concurrent dispatch loop — phases are strictly sequential):

```
For each tier (sequential):

  1. State Transition (per spec):
     - Reset orchestration.retry_count = 0, spec_update_count = 0
     - Reset orchestration.last_phase_action = null
     - Set phase = design-generated

  2. Wave Context Generation:
     - Dispatch `sdd-conventions-scanner` (mode: Generate) per run.md Step 3
     - Generate shared research if 2+ Architects in tier (include cross-cutting brief as additional context)
       - Store in specs/.cross-cutting/{CC_ID}/ alongside brief.md

  3. Design Fan-Out:
     - Dispatch Architects in parallel (run_in_background: true)
     - Each Architect prompt includes:
       a. design.md revision context (Mode: existing, User-instructions: revision intent)
       b. Cross-cutting brief path → Architect reads brief for shared context
       c. Conventions brief path + shared research path (from step 2)
       d. "Focus on spec-specific design changes. Shared background is in the brief."
     - After each Architect completes: update spec.yaml per design.md Step 4

  4. Design Review:
     - Dispatch per spec (parallel) via `/sdd-review design {feature}`
     - Handle verdicts per CLAUDE.md counter limits and run.md Phase Handlers (on NO-GO: re-dispatch Architect, increment counter)
     - SPEC-UPDATE-NEEDED is not expected for design review. If received, escalate immediately

  5. Implementation:
     - Update conventions brief with design-derived conventions (run.md Step 3 Post-Design)
     - Cross-Spec File Ownership Analysis (run.md Step 2) across tier specs
     - TaskGenerator → Builder per impl.md (includes conventions brief path, Pilot Stagger Protocol)
     - After ALL Builders complete per spec: update spec.yaml

  6. Impl Review:
     - Dispatch per spec (parallel) via `/sdd-review impl {feature}`
     - Handle verdicts per CLAUDE.md counter limits and run.md Phase Handlers (on NO-GO: re-dispatch Builder; on SPEC-UPDATE-NEEDED: cascade per run.md)

  7. Tier Checkpoint:
     - All specs in tier must reach implementation-complete
     - Auto-fix loop applies per spec: handle NO-GO/SPEC-UPDATE-NEEDED per run.md Phase Handlers (counter increment, Architect/Builder re-dispatch, phase transitions). Counter limits: retry_count max 5, spec_update_count max 2, aggregate cap 6 (per CLAUDE.md)
     - On exhaustion: escalate to user per run.md Step 7 blocking protocol (user chooses fix/skip/abort). Skip removes spec from tier; abort halts entire revision.
```

### Step 9: Cross-Cutting Consistency Review

After all tiers complete, verify cross-spec consistency:

1. Execute cross-cutting impl review via `/sdd-review impl --cross-cutting {spec1,spec2,...} --id {CC_ID}` with all FULL specs from all tiers
2. Persist verdict to `specs/.cross-cutting/{CC_ID}/verdicts.yaml` (NOT `reviews/wave-{N}/verdicts.yaml` — cross-cutting uses its own scope directory)
3. Handle verdict:
   - **GO/CONDITIONAL** → proceed to post-completion
   - **NO-GO** → identify target spec(s), dispatch Builder(s) with fix instructions, re-run cross-check review. Counter limits: retry_count max 5 (NO-GO), spec_update_count max 2 (SPEC-UPDATE-NEEDED), aggregate cap 6 (per CLAUDE.md). On exhaustion: escalate to user
   - **SPEC-UPDATE-NEEDED** → update affected spec design, re-implement, re-run cross-check review (counts toward spec_update_count and aggregate cap)

### Step 10: Post-Completion

1. Cross-cutting brief and verdicts are retained in `specs/.cross-cutting/{CC_ID}/` for reference
2. Auto-draft `{{SDD_DIR}}/session/handover.md`
3. Commit: `cross-cutting: {summary}`
4. Suggest: `/sdd-status` to verify state
