# tmux Integration Patterns

Reusable tmux patterns for Lead orchestration. Lead reads this file on-demand when entering a tmux-involving code path.

## Prerequisites

- Check `$TMUX` is set before using any pattern. If not set, use the documented Fallback.
- All pane targeting uses **pane ID** (`%N` format) returned by `tmux split-window -P -F '#{pane_id}'`. **Never use index-based targeting** (`-t 1`) — it may kill the wrong pane (including Claude Code itself).

### Session ID (`$SID`)

同一 tmux サーバー内で複数の sync-sdd セッション（別リポジトリ or 同一リポジトリ）が並行する場合にチャネル名・ペインタイトルの衝突を防止する。

**生成**: Session Resume Step 5a で `$MY_PANE` から導出。`$SID` = `$MY_PANE` の `%` を除去した数値 (例: pane `%5` → SID `5`)。ファイル永続化は不要 — pane ID 自体が tmux サーバー内で一意。

**命名規則**: `sdd-{SID}-{purpose}-{identifier}` (例: `sdd-5-devserver-auth`, `sdd-5-ext-1`)

## Shared Operations

### List Panes
```
tmux list-panes -a -F '#{pane_title} #{pane_id}'
```
Use Grep on output to find target pane by title pattern (`sdd-{SID}-` prefix でスコープ).

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
1. **Check for existing pane**: List Panes, Grep for `sdd-{SID}-{purpose}-{identifier}`. If found, reuse it (server already running from retry).
2. **Port offset** (parallel instances): if other `sdd-{SID}-{purpose}-*` panes exist, apply `--port {base+N}`. Skip if the server framework does not support port override.
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
- **Pane title**: `sdd-{SID}-{purpose}-{identifier}` (e.g., `sdd-5-ext-1`)
- **Wait-for channel**: pane title と同じ値を使う
- **Result file**: プロジェクト内のスコープディレクトリに置く。`/tmp` 等のプロジェクト外パスは使わない

### Multi-Pane Layout

複数 pane を並行起動する場合、tiled レイアウトを使う:
1. 任意の分割順序で必要数の pane を作成
2. 全 pane 作成後に `tmux select-layout tiled` → Lead 含む全 pane を均等グリッド配置

`tiled` は pane インデックス順に配置するため、Lead (最小インデックス) が自動的に左上になる。

### Auto-Approval Pattern

各 Bash 呼び出しを `tmux` で開始すること。settings.json の `Bash(tmux *)` にマッチし承認不要になる。変数代入 (`SD=... &&`) やコマンド置換 (`P1=$(tmux ...)`) をコマンド先頭に置くとパターン不一致で承認を求められる。パスはインラインで記述する。

### Execute
1. **Prepare**: `$SID` + 目的固有の識別子から pane title / channel / result file path を導出する。結果ファイルはスコープディレクトリ内に配置する。
2. **Create pane**: Append `; tmux wait-for -S {channel}` to signal completion. 各呼び出しは `tmux` で開始する（Auto-Approval Pattern）。
   ```
   tmux split-window -d {split-flags} -P -F '#{pane_id}' \
     '{command}; tmux wait-for -S {channel}'
   ```
   Bash 返値 = pane ID。次の呼び出しの `-t` に使う。
3. **Layout**: 全 pane 作成後に `tmux select-layout tiled` (Multi-Pane Layout)。
4. **Wait for completion**: `tmux wait-for {channel}` (blocking). For parallel dispatch: create all panes first (steps 1-3), then issue multiple `tmux wait-for` via `Bash(run_in_background=true)` in parallel to wait for all channels concurrently.
5. **Read result file**.
6. **Cleanup**: Pane typically auto-closes on command exit. If still alive, Kill Pane by stored ID.

### Fallback (no tmux)
1. Run command via `Bash()` with appropriate timeout. 結果ファイルは同じスコープディレクトリ内に書き出す。
2. Progress display is lost; result file is still produced.
3. Use `2>/dev/null` to suppress stderr if desired.

## Orphan Cleanup

On session resume (when `$TMUX` set):

1. List Panes, Grep for `sdd-` prefix のタイトルを持つペインを列挙
2. 各タイトルから SID (= Lead pane ID) を抽出 (`sdd-{SID}-...` の `{SID}` 部分)
3. 抽出した SID ごとに `%{SID}` ペインが現存するか確認
4. 存在しない → 前セッションの孤児ペイン。存在する → 別のアクティブセッション → skip
5. 孤児ペインが見つかった場合、**ユーザーに確認**: 「{N} 個の孤児ペインが見つかりました (前セッション SID: {SID})。kill しますか？」
6. ユーザーが承認 → Kill Pane。拒否 → skip
