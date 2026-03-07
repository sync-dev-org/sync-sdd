---
description: "Self-review for SDD framework development (framework-internal use only)"
argument-hint: "[--briefer-engine <name>] [--briefer-model <name>] [--briefer-effort <level>] [--inspector-engine <name>] [--inspector-model <name>] [--inspector-effort <level>] [--auditor-engine <name>] [--auditor-model <name>] [--auditor-effort <level>] [--builder-engine <name>] [--builder-model <name>] [--builder-effort <level>] [--timeout <seconds>]"
allowed-tools: Bash, Read, Glob, Grep, Write, Agent
---

# SDD Framework Self-Review

<instructions>

## Purpose

**sync-sdd フレームワーク開発リポ専用。** 通常リポでは実行不可（`framework/` ディレクトリが存在しないため NO_CHANGES で停止する）。

外部エンジン (Codex CLI / Claude Code headless / Gemini CLI) または SubAgent (Claude Code Agent tool) を使った self-review スキル。3 固定 Inspector + 1-4 動的 Inspector を並行実行し、Auditor が統合する。Lead は Inspector findings を読まない — Auditor の verdict-auditor.yaml のみを監修する。承認された修正は Builder (外部 CLI / SubAgent) が実行し、Lead はコンテキスト保全と監修に専念する。

動的 Inspector は Briefer が変更内容を分析し、固定 Inspector ではカバーしきれないリスク軸に対して焦点プロンプトを生成する。

## Step 1: Load Engine Config

### 1a Parse Arguments

引数からオーバーライドを抽出:

- `--briefer-engine <name>` / `--briefer-model <name>` / `--briefer-effort <level>`: Briefer
- `--inspector-engine <name>` / `--inspector-model <name>` / `--inspector-effort <level>`: Inspector ×3
- `--auditor-engine <name>` / `--auditor-model <name>` / `--auditor-effort <level>`: Auditor
- `--builder-engine <name>` / `--builder-model <name>` / `--builder-effort <level>`: Builder (A items fix)
- `--timeout <seconds>`: タイムアウト秒数

引数なし → engines.yaml の level chain デフォルトを使用。引数あり → デフォルト値を上書き。

例:
- Auditor のみ変更: `/sdd-review-self --auditor-engine claude --auditor-model claude-opus-4-6`
- 全ステージ SubAgent: `/sdd-review-self --briefer-engine subagents --inspector-engine subagents --auditor-engine subagents`
- Inspector の effort のみ変更: `/sdd-review-self --inspector-effort high`

### 1b Load engines.yaml

1. Read `.sdd/settings/engines.yaml`
   - If absent: all stages fallback to `subagents`, `$DENY_PATTERNS` = empty
2. Load `deny_patterns` → `$DENY_PATTERNS`

### 1c Resolve Final Config

**Level chain 解決** (各ステージ独立):

1. 各ステージの `start_level` を `roles.review-self.stages.{stage}.start_level` から取得
2. `levels.{start_level}` から `engine`, `model`, `effort` を取得 → ステージのデフォルト値
3. Skill 引数でオーバーライド (引数 > level chain):

| Stage Variable | Resolution (高→低) |
|---------------|-----------|
| `$BRIEFER_ENGINE` / `$BRIEFER_MODEL` / `$BRIEFER_EFFORT` | `--briefer-{engine,model,effort}` → `levels.{start_level}.{engine,model,effort}` |
| `$INSPECTOR_ENGINE` / `$INSPECTOR_MODEL` / `$INSPECTOR_EFFORT` | `--inspector-{engine,model,effort}` → `levels.{start_level}.{engine,model,effort}` |
| `$AUDITOR_ENGINE` / `$AUDITOR_MODEL` / `$AUDITOR_EFFORT` | `--auditor-{engine,model,effort}` → `levels.{start_level}.{engine,model,effort}` |
| `$BUILDER_ENGINE` / `$BUILDER_MODEL` / `$BUILDER_EFFORT` | `--builder-{engine,model,effort}` → `levels.{start_level}.{engine,model,effort}` |

**共通設定**:

| Variable | Resolution |
|----------|-----------|
| `$TIMEOUT` | `--timeout` → `roles.review-self.timeout` → 900 (hardcoded) |
| `$TOOLS` | `roles.review-self.tools` → null (full permission) |

4. 各ステージの engine について `engines.{engine}.install_check` を実行して可用性を確認
   - `install_check` 失敗 → level chain で次の level へ自動エスカレート。最終的に L0 (subagents) にフォールバック。Report: `{stage}: {engine} not available, escalating to L{N}`
   - claude エンジン使用時: `jq --version` で jq の可用性も確認。不在 → Report: `jq not available (required for claude engine streaming). Install: brew install jq / apt install jq` → 次 level へ
5. Build per-stage `$ENGINE_CMD` using Engine-Specific Command Construction (Step 4) with the resolved engine/model/effort

5. Set scope and template directories:

```
$SCOPE_DIR = .sdd/project/reviews/self
$TPL = .sdd/settings/templates/review-self
```

6. Determine `$BATCH_SEQ`: Read `$SCOPE_DIR/verdicts.yaml`, find max `batches[].seq` → `$BATCH_SEQ` = max+1. If absent → 1. This is used for tmux channel names to prevent cross-batch collisions.

6. Report resolved config:
```
Timeout: {$TIMEOUT}s
  Briefer: {$BRIEFER_ENGINE} [{$BRIEFER_MODEL}] effort:{$BRIEFER_EFFORT}
  Inspectors: {$INSPECTOR_ENGINE} [{$INSPECTOR_MODEL}] effort:{$INSPECTOR_EFFORT}
  Auditor: {$AUDITOR_ENGINE} [{$AUDITOR_MODEL}] effort:{$AUDITOR_EFFORT}
  Builder: {$BUILDER_ENGINE} [{$BUILDER_MODEL}] effort:{$BUILDER_EFFORT}
```
全ステージが同一 engine/model/effort の場合、1 行にまとめてもよい。

## Step 2: Prompt Construction (Briefer)

Prompt Construction は Briefer に委譲する。Lead は dispatch と成否確認のみ。

### Briefer Dispatch

1. `rm -rf $SCOPE_DIR/active; mkdir -p $SCOPE_DIR/active`
2. Briefer を dispatch:
   **SubAgent mode** (`$BRIEFER_ENGINE == "subagents"`):
   `Agent(subagent_type="general-purpose", description="Briefer for self-review", run_in_background=true, prompt="Read .sdd/settings/templates/review-self/briefer.md and execute the instructions.")`
   task-notification で完了を検知。
   **tmux mode** (`$TMUX` 設定あり):
   idle slot を選択し、`{{SDD_DIR}}/session/state.yaml` の該当 slot を `status: busy` + `agent: briefer`/`engine`/`channel` に更新。pane タイトルを更新: `tmux select-pane -t {pane_id} -T "review-self/briefer | {$BRIEFER_MODEL}"`。完了後は `status: idle` に戻し、`agent`/`engine`/`channel` を除去。pane タイトルをリセット: `tmux select-pane -t {pane_id} -T "sdd-{SID}-slot-{N}"`
   ```
   tmux send-keys -t {slot_pane_id} 'cat {$TPL}/briefer.md | {$BRIEFER_ENGINE_CMD}; tmux wait-for -S sdd-{SID}-review-self-briefer-B{seq}' Enter
   ```
   ユーザーに報告: `Briefer dispatched to slot-{N} ({pane_id})`
   send-keys ゾンビ確認: `pgrep -fl "tmux send-keys"` → 検出時はユーザーに報告し kill (exit code 1 = ゾンビなし、正常)
   `Bash(run_in_background=true)` で `tmux wait-for sdd-{SID}-review-self-briefer-B{seq}` を実行。task-notification で完了を検知。
   **background mode** (上記以外):
   `Bash(run_in_background=true)` で `cat $TPL/briefer.md | $BRIEFER_ENGINE_CMD` を実行。task-notification で完了を検知。
3. 完了後の検証:
   - `$SCOPE_DIR/active/briefer-status.md` が `NO_CHANGES` → "No changes since last review." を報告して停止
   - 固定 Inspector: `$SCOPE_DIR/active/shared-prompt.md` と `$SCOPE_DIR/active/inspector-{flow,consistency,compliance}.md` (3ファイル) の存在を確認
   - 動的 Inspector: `$SCOPE_DIR/active/dynamic-manifest.md` を Read し `DYNAMIC_COUNT:{N}` を取得。N >= 1 を確認。各 `$SCOPE_DIR/active/inspector-dynamic-{N}-{slug}.md` の存在を確認
   - いずれか欠損 → Briefer 失敗。SubAgent フォールバック (下記) を試行
4. `$DYNAMIC_COUNT` と動的 Inspector 名リスト (manifest から) を保持
5. **ユーザーに dispatch 一覧を報告**: fixed + dynamic 全 Inspector の名前と focus をテーブル形式で表示してから Step 3 へ進む

### Briefer Failure Handling

Briefer (外部エンジン) が失敗した場合 (出力ファイル不在):
1. **Failure Log Capture** (Runtime Escalation Protocol 参照) を実行
2. Runtime Escalation Protocol に従いエスカレーション dispatch
3. 最終 fallback (L0 subagents) も失敗 → "Briefer failed. Cannot proceed." を報告して停止

Briefer の SubAgent dispatch:
`Agent(subagent_type="general-purpose", description="Briefer fallback", run_in_background=true, prompt="Read .sdd/settings/templates/review-self/briefer.md and execute the instructions.")`

`$BRIEFER_ENGINE == "subagents"` (L0) の場合はフォールバック先がないため、失敗時は即停止。

## Step 3: Grid Setup (tmux mode only)

全ステージが subagents の場合はこのステップをスキップ（Agent ツール dispatch に tmux 不要）。
判定: `$BRIEFER_ENGINE == "subagents" && $INSPECTOR_ENGINE == "subagents" && $AUDITOR_ENGINE == "subagents"`

`$TMUX` が設定されている場合のみ実行:
1. `printenv TMUX_PANE` → `$MY_PANE` (avoid `tmux display-message -p '#{pane_id}'` — `#{}` triggers security heuristic)
2. SID + Grid 取得: `{{SDD_DIR}}/session/state.yaml` を Read し、`sid` と `grid` セクション (`window_id`, slot pane_ids) から `$SID` と slot pane ID を取得。state.yaml が存在しない場合 → tmux mode を諦め、全 agent を `Bash(run_in_background=true)` で実行 (background fallback)。
3. Grid 検証: `bash {{SDD_DIR}}/settings/scripts/grid-check.sh {grid.window_id} {all_slot_pane_ids}` — stdout に生存 pane_id を出力、exit 0 = 全 slot 生存, exit 1 = 一部消滅。一部消滅の場合、**Grid を再作成しない** (busy slot で実行中のプロセスを破壊する危険があるため)。idle slot 確定手順: (1) grid-check.sh stdout から生存 pane_id セットを取得 (2) state.yaml の各 slot で `status: idle` のものを抽出 (3) 両者の交差 = 使用可能 idle slot。不足分は `Bash(run_in_background=true)` にフォールバック。

`$TMUX` 未設定の場合はスキップして Step 4 background mode へ。

## Step 4: Parallel Dispatch (3 Fixed + N Dynamic Inspectors)

Apply **One-Shot Command pattern** from `{{SDD_DIR}}/settings/rules/tmux-integration.md`.

3 固定 + N 動的 (N=1-4) = 4-7 Inspector を並行起動する (外部エンジンまたは SubAgent)。

**固定 Inspector** (inspector-flow, inspector-consistency, inspector-compliance):
- Channel = `sdd-{SID}-review-self-{N}-B{seq}` (`$SID` は Step 3 で取得したセッション固有 ID)
- Prompt = `$SCOPE_DIR/active/shared-prompt.md` + `$SCOPE_DIR/active/inspector-{name}.md` (Briefer が展開済み)
- Findings file (成果物) = `$SCOPE_DIR/active/findings-inspector-{name}.yaml`

**動的 Inspector** (inspector-dynamic-{N}-{slug}):
- Channel = `sdd-{SID}-review-self-d{N}-B{seq}` (d prefix で固定と区別)
- Prompt = `$SCOPE_DIR/active/shared-prompt.md` + `$SCOPE_DIR/active/inspector-dynamic-{N}-{slug}.md` (Briefer が生成)
- Findings file (成果物) = `$SCOPE_DIR/active/findings-inspector-dynamic-{N}-{slug}.yaml`

### Engine-Specific Command Construction

Assemble command based on the resolved engine for each stage (`$BRIEFER_ENGINE`, `$INSPECTOR_ENGINE`, `$AUDITOR_ENGINE`). `$TOOLS` が null の場合は全許可モード、設定されている場合はツール制限モード:

全エンジン共通: stdout はリダイレクトしない — pane に応答テキスト / 進捗が流れる。成果物は findings YAML ファイルのみ。完了は task-notification で検出し、成功判定は findings YAML ファイル存在チェックで行う。

各ステージの engine に応じて `${STAGE}_ENGINE_CMD` を組み立てる (例: `$BRIEFER_ENGINE_CMD`, `$INSPECTOR_ENGINE_CMD`, `$AUDITOR_ENGINE_CMD`)。send-keys では Briefer が `active/` に書き出した展開済みファイルを使い、`cat {shared} {active/inspector-{name}.md} | ${STAGE}_ENGINE_CMD` の形でプロンプトを stdin に渡す。

以下 `${STAGE}_MODEL` / `${STAGE}_EFFORT` はそのステージの resolved model / effort。

**codex**:
```
npx -y @openai/codex exec --full-auto [--model ${STAGE}_MODEL] [-c model_reasoning_effort='"${STAGE}_EFFORT"'] -
```

**claude** (`env -u CLAUDECODE` で Lead セッションからのネスト検出を回避):
```
env -u CLAUDECODE CLAUDE_CODE_EFFORT_LEVEL=${STAGE}_EFFORT claude -p - --dangerously-skip-permissions --output-format stream-json --verbose --include-partial-messages [--model ${STAGE}_MODEL] | jq -rjf .sdd/settings/scripts/claude-stream-progress.jq
```
ツール制限時: `--dangerously-skip-permissions` を `--allowedTools "$TOOLS"` に置換。
`jq` が必要 (`brew install jq` / `apt install jq`)。
進捗表示: ツール名・引数・テキスト応答・コスト/所要時間を pane にリアルタイム表示。

**gemini** (effort 非対応 — 設定ファイル書き換え必須のため除外):
```
npx -y @google/gemini-cli -p "Review the project files per the instructions below." --yolo [--model ${STAGE}_MODEL]
```
ツール制限時: `--yolo` を `--sandbox` に置換。

`[]` 内は対応する値が設定されている場合のみ付与。

**subagents**: CLI command は不要。Agent ツール (`Agent(subagent_type="general-purpose")`) で dispatch する。
プロンプトにファイルパスを指示し、SubAgent が自分で Read する（Lead は Read 不要）。
Model mapping (engines.yaml の model 値 → Agent tool `model` パラメータ):
- `*spark*` or `*haiku*` を含む → `"haiku"`
- `*opus*` を含む → `"opus"`
- その他 → `"sonnet"` (デフォルト)
Effort mapping (subagents): effort=`high` → プロンプト先頭に `ultrathink` を追加。effort=`medium` → 追加なし。

### Dispatch Mode

分岐順序: SubAgent → tmux → background (Briefer/Auditor と統一)。

**SubAgent mode** (`$INSPECTOR_ENGINE == "subagents"`):
Agent ツールで dispatch。`$TMUX` の有無に関わらずこのモードを使用。Bash 呼び出しゼロ。

固定 Inspector の dispatch:
`Agent(subagent_type="general-purpose", description="{name} review", model=$INSPECTOR_MODEL_MAPPED, run_in_background=true, prompt="Read .sdd/project/reviews/self/active/shared-prompt.md and .sdd/project/reviews/self/active/inspector-{name}.md, then execute the instructions.")`

動的 Inspector の dispatch:
`Agent(subagent_type="general-purpose", description="{slug} review", model=$INSPECTOR_MODEL_MAPPED, run_in_background=true, prompt="Read .sdd/project/reviews/self/active/shared-prompt.md and .sdd/project/reviews/self/active/inspector-dynamic-{N}-{slug}.md, then execute the instructions.")`

全 Agent (3 固定 + N 動的) を一括 dispatch (単一メッセージで並列発行)。

各 Agent の task-notification で完了を検知。findings YAML ファイル存在チェックは外部エンジンと同一。

Hold-and-Release は不要 — Agent は完了時に自動的にリソースを解放する。

**tmux mode** (`$INSPECTOR_ENGINE != "subagents"` かつ `$TMUX` 設定あり):
各 Bash 呼び出しを `tmux` で開始することで `Bash(tmux *)` パターンにマッチさせ、承認を不要にする。

MultiView スロットに `send-keys` で agent コマンドを投入する (Hold-and-Release パターン)。idle スロットから (3+N) 個選択し、`{{SDD_DIR}}/session/state.yaml` の該当 slot を `status: busy` + `agent`/`engine`/`channel` に更新。pane タイトルを更新: `tmux select-pane -t {pane_id} -T "review-self/{inspector-name} | {$INSPECTOR_MODEL}"`。各 Agent の command chain を投入:

固定 Agent パターン (Briefer が `active/` に展開済みファイルを書き出し済み):
```
tmux send-keys -t {slot_pane_id} 'cat {shared} {active/inspector-{name}.md} | {$INSPECTOR_ENGINE_CMD}; tmux wait-for -S sdd-{SID}-review-self-{N}-B{seq}; tmux wait-for sdd-{SID}-close-B{seq}' Enter
```

動的 Agent パターン:
```
tmux send-keys -t {slot_pane_id} 'cat {shared} {active/inspector-dynamic-N-slug.md} | {$INSPECTOR_ENGINE_CMD}; tmux wait-for -S sdd-{SID}-review-self-d{N}-B{seq}; tmux wait-for sdd-{SID}-close-B{seq}' Enter
```

**tmux throttle**: 全 Agent の send-keys を staggered parallel dispatch で一括発行する。各コマンドに sleep プレフィックスを付けて 0.5 秒刻みでずらし、単一メッセージの並列 Bash 呼び出しで発行する（Lead のターン消費は 1 回）:
```
Bash(run_in_background=true): sleep 0.0; tmux send-keys -t {pane1} '...' Enter
Bash(run_in_background=true): sleep 0.5; tmux send-keys -t {pane2} '...' Enter
...
```

dispatch 後、ユーザーにスロット割り当てを報告:
```
Dispatched {N} inspectors to tmux slots:
  slot-{N} ({pane_id}): {agent-name}
  ...
```

全 Agent 分の send-keys 完了後:
1. send-keys ゾンビ確認: `pgrep -fl "tmux send-keys"` → 検出時はユーザーに報告し kill (exit code 1 = ゾンビなし、正常)
2. 固定 + 動的の全チャネルの `tmux wait-for` を `Bash(run_in_background=true)` で並行発行:
```
Bash(run_in_background=true): tmux wait-for sdd-{SID}-review-self-1-B{seq}
Bash(run_in_background=true): tmux wait-for sdd-{SID}-review-self-2-B{seq}
Bash(run_in_background=true): tmux wait-for sdd-{SID}-review-self-3-B{seq}
Bash(run_in_background=true): tmux wait-for sdd-{SID}-review-self-d1-B{seq}
... (動的 Inspector の数だけ追加)
```
各 task-notification で個別に完了を検知。全 Agent 完了まで待つ。TaskOutput は使わない。

パスは変数を使わずインラインで記述する（`Bash(tmux *)` マッチのため）。

**background mode** (上記以外):
全 Inspector (固定 + 動的) の `cat {shared} {active/inspector-*.md} | {$INSPECTOR_ENGINE_CMD}` を `Bash(run_in_background=true)` で並行実行。各 task-notification で個別に完了を検知。findings YAML はファイル書き出しで取得。

### Inspector Prompts (Templates)

固定 Inspector のプロンプト内容はテンプレートファイルに定義。動的 Inspector のプロンプトは Briefer が変更分析に基づいて生成する:

| Agent | Template | Dispatch-ready file |
|-------|----------|-------------------|
| Briefer | `$TPL/briefer.md` | (Briefer 自身が実行される) |
| Flow Integrity | `$TPL/inspector-flow.md` | `active/inspector-flow.md` |
| Consistency | `$TPL/inspector-consistency.md` | `active/inspector-consistency.md` |
| Compliance | `$TPL/inspector-compliance.md` | `active/inspector-compliance.md` |
| Dynamic 1-4 | (Briefer が動的生成) | `active/inspector-dynamic-{N}-{slug}.md` |
| Auditor | `$TPL/auditor.md` | (プレースホルダーなし) |
| Builder | `$TPL/builder.md` | (Lead がプレースホルダー展開) |

テンプレートは `.sdd/settings/templates/review-self/` に格納。Briefer が固定 Inspector のテンプレートを読み込み、プレースホルダー (`{{CACHED_OK}}`) を展開して `active/` に書き出す。動的 Inspector のプロンプトは Briefer が変更内容に基づいて `active/` に直接生成する。Lead の dispatch は `active/` のファイルのみ参照する。Auditor テンプレートにはプレースホルダーがないため、パス指示のみで dispatch する。

---

## Step 5: Collect Results

全 Agent 完了後 (tmux wait-for / background task / SubAgent — いずれも task-notification で検知):

1. 全 Inspector (固定 3 + 動的 N) の findings YAML ファイル存在とファイルサイズを確認 (`ls -la`) → 成功/失敗を判定
   - 固定: `$SCOPE_DIR/active/findings-inspector-{name}.yaml`
   - 動的: `$SCOPE_DIR/active/findings-inspector-dynamic-{N}-{slug}.yaml`
2. **Lead は findings の内容を Read しない**。存在 + サイズ確認のみ（Auditor が読む）
3. 失敗した Agent (findings YAML 不在またはサイズ 0) → Runtime Escalation Protocol を適用。最終失敗はレポートに注記

### Inspector Runtime Escalation

`$INSPECTOR_ENGINE != "subagents"` かつ findings YAML 未生成の Inspector がある場合に発動。

1. 失敗した Inspector のみを対象にリストアップ
2. 各失敗 Inspector について **Failure Log Capture** (Runtime Escalation Protocol 参照) を実行
3. Failure Classification → Escalation Logic に従い次の dispatch 先を決定
4. 失敗 Inspector を新しいレベルで再 dispatch (成功済み Inspector はそのまま)
   - **tmux/background escalation**: 新レベルの Engine-Specific Command で dispatch
   - **SubAgent escalation (L0)**: `Agent(subagent_type="general-purpose", description="{name} escalation", run_in_background=true, prompt="Read .sdd/project/reviews/self/active/shared-prompt.md and .sdd/project/reviews/self/active/inspector-{name}.md, then execute the instructions.")`
5. findings YAML 存在+サイズを再チェック（内容は Read しない）
6. まだ失敗 → 再度 Step 2 から (次レベルへ escalation、L0 到達まで)
7. L0 も失敗 → レポートに注記

`$INSPECTOR_ENGINE == "subagents"` (L0) の場合はフォールバック先がないため、findings YAML 不在は即レポートに注記。

### Health Check (tmux mode, subagents 以外)

`pgrep -fl "tmux send-keys"` でゾンビ send-keys プロセスを確認 (exit code 1 = ゾンビなし、正常)。検出時:
- ユーザーに報告（PID、対象 pane、経過時間）
- ユーザー確認後に `kill {PID}` で除去
- 原因を Error Handling セクションに記録

### Slot Release

SubAgent mode ではスキップ (Agent ツールが自動解放)。tmux mode の場合:
1. `tmux wait-for -S sdd-{SID}-close-B{seq}` → 全 Agent スロットのブロック解除 (Hold-and-Release)
2. command chain 完了後、スロットは idle に戻る（再利用可能）
3. `{{SDD_DIR}}/session/state.yaml` の該当 slot を `status: idle` に更新し、`agent`/`engine`/`channel` を除去。pane タイトルをリセット: `tmux select-pane -t {pane_id} -T "sdd-{SID}-slot-{N}"`

## Step 6: Consolidation (Auditor Agent)

Auditor Agent に統合を委譲する。Lead は dispatch と成否確認のみ。

### Auditor Dispatch

1. Auditor を dispatch:
   **SubAgent mode** (`$AUDITOR_ENGINE == "subagents"`):
   `Agent(subagent_type="general-purpose", description="self-review Auditor", model=$AUDITOR_MODEL_MAPPED, run_in_background=true, prompt="Read .sdd/settings/templates/review-self/auditor.md and execute the instructions.")`
   task-notification で完了を検知。
   **tmux mode** (`$TMUX` 設定あり):
   idle スロットを選択し、`{{SDD_DIR}}/session/state.yaml` の該当 slot を `status: busy` + `agent: auditor`/`engine`/`channel` に更新。pane タイトルを更新: `tmux select-pane -t {pane_id} -T "review-self/auditor | {$AUDITOR_MODEL}"`
   ```
   tmux send-keys -t {slot_pane_id} 'cat {$TPL}/auditor.md | {$AUDITOR_ENGINE_CMD}; tmux wait-for -S sdd-{SID}-review-self-auditor-B{seq}' Enter
   ```
   ユーザーに報告: `Auditor dispatched to slot-{N} ({pane_id})`
   `Bash(run_in_background=true)` で `tmux wait-for sdd-{SID}-review-self-auditor-B{seq}` を実行。task-notification で完了を検知。完了後、state.yaml の該当 slot を `status: idle` に更新し、`agent`/`engine`/`channel` を除去。pane タイトルをリセット: `tmux select-pane -t {pane_id} -T "sdd-{SID}-slot-{N}"`
   **background mode** (上記以外):
   `Bash(run_in_background=true)` で `cat $TPL/auditor.md | $AUDITOR_ENGINE_CMD` を実行。task-notification で完了を検知。
2. 完了後の検証:
   - `$SCOPE_DIR/active/verdict-auditor.yaml` の存在を確認
   - 欠損 → Auditor 失敗。Auditor SubAgent フォールバック (下記) を試行
3. `verdict-auditor.yaml` を Read → Step 7 へ進む

### Auditor Failure Handling

`$AUDITOR_ENGINE != "subagents"` かつ verdict-auditor.yaml が未生成の場合に発動。

1. **Failure Log Capture** (Runtime Escalation Protocol 参照) を実行
2. Runtime Escalation Protocol に従いエスカレーション dispatch
3. SubAgent (L0) の dispatch: `Agent(subagent_type="general-purpose", description="Auditor escalation", run_in_background=true, prompt="Read .sdd/settings/templates/review-self/auditor.md and execute the instructions.")`
4. L0 も失敗 → "Auditor failed. Manual review required." を報告し、findings YAML ファイルパスを列挙して停止

`$AUDITOR_ENGINE == "subagents"` (L0) の場合はフォールバック先がないため、失敗時は即上記メッセージで停止。

## Step 7: Lead Supervision + User Presentation

### 7a Lead 監修

Auditor の `verdict-auditor.yaml` を入力として以下を実行:

1. **FP 判定**: `decisions.yaml` の全エントリと突合。意図的決定 (USER_DECISION, STEERING_EXCEPTION) で説明できる finding → FP。Auditor が見落とした defer/意図的決定を Lead が補完する
2. **Defer 判定**: 過去に defer 済みの finding が再浮上していないか、decisions.yaml の該当エントリを引用して確認
3. **最終分類 (A/B)**: Auditor の classification を検証し、必要に応じて修正
4. **verdict.yaml 作成**: Lead のオーバーライドを反映した最終 verdict を `$SCOPE_DIR/active/verdict.yaml` に書き出す (verdict-format.md の Lead Final Verdict スキーマに準拠)

#### 分類基準

**A) 自明な修正** (Auto-fix):
命名不一致、typo、許可漏れ、example 誤り等、判断不要で正解が一意のもの。

**B) ユーザー判断が必要** (Decision-required):
pre-existing backlog の対処方針、設計レベルの変更、影響範囲が広い修正。
→ 各 finding のフィールドを **すべて埋めて** 提示。「どうしますか？」だけで聞かない。

### 7b ユーザー提示

**提示テンプレートの全フィールドを省略せず出力すること**。要約テーブルへの圧縮は禁止。

```markdown
# SDD Framework Self-Review Report
**Date**: {ISO-8601} | **Engines**: briefer:{$BRIEFER_ENGINE} [{$BRIEFER_MODEL}], insp:{$INSPECTOR_ENGINE} [{$INSPECTOR_MODEL}], aud:{$AUDITOR_ENGINE} [{$AUDITOR_MODEL}], builder:{$BUILDER_ENGINE} [{$BUILDER_MODEL}]
**Agents**: {dispatched} dispatched ({fixed} fixed + {dynamic} dynamic), {completed} completed

## False Positives Eliminated ({N}件)

| # | Finding | Agent | Reason (decisions.yaml ref) |
|---|---------|-------|---------------------------|
| 1 | {概要} | {検出Agent} | {FP理由 — D{seq} 参照 or 実動作確認等} |

## A) 自明な修正 ({N}件) — OK で Builder が修正します

| ID | Sev | Location | Summary | Fix |
|----|-----|----------|---------|-----|
| A1 | {H/M/L} | {file}:{line} | {何が問題か} | {具体的な修正内容} |

## B) ユーザー判断が必要 ({N}件)

### B1: {title}
- **Severity**: {C/H/M/L}
- **Location**: {file}:{line}
- **Description**: {問題の詳細説明}
- **Impact**: {影響範囲 — どこに波及するか、どの程度深刻か}
- **Options**:
  - (a) {選択肢1} — {トレードオフ}
  - (b) {選択肢2} — {トレードオフ}
- **Recommendation**: {推奨する選択肢} — {推奨理由}

## Platform Compliance

| Item | Status | Source |
|------|--------|--------|
| {項目} | {OK/OK (cached)/FP (UNCERTAIN)} | {URL or 確認方法} |
```

### 7c ユーザー判断の受領

ユーザーの回答を待つ:
- **A items**: 全承認 / 個別に却下
- **B items**: 各アイテムに対して approve / defer / reject

却下 (reject) されたアイテムはユーザー確認済み FP として扱う。defer されたアイテムは tracked に追加。

## Step 8: Builder Fix Dispatch

承認されたアイテム (A approved + B approved) が 0 件 → Step 9 へスキップ。

### 8a プロンプト構築

1. 承認済みアイテムを YAML 形式のリストに整形:
   ```yaml
   - id: "A1"
     location: "{file}:{line}"
     description: "{what}"
     fix: "{recommended fix}"
   ```
2. `$TPL/builder.md` を Read し、プレースホルダーを展開:
   - `{{DENY_PATTERNS}}` → `$DENY_PATTERNS`
   - `{{FINDINGS}}` → 上記整形済みリスト
   - `{{TEST_CMD}}` → "none" (sync-sdd フレームワークにはテストスイートがないため)
   - `{{OUTPUT_PATH}}` → `$SCOPE_DIR/active/builder-report.yaml`

### 8b Builder Dispatch

分岐順序: SubAgent → tmux → background (他ステージと統一)。

**SubAgent mode** (`$BUILDER_ENGINE == "subagents"`):
`Agent(subagent_type="general-purpose", description="Builder fix", model=$BUILDER_MODEL_MAPPED, run_in_background=true, prompt="{展開済みプロンプト}")`
task-notification で完了を検知。

**tmux mode** (`$BUILDER_ENGINE != "subagents"` かつ `$TMUX` 設定あり):
idle slot を選択し、`{{SDD_DIR}}/session/state.yaml` の該当 slot を `status: busy` + `agent: builder`/`engine`/`channel` に更新。pane タイトルを更新: `tmux select-pane -t {pane_id} -T "review-self/builder | {$BUILDER_MODEL}"`
```
tmux send-keys -t {slot_pane_id} 'cat {展開済みプロンプトファイル} | {$BUILDER_ENGINE_CMD}; tmux wait-for -S sdd-{SID}-review-self-builder-B{seq}' Enter
```
`Bash(run_in_background=true)` で `tmux wait-for sdd-{SID}-review-self-builder-B{seq}` を実行。task-notification で完了を検知。完了後、slot を idle に戻し、`agent`/`engine`/`channel`/`url` を除去。pane タイトルをリセット: `tmux select-pane -t {pane_id} -T "sdd-{SID}-slot-{N}"`

**background mode** (上記以外):
`Bash(run_in_background=true)` で `cat {展開済みプロンプトファイル} | $BUILDER_ENGINE_CMD` を実行。

### 8c Builder 結果確認

1. `$SCOPE_DIR/active/builder-report.yaml` の存在を確認
2. Read して結果を検証:
   - `status: complete` → 全アイテム修正成功
   - `status: partial` → 一部スキップあり — スキップ理由を確認
3. report の `diff_summary` で変更ファイル一覧と変更量を確認。疑わしい変更がある場合のみ `git diff {file}` で詳細確認
4. ユーザーに Builder 結果を報告:
   ```
   Builder fix complete: {N}/{total} items fixed
   Skipped: {list with reasons, if any}
   Files modified: {list}
   ```
5. Builder 失敗時 (report.yaml 不在) → Builder SubAgent フォールバック (下記)

### Builder Failure Handling

`$BUILDER_ENGINE != "subagents"` かつ builder-report.yaml 未生成の場合に発動。

1. **Failure Log Capture** (Runtime Escalation Protocol 参照) を実行
2. Runtime Escalation Protocol に従いエスカレーション dispatch
3. SubAgent (L0) の dispatch: `Agent(subagent_type="general-purpose", description="Builder fix escalation", run_in_background=true, prompt="{同じ展開済みプロンプト}")`
4. L0 も失敗 → "Builder fix failed. Manual fix required." を報告し、承認済みアイテムリストを表示

`$BUILDER_ENGINE == "subagents"` (L0) の場合はフォールバック先がないため、失敗時は即上記メッセージ。

## Step 9: Verdict Persistence

### 9a Persist Results

1. B{seq} を決定: `$SCOPE_DIR/verdicts.yaml` の最大 `seq` + 1。ファイル不在 → 1
2. `$SCOPE_DIR/active/verdict.yaml` から severity counts, files, disposition を読む
3. `$SCOPE_DIR/verdicts.yaml` に batch エントリを append (verdict-format.md §4 Verdict Index スキーマ準拠):
   ```yaml
   - seq: {N}
     type: "self"
     scope: "framework"
     date: "{ISO-8601}"              # date +%Y-%m-%dT%H:%M:%S%z
     version: "{version}"            # .sdd/.version
     engines:
       briefer: "{model}"
       inspectors: "{model}"
       auditor: "{model}"
       builder: "{model}"            # optional — omit if no Builder fixes
     agents:
       fixed: {N}
       dynamic: {N}
       total: {N}
     counts:
       C: {n}
       H: {n}
       M: {n}
       L: {n}
       FP: {n}
     verdict: "{verdict}"
     disposition: "{disposition}"
     tracked: [...]                  # optional — deferred items
     resolved: [...]                 # optional — resolved from prev batch
   ```
   - `tracked`/`resolved` は該当なしの場合省略
   - 前バッチに `tracked` がある場合: 今回の findings と突合し、解決されたものを `resolved` に記載
4. Archive: `$SCOPE_DIR/active/` → `$SCOPE_DIR/B{seq}/`

### 9b handover.md Auto-Draft

コマンド完了後の handover.md auto-draft を実行 (CLAUDE.md Session Persistence セクション参照)。

## Runtime Escalation Protocol

外部エンジンで成果物 (findings YAML / verdict YAML / builder report) が未生成の場合に発動。全ステージ (Briefer / Inspector / Auditor / Builder) で共通。

### Failure Log Capture

成果物不在を検出した時点で、直ちに diagnostic log を保存:

- **ファイル名**: `{scope_dir}/active/failure-{role}-{name}-{engine}-L{level}.log`
  - 例: `failure-inspector-flow-codex-L2.log`, `failure-auditor-claude-L4.log`
  - エスカレーション先も失敗した場合にログが上書きされないよう、engine + level をファイル名に含める
- **tmux mode**: `tmux capture-pane -t {pane_id} -p -S -100` の出力を Write
- **background mode**: TaskOutput ファイルを Read して Write
- **SubAgent mode**: Agent result を Write
- **先頭行**: `timestamp: {ISO-8601}  engine: {engine}  model: {model}  effort: {effort}  level: L{N}  agent: {name}`

### Failure Classification

Failure log の内容から障害タイプを **Lead が判定** する:

**ENGINE_FAILURE** (同一エンジンの上位レベルも同様に失敗する可能性が高い):
- HTTP 5xx (500, 502, 503, 504)
- Rate limit / quota exceeded
- Connection refused / reset / timeout
- API key invalid / authentication error
- "service unavailable", "internal server error"

**LEVEL_FAILURE** (エンジンは機能しているが、モデル/effort の変更で解決できる可能性あり):
- 出力が空 (pane に応答はあるが成果物ファイル未生成)
- YAML 構文エラー
- タスク途中終了 (partial output)

**判定不能** (ログが空、エラー情報なし): **ENGINE_FAILURE として扱う** (保守的判断 — 同じエンジンの retry は無駄になる可能性が高い)

### Escalation Logic

```
ENGINE_FAILURE:
  codex  (L1/L2/L3) → claude L4     (エンジン変更)
  claude (L4/L5/L6) → subagents L0  (エンジン変更)
  subagents (L0)    → 最終失敗

LEVEL_FAILURE:
  L{N} → L{N+1}    (同一チェーン内で次レベル)
  L6   → L0        (チェーン末端、subagents fallback)
  L0   → 最終失敗
```

新しいレベルの engine/model/effort は engines.yaml `levels.L{N}` から解決し、Engine-Specific Command Construction (Step 4) で新しいコマンドを組み立てる。

### User Reporting

エスカレーション発生時、ユーザーに報告:
```
Runtime escalation: {agent-name}
  L{from} ({engine} {model}) → L{to} ({engine} {model})
  Reason: {ENGINE_FAILURE|LEVEL_FAILURE} — {key error from log}
  Log: {failure log path}
```

## Error Handling

- **Engine not installed**: `install_check` が失敗した場合、level chain で次のレベルへ自動エスカレート (Step 1c)。最終的に L0 (subagents) にフォールバック
- **Claude nesting guard**: `CLAUDECODE` 環境変数が設定されている場合 (Lead セッション内)、claude engine は `env -u CLAUDECODE` で起動する必要がある。これなしでは "cannot be launched inside another Claude Code session" エラーで即座に失敗する
- **Agent failure**: Runtime Escalation Protocol でエスカレーション。最終失敗はレポートに "Agent {N} ({name}) did not complete." と注記。他の Agent の結果は有効
- **Timeout**: `$TIMEOUT` 超過時は部分結果があれば findings YAML 存在を確認。なければ Runtime Escalation Protocol を適用
- **Findings not generated**: Runtime Escalation Protocol を適用。L0 まで失敗 → 該当 Agent を最終失敗扱い。Failure log は `{scope_dir}/active/failure-*.log` に保存
- **Slot safety**: MultiView スロットは kill しない。command chain 完了で自動 idle 復帰。Timeout 時はスロットの shell に `C-c` を send-keys で停止
- **SubAgent engine (L0)**: `install_check` は常に成功 (`true`)。Agent ツールの dispatch 失敗はフォールバック先がないため即失敗扱い
- **No findings**: Report "No issues detected." with confirmation checklist
- **Briefer failure**: Runtime Escalation Protocol → L0 も失敗 → 停止
- **Auditor failure**: Runtime Escalation Protocol → L0 も失敗 → findings YAML パス列挙して停止
- **Builder failure**: Runtime Escalation Protocol → L0 も失敗 → 承認済みアイテムリストを提示して手動修正を依頼
- **Builder partial**: 一部アイテムをスキップした場合、スキップ理由をユーザーに報告。ユーザーが手動修正するか defer するか判断

</instructions>
