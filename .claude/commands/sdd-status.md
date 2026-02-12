---
description: Show specification status and progress
allowed-tools: Bash, Read, Glob, Write, Edit, MultiEdit, Update
argument-hint: <feature-name>
---

# SDD Specification Status

<background_information>
- **Mission**: Display comprehensive status and progress for specifications
- **Success Criteria**:
  - Show overall roadmap progress (Wave-level) when no argument or when roadmap.md exists
  - Show current phase and completion status for individual specs
  - Identify next actions and blockers
  - Provide clear visibility into progress
</background_information>

<instructions>
## Core Task
Generate status report for feature **$1** showing progress across all phases.

## Execution Steps

### Step 0: Load Roadmap and Calculate Progress (if roadmap.md exists)

1. **Read roadmap.md** for Wave structure:
   - `{{KIRO_DIR}}/specs/roadmap.md`
   - Extract: Wave names, spec assignments, dependencies

2. **Read ALL spec.json files** for current phase:
   - Glob `{{KIRO_DIR}}/specs/*/spec.json`
   - Extract `phase` field from each

3. **Calculate Wave progress dynamically**:
   - For each Wave, count specs by phase and approval status:
     - `implementation-complete` → complete
     - `tasks-generated` with `approvals.tasks.approved: true` → ready for implementation
     - `design-generated` with `approvals.design.approved: true` → design approved, ready for tasks
     - `requirements-generated` with `approvals.requirements.approved: true` → requirements approved, ready for design
     - `requirements-generated` or `requirements-pending` → in progress
     - Other → not started
   - Determine blocked waves (all dependencies not complete)

4. **Identify next actionable specs**:
   - Specs whose dependencies are all complete
   - Not yet implemented

### Step 1: Load Spec Context
- If **no argument** ($1 is empty): Skip to Step 3 for overall roadmap status only
- If **argument provided**: Read `{{KIRO_DIR}}/specs/$1/spec.json` for metadata and phase status
- Read existing files: `requirements.md`, `design.md`, `tasks.md` (if they exist)
- Check `{{KIRO_DIR}}/specs/$1/` directory for available files

### Step 2: Analyze Status

**Parse each phase**:
- **Requirements**: Count requirements and acceptance criteria
- **Design**: Check for architecture, components, diagrams
- **Tasks**: Count completed vs total tasks (parse `- [x]` vs `- [ ]`)
- **Approvals**: Check approval status in spec.json

**Version analysis** (backward compatible — skip if `version` field not present):
- Read `version`, `changelog`, `version_refs` from spec.json
- Determine version_refs alignment:
  - If `version_refs.design` < `version_refs.requirements` → design is stale
  - If `version_refs.tasks` < `version_refs.design` → tasks are stale

### Step 3: Generate Report

**If roadmap.md exists, show Overall Progress first**:
```
## Overall Roadmap Progress

Wave 1 (Foundation): ████████░░ 2/2 specs complete
Wave 2 (Core):       ██░░░░░░░░ 1/4 specs complete
Wave 3 (Integration): ░░░░░░░░░░ blocked by Wave 2
Wave 4 (Interface):   ░░░░░░░░░░ blocked by Wave 3

Next actionable specs: feature-a, feature-b (Wave 2)
```

**Then, if specific spec requested ($1 provided)**:

Create report in the language specified in spec.json covering:
1. **Current Phase & Progress**: Where the spec is in the workflow
2. **Completion Status**: Percentage complete for each phase
3. **Task Breakdown**: If tasks exist, show completed/remaining counts
4. **Next Actions**: What needs to be done next
5. **Blockers**: Any issues preventing progress
6. **Wave Context**: Which wave this spec belongs to, dependencies status

## Critical Constraints
- Use language from spec.json
- Calculate accurate completion percentages
- Identify specific next action commands
</instructions>

## Tool Guidance
- **Read**: Load spec.json first, then other spec files as needed
- **Parse carefully**: Extract completion data from tasks.md checkboxes
- Use **Glob** to check which spec files exist

## Output Description

Provide status report in the language specified in spec.json:

**Report Structure**:

**Part 1: Overall Roadmap** (if roadmap.md exists):
- Wave-by-wave progress bars
- Blocked waves indication
- Next actionable specs

**Part 2: Individual Spec** (if $1 provided):
1. **Feature Overview**: Name, phase, last updated, wave assignment
2. **Version Info** (if `version` field exists):
   - Current version: v{version}
   - Requirements ref: v{version_refs.requirements}
   - Design ref: v{version_refs.design} {STALE indicator if < requirements ref}
   - Tasks ref: v{version_refs.tasks} {STALE indicator if < design ref}
   - Recent changes (last 3 changelog entries)
3. **Phase Status**: Requirements, Design, Tasks with completion %
4. **Task Progress**: If tasks exist, show X/Y completed
5. **Next Action**: Specific command to run next
6. **Issues**: Any blockers or missing elements (including version staleness warnings)
7. **Dependencies**: Status of specs this one depends on

**Format**: Clear, scannable format with emojis (✅/⏳/❌) for status and progress bars (████░░) for waves

## Safety & Fallback

### Error Scenarios

**Spec Not Found**:
- **Message**: "No spec found for `$1`. Check available specs in `{{KIRO_DIR}}/specs/`"
- **Action**: List available spec directories

**Incomplete Spec**:
- **Warning**: Identify which files are missing
- **Suggested Action**: Point to next phase command

### List All Specs / Overall Progress

To see overall roadmap progress:
- Run with no argument: `/sdd-status`
- If `roadmap.md` exists: Shows Wave-by-wave progress with blocked indicators
- If no `roadmap.md`: Lists all specs in `{{KIRO_DIR}}/specs/` with their individual status
