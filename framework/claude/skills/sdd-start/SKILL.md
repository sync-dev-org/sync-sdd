---
description: Session start — invoke on "再開", "continue", "resume", or at every session start
allowed-tools: Bash, Glob, Grep, Read, Write, Edit
---

# SDD Start

<instructions>

## Core Task

Execute session start protocol. All steps are idempotent and safe to re-execute. Do NOT skip any step.

## Step 1: Detect

Check if `{{SDD_DIR}}/session/handover.md` exists.
- Absent → first session: skip to Step 6
- Present → resume session: proceed

## Step 2: Read Session Context

Read `{{SDD_DIR}}/session/handover.md` → Direction, Context, Warnings, Steering Exceptions.

## Step 2b: Read Knowledge

Check `{{SDD_DIR}}/session/knowledge.yaml` existence with Glob first (Read errors on missing files cascade and cancel parallel tool calls). Read only if found.

## Step 3: Read Review State

Check for active review verdicts (read if found):
- `{{SDD_DIR}}/project/specs/*/reviews/verdicts.yaml` → per-spec review state (latest batch)
- `{{SDD_DIR}}/project/reviews/*/verdicts.yaml` → project-level review state (dead-code, cross-check, wave)
- `{{SDD_DIR}}/project/specs/.cross-cutting/*/verdicts.yaml` → cross-cutting revision review state

## Step 4: Read Decision History

Read `{{SDD_DIR}}/session/decisions.yaml` → recent decision history (last ~20 entries from `entries` list).

## Step 5: Reconstruct Pipeline State

If roadmap active: scan all `{{SDD_DIR}}/project/specs/*/spec.yaml` files → build pipeline state dynamically.

## Step 6: tmux Initialization

**MANDATORY when `$TMUX` is set. Do NOT skip.**

Check `$TMUX` environment variable. If set, execute Steps 6a–6e:

a. **SID Generation**: Run `date +%H%M%S` and capture output as `$SID` (session-unique ID)
b. **Lead Pane Title**: Run `tmux select-pane -T 'sdd-{SID}-lead'` (best-effort — Claude Code overwrites this, but set it anyway for tmux UX)
c. **Orphan Cleanup**: Get current pane ID with `printenv TMUX_PANE` → `$MY_PANE`. Read `{{SDD_DIR}}/session/state.yaml` if it exists. Extract `grid.window_id` and all pane_ids (lead + slots). Run `bash .sdd/settings/scripts/orphan-detect.sh primary {window_id} {MY_PANE} {pane_id1} {pane_id2} ...` — outputs live orphan pane_ids (one per line; excludes MY_PANE; exits silently if window no longer exists). If orphans found, report to user (include window_id and count) and use `AskUserQuestion` tool to confirm before killing them. On confirmation, kill all orphans in one call: `bash .sdd/settings/scripts/orphan-kill.sh {pane_id1} {pane_id2} ...`. If state.yaml does not exist, fall back to title-based detection: `bash .sdd/settings/scripts/orphan-detect.sh fallback {MY_PANE} {SID}` — outputs `{pane_id} {title}` for panes with `sdd-` prefix titles whose SID does not match current `$SID` (current window only). On confirmation, extract pane_ids and pass to `orphan-kill.sh`.
d. **Grid Setup**: If state.yaml was found in Step 6c: first verify `grid.window_id` matches current Lead pane's window (get current window_id via `bash .sdd/settings/scripts/window-id.sh` or equivalent helper). If window_id mismatch → fresh grid. If match: run `bash .sdd/settings/scripts/grid-check.sh {grid.window_id} {slot_pane_id1} {slot_pane_id2} ...` (exit 0 = all alive, exit 1 = dead or window gone). If all alive → reuse existing grid, get `$WINDOW_ID` from state.yaml's `grid.window_id`. busy slot がある場合も再利用可能とし、idle slot のみ使用対象にする。If any dead or state.yaml not found → run `bash .sdd/settings/scripts/multiview-grid.sh $SID $MY_PANE`. Parse output: first line is `window_id:{id}` → `$WINDOW_ID`, remaining lines are `slot-{N}:{pane_id}` → slot management table.
e. **state.yaml Generation**: Write `{{SDD_DIR}}/session/state.yaml` with session metadata, window_id, and grid slot mappings. Note: `lead.window_id` and `grid.window_id` are always identical (Lead and Grid coexist in the same window). grid 再利用時: 既存 state.yaml の `grid` セクションから busy slot の metadata (`agent`, `engine`, `channel`, `url`) を保持し、`lead` と `sid` のみ更新する。fresh grid 作成時: 全 slot を `idle` で初期化する。
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

## Step 7: Record SESSION_START

Run `date +%Y-%m-%dT%H:%M:%S%z` for timestamp. Append `SESSION_START` entry to `{{SDD_DIR}}/session/decisions.yaml` `entries` list:
```yaml
- id: "D{seq}"
  type: "SESSION_START"
  summary: "{summary}"
  context: "{context}"
  detail: "セッション開始、{next action or ユーザー指示待ち}"
  created_at: "{timestamp}"
```

## Step 8: Pipeline Continuation

If roadmap pipeline was active (handover.md indicates run/revise in progress):
- Continue pipeline from spec.yaml state. Treat spec.yaml as ground truth.
- Do NOT manually update spec.yaml to "recover" or "fix" perceived inconsistencies.
- If spec.yaml state vs actual artifacts seem inconsistent: report to user, do not auto-fix.

Otherwise: report session state summary and await user instruction.

## Post-Completion Report

Report to user:
- Branch and working tree status
- Latest release version (from VERSION file if exists)
- Active pipeline status (if any)
- Immediate next action (from handover.md)
- Key warnings (from handover.md)

</instructions>
