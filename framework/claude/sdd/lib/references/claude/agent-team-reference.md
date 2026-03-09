# Claude Code Agent Team Reference

**Last Updated**: 2026-03-09
**Status**: Experimental (disabled by default)
**Sources**: code.claude.com/docs/en/agent-teams, code.claude.com/docs/en/costs

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
| **Team lead** | チームを作成し、タスクを割り当て、結果を統合する Claude Code セッション |
| **Teammates** | 独立したコンテキストウィンドウを持つ別個の Claude Code インスタンス |
| **Task list** | 依存関係トラッキング付きの共有タスクリスト。Teammate が自律的にタスクを claim |
| **Mailbox** | エージェント間のメッセージング基盤 |

### SubAgent との根本的違い

| 項目 | Agent tool (SubAgent) | Agent Team |
|------|----------------------|------------|
| **セッション** | 親セッション内の子コンテキスト | 完全に独立した Claude Code インスタンス |
| **通信** | 一方向 (親→子: prompt, 子→親: result) | **双方向** (Lead↔Teammate, Teammate↔Teammate) |
| **協調** | 親が全作業を管理 | Shared Task List による自律的 claim |
| **Context** | system prompt + 環境情報 + prompt (公式: CLAUDE.md は含まれない) | 独自の完全な Claude Code セッション (CLAUDE.md, MCP servers, Skills をロード) |
| **Nesting** | SubAgent は SubAgent を spawn 不可 | Teammate はサブチームを作成不可 |
| **トークンコスト** | 低い (result 要約) | **高い** — plan mode で約 7x、一般的に "significantly more" |
| **用途** | 焦点が明確な bounded タスク | 議論・協調が必要な複雑な並列作業 |

## チーム作成

自然言語でリクエスト。Claude がチーム構成を提案 → ユーザー承認 → spawn 実行:

```
Create an agent team to explore this CLI design from different angles:
- one teammate on UX
- one on technical architecture
- one playing devil's advocate
```

Teammate 数やモデルも指定可能:
```
Create a team with 4 teammates to refactor these modules in parallel.
Use Sonnet for each teammate.
```

**推奨チームサイズ**: 3-5 teammates。5-6 tasks/teammate が目安。

## 表示モード

| Mode | 説明 | 要件 |
|------|------|------|
| **In-process** | 全 Teammate をメインターミナル内で実行。Shift+Down で切替 | 任意のターミナル |
| **Split panes** | Teammate ごとに専用 pane。クリックで直接操作 | tmux または iTerm2 (`it2` CLI) |

デフォルトは `"auto"` (tmux 内なら split panes)。

設定方法:
- settings.json: `"teammateMode": "in-process"` / `"tmux"` / `"auto"`
- CLI フラグ: `claude --teammate-mode in-process`

`"tmux"` は split-pane mode を有効化し、tmux と iTerm2 を自動検出する。

## Communication

### メッセージタイプ

| タイプ | 宛先 | 用途 |
|--------|------|------|
| `message` | 特定の Teammate 1名 | タスク指示、質問、フィードバック |
| `broadcast` | 全 Teammate | 全体通知 (コストがチームサイズに比例するため控えめに) |

メッセージ配信は自動 (polling 不要)。Teammate が idle になると自動通知。

### 直接操作

- **In-process**: Shift+Down で Teammate 間を巡回。Enter で session に入り、Escape で interrupt。Ctrl+T でタスクリスト表示
- **Split panes**: pane をクリックして直接操作

### Plan Approval

Teammate に計画承認を要求可能:
```
Spawn an architect teammate to refactor the auth module.
Require plan approval before they make any changes.
```

Teammate が plan を提出 → Lead が自律的に承認/拒否 → 拒否時はフィードバック付きで再提出。Lead の判断基準はプロンプトで指示可能。

## Task Coordination

- Lead がタスクを分解し Shared Task List に登録
- Teammate が unblocked なタスクを自律的に claim
- タスク完了で依存先が自動 unblock
- ファイルロックで同時 claim の race condition を防止
- Task states: pending → in progress → completed

## Hooks

| Event | 説明 | Exit code 2 の効果 |
|-------|------|-------------------|
| `TeammateIdle` | Teammate が idle になる直前 | 作業を継続させる |
| `TaskCompleted` | タスクが完了マークされる直前 | 完了を阻止しフィードバック (stderr) を送信 |

両フックとも JSON 出力にも対応: `{"continue": false, "stopReason": "..."}` で Teammate を完全停止。

`TeammateIdle` は `type: "command"` のみサポート。`TaskCompleted` は全 4 タイプ (`command`, `http`, `prompt`, `agent`) をサポート。

## Permissions

- 全 Teammate が spawn 時の Lead の permission mode を継承
- spawn 後に個別 Teammate の mode を変更可能 (ただし spawn 時の per-teammate 指定は不可)
- Lead が `--dangerously-skip-permissions` の場合、全 Teammate も同様

## State Storage

| 場所 | 内容 |
|------|------|
| `~/.claude/teams/{team-name}/config.json` | メンバー配列 (名前, agent ID, agent type) |
| `~/.claude/tasks/{team-name}/` | タスク定義と status |

Teammate は config.json を読んで他メンバーを discover 可能。

## Context

各 Teammate が受け取るもの:
- CLAUDE.md (プロジェクトの)
- MCP servers
- Skills
- Lead からの spawn prompt

Lead の会話履歴は**引き継がれない**。

## 適切な Use Cases

- **リサーチ・レビュー**: 複数 Teammate が異なる観点から同時調査し、発見を共有・挑戦
- **新モジュール開発**: Teammate がコンポーネントを分担 (ファイル競合なし前提)
- **デバッグ**: 複数仮説を並列テスト — adversarial debate で root cause に収束
- **Cross-layer 協調**: Frontend / Backend / Tests を別 Teammate が担当

## 避けるべきケース

- 逐次的なタスク (single session の方が効率的)
- 同一ファイルの編集 (協調オーバーヘッドが利益を超える)
- 依存関係が多いタスク (協調が複雑化)
- ルーチンワーク (トークンコストが正当化されない)

## 既知の制限

| 制限 | 詳細 |
|------|------|
| **セッション復元不可** | `/resume`, `/rewind` で in-process Teammate は復元されない。Lead が存在しない Teammate にメッセージを送る場合がある → 新しい Teammate を spawn するよう指示 |
| **タスク status ラグ** | Teammate がタスク完了をマークし損ね、依存タスクがブロックされることがある |
| **シャットダウン遅延** | Teammate は現在のリクエスト/ツール呼び出し完了後にシャットダウン |
| **1チーム/セッション** | Lead は同時に 1 チームのみ管理可能。新チーム作成前に cleanup 必要 |
| **Nested team 不可** | Teammate はサブチームを作成できない |
| **Lead 固定** | チーム作成セッションが lifetime を通じて Lead (移譲不可) |
| **Split panes 制約** | VS Code 統合ターミナル、Windows Terminal、Ghostty 非対応 |

### 既知の Issues (GitHub)

- **#32276** (OPEN): shutdown_request が idle Teammate を起こし、既に terminate した peer にメッセージを送ろうとする
- **#27556** (OPEN): Background agent での TaskUpdate metadata がディスクに永続化されない
- **#32357** (OPEN): カスタム agent 定義での Teammate 採用の feature request

## Agent SDK との関係

Agent Team は **Claude Code CLI 専用機能**。Agent SDK (Python/TypeScript) では programmable API として公開されていない (2026-03 時点)。

| 機能 | Claude Code CLI | Agent SDK |
|------|----------------|-----------|
| Agent Team | Yes (experimental) | No |
| SubAgent (Agent tool) | Yes | Yes (`query()`) |
| Custom agent 定義 | Yes (`.claude/agents/`) | Yes (config) |
| Hooks | Yes | Yes |
| MCP servers | Yes | Yes |

## sync-sdd での位置づけ

sync-sdd は Agent Team を**使用していない**。理由:

1. Experimental でデフォルト無効 — ユーザー環境で動作を保証できない
2. トークンコストが高い (plan mode で約 7x) — フレームワークのデフォルト動作としては高すぎる
3. Agent tool (SubAgent) + tmux grid で同等の並列性を実現済み
4. sync-sdd の SubAgent は file-based communication で疎結合 — Agent Team の双方向メッセージングは不要

ただし、Agent Team が stable になり SDK API が公開された場合、review pipeline の Inspector 並列実行などに適用できる可能性がある。
