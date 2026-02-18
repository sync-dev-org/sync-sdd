---
description: Multi-feature roadmap (create, run, update, delete)
allowed-tools: Bash, Glob, Grep, Read, Write, Edit, AskUserQuestion, WebSearch, WebFetch
argument-hint: [run [--gate]] | [-y] | [create [-y]] | [update] | [delete]
---

# SDD Roadmap (Unified)

<instructions>

## Core Task

Manage product-wide specification roadmap. Create/update/delete are handled by Lead directly. Run is the primary orchestration flow — Lead manages full pipeline execution.

## Step 1: Detect Mode

```
$ARGUMENTS = "run"              → Execute roadmap (full-auto mode)
$ARGUMENTS = "run --gate"       → Execute roadmap (gate mode)
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
1. Spawn Architect with context:
   - Feature: {feature}
   - Steering: `{{SDD_DIR}}/project/steering/`
   - Template: `{{SDD_DIR}}/settings/templates/specs/`
   - Mode: {new|existing}
2. Read Architect's completion report
3. Dismiss Architect
4. Verify `design.md` and `research.md` exist
5. Update spec.yaml: `phase=design-generated`, `version_refs.design={v}`
6. Auto-draft `{{SDD_DIR}}/handover/session.md`

#### Design Review Phase
1. Spawn 5 design Inspectors + design Auditor:
   - Inspector set: rulebase, testability, architecture, consistency, best-practices
   - Each Inspector context: "Feature: {feature}, Report to: sdd-auditor-design"
   - Auditor context: "Feature: {feature}, Expect: 5 Inspector results via SendMessage"
2. Read Auditor's verdict from completion output
3. Dismiss all review teammates (5 Inspectors + Auditor)
4. Handle verdict:
   - **GO/CONDITIONAL** → proceed to Implementation Phase
   - **NO-GO** → Auto-Fix Loop (see CLAUDE.md). After fix, phase remains `design-generated`
   - In **gate mode**: pause for user approval before advancing
5. Process `STEERING:` entries from verdict (append to `decisions.md` with Reason)
6. Auto-draft `{{SDD_DIR}}/handover/session.md`

#### Implementation Phase
1. Spawn TaskGenerator with context:
   - Feature: {feature}
   - Design: `{{SDD_DIR}}/project/specs/{feature}/design.md`
   - Research: `{{SDD_DIR}}/project/specs/{feature}/research.md` (if exists)
2. Read TaskGenerator's completion report (`TASKGEN_COMPLETE`)
3. Dismiss TaskGenerator
4. Verify `tasks.yaml` exists
5. Read `tasks.yaml` execution plan → determine Builder grouping
6. Cross-Spec File Ownership (Layer 2): Lead reads all parallel specs' tasks.yaml execution sections. Detect file overlap → serialize or partition (see Step 2). If partition requires file reassignment, re-spawn TaskGenerator for affected spec with file exclusion constraints, then re-read tasks.yaml
7. Read tasks.yaml tasks section → extract detail bullets for Builder spawn prompts
8. Spawn Builder(s) with context for each work package:
   - Feature: {feature}
   - Tasks: {task IDs + summaries + detail bullets}
   - File scope: {assigned files}
   - Design ref: `{{SDD_DIR}}/project/specs/{feature}/design.md`
   - Research ref: `{{SDD_DIR}}/project/specs/{feature}/research.md` (if exists)
9. **Builder逐次更新**: As each Builder completes, immediately:
   - Read completion report (files, test results, knowledge tags, blockers)
   - Update tasks.yaml: mark completed tasks as `done`
   - Store knowledge tags in `{{SDD_DIR}}/handover/buffer.md`
   - If BUILDER_BLOCKED: re-plan execution (modify tasks.yaml execution) or escalate
10. When dependent tasks are unblocked: dismiss completed Builder, spawn next-wave Builders immediately
11. On ALL Builders complete:
   - Dismiss remaining Builders
   - Aggregate files from all Builder reports
   - Update spec.yaml: `phase=implementation-complete`, `implementation.files_created=[{files}]`
   - Auto-draft `{{SDD_DIR}}/handover/session.md`

#### Implementation Review Phase
1. Spawn 5 impl Inspectors + impl Auditor:
   - Inspector set: impl-rulebase, interface, test, quality, impl-consistency
   - Each Inspector context: "Feature: {feature}, Report to: sdd-auditor-impl"
   - Auditor context: "Feature: {feature}, Expect: 5 Inspector results via SendMessage"
2. Read Auditor's verdict from completion output
3. Dismiss all review teammates (5 Inspectors + Auditor)
4. Handle verdict:
   - **GO/CONDITIONAL** → spec pipeline complete
   - **NO-GO** → increment `retry_count`. Auto-Fix Loop: spawn Builder(s) with fix instructions → re-review (max 3 retries)
   - **SPEC-UPDATE-NEEDED** → increment `spec_update_count` (max 2). Reset `orchestration.last_phase_action = null`, set `phase = design-generated`. Cascade fix: spawn Architect (with SPEC_FEEDBACK from Auditor) → TaskGenerator → Builder → re-review. All tasks fully re-implemented (no differential).
   - In **gate mode**: pause for user approval
5. Process `STEERING:` entries from verdict (append to `decisions.md` with Reason)
6. Auto-draft `{{SDD_DIR}}/handover/session.md`

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
1. Spawn 5 impl Inspectors + Auditor with wave-scoped cross-check context:
   - Each Inspector: "Wave-scoped cross-check, Wave: 1..{N}, Report to: sdd-auditor-impl"
   - Auditor: "Wave-scoped cross-check, Wave: 1..{N}, Expect: 5 Inspector results"
2. Read Auditor verdict from completion output
3. Dismiss all cross-check teammates
4. Handle verdict:
   - **GO/CONDITIONAL** → proceed to dead-code review
   - **NO-GO** → map findings to file paths, identify responsible Builder(s) from wave's file ownership records, re-spawn with fix instructions, re-review (max 3 retries). On exhaustion: escalate to user → user chooses: proceed to Dead Code Review despite issues, or abort wave
   - **SPEC-UPDATE-NEEDED** → parse Auditor's SPEC_FEEDBACK section to identify the target spec(s). For each affected spec: reset orchestration (`last_phase_action = null`), set `phase = design-generated`, spawn Architect with SPEC_FEEDBACK → TaskGenerator → Builder → re-review

**b. Dead Code Review** (full codebase):
1. Spawn 4 dead-code Inspectors + dead-code Auditor:
   - sdd-inspector-dead-settings, sdd-inspector-dead-code, sdd-inspector-dead-specs, sdd-inspector-dead-tests
   - Each: "Report to: sdd-auditor-dead-code"
   - sdd-auditor-dead-code: "Expect: 4 Inspector results via SendMessage"
2. Read Auditor verdict from completion output
3. Dismiss all dead-code review teammates
4. Handle verdict:
   - **GO/CONDITIONAL** → Wave N complete, proceed to next wave
   - **NO-GO** → map findings to file paths, identify responsible Builder(s) from wave's file ownership records, re-spawn with fix instructions, re-review dead-code (max 3 retries → escalate)

**c. Post-gate**:
- Aggregate Knowledge Buffer from `{{SDD_DIR}}/handover/buffer.md`, deduplicate, write to `{{SDD_DIR}}/project/knowledge/` using templates, update `{{SDD_DIR}}/project/knowledge/index.md`, clear buffer.md
- Commit: `Wave {N}: {summary of completed specs}`
- Auto-draft `{{SDD_DIR}}/handover/session.md`

### Step 8: Roadmap Completion

After all waves complete:
- Report summary to user: `{wave_count} waves, {spec_count} specs completed`
- Suggest: `/sdd-status`

## Update Mode

Lead handles directly:
1. Load roadmap and scan all spec states
2. Detect structural differences (missing specs, wave mismatches, dependency changes)
3. Impact analysis (wave reordering, scope changes)
4. Present update options (Apply All / Selective / Abort)
5. Execute updates with preview

## Delete Mode

Lead handles directly:
1. Require explicit "RESET" confirmation
2. Delete roadmap.md and all spec directories
3. Optionally reinitialize via Create mode

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
