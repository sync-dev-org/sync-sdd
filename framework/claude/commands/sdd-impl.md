---
description: Execute spec tasks using TDD methodology
allowed-tools: Bash, Read, Write, Edit, Grep, Glob, AskUserQuestion
argument-hint: <feature-name> [task-numbers]
---

# SDD Implementation (Dispatcher)

<instructions>

## Core Task

Orchestrate TDD implementation for feature **$1** by spawning Builder(s) directly.

## Step 1: Phase Gate

1. Read `{{SDD_DIR}}/project/specs/$1/spec.json`, verify `design.md` and `tasks.md` exist
2. **Phase check**: BLOCK if phase is not `tasks-generated` or `implementation-complete`
   - "Phase is '{phase}'. Run `/sdd-tasks $1` first."

### Version Consistency Check

If `version_refs` present:
- If `version_refs.design` != `version_refs.tasks`:
  - BLOCK: "Tasks based on design v{task_ref} but design is now v{design_ref}. Re-run `/sdd-tasks $1`."

## Step 2: Determine Task Scope

- If `$2` provided: Execute specified task numbers (e.g., "1.1" or "1,2,3")
- Otherwise: Execute all pending tasks (unchecked `- [ ]` in tasks.md)

## Step 3: Analyze and Spawn Builders

1. Read `tasks.md`, `design.md`, and `research.md` (if exists) for the feature
2. **Analyze parallelism**:
   - Read `(P)` markers and dependency chains from tasks.md → determine which tasks can run in parallel
   - Read Components section from design.md → determine file ownership per Builder
   - Group tasks into Builder work packages (**no file overlap** between Builders)
3. **Spawn Builder(s)** with context for each work package:
   ```
   Feature: {feature}
   Tasks: {task numbers}
   File scope: {assigned files}
   Design ref: {{SDD_DIR}}/project/specs/{feature}/design.md
   Research ref: {{SDD_DIR}}/project/specs/{feature}/research.md (if exists)
   ```
   For dependent tasks, include: `Depends on: Tasks {numbers} (wait for completion)`
4. **Read each Builder's completion report**. Collect:
   - Tasks completed
   - Files created/modified
   - Test results
   - Knowledge tags (`[PATTERN]`/`[INCIDENT]`/`[REFERENCE]`)
   - Blocker reports (`BUILDER_BLOCKED`)
5. **Handle BUILDER_BLOCKED**: analyze blocker cause, re-plan file ownership or escalate to user
6. **When dependent tasks are unblocked**: dismiss completed Builders, spawn next wave of Builders
7. **On all tasks complete**:
   - Dismiss all Builders
   - Aggregate `Files` from all Builder reports
   - Store knowledge tags in `{{SDD_DIR}}/handover/state.md` Knowledge Buffer
   - Update spec.json:
     - Set `phase` = `implementation-complete`
     - Set `implementation.files_created` = `[{aggregated files}]`
     - Update `changelog`

## Step 4: Post-Completion

1. **Flush Knowledge Buffer** (standalone mode only, not within roadmap run):
   - Read Knowledge Buffer from `{{SDD_DIR}}/handover/state.md`
   - If non-empty: write entries to `{{SDD_DIR}}/project/knowledge/` using templates, update index.md
   - Clear processed entries from Knowledge Buffer
2. Update `{{SDD_DIR}}/handover/state.md` with current state
3. Report to user:
   - Tasks executed and test results
   - Knowledge entries written (if any)
   - Remaining tasks count
   - Next action: `/sdd-review impl {feature}` or continue with more tasks

</instructions>

## Error Handling

- **Missing spec files**: "Complete previous phases: `/sdd-design`, `/sdd-tasks`"
- **Wrong phase**: "Phase is '{phase}'. Run `/sdd-tasks $1` first."
- **Version mismatch**: BLOCK with re-run instruction
