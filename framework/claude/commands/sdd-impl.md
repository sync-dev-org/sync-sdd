---
description: Execute spec tasks using TDD methodology
allowed-tools: Bash, Read, Write, Edit, Grep, Glob, AskUserQuestion
argument-hint: <feature-name> [task-numbers]
---

# SDD Implementation (Dispatcher)

<instructions>

## Core Task

Orchestrate TDD implementation for feature **$1** by spawning TaskGenerator and Builder(s) directly.

## Step 1: Phase Gate

1. Read `{{SDD_DIR}}/project/specs/$1/spec.yaml`, verify `design.md` exists
2. **Phase check**: BLOCK if phase is not `design-generated` or `implementation-complete`
   - "Phase is '{phase}'. Run `/sdd-design $1` first."
3. **Blocked check**: BLOCK if phase is `blocked`
   - "$1 is blocked by {blocked_info.blocked_by}."

## Step 2: Task Generation

- If `tasks.yaml` does not exist OR `spec.yaml.orchestration.last_phase_action` != `"tasks-generated"`:
  1. Spawn TaskGenerator with context:
     ```
     Feature: {feature}
     Design: {{SDD_DIR}}/project/specs/{feature}/design.md
     Research: {{SDD_DIR}}/project/specs/{feature}/research.md (if exists)
     ```
  2. Read TaskGenerator's completion report (`TASKGEN_COMPLETE`)
  3. Dismiss TaskGenerator
  4. Verify `tasks.yaml` exists
  5. Update `spec.yaml.orchestration.last_phase_action` = `"tasks-generated"`
- Else: use existing `tasks.yaml` (resume case)

## Step 3: Spawn Builders

1. Read `tasks.yaml` execution section → determine Builder groups
2. Read `tasks.yaml` tasks section → extract detail bullets for assigned tasks
3. If `$2` provided: filter to specified task numbers only
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
   - If `BUILDER_BLOCKED`: re-plan execution (modify tasks.yaml execution) or escalate to user
7. **When dependent tasks are unblocked**: dismiss completed Builder, spawn next-wave Builders immediately
8. **On ALL Builders complete**:
   - Dismiss remaining Builders
   - Aggregate files from all Builder reports
   - Update spec.yaml:
     - Set `phase` = `implementation-complete`
     - Set `implementation.files_created` = `[{aggregated files}]`
     - Set `orchestration.last_phase_action` = `"impl-complete"`
     - Update `changelog`

## Step 4: Post-Completion

1. **Flush Knowledge Buffer** (standalone mode only, not within roadmap run):
   - Read Knowledge Buffer from `{{SDD_DIR}}/handover/buffer.md`
   - If non-empty: write entries to `{{SDD_DIR}}/project/knowledge/` using templates, update index.md
   - Clear processed entries from Knowledge Buffer
2. Auto-draft `{{SDD_DIR}}/handover/session.md`
3. Report to user:
   - Tasks executed and test results
   - Knowledge entries written (if any)
   - Remaining tasks count
   - Next action: `/sdd-review impl {feature}` or continue with more tasks

</instructions>

## Error Handling

- **Missing design.md**: "Run `/sdd-design $1` first."
- **Wrong phase**: "Phase is '{phase}'. Run `/sdd-design $1` first."
- **Blocked**: "$1 is blocked by {blocked_info.blocked_by}."
- **Artifact verification failure**: Do not update spec.yaml — escalate to user
