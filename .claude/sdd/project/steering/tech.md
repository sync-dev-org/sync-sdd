# Technology Stack

## Architecture

3-tier Agent Teams hierarchy (Lead → Brain → Execute)。Claude Code の `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` を前提とし、TeammateTool (spawn/shutdown/cleanup) と SendMessageTool (direct/broadcast/shutdown_request) でエージェント間通信を行う。

## Core Technologies

- **Primary format**: Markdown（スキル定義、エージェント定義、ルール、テンプレート、ステアリング）
- **Configuration**: YAML（spec.yaml、tasks.yaml）
- **Installer**: Bash（POSIX互換シェルスクリプト）
- **Platform**: Claude Code (Anthropic CLI)
- **Agent API**: Agent Teams experimental API（TeammateTool, SendMessageTool）

## Key Libraries

なし（外部依存なし。curl, tar, git, awk, sed のみ installer で使用）

## Development Standards

### Type Safety

N/A（Markdownベースのため型システムなし。YAML構造はspec.yaml/tasks.yamlのスキーマで定義）

### Code Quality

- Markdown: 見出し階層の一貫性、セクション間の参照整合性
- Bash: POSIX互換、shellcheck準拠推奨
- YAML: spec.yaml/tasks.yaml のスキーマ準拠（init.yaml テンプレート参照）
- エージェント定義: 統一フォーマット（role, tools, instructions セクション）

### Testing

手動テスト（E2Eでのスキル実行確認）。自動テストフレームワークは未導入。

## Development Environment

### Required Tools

- Claude Code CLI
- Git
- curl, tar（installer用）

### Common Commands

```bash
# Install: curl -LsSf <url>/install.sh | sh
# Update: curl -LsSf <url>/install.sh | sh -s -- --update
# Uninstall: curl -LsSf <url>/install.sh | sh -s -- --uninstall
# Version check: cat VERSION
```

## Key Technical Decisions

- **Agent Teams mode**: subagent (Task tool) ではなく TeammateTool による spawn/dismiss。SendMessage でのピア通信が可能
- **Markdown-first**: コードではなくMarkdownで全エージェント・スキルを定義。Claude Codeが直接読み込み・実行
- **YAML over JSON**: spec.yaml/tasks.yaml は人間が読みやすいYAMLを採用
- **Marker-based injection**: install.sh は `<!-- sdd:start -->` マーカーで CLAUDE.md のフレームワークセクションを管理
- **Auto-Fix Loop ownership**: Auto-Fix Loop は各レビュー spec（design-review, impl-review）にスタンドアロン用の完全な定義を持ち、roadmap-orchestration が Wave レベルの調整層として機能する。各レビュー spec が standalone auto-fix semantics の canonical 定義
- **Auditor timeout**: Inspector 結果待ちのタイムアウトは実装裁量（固定値なし）。Agent Teams メッセージ配信は非決定的でプラットフォーム依存のため、Lead Recovery Protocol で障害ケースを処理する
- **Agent Teams API dependency**: Agent Teams experimental API (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`) 依存をフォールバックなしで受け入れる。フレームワークは Agent Teams 専用設計。install.sh のバージョン固定でリスク軽減
- **Dead-code review scope**: dead-code review pipeline は verdict 出力のみ。Wave Quality Gate での post-verdict Builder re-spawn は roadmap-orchestration (Lead) の責務
- **Revision Notes convention**: design.md の Revision Notes セクションは revision 単位の変更履歴として使用する（テンプレート拡張）
- **SendMessage discrimination**: 現時点では message-type discriminator を導入せず content pattern match で区別する。将来的に channel が複雑化した場合は再検討の余地あり

---
_Document standards and patterns, not every dependency_
