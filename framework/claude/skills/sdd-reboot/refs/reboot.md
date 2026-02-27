# Reboot Execution Logic

Detailed execution reference. Lead handles all phases directly.

---

## Phase 1: Pre-Flight

1. **Working tree clean**: `git status --porcelain` — if output non-empty, BLOCK: "Uncommitted changes detected. Commit or stash before running `/sdd-reboot`."
2. **Main branch**: `git branch --show-current` — if not `main`, BLOCK: "Switch to main branch first: `git checkout main`"
3. **Existing reboot branch**: `git branch --list 'reboot/*'` — if found:
   - Present options: **Resume** (checkout existing branch, skip to appropriate phase), **Delete & restart** (delete branch, proceed), **Abort**
   - Record `USER_DECISION` in decisions.md
4. **Codebase check**: Glob for source files (exclude `.sdd/`, `.claude/`, `node_modules/`, `.git/`). If no source files found, BLOCK: "No source code found. Nothing to reboot."
5. **Input state detection**:

   | Check | Result |
   |-------|--------|
   | `{{SDD_DIR}}/project/steering/` exists with ≥1 file | `has_steering = true` |
   | `{{SDD_DIR}}/project/specs/` exists with ≥1 spec directory | `has_specs = true` |

   Derive input state:
   - `has_steering AND has_specs` → `full-reboot`
   - `NOT has_steering AND NOT has_specs` → `code-only`
   - Otherwise → `partial`

## Phase 2: Branch Setup

1. Determine branch name:
   - If `$ARGUMENTS` contains a name (not `-y`): `reboot/{name}`
   - Otherwise: `reboot/{YYYY-MM-DD}` (today's date)
2. Create and checkout: `git checkout -b reboot/{branch_name}`
3. Append `DIRECTION_CHANGE` to decisions.md: "Reboot started: zero-based redesign on branch reboot/{branch_name} (input state: {state})"

## Phase 3: Conventions Brief

Dispatch `sdd-conventions-scanner` to scan the codebase for existing patterns.

1. Create output directory: `mkdir -p {{SDD_DIR}}/project/reboot/`
2. Dispatch via `Task(subagent_type="sdd-conventions-scanner", run_in_background=true)` with prompt:
   - Mode: Generate
   - Steering: `{{SDD_DIR}}/project/steering/` (if exists)
   - Buffer: `{{SDD_DIR}}/handover/buffer.md` (if exists)
   - Template: `{{SDD_DIR}}/settings/templates/wave-context/conventions-brief.md`
   - Output: `{{SDD_DIR}}/project/reboot/conventions-brief.md`
   - Identifier: `reboot`
3. Wait for `WRITTEN:{path}` via `TaskOutput`

## Phase 4: Deep Analysis

Dispatch `sdd-analyst` for holistic codebase analysis and redesign proposal.

1. Dispatch via `Task(subagent_type="sdd-analyst", run_in_background=true)` with prompt:
   - Steering path: `{{SDD_DIR}}/project/steering/` (note if absent)
   - Conventions brief path: `{{SDD_DIR}}/project/reboot/conventions-brief.md`
   - User instructions: from `$ARGUMENTS` (excluding name and `-y` flag), or empty
   - Output path: `{{SDD_DIR}}/project/reboot/analysis-report.md`
   - Template path: `{{SDD_DIR}}/settings/templates/reboot/analysis-report.md`
   - Input state: `{full-reboot|code-only|partial}`
   - **DO NOT pass specs path** — Analyst must not read existing specs
2. Wait for `ANALYST_COMPLETE` via `TaskOutput`
3. Verify: `analysis-report.md` exists at output path. If missing, retry once with same prompt. On second failure: `git checkout main && git branch -D reboot/{branch_name}`, report error to user, stop.

## Phase 5: User Review Checkpoint

Skip if `-y` flag is present.

1. Read `{{SDD_DIR}}/project/reboot/analysis-report.md`
2. Present to user:
   - Executive summary
   - Steering changes/generation summary
   - Proposed spec count and wave count
   - Risk assessment highlights
3. Ask user via `AskUserQuestion`:
   - **Approve**: Proceed to Phase 6
   - **Modify**: Collect user feedback. Re-dispatch Analyst with additional instructions appended to original prompt + user feedback. Max 2 modification rounds. After 2 rounds, present final version — user must Approve or Abort.
   - **Abort**: `git checkout main && git branch -D reboot/{branch_name}`. Record `USER_DECISION` in decisions.md. Stop.
4. Record `USER_DECISION` in decisions.md

## Phase 6: Roadmap Regeneration

### 6a. Archive Old Specs (if `has_specs`)

1. `mkdir -p {{SDD_DIR}}/project/reboot/old-specs/`
2. For each directory in `{{SDD_DIR}}/project/specs/` (including dot-prefixed like `.wave-context/`, `.cross-cutting/`):
   - `cp -r {{SDD_DIR}}/project/specs/{feature}/ {{SDD_DIR}}/project/reboot/old-specs/{feature}/`
3. If `roadmap.md` exists: `cp {{SDD_DIR}}/project/specs/roadmap.md {{SDD_DIR}}/project/reboot/old-specs/roadmap.md`

### 6b. Delete Old Specs

1. Remove all spec directories under `{{SDD_DIR}}/project/specs/` (including dot-prefixed meta-dirs and `roadmap.md`)
2. Remove `{{SDD_DIR}}/project/reviews/` if exists (wave-level review artifacts)

Code-Only: skip 6a and 6b (nothing to archive or delete).

### 6c. Create New Specs

Read the analysis report to extract proposed spec decomposition.

For each proposed spec from the report:
1. Create directory: `mkdir -p {{SDD_DIR}}/project/specs/{spec-name}/`
2. Initialize `spec.yaml` from `{{SDD_DIR}}/settings/templates/specs/init.yaml`:
   - Set `feature_name` to spec name
   - Set `created_at` and `updated_at` to current timestamp
   - Set `phase` to `initialized`
   - Set `roadmap` to `{wave: N, dependencies: ["dep-name", ...]}`
3. Create skeleton `design.md`:
   - Use `{{SDD_DIR}}/settings/templates/specs/design.md` as base
   - Seed the Introduction section with the Analyst's description for this spec
   - Add a note: `<!-- Seeded by sdd-reboot Analyst. Architect will expand and refine. -->`

### 6d. Generate Roadmap

1. Write `{{SDD_DIR}}/project/specs/roadmap.md` with:
   - Wave Overview (from Analyst's wave structure)
   - Dependencies (from Analyst's dependency graph)
   - Execution Flow (wave-by-wave description)
   - Parallelism Report (from Analyst's parallelism report)
2. Update `{{SDD_DIR}}/project/steering/product.md` Spec Rationale section (Analyst may have already updated this — verify and supplement if needed)

## Phase 7: Design Pipeline (Design-Only Mode)

Reuse the design dispatch loop from `refs/run.md` Step 4, but **skip all implementation phases**. Only Design and Design Review are executed.

**Auto-draft policy**: Auto-draft session.md only at wave completion (all specs in wave design-reviewed) and pipeline completion. Skip at individual spec phase completions (same as run.md dispatch loop policy).

### Modified Readiness Rules

| Next Phase | Conditions |
|-----------|------------|
| **Design** | Phase is `initialized`. Intra-wave dependencies (if any) have reached `design-generated`. |
| **Design Review** | Phase is `design-generated`. No GO/CONDITIONAL verdict in `verdicts.md` latest design batch (verdict absent or last is NO-GO). |

Implementation and Impl Review readiness rules are NOT evaluated.

### Dispatch Loop

```
For each wave (sequential):

  Initialize:
    ready_specs = wave-bound specs at their current phase
    active = {}
    review_state = {}

  Loop:
    1. ADVANCE: For each spec in wave (not active, not blocked):
       - Determine next phase based on Modified Readiness Rules
       - If Design ready: dispatch Architect
       - If Design Review ready: dispatch Inspectors (Review Decomposition)

    2. LOOKAHEAD: Check next-wave Design eligibility
       (same as run.md: if all deps reached design-generated, dispatch Architect)

    3. WAIT: Poll active tasks via TaskOutput

    4. PROCESS: Handle completion
       - Inspector/Auditor: advance per Review Decomposition
       - Design complete: update spec.yaml (phase=design-generated, version_refs)
       - Design Review verdict: handle per §Verdict Handling

    5. EXIT: If all specs in wave have design-generated + GO/CONDITIONAL verdict
       and active is empty → next wave (or Phase 8)
```

### Architect Dispatch

When dispatching Architects, include extra context for the reboot:
- Standard context: feature name, mode=new, steering path, conventions brief path
- **Additional**: analysis-report.md path — Architect reads this for the redesign vision and proposed scope

### Review Decomposition

Same protocol as `refs/run.md` §Review Decomposition:
1. **DISPATCH-INSPECTORS**: Spawn 6 design Inspectors in parallel (rulebase, testability, architecture, consistency, best-practices, holistic)
2. **INSPECTORS-COMPLETE**: Spawn Auditor (sdd-auditor-design)
3. **AUDITOR-COMPLETE**: Read verdict, persist to verdicts.md, archive

### Verdict Handling

- **GO/CONDITIONAL** → Spec design complete. Proceed to next spec or next wave.
- **NO-GO** → increment `retry_count`. Dispatch Architect with fix instructions from verdict. After fix: re-run Design Review. Max 5 retries (aggregate cap 6). On exhaustion: escalate to user per `refs/run.md` Step 6 Blocking Protocol (fix/skip/abort). Skip → exclude spec from wave EXIT condition; remaining specs must still meet completion condition.
- Process `STEERING:` entries from verdict.

### Shared Research

If 2+ Architects dispatch in parallel (Design Fan-Out):
1. Extract common technology decisions from steering
2. Identify shared dependencies across wave specs
3. Write to `{{SDD_DIR}}/project/specs/.wave-context/{wave-N}/shared-research.md`

### Completion Condition

All specs have `phase = design-generated` AND a GO/CONDITIONAL design review verdict in `verdicts.md`.

## Phase 8: Regression Check

**Skip if**: no old specs were archived (Code-Only mode — `{{SDD_DIR}}/project/reboot/old-specs/` doesn't exist).

Lead performs this directly (no SubAgent needed).

1. **Extract old capabilities**: For each `{{SDD_DIR}}/project/reboot/old-specs/*/design.md`:
   - Read the Specifications section
   - Extract each spec heading + goal + acceptance criteria
   - Build a list: `[{spec_id, goal, acs, source_feature}]`

2. **Extract new capabilities**: For each `{{SDD_DIR}}/project/specs/*/design.md`:
   - Read the Specifications section
   - Extract each spec heading + goal + acceptance criteria
   - Build a list: `[{spec_id, goal, acs, target_feature}]`

3. **Compare**: For each old capability:
   - Search new capabilities for semantic match (same goal or same acceptance criteria)
   - Status: `COVERED` (found a match) or `AT-RISK` (no clear match)

4. **Write**: `{{SDD_DIR}}/project/reboot/regression-check.md`

   ```
   # Regression Check

   Old specs: {count} features, {count} capabilities
   New specs: {count} features, {count} capabilities

   ## COVERED ({count})
   | Old Capability | Old Feature | New Feature | Notes |
   |---------------|-------------|-------------|-------|

   ## AT-RISK ({count})
   | Old Capability | Old Feature | Notes |
   |---------------|-------------|-------|
   ```

## Phase 9: Final Report

Lead generates the comprehensive final report.

1. Read analysis report, all new spec design.md files, regression check (if exists), all design review verdicts
2. Write `{{SDD_DIR}}/project/reboot/final-report.md`:

   ```markdown
   # Reboot Final Report

   ## Summary
   - Input state: {full-reboot|code-only|partial}
   - New specs: {count} across {wave_count} waves
   - Steering: {created|updated} ({file_list})
   - Design review: {passed_count}/{total_count} GO/CONDITIONAL

   ## Steering Changes
   {Per-file summary of what changed and why}

   ## New Design Overview
   | Spec | Wave | Description | Review Verdict |
   |------|------|-------------|---------------|

   ## Wave Structure
   {Parallelism report}

   ## Regression Check
   {AT-RISK items if any, or "No regression check (Code-Only mode)"}

   ## Design Quality
   {CONDITIONAL items that need attention}

   ## Next Steps
   - Accept: merge this branch to main, then run `/sdd-roadmap run` to implement
   - Reject: `git checkout main && git branch -D reboot/{branch_name}`
   - Iterate: continue editing designs on this branch
   ```

3. Present report content to user
4. **DO NOT merge. DO NOT checkout main. Skill terminates here.**

## Phase 10: Post-Completion

1. Stage and commit all changes on reboot branch: `reboot: {1-line summary of redesign}`
2. Auto-draft `{{SDD_DIR}}/handover/session.md`
3. Append `DIRECTION_CHANGE` to decisions.md: "Reboot complete: {spec_count} specs across {wave_count} waves on branch reboot/{branch_name}"
