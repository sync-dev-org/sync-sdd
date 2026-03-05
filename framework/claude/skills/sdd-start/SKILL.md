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
- Absent → first session: skip to Step 8
- Present → resume session: proceed

## Step 2: Read Session Context

Read `{{SDD_DIR}}/handover/session.md` → Direction, Context, Warnings, Steering Exceptions.

## Step 3: Read Review State

Check for active review verdicts (read if found):
- `{{SDD_DIR}}/project/specs/*/reviews/verdicts.md` → per-spec review state (latest batch)
- `{{SDD_DIR}}/project/reviews/*/verdicts.md` → project-level review state (dead-code, cross-check, wave)
- `{{SDD_DIR}}/project/specs/.cross-cutting/*/verdicts.md` → cross-cutting revision review state

## Step 4: Read Decision History

Read latest N entries from `{{SDD_DIR}}/handover/decisions.md` → recent decision history.

## Step 5: Read Knowledge Buffer

Check `{{SDD_DIR}}/handover/buffer.md` existence with Glob first (Read errors on missing files cascade and cancel parallel tool calls). Read only if found.

## Step 6: Reconstruct Pipeline State

If roadmap active: scan all `{{SDD_DIR}}/project/specs/*/spec.yaml` files → build pipeline state dynamically.

## Step 7: tmux Initialization

**MANDATORY when `$TMUX` is set. Do NOT skip.**

Check `$TMUX` environment variable. If set, execute Steps 7a–7e:

a. **SID Generation**: Run `date +%H%M%S` and capture output as `$SID` (session-unique ID)
b. **Lead Pane Title**: Run `tmux select-pane -T 'sdd-{SID}-lead'` (best-effort — Claude Code overwrites this, but set it anyway for tmux UX)
c. **Orphan Cleanup**: Get current pane ID with `printenv TMUX_PANE` → `$MY_PANE`. Read `{{SDD_DIR}}/state.yaml` if it exists. Extract `grid.window_id` and all pane_ids (lead + slots). Run `bash .sdd/settings/scripts/orphan-detect.sh primary {window_id} {MY_PANE} {pane_id1} {pane_id2} ...` — outputs live orphan pane_ids (one per line; excludes MY_PANE; exits silently if window no longer exists). If orphans found, report to user (include window_id and count) and use `AskUserQuestion` tool to confirm before killing them. If state.yaml does not exist, fall back to title-based detection: `bash .sdd/settings/scripts/orphan-detect.sh fallback {MY_PANE} {SID}` — outputs `{pane_id} {title}` for panes with `sdd-` prefix titles whose SID does not match current `$SID` (current window only).
d. **Grid Setup**: If state.yaml was found in Step 7c: run `bash .sdd/settings/scripts/grid-check.sh {grid.window_id} {slot_pane_id1} {slot_pane_id2} ...` (exit 0 = all alive, exit 1 = dead or window gone). If all alive → reuse existing grid, get `$WINDOW_ID` from state.yaml's `grid.window_id`. If any dead or state.yaml not found → run `bash .sdd/settings/scripts/multiview-grid.sh $SID $MY_PANE`. Parse output: first line is `window_id:{id}` → `$WINDOW_ID`, remaining lines are `slot-{N}:{pane_id}` → slot management table.
e. **state.yaml Generation**: Write `{{SDD_DIR}}/state.yaml` with session metadata, window_id, and grid slot mappings:
   ```yaml
   sid: "{SID}"
   created_at: "{ISO-8601 timestamp}"
   lead:
     pane_id: "{lead pane_id}"
     window_id: "{window_id}"
   grid:
     window_id: "{window_id}"
     slot-1:
       pane_id: "{pane_id}"
       status: idle
     slot-2:
       pane_id: "{pane_id}"
       status: idle
     # ... slot-3 through slot-12
   ```

## Step 8: Record SESSION_START

Run `date +%Y-%m-%dT%H:%M:%S%z` for timestamp. Append `SESSION_START` entry to `{{SDD_DIR}}/handover/decisions.md`:
```
[{timestamp}] D{seq}: SESSION_START | {summary}
- Context: {context}
- Decision: セッション開始、{next action or ユーザー指示待ち}
```

## Step 9: Pipeline Continuation

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
