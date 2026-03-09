# Claude Code SubAgent Definition Reference

**Last Updated**: 2026-03-09
**Sources**: code.claude.com/docs/en/sub-agents, sync-sdd agent definitions (5 agents)

`.claude/agents/` にエージェント定義ファイルを配置するための仕様リファレンス。Agent tool (dispatch 側) の仕様は `agent-tool-reference.md` を参照。

## File Format

Location: `.claude/agents/{name}.md`

YAML frontmatter + Markdown body。ファイル名（拡張子除く）が `subagent_type` の値になる。

```yaml
---
name: my-agent
description: "What this agent does and when to use it."
model: sonnet
tools: Read, Glob, Grep, Write, Edit, Bash
background: true
---

Markdown body = SubAgent のシステムプロンプト。
```

## Frontmatter Fields

### Required

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | 一意な識別子。小文字 + ハイフンのみ。先頭/末尾/連続ハイフン不可。親ディレクトリ名と一致必須 |
| `description` | string | 用途と使用条件。Max 1024 chars。Auto-delegation の判定に使われる |

### Model / Execution

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `model` | string | `inherit` | `sonnet`, `opus`, `haiku`, `inherit`。inherit = 親会話と同じモデル |
| `background` | boolean | `false` | `true` で非同期実行をデフォルト化 |
| `maxTurns` | integer | なし | 最大ターン数。超過で停止 |
| `isolation` | string | なし | `worktree` で git worktree 上のコピーで実行 |

**model の注意点**: agent 定義の `model` が無視され Sonnet にフォールバックする既知バグあり (#5456, #3903)。確実にモデルを制御するには、dispatch 側の Agent tool `model` パラメータを使う（`agent-tool-reference.md` 参照）。

### Tools / Permissions

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `tools` | string | all | スペースまたはカンマ区切り。省略時は全ツール |
| `disallowedTools` | string | なし | 拒否リスト (denylist) |
| `permissionMode` | string | `default` | 下記参照 |

**Permission Modes:**

| Mode | 動作 |
|------|------|
| `default` | 通常の承認プロンプト |
| `acceptEdits` | ファイル編集を自動承認 |
| `dontAsk` | 承認プロンプトを自動拒否 (allowed tools は動作) |
| `bypassPermissions` | 全チェックをスキップ |
| `plan` | 読み取り専用モード |

**AskUserQuestion 禁止**: `tools` に含めると auto-approval パスに入り UI が表示されず空回答で返るバグがある。SubAgent のツールリストから除外すること。

### Advanced

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `skills` | list | なし | 起動時に SubAgent のコンテキストに注入する Skill (全文注入) |
| `memory` | string | なし | `user`, `project`, `local`。永続メモリスコープ |
| `mcpServers` | object | なし | SubAgent が利用可能な MCP サーバー |
| `hooks` | object | なし | ライフサイクルフック (PreToolUse, PostToolUse, Stop) |

## Markdown Body (System Prompt)

frontmatter の後の Markdown がそのまま SubAgent のシステムプロンプトになる。

### 構造の推奨パターン

```markdown
You are a **{Role Name}** — responsible for {one-line mission}.

## Mission
{detailed mission description}

## Input
{what the SubAgent receives via prompt}

## Process
{step-by-step instructions}

## Output
{expected output format and delivery method}
```

### 設計指針

- **自己完結**: 親の会話履歴を参照できないため、必要な情報はすべて prompt で受け取る前提で書く
- **出力最小化**: result は簡潔に。大きな出力はファイルに書き出し `WRITTEN:{path}` を返す
- **ツール制約との整合**: `tools` フィールドで制限したツール以外を指示しない

## Discovery Paths (Priority Order)

1. `--agents` CLI フラグ (セッション限定、最高優先)
2. `.claude/agents/` (プロジェクトレベル、VCS 管理対象)
3. `~/.claude/agents/` (ユーザーレベル、全プロジェクト共通)
4. Plugin ディレクトリ (最低優先)

Claude Code は `.agents/skills/` をスキャンしない (Codex/Gemini 用)。

## Agent Tool との関係

| 項目 | Agent 定義ファイル | Agent tool パラメータ |
|------|-------------------|---------------------|
| model | `model: sonnet` (定義時) | `model: "sonnet"` (dispatch 時) |
| 優先度 | 低い (既知バグで無視される場合あり) | 高い (確実に動作) |
| tools | 定義時に固定 | override 不可 |
| prompt | system prompt (常に適用) | task prompt (invocation ごとに異なる) |

dispatch 時に `subagent_type` で定義を指定すると、定義の system prompt + Agent tool の task prompt が組み合わされる。`model` は Agent tool 側の指定が優先される。

## sync-sdd の Agent 定義一覧

| Name | Model | Tools | Tier | 用途 |
|------|-------|-------|------|------|
| `sdd-analyst` | opus | Read, Glob, Grep, Write, Edit, WebSearch, WebFetch | T2 | ゼロベース再設計 |
| `sdd-architect` | opus | Read, Glob, Grep, Write, Edit, WebSearch, WebFetch | T2 | 設計生成 |
| `sdd-builder` | sonnet | Read, Glob, Grep, Write, Edit, Bash | T3 | TDD 実装 |
| `sdd-taskgenerator` | sonnet | Read, Glob, Grep, Write | T3 | タスク分解 |
| `sdd-conventions-scanner` | sonnet | Read, Glob, Grep, Write | T3 | コードベースパターンスキャン |
