# Claude Code Agent Team Reference

**Last Updated**: 2026-03-09
**Status**: Experimental (disabled by default)
**Sources**: code.claude.com/docs/en/agent-teams, anthropic.com/engineering/building-agents-with-the-claude-agent-sdk

複数の独立した Claude Code セッションをチームとして協調させる実験的機能。Agent tool (SubAgent) とは根本的に異なるアーキテクチャ。

SubAgent (Agent tool) の仕様は `agent-tool-reference.md`、エージェント定義は `subagent-definition-reference.md` を参照。

## 有効化

デフォルトで無効。環境変数または settings.json で有効化:

```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

## アーキテクチャ

| コンポーネント | 役割 |
|--------------|------|
| **Team Lead** | チームを作成し、タスクを割り当て、結果を統合する Claude Code セッション |
| **Teammate** | 独立したコンテキストウィンドウを持つ別個の Claude Code インスタンス |
| **Shared Task List** | 依存関係トラッキング付きの集中タスクリスト。Teammate が自律的にタスクを claim |
| **Mailbox System** | エージェント間の直接メッセージング基盤 |

### Agent tool (SubAgent) との根本的違い

| 項目 | Agent tool (SubAgent) | Agent Team |
|------|----------------------|------------|
| **セッション** | 親セッション内の子コンテキスト | 完全に独立した Claude Code セッション |
| **通信** | 一方向 (親→子: prompt, 子→親: result) | **双方向** (Lead↔Teammate, Teammate↔Teammate) |
| **協調** | 親が全作業を管理 | Shared Task List による自律的 claim |
| **Context** | 親の会話履歴なし、prompt のみ | 独自の完全なコンテキストウィンドウ |
| **Nesting** | SubAgent は SubAgent を spawn 不可 | Teammate は sub-team を作成不可 |
| **トークンコスト** | 低い (result 要約) | **高い (3-4x)** — Teammate 数に比例 |
| **用途** | 焦点が明確な bounded タスク | 議論・協調が必要な複雑な並列作業 |

## チーム作成

自然言語でリクエスト:

```
Create an agent team to explore this CLI design from different angles:
- one teammate on UX
- one on technical architecture
- one playing devil's advocate
```

Claude がチーム構成を提案 → ユーザー承認 → spawn 実行。

## 表示モード

| Mode | 説明 | 要件 |
|------|------|------|
| **Split panes** | Teammate ごとに専用 pane。クリックで直接操作 | tmux または iTerm2 (`it2` CLI) |
| **In-process** | 全 Teammate をメインターミナル内で実行。Shift+Down で切替 | 任意のターミナル |

デフォルトは `auto` (tmux 内なら split panes)。`"teammateMode": "in-process"` で上書き可能。

## Communication

### メッセージタイプ

| タイプ | 宛先 | 用途 |
|--------|------|------|
| `message` | 特定の Teammate 1名 | タスク指示、質問、フィードバック |
| `broadcast` | 全 Teammate | 全体通知 (使用は控えめに) |

メッセージ配信は自動 (polling 不要)。Teammate が idle になると自動通知。

### Lead の操作

- タスク割当: `Give task X to teammate Y`
- シャットダウン要求: `Ask the researcher teammate to shut down`
- チーム解散: `Clean up the team`
- 計画承認の強制: `Require plan approval before they make any changes`

## Task Coordination

- Lead がタスクを分解し Shared Task List に登録
- Teammate が unblocked なタスクを自律的に claim
- タスク完了で依存先が自動 unblock
- ファイルロックで同時 claim の race condition を防止

## Hooks

| Event | 説明 | Exit code 2 の効果 |
|-------|------|-------------------|
| `TeammateIdle` | Teammate が idle になる直前 | 作業を継続させる |
| `TaskCompleted` | タスクが完了マークされる直前 | 完了を阻止しフィードバックを送信 |

## State Storage

| 場所 | 内容 |
|------|------|
| `~/.claude/teams/{team-name}/config.json` | メンバー配列 (名前, agent ID, agent type) |
| `~/.claude/tasks/{team-name}/` | タスク定義と status |

## 適切な Use Cases

- **リサーチ・レビュー**: 複数 Teammate が異なる観点から同時調査し、発見を共有
- **新モジュール開発**: Teammate がコンポーネントを分担 (ファイル競合なし前提)
- **デバッグ**: 複数仮説を並列テストし root cause に収束
- **Cross-layer 協調**: Frontend / Backend / Tests を別 Teammate が担当
- **議論・合意形成**: 異なるアーキテクチャ立場からの debate

## 避けるべきケース

- 逐次的なタスク (single session の方が効率的)
- 同一ファイルの編集 (協調オーバーヘッドが利益を超える)
- 依存関係が多いタスク (協調が複雑化)
- ルーチンワーク (トークンコストが正当化されない)

## 既知の制限

| 制限 | 詳細 |
|------|------|
| セッション復元不可 | `/resume`, `/rewind` で in-process Teammate は復元されない |
| タスク status ラグ | Teammate がタスク完了をマークし損ね、依存タスクがブロックされることがある |
| シャットダウン遅延 | Teammate は現在のリクエスト完了後にシャットダウン |
| 1チーム/セッション | Lead は同時に 1 チームのみ管理可能 |
| Nested team 不可 | Teammate はサブチームを作成できない |
| Lead 固定 | チーム作成セッションが lifetime を通じて Lead (移譲不可) |
| Permission 継承 | 全 Teammate が spawn 時の Lead の permission mode を継承 |
| Split panes 制約 | VS Code 統合ターミナル、Windows Terminal、Ghostty 非対応 |

## Agent SDK との関係

AgentTeam は **Claude Code CLI 専用機能**。Agent SDK (Python/TypeScript) では programmable API として公開されていない (2026-03 時点)。

| 機能 | Claude Code CLI | Agent SDK |
|------|----------------|-----------|
| Agent Team | Yes (experimental) | No |
| SubAgent (Agent tool) | Yes | Yes (`query()`) |
| Custom agent 定義 | Yes (`.claude/agents/`) | Yes (config) |
| Hooks | Yes | Yes |
| MCP servers | Yes | Yes |

将来的に SDK API として公開される可能性があるが、現時点では CLI の interactive interface と自然言語リクエストでのみ利用可能。

## sync-sdd での位置づけ

sync-sdd は Agent Team を**使用していない**。理由:

1. Experimental でデフォルト無効 — ユーザー環境で動作を保証できない
2. トークンコストが 3-4x — フレームワークのデフォルト動作としては高すぎる
3. Agent tool (SubAgent) + tmux grid で同等の並列性を実現済み
4. sync-sdd の SubAgent は file-based communication で疎結合 — AgentTeam の双方向メッセージングは不要

ただし、Agent Team が stable になり SDK API が公開された場合、review pipeline の Inspector 並列実行などに適用できる可能性がある。
