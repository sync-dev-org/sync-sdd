---
description: Execute spec tasks using TDD methodology
allowed-tools: Bash, Read, Write, Edit, Grep, Glob, AskUserQuestion
argument-hint: <feature-name> [task-numbers]
---

# SDD Implementation (Dispatcher)

<instructions>

## Core Task

Orchestrate TDD implementation by spawning TaskGenerator and Builder(s) directly. Parse `$ARGUMENTS`: first token = `{feature}` (feature name), remaining tokens = `{task-numbers}` (optional task number list).

## Step 1: Phase Gate

1. Read `{{SDD_DIR}}/project/specs/{feature}/spec.yaml`, verify `design.md` exists
2. **Blocked check**: BLOCK if phase is `blocked`
   - "{feature} is blocked by {blocked_info.blocked_by}."
3. **Phase check**:
   - `design-generated`: proceed (standard flow)
   - `implementation-complete`: proceed (re-execution or task-specific re-run)
   - Other: BLOCK — "Phase is '{phase}'. Run `/sdd-design {feature}` first."

## Step 2: Determine Execution Mode

Read `tasks.yaml` status and `spec.yaml.orchestration.last_phase_action`:

**REGENERATE** (generate new tasks):
- Condition: `tasks.yaml` does not exist OR `orchestration.last_phase_action` is null
- Action:
  1. Spawn TaskGenerator with context:
     ```
     Feature: {feature}
     Design: {{SDD_DIR}}/project/specs/{feature}/design.md
     Research: {{SDD_DIR}}/project/specs/{feature}/research.md (if exists)
     Review findings (advisory): {M/L issues from design review, if available}
     ```
  2. Read TaskGenerator's completion report (`TASKGEN_COMPLETE`)
  3. Dismiss TaskGenerator
  4. Verify `tasks.yaml` exists
  5. Update `spec.yaml.orchestration.last_phase_action` = `"tasks-generated"`

**RESUME** (execute existing tasks):
- Condition: `tasks.yaml` exists AND `last_phase_action` == `"tasks-generated"`
- Action: Use existing `tasks.yaml` as-is. Proceed to Step 3.

**TASK RE-EXECUTION** (re-run specific tasks from completed state):
- Condition: `phase` == `implementation-complete` AND `{task-numbers}` provided
- Action: Use existing `tasks.yaml` without regeneration. Filter to specified tasks in Step 3.
- Note: Does NOT regenerate tasks — uses existing task definitions.

**COMPLETED WITHOUT TASK SPEC** (ambiguous re-execution):
- Condition: `phase` == `implementation-complete` AND `{task-numbers}` NOT provided
- Action: Ask user — "Implementation is complete. Options: A) Specify task numbers to re-run, B) Re-edit design first (`/sdd-design {feature}`), C) Abort"

## Step 3: Spawn Builders

1. Read `tasks.yaml` execution section → determine Builder groups
2. Read `tasks.yaml` tasks section → extract detail bullets for assigned tasks
3. If `{task-numbers}` provided: filter to specified task numbers only
4. Build spawn prompt per group:
   ```
   Feature: {feature}
   Tasks: {task IDs + summaries + detail bullets}
   File scope: {files from execution group}
   Design ref: {{SDD_DIR}}/project/specs/{feature}/design.md
   Research ref: {{SDD_DIR}}/project/specs/{feature}/research.md (if exists)
   ```
   For dependent tasks, include: `Depends on: Tasks {numbers} (wait for completion)`
5. Spawn Builder(s) per execution group (parallel where possible)
6. **Builder逐次更新**: As each Builder completes, immediately:
   - Read completion report: tasks completed, files created/modified, test results, knowledge tags, blocker reports
   - Update tasks.yaml: mark completed tasks as `done`
   - Store knowledge tags in `{{SDD_DIR}}/handover/buffer.md` Knowledge Buffer
   - If `BUILDER_BLOCKED`: classify blocker cause from Builder's report:
     - **Missing dependency** (code from another task not yet available): re-order remaining tasks to prioritize the dependency, re-spawn Builder
     - **External blocker** (API unavailable, environment issue): escalate to user with context
     - **Design gap** (task cannot be implemented as designed): escalate to user, suggest `/sdd-design {feature}`
     - Record blocker in `{{SDD_DIR}}/handover/buffer.md` as `[INCIDENT]`
7. **When dependent tasks are unblocked**: dismiss completed Builder, spawn next-wave Builders immediately
8. **On ALL Builders complete**:
   - Dismiss remaining Builders
   - Aggregate files from all Builder reports
   - Update spec.yaml:
     - Set `phase` = `implementation-complete`
     - Set `implementation.files_created` = `[{aggregated files}]`
     - Set `version_refs.implementation` = current `version`
     - Set `orchestration.last_phase_action` = `"impl-complete"`
     - Update `changelog`

## Step 4: Post-Completion

1. **Flush Knowledge Buffer** (standalone mode only, not within roadmap run):
   - Read Knowledge Buffer from `{{SDD_DIR}}/handover/buffer.md`
   - If non-empty: write entries to `{{SDD_DIR}}/project/knowledge/` using templates
   - Clear processed entries from Knowledge Buffer
2. Auto-draft `{{SDD_DIR}}/handover/session.md`
3. Report to user:
   - Tasks executed and test results
   - Knowledge entries written (if any)
   - Remaining tasks count
   - Next action: `/sdd-review impl {feature}` or continue with more tasks

</instructions>

## Error Handling

- **Missing design.md**: "Run `/sdd-design {feature}` first."
- **Wrong phase**: "Phase is '{phase}'. Run `/sdd-design {feature}` first."
- **Blocked**: "{feature} is blocked by {blocked_info.blocked_by}."
- **Artifact verification failure**: Do not update spec.yaml — escalate to user
