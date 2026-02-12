---
description: Execute spec tasks using TDD methodology
allowed-tools: Bash, Read, Write, Edit, MultiEdit, Grep, Glob, LS, WebFetch, WebSearch
argument-hint: <feature-name> [task-numbers]
---

# SDD Implementation Task Executor

<background_information>
- **Mission**: Execute implementation tasks using Test-Driven Development methodology based on approved specifications
- **Success Criteria**:
  - All tests written before implementation code
  - Code passes all tests with no regressions
  - Tasks marked as completed in tasks.md
  - Implementation aligns with design and requirements
</background_information>

<instructions>
## Core Task
Execute implementation tasks for feature **$1** using Test-Driven Development.

## Execution Steps

### Step 1: Load Context

**Read all necessary context**:
- `{{KIRO_DIR}}/specs/$1/spec.json`, `requirements.md`, `design.md`, `tasks.md`
- **Entire `{{KIRO_DIR}}/steering/` directory** for complete project memory

**Validate approvals**:
- Verify tasks are approved in spec.json (stop if not, see Safety & Fallback)

**Version consistency check** (backward compatible — skip if `version_refs` not present in spec.json):
- Read `version_refs` from spec.json
- If `version_refs` exists:
  - If `version_refs.requirements` != `version_refs.design`:
    - **BLOCK**: "Design is based on requirements v{design_ref} but requirements are now v{req_ref}. Re-run `/sdd-design $1` to update design before implementation."
  - If `version_refs.design` != `version_refs.tasks`:
    - **BLOCK**: "Tasks are based on design v{task_ref} but design is now v{design_ref}. Re-run `/sdd-tasks $1` to update tasks before implementation."
- If `version_refs` is absent: Skip check (backward compatible with pre-versioning specs)

### Step 2: Select Tasks

**Determine which tasks to execute**:
- If `$2` provided: Execute specified task numbers (e.g., "1.1" or "1,2,3")
- Otherwise: Execute all pending tasks (unchecked `- [ ]` in tasks.md)

### Step 3: Execute with TDD

For each selected task, follow Kent Beck's TDD cycle:

1. **RED - Write Failing Test**:
   - Write test for the next small piece of functionality
   - Test should fail (code doesn't exist yet)
   - Use descriptive test names
   - **Add traceability marker**: Include `AC: {feature}.R{N}.AC{M}` in the test docstring or comment, where R{N} is the Requirement number and AC{M} is the Acceptance Criteria number
     - Python: `def test_login_redirects(): """AC: auth-flow.R1.AC1"""`
     - TypeScript: `it('redirects to login', () => { // AC: auth-flow.R1.AC1`
     - One test may reference multiple ACs if it covers a combined scenario

2. **GREEN - Write Minimal Code**:
   - Implement simplest solution to make test pass
   - Focus only on making THIS test pass
   - Avoid over-engineering

3. **REFACTOR - Clean Up**:
   - Improve code structure and readability
   - Remove duplication
   - Apply design patterns where appropriate
   - Ensure all tests still pass after refactoring

4. **VERIFY - Validate Quality**:
   - All tests pass (new and existing)
   - No regressions in existing functionality
   - Code coverage maintained or improved

5. **MARK COMPLETE**:
   - Update checkbox from `- [ ]` to `- [x]` in tasks.md
   - **AC coverage validation**: Verify that all ACs referenced by this task (from `_Requirements:_` and `_ACs:_` annotations in tasks.md) have at least one test with a matching `AC: {feature}.R{N}.AC{M}` marker

### Step 4: Update Completion Status

After all selected tasks are executed:
- Check if ALL tasks in tasks.md are now marked `[x]` (completed)
- If all tasks complete:
  - Set spec.json `phase: "implementation-complete"`
  - Update `updated_at` timestamp

## Critical Constraints
- **TDD Mandatory**: Tests MUST be written before implementation code
- **Task Scope**: Implement only what the specific task requires
- **Test Coverage**: All new code must have tests
- **No Regressions**: Existing tests must continue to pass
- **Design Alignment**: Implementation must follow design.md specifications
</instructions>

## Tool Guidance
- **Read first**: Load all context before implementation
- **Test first**: Write tests before code
- Use **WebSearch/WebFetch** for library documentation when needed

## Output Description

Provide brief summary in the language specified in spec.json:

1. **Tasks Executed**: Task numbers and test results
2. **Status**: Completed tasks marked in tasks.md, remaining tasks count

**Format**: Concise (under 150 words)

## Safety & Fallback

### Error Scenarios

**Tasks Not Approved or Missing Spec Files**:
- **Stop Execution**: All spec files must exist and tasks must be approved
- **Suggested Action**: "Complete previous phases: `/sdd-requirements`, `/sdd-design`, `/sdd-tasks`"

**Test Failures**:
- **Stop Implementation**: Fix failing tests before continuing
- **Action**: Debug and fix, then re-run

### Task Execution

**Execute specific task(s)**:
- `/sdd-impl $1 1.1` - Single task
- `/sdd-impl $1 1,2,3` - Multiple tasks

**Execute all pending**:
- `/sdd-impl $1` - All unchecked tasks

think
