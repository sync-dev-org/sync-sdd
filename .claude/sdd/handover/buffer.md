# Handover Buffer
**Updated**: 2026-02-20

## Knowledge Buffer
- [INCIDENT] Subagent (Task tool) による並列ファイル書き込みで一部エージェントが Write/Edit 権限を拒否される。mode: bypassPermissions でも UI 承認ダイアログの並列競合が原因と推定。フォールバックとして Lead が completion report から内容を取得して代理書き込みが必要。(source: retroactive-spec-creation Lead, session 2026-02-20)
- [PATTERN] Write Fallback Protocol: Teammate が書き込み失敗時、completion report に `[WRITE_FALLBACK]` タグ + ファイルパス + 全コンテンツを出力 → Lead が代理書き込み。フレームワーク改修候補。(source: retroactive-spec-creation Lead, session 2026-02-20)

## Skill Candidates
