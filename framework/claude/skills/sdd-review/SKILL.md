---
description: "Unified review pipeline for design, impl, and dead-code reviews"
argument-hint: "design|impl <feature> [--cross-check] [--wave N] | dead-code [--inspector-engine <name>] [--auditor-engine <name>]"
allowed-tools: Agent, Bash, Glob, Grep, Read, Write
---

# SDD Review

<instructions>

## Purpose

Design / Implementation / Dead-Code の 3 レビュータイプを統一的に実行するスキル。Inspector 並行 dispatch → Auditor 統合 → Verdict 永続化の一貫パイプラインを提供する。

SubAgent (Claude Code Agent tool) がデフォルト。外部エンジン (Codex / Claude / Gemini) は engines.yaml でオプトイン (Session 2+ で追加予定)。

## Step 0: Parse Arguments

```
$ARGUMENTS = "design {feature}"              → REVIEW_TYPE=design, FEATURE={feature}
$ARGUMENTS = "impl {feature}"                → REVIEW_TYPE=impl, FEATURE={feature}
$ARGUMENTS = "dead-code"                      → REVIEW_TYPE=dead-code, FEATURE=none
$ARGUMENTS = "design --cross-check"          → REVIEW_TYPE=design, SCOPE=cross-check
$ARGUMENTS = "impl --cross-check"            → REVIEW_TYPE=impl, SCOPE=cross-check
$ARGUMENTS = "design --wave N"               → REVIEW_TYPE=design, SCOPE=wave-N
$ARGUMENTS = "impl --wave N"                 → REVIEW_TYPE=impl, SCOPE=wave-N
```

オプション:
- `--inspector-engine <name>` / `--inspector-model <name>`: Inspector エンジン/モデル override
- `--auditor-engine <name>` / `--auditor-model <name>`: Auditor エンジン/モデル override
- `--timeout <seconds>`: タイムアウト

引数エラー → "Usage: `/sdd-review design|impl {feature}` or `/sdd-review design|impl --cross-check` or `/sdd-review design|impl --wave N` or `/sdd-review dead-code`"

**1-Spec Roadmap guard**: `--cross-check` or `--wave N` で roadmap.md が 1 spec のみ → "Single-spec roadmap — cross-check/wave review has no additional value." で中止。

## Step 1: Phase Gate

**Design Review**: `design.md` 存在確認。`phase` が `design-generated` or `implementation-complete`。`blocked` → BLOCK。
**Implementation Review**: `design.md` + `tasks.yaml` 存在確認。`phase` が `implementation-complete`。`blocked` → BLOCK。
**Dead-Code Review**: Phase gate なし (codebase 全体)。Roadmap 存在のみ確認。

## Step 2: Inspector Set Resolution

Review type に応じて Inspector リストを決定:

### Design Review
Base (6): `sdd-inspector-rulebase`, `sdd-inspector-testability`, `sdd-inspector-architecture`, `sdd-inspector-consistency`, `sdd-inspector-best-practices`, `sdd-inspector-holistic`

Auditor: `sdd-auditor-design`

### Implementation Review
Base (6): `sdd-inspector-impl-rulebase`, `sdd-inspector-interface`, `sdd-inspector-test`, `sdd-inspector-quality`, `sdd-inspector-impl-consistency`, `sdd-inspector-impl-holistic`

Conditional:
- `sdd-inspector-e2e`: `steering/tech.md` Common Commands に `# E2E` + 非空・非 placeholder コマンドが存在する場合
- `sdd-inspector-web-e2e` + `sdd-inspector-web-visual`: `steering/tech.md` に web stack indicators (React, Next.js, Vue, Angular, Svelte, Express, Django+templates, Rails, FastAPI+frontend 等) が存在する場合

Auditor: `sdd-auditor-impl`

### Dead-Code Review
Base (4): `sdd-inspector-dead-settings`, `sdd-inspector-dead-code`, `sdd-inspector-dead-specs`, `sdd-inspector-dead-tests`

Auditor: `sdd-auditor-dead-code`

## Step 3: Scope Directory + B{seq}

Review scope directory を決定:

| Scope | Directory |
|-------|-----------|
| Per-feature (design/impl with feature) | `{{SDD_DIR}}/project/specs/{feature}/reviews/` |
| Dead-code (standalone) | `{{SDD_DIR}}/project/reviews/dead-code/` |
| Dead-code (Wave QG context) | `{{SDD_DIR}}/project/reviews/wave/` |
| Cross-check (`--cross-check`) | `{{SDD_DIR}}/project/reviews/cross-check/` |
| Wave-scoped (`--wave N`) | `{{SDD_DIR}}/project/reviews/wave/` |
| Cross-cutting (from revise.md) | `{{SDD_DIR}}/project/specs/.cross-cutting/{id}/` |

B{seq} 決定: `{scope-dir}/verdicts.md` を Read し、最大 batch 番号を +1。なければ 1。

`{scope-dir}/active/` を作成 (既存があれば削除してから再作成)。

## Step 4: Context Preamble Generation

各 Inspector に渡すコンテキスト情報を準備する。

SubAgent mode では Agent dispatch prompt に以下を含める:

```
Review: {REVIEW_TYPE}
Feature: {FEATURE} | Scope: {SCOPE}
Output: {scope-dir}/active/{inspector-name}.cpf
```

追加コンテキスト (該当する場合のみ):
- **Wave-scoped**: `{scope-dir}/verdicts.md` から previously resolved issues を抽出し、"PREVIOUSLY_RESOLVED" として Inspector context に含める。Inspector は resolved items を re-flag してはならない。再発 = REGRESSION (severity 昇格)
- **Impl review**: Builder SelfCheck warnings (impl phase で WARN flagged items) があれば Auditor context に含める (attention points, not authoritative findings)
- **Web inspectors** (impl review): Web server URL を含める (Step 5a 参照)

## Step 5: Inspector Dispatch

### Step 5a: Web Server Lifecycle (impl review, web projects only)

Web inspectors (`sdd-inspector-web-e2e`, `sdd-inspector-web-visual`) を含む場合、Inspector dispatch **前に** dev server を起動。

**Server Lifecycle pattern** (from `{{SDD_DIR}}/settings/rules/tmux-integration.md`):
1. `steering/tech.md` Common Commands の `Dev:` entry からコマンド取得
2. Dev server command がない → skip (web inspectors は "Server URL not accessible" で graceful termination)
3. Server 起動 (tmux pane or background Bash)
4. Ready pattern: `ready`, `localhost`, `listening on`
5. Server URL を記録 → web inspector context に含める

### Step 5b: Inspector Dispatch (SubAgent mode)

全 Inspector を並行 dispatch:

```
Agent(subagent_type="sdd-inspector-{name}", run_in_background=true, prompt="{context preamble}")
```

**Single message で全 Inspector を dispatch** (Claude Code の parallel tool call)。

各 Inspector は self-loading — feature 名と output path を渡せば、自分で steering, design.md, tasks.yaml 等を Read する。

Cross-check / wave-scoped mode: Inspector context に scope (cross-check / wave N) を明記。Inspector はスコープに応じたコンテキストロードを行う。

### Step 5c: Wait + Collect

全 Inspector 完了を `TaskOutput` で polling。

**Inspector failure handling**:
- CPF ファイル未出力 → retry once (同じ Inspector を再 dispatch)
- 再試行失敗 → skip (Auditor context に "Inspector {name} unavailable" を明記)
- `VERDICT:ERROR` CPF に C-level findings → Auditor にエラーコンテキスト + C findings を渡す

### Step 5d: Web Server Stop (impl review, web projects only)

全 Inspector 完了後、Auditor dispatch 前に dev server を停止。

## Step 6: Auditor Dispatch

```
Agent(subagent_type="sdd-auditor-{type}", run_in_background=true, prompt="{auditor context}")
```

Auditor context:
- Review directory path: `{scope-dir}/active/` (Auditor が全 .cpf を Read)
- Verdict output path: `{scope-dir}/active/verdict.cpf`
- Steering Exceptions: `{{SDD_DIR}}/handover/session.md` から
- Builder SelfCheck warnings (impl review)

完了を `TaskOutput` で待機。

## Step 7: Verdict Read + Persist + Archive

1. Read `{scope-dir}/active/verdict.cpf`
2. Verdict を `{scope-dir}/verdicts.md` に永続化:
   a. 既存ファイル Read (なければ `# Verdicts: {feature}` ヘッダーで作成)
   b. Batch entry header 追加:
      - Per-feature/standalone: `## [B{seq}] {review-type} | {ISO-8601} | v{version}`
      - Wave QG cross-check: `## [W{wave}-B{seq}] ...`
      - Wave QG dead-code: `## [W{wave}-DC-B{seq}] ...`
   c. Raw section (Auditor CPF verbatim)
   d. Disposition (`GO-ACCEPTED`, `CONDITIONAL-TRACKED`, `NO-GO-FIXED`, `SPEC-UPDATE-CASCADED`, `ESCALATED`)
   e. CONDITIONAL: M/L issues → Tracked section
   f. 前 batch に Tracked → compare → `Resolved since B{prev}`
3. Archive: rename `{scope-dir}/active/` → `{scope-dir}/B{seq}/`

## Step 8: Standalone Verdict Handling

Standalone 呼び出し時 (run/revise pipeline 外):
1. Formatted verdict report を user に表示
2. **Auto-fix なし**: verdict 報告のみ。Auto-fix loop は pipeline orchestration (run.md / revise.md) のみ
3. **STEERING entries 処理**:
   - `CODIFY|{file}|{decision}` → `steering/{file}` を直接更新 + decisions.md に STEERING_UPDATE append
   - `PROPOSE|{file}|{decision}` → user に提示。承認 → 更新 + STEERING_UPDATE。却下 → STEERING_EXCEPTION or USER_DECISION
4. Auto-draft `{{SDD_DIR}}/handover/session.md`

### Next Steps by Verdict (standalone)
- Design GO/CONDITIONAL → suggest `/sdd-roadmap impl {feature}`
- Impl GO/CONDITIONAL → feature complete
- NO-GO → report findings to user
- SPEC-UPDATE-NEEDED → report to user

## Inspector Error Handling

Inspector CPF に `VERDICT:ERROR` → "Inspector unavailable" として扱う。残りの Inspector 結果で続行。Auditor context に unavailable Inspector を明記。

**Exception**: ERROR CPF に C-level findings → Auditor にエラーコンテキスト + C findings を渡す。Critical findings は無視しない。

</instructions>
