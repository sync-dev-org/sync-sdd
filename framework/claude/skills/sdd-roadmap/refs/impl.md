# Impl Subcommand

Phase execution reference. Assumes Single-Spec Roadmap Ensure already completed by router.

Triggered by: `$ARGUMENTS = "impl {feature} [task-numbers]"`

## Step 1: Phase Gate

1. Read `{{SDD_DIR}}/project/specs/{feature}/spec.yaml`, verify `design.md` exists
2. BLOCK if phase is `blocked`: "{feature} is blocked by {blocked_info.blocked_by}."
3. Phase check:
   - `design-generated`: proceed (standard flow)
   - `implementation-complete`: proceed (re-execution or task-specific re-run)
   - Other: BLOCK — "Phase is '{phase}'. Run `/sdd-roadmap design {feature}` first."

## Step 2: Determine Execution Mode

Read `tasks.yaml` status and `spec.yaml.orchestration.last_phase_action`:

- **REGENERATE**: `tasks.yaml` does not exist OR `orchestration.last_phase_action` is null → Spawn TaskGenerator (see below). After TaskGenerator completes: set `orchestration.last_phase_action = "tasks-generated"`
- **RESUME**: `tasks.yaml` exists AND `last_phase_action` == `"tasks-generated"` → Use existing tasks.yaml
- **TASK RE-EXECUTION**: `phase` == `implementation-complete` AND `{task-numbers}` provided → Use existing tasks.yaml, filter to specified tasks
- **COMPLETED WITHOUT TASK SPEC**: `phase` == `implementation-complete` AND no task-numbers → Ask user: "A) Specify task numbers to re-run, B) Re-design first (`/sdd-roadmap design {feature}`), C) Abort"

**TaskGenerator dispatch** (REGENERATE mode):
Spawn TaskGenerator via `Task(subagent_type="sdd-taskgenerator")` with prompt:
- Feature: {feature}
- Design: `{{SDD_DIR}}/project/specs/{feature}/design.md`
- Research: `{{SDD_DIR}}/project/specs/{feature}/research.md` (if exists)
- Review findings: from `specs/{feature}/verdicts.md` latest design batch Tracked (if exists)

Read TaskGenerator's completion report. Verify `tasks.yaml` exists.

## Step 3: Execute

Read `tasks.yaml` execution plan → determine Builder grouping.
Read tasks.yaml tasks section → extract detail bullets for Builder spawn prompts.

Spawn Builder(s) via `Task(subagent_type="sdd-builder")` with prompt for each work package:
- Feature: {feature}
- Tasks: {task IDs + summaries + detail bullets}
- File scope: {assigned files}
- Design ref: `{{SDD_DIR}}/project/specs/{feature}/design.md`
- Research ref: `{{SDD_DIR}}/project/specs/{feature}/research.md` (if exists)

If `{task-numbers}` provided: filter to specified task numbers only.

**Builder incremental processing**: As each Builder completes, immediately:
- Read completion report (from Task result: files, test results, knowledge tags, blockers)
- Update tasks.yaml: mark completed tasks as `done`
- Store knowledge tags in `{{SDD_DIR}}/handover/buffer.md`
- If BUILDER_BLOCKED: classify cause (missing dependency → reorder tasks, re-dispatch; external blocker → escalate to user; design gap → escalate, suggest re-design). Record as `[INCIDENT]` in buffer.md

When dependent tasks are unblocked: spawn next-wave Builders immediately.

After ALL Builders complete, update spec.yaml:
- Set `phase` = `implementation-complete`
- Update `implementation.files_created`: For TASK RE-EXECUTION mode, merge new files into existing list (union). For full execution, set to `[{aggregated files}]`
- Set `version_refs.implementation` = current `version`
- Set `orchestration.last_phase_action` = `"impl-complete"`
- Update `changelog`

## Step 4: Post-Completion

1. Flush Knowledge Buffer to `{{SDD_DIR}}/project/knowledge/` (aggregate, deduplicate, write using templates, clear buffer.md)
2. Auto-draft `{{SDD_DIR}}/handover/session.md`
3. Report to user: tasks executed, test results, next: `/sdd-roadmap review impl {feature}`
