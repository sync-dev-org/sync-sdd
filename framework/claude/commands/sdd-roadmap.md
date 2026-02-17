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
7. Set `spec.json.roadmap` for each spec: `{"wave": N, "dependencies": ["spec-name", ...]}`
8. Generate roadmap.md with Wave Overview, Dependencies, Execution Flow
9. **Update product.md** User Intent → Spec Rationale section
10. Update `{{SDD_DIR}}/handover/state.md`

## Run Mode

Lead handles pipeline execution directly.

### Step 1: Load State

1. Read `roadmap.md` and all `spec.json` files
2. If `{{SDD_DIR}}/handover/state.md` exists with Pipeline State → resume from saved state
3. Build dependency graph from `spec.json.roadmap` fields

### Step 2: Cross-Spec File Ownership Analysis

1. Read all parallel-candidate specs' `design.md` Components sections
2. Detect file scope overlaps between specs in the same wave
3. If overlap detected: serialize overlapping specs OR partition file ownership
4. Record file ownership assignments for later auto-fix routing

### Step 3: Schedule Specs

Determine which specs can run in parallel (same wave, no file overlap, no dependency).
For each spec, track individual pipeline state:
```
spec-a: [Architect] → [Design Review] → [Planner] → [Builder ×N] → [Impl Review]
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
5. Update spec.json: `phase=design-generated`, `version_refs.design={v}`, `version_refs.tasks=null`
6. Update `{{SDD_DIR}}/handover/state.md`

#### Design Review Phase
1. Spawn 5 design Inspectors + design Auditor:
   - Inspector set: rulebase, testability, architecture, consistency, best-practices
   - Each Inspector context: "Feature: {feature}, Report to: sdd-auditor-design"
   - Auditor context: "Feature: {feature}, Expect: 5 Inspector results via SendMessage"
2. Read Auditor's verdict from completion output
3. Dismiss all review teammates (5 Inspectors + Auditor)
4. Handle verdict:
   - **GO/CONDITIONAL** → proceed to Task Generation
   - **NO-GO** → Auto-Fix Loop (see CLAUDE.md)
   - In **gate mode**: pause for user approval before advancing
5. Process `STEERING:` entries from verdict
6. Update handover

#### Task Generation Phase
1. Spawn Planner with context:
   - Feature: {feature}
   - Design: `{{SDD_DIR}}/project/specs/{feature}/design.md`
   - Research: `{{SDD_DIR}}/project/specs/{feature}/research.md` (if exists)
   - Template: `{{SDD_DIR}}/settings/templates/specs/tasks.md`
2. Read Planner's completion report
3. Dismiss Planner
4. Verify `tasks.md` exists
5. Update spec.json: `phase=tasks-generated`, `version_refs.tasks={v}`
6. Update handover

#### Implementation Phase
1. Read `tasks.md`, `design.md`, and `research.md` (if exists) for the feature
2. Analyze `(P)` markers and dependency chains → determine parallelism
3. Read Components section → determine file ownership per Builder
4. Group tasks into Builder work packages (no file overlap)
5. Spawn Builder(s) with context for each work package:
   - Feature: {feature}
   - Tasks: {task numbers}
   - File scope: {assigned files}
   - Design ref: `{{SDD_DIR}}/project/specs/{feature}/design.md`
   - Research ref: `{{SDD_DIR}}/project/specs/{feature}/research.md` (if exists)
6. Read each Builder's completion report. Collect:
   - Files created/modified
   - Test results
   - Knowledge tags (`[PATTERN]`/`[INCIDENT]`/`[REFERENCE]`)
   - Blocker reports
7. When dependent tasks are unblocked: dismiss completed Builders, spawn next wave
8. On all tasks complete:
   - Dismiss all Builders
   - Aggregate files from all Builder reports
   - Update spec.json: `phase=implementation-complete`, `implementation.files_created=[{files}]`
   - Update handover

#### Implementation Review Phase
1. Spawn 5 impl Inspectors + impl Auditor:
   - Inspector set: impl-rulebase, interface, test, quality, impl-consistency
   - Each Inspector context: "Feature: {feature}, Report to: sdd-auditor-impl"
   - Auditor context: "Feature: {feature}, Expect: 5 Inspector results via SendMessage"
2. Read Auditor's verdict from completion output
3. Dismiss all review teammates (5 Inspectors + Auditor)
4. Handle verdict:
   - **GO/CONDITIONAL** → spec pipeline complete
   - **NO-GO** → Auto-Fix Loop: spawn Builder(s) with fix instructions → re-review (max 3 retries)
   - **SPEC-UPDATE-NEEDED** → cascade fix: Architect → Planner → Builder → re-review
   - In **gate mode**: pause for user approval
5. Process `STEERING:` entries from verdict
6. Update handover

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

### Step 6: Failure Propagation

When a spec fails after exhausting retries:
- Mark all downstream dependent specs as `blocked`
- Report cascading impact to user
- Present options to user: fix / skip / abort roadmap

### Step 7: Wave Quality Gate

After all specs in a wave complete individual pipelines:

**a. Impl Cross-Check Review** (wave-scoped):
1. Spawn 5 impl Inspectors + Auditor with wave-scoped cross-check context:
   - Each Inspector: "Wave-scoped cross-check, Wave: 1..{N}, Report to: sdd-auditor-impl"
   - Auditor: "Wave-scoped cross-check, Wave: 1..{N}, Expect: 5 Inspector results"
2. Read Auditor verdict from completion output
3. Dismiss all cross-check teammates
4. Handle verdict:
   - **GO/CONDITIONAL** → proceed to dead-code review
   - **NO-GO** → map findings to file paths, identify responsible Builder(s) from wave's file ownership records, re-spawn with fix instructions, re-review (max 3 retries → escalate)
   - **SPEC-UPDATE-NEEDED** → cascade fix from spec level (Architect → Planner → Builder → re-review)

**b. Dead Code Review** (full codebase):
1. Spawn 4 dead-code Inspectors + dead-code Auditor:
   - sdd-inspector-dead-settings, sdd-inspector-dead-code, sdd-inspector-dead-specs, sdd-inspector-dead-tests
   - Each: "Report to: sdd-auditor-dead-code"
   - sdd-auditor-dead-code: "Expect: 4 Inspector results via SendMessage"
2. Read Auditor verdict from completion output
3. Dismiss all dead-code review teammates
4. Handle verdict:
   - **GO** → Wave N complete, proceed to next wave
   - **CONDITIONAL/NO-GO** → map findings to file paths, identify responsible Builder(s) from wave's file ownership records, re-spawn with fix instructions, re-review dead-code (max 3 retries → escalate)

**c. Post-gate**:
- Aggregate Knowledge Buffer entries, deduplicate, write to `{{SDD_DIR}}/project/knowledge/`
- Commit: `Wave {N}: {summary of completed specs}`
- Update `{{SDD_DIR}}/handover/state.md` with Wave Quality Gate results

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

1. Update `{{SDD_DIR}}/handover/state.md`
2. Report results to user

</instructions>

## Error Handling

- **No roadmap for run/update**: "No roadmap found. Run `/sdd-roadmap create` first."
- **No steering for create**: Warn and suggest `/sdd-steering` first
- **Spec conflicts during run**: Lead handles file ownership resolution (serialize or partition)
- **Spec failure (retries exhausted)**: Block dependent specs, report cascading impact, present options (fix / skip / abort)
