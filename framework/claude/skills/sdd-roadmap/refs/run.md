# Run Mode

Orchestration reference. Lead handles pipeline execution directly. References phase execution refs (design.md, impl.md, review.md) for individual phase details.

## Step 1: Load State

1. Read `roadmap.md` and all `spec.yaml` files
2. Scan all `spec.yaml` files → rebuild pipeline state from phase/status fields
3. Build dependency graph from `spec.yaml.roadmap` fields
4. **DAG validation**: Topological sort the dependency graph. If a cycle is detected, BLOCK with: "Circular dependency detected: {cycle_path}. Fix spec.yaml.roadmap.dependencies before proceeding."

## Step 2: Cross-Spec File Ownership Analysis

File ownership is **advisory**: it guides Builder task assignment and auto-fix routing but is not enforced at the file system level. Builders may read files outside their assigned scope; they SHOULD NOT write to files owned by another spec's Builder unless the task explicitly requires cross-spec integration.

1. Read all parallel-candidate specs' `design.md` Components sections (skip specs without `design.md`)
2. Detect file scope overlaps between specs in the same wave
3. Resolve overlaps:
   - **Serialize** (preferred): convert overlapping specs to sequential execution
   - **Partition**: re-assign file ownership. May require re-spawning TaskGenerator with file exclusion constraints
4. Validate: no file claimed by two parallel specs
5. Record final file ownership assignments for auto-fix routing

## Step 2.5: Wave Context Generation

Before dispatching any Architect or Builder, Lead generates shared context artifacts to ensure consistency across parallel agents.

### Conventions Brief

Dispatch `sdd-conventions-scanner` SubAgent (mode: Generate) to scan the codebase and generate the conventions brief. This keeps scan results out of Lead's context.

Dispatch via `Agent(subagent_type="sdd-conventions-scanner", run_in_background=true)` with prompt:
- Mode: Generate
- Steering: `{{SDD_DIR}}/project/steering/`
- Buffer: `{{SDD_DIR}}/handover/buffer.md`
- Template: `{{SDD_DIR}}/settings/templates/wave-context/conventions-brief.md`
- Output: `{{SDD_DIR}}/project/specs/.wave-context/{wave-N}/conventions-brief.md` (multi-spec roadmap) or `{{SDD_DIR}}/project/specs/{feature}/conventions-brief.md` (1-spec roadmap)
- Wave/feature: {identifier}

Wait for `WRITTEN:{path}` response.

**Greenfield projects**: Scanner generates from steering only if no source files exist. Pilot Stagger (impl.md) becomes the primary convention-seeding mechanism.

**Steering precedence**: Conventions brief captures *observed practice*. If brief conflicts with steering, steering wins (stated in brief header by scanner).

### Shared Research (Architect-only, conditional)

When 2+ Architects will be dispatched in parallel (Design Fan-Out), Lead generates a shared research context to reduce redundant discovery:

1. Extract common technology stack decisions from steering
2. Identify shared dependencies across wave specs (from spec.yaml descriptions + roadmap context)
3. If previous waves completed: summarize relevant findings from their `research.md` files
4. Write to `{{SDD_DIR}}/project/specs/.wave-context/{wave-N}/shared-research.md` (free-form, no template — content varies by project context)

Skip if only 1 Architect will be dispatched (1-spec roadmap or single spec in wave).

### Dependency Sync (Pre-Design)

Before dispatching Architects (Design Fan-Out), ensure project dependencies are in sync:

1. Read `steering/tech.md` and `pyproject.toml` (or package.json, Cargo.toml)
2. For each spec in this wave: if spec name/description, user instructions, or existing design.md implies new external SDKs, add to dependency manifest (extras + dev group) and install
3. Run install command from `steering/tech.md` Common Commands (`# Install:` line)
4. Determine SDK source paths for Architect prompts (e.g., `uv run python -c "import {pkg}; print({pkg}.__file__)"`)
5. This ensures SDKs are available for Architect to read from site-packages during design (see design-discovery-full.md Step 3)

### Conventions Brief Update (Post-Design)

After all Architects in a wave complete Design, Lead may update the conventions brief with design-derived conventions (e.g., shared interface patterns, agreed data model styles from design.md files) before Implementation begins. This is a lightweight supplement, not a full regeneration.

## Step 3: Schedule Specs

### Island Spec Detection (Wave Bypass)

Before wave scheduling, identify **island specs** — specs that are fully independent:
1. Has no `roadmap.dependencies`
2. No other spec lists it in their `dependencies`
3. Extract island specs to **fast-track lane** — they run outside the wave structure

Fast-track execution:
- Full pipeline: Design → Design Review → Impl → Impl Review
- 1-Spec Roadmap Optimizations apply: skip Wave QG
- Individual commit: `{feature}: {summary}`
- Runs in parallel with wave-bound specs
- Does NOT participate in Wave QG cross-check

If Impl-phase Layer 2 file ownership check discovers overlap between a fast-track spec and a wave-bound spec, demote the fast-track spec back to wave-bound and serialize.

### Wave Spec Scheduling

For wave-bound specs, track per-spec pipeline state and determine readiness dynamically (see Step 4 Dispatch Loop).

Design Review and Impl Review are **mandatory** in roadmap run.

## Step 4: Parallel Dispatch Loop

Specs within a wave advance through phases concurrently (**Spec Stagger**). Instead of processing one spec's full pipeline before starting the next, Lead dispatches the next ready phase for any eligible spec.

### Dispatch Loop

```
For each wave (sequential):

  Initialize:
    ready_specs = wave-bound specs at their current phase
    active = {}  # spec → running SubAgent task(s)
    review_state = {}  # spec → {phase: inspecting|auditing, inspector_tasks, auditor_task, b_seq, scope_dir}

  Loop:
    1. ADVANCE: For each spec in wave (not active, not blocked):
       - Determine next phase based on Readiness Rules (phase + verdict history)
       - If ready: dispatch phase (run_in_background: true), add to active set
       - For review phases: decomposed dispatch per §Review Decomposition

    2. LOOKAHEAD: Check next-wave Design eligibility (see Design Lookahead below)

    3. WAIT: Poll all active agents (Architects, Builders, individual Inspectors, Auditors) via TaskOutput (block=false). When any completes, proceed to step 4. If none complete, block on any one via TaskOutput.

    4. PROCESS: Handle completion
       - Review sub-phase (Inspector/Auditor): advance per §Review Decomposition
       - Phase completion (Design/Impl/TaskGenerator/Builder): handle per Phase Handlers, update spec.yaml as specified
       - Remove completed task from active set
       - Loop back to step 1 (completions may unblock other specs or enable next phase for same spec)

    5. EXIT: If no spec has a dispatchable next phase (per Readiness Rules) and active is empty → Wave QG (Step 7)
```

### Review Decomposition (Dispatch Loop Context)

Within the dispatch loop, reviews are NOT atomic operations. They decompose into dispatch-loop events so that one spec's review completion immediately triggers the next phase for that spec (Spec Stagger). Standalone reviews (`/sdd-roadmap review design {feature}`) use review.md's sequential flow as-is.

**Sub-phases**:

1. **DISPATCH-INSPECTORS** (triggered from ADVANCE when spec is ready for review):
   - Execute review.md steps 1-4 (scope dir, B{seq}, create active dir, web server start if applicable — uses tmux pane or background Bash per Web Inspector Server Protocol, spawn all Inspectors)
   - Add Inspector tasks to `active[spec]`, set `review_state[spec].phase = inspecting`
   - **Return to dispatch loop immediately** — do not wait for Inspectors

2. **INSPECTORS-COMPLETE** (triggered from PROCESS when ALL Inspectors for a spec finish):
   - Execute review.md steps 5, 5a (handle failures, stop web server if applicable — kill tmux pane or PID per Web Inspector Server Protocol)
   - Spawn Auditor (review.md step 6), update `active[spec]` to Auditor task
   - Set `review_state[spec].phase = auditing`

3. **AUDITOR-COMPLETE** (triggered from PROCESS when Auditor finishes):
   - Execute review.md steps 7-9 (read verdict, persist to verdicts.md, archive active → B{seq})
   - Remove from `active` and `review_state`
   - Proceed to Phase Handler verdict handling (GO/CONDITIONAL/NO-GO)
   - ADVANCE runs next → may dispatch Implementation for this spec while other specs are still in review

**NO-GO flow**: Phase Handler dispatches Architect with fix instructions directly from PROCESS (not via ADVANCE). After Architect completes, ADVANCE re-evaluates readiness and dispatches new review (Readiness Rules: last verdict is NO-GO → DR eligible).

### Readiness Rules

A spec can advance to its next phase when ALL conditions are met:

| Next Phase | Conditions |
|-----------|------------|
| **Design** | Phase is `initialized`. Intra-wave dependencies (if any) have reached `design-generated`. |
| **Design Review** | Phase is `design-generated`. Latest design batch verdict is absent or NO-GO (review not yet passed). |
| **Implementation** | Phase is `design-generated` AND Design Review verdict is GO/CONDITIONAL (check `verdicts.md` latest batch on resume). No file overlap with any spec currently in Implementation (Cross-Spec File Ownership Layer 2). Inter-wave dependencies `implementation-complete` (intra-wave deps do NOT block impl — only inter-wave deps matter). |
| **Impl Review** | Phase is `implementation-complete`. All Builders for this spec have completed. Latest impl batch verdict is absent or NO-GO (review not yet passed). |

**Design Fan-Out**: Multiple specs at `initialized` that satisfy the Design readiness rule are dispatched in parallel via `Agent(subagent_type="sdd-architect", run_in_background=true)`. Each Architect prompt includes conventions brief path and shared research path (if generated in Step 2.5). Lead continues the dispatch loop immediately.

### Design Lookahead

During the dispatch loop, check if next-wave specs can begin Design early:

1. For each Wave N+1 spec at `initialized`:
   - All its `roadmap.dependencies` in Wave N have `design.md` available (reached `design-generated`)?
   - If yes: dispatch Architect (same as Design Fan-Out)
2. Lookahead eligibility is **dynamically computed** from spec.yaml phase + dependency state — no persistent tracking needed. On resume, re-evaluate: any Wave N+1 spec at `initialized` whose Wave N dependencies are `design-generated` is eligible.
3. Lookahead specs proceed through Design and Design Review only — they do NOT start Implementation until Wave N QG passes
4. **Staleness guard**: If a Wave N spec's design changes (NO-GO → Architect re-dispatch), check if any lookahead spec depends on it. If yes: reset the lookahead spec's `phase` to `initialized`, clear `version_refs.design`, and set `orchestration.last_phase_action` to `null`. This is persistent (survives session resume) and causes the dispatch loop to re-evaluate lookahead eligibility naturally — once the Wave N dependency's new design is ready, the spec becomes eligible for Lookahead again via step 1.

### Phase Handlers

**Auto-draft policy (dispatch loop)**: During `run` pipeline execution, auto-draft session.md only at: Wave QG post-gate, user escalation, pipeline completion. Skip auto-draft at individual phase completions (Design, Impl, Review) — spec.yaml is the ground truth for pipeline state.

#### Design completion
Dispatch Architect per `refs/design.md` Step 3 (Mode Detection and Phase Gate already handled by dispatch loop). After Architect completes, update spec.yaml per design.md Step 3.

#### Design Review completion
In dispatch loop: decomposed per §Review Decomposition (verdict handling below triggers at AUDITOR-COMPLETE). Standalone: execute per `refs/review.md`.

Handle verdict:
- **GO/CONDITIONAL** → Spec becomes eligible for Implementation (counters NOT reset — see CLAUDE.md §Auto-Fix Counter Limits)
- **NO-GO** → increment `retry_count`. Dispatch Architect with fix instructions. If Architect fails: escalate to user. After fix: reset `orchestration.last_phase_action = null`, phase remains `design-generated`. Re-run Design Review (max 5 retries, aggregate cap 6). On exhaustion: escalate to user (same options as Step 6 Blocking Protocol).
- **SPEC-UPDATE-NEEDED** → not expected for design review. If received, escalate immediately.
- In **gate mode**: pause for user approval before advancing

Process `STEERING:` entries from verdict.
For `--consensus N`, apply Consensus Mode protocol (see Router).

#### Implementation completion
Execute per `refs/impl.md` (Steps 1-3, skip Step 4 auto-draft when called from dispatch loop). Pass conventions brief path from Step 2.5 to impl.md (included in TaskGenerator and Builder dispatch prompts). Cross-Spec File Ownership (Layer 2): after TaskGenerator, detect file overlap between specs currently in Implementation → serialize or partition per Step 2. After ALL Builders complete, update spec.yaml per impl.md Step 3.

#### Impl Review completion
In dispatch loop: decomposed per §Review Decomposition (verdict handling below triggers at AUDITOR-COMPLETE). Standalone: execute per `refs/review.md`.

Handle verdict:
- **GO/CONDITIONAL** → Spec pipeline complete (counters NOT reset)
- **NO-GO** → increment `retry_count`. Dispatch Builder(s) with fix instructions. After Builder completes: phase remains `implementation-complete`, update `implementation.files_created`. Re-run Impl Review (max 5 retries, aggregate cap 6)
- **SPEC-UPDATE-NEEDED** → increment `spec_update_count` (max 2). Reset `orchestration.last_phase_action = null`, set `phase = design-generated`. Cascade: Architect (with SPEC_FEEDBACK) → TaskGenerator → Builder → re-run Impl Review. All tasks fully re-implemented.
- **Aggregate cap**: Total cycles (retry_count + spec_update_count) MUST NOT exceed 6. Escalate at 6.
- In **gate mode**: pause for user approval

Process `STEERING:` entries from verdict.
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
   - **fix**: Verify upstream `implementation-complete` → unblock downstream (restore phases, clear blocked_info, reset `retry_count=0` and `spec_update_count=0` for unblocked specs) → resume pipeline
   - **skip**: Exclude upstream. Reset counters (`retry_count=0`, `spec_update_count=0`) for affected downstream specs. Warn downstream per-spec: "depends on skipped {upstream}". User confirms each: proceed / keep blocked / remove dependency
   - **abort**: Stop pipeline, leave all specs as-is

## Step 7: Wave Quality Gate

**1-Spec Roadmap**: Skip this step (see Router §1-Spec Roadmap Optimizations). Proceed to Post-gate.

Wave completion condition: all specs `implementation-complete` or `blocked`.

**a. Impl Cross-Check Review** (wave-scoped):
1. Execute impl review per `refs/review.md` (Impl Review, wave-scoped context: Waves 1..N, previously-resolved tracking)
2. Persist verdict to `{{SDD_DIR}}/project/reviews/wave/verdicts.md` (header: `[W{wave}-B{seq}]`)
3. Handle verdict:
   - **GO/CONDITIONAL** → proceed to dead-code
   - **NO-GO** → map to target spec(s), increment target spec's `retry_count`, re-dispatch Builder(s) (update `implementation.files_created` after fix), re-run cross-check. Max 5 retries per spec (aggregate cap 6 per spec). On exhaustion: escalate to user with options:
     - **Proceed**: Accept remaining issues, proceed to Dead Code Review. Record `ESCALATION_RESOLVED` in decisions.md
     - **Abort wave**: Stop wave execution, leave specs as-is. Record `ESCALATION_RESOLVED` with abort reason
     - **Manual fix**: User fixes manually, then Lead re-runs Wave QG (counters reset for manual-fix cycle)
   - **SPEC-UPDATE-NEEDED** → identify target spec(s), increment `spec_update_count`, cascade per spec: Architect → TaskGenerator → Builder → individual Impl Review. After ALL target spec cascades complete → re-run cross-check

**b. Dead Code Review**:
1. Execute dead-code review per `refs/review.md` (Dead-Code Review section)
2. Persist verdict to `{{SDD_DIR}}/project/reviews/wave/verdicts.md` (header: `[W{wave}-DC-B{seq}]`)
3. Handle verdict:
   - **GO/CONDITIONAL** → Wave complete
   - **NO-GO** → identify responsible Builder(s), re-dispatch with fix instructions, re-review (max 3 retries, tracked in-memory by Lead — not persisted to spec.yaml. Dead-code findings are wave-scoped and resolved within a single execution window; counter restarts at 0 on session resume. Separate from per-spec aggregate cap → escalate). If findings reference files not owned by any wave spec: escalate those findings to user (cannot auto-fix unowned files)

**c. Post-gate**:
- **Reset counters**: For each spec in wave: `retry_count=0`, `spec_update_count=0`. Other reset triggers (see CLAUDE.md §Auto-Fix Counter Limits): user escalation decision (fix/skip), `/sdd-roadmap revise` start, session resume (dead-code counters are in-memory only).
- Commit: `Wave {N}: {summary}`
- Auto-draft session.md

## Step 8: Roadmap Completion

After all waves complete:
- Report summary: `{wave_count} waves, {spec_count} specs completed`
- Suggest: `/sdd-status`
