---
description: Multi-feature roadmap (create, run, revise, update, delete)
allowed-tools: Bash, Glob, Grep, Read, Write, Edit, AskUserQuestion
argument-hint: [run [--gate] [--consensus N]] | [revise {feature} [instructions]] | [-y] | [create [-y]] | [update] | [delete]
---

# SDD Roadmap (Unified)

<instructions>

## Core Task

Manage product-wide specification roadmap. Create/update/delete are handled by Lead directly. Run is the primary orchestration flow — Lead manages full pipeline execution. Revise enables user-initiated modification of past-wave specs through the standard pipeline.

## Step 1: Detect Mode

```
$ARGUMENTS = "run"              → Execute roadmap (full-auto mode)
$ARGUMENTS = "run --gate"       → Execute roadmap (gate mode)
$ARGUMENTS = "run --consensus N" → Execute with N-run consensus reviews
$ARGUMENTS = "revise {feature} [instructions]" → Revise past-wave spec
$ARGUMENTS = "create" or "create -y" → Create roadmap
$ARGUMENTS = "update"           → Sync roadmap with current spec states
$ARGUMENTS = "delete"           → Delete roadmap and all specs
$ARGUMENTS = "-y"               → Auto-detect: run if roadmap exists, create if not
$ARGUMENTS = ""                 → Auto-detect with user choice
```

## Step 2: Auto-Detect (if no explicit mode)

1. Check if `{{SDD_DIR}}/project/specs/roadmap.md` exists
2. If exists: Present options (Run / Update / Reset)
3. If not: Start creation flow

---

## Create Mode

Lead handles directly (user-interactive):

1. Load steering, rules, templates, existing specs
2. Verify product understanding with user
3. Propose spec candidates from steering analysis
4. Organize into implementation waves (dependency-based)
5. Refine wave organization through dialogue (unless `-y`)
6. Create spec directories with skeleton design.md files
7. Set `spec.yaml.roadmap` for each spec: `{wave: N, dependencies: ["spec-name", ...]}`
8. Generate roadmap.md with Wave Overview, Dependencies, Execution Flow
9. **Update product.md** User Intent → Spec Rationale section
10. Auto-draft `{{SDD_DIR}}/handover/session.md`

## Run Mode

Lead handles pipeline execution directly.

### Step 1: Load State

1. Read `roadmap.md` and all `spec.yaml` files
2. Scan all `spec.yaml` files → rebuild pipeline state from phase/status fields
3. Build dependency graph from `spec.yaml.roadmap` fields
4. **DAG validation**: Topological sort the dependency graph. If a cycle is detected, BLOCK with: "Circular dependency detected: {cycle_path}. Fix spec.yaml.roadmap.dependencies before proceeding."

### Step 2: Cross-Spec File Ownership Analysis

1. Read all parallel-candidate specs' `design.md` Components sections
2. Detect file scope overlaps between specs in the same wave:
   - For each pair of parallel-candidate specs: compare claimed file paths
   - If intersection is non-empty: flag as overlap
3. Resolve overlaps:
   - **Serialize** (preferred): convert overlapping specs to sequential execution within the wave
   - **Partition**: re-assign file ownership so each file belongs to exactly one spec. May require re-spawning TaskGenerator for affected specs with file exclusion constraints
4. Validate: after resolution, verify no file is claimed by two parallel specs
5. Record final file ownership assignments for later auto-fix routing
6. buffer.md: Lead has exclusive write access (no parallel write conflicts)

### Step 3: Schedule Specs

Determine which specs can run in parallel (same wave, no file overlap, no dependency).
For each spec, track individual pipeline state:
```
spec-a: [Architect] → [Design Review] → [TaskGenerator] → [Builder ×N] → [Impl Review]
spec-b:   [Architect] → [Design Review] → ...
spec-c:         (waiting on spec-a) → [Architect] → ...
```

Design Review and Impl Review are **mandatory** in roadmap run.

### Step 4: Execute Pipelines

For each ready spec, execute pipeline phases in order:

#### Design Phase
1. Spawn Architect via `TeammateTool` with context:
   - Feature: {feature}
   - Mode: {new|existing}
   - User-instructions: {additional user instructions, or empty string if none}
   - **Architect loads its own context** (steering, templates, rules, existing code) autonomously in Step 1-2. Do NOT pre-read these files for Architect.
2. Read Architect's completion report
3. Dismiss Architect
4. Verify `design.md` and `research.md` exist
5. Update spec.yaml: `phase=design-generated`, `version_refs.design={v}`
6. Auto-draft `{{SDD_DIR}}/handover/session.md`

#### Design Review Phase
1. Spawn (via `TeammateTool`) 6 design Inspectors + design Auditor:
   - Inspector set: rulebase, testability, architecture, consistency, best-practices, holistic
   - Each Inspector context: "Feature: {feature}, Report to: sdd-auditor-design"
   - Auditor context: "Feature: {feature}, Expect: 6 Inspector results via SendMessage"
2. Read Auditor's verdict from completion output
3. Dismiss all review teammates (6 Inspectors + Auditor)
4. Persist verdict to `{{SDD_DIR}}/project/specs/{feature}/verdicts.md` (see sdd-review.md Step 4 step 2)
5. Handle verdict:
   - **GO/CONDITIONAL** → reset `retry_count` and `spec_update_count` to 0. Proceed to Implementation Phase
   - **NO-GO** → Auto-Fix Loop (see CLAUDE.md). After fix, phase remains `design-generated`
   - In **gate mode**: pause for user approval before advancing
6. Process `STEERING:` entries from verdict (append to `decisions.md` with Reason)
7. Auto-draft `{{SDD_DIR}}/handover/session.md`

If `--consensus N` is active, apply consensus mode per sdd-review.md §Consensus Mode.

#### Implementation Phase
1. Spawn TaskGenerator via `TeammateTool` with context:
   - Feature: {feature}
   - Design: `{{SDD_DIR}}/project/specs/{feature}/design.md`
   - Research: `{{SDD_DIR}}/project/specs/{feature}/research.md` (if exists)
   - Review findings: from `specs/{feature}/verdicts.md` latest design batch Tracked (if exists)
2. Read TaskGenerator's completion report (`TASKGEN_COMPLETE`)
3. Dismiss TaskGenerator
4. Verify `tasks.yaml` exists
5. Read `tasks.yaml` execution plan → determine Builder grouping
6. Cross-Spec File Ownership (Layer 2): Lead reads all parallel specs' tasks.yaml execution sections. Detect file overlap → serialize or partition (see Step 2). If partition requires file reassignment, re-spawn TaskGenerator for affected spec with file exclusion constraints, then re-read tasks.yaml
7. Read tasks.yaml tasks section → extract detail bullets for Builder spawn prompts
8. Spawn Builder(s) via `TeammateTool` with context for each work package:
   - Feature: {feature}
   - Tasks: {task IDs + summaries + detail bullets}
   - File scope: {assigned files}
   - Design ref: `{{SDD_DIR}}/project/specs/{feature}/design.md`
   - Research ref: `{{SDD_DIR}}/project/specs/{feature}/research.md` (if exists)
9. **Builder incremental processing**: As each Builder completes, immediately:
   - Read completion report (files, test results, knowledge tags, blockers)
   - Update tasks.yaml: mark completed tasks as `done`
   - Store knowledge tags in `{{SDD_DIR}}/handover/buffer.md`
   - If BUILDER_BLOCKED: classify cause (missing dependency → reorder tasks, re-spawn; external blocker → escalate to user; design gap → escalate, suggest re-design). Record as `[INCIDENT]` in buffer.md
10. When dependent tasks are unblocked: dismiss completed Builder, spawn next-wave Builders immediately
11. On ALL Builders complete:
   - Dismiss remaining Builders
   - Aggregate files from all Builder reports
   - Update spec.yaml: `phase=implementation-complete`, `implementation.files_created=[{files}]`, `version_refs.implementation={version}`
   - Auto-draft `{{SDD_DIR}}/handover/session.md`

#### Implementation Review Phase
1. Spawn (via `TeammateTool`) 6 impl Inspectors + impl Auditor:
   - Inspector set: impl-rulebase, interface, test, quality, impl-consistency, impl-holistic
   - Each Inspector context: "Feature: {feature}, Report to: sdd-auditor-impl"
   - Auditor context: "Feature: {feature}, Expect: 6 Inspector results via SendMessage"
2. Read Auditor's verdict from completion output
3. Dismiss all review teammates (6 Inspectors + Auditor)
4. Persist verdict to `{{SDD_DIR}}/project/specs/{feature}/verdicts.md` (see sdd-review.md Step 4 step 2)
5. Handle verdict:
   - **GO/CONDITIONAL** → reset `retry_count` and `spec_update_count` to 0. Spec pipeline complete
   - **NO-GO** → increment `retry_count`. Auto-Fix Loop: spawn Builder(s) via `TeammateTool` with fix instructions → re-review (max 3 retries)
   - **SPEC-UPDATE-NEEDED** → increment `spec_update_count` (max 2). Reset `orchestration.last_phase_action = null`, set `phase = design-generated`. Cascade fix: spawn Architect via `TeammateTool` (with SPEC_FEEDBACK from Auditor) → TaskGenerator → Builder → re-review. All tasks fully re-implemented (no differential).
   - In **gate mode**: pause for user approval
6. Process `STEERING:` entries from verdict (append to `decisions.md` with Reason)
7. Auto-draft `{{SDD_DIR}}/handover/session.md`

If `--consensus N` is active, apply consensus mode per sdd-review.md §Consensus Mode.

### Step 5: Auto/Gate Mode Handling

**Full-Auto Mode** (default):
- GO/CONDITIONAL → auto-advance to next phase
- NO-GO → auto-fix loop (max 3 retries, including structural changes), then escalate to user
- SPEC-UPDATE-NEEDED → auto-fix from spec level (including structural changes), then escalate
- Wave transitions → automatic

**Gate Mode** (`--gate`):
- Pause at each Design Review completion → user approval
- Pause at each Impl Review completion → user approval
- Pause at Wave transitions → user approval
- Structural changes (spec splitting, wave restructuring) → escalate to user

### Step 6: Failure Propagation (Blocking Protocol)

When a spec fails after exhausting retries:
1. Traverse dependency graph → identify all downstream specs
2. For each downstream spec:
   - Save current phase to `blocked_info.blocked_at_phase`
   - Set `phase` = `blocked`, `blocked_info.blocked_by` = `{failed_spec}`, `blocked_info.reason` = `upstream_failure`
3. Report cascading impact to user
4. Present options: fix / skip / abort roadmap
   - **fix**: After user claims upstream is fixed, Lead verifies upstream spec phase is `implementation-complete` before unblocking downstream. If not verified, re-run `/sdd-review impl {upstream}` first
   - **skip**: Exclude upstream spec from pipeline, evaluate if downstream dependencies are resolved
   - **abort**: Stop pipeline, leave all specs as-is

### Step 7: Wave Quality Gate

Wave completion condition: all specs in wave are `implementation-complete` or `blocked`.
Wave scope is cumulative: Wave N quality gate re-inspects ALL code from Waves 1..N. Inspectors flag only NEW issues not previously resolved in earlier wave gates.

After all specs in a wave complete individual pipelines:

**a. Impl Cross-Check Review** (wave-scoped):
0. **Load previously resolved issues**: Read `{{SDD_DIR}}/project/specs/verdicts-wave.md` (if exists). Collect Consensus findings from previous wave batches. Compare successive batches to identify resolved issues (present in earlier batch Consensus but absent from later). Format as PREVIOUSLY_RESOLVED for Inspector spawn context.
1. Spawn (via `TeammateTool`) 6 impl Inspectors + Auditor with wave-scoped cross-check context:
   - Each Inspector: "Wave-scoped cross-check, Wave: 1..{N}, Previously resolved: {PREVIOUSLY_RESOLVED from verdicts-wave.md}, Report to: sdd-auditor-impl"
   - Auditor: "Wave-scoped cross-check, Wave: 1..{N}, Expect: 6 Inspector results"
2. Read Auditor verdict from completion output
3. Dismiss all cross-check teammates
3.5. Persist verdict to `{{SDD_DIR}}/project/specs/verdicts-wave.md` (header: `[W{wave}-B{seq}]`). Same persistence logic as sdd-review.md Step 4 step 2.
4. Handle verdict:
   - **GO/CONDITIONAL** → proceed to dead-code review
   - **NO-GO** → map findings to file paths, identify responsible Builder(s) from wave's file ownership records, re-spawn via `TeammateTool` with fix instructions, re-review (max 3 retries). On exhaustion: escalate to user with options:
     a. **Proceed**: Accept remaining issues, proceed to Dead Code Review. Record as `ESCALATION_RESOLVED` in decisions.md with accepted issues listed
     b. **Abort wave**: Stop wave execution, leave specs as-is. Record as `ESCALATION_RESOLVED` with abort reason
     c. **Manual fix**: User fixes issues manually, then Lead re-runs Wave QG (counter reset)
   - **SPEC-UPDATE-NEEDED** → parse Auditor's SPEC_FEEDBACK section to identify the target spec(s). For each affected spec: reset orchestration (`last_phase_action = null`), set `phase = design-generated`, spawn Architect via `TeammateTool` with SPEC_FEEDBACK → TaskGenerator → Builder → re-review

**b. Dead Code Review** (full codebase):
1. Spawn (via `TeammateTool`) 4 dead-code Inspectors + dead-code Auditor:
   - sdd-inspector-dead-settings, sdd-inspector-dead-code, sdd-inspector-dead-specs, sdd-inspector-dead-tests
   - Each: "Report to: sdd-auditor-dead-code"
   - sdd-auditor-dead-code: "Expect: 4 Inspector results via SendMessage"
2. Read Auditor verdict from completion output
3. Dismiss all dead-code review teammates
3.5. Persist verdict to `{{SDD_DIR}}/project/specs/verdicts-wave.md` (header: `[W{wave}-DC-B{seq}]`)
4. Handle verdict:
   - **GO/CONDITIONAL** → Wave N complete, proceed to next wave
   - **NO-GO** → map findings to file paths, identify responsible Builder(s) from wave's file ownership records, re-spawn via `TeammateTool` with fix instructions, re-review dead-code (max 3 retries → escalate)

**c. Post-gate**:
- Aggregate Knowledge Buffer from `{{SDD_DIR}}/handover/buffer.md`, deduplicate, write to `{{SDD_DIR}}/project/knowledge/` using templates, clear buffer.md
- Commit: `Wave {N}: {summary of completed specs}`
- Auto-draft `{{SDD_DIR}}/handover/session.md`

### Step 8: Roadmap Completion

After all waves complete:
- Report summary to user: `{wave_count} waves, {spec_count} specs completed`
- Suggest: `/sdd-status`

## Update Mode

Lead handles directly:

### Step 1: Load and Compare
1. Read `roadmap.md` and scan all `spec.yaml` files
2. Build current state map: `{spec: {phase, wave, dependencies, version}}`
3. Compare against roadmap.md declared state

### Step 2: Detect Differences

| Category | Detection |
|----------|-----------|
| **Missing spec** | spec.yaml exists but not in roadmap.md |
| **Orphaned entry** | roadmap.md lists spec but no spec.yaml |
| **Wave mismatch** | spec.yaml.roadmap.wave differs from roadmap.md |
| **Dependency change** | spec.yaml.roadmap.dependencies differ |
| **Phase regression** | spec phase earlier than expected for completed wave |
| **Blocked cascade** | spec is blocked but roadmap shows active |

### Step 3: Impact Analysis
For each difference:
1. Trace dependency graph forward (downstream impact)
2. Check wave ordering integrity (would change violate wave boundaries?)
3. Classify impact: `SAFE` / `WAVE_REORDER` / `SCOPE_CHANGE`

### Step 4: Present Options
- **Apply All**: Apply all safe changes, present risky changes individually
- **Selective**: User picks which changes to apply
- **Abort**: No changes

### Step 5: Execute
1. Update roadmap.md to reflect accepted changes
2. Update affected spec.yaml roadmap fields
3. If wave reordering: re-validate dependency graph (no cycles)
4. Auto-draft `{{SDD_DIR}}/handover/session.md`
5. Record changes to `decisions.md` as `DIRECTION_CHANGE`

## Delete Mode

Lead handles directly:
1. Require explicit "RESET" confirmation
2. Delete roadmap.md and all spec directories
3. Optionally reinitialize via Create mode

## Revise Mode

Execute past-wave spec modifications through the standard pipeline. Lead follows CLAUDE.md §Artifact Ownership and MUST NOT directly edit artifact content.

### Step 1: Validate

1. Verify `roadmap.md` exists
2. Verify `spec.yaml` exists and `phase` is `implementation-complete`
3. Verify spec belongs to a completed wave (wave < current executing wave, or all waves complete)
4. BLOCK if `phase` is `blocked`

### Step 2: Collect Revision Intent

1. If instructions provided in arguments → use directly
2. If not → AskUser: "What changes are needed for {feature}?"
3. Record as `REVISION_INITIATED` in `decisions.md`

### Step 3: Impact Preview

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

### Step 4: State Transition

1. Reset `orchestration.last_phase_action = null`
2. Reset `orchestration.retry_count = 0`, `orchestration.spec_update_count = 0`
3. Set `phase = design-generated`

### Step 5: Execute Pipeline

Standard pipeline with revision context:

1. **Design Phase**: Spawn Architect via `TeammateTool` with context:
   - Feature: {feature}
   - Mode: existing
   - User-instructions: {REVISION_INSTRUCTIONS from Step 2}. Preserve unaffected design sections. Document changes in a '## Revision Notes' subsection.
   - **Architect loads its own context.** Do NOT pre-read files for Architect.
2. **Design Review Phase**: Same as Run Mode Step 4 Design Review
3. **Implementation Phase**: Same as Run Mode Step 4 Implementation (TaskGenerator → Builder, all tasks fully re-implemented)
4. **Implementation Review Phase**: Same as Run Mode Step 4 Impl Review

Auto-fix loop applies normally (retry_count, spec_update_count).

### Step 6: Downstream Resolution

After revision pipeline completes (spec returns to `implementation-complete`):

1. For each direct dependent spec that is `implementation-complete`:
   - Present to user per-spec:
     a. **Re-review**: Run impl review only (`/sdd-review impl {dep}`)
     b. **Re-implement**: Reset to `design-generated`, full cascade
     c. **Skip**: Accept current state
   - Record each decision in `decisions.md` as `USER_DECISION`
2. Execute user's choices sequentially
3. For transitive dependents: flag in session.md Warnings section only (user decides in future waves)

### Step 7: Post-Revision

1. Auto-draft `{{SDD_DIR}}/handover/session.md`
2. If roadmap run was in progress: resume from current position
3. Suggest: `/sdd-status` to verify state

## Post-Completion

1. Auto-draft `{{SDD_DIR}}/handover/session.md`
2. Report results to user

</instructions>

## Error Handling

- **No roadmap for run/update**: "No roadmap found. Run `/sdd-roadmap create` first."
- **No steering for create**: Warn and suggest `/sdd-steering` first
- **Spec conflicts during run**: Lead handles file ownership resolution (serialize preferred, partition allowed)
- **Spec failure (retries exhausted)**: Block dependent specs via Blocking Protocol, report cascading impact, present options (fix / skip / abort)
- **Artifact verification failure**: Do not update spec.yaml — escalate to user
