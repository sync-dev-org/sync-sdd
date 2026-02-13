---
description: Execute Wave-based implementation following the roadmap
allowed-tools: Glob, Grep, Read, Write, Edit, AskUserQuestion, Task, Skill, TeamCreate, TaskCreate, TaskUpdate, TaskList, SendMessage, TeamDelete
argument-hint: "[wave-number] [--team]"
---

# Execute Roadmap Implementation

<background_information>
- **Mission**: Execute Wave-based implementation following the existing roadmap
- **Prerequisite**: roadmap.md must exist (use `/sdd-roadmap` to create)
- **Dual Architecture**:
  - **Subagent mode** (default): Sequential spec execution via Task tool subagents
  - **Agent Team mode** (`--team`): Parallel spec execution via Sonnet teammates with file ownership
- **Router's Role**: Orchestrate wave execution, manage teammates (Team mode), report progress
</background_information>

<instructions>

## Mode Detection

```
$ARGUMENTS = ""                → Execute next incomplete wave (Subagent mode)
$ARGUMENTS = "{N}"             → Execute from wave N (Subagent mode)
$ARGUMENTS = "--team"          → Execute next incomplete wave (Agent Team mode)
$ARGUMENTS = "{N} --team"      → Execute from wave N (Agent Team mode)
```

### Agent Team Mode Detection

If `--team` flag is present in arguments:
1. Remove `--team` from arguments before further processing
2. Display: "Agent Team mode — parallel Wave execution"
3. After Steps 1-3 (shared), go to **Agent Team Wave Execution Flow** instead of Step 4

---

## Shared Steps (both modes)

### Execution Flow

### Step 1: Load Roadmap State

1. **Read roadmap.md**:
   - Load `{{KIRO_DIR}}/specs/roadmap.md`
   - Parse Wave structure and dependencies

2. **Scan all specs**:
   - Read all `{{KIRO_DIR}}/specs/*/spec.json`
   - For each spec, check:
     - Current phase
     - tasks.md existence and completion status
     - Implementation status

3. **Build execution state**:
   ```
   Wave 1: [complete/in-progress/pending]
     - spec-a: implementation-complete
     - spec-b: tasks-generated (2/5 tasks done)
   Wave 2: [pending]
     - spec-c: initialized
     - spec-d: initialized
   ```

### Step 2: Determine Resume Point

1. **If wave argument provided**: Start from that wave
2. **Otherwise**: Find first incomplete wave/spec

**Resume point identification**:
- Find first spec where phase != "implementation-complete"
- Within that spec, determine next action:
  - `initialized` → `/sdd-design`
  - `design-generated` → Review design, then `/sdd-tasks`
  - `tasks-generated` → `/sdd-impl`

### Step 3: Present Execution Plan

```
## Execution Plan

**Resume from**: Wave [N], spec [name]
**Current phase**: [phase]
**Tasks status**: [X/Y complete] (if applicable)

### Wave [N] Execution Order
1. [spec-a]: [next action needed]
2. [spec-b]: [next action needed]

### Parallel Execution Opportunities
- [spec-a] and [spec-b] can run in parallel after [dependency]

Proceed with execution?
```

---

## Subagent Execution Flow (default, without --team)

### Step 4: Execute Wave Flow

Follow the 7-step Wave execution flow from roadmap.md:

```
┌─────────────────────────────────────────────────────────────────┐
│                    Wave N Development Flow                       │
├─────────────────────────────────────────────────────────────────┤
│  1. Identify specs in Wave                                      │
│  2. Design existence check                                      │
│  3. Design Review (subagent or --team)                          │
│  4. User Confirmation [REQUIRED]                                │
│  5. Task Generation                                             │
│  6. Implementation (subagent or --team)                         │
│  7. Implementation Review (subagent or --team) & Completion     │
└─────────────────────────────────────────────────────────────────┘
```

#### Step Execution Details

**For each spec in current wave**:

1. **Design Check**:
   ```python
   if not exists(design.md) or phase == "initialized":
       # Use Skill tool
       /sdd-design {spec}
   ```

2. **Design Review** (propagate `--team` if present):
   ```python
   team_flag = " --team" if team_mode else ""
   # Launch via Task tool for context isolation
   for spec in wave_specs:
       Task(f"/sdd-review-design {spec}{team_flag}")
   # Wave-Scoped Cross-Check
   Task(f"/sdd-review-design --wave {N}{team_flag}")
   ```
   - Report ALL results (GO/CONDITIONAL/NO-GO) to user
   - User decides how to proceed for every case

3. **User Confirmation** [REQUIRED]:
   - Present responsibility allocation table
   - Show design review results
   - Ask: "Proceed to task generation?"

4. **Task Generation**:
   ```python
   for spec in wave_specs:
       /sdd-tasks {spec} -y
   ```

5. **Implementation** (subagent parallel):
   ```python
   # Group by dependencies for parallel execution
   for spec in parallel_group:
       Task("/sdd-impl {spec}")
   ```

6. **Implementation Review** (propagate `--team` if present):
   ```python
   team_flag = " --team" if team_mode else ""
   for spec in wave_specs:
       Task(f"/sdd-review-impl {spec}{team_flag}")
   # Wave-Scoped Cross-Check
   Task(f"/sdd-review-impl --wave {N}{team_flag}")
   ```
   - Report ALL results (GO/CONDITIONAL/NO-GO/SPEC-UPDATE-NEEDED) to user
   - User decides how to proceed for every case

6.5. **SPEC Feedback Loop** (if any review returned SPEC-UPDATE-NEEDED):
   ```
   a. Identify affected specs from SPEC_FEEDBACK sections in review results
   b. For each affected spec:
      - Read spec.json version_refs
      - Roll back spec phase to "design-generated" (regardless of SPEC_FEEDBACK phase value)
      - Set version_refs.tasks to null in spec.json (invalidate stale task reference)
   c. Present feedback to user:
      "SPEC feedback detected for: {spec_list}. Specs need updating before proceeding."
   d. User options (via AskUserQuestion):
      - Fix specs now (re-run /sdd-design for affected specs, then cascade downstream)
      - Defer to next wave iteration (record in Wave Completion Report)
      - Override and proceed (with warning about known spec defects)
   e. If specs are fixed:
      - Re-run affected downstream phases (tasks, impl) for the fixed specs
      - Re-run implementation review
   f. If deferred:
      - Record deferred feedback in Wave Completion Report
      - Add to next wave's prerequisites
   ```

7. **Wave Completion Report**:
   ```
   ## Wave [N] Complete

   | Spec | Status | Test Coverage | Issues |
   |------|--------|---------------|--------|
   | spec-a | ✅ Complete | 85% | None |
   | spec-b | ✅ Complete | 82% | 1 warning |

   Proceed to Wave [N+1]?
   ```

### Step 5: Wave Transition

After wave completion:
1. Update spec.json phases
2. Git commit checkpoint (recommend)
3. Ask: "Proceed to next wave?"
4. If yes, repeat from Step 4 with next wave

---

## Agent Team Wave Execution Flow (when --team flag detected)

Skip the Subagent Execution Flow above. After Shared Steps 1-3, use the following flow instead.

### Wave Team Setup

1. **Create team**: `TeamCreate` with team name `sdd-wave-{N}`
2. **Identify specs**: Filter specs in current wave from roadmap

### Teammate Roles

All teammates are flat members of the wave team. No nested teams.

| Role | Agent Type | Responsibility |
|------|-----------|---------------|
| **Lead** | Opus | Dependency management, per-spec user approval, escalation handling. No file writes. |
| **spec-pipeline-{spec}** | Sonnet | Full lifecycle per spec: `/sdd-design` → `/sdd-tasks` → `/sdd-impl`. File-scoped. |
| **review-coordinator** | Sonnet | Persistent review service. Receives review requests, spawns 5 review Task subagents per request, synthesizes verdicts. Retains context across all reviews for wave cross-check. |

Note: review-coordinator uses the Task tool to spawn review subagents (same as current Subagent review mode). This is NOT a nested team — subagents are isolated Tasks, not teammates.

### Step 4T: Spawn Persistent Services

1. **Spawn review-coordinator** (1 teammate, persists for entire wave):
   ```
   "You are a WORKER agent. Do NOT create new teams or spawn teammates.
    You are the review coordinator for wave {N}. You persist for the entire wave.

    When you receive a review request, execute the review:
    - For design review: Follow the Subagent Execution Flow in `.claude/commands/sdd-review-design.md`
      (Phase 1: spawn 5 Task subagents, Phase 2: spawn verifier Task subagent)
    - For impl review: Follow the Subagent Execution Flow in `.claude/commands/sdd-review-impl.md`
      (Phase 1: spawn 5 Task subagents, Phase 2: spawn verifier Task subagent)
    - For wave cross-check: Use --wave {N} mode in the relevant review command

    Send the final CPF verdict to the team lead.
    Retain context from all reviews — you will need it for wave cross-checks."
   ```

### Step 5T: File Ownership Analysis

Lead analyzes file ownership (read-only, no file writes):

1. **Extract file ownership** from each spec's `design.md` Components section
2. **Check for overlaps**: If any file appears in 2+ specs' component lists:
   - Mark those specs as **conflicting** → must be serialized (not parallelized)
   - Report to user: "Specs {X} and {Y} share files: {list}. These will execute sequentially."
3. **Build ownership map** for each spec

### Step 6T: Spawn Spec Pipelines (Pipelined Execution)

Spawn spec-pipeline teammates respecting dependencies AND file ownership conflicts (from Step 5T):

A spec is **independent** only if it has NO roadmap dependencies on pending specs AND NO file conflicts with other specs.
A spec is **dependent** if it has roadmap dependencies OR file conflicts (treat file-conflicting specs as implicitly dependent — serialize them).

1. **Independent specs** — spawn in a SINGLE message (parallel):
   ```
   "You are a WORKER agent. Do NOT create new teams or spawn teammates.
    You own files: {file-list-from-ownership-map}. Do NOT modify files outside this list.

    Execute the full SDD pipeline for spec '{spec}':
    1. Run /sdd-design {spec}
    2. Send to 'review-coordinator': 'Review design for spec {spec} in single mode'
    3. WAIT for message from team lead (design approval or rejection)
    4. If approved: Run /sdd-tasks {spec}
    5. Run /sdd-impl {spec} (follow TDD per .claude/commands/sdd-impl.md)
    6. Send to 'review-coordinator': 'Review impl for spec {spec}, task scope: all'
    7. Send to team lead: 'Spec {spec} implementation complete, review submitted'
    Include in all reports: files modified, tests written, test results"
   ```

2. **Dependent specs** — spawn after dependency completes implementation:
   - Lead tracks which specs are complete
   - When a dependency is satisfied, spawn the dependent spec-pipeline
   - Dependent spec-pipeline prompt is identical but may include: "Note: {dep-spec} is already implemented. Its interfaces are available."

### Step 7T: Pipeline Orchestration (Lead's Main Loop)

Lead processes messages as they arrive. Each spec progresses independently.

**Message: design review verdict from review-coordinator**
```
For the reviewed spec:
- If GO/CONDITIONAL: Present to user (AskUserQuestion): "Approve design for {spec}? {verdict summary}"
  - User approves → SendMessage to spec-pipeline-{spec}: "Design approved. Proceed."
  - User rejects → SendMessage to spec-pipeline-{spec}: "Design rejected. {feedback}"
    Spec-pipeline re-runs /sdd-design with feedback.
- If NO-GO: Present issues to user. User decides: fix or skip spec.
```

**Message: spec implementation complete from spec-pipeline**
```
- Log progress: "{spec} implementation complete, review pending"
- Check dependencies: if any blocked spec now has all deps satisfied → spawn its spec-pipeline
```

**Message: impl review verdict from review-coordinator**
```
- GO/CONDITIONAL: Mark spec complete. Log any warnings.
- NO-GO: Escalate to user. User decides: fix or defer.
- SPEC-UPDATE-NEEDED: Handle via Step 8T.
```

**Trigger: all designs submitted to review-coordinator**
```
- Send to review-coordinator: "Wave design cross-check for wave {N}, specs: {spec-list}"
- When verdict arrives:
  - GO: Log, no action (specs already proceeding — optimistic pipeline)
  - Issues found: Halt affected spec-pipelines that haven't started impl yet.
    For specs already in impl: continue, address at impl review.
    For critical cross-spec conflicts: escalate to user.
```

**Trigger: all specs complete (all impl reviews are GO/CONDITIONAL)**
```
- Send to review-coordinator: "Wave impl cross-check for wave {N}, specs: {spec-list}"
- When verdict arrives: present to user → proceed to Step 9T
```

### Step 8T: SPEC Feedback Loop

If any impl review returned SPEC-UPDATE-NEEDED:

1. **Identify affected specs** from SPEC_FEEDBACK sections
2. **Rollback affected specs**:
   - Roll back spec phase to "design-generated"
   - Set version_refs.tasks to null in spec.json
3. **Present feedback to user** with options (fix now / defer / override)
4. **If user chooses "Fix specs now"**:
   a. Spawn spec-fixer teammates (one per affected spec, parallel if independent):
      ```
      "You are a WORKER agent. Do NOT create new teams or spawn teammates.
       You own files: {file-list}. Do NOT modify files outside this list.
       Fix spec '{spec}':
       1. Run /sdd-design {spec} (apply SPEC_FEEDBACK: {description})
       2. Run /sdd-tasks {spec}
       3. Run /sdd-impl {spec}
       4. Send to 'review-coordinator': 'Review impl for spec {spec}, task scope: all'
       5. Send completion summary to team lead."
      ```
   b. review-coordinator reviews → verdict to Lead (same handling as Step 7T)
   c. Unaffected specs remain at implementation-complete (do NOT re-implement)
5. **If deferred**: record in Wave Completion Report
6. **If override**: log warning, continue to Step 9T

### Step 9T: Wave Completion & Cleanup

1. **Wave Completion Report** (same format as Subagent flow Step 7)
2. **Clean up team**:
   - Send shutdown requests to all remaining teammates (spec-pipelines, review-coordinator)
   - `TeamDelete` to clean up team resources
3. **Update** spec.json phases
4. **Git commit** checkpoint (recommend)
5. **Wave Transition**: Ask "Proceed to next wave?"
   - If yes: Create new team `sdd-wave-{N+1}` and repeat from Step 4T

**IMPORTANT**: Each wave creates and destroys its own team. Do NOT reuse teams across waves (prevents stale context and Compact/Resume issues).

### File Conflict Prevention

- Step 5T extracts file ownership from design.md Components sections before any implementation
- File-conflicting specs are serialized (never parallelized)
- Each spec-pipeline's spawn prompt includes: "You own files: {list}. Do NOT modify files outside this list."
- Lead operates in coordination-only mode: spawning, messaging, task management only — no file writes
- If a spec-pipeline reports needing to modify a file outside its ownership: stop, report to Lead
- **Post-hoc verification**: When a spec-pipeline reports completion, Lead checks `spec.json` `implementation.files_created` against the ownership map. Files outside scope → escalate to user before proceeding to impl review, Lead reassigns or serializes

</instructions>

## Tool Guidance

### Subagent Usage (Task tool) — Subagent mode

**Use Task tool for context isolation**:
- All review commands (`/sdd-review-*`)
- Design generation (`/sdd-design`)
- Implementation (`/sdd-impl`)

**Parallel execution**:
- Launch multiple Task calls in single message for parallel specs
- Example:
  ```
  Task("/sdd-design spec-a")
  Task("/sdd-design spec-b")  # Same message = parallel
  ```

### Agent Team Usage — Team mode

**Team lifecycle per wave**:
- `TeamCreate` at wave start → `TeamDelete` at wave end
- Do NOT reuse teams across waves

**Teammate spawning**:
- Use Task tool with `team_name` and `model: sonnet`
- Always include WORKER preamble: "You are a WORKER agent. Do NOT spawn new teammates or subagents."
- Always include file ownership list in spawn prompt
- Spawn independent teammates in a SINGLE message for parallel execution

**Lead coordination**:
- Lead performs: design checks, task generation, review orchestration, progress reporting
- Lead delegates: implementation (to teammates), review execution (via `--team` flag)
- Lead does NOT edit implementation files directly during teammate execution

**Review commands in Team mode**:
- Reviews use `--team` flag: `/sdd-review-design {spec} --team`, `/sdd-review-impl {spec} --team`
- Each review command creates its own sub-team internally (separate from Wave team)

### Skill Invocation

Use Skill tool for:
- `/sdd-tasks`

### Checkpoints

Recommend git commit after:
- Design review completion
- Each spec implementation completion
- Wave completion

## Error Handling

### Review Results (CONDITIONAL or NO-GO)

1. Stop execution for that spec
2. Report ALL review results to user (never auto-fix)
3. User decides how to proceed:
   - Fix and re-review
   - Skip spec (with warning)
   - Abort wave execution
4. Do NOT automatically fix any issues - user must explicitly instruct fixes

### Implementation Error

1. Log error
2. Continue other parallel specs
3. Report all errors at wave end
4. User decides: fix, skip, or abort

### Dependency Violation

If spec depends on incomplete spec:
1. Report dependency issue
2. Execute dependency first
3. Resume original spec

### Agent Team Errors (Team mode only)

**TeamCreate failure**:
- Fall back to Subagent Execution Flow with warning
- Display: "Agent Team unavailable. Falling back to Subagent mode."

**Teammate failure** (crash or no response):
- Continue with other teammates
- Report failed spec at wave end
- User decides: retry with new teammate, fall back to subagent, or skip

**File ownership violation** (teammate modifies outside its scope):
- Stop that teammate
- Report violation to user
- User decides: revert changes, reassign, or serialize specs

## Output Description

### Progress Indicators

```
## Wave 2 Execution Progress

[████████░░] 80% - Implementing health-checker

Completed:
✅ slack-notifier: implementation-complete

In Progress:
🔄 health-checker: implementing (task 4/5)

Pending:
⏳ (none in this wave)
```

### Completion Summary

```
## Roadmap Execution Summary

| Wave | Status | Specs | Time |
|------|--------|-------|------|
| 1 | ✅ Complete | 1/1 | - |
| 2 | ✅ Complete | 2/2 | - |
| 3 | 🔄 In Progress | 1/2 | - |
| 4 | ⏳ Pending | 0/1 | - |

Next: Continue with Wave 3, spec monitor-scheduler
```
