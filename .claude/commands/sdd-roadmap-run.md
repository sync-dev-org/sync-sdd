---
description: Execute Wave-based implementation following the roadmap
allowed-tools: Glob, Grep, Read, Write, Edit, AskUserQuestion, Task, Skill
argument-hint: "[wave-number]"
---

# Execute Roadmap Implementation

<background_information>
- **Mission**: Execute Wave-based implementation following the existing roadmap
- **Prerequisite**: roadmap.md must exist (use `/sdd-roadmap` to create)
</background_information>

<instructions>

## Execution Flow

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

### Step 4: Execute Wave Flow

Follow the 7-step Wave execution flow from roadmap.md:

```
┌─────────────────────────────────────────────────────────────────┐
│                    Wave N Development Flow                       │
├─────────────────────────────────────────────────────────────────┤
│  1. Identify specs in Wave                                      │
│  2. Design existence check                                      │
│  3. Design Review (subagent parallel)                           │
│  4. User Confirmation [REQUIRED]                                │
│  5. Task Generation                                             │
│  6. Implementation (subagent parallel)                          │
│  7. Implementation Review & Completion Report                   │
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

2. **Design Review** (subagent parallel):
   ```python
   # Launch via Task tool for context isolation
   for spec in wave_specs:
       Task("/sdd-review-design {spec}")
   # Wave-Scoped Cross-Check
   Task("/sdd-review-design --wave {N}")
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

6. **Implementation Review** (subagent parallel):
   ```python
   for spec in wave_specs:
       Task("/sdd-review-impl {spec}")
   # Wave-Scoped Cross-Check
   Task("/sdd-review-impl --wave {N}")
   ```
   - Report ALL results (GO/CONDITIONAL/NO-GO/SPEC-UPDATE-NEEDED) to user
   - User decides how to proceed for every case

6.5. **SPEC Feedback Loop** (if any review returned SPEC-UPDATE-NEEDED):
   ```
   a. Identify affected specs from SPEC_FEEDBACK sections in review results
   b. For each affected spec:
      - Read spec.json version_refs
      - If phase=design: Roll back spec phase to "design-generated"
      - Mark version_refs as stale (downstream refs outdated)
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

</instructions>

## Tool Guidance

### Subagent Usage (Task tool)

**Use Task tool for context isolation**:
- All review commands (`/sdd-review-*`)
- Design generation (`/sdd-design`)
- Implementation (`/sdd-impl`)

**Parallel execution**:
- Launch multiple Task calls in single message for parallel specs
- Example:
  ```
  Task("/sdd-design spec-a -y")
  Task("/sdd-design spec-b -y")  # Same message = parallel
  ```

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
