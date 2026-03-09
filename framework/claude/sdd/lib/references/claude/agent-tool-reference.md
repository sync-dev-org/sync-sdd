# Claude Code Agent Tool Reference

**Last Updated**: 2026-03-09
**Sources**: code.claude.com/docs/en/sub-agents, code.claude.com/docs/en/model-config, GitHub anthropics/claude-code

Claude Code の Agent tool で SubAgent を spawn するための仕様リファレンス。`.claude/agents/` のエージェント定義ファイルの仕様は `subagent-definition-reference.md` を参照。

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `description` | string | Yes | 3-5 word の短い task 説明 |
| `prompt` | string | Yes | SubAgent への指示。SubAgent はこれだけを task prompt として受け取る |
| `subagent_type` | string | No | エージェント種別。Built-in または `.claude/agents/` のカスタム定義名 |
| `model` | string | No | モデル指定 (下記参照)。省略時は inherit |
| `run_in_background` | boolean | No | `true` で非同期実行。完了は `task-notification` で自動通知 |
| `isolation` | string | No | `"worktree"` で git worktree 上のコピーで実行 |
| `resume` | string | No | 前回の Agent ID を指定して会話を継続 |

## Built-in Agent Types

| Type | Model | Tools | 用途 |
|------|-------|-------|------|
| `general-purpose` | inherit | All | 汎用タスク委譲。省略時のデフォルト |
| `Explore` | haiku | Read-only (Write/Edit 拒否) | 高速なコードベース探索。thoroughness level: quick/medium/very thorough |
| `Plan` | inherit | Read-only (Write/Edit 拒否) | plan mode でのコードベース調査 |
| `Bash` | inherit | (separate context) | ターミナルコマンド実行 |
| `statusline-setup` | sonnet | (internal) | `/statusline` で status line 設定 |
| `claude-code-guide` | haiku | (internal) | Claude Code 機能についての質問応答 |

`subagent_type` 省略時は `general-purpose` が使われる。

## Model Control

### Model Aliases

| Alias | 解決先 | 用途 |
|-------|--------|------|
| `sonnet` | claude-sonnet-4-6 (latest Sonnet) | 日常的コーディング |
| `opus` | claude-opus-4-6 (latest Opus) | 複雑な推論 |
| `haiku` | claude-haiku-4-5 | 高速・低コスト |
| `default` | アカウント種別依存 (Max/Team Premium=Opus, Pro/Team Standard=Sonnet) | — |
| `sonnet[1m]` | Sonnet + 1M token context | 長いセッション |
| `opusplan` | plan mode=Opus, execution=Sonnet | ハイブリッド |
| `inherit` | 親会話と同じモデル | model 省略時のデフォルト |

Aliases は常に最新バージョンに解決される。特定バージョンに固定するには完全なモデル名 (e.g., `claude-opus-4-6`) を使うか、環境変数で上書きする。

### 環境変数

| 変数 | 用途 |
|------|------|
| `ANTHROPIC_DEFAULT_OPUS_MODEL` | `opus` alias の解決先を上書き |
| `ANTHROPIC_DEFAULT_SONNET_MODEL` | `sonnet` alias の解決先を上書き |
| `ANTHROPIC_DEFAULT_HAIKU_MODEL` | `haiku` alias の解決先を上書き |
| `CLAUDE_CODE_SUBAGENT_MODEL` | 全 SubAgent のモデルを一括指定 |

sync-sddにおいては、環境変数によるモデル指定は行わない。

### dispatch 時の指定

```
Agent(model="sonnet", description="...", prompt="...")
```

`model` パラメータで dispatch 時にモデルをオーバーライドできる。

### 優先順位 (推定)

公式ドキュメントに明示的な優先順位の記載はない。以下は各ソースからの推定:

| 優先度 | 方法 | 根拠 |
|--------|------|------|
| 1 (最高) | Agent tool `model` パラメータ | dispatch 時に明示指定。#3903/#5456 の workaround として推奨 |
| 2 | `.claude/agents/` 定義の `model` フィールド | 公式 frontmatter table に記載。default は `inherit` |
| 3 | `CLAUDE_CODE_SUBAGENT_MODEL` 環境変数 | model-config ページに記載。"The model to use for subagents" |
| 4 (デフォルト) | inherit | 親会話と同じモデル |

### 既知の Issues

- **#5456** (CLOSED, DUPLICATE of #3903): Agent 定義の model が無視され Sonnet にフォールバック。v1.0.72 時点の報告
- **#3903** (CLOSED, NOT_PLANNED): `--model` CLI フラグが sub-task に継承されない。v1.0.53 時点の報告
- **#27736** (OPEN): Agent 定義の `skills` フィールドが Agent tool の description に表示されないバグ
- **#32340** (OPEN): SubAgent からの skills 動的呼び出し + nested spawning の feature request (duplicate 判定中)

現在のバージョンではこれらの古いバグは修正されている可能性がある。確実にモデルを制御するには dispatch 時の `model` パラメータまたは `CLAUDE_CODE_SUBAGENT_MODEL` 環境変数を推奨。

## Context と Communication

- SubAgent は**新しいコンテキストウィンドウ**で起動 — 親の会話履歴を継承しない
- **公式ドキュメント**: "Subagents receive only this system prompt (plus basic environment details like working directory), not the full Claude Code system prompt." — CLAUDE.md は "full Claude Code system prompt" の一部であり、**SubAgent には渡されない**とされる
- **注意**: Agent Team の Teammate は CLAUDE.md をロードするが、SubAgent (Agent tool) とは異なる。"CLAUDE.md works normally" は Teammate についての記述
- **実動作との乖離の可能性**: リサーチで「CLAUDE.md が SubAgent にも読み込まれる」という報告あり。公式ドキュメントと実動作が異なる場合がある。フレームワーク設計では CLAUDE.md 非継承を前提とし、必要なコンテキストは prompt で明示的に渡す
- `skills` フィールドで指定された Skill の全文が注入される (親の Skill は継承されない)
- 全 task コンテキストは `prompt` パラメータで渡す
- 通信は一方向: 親 → SubAgent (prompt)、SubAgent → 親 (return value)
- 大きな出力は SubAgent がファイルに書き出し、`WRITTEN:{path}` を返す

## Background Execution

- `run_in_background: true` で非同期実行
- **起動前**に Claude Code がツール権限の事前承認プロンプトを表示。起動後は事前承認された権限のみで動作し、未承認操作は自動拒否
- 完了は `task-notification` で自動通知 — **TaskOutput で polling しない** (#14055 Race Condition)
- Background SubAgent で権限不足のため失敗した場合、foreground で `resume` して interactive prompts で再試行可能
- AskUserQuestion の呼び出しは失敗するが SubAgent は続行する
- `CLAUDE_CODE_DISABLE_BACKGROUND_TASKS=1` で background 機能全体を無効化可能
- Ctrl+B で実行中の foreground task を background に移行可能

## Resume と Transcript

- `resume` パラメータで前回の Agent ID を指定して会話を継続
- 再開時は full conversation history を保持 (tool calls, results, reasoning 含む)
- Transcript: `~/.claude/projects/{project}/{sessionId}/subagents/agent-{agentId}.jsonl`
- 親会話の compaction は SubAgent transcript に影響しない (別ファイル)
- `cleanupPeriodDays` (default: 30) で自動クリーンアップ

## Auto-Compaction

SubAgent も親会話と同じ auto-compaction をサポート。約 95% capacity で発動。`CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` で閾値を変更可能。

## Limitations

| 制約 | 詳細 |
|------|------|
| **Context 分離** | 親の会話履歴なし。公式: system prompt + 環境情報 + prompt のみ (CLAUDE.md は含まれないとされる) |
| **Nesting 不可** | SubAgent は他の SubAgent を spawn できない。`Agent(type)` を tools に書いても SubAgent 定義では無効 |
| **Tool override 不可** | dispatch 時にツールリストを変更できない。agent 定義の tools/disallowedTools で制御 |
| **AskUserQuestion** | foreground: 親に pass-through。background: 呼び出し失敗 (SubAgent は続行) |
| **Skills 継承なし** | 親の Skill は継承されない。agent 定義の `skills` フィールドで明示指定が必要 |
| **Memory 非共有** | invocation 間でメモリは共有されない (resume 除く)。`memory` フィールドで永続化は可能 |

## Agent Tool vs Agent Team

| 項目 | Agent Tool (SubAgent) | Agent Team |
|------|----------------------|------------|
| プラットフォーム | Claude Code CLI | Claude Code CLI (experimental, デフォルト無効) |
| セッション | 親セッション内の子コンテキスト | 完全に独立した Claude Code インスタンス |
| 通信 | 一方向 (prompt → result) | 双方向 (message, broadcast) + Shared Task List |
| 並列 | 1 セッション内で複数 SubAgent | 複数独立セッション |
| Nesting | 不可 | 不可 (Teammate はサブチーム作成不可) |
| トークンコスト | 低い (result 要約で返却) | 高い (plan mode で約 7x、一般的に "significantly more") |
| sync-sdd での利用 | Yes (唯一の手段) | No |

Agent Team は Claude Code CLI の experimental 機能。Agent SDK (Python/TypeScript) では利用不可 (2026-03 時点)。
