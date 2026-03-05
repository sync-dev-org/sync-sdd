---
description: Session start — invoke on "再開", "continue", "resume", or at every session start
allowed-tools: Bash, Glob, Grep, Read, Write, Edit
---

# SDD Start

<instructions>

## Core Task

Execute session start protocol. All steps are idempotent and safe to re-execute. Do NOT skip any step.

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

Check `{{SDD_DIR}}/handover/buffer.md` existence with Glob first (Read errors on missing files cascade and cancel parallel tool calls). Read only if found.

## Step 5: Reconstruct Pipeline State

If roadmap active: scan all `{{SDD_DIR}}/project/specs/*/spec.yaml` files → build pipeline state dynamically.

## Step 5a: tmux Initialization

**MANDATORY when `$TMUX` is set. Do NOT skip.**

Check `$TMUX` environment variable. If set, execute all sub-steps:

1. **SID Generation**: Run `date +%H%M%S` and capture output as `$SID` (session-unique ID)
2. **Lead Pane Title**: Run `tmux select-pane -T 'sdd-{SID}-lead'` (best-effort — Claude Code overwrites this, but set it anyway for tmux UX)
3. **Orphan Cleanup**: Get current pane ID with `printenv TMUX_PANE` → `$MY_PANE`. Read `{{SDD_DIR}}/state.yaml` if it exists. For each pane_id listed (lead + all slots), check if it still exists in tmux via `tmux list-panes -F '#{pane_id}'`. Exclude `$MY_PANE` (own Lead pane). Collect remaining live panes as orphan candidates. Report orphans to user and use `AskUserQuestion` tool to confirm before killing them. If state.yaml does not exist, fall back to title-based detection: `tmux list-panes -F '#{pane_id} #{pane_title}'` (current window only), identify panes with `sdd-` prefix titles whose SID does not match current `$SID`.
4. **Grid Setup**: If state.yaml exists and ALL slot pane_ids are alive in tmux (after orphan cleanup) → reuse existing grid, skip grid.sh. Otherwise → run `bash .sdd/settings/scripts/multiview-grid.sh $SID $MY_PANE`. Parse output to build slot management table (`slot-{N}:{pane_id}` format).
5. **state.yaml Generation**: Write `{{SDD_DIR}}/state.yaml` with session metadata and grid slot mappings:
   ```yaml
   sid: "{SID}"
   created_at: "{ISO-8601 timestamp}"
   lead:
     pane_id: "{lead pane_id}"
   grid:
     slot-1:
       pane_id: "{pane_id}"
       status: idle
     slot-2:
       pane_id: "{pane_id}"
       status: idle
     # ... slot-3 through slot-12
   ```

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
