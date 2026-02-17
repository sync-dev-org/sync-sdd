---
description: Execute spec tasks using TDD methodology
allowed-tools: Bash, Read, Write, Edit, Grep, Glob, SendMessage
argument-hint: <feature-name> [task-numbers]
---

# SDD Implementation (Dispatcher)

<instructions>

## Core Task

Orchestrate TDD implementation for feature **$1** via Coordinator → Builder pipeline.

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

## Step 3: Dispatch to Coordinator

Send instruction to Coordinator:

```
実装 feature={feature}
Tasks: {task numbers or "all pending"}
```

Coordinator will:
1. Analyze tasks.md for parallelism and file ownership
2. Request Builder spawns with appropriate file scopes
3. Track progress and manage dependencies

Enter Conductor Message Loop: handle Coordinator's typed messages until PIPELINE_COMPLETE.

## Step 4: Post-Completion

After Coordinator reports all tasks complete:
1. Update `{{SDD_DIR}}/handover/conductor.md` with current state
2. Report to user:
   - Tasks executed and test results
   - Remaining tasks count
   - Next action: `/sdd-review impl {feature}` or continue with more tasks

</instructions>

## Error Handling

- **Missing spec files**: "Complete previous phases: `/sdd-design`, `/sdd-tasks`"
- **Wrong phase**: "Phase is '{phase}'. Run `/sdd-tasks $1` first."
- **Version mismatch**: BLOCK with re-run instruction
