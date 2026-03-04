---
description: "Self-review for SDD framework development (framework-internal use only)"
argument-hint: "[--prep-engine <name>] [--prep-model <name>] [--inspector-engine <name>] [--inspector-model <name>] [--auditor-engine <name>] [--auditor-model <name>] [--timeout <seconds>]"
allowed-tools: Bash, Read, Glob, Grep, Write, Agent
---

# SDD Framework Self-Review

<instructions>

## Purpose

外部エンジン (Codex CLI / Claude Code headless / Gemini CLI) または SubAgent (Claude Code Agent tool) を使った self-review スキル。4 Inspector を並行実行し、Auditor が統合する。Lead は CPF を読まない — Auditor の report.md のみを監修する。

## Step 0: Load Engine Config

### 0.1 Parse Arguments

引数からオーバーライドを抽出:

- `--prep-engine <name>` / `--prep-model <name>`: Prep Agent
- `--inspector-engine <name>` / `--inspector-model <name>`: Inspector ×4
- `--auditor-engine <name>` / `--auditor-model <name>`: Auditor
- `--timeout <seconds>`: タイムアウト秒数

引数なし → engines.yaml の設定を使用。引数あり → engines.yaml の値を上書き。

例:
- Auditor のみ変更: `/sdd-review-self --auditor-engine claude --auditor-model claude-sonnet-4-6`
- 全ステージ SubAgent: `/sdd-review-self --prep-engine subagents --inspector-engine subagents --auditor-engine subagents`

### 0.2 Load engines.yaml

1. Read `.sdd/settings/engines.yaml`
   - If absent: copy from `.sdd/settings/templates/engines.yaml` → `.sdd/settings/engines.yaml`, then read. Report: `engines.yaml をデフォルトで作成しました。/sdd-steering engines でカスタマイズ可能です。`
   - If template also absent: all stages fallback to `subagents`
2. Load `deny_patterns` → `$DENY_PATTERNS`

### 0.3 Resolve Final Config

**Per-stage 解決** (各ステージ独立):

| Stage Variable | Resolution (高→低) |
|---------------|-----------|
| `$PREP_ENGINE` / `$PREP_MODEL` | `--prep-{engine,model}` → `stages.prep.{engine,model}` → **subagents** / null |
| `$INSPECTOR_ENGINE` / `$INSPECTOR_MODEL` | `--inspector-{engine,model}` → `stages.inspectors.{engine,model}` → **subagents** / null |
| `$AUDITOR_ENGINE` / `$AUDITOR_MODEL` | `--auditor-{engine,model}` → `stages.auditor.{engine,model}` → **subagents** / null |

**共通設定**:

| Variable | Resolution |
|----------|-----------|
| `$TIMEOUT` | `--timeout` → `roles.review-self.timeout` → 900 (hardcoded) |
| `$TOOLS` | `roles.review-self.tools` → null (full permission) |

末尾の **subagents** がフォールバック — engine 未指定時は常に subagents を使用。

3. 各ステージの engine について `engines.{engine}.install_check` を実行して可用性を確認
   - `install_check` 失敗 → そのステージを **subagents にフォールバック**。Report: `{stage}: {engine} not available, falling back to subagents`
4. Build per-stage `$ENGINE_CMD` using Engine-Specific Command Construction (Step 5) with the resolved engine/model

5. Determine `$BATCH_SEQ`: Read `$SCOPE_DIR/verdicts.md`, find max `B{N}` → `$BATCH_SEQ` = N+1. If absent → 1. This is used for tmux channel names to prevent cross-batch collisions. (Note: `$SCOPE_DIR` is defined in Steps 1-3 section below.)

6. Report resolved config:
```
Timeout: {$TIMEOUT}s
  Prep: {$PREP_ENGINE} [{$PREP_MODEL or "default"}]
  Inspectors: {$INSPECTOR_ENGINE} [{$INSPECTOR_MODEL or "default"}]
  Auditor: {$AUDITOR_ENGINE} [{$AUDITOR_MODEL or "default"}]
```
全ステージが同一 engine/model の場合、1 行にまとめてもよい。

## Steps 1-3: Prompt Construction (Prep Agent)

```
$SCOPE_DIR = .sdd/project/reviews/self
$TPL = .sdd/settings/templates/review-self
```

Steps 1-3 は Prep Agent に委譲する。Lead は dispatch と成否確認のみ。

### Prep Agent Dispatch

1. `rm -rf $SCOPE_DIR/active && mkdir -p $SCOPE_DIR/active`
2. Prep Agent を dispatch:
   **SubAgent mode** (`$PREP_ENGINE == "subagents"`):
   `Agent(subagent_type="general-purpose", model=$PREP_MODEL_MAPPED, run_in_background=true, prompt="Read .sdd/settings/templates/review-self/prep.md and execute the instructions.")`
   完了待ち: `TaskOutput(block=true)`
   **tmux mode** (`$TMUX` 設定あり):
   ```
   tmux send-keys -t {slot_pane_id} 'cat {$TPL}/prep.md | {$PREP_ENGINE_CMD}; tmux wait-for -S sdd-{SID}-review-self-prep-B{seq}' Enter
   ```
   send-keys ゾンビ確認: `pgrep -fl "tmux send-keys"` → 検出時はユーザーに報告し kill
   完了待ち: `Bash(run_in_background=true)` で `tmux wait-for sdd-{SID}-review-self-prep-B{seq}` を実行
   **Fallback mode** (上記以外):
   `Bash(run_in_background=true)` で `cat $TPL/prep.md | $PREP_ENGINE_CMD` を実行。完了待ち。
3. 完了後の検証:
   - `$SCOPE_DIR/active/prep-status.md` が `NO_CHANGES` → "No changes since last review." を報告して停止
   - `$SCOPE_DIR/active/shared-prompt.md` と `$SCOPE_DIR/active/agent-{1,2,3,4}-*.md` (4ファイル) の存在を確認
   - いずれか欠損 → Prep Agent 失敗。SubAgent フォールバック (下記) を試行
4. Step 4 へ進む

### Prep SubAgent Fallback

Prep Agent (外部エンジン) が失敗した場合:
1. `Agent(subagent_type="general-purpose", model="sonnet", run_in_background=true, prompt="Read .sdd/settings/templates/review-self/prep.md and execute the instructions.")`
3. 完了待ち → 出力ファイル存在を再チェック
4. それでも失敗 → "Prep failed. Cannot proceed." を報告して停止

`$PREP_ENGINE == "subagents"` の場合はフォールバック先がないため、失敗時は即停止。

## Step 4: Grid Setup (tmux mode only)

全ステージが subagents の場合はこのステップをスキップ（Agent ツール dispatch に tmux 不要）。
判定: `$PREP_ENGINE == "subagents" && $INSPECTOR_ENGINE == "subagents" && $AUDITOR_ENGINE == "subagents"`

`$TMUX` が設定されている場合のみ実行:
1. `tmux display-message -p '#{pane_id}'` → `$MY_PANE`
2. SID 取得: Lead pane タイトルから抽出 (`tmux display-message -p '#{pane_title}'` → `sdd-{SID}-lead` → `$SID`)。Lead タイトルが `sdd-*-lead` パターンでない場合 → `date +%H%M%S` で生成し、`tmux select-pane -T 'sdd-{SID}-lead'` で設定。

MultiView グリッド確認:
3. List Panes → `sdd-{SID}-slot-*` を Grep
4. グリッドあり → idle スロットの pane ID リストを取得
5. グリッドなし → `bash {{SDD_DIR}}/settings/scripts/multiview-grid.sh $SID $MY_PANE` で作成。出力から slot pane ID を parse

`$TMUX` 未設定の場合はスキップして Step 5 Fallback mode へ。

## Step 5: Parallel Dispatch (4 Inspectors)

Apply **One-Shot Command pattern** from `{{SDD_DIR}}/settings/rules/tmux-integration.md`.

4 つの Inspector を並行起動する (外部エンジンまたは SubAgent)。各 Agent:
- Channel = `sdd-{SID}-review-self-{N}-B{seq}` (`$SID` は Step 4 で生成したセッション固有 ID)。スロットの pane title (`sdd-{SID}-slot-{N}`) は変更しない。
- Prompt = `$SCOPE_DIR/active/shared-prompt.md` + `$SCOPE_DIR/active/agent-{N}-{name}.md` (Prep が展開済み)
- CPF file (成果物) = `$SCOPE_DIR/active/agent-{N}-{name}.cpf`

### Engine-Specific Command Construction

Assemble command based on the resolved engine for each stage (`$PREP_ENGINE`, `$INSPECTOR_ENGINE`, `$AUDITOR_ENGINE`). `$TOOLS` が null の場合は全許可モード、設定されている場合はツール制限モード:

全エンジン共通: stdout はリダイレクトしない — pane に応答テキスト / 進捗が流れる。成果物は CPF ファイルのみ。完了は `tmux wait-for` / background task で検出し、成功判定は CPF ファイル存在チェックで行う。

各ステージの engine に応じて `${STAGE}_ENGINE_CMD` を組み立てる (例: `$PREP_ENGINE_CMD`, `$INSPECTOR_ENGINE_CMD`, `$AUDITOR_ENGINE_CMD`)。send-keys では Prep が `active/` に書き出した展開済みファイルを使い、`cat {shared} {active/agent-N-name.md} | ${STAGE}_ENGINE_CMD` の形でプロンプトを stdin に渡す。

以下 `${STAGE}_MODEL` はそのステージの resolved model。

**codex**:
```
npx -y @openai/codex exec --full-auto [--model ${STAGE}_MODEL] -
```

**claude** (`env -u CLAUDECODE` で Lead セッションからのネスト検出を回避):
```
env -u CLAUDECODE claude -p - --dangerously-skip-permissions [--model ${STAGE}_MODEL]
```
ツール制限時: `--dangerously-skip-permissions` を `--allowedTools "$TOOLS"` に置換。

**gemini**:
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

### Dispatch Mode

分岐順序: SubAgent → tmux → Fallback (Prep/Auditor と統一)。

**SubAgent mode** (`$INSPECTOR_ENGINE == "subagents"`):
Agent ツールで dispatch。`$TMUX` の有無に関わらずこのモードを使用。Bash 呼び出しゼロ。

各 Inspector の dispatch:
`Agent(subagent_type="general-purpose", model=$INSPECTOR_MODEL_MAPPED, run_in_background=true, prompt="Read .sdd/project/reviews/self/active/shared-prompt.md and .sdd/project/reviews/self/active/agent-{N}-{name}.md, then execute the instructions.")`

4 Agent を一括 dispatch (単一メッセージで 4 つの Agent tool call を並列発行)。

完了待ち: 各 Agent の TaskOutput(block=true) で完了を待つ。CPF ファイル存在チェックは外部エンジンと同一。

Hold-and-Release は不要 — Agent は完了時に自動的にリソースを解放する。

**tmux mode** (`$INSPECTOR_ENGINE != "subagents"` かつ `$TMUX` 設定あり):
各 Bash 呼び出しを `tmux` で開始することで `Bash(tmux *)` パターンにマッチさせ、承認を不要にする。

MultiView スロットに `send-keys` で agent コマンドを投入する (Hold-and-Release パターン)。idle スロットから 4 つ選択し、各 Agent の command chain を投入:

全 Agent 同一パターン (Prep が `active/` に展開済みファイルを書き出し済み):
```
tmux send-keys -t {slot_pane_id} 'cat {shared} {active/agent-N-name.md} | {$INSPECTOR_ENGINE_CMD}; tmux wait-for -S sdd-{SID}-review-self-{N}-B{seq}; tmux wait-for sdd-{SID}-close-B{seq}' Enter
```

**tmux throttle**: 4 Agent の send-keys を staggered parallel dispatch で一括発行する。各コマンドに sleep プレフィックスを付けて 0.5 秒刻みでずらし、単一メッセージの並列 Bash 呼び出しで発行する（Lead のターン消費は 1 回）:
```
Bash(run_in_background=true): sleep 0.0; tmux send-keys -t {pane1} '...' Enter
Bash(run_in_background=true): sleep 0.5; tmux send-keys -t {pane2} '...' Enter
Bash(run_in_background=true): sleep 1.0; tmux send-keys -t {pane3} '...' Enter
Bash(run_in_background=true): sleep 1.5; tmux send-keys -t {pane4} '...' Enter
```

4 Agent 分の send-keys 完了後:
1. send-keys ゾンビ確認: `pgrep -fl "tmux send-keys"` → 検出時はユーザーに報告し kill
2. 4 つの `tmux wait-for sdd-{SID}-review-self-{N}-B{seq}` も同様に staggered parallel dispatch (0.5 秒刻み、`Bash(run_in_background=true)`) で並行発行し、全 Agent 完了を待つ。

パスは変数を使わずインラインで記述する（`Bash(tmux *)` マッチのため）。

**Fallback mode** (上記以外):
`cat {shared} {active/agent-N-name.md} | {$INSPECTOR_ENGINE_CMD}` を 4 つの `Bash(run_in_background=true)` で並行実行。CPF はファイル書き出しで取得。

### Agent Prompts (Templates)

Agent 1-4 のプロンプト内容はテンプレートファイルに定義。変更はテンプレートを編集すること:

| Agent | Template | Dispatch-ready file |
|-------|----------|-------------------|
| Prep | `$TPL/prep.md` | (Prep 自身が実行される) |
| 1 (Flow Integrity) | `$TPL/agent-1-flow.md` | `active/agent-1-flow.md` |
| 2 (Change-Focused) | `$TPL/agent-2-changes.md` | `active/agent-2-changes.md` |
| 3 (Consistency) | `$TPL/agent-3-consistency.md` | `active/agent-3-consistency.md` |
| 4 (Compliance) | `$TPL/agent-4-compliance.md` | `active/agent-4-compliance.md` |
| Auditor | `$TPL/auditor.md` | (プレースホルダーなし) |

テンプレートは `.sdd/settings/templates/review-self/` に格納。Prep が Agent 1-4 のテンプレートを読み込み、動的プレースホルダー (`{{FOCUS_TARGETS}}`, `{{CACHED_OK}}`) を展開して `active/` に書き出す。Lead の dispatch は `active/` のファイルのみ参照する。Auditor テンプレートにはプレースホルダーがないため、パス指示のみで dispatch する。

---

## Step 6: Collect Results

全 Agent 完了後 (tmux wait-for / background task / SubAgent TaskOutput 完了):

1. 各 `$SCOPE_DIR/active/agent-{N}-{name}.cpf` の存在とファイルサイズを確認 (`ls -la`) → 成功/失敗を判定
2. **Lead は CPF の内容を Read しない**。存在 + サイズ確認のみ（Auditor が読む）
3. 失敗した Agent (CPF 不在またはサイズ 0) → Inspector SubAgent フォールバック (下記) を試行。フォールバック後も CPF 不在の場合はレポートに注記

### Inspector SubAgent Fallback (外部エンジン失敗時)

`$INSPECTOR_ENGINE != "subagents"` かつ CPF 未生成の Inspector がある場合に発動。

1. 失敗した Inspector のみを対象にリストアップ
2. 各失敗 Inspector について:
   - `Agent(subagent_type="general-purpose", model="sonnet", run_in_background=true, prompt="Read .sdd/project/reviews/self/active/shared-prompt.md and .sdd/project/reviews/self/active/agent-{N}-{name}.md, then execute the instructions.")`
3. 全 fallback Agent の TaskOutput(block=true) で完了待ち
4. CPF ファイル存在+サイズを再チェック（内容は Read しない）
5. それでも CPF 不在の場合はレポートに注記 (2 回失敗)

`$INSPECTOR_ENGINE == "subagents"` の場合はフォールバック先がないため、CPF 不在は即レポートに注記。

### Health Check (tmux mode, subagents 以外)

`pgrep -fl "tmux send-keys"` でゾンビ send-keys プロセスを確認。検出時:
- ユーザーに報告（PID、対象 pane、経過時間）
- ユーザー確認後に `kill {PID}` で除去
- 原因を Error Handling セクションに記録

### Slot Release

SubAgent mode ではスキップ (Agent ツールが自動解放)。tmux mode の場合:
1. `tmux wait-for -S sdd-{SID}-close-B{seq}` → 全 Agent スロットのブロック解除 (Hold-and-Release)
2. command chain 完了後、スロットは idle に戻る（再利用可能）

## Step 7: Consolidation (Auditor Agent)

Auditor Agent に統合を委譲する。Lead は dispatch と成否確認のみ。

### Auditor Dispatch

1. Auditor を dispatch:
   **SubAgent mode** (`$AUDITOR_ENGINE == "subagents"`):
   `Agent(subagent_type="general-purpose", model=$AUDITOR_MODEL_MAPPED, run_in_background=true, prompt="Read .sdd/settings/templates/review-self/auditor.md and execute the instructions.")`
   完了待ち: `TaskOutput(block=true)`
   **tmux mode** (`$TMUX` 設定あり):
   ```
   tmux send-keys -t {slot_pane_id} 'cat {$TPL}/auditor.md | {$AUDITOR_ENGINE_CMD}; tmux wait-for -S sdd-{SID}-review-self-auditor-B{seq}' Enter
   ```
   完了待ち: `Bash(run_in_background=true)` で `tmux wait-for sdd-{SID}-review-self-auditor-B{seq}` を実行
   **Fallback mode** (上記以外):
   `Bash(run_in_background=true)` で `cat $TPL/auditor.md | $AUDITOR_ENGINE_CMD` を実行。完了待ち。
2. 完了後の検証:
   - `$SCOPE_DIR/active/report.md` と `$SCOPE_DIR/active/verdict-data.md` の存在を確認
   - いずれか欠損 → Auditor 失敗。Auditor SubAgent フォールバック (下記) を試行
3. `report.md` を Read → Step 8 へ進む

### Auditor SubAgent Fallback (外部エンジン失敗時)

`$AUDITOR_ENGINE != "subagents"` かつ report.md / verdict-data.md が未生成の場合に発動。

1. `Agent(subagent_type="general-purpose", model="sonnet", run_in_background=true, prompt="Read .sdd/settings/templates/review-self/auditor.md and execute the instructions.")`
3. 完了待ち → 出力ファイル存在を再チェック
4. それでも失敗 → "Auditor failed. Manual review required." を報告し、CPF ファイルパスを列挙して停止

`$AUDITOR_ENGINE == "subagents"` の場合はフォールバック先がないため、失敗時は即上記メッセージで停止。

## Step 8: Report Output + Verdict Persistence

### 8.1 Persist Results

1. B{seq} を決定: `$SCOPE_DIR/verdicts.md` の最大バッチ番号 + 1
2. Auditor が生成した `verdict-data.md` から severity counts と files を読む
3. `$SCOPE_DIR/verdicts.md` にバッチエントリを追記:
   ```
   ## [B{seq}] {ISO-8601} | prep:{$PREP_ENGINE} insp:{$INSPECTOR_ENGINE} aud:{$AUDITOR_ENGINE} | agents:{completed}/{dispatched}
   C:{n} H:{n} M:{n} L:{n} | FP:{n} eliminated
   Files: {comma-separated list of files with confirmed findings}
   ```
4. Archive: `$SCOPE_DIR/active/` → `$SCOPE_DIR/B{seq}/`

### 8.2 Report to User + Action

**提示テンプレートの全フィールドを省略せず出力すること**。

#### Lead 監修

Auditor の `report.md` を入力として以下を実行:

1. **FP 判定**: `decisions.md` の全エントリと突合。意図的決定 (USER_DECISION, STEERING_EXCEPTION) で説明できる finding → FP。Auditor が見落とした defer/意図的決定を Lead が補完する
2. **Defer 判定**: 過去に defer 済みの finding が再浮上していないか、decisions.md の該当エントリを引用して確認
3. **最終分類 (A/B)**: 分類基準に照らして検証し、必要に応じて修正

#### 分類基準

**A) 自明な修正** (Auto-fix):
命名不一致、typo、許可漏れ、example 誤り等、判断不要で正解が一意のもの。
→ 一覧表示し、ユーザーの OK 一言で全件修正を実行。

**B) ユーザー判断が必要** (Decision-required):
pre-existing backlog の対処方針、設計レベルの変更、影響範囲が広い修正。
→ 各 finding のフィールドを **すべて埋めて** 提示。「どうしますか？」だけで聞かない。

#### 提示テンプレート (MUST)

Lead はこのテンプレートの全セクション・全フィールドを省略せずユーザーに出力する。要約テーブルへの圧縮は禁止。

```markdown
# SDD Framework Self-Review Report
**Date**: {ISO-8601} | **Engines**: prep:{$PREP_ENGINE} [{$PREP_MODEL}], insp:{$INSPECTOR_ENGINE} [{$INSPECTOR_MODEL}], aud:{$AUDITOR_ENGINE} [{$AUDITOR_MODEL}]
**Agents**: {dispatched} dispatched, {completed} completed

## False Positives Eliminated ({N}件)

| # | Finding | Agent | Reason (decisions.md ref) |
|---|---------|-------|---------------------------|
| 1 | {概要} | {検出Agent} | {FP理由 — D{seq} 参照 or 実動作確認等} |

## A) 自明な修正 ({N}件) — OK で全件修正します

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

## Error Handling

- **Engine not installed**: `install_check` が失敗した場合、そのステージを subagents にフォールバック。Report: `{stage}: {engine} not available, falling back to subagents`
- **Claude nesting guard**: `CLAUDECODE` 環境変数が設定されている場合 (Lead セッション内)、claude engine は `env -u CLAUDECODE` で起動する必要がある。これなしでは "cannot be launched inside another Claude Code session" エラーで即座に失敗する
- **Agent failure**: レポートに "Agent {N} ({name}) did not complete." と注記。他の Agent の結果は有効
- **Timeout**: `$TIMEOUT` 超過時は部分結果があれば CPF 存在を確認。なければ該当 Agent を失敗扱い
- **CPF not generated**: CPF ファイルが存在しない、または空の場合、SubAgent Fallback を試行 (外部エンジン時のみ)。Fallback 後も不在なら該当 Agent を失敗扱い
- **Slot safety**: MultiView スロットは kill しない。command chain 完了で自動 idle 復帰。Timeout 時はスロットの shell に `C-c` を send-keys で停止
- **SubAgent engine**: `install_check` は常に成功 (`true`)。Agent ツールの dispatch 失敗はフォールバック先がないため即失敗扱い
- **No findings**: Report "No issues detected." with confirmation checklist.
- **Prep failure**: 外部エンジン失敗 → SubAgent フォールバック。SubAgent も失敗 → 停止
- **Auditor failure**: 外部エンジン失敗 → SubAgent フォールバック。SubAgent も失敗 → CPF パス列挙して停止

</instructions>
