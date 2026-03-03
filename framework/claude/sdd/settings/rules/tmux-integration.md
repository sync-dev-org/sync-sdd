# tmux Integration Patterns

Reusable tmux patterns for Lead orchestration. Lead reads this file on-demand when entering a tmux-involving code path.

## Prerequisites

- Check `$TMUX` is set before using any pattern. If not set, use the documented Fallback.
- All pane targeting uses **pane ID** (`%N` format) returned by `tmux split-window -P -F '#{pane_id}'`. **Never use index-based targeting** (`-t 1`) — it may kill the wrong pane (including Claude Code itself).
- Pane title convention: `sdd-{purpose}-{identifier}` (e.g., `sdd-devserver-auth`, `sdd-ext-review`).

## Shared Operations

### List Panes
```
tmux list-panes -a -F '#{pane_title} #{pane_id}'
```
Use Grep on output to find target pane by title pattern.

### Create Pane with Title
```
tmux split-window -d -l {size} -P -F '#{pane_id}' \
  'printf "\\033]2;{pane_title}\\033\\\\" && {command}'
```
Store returned pane ID for all subsequent operations. `-d` keeps focus on the current pane.

### Kill Pane
```
tmux kill-pane -t '{pane_id}'
```
Using stored ID from creation.

### Capture Pane Output
```
tmux capture-pane -t '{pane_id}' -p
```
Use Grep on output for pattern matching.

## Pattern A: Server Lifecycle

Long-running server in a visible pane with readiness polling. Used for dev servers during web inspector reviews.

### Start
1. **Check for existing pane**: List Panes, Grep for `sdd-{purpose}-{identifier}`. If found, reuse it (server already running from retry).
2. **Port offset** (parallel instances): if other `sdd-{purpose}-*` panes exist, apply `--port {base+N}`. Skip if the server framework does not support port override.
3. **Create pane**: size 30%, with server command. Store pane ID.
4. **Poll readiness**: Capture Pane Output, Grep for ready pattern (`ready`, `localhost`, `listening on`). Max 30 seconds, check every 2 seconds.
5. **Record** server URL (e.g., `http://localhost:{port}`).

### Stop
Kill Pane by stored ID.

### Fallback (no tmux)
1. Start server via `Bash(run_in_background=true)`. Record PID.
2. Poll URL for readiness (retry access with brief delays, max 30 seconds).
3. Stop by killing PID.

## Pattern B: One-Shot Command

External CLI runs in a pane with native progress display, result captured via file. Used for external tool execution (e.g., external engines).

### Concurrency

複数インスタンスが並行する場合、以下を一意にする:
- **Pane title**: `sdd-{purpose}-{identifier}` (e.g., `sdd-ext-review-1`, `sdd-ext-review-2`)
- **Wait-for channel**: pane title と同じ値を使う (e.g., `sdd-ext-review-1`)
- **Result file**: プロジェクト内のスコープディレクトリに置く。`/tmp` 等のプロジェクト外パスは使わない

### Multi-Pane Layout

複数 pane を並行起動する場合、右カラムレイアウトを使う:
1. **1st pane**: `tmux split-window -h` (右に分割) → Lead の左カラムを維持
2. **2nd+ pane**: `tmux split-window -v -t $PREV_PANE` (直前の pane を下方向に分割)

これにより全 Agent pane が右カラムに縦積みされ、Lead の作業エリアを圧迫しない。

### Auto-Approval Pattern

各 Bash 呼び出しを `tmux` で開始すること。settings.json の `Bash(tmux *)` にマッチし承認不要になる。変数代入 (`SD=... &&`) やコマンド置換 (`P1=$(tmux ...)`) をコマンド先頭に置くとパターン不一致で承認を求められる。パスはインラインで記述する。

### Execute
1. **Prepare**: 一意な識別子を決め、pane title / channel / result file path を導出する。結果ファイルはスコープディレクトリ内に配置する。
2. **Create pane**: Append `; tmux wait-for -S {channel}` to signal completion. Multi-Pane Layout に従い、1st は `-h`、2nd 以降は `-v -t $PREV_PANE` を使う。各呼び出しは `tmux` で開始する（Auto-Approval Pattern）。
   ```
   tmux split-window -d {-h or -v -t $PREV} -P -F '#{pane_id}' \
     '{command}; tmux wait-for -S {channel}'
   ```
   Bash 返値 = pane ID。次の呼び出しの `-t` に使う。
3. **Wait for completion**: `tmux wait-for {channel}` (blocking). For parallel dispatch: create all panes first (steps 1-2 for each), then issue multiple `tmux wait-for` via `Bash(run_in_background=true)` in parallel to wait for all channels concurrently.
4. **Read result file**.
5. **Cleanup**: Pane typically auto-closes on command exit. If still alive, Kill Pane by stored ID.

### Fallback (no tmux)
1. Run command via `Bash()` with appropriate timeout. 結果ファイルは同じスコープディレクトリ内に書き出す。
2. Progress display is lost; result file is still produced.
3. Use `2>/dev/null` to suppress stderr if desired.

## Orphan Cleanup

On session resume (when `$TMUX` set):

1. List Panes, Grep for `sdd-`.
2. Extract pane IDs from matches.
3. Kill each with Kill Pane.

`sdd-` prefix で全パターン (devserver, ext, 将来追加分) を一括検出する。セッション再開時点で残存しているペインは前回のクラッシュ由来であり、安全に kill できる。
