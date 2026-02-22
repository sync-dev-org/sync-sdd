# Run Mode

Orchestration reference. Lead handles pipeline execution directly. References phase execution refs (design.md, impl.md, review.md) for individual phase details.

## Step 1: Load State

1. Read `roadmap.md` and all `spec.yaml` files
2. Scan all `spec.yaml` files → rebuild pipeline state from phase/status fields
3. Build dependency graph from `spec.yaml.roadmap` fields
4. **DAG validation**: Topological sort the dependency graph. If a cycle is detected, BLOCK with: "Circular dependency detected: {cycle_path}. Fix spec.yaml.roadmap.dependencies before proceeding."

## Step 2: Cross-Spec File Ownership Analysis

1. Read all parallel-candidate specs' `design.md` Components sections (skip specs without `design.md`)
2. Detect file scope overlaps between specs in the same wave
3. Resolve overlaps:
   - **Serialize** (preferred): convert overlapping specs to sequential execution
   - **Partition**: re-assign file ownership. May require re-spawning TaskGenerator with file exclusion constraints
4. Validate: no file claimed by two parallel specs
5. Record final file ownership assignments for auto-fix routing
6. buffer.md: Lead has exclusive write access

## Step 3: Schedule Specs

Determine which specs can run in parallel (same wave, no file overlap, no dependency).
For each spec, track individual pipeline state:
```
spec-a: [Design] → [Design Review] → [Impl] → [Impl Review]
spec-b:   [Design] → [Design Review] → ...
spec-c:         (waiting on spec-a) → [Design] → ...
```

Design Review and Impl Review are **mandatory** in roadmap run.

## Step 4: Execute Per-Spec Pipelines

For each ready spec, execute pipeline phases in order:

### Design Phase

Execute per `refs/design.md` (Steps 1-3). After completion, update spec.yaml per design.md Step 3.

### Design Review Phase

Execute design review per `refs/review.md` (Design Review section).

Handle verdict:
- **GO/CONDITIONAL** → Proceed to Implementation Phase (counters are NOT reset — see CLAUDE.md §Counter Reset)
- **NO-GO** → increment `retry_count`. Dispatch Architect via `Task(subagent_type="sdd-architect")` with fix instructions. If Architect fails (no valid completion report): escalate entire spec to user. After successful fix: reset `orchestration.last_phase_action = null`. Phase remains `design-generated`. Re-run Design Review (max 5 retries, aggregate cap 6).
- **SPEC-UPDATE-NEEDED** → not expected for design review. If received, escalate immediately.
- In **gate mode**: pause for user approval before advancing

Process `STEERING:` entries from verdict. Auto-draft session.md.
For `--consensus N`, apply Consensus Mode protocol (see Router).

### Implementation Phase

Execute per `refs/impl.md` (Steps 1-3). Cross-Spec File Ownership (Layer 2): after TaskGenerator, detect file overlap between parallel specs → serialize or partition per Step 2. After ALL Builders complete, update spec.yaml per impl.md Step 3.

### Implementation Review Phase

Execute impl review per `refs/review.md` (Impl Review section).

Handle verdict:
- **GO/CONDITIONAL** → Spec pipeline complete (counters NOT reset)
- **NO-GO** → increment `retry_count`. Dispatch Builder(s) with fix instructions. After Builder completes: set `phase = implementation-complete`, update `implementation.files_created`. Re-run Impl Review (max 5 retries)
- **SPEC-UPDATE-NEEDED** → increment `spec_update_count` (max 2). Reset `orchestration.last_phase_action = null`, set `phase = design-generated`. Cascade: Architect (with SPEC_FEEDBACK) → TaskGenerator → Builder → re-run Impl Review. All tasks fully re-implemented.
- **Aggregate cap**: Total cycles (retry_count + spec_update_count) MUST NOT exceed 6. Escalate at 6.
- In **gate mode**: pause for user approval

Process `STEERING:` entries from verdict. Auto-draft session.md.
For `--consensus N`, apply Consensus Mode protocol (see Router).

## Step 5: Auto/Gate Mode Handling

**Full-Auto Mode** (default):
- GO/CONDITIONAL → auto-advance to next phase
- NO-GO → auto-fix loop (max 5 retries), then escalate
- SPEC-UPDATE-NEEDED → auto-fix from spec level, then escalate
- Wave transitions → automatic

**Gate Mode** (`--gate`):
- Pause at each review completion → user approval
- Pause at wave transitions → user approval
- Structural changes → escalate to user

## Step 6: Blocking Protocol

When a spec fails after exhausting retries:
1. Traverse dependency graph → identify all downstream specs
2. For each downstream spec: save phase to `blocked_info.blocked_at_phase`, set `phase=blocked`, `blocked_info.blocked_by={failed_spec}`, `blocked_info.reason=upstream_failure`
3. Report cascading impact to user
4. Present options:
   - **fix**: Verify upstream `implementation-complete` → unblock downstream (restore phases, clear blocked_info) → resume pipeline
   - **skip**: Exclude upstream. Warn downstream per-spec: "depends on skipped {upstream}". User confirms each: proceed / keep blocked / remove dependency
   - **abort**: Stop pipeline, leave all specs as-is

## Step 7: Wave Quality Gate

**1-Spec Roadmap**: Skip this step (see Router §1-Spec Roadmap Optimizations). Proceed to Post-gate.

Wave completion condition: all specs `implementation-complete` or `blocked`.

**a. Impl Cross-Check Review** (wave-scoped):
1. Execute impl review per `refs/review.md` (Impl Review, wave-scoped context: Waves 1..N, previously-resolved tracking)
2. Persist verdict to `specs/verdicts-wave.md` (header: `[W{wave}-B{seq}]`)
3. Handle verdict:
   - **GO/CONDITIONAL** → proceed to dead-code
   - **NO-GO** → map to target spec(s), increment `retry_count`, re-dispatch Builder(s) (update `implementation.files_created` after fix), re-run cross-check. Max 5 retries (aggregate cap 6). On exhaustion: escalate to user with options:
     - **Proceed**: Accept remaining issues, proceed to Dead Code Review. Record `ESCALATION_RESOLVED` in decisions.md
     - **Abort wave**: Stop wave execution, leave specs as-is. Record `ESCALATION_RESOLVED` with abort reason
     - **Manual fix**: User fixes manually, then Lead re-runs Wave QG (counters reset for manual-fix cycle)
   - **SPEC-UPDATE-NEEDED** → identify target spec(s), increment `spec_update_count`, cascade: Architect → TaskGenerator → Builder → individual Impl Review → re-run cross-check

**b. Dead Code Review**:
1. Execute dead-code review per `refs/review.md` (Dead-Code Review section)
2. Persist verdict to `specs/verdicts-wave.md` (header: `[W{wave}-DC-B{seq}]`)
3. Handle verdict:
   - **GO/CONDITIONAL** → Wave complete
   - **NO-GO** → identify responsible Builder(s), re-dispatch with fix instructions, re-review (max 3 retries → escalate). If findings reference files not owned by any wave spec: escalate those findings to user (cannot auto-fix unowned files)

**c. Post-gate**:
- **Reset counters**: For each spec in wave: `retry_count=0`, `spec_update_count=0`
- Aggregate Knowledge Buffer, deduplicate, write to `{{SDD_DIR}}/project/knowledge/`, clear buffer.md
- Commit: `Wave {N}: {summary}`
- Auto-draft session.md

## Step 8: Roadmap Completion

After all waves complete:
- Report summary: `{wave_count} waves, {spec_count} specs completed`
- Suggest: `/sdd-status`
