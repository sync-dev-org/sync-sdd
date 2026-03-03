# tmux Integration Patterns

Reusable tmux patterns for Lead orchestration. Lead reads this file on-demand when entering a tmux-involving code path.

## Prerequisites

- Check `$TMUX` is set before using any pattern. If not set, use the documented Fallback.
- All pane targeting uses **pane ID** (`%N` format). **Never use index-based targeting** (`-t 1`) — it may kill the wrong pane (including Claude Code itself).

### Session ID (`$SID`)

同一 tmux サーバー内で複数の sync-sdd セッション（別リポジトリ or 同一リポジトリ）が並行する場合にチャネル名・ペインタイトルの衝突を防止する。

**生成**: Session Resume Step 5a で `$MY_PANE` から導出。`$SID` = `$MY_PANE` の `%` を除去した数値 (例: pane `%5` → SID `5`)。ファイル永続化は不要 — pane ID 自体が tmux サーバー内で一意。

**Lead pane タイトル**: SID 生成直後に `tmux select-pane -T 'sdd-{SID}-lead'` を実行。他の Lead からの検出に使用。

**命名規則**: `sdd-{SID}-{purpose}-{identifier}` (例: `sdd-5-devserver-auth`, `sdd-5-slot-3`)

## Shared Operations

### List Panes
```
tmux list-panes -a -F '#{pane_title} #{pane_id}'
```
Use Grep on output to find target pane by title pattern (`sdd-{SID}-` prefix でスコープ).

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

セッション開始時に tmux pane グリッドを一括作成し、agent をスロットに動的割り当てするレイアウトモデル。pane の生成・破棄は発生せず、レイアウトは完全に安定する。

### Grid Structure

4 象限ベース。Lead が top-left 象限を占有し、残りを agent スロットに割り当てる。カラム比 2:1:1 は Lead 数によらず共通。

**1 Lead** (3 col × 6 row, 14 slots):
```
┌───────────────────────────────┬───────────────┐
│                               │      S1       │
│           Lead                ├───────────────┤
│                               │      S2       │
├───────────────┬───────────────┼───────────────┤
│      S3       │      S4       │      S5       │
├───────────────┼───────────────┼───────────────┤
│      S6       │      S7       │      S8       │
├───────────────┼───────────────┼───────────────┤
│      S9       │     S10       │     S11       │
├───────────────┼───────────────┼───────────────┤
│     S12       │     S13       │     S14       │
└───────────────┴───────────────┴───────────────┘
```

**2 Lead** (6 col × 6 row, 14 slots/Lead):
```
┌───────────────┬───────┬───────────────┬───────┐
│               │  A-1  │               │  B-1  │
│    Lead A     ├───────┤    Lead B     ├───────┤
│               │  A-2  │               │  B-2  │
├───────┬───────┼───────┼───────┬───────┼───────┤
│  A-3  │  A-4  │  A-5  │  B-3  │  B-4  │  B-5  │
├───────┼───────┼───────┼───────┼───────┼───────┤
│  A-6  │  A-7  │  A-8  │  B-6  │  B-7  │  B-8  │
├───────┼───────┼───────┼───────┼───────┼───────┤
│  A-9  │ A-10  │ A-11  │  B-9  │ B-10  │ B-11  │
├───────┼───────┼───────┼───────┼───────┼───────┤
│ A-12  │ A-13  │ A-14  │ B-12  │ B-13  │ B-14  │
└───────┴───────┴───────┴───────┴───────┴───────┘
```

| | 1 Lead | 2 Lead |
|---|---|---|
| カラム | 3 (80w) | 6 (40w) |
| Lead サイズ | 160w × top 1/3 | 80w × top 1/3 |
| Max slots | 14 | 14/Lead |
| Slot サイズ | 80w | 40w |

**Max Lead: 2**。3 Lead 以上は MultiView なしで動作（全 agent が `run_in_background` フォールバック）。

### Grid Creation

Session Resume Step 5a で `$SID` 生成・Lead pane タイトル設定後に実行。

**一括作成スクリプト**:
```
bash {{SDD_DIR}}/settings/scripts/multiview-grid.sh $SID $MY_PANE
```
出力: `slot-{N}:{pane_id}` (N = 1-14)。Lead はこの出力を parse してスロット管理テーブルを構築する。

**スクリプトの処理手順** (参考):
1. **Lead 検出**: List Panes → `sdd-*-lead` を Grep。自分以外の Lead が 2 以上 → grid 作成スキップ
2. **Top/Bottom 分割**: Lead pane を `-v -p 67` で分割 → Lead(top 33%) | BOTTOM(67%)
3. **Top-right スロット列**: Lead pane を `-h -p 33` で分割 → Lead(67%w) | RIGHT(33%w)
4. **S1/S2**: RIGHT を `-v -p 50` で分割
5. **Bottom 3 等分列**: BOTTOM を `-h -p 67` → LEFT | MID_RIGHT。MID_RIGHT を `-h -p 50` → MID | RIGHT_COL
6. **各列 4 行**: 各 column を `-v -p 75`, `-v -p 67`, `-v -p 50` で順次分割
7. **タイトル設定**: Lead pane → `sdd-{SID}-lead`、全スロット pane → `sdd-{SID}-slot-{N}` (N = 1-14)

全スロットは idle shell 状態で待機。Grid Creation 完了後、Lead はスロット一覧 `{slot_number, pane_id, status: idle}` を保持する。

**検証済み寸法** (240w × 65h terminal): Lead 160w × 21h, Slots 78-80w × 10h。

### Slot Management

| 操作 | 方法 |
|------|------|
| **Assign** | `tmux send-keys -t {pane_id} '{command}; tmux wait-for -S {channel}' Enter` |
| **Wait** | `tmux wait-for {channel}` (blocking) |
| **Release** | 自動 — コマンド完了後 shell が idle に戻る |
| **Reuse** | idle スロットを次の agent に割り当て |
| **Overflow** | 14 slots 全て busy → `Bash(run_in_background=true)` にフォールバック |

Lead はスロット状態を追跡: `{slot_number, pane_id, status: idle|busy, channel}`。

### Hold-and-Release

複数 agent を完了後に一斉解放するパターン。全 Agent の結果を確認してから次に進みたい場合に使う。

**Command chain** (send-keys で投入):
```
{command}; tmux wait-for -S {channel}; tmux wait-for {close-channel}
```
- `{channel}`: Agent 固有の完了シグナル (e.g., `sdd-{SID}-ext-1`)
- `{close-channel}`: 全 Agent 共有の解放シグナル (e.g., `sdd-{SID}-close`)

**Lead flow**:
1. 全 Agent の完了シグナルを待つ
2. 結果ファイルを読む
3. `tmux wait-for -S {close-channel}` → 全 pane のブロック解除
4. Agent command chain 完了 → shell が idle に戻る（スロット再利用可能）

## Pattern A: Server Lifecycle

Long-running server in a MultiView スロットで実行。readiness polling 付き。Used for dev servers during web inspector reviews.

### Start
1. **Check for existing server**: List Panes, Grep for `sdd-{SID}-{purpose}-{identifier}` タイトル。If found, reuse (server already running from retry).
2. **Port offset** (parallel instances): if other `sdd-{SID}-{purpose}-*` panes exist, apply `--port {base+N}`. Skip if the server framework does not support port override.
3. **Assign slot**: idle スロットを選択し、`send-keys` でサーバーコマンドを投入。スロットタイトルを `sdd-{SID}-{purpose}-{identifier}` に変更。
4. **Poll readiness**: Capture Pane Output, Grep for ready pattern (`ready`, `localhost`, `listening on`). Max 30 seconds, check every 2 seconds.
5. **Record** server URL (e.g., `http://localhost:{port}`).

### Stop
1. `tmux send-keys -t {pane_id} C-c` でサーバー停止
2. スロットタイトルを `sdd-{SID}-slot-{N}` に復元。スロットは idle に戻る

### Fallback (no tmux)
1. Start server via `Bash(run_in_background=true)`. Record PID.
2. Poll URL for readiness (retry access with brief delays, max 30 seconds).
3. Stop by killing PID.

## Pattern B: One-Shot Command

External CLI runs in a MultiView スロットで実行。native progress display 付き、result captured via file. Used for external tool execution (e.g., external engines).

### Naming

複数インスタンスが並行する場合、以下を一意にする:
- **Wait-for channel**: `sdd-{SID}-{purpose}-{identifier}` (e.g., `sdd-5-ext-1`)
- **Result file**: プロジェクト内のスコープディレクトリに置く。`/tmp` 等のプロジェクト外パスは使わない

### Auto-Approval Pattern

各 Bash 呼び出しを `tmux` で開始すること。settings.json の `Bash(tmux *)` にマッチし承認不要になる。変数代入 (`SD=... &&`) やコマンド置換 (`P1=$(tmux ...)`) をコマンド先頭に置くとパターン不一致で承認を求められる。パスはインラインで記述する。

### Execute
1. **Prepare**: `$SID` + 目的固有の識別子から channel / result file path を導出する。結果ファイルはスコープディレクトリ内に配置する。
2. **Assign slot**: idle スロットを選択し、`send-keys` でコマンドを投入。各呼び出しは `tmux` で開始する（Auto-Approval Pattern）。
   ```
   tmux send-keys -t {slot_pane_id} '{command}; tmux wait-for -S {channel}' Enter
   ```
3. **Wait for completion**: `tmux wait-for {channel}` (blocking). For parallel dispatch: assign all agents to slots first (step 2), then issue multiple `tmux wait-for` via `Bash(run_in_background=true)` in parallel.
4. **Read result file**.
5. スロットは自動的に idle に戻る。

Overflow (全スロット busy): `Bash(run_in_background=true)` で実行。結果ファイルは同じスコープディレクトリ内。

### Fallback (no tmux)
1. Run command via `Bash()` with appropriate timeout. 結果ファイルは同じスコープディレクトリ内に書き出す。
2. Progress display is lost; result file is still produced.
3. Use `2>/dev/null` to suppress stderr if desired.

## Orphan Cleanup

On session resume (when `$TMUX` set):

1. List Panes, Grep for `sdd-` prefix のタイトルを持つペインを列挙
2. 各タイトルから SID を抽出 (`sdd-{SID}-...` の `{SID}` 部分)
3. 抽出した SID ごとに `%{SID}` ペイン (= Lead) が現存するか確認
4. 存在しない → 前セッションの孤児ペイン (slot + server 含む)。存在する → 別のアクティブセッション → skip
5. 孤児ペインが見つかった場合、**ユーザーに確認**: 「{N} 個の孤児ペインが見つかりました (前セッション SID: {SID})。kill しますか？」
6. ユーザーが承認 → Kill Pane。拒否 → skip
