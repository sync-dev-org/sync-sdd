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

セッション開始時にロードされる。手動でファイルを追加した場合、セッション再起動または `/agents` で即時ロード可能。

## Frontmatter Fields

### Required

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | 一意な識別子。小文字 + ハイフンのみ。ファイル名（拡張子除く）と一致させる |
| `description` | string | 用途と使用条件。Claude が auto-delegation の判定に使う。詳しく書くほど適切に委譲される |

### Model / Execution

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `model` | string | `inherit` | `sonnet`, `opus`, `haiku`, `inherit`。inherit = 親会話と同じモデル |
| `background` | boolean | `false` | `true` で非同期実行をデフォルト化 |
| `maxTurns` | integer | なし | 最大ターン数。超過で停止 |
| `isolation` | string | なし | `worktree` で git worktree 上のコピーで実行。変更なしなら自動クリーンアップ |

**model の注意点**: agent 定義の `model` は動作するが、確実に制御するには dispatch 側の Agent tool `model` パラメータまたは `CLAUDE_CODE_SUBAGENT_MODEL` 環境変数を使う方が安全。詳細は `agent-tool-reference.md` の Model Control セクション参照。

### Tools / Permissions

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `tools` | string | all (全ツール継承) | カンマ区切り (e.g., `Read, Glob, Grep, Bash`)。CLI JSON では配列 |
| `disallowedTools` | string | なし | 拒否リスト (denylist)。inherited/specified から除去 |
| `permissionMode` | string | `default` | 下記参照 |

**Agent(type) syntax in tools**: `claude --agent` でメインスレッドとして動作するエージェントの場合、`tools: Agent(worker, researcher), Read, Bash` のように spawn 可能な SubAgent 種別を制限できる。`Agent` のみ (括弧なし) なら全種別許可。`Agent` を tools から除外すると SubAgent spawn 不可。**この制限はメインスレッドのみに適用** — SubAgent は他の SubAgent を spawn できないため、SubAgent 定義では `Agent(type)` は無効。

**Permission Modes:**

| Mode | 動作 |
|------|------|
| `default` | 通常の承認プロンプト |
| `acceptEdits` | ファイル編集を自動承認 |
| `dontAsk` | 承認プロンプトを自動拒否 (allowed tools は動作) |
| `bypassPermissions` | 全チェックをスキップ。**注意: 親が bypassPermissions の場合、SubAgent で上書き不可** |
| `plan` | 読み取り専用モード |

**AskUserQuestion**: foreground SubAgent では親に pass-through される。background SubAgent では呼び出し失敗 (SubAgent は続行)。

### Advanced

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `skills` | list | なし | 起動時に SubAgent のコンテキストに全文注入する Skill。親の Skill は継承されない |
| `memory` | string | なし | 永続メモリスコープ (下記参照) |
| `mcpServers` | string/object | なし | サーバー名 (既存設定参照) またはインライン定義 (name: config) |
| `hooks` | object | なし | ライフサイクルフック (下記参照) |

**skills の既知バグ (#27736, OPEN)**: Plugin 経由の agent 定義で `skills` フィールドが Agent tool の description に表示されない。Skill の内容自体は注入されるが、親セッションの Tool UI に表示されない。

**memory スコープ:**

| Scope | Location | 用途 |
|-------|----------|------|
| `user` | `~/.claude/agent-memory/<name>/` | 全プロジェクト共通の学習 (推奨デフォルト) |
| `project` | `.claude/agent-memory/<name>/` | プロジェクト固有 (VCS 共有可) |
| `local` | `.claude/agent-memory-local/<name>/` | プロジェクト固有 (VCS 共有不可) |

memory 有効時: system prompt にメモリディレクトリの読み書き指示が追加され、`MEMORY.md` の先頭 200 行がコンテキストに注入される。**Read, Write, Edit ツールが自動的に有効化される** (tools で制限していても)。

**hooks (SubAgent 定義内):**

SubAgent のアクティブ中のみ実行されるフック。サポートイベント:

| Event | Matcher | 用途 |
|-------|---------|------|
| `PreToolUse` | Tool name | ツール実行前のバリデーション |
| `PostToolUse` | Tool name | ツール実行後の処理 (lint 等) |
| `Stop` | (none) | SubAgent 完了時。実行時に `SubagentStop` に変換される |

**hooks (settings.json 側):**

プロジェクトレベルで SubAgent ライフサイクルに反応するフック:

| Event | Matcher | 用途 |
|-------|---------|------|
| `SubagentStart` | Agent type name | SubAgent 開始時 |
| `SubagentStop` | Agent type name | SubAgent 完了時 |

## Markdown Body (System Prompt)

frontmatter の後の Markdown がそのまま SubAgent のシステムプロンプトになる。

SubAgent が受け取るコンテキスト (公式ドキュメント準拠):
1. この system prompt (agent 定義の Markdown body)
2. Basic environment details (working directory)
3. `skills` フィールドで指定された Skill の全文
4. `memory` の MEMORY.md (有効時)

**受け取らないもの:**
- 親の full Claude Code system prompt (CLAUDE.md を含む)
- 親の会話履歴

> **注意**: 公式ドキュメントは "Subagents receive only this system prompt (plus basic environment details), not the full Claude Code system prompt" と記述。CLAUDE.md が読み込まれるのは Agent Team の Teammate であり、SubAgent ではない。実動作が異なる可能性もあるが、フレームワーク設計では CLAUDE.md 非継承を前提とする。

### 設計指針

- **自己完結**: 親の会話履歴を参照できないため、必要な情報はすべて prompt で受け取る前提で書く
- **出力最小化**: result は簡潔に。大きな出力はファイルに書き出し `WRITTEN:{path}` を返す
- **ツール制約との整合**: `tools` フィールドで制限したツール以外を指示しない

## Discovery Paths (Priority Order)

| Location | Scope | Priority |
|----------|-------|----------|
| `--agents` CLI フラグ (JSON) | セッション限定 | 1 (最高) |
| `.claude/agents/` | プロジェクトレベル (VCS 管理対象) | 2 |
| `~/.claude/agents/` | ユーザーレベル (全プロジェクト共通) | 3 |
| Plugin の `agents/` ディレクトリ | Plugin 有効範囲 | 4 (最低) |

同名の定義が複数ある場合、高い優先度の定義が勝つ。`/agents` コマンドで override 状態を確認可能。`claude agents` で CLI からリスト表示。

## Agent Tool との関係

| 項目 | Agent 定義ファイル | Agent tool パラメータ |
|------|-------------------|---------------------|
| model | `model: sonnet` (定義時) | `model: "sonnet"` (dispatch 時) |
| 優先度 | Agent tool 側が優先 | — |
| tools | 定義時に固定 | override 不可 |
| prompt | system prompt (常に適用) | task prompt (invocation ごとに異なる) |

dispatch 時に `subagent_type` で定義を指定すると、定義の system prompt + Agent tool の task prompt が組み合わされる。

## 特定の SubAgent の無効化

`settings.json` の `permissions.deny` で特定の SubAgent (built-in 含む) を無効化できる:

```json
{
  "permissions": {
    "deny": ["Agent(Explore)", "Agent(my-custom-agent)"]
  }
}
```

CLI: `claude --disallowedTools "Agent(Explore)"`

## sync-sdd の Agent 定義一覧

| Name | Model | Tools | Tier | 用途 |
|------|-------|-------|------|------|
| `sdd-analyst` | opus | Read, Glob, Grep, Write, Edit, WebSearch, WebFetch | T2 | ゼロベース再設計 |
| `sdd-architect` | opus | Read, Glob, Grep, Write, Edit, WebSearch, WebFetch | T2 | 設計生成 |
| `sdd-builder` | sonnet | Read, Glob, Grep, Write, Edit, Bash | T3 | TDD 実装 |
| `sdd-taskgenerator` | sonnet | Read, Glob, Grep, Write | T3 | タスク分解 |
| `sdd-conventions-scanner` | sonnet | Read, Glob, Grep, Write | T3 | コードベースパターンスキャン |
