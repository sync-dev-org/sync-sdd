# tmux Integration Patterns

Reusable tmux patterns for Lead orchestration. Lead reads this file on-demand when entering a tmux-involving code path.

## Prerequisites

- Check `$TMUX` is set before using any pattern. If not set, use the documented background mode alternative.
- All pane targeting uses **pane ID** (`%N` format). **Never use index-based targeting** (`-t 1`) — it may kill the wrong pane (including Claude Code itself).

### Session ID (`$SID`)

同一 tmux サーバー内で複数の sync-sdd セッション（別リポジトリ or 同一リポジトリ）が並行する場合にチャネル名の衝突を防止する。

**生成**: `/sdd-start` Step 7 で `date +%H%M%S` を実行し、出力をそのまま `$SID` とする (例: `104817`)。セッション（プロセス）ごとに一意な値となる。pane ID ベースだと同一 pane での再起動時に前セッションと衝突するため、時刻ベースを使用する。

**永続化**: SID、window_id、全 pane ID は `{{SDD_DIR}}/session/state.yaml` に記録される。`window_id` は grid が存在するウィンドウを特定するために使用する（orphan 検出・grid 再利用のスコープ制御）。pane タイトルは装飾用 (best-effort) であり、ロジックの依存先ではない。Claude Code は TUI/print 両モードで pane タイトルを上書きするため、タイトルに依存してはならない。

**Lead pane タイトル**: SID 生成直後に `tmux select-pane -T 'sdd-{SID}-lead'` を実行 (best-effort)。Claude Code により上書きされるが、tmux UX のために設定する。

**命名規則**: `sdd-{SID}-{purpose}-{identifier}` (例: `sdd-104817-devserver-auth`, `sdd-104817-slot-3`)

## Shared Operations

### List Panes

**Lead からの直接実行は `#{}` ヒューリスティクス誤検出のため不可。** `orphan-detect.sh` 等のヘルパースクリプト経由で実行する。スクリプト内での構文:
```
tmux list-panes -F '#{pane_title} #{pane_id}'
```
Current window only (default). Use `-t @{window_id}` to target a specific window. `-a` (all windows/sessions) は誤スコープの原因になるため原則使わない。

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

4 象限ベース (2 列 × 2 行)。Lead が左上象限を占有し、残り 3 象限を田の字 (2×2) に細分化して agent スロットに割り当てる。

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

| 項目 | 値 |
|---|---|
| Lead サイズ | 120w × 32h |
| Slot サイズ | 60w × 16h |
| Max slots | 12 |

**Max Lead: 1**。2 Lead 以上は MultiView なしで動作（全 agent が `run_in_background` フォールバック）。

### Grid Creation

**Grid の作成・再作成は `/sdd-start` の専任。** 他のスキル (sdd-review, sdd-review-self 等) は Grid を「使うだけ」であり、再作成してはならない — busy slot で実行中のプロセスを破壊する危険がある。slot 不足時は生存 idle slot + `Bash(run_in_background=true)` フォールバックで対応する。

`/sdd-start` Step 7 で `$SID` 生成・Lead pane タイトル設定後に実行。

**一括作成スクリプト**:
```
bash .sdd/settings/scripts/multiview-grid.sh $SID $MY_PANE
```
出力: 先頭行 `window_id:{id}` + 続く 12 行 `slot-{N}:{pane_id}` (N = 1-12)。Lead はこの出力を parse して window_id とスロット管理テーブルを構築する。

**スクリプトの処理手順** (参考):
1. **4 象限分割**: Lead pane を `-v -p 50` (上下) → Lead | BOTTOM。Lead を `-h -p 50` (左右) → Lead | RIGHT
2. **TR 象限 (S1-S4)**: RIGHT を `-v -p 50` → TR_TOP | TR_BOT。各行を `-h -p 50` で 2 分割
3. **BL/BR 象限 (S5-S12)**: BOTTOM を `-v -p 50` → BL_TOP | BL_BOT。各行を `-h -p 50` で左右分割し BL/BR を形成。各セルをさらに `-h -p 50` で 2 分割
4. **タイトル設定**: Lead pane → `sdd-{SID}-lead`、全スロット pane → `sdd-{SID}-slot-{N}` (N = 1-12)

全スロットは idle shell 状態で待機。Grid Creation 完了後、Lead はスロット一覧 `{slot_number, pane_id, status: idle}` を保持する。

**検証済み寸法** (240w × 65h terminal): Lead 120w × 32h, Slots 60w × 16h。

### Slot Management

| 操作 | 方法 |
|------|------|
| **Assign** | `tmux send-keys -t {pane_id} '{command}; tmux wait-for -S {channel}' Enter` |
| **Wait** | `tmux wait-for {channel}` (blocking) |
| **Release** | 自動 — コマンド完了後 shell が idle に戻る |
| **Reuse** | idle スロットを次の agent に割り当て |
| **Overflow** | 12 slots 全て busy → `Bash(run_in_background=true)` にフォールバック |

Lead はスロット状態を `{{SDD_DIR}}/session/state.yaml` の `grid` セクションで追跡。`grid.window_id` は grid が存在するウィンドウを示す。slot assign 時に status → busy + 用途に応じた属性 (Pattern B: agent/engine/channel, Pattern A: agent/url) を記入、release 時に status → idle に戻し追加属性を除去する。

### Hold-and-Release

複数 agent を完了後に一斉解放するパターン。全 Agent の結果を確認してから次に進みたい場合に使う。

**Command chain** (send-keys で投入):
```
{command}; tmux wait-for -S {channel}; tmux wait-for {close-channel}
```
- `{channel}`: Agent 固有の完了シグナル (e.g., `sdd-{SID}-ext-1-B{seq}`)
- `{close-channel}`: 全 Agent 共有の解放シグナル (e.g., `sdd-{SID}-close-B{seq}`)

**Lead flow**:
1. 全 Agent の完了シグナルを待つ
2. 結果ファイルを読む
3. `tmux wait-for -S {close-channel}` → 全 pane のブロック解除
4. Agent command chain 完了 → shell が idle に戻る（スロット再利用可能）

## Pattern A: Server Lifecycle

Long-running server in a MultiView スロットで実行。readiness polling 付き。Used for dev servers during web inspector reviews.

### Start
1. **Check for existing server**: `{{SDD_DIR}}/session/state.yaml` の `grid` セクションで `agent: {purpose}-*` の slot を検索。見つかった場合、そのサーバーを再利用 (retry 時にサーバーが前回から動いたまま)。`url` フィールドからサーバー URL を取得。
2. **Port offset** (parallel instances): state.yaml で他の `agent: {purpose}-*` slot が存在する場合、その `url` フィールドからポート番号を取得し `--port {base+N}` を適用。Skip if the server framework does not support port override.
3. **Assign slot**: idle スロットを選択し、`send-keys` でサーバーコマンドを投入。`{{SDD_DIR}}/session/state.yaml` の該当 slot を更新:
   ```yaml
   status: busy
   agent: "{purpose}-{identifier}"
   url: "http://localhost:{port}"
   ```
4. **Poll readiness**: Capture Pane Output, Grep for ready pattern (`ready`, `localhost`, `listening on`). Max 30 seconds, check every 2 seconds.

### Stop
1. `tmux send-keys -t {pane_id} C-c` でサーバー停止
2. `{{SDD_DIR}}/session/state.yaml` の該当 slot を `status: idle` に更新し、`agent`/`url` を除去。

### Background Mode (no tmux)
1. Start server via `Bash(run_in_background=true)`. Record PID.
2. Poll URL for readiness (retry access with brief delays, max 30 seconds).
3. Stop by killing PID.

## Pattern B: One-Shot Command

External CLI runs in a MultiView スロットで実行。native progress display 付き、result captured via file. Used for external tool execution (e.g., external engines).

### Naming

複数インスタンスが並行する場合、以下を一意にする:
- **Wait-for channel**: `sdd-{SID}-{purpose}-{identifier}-B{seq}` (e.g., `sdd-5-ext-1-B3`)。`-B{seq}` サフィックスは必須 — 再実行時のチャネル衝突を防止する
- **Result file**: プロジェクト内のスコープディレクトリに置く。`/tmp` 等のプロジェクト外パスは使わない

### Auto-Approval Pattern

各 Bash 呼び出しを `tmux` で開始すること。settings.json の `Bash(tmux *)` にマッチし承認不要になる。変数代入 (`SD=... &&`) やコマンド置換 (`P1=$(tmux ...)`) をコマンド先頭に置くとパターン不一致で承認を求められる。パスはインラインで記述する。

### Execute
1. **Prepare**: `$SID` + 目的固有の識別子から channel / result file path を導出する。結果ファイルはスコープディレクトリ内に配置する。
2. **Assign slot**: idle スロットを選択し、`send-keys` でコマンドを投入。各呼び出しは `tmux` で開始する（Auto-Approval Pattern）。
   ```
   tmux send-keys -t {slot_pane_id} '{command}; tmux wait-for -S {channel}' Enter
   ```
3. **Wait for completion**: `tmux wait-for {channel}` (blocking). For parallel dispatch: assign all agents to slots first (step 2), then issue parallel `Bash(run_in_background=true)` for each `tmux wait-for`.
   - **Staggered Parallel Dispatch**: 複数の `send-keys` や `wait-for` を発行する場合、sleep プレフィックスで 0.5 秒刻みにずらし、単一メッセージの並列 Bash 呼び出しで一括発行する（Lead のターン消費 1 回）:
     ```
     Bash(run_in_background=true): sleep 0.0; tmux send-keys -t {pane1} '...' Enter
     Bash(run_in_background=true): sleep 0.5; tmux send-keys -t {pane2} '...' Enter
     Bash(run_in_background=true): sleep 1.0; tmux send-keys -t {pane3} '...' Enter
     ```
     tmux は短時間のコマンド連発で詰まることがあるため、stagger が必要。逐次発行 (send-keys → sleep → send-keys) はターンを浪費するので使わない。
   - **Notification-based completion**: 各 `Bash(run_in_background=true)` の完了は task-notification で個別に検知する。TaskOutput は使わない（#14055 Race Condition 回避 + Lead 非ブロック）。
4. **Read result file**.
5. スロットは自動的に idle に戻る。

Overflow (全スロット busy): `Bash(run_in_background=true)` で実行。結果ファイルは同じスコープディレクトリ内。

### Template Variable Expansion in send-keys

send-keys 内のコマンドは pane のシェルで実行されるため、Claude Code のセキュリティヒューリスティクス (`$()` / `${}` 禁止) は適用されない。テンプレートファイルのプレースホルダーを動的値で置換して外部エンジンに渡す場合、2つの方式がある:

**方式 A: sed ワンライナー** — 値が単一行のとき最も効率的 (Lead の Read/Write ゼロ)
```
tmux send-keys -t {pane} 'sed "s|{{PLACEHOLDER}}|{value}|g" template.md | cat shared.md - | ENGINE_CMD; tmux wait-for -S {channel}' Enter
```
- BSD sed (macOS) の `s` コマンドは置換文字列に literal newline を入れられない。**値が単一行の場合のみ使用可**
- 区切り文字は `|` を使用（値に `/` が含まれうるため）

**方式 B: Briefer 展開** — 値が複数行、または複数テンプレートに同じ値を展開するとき
1. Briefer がテンプレートを読み込み、プレースホルダーを展開して `active/` に書き出す
2. Lead の dispatch は全 Inspector 同一パターン: `cat shared active/inspector-{name}.md | ENGINE_CMD`
3. sed 分岐・改行判定ロジックが不要になり、dispatch が大幅に簡素化される

sdd-review-self は方式 B を採用 (v2.1.2)。方式 A は値が常に単一行であることが保証できるケースで有用。

### Background Mode (no tmux)
1. Run command via `Bash()` with appropriate timeout. 結果ファイルは同じスコープディレクトリ内に書き出す。
2. Progress display is lost; result file is still produced.
3. Stderr is not suppressed — let errors surface for debugging.

## Orphan Cleanup

`/sdd-start` Step 7 で、SID 生成・Lead タイトル設定の**後**、Grid Creation の**前**に実行する。

**Primary (state.yaml ベース)**:
1. `{{SDD_DIR}}/session/state.yaml` を読む (`old_sid`, `grid.window_id`, 全 pane_id を取得)
2. `bash {{SDD_DIR}}/settings/scripts/orphan-detect.sh primary {window_id} {MY_PANE} {pane_ids...}` を実行。スクリプトは grid の window_id をスコープとして pane 存在確認し、live orphan の pane_id を出力する（`$MY_PANE` は除外済み、window が存在しない場合は空出力）
3. orphan が見つかった場合、**ユーザーに確認**: 「前セッション (SID: {old_sid}) の {N} 個の pane が Window {window_id} に残っています。kill しますか？」
4. ユーザーが承認 → Kill Pane。拒否 → skip

**Fallback (state.yaml なし)**: タイトルベースで検出。`bash {{SDD_DIR}}/settings/scripts/orphan-detect.sh fallback {MY_PANE} {SID}` を実行。current window の pane で `sdd-` prefix タイトルを持ち、SID が現在と異なるものを出力する (`{pane_id} {title}` 形式)。
