# Claude Code Agent Tool Reference

**Last Updated**: 2026-03-09
**Sources**: code.claude.com/docs/en/sub-agents, GitHub anthropics/claude-code #5456/#3903, dev.to (Task Tool orchestration)

Claude Code の Agent tool（旧 Task tool）で SubAgent を spawn するための仕様リファレンス。`.claude/agents/` のエージェント定義ファイルの仕様は対象外。

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `description` | string | Yes | 3-5 word の短い task 説明 |
| `prompt` | string | Yes | SubAgent への指示。SubAgent はこれだけをコンテキストとして受け取る |
| `subagent_type` | string | No | エージェント種別。Built-in (`general-purpose`, `Explore`, `Plan`) または `.claude/agents/` のカスタム定義名 |
| `model` | string | No | モデル指定: `"sonnet"`, `"opus"`, `"haiku"`。省略時は inherit (下記参照) |
| `run_in_background` | boolean | No | `true` で非同期実行。完了は `task-notification` で自動通知 |
| `isolation` | string | No | `"worktree"` で git worktree 上のコピーで実行 |
| `resume` | string | No | 前回の Agent ID を指定して会話を継続 |

## Built-in Agent Types

| Type | Default Model | Tools | 用途 |
|------|--------------|-------|------|
| `general-purpose` | inherit (親と同じ) | All | 汎用タスク委譲。省略時のデフォルト |
| `Explore` | haiku | Read-only (Edit/Write/Agent 除外) | 高速なコードベース探索 |
| `Plan` | inherit | Read-only + Agent | 実装計画の設計 |

`subagent_type` 省略時は `general-purpose` が使われる。

## Model Control

### dispatch 時の指定

```
Agent(model="sonnet", description="...", prompt="...")
```

`model` パラメータで dispatch 時にモデルをオーバーライドできる。これが最も確実な制御方法。

### 優先順位

| 優先度 | 方法 | 動作 |
|--------|------|------|
| 1 (最高) | Agent tool `model` パラメータ | dispatch 時に明示指定 |
| 2 | `.claude/agents/` 定義の `model` フィールド | カスタムエージェント定義 |
| 3 (デフォルト) | inherit | 親会話と同じモデル |

### 既知バグ (#5456, #3903)

Agent 定義ファイルや settings.json の model 指定が無視され、Sonnet にフォールバックする報告あり (CLOSED NOT PLANNED, 2026-01)。**dispatch 時の `model` パラメータは動作する**。コスト制御が必要な場合は dispatch 時指定を推奨。

### Model Aliases

| Alias | 解決先 |
|-------|--------|
| `sonnet` | claude-sonnet-4-6 |
| `opus` | claude-opus-4-6 |
| `haiku` | claude-haiku-4-5 |

## Context と Communication

- SubAgent は**新しいコンテキストウィンドウ**で起動 — 親の会話履歴を継承しない
- 全コンテキストは `prompt` パラメータで渡す
- 通信は一方向: 親 → SubAgent (prompt)、SubAgent → 親 (return value)
- 大きな出力は SubAgent がファイルに書き出し、`WRITTEN:{path}` を返す
- 親は必要に応じてファイルを Read (コンテキスト保全)

## Background Execution

- `run_in_background: true` で非同期実行
- Permission は事前承認される (interactive prompt なし)
- 完了は `task-notification` で自動通知 — **TaskOutput で polling しない** (#14055 Race Condition)
- `resume` パラメータで前回の Agent を continuation 可能

## Limitations

| 制約 | 詳細 |
|------|------|
| **Context 分離** | 親の会話履歴なし。prompt が唯一のコンテキスト |
| **Nesting 不可** | SubAgent は他の SubAgent を spawn できない |
| **Tool override 不可** | dispatch 時にツールリストを変更できない。built-in type のツールセットは固定 |
| **AskUserQuestion 禁止** | SubAgent の allowed-tools に含めると UI バグ (空回答) |
| **Memory 非共有** | invocation 間でメモリは共有されない (resume 除く) |

## Agent Tool vs AgentTeam

| 項目 | Agent Tool | AgentTeam (Agent SDK) |
|------|-----------|----------------------|
| プラットフォーム | Claude Code CLI | Claude Agent SDK (TypeScript/Python) |
| コンテキスト | 呼び出しごとに新規 | エージェントごとに独立セッション |
| 通信 | 一方向 (prompt → result) | 双方向 (shared state) |
| 並列 | 1 セッション内 | 複数セッション横断 |
| Nesting | 不可 | 可能 |
| sync-sdd での利用 | Yes (唯一の手段) | No |

AgentTeam は SDK 専用。Claude Code CLI では利用不可。
