---
description: Unified spec lifecycle (design, implement, review, roadmap management)
allowed-tools: Bash, Glob, Grep, Read, Write, Edit, AskUserQuestion
argument-hint: design <feature> | impl <feature> [tasks] | review design|impl|dead-code <feature> [flags] | run [--gate] [--consensus N] | revise <feature> [instructions] | create [-y] | update | delete | -y
---

# SDD Roadmap (Unified Entry Point)

<instructions>

## Core Task

Unified entry point for all spec lifecycle operations. Roadmap is always required — even single-feature work auto-creates a 1-spec roadmap. Lifecycle subcommands (design, impl, review) ensure a roadmap exists before executing. Management subcommands (create, run, revise, update, delete) handle multi-feature orchestration.

## Step 1: Detect Mode

```
# Lifecycle subcommands (auto-create roadmap if needed)
$ARGUMENTS = "design {feature-or-description}"     → Design Subcommand
$ARGUMENTS = "impl {feature} [task-numbers]"        → Impl Subcommand
$ARGUMENTS = "review design {feature}"              → Review Subcommand (design)
$ARGUMENTS = "review impl {feature} [tasks]"        → Review Subcommand (impl)
$ARGUMENTS = "review dead-code [subtype]"           → Review Subcommand (dead-code)
$ARGUMENTS = "review {type} {feature} --consensus N" → Review Subcommand (consensus)
$ARGUMENTS = "review design --cross-check"          → Review Subcommand (cross-check)
$ARGUMENTS = "review impl --cross-check"            → Review Subcommand (cross-check)
$ARGUMENTS = "review design --wave N"               → Review Subcommand (wave-scoped)
$ARGUMENTS = "review impl --wave N"                 → Review Subcommand (wave-scoped)

# Management subcommands
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

## Single-Spec Roadmap Ensure

When a lifecycle subcommand (design, impl, review) is detected:

1. Check if `{{SDD_DIR}}/project/specs/roadmap.md` exists
2. **If roadmap exists**: Verify the target spec is enrolled
   - Read `{{SDD_DIR}}/project/specs/{feature}/spec.yaml`
   - If `spec.yaml.roadmap` is non-null → proceed to subcommand execution
   - If spec not found AND subcommand is `design` → **auto-add to roadmap**:
     1. Create spec directory, initialize spec.yaml from template
     2. Determine next wave number: max(existing waves) + 1
     3. Set `spec.yaml.roadmap = {wave: N+1, dependencies: []}`
     4. Update `roadmap.md` Wave Overview with new spec entry
     5. Inform user: "Added {feature} to roadmap (Wave {N+1})."
     6. Proceed to subcommand execution
   - If spec not found AND subcommand is `impl`/`review` → BLOCK: "Spec '{feature}' not found. Use `/sdd-roadmap design \"description\"` to create."
   - If spec exists but `spec.yaml.roadmap` is null → BLOCK: "{feature} exists but is not enrolled in the roadmap. Use `/sdd-roadmap update` to sync."
   - Exception: `review dead-code` and `review --cross-check` / `review --wave N` operate on the whole codebase/wave, not a single spec → skip enrollment check
3. **If no roadmap**:
   - If subcommand is `review dead-code`, `review --cross-check`, or `review --wave N` → BLOCK: "No roadmap found. Run `/sdd-roadmap create` first."
   - Otherwise, auto-create a 1-spec roadmap:
     a. For `design` with a new description: generate feature name (kebab-case), create spec directory, initialize spec.yaml from `{{SDD_DIR}}/settings/templates/specs/init.yaml`
     b. For `design` with existing spec name: verify spec directory exists (create if not)
     c. For `impl`/`review {feature}`: verify spec exists → BLOCK if not: "Spec '{feature}' not found. Use `/sdd-roadmap design \"description\"` to create."
     d. Create `roadmap.md` with single-wave structure containing the target spec
     e. Set `spec.yaml.roadmap = {wave: 1, dependencies: []}`
     f. Inform user: "Created single-spec roadmap for {feature}."
4. Proceed to the appropriate subcommand section

### 1-Spec Roadmap Optimizations

When `roadmap.md` contains exactly 1 spec:
- **Skip Wave Quality Gate**: Cross-check review is meaningless with 1 spec
- **Skip Cross-Spec File Ownership Analysis**: No overlap possible
- **Skip wave-level dead-code review**: User can still run `/sdd-roadmap review dead-code` manually
- **Commit message format**: `{feature}: {summary}` (not `Wave 1: {summary}`)

---

## Design Subcommand

Triggered by: `$ARGUMENTS = "design {feature-or-description}"`

After Single-Spec Roadmap Ensure:

### Step 1: Input Mode Detection

1. Parse feature name or description from arguments
2. Determine mode:
   - If spec was **just auto-created** by Single-Spec Roadmap Ensure (phase = `initialized`, no `design.md`) → **New Spec mode**
   - If spec existed before with `design.md` → **Existing Spec mode** (edit/regenerate)
   - If spec existed before without `design.md` (e.g., created by `create` with skeleton only) → **New Spec mode**

### Step 2: Phase Gate

- BLOCK if `spec.yaml.phase` is `blocked`: "{feature} is blocked by {blocked_info.blocked_by}"
- If `spec.yaml.phase` is `implementation-complete`: warn user that re-designing will invalidate existing implementation. Use AskUser to confirm: "Re-designing {feature} will invalidate the current implementation. Use `/sdd-roadmap revise {feature}` for targeted changes, or proceed with full re-design?" If rejected, abort.
- Otherwise: no phase restriction

### Step 3: Execute

Spawn Architect via **`TeammateTool`** (NOT Task tool). Follow Run Mode → Step 4 → Design Phase. Context:
- Feature: {feature}
- Mode: {new|existing}
- User-instructions: {from arguments, or empty}

After Architect completion, update spec.yaml:
- If re-edit (`version_refs.design` is non-null): increment `version` minor
- Set `version_refs.design` = current `version`
- Set `phase` = `design-generated`
- Set `orchestration.last_phase_action` = null (ensures next impl triggers REGENERATE)
- Update `changelog`

### Step 4: Post-Completion

1. Update relevant steering files if user expressed new requirements or direction changes (`product.md`, `tech.md`, `structure.md`, custom files as applicable)
2. Auto-draft `{{SDD_DIR}}/handover/session.md`
3. Report to user: design.md generated. Next: `/sdd-roadmap review design {feature}` or `/sdd-roadmap impl {feature}`

---

## Impl Subcommand

Triggered by: `$ARGUMENTS = "impl {feature} [task-numbers]"`

After Single-Spec Roadmap Ensure:

### Step 1: Phase Gate

1. Read `{{SDD_DIR}}/project/specs/{feature}/spec.yaml`, verify `design.md` exists
2. BLOCK if phase is `blocked`: "{feature} is blocked by {blocked_info.blocked_by}."
3. Phase check:
   - `design-generated`: proceed (standard flow)
   - `implementation-complete`: proceed (re-execution or task-specific re-run)
   - Other: BLOCK — "Phase is '{phase}'. Run `/sdd-roadmap design {feature}` first."

### Step 2: Determine Execution Mode

Read `tasks.yaml` status and `spec.yaml.orchestration.last_phase_action`:

- **REGENERATE**: `tasks.yaml` does not exist OR `orchestration.last_phase_action` is null → Spawn TaskGenerator via **`TeammateTool`** (see Run Mode → Step 4 → Implementation Phase steps 1-5). After TaskGenerator completes: set `orchestration.last_phase_action = "tasks-generated"`
- **RESUME**: `tasks.yaml` exists AND `last_phase_action` == `"tasks-generated"` → Use existing tasks.yaml
- **TASK RE-EXECUTION**: `phase` == `implementation-complete` AND `{task-numbers}` provided → Use existing tasks.yaml, filter to specified tasks
- **COMPLETED WITHOUT TASK SPEC**: `phase` == `implementation-complete` AND no task-numbers → Ask user: "A) Specify task numbers to re-run, B) Re-design first (`/sdd-roadmap design {feature}`), C) Abort"

### Step 3: Execute

Spawn Builder(s) via **`TeammateTool`** (NOT Task tool). Follow Run Mode → Step 4 → Implementation Phase (steps 6-11). If `{task-numbers}` provided: filter to specified task numbers only.

After ALL Builders complete, update spec.yaml:
- Set `phase` = `implementation-complete`
- Set `implementation.files_created` = `[{aggregated files}]`
- Set `version_refs.implementation` = current `version`
- Set `orchestration.last_phase_action` = `"impl-complete"`
- Update `changelog`

### Step 4: Post-Completion

1. Flush Knowledge Buffer to `{{SDD_DIR}}/project/knowledge/` (same as Run Mode post-gate)
2. Auto-draft `{{SDD_DIR}}/handover/session.md`
3. Report to user: tasks executed, test results, next: `/sdd-roadmap review impl {feature}`

---

## Review Subcommand

Triggered by: `$ARGUMENTS = "review design|impl|dead-code {feature} [options]"`

After Single-Spec Roadmap Ensure (except dead-code/cross-check/wave which skip enrollment):

### Step 1: Parse Arguments

Parse review type (`design`/`impl`/`dead-code`), feature name, and options (`--consensus N`, `--cross-check`, `--wave N`).

If first argument after "review" is not one of `design`, `impl`, `dead-code`:
- Error: "Usage: `/sdd-roadmap review design|impl|dead-code {feature}`"

### Step 2: Phase Gate

**Design Review**: Verify `design.md` exists. BLOCK if `spec.yaml.phase` is `blocked`.
**Implementation Review**: Verify `design.md` and `tasks.yaml` exist. Verify `phase` is `implementation-complete`. BLOCK if `blocked`.
**Dead Code Review**: No phase gate (operates on entire codebase).

### Step 3: Execute

Spawn all Inspectors + Auditor via **`TeammateTool`** (NOT Task tool — SubAgents cannot receive SendMessage).

- **Design review (single spec)**: Follow Run Mode → Step 4 → Design Review Phase
- **Impl review (single spec)**: Follow Run Mode → Step 4 → Implementation Review Phase
- **Dead-code review**: Follow Run Mode → Step 7b → Dead Code Review
- **Design cross-check / design wave-scoped**: Same as Design Review Phase but with cross-check context (all specs or wave-scoped). Use design Inspector set + design Auditor.
- **Impl cross-check / impl wave-scoped**: Follow Run Mode → Step 7a (Impl Cross-Check Review)
- **Consensus mode**: Apply consensus protocol per §Consensus Mode below

### Step 4: Handle Verdict

1. Parse CPF output from Auditor (or consensus verdict)
2. Persist verdict to the appropriate file:
   - **Single-spec review**: `{{SDD_DIR}}/project/specs/{feature}/verdicts.md`
   - **Dead-code review**: `{{SDD_DIR}}/project/specs/verdicts-dead-code.md`
   - **Cross-check review**: `{{SDD_DIR}}/project/specs/verdicts-cross-check.md`
   - **Wave-scoped review**: `{{SDD_DIR}}/project/specs/verdicts-wave.md`
   Persistence format:
   a. Read existing file (or create with `# Verdicts: {feature}` header)
   b. Determine B{seq} (increment max existing, or start at 1)
   c. Append batch entry: `## [B{seq}] {review-type} | {timestamp} | v{version} | runs:{N} | threshold:{K}/{N}`
   d. Append Raw section (N Auditor CPF verdicts verbatim)
   e. Append Consensus section (findings with freq ≥ threshold) and Noise section
   f. Append Disposition (`GO-ACCEPTED`, `CONDITIONAL-TRACKED`, `NO-GO-FIXED`, `SPEC-UPDATE-CASCADED`, `ESCALATED`)
   g. For CONDITIONAL: extract M/L issues → append as Tracked section
   h. If previous batch exists with Tracked: compare → append `Resolved since B{prev}`
3. Display formatted verdict report to user
4. **Auto-Fix Loop** (design/impl review only): Follow CLAUDE.md §Auto-Fix Loop
5. **Process STEERING entries**: CODIFY → apply directly. PROPOSE → present to user for approval.
6. Auto-draft `{{SDD_DIR}}/handover/session.md`

**Auditor context**: Include Steering Exceptions from `{{SDD_DIR}}/handover/session.md` in Auditor spawn prompt.

### Consensus Mode (`--consensus N`)

When `--consensus N` is provided (default threshold: ⌈N×0.6⌉):

1. Spawn N pipelines in parallel via `TeammateTool`. Each: same Inspector set + unique Auditor name
2. Apply Inspector Completion Protocol independently per pipeline
3. Read all N verdicts. Aggregate VERIFIED sections:
   - Key by `{category}|{location}`, count frequency
   - Confirmed (freq ≥ threshold) → Consensus. Noise (freq < threshold)
4. Consensus verdict: all GO → GO; any C/H in Consensus → NO-GO; only M/L → CONDITIONAL
5. Proceed to Step 4 with consensus verdict

### Inspector Completion Protocol

Apply uniformly to all review types:

**Step A**: Track Inspector idle notifications. Maintain `completed_inspectors[]` and `expected_count`.
**Step B**: Handle unavailable Inspectors per CLAUDE.md §Inspector Recovery Protocol.
**Step C**: Once all Inspectors resolved, send `SendMessageTool` to Auditor: `"ALL_INSPECTORS_COMPLETE: {N}/{expected} results delivered. Inspectors: {names}. Synthesize and output your verdict now."`
**Step D**: Await Auditor verdict. If idle without verdict → Auditor Recovery Protocol.

### Next Steps by Verdict

- Design GO/CONDITIONAL → `/sdd-roadmap impl {feature}`
- Impl GO/CONDITIONAL → Feature complete
- NO-GO → Auto-fix or manual fix
- SPEC-UPDATE-NEEDED → Auto-fix from spec level

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
1. Read `{{SDD_DIR}}/settings/agents/sdd-architect.md` → embed as spawn instructions
2. Spawn Architect via `TeammateTool` (opus) with instructions + context:
   - Feature: {feature}
   - Mode: {new|existing}
   - User-instructions: {additional user instructions, or empty string if none}
   - **Architect loads its own context** (steering, templates, rules, existing code) autonomously in Step 1-2. Do NOT pre-read these files for Architect.
3. Read Architect's completion report
4. Dismiss Architect
5. Verify `design.md` and `research.md` exist
6. Update spec.yaml: `phase=design-generated`, `version_refs.design={v}`
7. Auto-draft `{{SDD_DIR}}/handover/session.md`

#### Design Review Phase
1. Read agent profiles from `{{SDD_DIR}}/settings/agents/` for each teammate
2. Spawn (via `TeammateTool`) 6 design Inspectors (sonnet) + design Auditor (opus):
   - Inspector profiles: `sdd-inspector-{rulebase,testability,architecture,consistency,best-practices,holistic}.md`
   - Each Inspector context: "Feature: {feature}, Report to: sdd-auditor-design"
   - Auditor profile: `sdd-auditor-design.md`
   - Auditor context: "Feature: {feature}, Expect: 6 Inspector results via SendMessage"
3. Read Auditor's verdict from completion output
4. Dismiss all review teammates (6 Inspectors + Auditor)
5. Persist verdict to `{{SDD_DIR}}/project/specs/{feature}/verdicts.md` (see Review Subcommand § Step 4 step 2)
6. Handle verdict:
   - **GO/CONDITIONAL** → reset `retry_count` and `spec_update_count` to 0. Proceed to Implementation Phase
   - **NO-GO** → Auto-Fix Loop (see CLAUDE.md). After fix, phase remains `design-generated`
   - In **gate mode**: pause for user approval before advancing
7. Process `STEERING:` entries from verdict (append to `decisions.md` with Reason)
8. Auto-draft `{{SDD_DIR}}/handover/session.md`

If `--consensus N` is active, apply consensus mode per Review Subcommand §Consensus Mode.

#### Implementation Phase
1. Read `{{SDD_DIR}}/settings/agents/sdd-taskgenerator.md` → embed as spawn instructions
2. Spawn TaskGenerator via `TeammateTool` (sonnet) with instructions + context:
   - Feature: {feature}
   - Design: `{{SDD_DIR}}/project/specs/{feature}/design.md`
   - Research: `{{SDD_DIR}}/project/specs/{feature}/research.md` (if exists)
   - Review findings: from `specs/{feature}/verdicts.md` latest design batch Tracked (if exists)
3. Read TaskGenerator's completion report (`TASKGEN_COMPLETE`)
4. Dismiss TaskGenerator
5. Verify `tasks.yaml` exists
6. Read `tasks.yaml` execution plan → determine Builder grouping
7. Cross-Spec File Ownership (Layer 2): Lead reads all parallel specs' tasks.yaml execution sections. Detect file overlap → serialize or partition (see Step 2). If partition requires file reassignment, re-spawn TaskGenerator for affected spec with file exclusion constraints, then re-read tasks.yaml
8. Read tasks.yaml tasks section → extract detail bullets for Builder spawn prompts
9. Read `{{SDD_DIR}}/settings/agents/sdd-builder.md` → embed as spawn instructions
10. Spawn Builder(s) via `TeammateTool` (sonnet) with instructions + context for each work package:
    - Feature: {feature}
    - Tasks: {task IDs + summaries + detail bullets}
    - File scope: {assigned files}
    - Design ref: `{{SDD_DIR}}/project/specs/{feature}/design.md`
    - Research ref: `{{SDD_DIR}}/project/specs/{feature}/research.md` (if exists)
11. **Builder incremental processing**: As each Builder completes, immediately:
   - Read completion report (files, test results, knowledge tags, blockers)
   - Update tasks.yaml: mark completed tasks as `done`
   - Store knowledge tags in `{{SDD_DIR}}/handover/buffer.md`
    - If BUILDER_BLOCKED: classify cause (missing dependency → reorder tasks, re-spawn; external blocker → escalate to user; design gap → escalate, suggest re-design). Record as `[INCIDENT]` in buffer.md
12. When dependent tasks are unblocked: dismiss completed Builder, spawn next-wave Builders immediately
13. On ALL Builders complete:
   - Dismiss remaining Builders
   - Aggregate files from all Builder reports
   - Update spec.yaml: `phase=implementation-complete`, `implementation.files_created=[{files}]`, `version_refs.implementation={version}`
   - Auto-draft `{{SDD_DIR}}/handover/session.md`

#### Implementation Review Phase
1. Read agent profiles from `{{SDD_DIR}}/settings/agents/` for each teammate
2. Spawn (via `TeammateTool`) 6 impl Inspectors (sonnet) + impl Auditor (opus):
   - Inspector profiles: `sdd-inspector-{impl-rulebase,interface,test,quality,impl-consistency,impl-holistic}.md`
   - Each Inspector context: "Feature: {feature}, Report to: sdd-auditor-impl"
   - Auditor profile: `sdd-auditor-impl.md`
   - Auditor context: "Feature: {feature}, Expect: 6 Inspector results via SendMessage"
3. Read Auditor's verdict from completion output
4. Dismiss all review teammates (6 Inspectors + Auditor)
5. Persist verdict to `{{SDD_DIR}}/project/specs/{feature}/verdicts.md` (see Review Subcommand § Step 4 step 2)
6. Handle verdict:
   - **GO/CONDITIONAL** → reset `retry_count` and `spec_update_count` to 0. Spec pipeline complete
   - **NO-GO** → increment `retry_count`. Auto-Fix Loop: spawn Builder(s) via `TeammateTool` with fix instructions → re-review (max 3 retries)
   - **SPEC-UPDATE-NEEDED** → increment `spec_update_count` (max 2). Reset `orchestration.last_phase_action = null`, set `phase = design-generated`. Cascade fix: spawn Architect via `TeammateTool` (with SPEC_FEEDBACK from Auditor) → TaskGenerator → Builder → re-review. All tasks fully re-implemented (no differential).
   - In **gate mode**: pause for user approval
7. Process `STEERING:` entries from verdict (append to `decisions.md` with Reason)
8. Auto-draft `{{SDD_DIR}}/handover/session.md`

If `--consensus N` is active, apply consensus mode per Review Subcommand §Consensus Mode.

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
   - **fix**: After user claims upstream is fixed, Lead verifies upstream spec phase is `implementation-complete` before unblocking downstream. If not verified, re-run `/sdd-roadmap review impl {upstream}` first
   - **skip**: Exclude upstream spec from pipeline, evaluate if downstream dependencies are resolved
   - **abort**: Stop pipeline, leave all specs as-is

### Step 7: Wave Quality Gate

**1-Spec Roadmap**: If `roadmap.md` contains exactly 1 spec, skip this entire step (see §1-Spec Roadmap Optimizations). Proceed directly to Post-gate commit.

Wave completion condition: all specs in wave are `implementation-complete` or `blocked`.
Wave scope is cumulative: Wave N quality gate re-inspects ALL code from Waves 1..N. Inspectors flag only NEW issues not previously resolved in earlier wave gates.

After all specs in a wave complete individual pipelines:

**a. Impl Cross-Check Review** (wave-scoped):
0. **Load previously resolved issues**: Read `{{SDD_DIR}}/project/specs/verdicts-wave.md` (if exists). Collect Consensus findings from previous wave batches. Compare successive batches to identify resolved issues (present in earlier batch Consensus but absent from later). Format as PREVIOUSLY_RESOLVED for Inspector spawn context.
1. Read agent profiles from `{{SDD_DIR}}/settings/agents/`. Spawn (via `TeammateTool`) 6 impl Inspectors (sonnet) + Auditor (opus) with wave-scoped cross-check context:
   - Inspector profiles: `sdd-inspector-{impl-rulebase,interface,test,quality,impl-consistency,impl-holistic}.md`
   - Each Inspector context: "Wave-scoped cross-check, Wave: 1..{N}, Previously resolved: {PREVIOUSLY_RESOLVED from verdicts-wave.md}, Report to: sdd-auditor-impl"
   - Auditor profile: `sdd-auditor-impl.md`. Context: "Wave-scoped cross-check, Wave: 1..{N}, Expect: 6 Inspector results"
2. Read Auditor verdict from completion output
3. Dismiss all cross-check teammates
3.5. Persist verdict to `{{SDD_DIR}}/project/specs/verdicts-wave.md` (header: `[W{wave}-B{seq}]`). Same persistence logic as Review Subcommand § Step 4 step 2.
4. Handle verdict:
   - **GO/CONDITIONAL** → proceed to dead-code review
   - **NO-GO** → map findings to file paths, identify responsible Builder(s) from wave's file ownership records, re-spawn via `TeammateTool` with fix instructions, re-review (max 3 retries). On exhaustion: escalate to user with options:
     a. **Proceed**: Accept remaining issues, proceed to Dead Code Review. Record as `ESCALATION_RESOLVED` in decisions.md with accepted issues listed
     b. **Abort wave**: Stop wave execution, leave specs as-is. Record as `ESCALATION_RESOLVED` with abort reason
     c. **Manual fix**: User fixes issues manually, then Lead re-runs Wave QG (counter reset)
   - **SPEC-UPDATE-NEEDED** → parse Auditor's SPEC_FEEDBACK section to identify the target spec(s). For each affected spec: reset orchestration (`last_phase_action = null`), set `phase = design-generated`, spawn Architect via `TeammateTool` with SPEC_FEEDBACK → TaskGenerator → Builder → re-review

**b. Dead Code Review** (full codebase):
1. Read agent profiles from `{{SDD_DIR}}/settings/agents/`. Spawn (via `TeammateTool`) 4 dead-code Inspectors (sonnet) + dead-code Auditor (opus):
   - Inspector profiles: `sdd-inspector-{dead-settings,dead-code,dead-specs,dead-tests}.md`
   - Each context: "Report to: sdd-auditor-dead-code"
   - Auditor profile: `sdd-auditor-dead-code.md`. Context: "Expect: 4 Inspector results via SendMessage"
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
4. **Steering update**: If revision intent implies direction changes, update relevant steering files BEFORE spawning Architect (`product.md` for requirements/vision, `tech.md` for technical decisions, `structure.md` for structural changes, custom files as needed). This ensures Architect reads current steering context.

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

All teammates spawned via **`TeammateTool`** with agent profiles from `{{SDD_DIR}}/settings/agents/`.

1. **Design Phase**: Read `sdd-architect.md` profile. Spawn Architect (opus) with instructions + context:
   - Feature: {feature}
   - Mode: existing
   - User-instructions: {REVISION_INSTRUCTIONS from Step 2}. Preserve unaffected design sections. Document changes in a '## Revision Notes' subsection.
   - **Architect loads its own context.** Do NOT pre-read files for Architect.
2. **Design Review Phase**: Same as Run Mode Step 4 Design Review (read Inspector/Auditor profiles, spawn via TeammateTool)
3. **Implementation Phase**: Same as Run Mode Step 4 Implementation (read TaskGenerator/Builder profiles, spawn via TeammateTool)
4. **Implementation Review Phase**: Same as Run Mode Step 4 Impl Review (read Inspector/Auditor profiles, spawn via TeammateTool)

Auto-fix loop applies normally (retry_count, spec_update_count).

### Step 6: Downstream Resolution

After revision pipeline completes (spec returns to `implementation-complete`):

1. For each direct dependent spec that is `implementation-complete`:
   - Present to user per-spec:
     a. **Re-review**: Run impl review only (`/sdd-roadmap review impl {dep}`)
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

- **No roadmap for run/update/revise**: "No roadmap found. Run `/sdd-roadmap create` first."
- **No steering for create**: Warn and suggest `/sdd-steering` first
- **Spec not in roadmap**: "{feature} is not part of the active roadmap. Use `/sdd-roadmap update` to add it."
- **Spec not found (impl/review)**: "Spec '{feature}' not found. Use `/sdd-roadmap design \"description\"` to create."
- **Missing design.md (impl)**: "Run `/sdd-roadmap design {feature}` first."
- **Wrong phase (impl)**: "Phase is '{phase}'. Run `/sdd-roadmap design {feature}` first."
- **Wrong phase for impl review**: "Phase is '{phase}'. Run `/sdd-roadmap impl {feature}` first."
- **Blocked**: "{feature} is blocked by {blocked_info.blocked_by}."
- **Spec conflicts during run**: Lead handles file ownership resolution (serialize preferred, partition allowed)
- **Spec failure (retries exhausted)**: Block dependent specs via Blocking Protocol, report cascading impact, present options (fix / skip / abort)
- **Artifact verification failure**: Do not update spec.yaml — escalate to user
