---
description: Session resume — invoke on "再開", "continue", "resume", or at every session start
allowed-tools: Bash, Glob, Grep, Read, Write, Edit, AskUserQuestion
---

# SDD Resume

<instructions>

## Core Task

Execute session resume protocol. All steps are idempotent and safe to re-execute. Do NOT skip any step.

## Step 1: Detect

Check if `{{SDD_DIR}}/handover/session.md` exists.
- Absent → first session: skip to Step 6
- Present → resume session: proceed

## Step 2: Read Session Context

Read `{{SDD_DIR}}/handover/session.md` → Direction, Context, Warnings, Steering Exceptions.

## Step 2a: Read Review State

Check for active review verdicts (read if found):
- `{{SDD_DIR}}/project/specs/*/reviews/verdicts.md` → per-spec review state (latest batch)
- `{{SDD_DIR}}/project/reviews/*/verdicts.md` → project-level review state (dead-code, cross-check, wave)
- `{{SDD_DIR}}/project/specs/.cross-cutting/*/verdicts.md` → cross-cutting revision review state

## Step 3: Read Decision History

Read latest N entries from `{{SDD_DIR}}/handover/decisions.md` → recent decision history.

## Step 4: Read Knowledge Buffer

Read `{{SDD_DIR}}/handover/buffer.md` → pending knowledge tags (if exists).

## Step 5: Reconstruct Pipeline State

If roadmap active: scan all `{{SDD_DIR}}/project/specs/*/spec.yaml` files → build pipeline state dynamically.

## Step 5a: tmux Initialization

**MANDATORY when `$TMUX` is set. Do NOT skip.**

Check `$TMUX` environment variable. If set, execute all 4 sub-steps:

1. **SID Generation**: Run `date +%H%M%S` and capture output as `$SID` (session-unique ID)
2. **Lead Pane Title**: Run `tmux select-pane -T 'sdd-{SID}-lead'`
3. **Orphan Cleanup**: Run `tmux list-panes -a -F '#{pane_id} #{pane_title}'` to list all panes. Identify panes with `sdd-` prefix titles whose SID does not match current `$SID`. Report orphans to user and ask for confirmation before killing them.
4. **Grid Creation**: Get current pane ID with `tmux display-message -p '#{pane_id}'`. Run `bash .sdd/settings/scripts/multiview-grid.sh $SID $MY_PANE`. Parse output to build slot management table (`slot-{N}:{pane_id}` format).

## Step 6: Record SESSION_START

Run `date +%Y-%m-%dT%H:%M:%S%z` for timestamp. Append `SESSION_START` entry to `{{SDD_DIR}}/handover/decisions.md`:
```
[{timestamp}] D{seq}: SESSION_START | {summary}
- Context: {context}
- Decision: セッション開始、{next action or ユーザー指示待ち}
```

## Step 7: Pipeline Continuation

If roadmap pipeline was active (session.md indicates run/revise in progress):
- Continue pipeline from spec.yaml state. Treat spec.yaml as ground truth.
- Do NOT manually update spec.yaml to "recover" or "fix" perceived inconsistencies.
- If spec.yaml state vs actual artifacts seem inconsistent: report to user, do not auto-fix.

Otherwise: report session state summary and await user instruction.

## Post-Completion Report

Report to user:
- Branch and working tree status
- Latest release version (from VERSION file if exists)
- Active pipeline status (if any)
- Immediate next action (from session.md)
- Key warnings (from session.md)

</instructions>
