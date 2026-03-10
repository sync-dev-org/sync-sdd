# Agent Tool — Sources & Verification Procedure

> **Purpose**: `agent-tool.md` の情報源と実環境テスト手順を記録する。
> このファイル自体が再テスト手順書として機能する。新バージョンで再検証する際はこのファイルの手順に従い、結果を更新する。

## Verification Environment

| Item | Value |
|------|-------|
| Claude Code version | 2.1.72 |
| Date | 2026-03-10 |
| Platform | Darwin 23.6.0 (arm64) |

---

## Part 1: Research — External Sources

**Principle**: 公式ドキュメントと GitHub Issues は出発点であり ground truth ではない。ドキュメントは実装に遅れ、不正確な記載や意図された動作 vs 実際の動作の乖離がある。GitHub Issues は修正後も OPEN のまま、あるいは未修正で CLOSED になることがある。

### 1.1 Official Documentation

| Source | URL | Last Verified |
|--------|-----|--------------|
| Sub-agents documentation | https://code.claude.com/docs/en/sub-agents | 2026-03-09 |
| Model configuration | https://code.claude.com/docs/en/model-config | 2026-03-09 |
| Costs and token usage | https://code.claude.com/docs/en/costs | 2026-03-09 |
| Settings & env vars | https://code.claude.com/docs/en/settings | 2026-03-09 |
| Agent teams (for comparison) | https://code.claude.com/docs/en/agent-teams | 2026-03-09 |
| Hooks reference | https://code.claude.com/docs/en/hooks | 2026-03-09 |
| CLI reference | https://code.claude.com/docs/en/cli-reference | 2026-03-09 |

Notes: hooks.md の PreToolUse セクションに Agent tool の入力フィールド (prompt, description, subagent_type, model) が記載。Built-in agent types は sub-agents ページの "Built-in subagents" セクション。Model aliases は model-config ページ。

### 1.2 GitHub Issues (Active Monitoring)

| Issue | Topic | Status | Last Verified |
|-------|-------|--------|--------------|
| #31311 | Agent tool `model` parameter regression v2.1.69-v2.1.71 (fixed v2.1.72) | OPEN | 2026-03-10 |
| #31027 | Agent tool schema missing `model` parameter (fixed v2.1.72) | OPEN | 2026-03-10 |
| #18873 | `model` parameter returns 404 (fixed v2.1.72) | OPEN | 2026-03-10 |
| #5456 | Agent definition model ignored (DUPLICATE of #3903) | CLOSED | 2026-03-09 |
| #3903 | --model not inherited by sub-tasks | CLOSED | 2026-03-09 |
| #27736 | skills field not rendered in Agent tool description | OPEN | 2026-03-09 |
| #32340 | Skills invocation + nested spawning feature request | OPEN | 2026-03-09 |

### 1.3 Research Queries

再調査時に使用するクエリ:

```bash
# Official Docs
# WebFetch: https://code.claude.com/docs/en/sub-agents
# WebFetch: https://code.claude.com/docs/en/model-config

# GitHub Issues
gh search issues --repo anthropics/claude-code "subagent OR agent definition OR agent tool" --sort updated --limit 20
gh search issues --repo anthropics/claude-code "subagent model" --sort updated --limit 10
gh search issues --repo anthropics/claude-code "Agent tool model" --sort updated --limit 10
gh search issues --repo anthropics/claude-code "CLAUDE_CODE_SUBAGENT_MODEL" --sort updated

# Release Tracking
# WebFetch: https://www.claudeupdates.dev
# WebFetch: https://code.claude.com/docs/llms.txt
```

### 1.4 Research Focus Points

再調査時に特に注目すべき変更ポイント:

1. **Built-in agent types**: 新規追加・削除の可能性
2. **Model aliases**: 新しいエイリアス (e.g., `sonnet[1m]`) の追加
3. **Nesting**: 現在は禁止。#32340 で変更の可能性
4. **Background behavior**: Permission pre-approval model の変更
5. **CLAUDE_CODE_SUBAGENT_MODEL**: 動作変更の可能性
6. **Agent Team comparison**: experimental → stable 移行の可能性
7. **CLAUDE.md inheritance**: SubAgent への継承有無

---

## Part 2: Verification — Test Cases

**Why**: 公式ドキュメントに以下の不正確さが確認されている:
- `model` パラメータが数ヶ月間ドキュメントに記載されたまま実際には壊れていた
- `Bash` が built-in type として記載されていたがランタイムリストに存在しなかった
- GitHub Issues が修正後も OPEN のまま

リサーチだけでは信頼できるリファレンスは作れない。実環境テストが必須。

### How to Use Part 2

1. 既存テストケースを順に実行し、Result を記入する
2. **Part 1 のリサーチで新しい情報を発見した場合** (新パラメータ、新 agent type、動作変更、新 env var 等)、対応するテストケースを適切なカテゴリに追加してからテストする。既存ケースだけでなく、リサーチ結果を反映した動的なケース追加が重要
3. 既存ケースの Expect が現在のドキュメントと矛盾する場合、Expect を更新してからテストする
4. テスト結果が Expect と異なる場合、Notes に詳細を記録し、Part 3 に Critical Evidence として追記する

### Legend

- **Expect**: ドキュメント/リサーチからの予測
- **Result**: 実行結果 — テスト実行時に記入
- **Notes**: エラーメッセージ等の詳細 — テスト実行時に記入

### Category 1: Parameter Schema

Agent tool に不正な値を渡し、バリデーションエラーから型・enum 値を特定する。

| ID | Action | Expect | Result | Notes |
|----|--------|--------|--------|-------|
| P1-01 | `Agent(model: "invalid")` | enum error listing accepted values | enum error | `sonnet`, `opus`, `haiku` の 3 値 |
| P1-02 | `Agent(model: "sonnet")` | success, SubAgent starts | success | claude-sonnet-4-6 で起動 |
| P1-03 | `Agent(model: "haiku")` | success, SubAgent starts | success | claude-haiku-4-5 で起動 |
| P1-04 | `Agent(model: "sonnet[1m]")` | enum error | enum error | extended alias は不可 |
| P1-05 | `Agent(isolation: "invalid")` | enum error | enum error | `worktree` のみ (single-value enum) |
| P1-06 | `Agent(subagent_type: "nonexistent")` | runtime error listing available agents | runtime error | general-purpose, statusline-setup, Explore, Plan, claude-code-guide + custom |
| P1-07 | `Agent(resume: "invalid_id")` | runtime error (no schema validation) | runtime error | "No transcript found" — string 型 |
| P1-08 | `Agent(run_in_background: true)` | success | success | boolean 型確認 |
| P1-09 | `Agent` with `description` omitted | schema validation error | schema error | required |
| P1-10 | `Agent` with `prompt` omitted | schema validation error | schema error | required |

### Category 2: Model Resolution

SubAgent の自己申告モデル名は信頼できない（frontmatter を読んで答えている可能性）。transcript jsonl の `message.model` で実際の API 呼び出しを確認する。

**Verification method:**
```bash
jq -r 'select(.type == "assistant") | .message.model' ~/.claude/projects/{project}/{session}/subagents/agent-{id}.jsonl
```

| ID | Action | Expect | Result | Notes |
|----|--------|--------|--------|-------|
| M2-01 | `Agent(model: "sonnet")` → check transcript | claude-sonnet-4-6 | claude-sonnet-4-6 | |
| M2-02 | `Agent(model: "haiku")` → check transcript | claude-haiku-4-5 | claude-haiku-4-5 | |
| M2-03 | Agent definition with `model: sonnet` → check transcript | claude-sonnet-4-6 | claude-sonnet-4-6 | sdd-builder で確認 |
| M2-04 | Agent with no model override → check transcript | parent model (inherit) | parent model | general-purpose で確認 |
| M2-05 | Dispatch `model` vs definition `model` conflict → which wins? | dispatch wins (inferred) | (未検証) | 要実機テスト |

### Category 3: Built-in Agent Types

P1-06 のエラーメッセージから取得できるリストと、ドキュメント記載を照合する。

| ID | Agent Type | Documented | In Runtime List | Notes |
|----|-----------|------------|-----------------|-------|
| B3-01 | general-purpose | Yes | Yes | default |
| B3-02 | Explore | Yes | Yes | haiku |
| B3-03 | Plan | Yes | Yes | opus (inherit) |
| B3-04 | statusline-setup | Yes | Yes | sonnet |
| B3-05 | claude-code-guide | Yes | Yes | haiku |
| B3-06 | Bash | Yes (docs) | **No** | ドキュメントには記載あるがランタイムリストに不在 |
| B3-07 | (custom definitions) | N/A | Yes | .claude/agents/*.md で定義されたものがリストに含まれる |

### Category 4: CLAUDE.md Inheritance

SubAgent が CLAUDE.md のコンテキストを継承するかどうか。

| ID | Action | Expect | Result | Notes |
|----|--------|--------|--------|-------|
| C4-01 | SubAgent に CLAUDE.md の内容を質問 | 回答できない (継承なし) | (未検証) | ドキュメント上は非継承 |
| C4-02 | Agent Team (Teammate) に CLAUDE.md の内容を質問 | 回答できる (継承あり) | (未検証) | ドキュメント上は継承 |

**Documentary evidence (2026-03-09)**:

Sub-agents page, "Write subagent files":
> "Subagents receive only this system prompt (plus basic environment details like working directory), not the full Claude Code system prompt."

Agent Teams page, "Context and communication":
> "Each teammate has its own context window. When spawned, a teammate loads the same project context as a regular session: CLAUDE.md, MCP servers, and skills."

→ CLAUDE.md loading は Teammate にのみ明示的に記載。SubAgent には記載なし。
→ 実際の動作はドキュメントと異なる可能性がある。次回更新時に実機テスト推奨。

### Category 5: Subagent File Frontmatter

Agent 定義ファイル (.claude/agents/*.md) の YAML frontmatter フィールド。

| ID | Field | Expect | Result | Notes |
|----|-------|--------|--------|-------|
| F5-01 | `name` (= subagent_type に使われる名前) | required | required | 欠けるとサイレント無視 |
| F5-02 | `description` | required | required | 欠けるとサイレント無視 |
| F5-03 | `model` | optional | optional | sonnet/opus/haiku |
| F5-04 | `tools` | optional (YAML array) | optional | |
| F5-05 | `name` ≠ filename | allowed | allowed | name が subagent_type になる |
| F5-06 | `maxTurns` | optional | optional | |
| F5-07 | `background` | optional | optional | |
| F5-08 | `isolation` | optional | optional | |
| F5-09 | `permissionMode` | optional | optional | |

Note: F5 の詳細は `subagent-file-sources.md` を参照。ここでは agent-tool.md との関連箇所のみ記載。

### Category 6: Background Execution

| ID | Action | Expect | Result | Notes |
|----|--------|--------|--------|-------|
| BG6-01 | `Agent(run_in_background: true)` — launch and wait for completion | task-notification で完了通知 | (verified) | |
| BG6-02 | Background SubAgent で AskUserQuestion を呼ぶ | call fails, SubAgent continues | (未検証) | ドキュメントベース |
| BG6-03 | Background SubAgent が未承認操作を実行 | automatically denied | (未検証) | permission pre-approval model |
| BG6-04 | Background SubAgent failure → `resume` で foreground 復帰 | interactive prompts で retry 可能 | (未検証) | |
| BG6-05 | `CLAUDE_CODE_DISABLE_BACKGROUND_TASKS=1` 設定時に background 起動 | 拒否 or foreground fallback | (未検証) | |
| BG6-06 | Foreground 実行中に Ctrl+B | background に移行 | (未検証) | UI 操作のため自動テスト困難 |

### Category 7: Resume & Transcript

| ID | Action | Expect | Result | Notes |
|----|--------|--------|--------|-------|
| R7-01 | `Agent(resume: "{valid_agent_id}")` | 前回の会話を継続 | (verified) | 実運用で日常的に使用 |
| R7-02 | Transcript ファイルの存在確認 | `~/.claude/projects/{project}/{session}/subagents/agent-{id}.jsonl` | (verified) | M2 で確認済み |
| R7-03 | Resume 後に前回のコンテキストが保持されているか | tool calls, results, reasoning を保持 | (未検証) | 明示的テスト未実施 |
| R7-04 | Parent conversation compaction 後の SubAgent transcript | 影響なし (separate files) | (未検証) | |

### Category 8: Environment Variables

| ID | Action | Expect | Result | Notes |
|----|--------|--------|--------|-------|
| E8-01 | `env CLAUDE_CODE_SUBAGENT_MODEL=claude-haiku-4-5` で起動 → transcript 確認 | haiku で起動 | (未検証) | |
| E8-02 | `env ANTHROPIC_DEFAULT_SONNET_MODEL=claude-sonnet-4-6` → `model: sonnet` で起動 | 指定モデルで起動 | (未検証) | alias 解決先の override |
| E8-03 | `env ANTHROPIC_DEFAULT_OPUS_MODEL=...` → `model: opus` で起動 | 指定モデルで起動 | (未検証) | |
| E8-04 | `CLAUDE_CODE_SUBAGENT_MODEL` vs dispatch `model` → which wins? | dispatch wins (inferred) | (未検証) | priority order テスト |

### Category 9: Limitations & Nesting

| ID | Action | Expect | Result | Notes |
|----|--------|--------|--------|-------|
| L9-01 | SubAgent 内から Agent tool を呼ぶ (nesting) | 失敗 or 無視 | (未検証) | ドキュメント上は禁止 |
| L9-02 | Agent definition の tools に Agent を含める | 効果なし | (未検証) | |
| L9-03 | Dispatch 時に tools を override | 不可 (パラメータなし) | (verified) | P1 schema テストで確認 — tools パラメータ不在 |
| L9-04 | SubAgent が Skills を継承するか (skills field なし) | 継承しない | (未検証) | |
| L9-05 | SubAgent が MCP Servers を使えるか | 不明 | (未検証) | ドキュメントに明示なし |

### Category 10: Auto-Compaction

| ID | Action | Expect | Result | Notes |
|----|--------|--------|--------|-------|
| AC10-01 | SubAgent が長時間実行し 95% capacity に達する | auto-compaction 発動 | (未検証) | 発動条件の意図的テストは困難 |
| AC10-02 | `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` で閾値変更 | 指定閾値で発動 | (未検証) | |

### Category 11: Model Aliases (Extended)

dispatch `model` パラメータでは enum (sonnet/opus/haiku) のみだが、frontmatter や env var で使える aliases をテスト。

| ID | Action | Expect | Result | Notes |
|----|--------|--------|--------|-------|
| MA11-01 | Agent definition `model: default` | account type に応じたモデル | (未検証) | |
| MA11-02 | Agent definition `model: sonnet[1m]` | Sonnet + 1M context | (未検証) | |
| MA11-03 | Agent definition `model: opusplan` | plan=Opus, exec=Sonnet | (未検証) | |
| MA11-04 | Agent definition `model: claude-sonnet-4-6` (full ID) | そのまま解決 | (未検証) | |

---

## Part 3: Critical Evidence

リサーチ + テスト結果から導かれた結論。agent-tool.md の記載根拠。

### `model` Parameter History

**Conclusion (2026-03-10)**: v2.1.72 で動作確認済み。short alias (sonnet/opus/haiku) をサポート。

**Timeline:**
- **v1.0.53-v1.0.72**: #3903/#5456 — model not inherited by sub-tasks
- **v2.1.12+**: #18873 — `model` broken (short name → 404, full ID → validation error)
- **v2.1.66**: `model` present in tool schema (#31027 with full schema comparison)
- **v2.1.68**: `model` reported as working briefly (#31311 author)
- **v2.1.69**: `model` removed from tool schema (#31311 regression, #31027)
- **v2.1.71**: Confirmed absent from tool schema (hands-on verification)
- **v2.1.72**: **Fixed.** `model` restored. Short aliases work (hands-on verification)

### Model Priority

**Conclusion (2026-03-10)**: 検証済みの優先順位。

1. Dispatch-time `model` parameter: **verified** (P1-02, P1-03, M2-01, M2-02)
2. Agent definition `model` field: **verified** (M2-03)
3. `CLAUDE_CODE_SUBAGENT_MODEL` env var: documented but **unverified**
4. Default (inherit parent): **verified** (M2-04)

Priority 1 vs 2 の precedence (dispatch-time が definition を override する) は推定。M2-05 で要実機テスト。

### Research Agent Misreport Warning

2026-03-09 のリサーチエージェントが「CLAUDE.md は SubAgent にもロードされる」と誤報告。Teammate の記述と SubAgent の記述を混同していた。リサーチエージェントの出力は検証なしに信用してはならない。

---

## Results Summary

| Category | Total | Verified | Unverified | Notes |
|----------|-------|----------|------------|-------|
| P1: Parameter Schema | 10 | 10 | 0 | v2.1.72 で全項目確認 |
| M2: Model Resolution | 5 | 4 | 1 | M2-05 (priority conflict) 未検証 |
| B3: Built-in Types | 7 | 7 | 0 | Bash はランタイムに不在 |
| C4: CLAUDE.md Inheritance | 2 | 0 | 2 | ドキュメントベースの推定のみ |
| F5: Frontmatter Fields | 9 | 9 | 0 | テスト定義作成で全確認 |
| BG6: Background Execution | 6 | 1 | 5 | BG6-01 のみ実運用で確認 |
| R7: Resume & Transcript | 4 | 2 | 2 | 日常使用で部分確認 |
| E8: Environment Variables | 4 | 0 | 4 | 全未検証 |
| L9: Limitations & Nesting | 5 | 1 | 4 | L9-03 のみ schema テストで確認 |
| AC10: Auto-Compaction | 2 | 0 | 2 | 意図的テスト困難 |
| MA11: Model Aliases (Extended) | 4 | 0 | 4 | frontmatter/env var 経由の拡張 alias |
| **Total** | **58** | **34** | **24** | |

## Changelog

| Date | CC Version | Tester | Notes |
|------|-----------|--------|-------|
| 2026-03-10 | 2.1.72 | Lead + User | v2.1.72 parameter schema 全検証, model transcript 検証, built-in types 確認 |
| 2026-03-10 | 2.1.71 | Lead + User | v2.1.71 で model パラメータ不在を確認 |
| 2026-03-09 | — | Lead | 初回リサーチ: ドキュメント + GitHub Issues 収集 |
