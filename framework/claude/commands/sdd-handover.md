---
description: Generate session handover document for cross-session continuity
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, AskUserQuestion
argument-hint: [output-path]
---

# SDD Session Handover

<background_information>
- **Mission**: Generate a structured handover document at session end so the next session can seamlessly continue work
- **Success Criteria**:
  - Accurately auto-collect current project state
  - Capture work done, decisions made, and unresolved items during the session
  - Enable the next session to restore context just by reading the document
  - Maintain sufficient information in a token-efficient format
- **Design Principles** (Community Best Practices):
  - **Goal-Directed Handoff**: Prioritize intent (what you're trying to do) over history (what happened)
  - **Two-Layer Approach**: Strategic direction + technical details as a two-layer structure
  - **External File Persistence**: Persist to file rather than relying on context window
  - **Concise Over Complete**: Omit information recoverable by re-reading code; focus on what code alone cannot convey
</background_information>

<instructions>

## Core Task
Collect and structure the current session state, then generate a handover document.

## Execution Steps

### Step 1: Auto-collect Project State

Collect the following **in parallel**:

#### 1a. Git State
```bash
git branch --show-current          # Current branch
git status --short                 # Uncommitted changes
git log --oneline -10              # Recent commits
git diff --stat HEAD               # Unstaged changes summary
git stash list                     # Stash list
```

#### 1b. Roadmap & Spec State
- Read `{{KIRO_DIR}}/specs/roadmap.md` to understand Wave structure
- Read all `{{KIRO_DIR}}/specs/*/spec.json` to collect each spec's phase
- Scan each spec's `tasks.md` to tally task completion (`- [x]` vs `- [ ]`)

#### 1c. Test State
```bash
# Run tests and capture results (use the project's test command)
uv run pytest --tb=no -q 2>&1 | tail -5
```

#### 1d. Steering Changes
- Check file list and last modified dates in `{{KIRO_DIR}}/steering/`

### Step 2: Collect Session Context

**Collect interactively via AskUserQuestion** (some items are optional):

#### Question 1: Session Goal and Accomplishments
```
What did you accomplish in this session?
(Present auto-inferred content from conversation history for user to confirm/correct)
```
- Present an auto-inferred list of accomplishments from conversation context
- User confirms, corrects, or adds items

#### Question 2: Incomplete Tasks and Next Action
```
What should be done first in the next session?
```
- Options:
  - A. "Continue with the next roadmap step" (show auto-detected next step)
  - B. "Resume from a specific task" (specify task number)
  - C. "Specify manually"

#### Question 3: Key Decisions and Caveats (optional)
```
Are there important decisions or caveats to carry over to the next session?
(Skip if none)
```
- Options:
  - A. "Nothing in particular"
  - B. "Yes (describe)"

### Step 3: Generate Handover Document

Generate a markdown document with the following structure:

```markdown
# Session Handover

**Generated**: {ISO 8601 timestamp}
**Branch**: {current branch}
**Session Goal**: {one-sentence session goal}

## Direction (Instructions for Next Session)

### Immediate Next Action
{Specific action the next session should execute first}
{Include executable commands if possible: `/sdd-impl feature 3.1` etc.}

### Active Goals
{Current active goals, linked to roadmap wave progress}

### Key Decisions
{Important decisions made in this session and their rationale}
{Explicitly mark decisions the next session should not overturn}

### Warnings
{Known issues, pitfalls, things to watch out for}
{Omit section if none}

## State (Project State Snapshot)

### Roadmap Progress
| Wave | Name | Progress | Status |
|------|------|----------|--------|
{Generate table from auto-collected data}

### Spec Status
| Spec | Phase | Tasks | Notes |
|------|-------|-------|-------|
{Generate table from auto-collected data}

### Git State
- **Branch**: {branch}
- **Uncommitted Changes**: {count} files
- **Recent Commits**:
{Last 5 commit logs}

### Test Status
{Test execution result summary}

## Session Log (Work Done)

### Accomplished
{Bulleted list of completed work}

### Modified Files
{Key modified files list - from git diff --stat}

## Resume Instructions

To resume in the next session:
1. `Read .claude/handover.md` to restore context
2. {Specific resume steps}
```

### Step 4: Write to File

1. **Default output**: `.claude/handover.md` (always overwrite with the latest handover)
2. **Custom output path**: If `$1` is specified, write to that path instead
3. **Archive**: If `.claude/handover.md` already exists:
   - If content differs, copy to `.claude/handovers/{YYYY-MM-DD-HHMM}.md` before overwriting
   - Create the archive directory if it doesn't exist

### Step 5: Add Reference to CLAUDE.md (first time only)

If `.claude/CLAUDE.md` does not already contain the following, append it:

```markdown
## Session Handover
- On session start: If `.claude/handover.md` exists, read it to restore previous state
- On session end: Run `/sdd-handover` to generate a handover document
```

</instructions>

## Tool Guidance

### Parallel Execution
- Git state collection, spec scanning, and test execution in Step 1 should be run **in parallel**
- Step 2 interactive collection should happen after Step 1 completes

### File Operations
- **Glob**: Batch search for `{{KIRO_DIR}}/specs/*/spec.json`, `{{KIRO_DIR}}/specs/*/tasks.md`
- **Read**: Read spec.json, tasks.md, roadmap.md
- **Bash**: Execute git commands, run tests
- **Write**: Write handover document
- **Edit**: Add reference to CLAUDE.md (first time only)

### Interaction
- **AskUserQuestion**: Collect session context
- Auto-collect what can be automated; only ask interactively for information only the human knows
- If the user is in a hurry, generate with minimal interaction (Question 1 only)

## Output Description

After generating the handover document, display:

```
## Handover Generated

**File**: .claude/handover.md
**Archive**: .claude/handovers/YYYY-MM-DD-HHMM.md (if applicable)

### Summary
- Wave N: X/Y specs complete
- Next action: {specific next action}
- Uncommitted changes: {count} files
- Tests: {pass/fail status}

### Resume in Next Session
> Read .claude/handover.md to restore context
```

**Format**: Concise (200 words or less)

## Safety & Fallback

### Error Scenarios

**Git repository not initialized**:
- Skip git-related data collection
- Display warning and continue

**Roadmap not created**:
- Omit Roadmap Progress section
- Show only individual Spec Status

**Test execution failure**:
- Record error message as-is in Test Status
- Do not abort generation

**Conflict with existing handover**:
- Always archive before overwriting
- Archives are sorted by date, oldest first for reference

### Integration

**On session start (recommended flow for next session)**:
1. Read `.claude/handover.md`
2. Begin work following the Direction section
3. Refer to State section if anything is unclear

**On session end**:
1. Run `/sdd-handover`
2. Commit if needed
3. End session

think
