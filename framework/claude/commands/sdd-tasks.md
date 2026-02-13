---
description: Generate implementation tasks for a specification
allowed-tools: Read, Write, Edit, MultiEdit, Glob, Grep
argument-hint: <feature-name> [-y] [--sequential]
---

# SDD Implementation Tasks Generator

<background_information>
- **Mission**: Generate detailed, actionable implementation tasks that translate technical design into executable work items
- **Success Criteria**:
  - All specifications mapped to specific tasks
  - Tasks properly sized (1-3 hours each)
  - Clear task progression with proper hierarchy
  - Natural language descriptions focused on capabilities
</background_information>

<instructions>
## Core Task
Generate implementation tasks for feature **$1** based on design (specifications and architecture).

## Execution Steps

### Step 1: Load Context

**Read all necessary context**:
- `{{SDD_DIR}}/project/specs/$1/spec.json`, `design.md`
- `{{SDD_DIR}}/project/specs/$1/tasks.md` (if exists, for merge mode)
- **Entire `{{SDD_DIR}}/project/steering/` directory** for complete project memory

**Validate phase**:
- Verify design.md exists (stop if not, see Safety & Fallback)
- Verify `phase` is `design-generated` or later (stop if `initialized`)
- Determine sequential mode based on presence of `--sequential`

**Version consistency check** (skip if `version_refs` not present):
- Read `version` and `version_refs` from spec.json (default: `version ?? "1.0.0"`, `version_refs ?? {}`)
- If `version_refs.tasks` exists and differs from `version_refs.design`:
  - **CONFIRM** (via AskUserQuestion): "Design updated since last task generation (tasks based on v{refs.tasks}, design now at v{refs.design}). Regenerate tasks based on the latest design?"
  - If user declines: Stop execution
  - If user confirms (or `-y` flag): Proceed with regeneration

### Step 2: Generate Implementation Tasks

**Load generation rules and template**:
- Read `{{SDD_DIR}}/settings/rules/tasks-generation.md` for principles
- If `sequential` is **false**: Read `{{SDD_DIR}}/settings/rules/tasks-parallel-analysis.md` for parallel judgement criteria
- Read `{{SDD_DIR}}/settings/templates/specs/tasks.md` for format (supports `(P)` markers)

**Generate task list following all rules**:
- Use language specified in spec.json
- Map all specifications from design.md's Specifications section to tasks
- When documenting spec coverage, list numeric spec IDs only (comma-separated) without descriptive suffixes, parentheses, translations, or free-form labels
- Ensure all design components included
- Verify task progression is logical and incremental
- Collapse single-subtask structures by promoting them to major tasks and avoid duplicating details on container-only major tasks (use template patterns accordingly)
- Apply `(P)` markers to tasks that satisfy parallel criteria (omit markers in sequential mode)
- Mark optional test coverage subtasks with `- [ ]*` only when they strictly cover acceptance criteria already satisfied by core implementation and can be deferred post-MVP
- If existing tasks.md found, merge with new content

### Step 3: Finalize

**Write and update**:
- Create/update `{{SDD_DIR}}/project/specs/$1/tasks.md`
- Update spec.json metadata:
  - Set `phase: "tasks-generated"`
  - Update `updated_at` timestamp
  - **Version tracking** (backward compatible — initialize defaults if fields missing):
    - Set `version_refs.tasks` to the current spec `version`
    - Append changelog entry: `{ "version": "{CURRENT_VER}", "date": "{ISO_DATE}", "phase": "tasks", "summary": "Tasks generated based on design v{version_refs.design}" }`

## Critical Constraints
- **Follow rules strictly**: All principles in tasks-generation.md are mandatory
- **Natural Language**: Describe what to do, not code structure details
- **Complete Coverage**: ALL specifications from design.md must map to tasks
- **Maximum 2 Levels**: Major tasks and sub-tasks only (no deeper nesting)
- **Sequential Numbering**: Major tasks increment (1, 2, 3...), never repeat
- **Task Integration**: Every task must connect to the system (no orphaned work)
</instructions>

## Tool Guidance
- **Read first**: Load all context, rules, and templates before generation
- **Write last**: Generate tasks.md only after complete analysis and verification

## Output Description

Provide brief summary in the language specified in spec.json:

1. **Status**: Confirm tasks generated at `{{SDD_DIR}}/project/specs/$1/tasks.md`
2. **Task Summary**:
   - Total: X major tasks, Y sub-tasks
   - All Z specifications covered
   - Average task size: 1-3 hours per sub-task
3. **Quality Validation**:
   - ✅ All specifications mapped to tasks
   - ✅ Task dependencies verified
   - ✅ Testing tasks included
4. **Next Action**: Review tasks and proceed when ready

**Format**: Concise (under 200 words)

## Safety & Fallback

### Error Scenarios

**Missing Design**:
- **Stop Execution**: Design document must exist
- **User Message**: "Missing design.md at `{{SDD_DIR}}/project/specs/$1/`"
- **Suggested Action**: "Run `/sdd-design $1` or `/sdd-design \"description\"` first"

**Incomplete Spec Coverage**:
- **Warning**: "Not all specifications mapped to tasks. Review coverage."
- **User Action Required**: Confirm intentional gaps or regenerate tasks

**Template/Rules Missing**:
- **User Message**: "Template or rules files missing in `{{SDD_DIR}}/settings/`"
- **Fallback**: Use inline basic structure with warning
- **Suggested Action**: "Check repository setup or restore template files"
- **Missing Numeric Spec IDs**:
  - **Stop Execution**: All specifications in design.md's Specifications section MUST have numeric IDs. If any spec lacks a numeric ID, stop and request that design.md be fixed before generating tasks.

### Next Phase: Implementation

**Before Starting Implementation**:
- **IMPORTANT**: Clear conversation history and free up context before running `/sdd-impl`
- This applies when starting first task OR switching between tasks
- Fresh context ensures clean state and proper task focus

- Execute specific task: `/sdd-impl $1 1.1` (recommended: clear context between each task)
- Execute multiple tasks: `/sdd-impl $1 1.1,1.2` (use cautiously, clear context between tasks)
- Without arguments: `/sdd-impl $1` (executes all pending tasks - NOT recommended due to context bloat)

**If Modifications Needed**:
- Provide feedback and re-run `/sdd-tasks $1`
- Existing tasks used as reference (merge mode)

**Note**: The implementation phase will guide you through executing tasks with appropriate context and validation.

think
