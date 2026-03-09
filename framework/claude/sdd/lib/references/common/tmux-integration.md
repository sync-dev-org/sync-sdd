# tmux Integration Patterns

Reusable tmux patterns for Lead orchestration. Lead reads this file on-demand when entering a tmux-involving code path.

## Prerequisites

- Check `$TMUX` is set before using any pattern. If not set, use the documented background mode alternative.
- All pane targeting uses **pane ID** (`%N` format). **Never use index-based targeting** (`-t 1`) — it may kill the wrong pane (including Claude Code itself).

### Session ID (`$SID`)

Prevents channel name collisions when multiple sync-sdd sessions (different repositories or same repository) run in parallel within the same tmux server.

**Generation**: Execute `date +%H%M%S` in `/sdd-start` Step 6 and use the output directly as `$SID` (e.g., `104817`). This produces a unique value per session (process). A time-based approach is used because pane ID-based values would collide with a previous session when restarting in the same pane.

**Persistence**: SID, window_id, and all pane IDs are recorded in `{{SDD_DIR}}/session/state.yaml`. `window_id` identifies the window where the grid exists (used for orphan detection and grid reuse scoping). Pane titles are decorative (best-effort) and must not be relied upon for logic. Claude Code overwrites pane titles in both TUI and print modes, so titles must not be depended on.

**Lead pane title**: Immediately after SID generation, execute `tmux select-pane -T 'sdd-{SID}-lead'` (best-effort). Claude Code will overwrite it, but it is set for tmux UX purposes.

**Naming convention**: `sdd-{SID}-{purpose}-{identifier}` (e.g., `sdd-104817-devserver-auth`, `sdd-104817-slot-3`)

## Shared Operations

### List Panes

**Cannot be executed directly from Lead due to `#{}` heuristic false detection.** Execute via helper scripts such as `orphan-detect.sh`. Syntax within scripts:
```
tmux list-panes -F '#{pane_title} #{pane_id}'
```
Current window only (default). Use `-t @{window_id}` to target a specific window. `-a` (all windows/sessions) should not be used in principle as it causes scope errors.

### Kill Pane
```
tmux kill-pane -t '{pane_id}'
```

### Capture Pane Output
```
tmux capture-pane -t '{pane_id}' -p
```
Use Grep on output for pattern matching.

### Set Pane Title
```
tmux select-pane -t '{pane_id}' -T '{title}'
```

## MultiView Layout

A layout model that batch-creates a tmux pane grid at session start and dynamically assigns agents to slots. No pane creation or destruction occurs, keeping the layout completely stable.

### Grid Structure

Based on 4 quadrants (2 columns x 2 rows). Lead occupies the top-left quadrant, and the remaining 3 quadrants are subdivided into a 2x2 grid each, assigned as agent slots.

```
┌─────────────────────┬──────────┬──────────┐
│                     │    S1    │    S2    │
│                     ├──────────┼──────────┤
│        Lead         │    S3    │    S4    │
│                     │          │          │
├──────────┬──────────┼──────────┼──────────┤
│    S5    │    S6    │    S9    │   S10    │
│          │          │          │          │
├──────────┼──────────┼──────────┼──────────┤
│    S7    │    S8    │   S11    │   S12    │
│          │          │          │          │
└──────────┴──────────┴──────────┴──────────┘
```

| Item | Value |
|---|---|
| Lead size | 120w × 32h |
| Slot size | 60w × 16h |
| Max slots | 12 |

**Max Lead: 1**. With 2 or more Leads, MultiView is not used (all agents fall back to `run_in_background`).

### Grid Creation

**Grid creation and recreation is exclusively handled by `/sdd-start`.** Other skills (sdd-review, sdd-review-self, etc.) only "use" the Grid and must never recreate it — doing so risks destroying processes running in busy slots. When slots are insufficient, use surviving idle slots + `Bash(run_in_background=true)` fallback.

Executed in `/sdd-start` Step 7 after `$SID` generation and Lead pane title setup.

**Batch creation script**:
```
bash .sdd/settings/scripts/multiview-grid.sh $SID $MY_PANE
```
Output: first line `window_id:{id}` followed by 12 lines `slot-{N}:{pane_id}` (N = 1-12). Lead parses this output to build the window_id and slot management table.

**Script processing steps** (reference):
1. **4-quadrant split**: Split Lead pane with `-v -p 50` (top/bottom) → Lead | BOTTOM. Split Lead with `-h -p 50` (left/right) → Lead | RIGHT
2. **TR quadrant (S1-S4)**: Split RIGHT with `-v -p 50` → TR_TOP | TR_BOT. Split each row with `-h -p 50` into 2
3. **BL/BR quadrants (S5-S12)**: Split BOTTOM with `-v -p 50` → BL_TOP | BL_BOT. Split each row with `-h -p 50` into left/right to form BL/BR. Further split each cell with `-h -p 50` into 2
4. **Title setup**: Lead pane → `sdd-{SID}-lead`, all slot panes → `sdd-{SID}-slot-{N}` (N = 1-12)

All slots wait in idle shell state. After Grid Creation completes, Lead holds the slot list `{slot_number, pane_id, status: idle}`.

**Verified dimensions** (240w × 65h terminal): Lead 120w × 32h, Slots 60w × 16h.

### Slot Management

| Operation | Method |
|------|------|
| **Assign** | `tmux send-keys -t {pane_id} '{command}; tmux wait-for -S {channel}' Enter` |
| **Wait** | `tmux wait-for {channel}` (blocking) |
| **Release** | Automatic — shell returns to idle after command completes |
| **Reuse** | Assign idle slot to the next agent |
| **Overflow** | All 12 slots busy → fall back to `Bash(run_in_background=true)` |

Lead tracks slot state in the `grid` section of `{{SDD_DIR}}/session/state.yaml`. `grid.window_id` indicates the window where the grid exists. On slot assign, update status → busy with purpose-specific attributes (Pattern B: agent/engine/channel, Pattern A: agent/url); on release, revert status → idle and remove additional attributes.

### Hold-and-Release

A pattern for releasing multiple agents simultaneously after all complete. Used when you want to verify all Agent results before proceeding.

**Command chain** (submitted via send-keys):
```
{command}; tmux wait-for -S {channel}; tmux wait-for {close-channel}
```
- `{channel}`: Agent-specific completion signal (e.g., `sdd-{SID}-ext-1-B{seq}`)
- `{close-channel}`: Release signal shared by all Agents (e.g., `sdd-{SID}-close-B{seq}`)

**Lead flow**:
1. Wait for all Agent completion signals
2. Read result files
3. `tmux wait-for -S {close-channel}` → unblock all panes
4. Agent command chain completes → shell returns to idle (slot reusable)

## Pattern A: Server Lifecycle

Long-running server executed in a MultiView slot with readiness polling. Used for dev servers during web inspector reviews.

### Start
1. **Check for existing server**: Search the `grid` section of `{{SDD_DIR}}/session/state.yaml` for slots with `agent: {purpose}-*`. If found, reuse that server (it may still be running from a previous retry). Obtain the server URL from the `url` field.
2. **Port offset** (parallel instances): If other `agent: {purpose}-*` slots exist in state.yaml, obtain port numbers from their `url` fields and apply `--port {base+N}`. Skip if the server framework does not support port override.
3. **Assign slot**: Select an idle slot and submit the server command via `send-keys`. Update the corresponding slot in `{{SDD_DIR}}/session/state.yaml`:
   ```yaml
   status: busy
   agent: "{purpose}-{identifier}"
   url: "http://localhost:{port}"
   ```
4. **Poll readiness**: Capture Pane Output, Grep for ready pattern (`ready`, `localhost`, `listening on`). Max 30 seconds, check every 2 seconds.

### Stop
1. Stop the server with `tmux send-keys -t {pane_id} C-c`
2. Update the corresponding slot in `{{SDD_DIR}}/session/state.yaml` to `status: idle` and remove `agent`/`url`.

### Background Mode (no tmux)
1. Start server via `Bash(run_in_background=true)`. Record PID.
2. Poll URL for readiness (retry access with brief delays, max 30 seconds).
3. Stop by killing PID.

## Pattern B: One-Shot Command

External CLI executed in a MultiView slot with native progress display, result captured via file. Used for external tool execution (e.g., external engines).

### Naming

When multiple instances run in parallel, the following must be unique:
- **Wait-for channel**: `sdd-{SID}-{purpose}-{identifier}-B{seq}` (e.g., `sdd-5-ext-1-B3`). The `-B{seq}` suffix is required — it prevents channel collisions on re-execution
- **Result file**: Place in a scoped directory within the project. Do not use paths outside the project such as `/tmp`

### Auto-Approval Pattern

Each Bash call must start with `tmux`. This matches `Bash(tmux *)` in settings.json, making approval unnecessary. Placing variable assignments (`SD=... &&`) or command substitutions (`P1=$(tmux ...)`) at the start of the command causes pattern mismatch and triggers approval prompts. Write paths inline.

### Execute
1. **Prepare**: Derive channel / result file path from `$SID` + purpose-specific identifier. Place result files in the scoped directory.
2. **Assign slot**: Select an idle slot and submit the command via `send-keys`. Each call must start with `tmux` (Auto-Approval Pattern).
   ```
   tmux send-keys -t {slot_pane_id} '{command}; tmux wait-for -S {channel}' Enter
   ```
3. **Wait for completion**: `tmux wait-for {channel}` (blocking). For parallel dispatch: assign all agents to slots first (step 2), then issue parallel `Bash(run_in_background=true)` for each `tmux wait-for`.
   - **Staggered Parallel Dispatch**: When issuing multiple `send-keys` or `wait-for` commands, stagger them with sleep prefixes at 0.5-second intervals, dispatching all at once via parallel Bash calls in a single message (consuming 1 Lead turn):
     ```
     Bash(run_in_background=true): sleep 0.0; tmux send-keys -t {pane1} '...' Enter
     Bash(run_in_background=true): sleep 0.5; tmux send-keys -t {pane2} '...' Enter
     Bash(run_in_background=true): sleep 1.0; tmux send-keys -t {pane3} '...' Enter
     ```
     Staggering is necessary because tmux can choke on rapid-fire command bursts. Sequential issuing (send-keys → sleep → send-keys) wastes turns, so avoid it.
   - **Notification-based completion**: Each `Bash(run_in_background=true)` completion is detected individually via task-notification. Do not use TaskOutput (#14055 Race Condition avoidance + Lead non-blocking).
4. **Read result file**.
5. Slot automatically returns to idle.

Overflow (all slots busy): Execute with `Bash(run_in_background=true)`. Result files go in the same scoped directory.

### Template Variable Expansion in send-keys

Commands inside send-keys execute in the pane's shell, so Claude Code's security heuristics (`$()` / `${}` prohibition) do not apply. When substituting template file placeholders with dynamic values to pass to external engines, there are two approaches:

**Approach A: sed one-liner** — Most efficient when values are single-line (zero Read/Write from Lead)
```
tmux send-keys -t {pane} 'sed "s|{{PLACEHOLDER}}|{value}|g" template.md | cat shared.md - | ENGINE_CMD; tmux wait-for -S {channel}' Enter
```
- BSD sed (macOS) `s` command cannot include literal newlines in the replacement string. **Use only when values are single-line**
- Use `|` as delimiter (values may contain `/`)

**Approach B: Briefer expansion** — When values are multi-line, or the same value is expanded into multiple templates
1. Briefer reads templates, expands placeholders, and writes to `active/`
2. Lead's dispatch follows the same pattern for all Inspectors: `cat shared active/inspector-{name}.md | ENGINE_CMD`
3. Eliminates sed branching and newline detection logic, greatly simplifying dispatch

sdd-review-self uses Approach B (v2.1.2). Approach A is useful when values are guaranteed to always be single-line.

### Background Mode (no tmux)
1. Run command via `Bash()` with appropriate timeout. Write result files to the same scoped directory.
2. Progress display is lost; result file is still produced.
3. Stderr is not suppressed — let errors surface for debugging.

## Orphan Cleanup

Executed in `/sdd-start` Step 7 **after** SID generation and Lead title setup, but **before** Grid Creation.

**Primary (state.yaml-based)**:
1. Read `{{SDD_DIR}}/session/state.yaml` (obtain `old_sid`, `grid.window_id`, all pane_ids)
2. Execute `bash {{SDD_DIR}}/settings/scripts/orphan-detect.sh primary {window_id} {MY_PANE} {pane_ids...}`. The script checks pane existence scoped to the grid's window_id and outputs live orphan pane_ids (`$MY_PANE` is excluded; empty output if the window does not exist)
3. If orphans are found, **confirm with user**: "There are {N} panes from the previous session (SID: {old_sid}) remaining in Window {window_id}. Kill them?"
4. If user approves → Kill Pane. If declined → skip

**Fallback (no state.yaml)**: Detect by title. Execute `bash {{SDD_DIR}}/settings/scripts/orphan-detect.sh fallback {MY_PANE} {SID}`. Outputs panes in the current window that have `sdd-` prefix titles with a different SID than the current one (`{pane_id} {title}` format).
