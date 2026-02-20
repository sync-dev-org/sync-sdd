# Handover Buffer
**Updated**: 2026-02-20T12:30:00Z

## Knowledge Buffer
- [INCIDENT] Subagent (Task tool) による並列ファイル書き込みで一部エージェントが Write/Edit 権限を拒否される。mode: bypassPermissions でも UI 承認ダイアログの並列競合が原因と推定。フォールバックとして Lead が completion report から内容を取得して代理書き込みが必要。(source: retroactive-spec-creation Lead, session 2026-02-20)
- [PATTERN] Write Fallback Protocol: Teammate が書き込み失敗時、completion report に `[WRITE_FALLBACK]` タグ + ファイルパス + 全コンテンツを出力 → Lead が代理書き込み。フレームワーク改修候補。(source: retroactive-spec-creation Lead, session 2026-02-20)
- [INCIDENT] hatch-vcs プロジェクトで git tag 作成後に importlib.metadata.version() が旧バージョンを返す。editable install のメタデータキャッシュが原因。正しい修正: `uv sync --reinstall-package {pkg}` (NOT `uv pip install -e .`)。(source: release-automation Builder, task 1.4)
- [PATTERN] Markdown スキルファイル (AI agent instructions) の TDD: RED = spec ACs が未実装であることを確認、GREEN = AC を満たすコンテンツ記述、REFACTOR = 設計との整合性レビュー。diff 検証が sync コピーの機能テスト相当。(source: release-automation Builder, task 2.1)

## Skill Candidates
