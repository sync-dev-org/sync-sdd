# Session Handover
**Generated**: 2026-03-10T02:49:05+0900
**Branch**: main
**Session Goal**: Agent tool model パラメータ検証 + sdd-review-self 関連 issue 整理

## Direction

### Immediate Next Action
1. v2.1.72 リリース確認 → Agent tool `model` パラメータ復活を実機検証
2. I58 設計着手 — sdd-review-self スコープ指定モード (I45/I60 包含)

### Active Goals
- **I58 スコープ指定モード**: 特定スキル/設定/リファレンスを起点に Briefer が芋蔓式にリストアップ。Inspector プロンプトも汎用化 (I60)。FILE_LIST 再帰収集 (I45) も包含
- **I59 Briefer model**: v2.1.72 でスキーマに `model` 復活予定。SKILL.md 変更不要 — バージョンアップで自動解決
- **I33 lib/ マイグレーション**: 残り: scripts, rules, templates, profiles
- **I41 sdd-review 改修**: dispatch/engine.md 参照に改修

### Key Decisions
**Continuing from previous sessions:**
- D2: 本リポは spec/steering/roadmap 不使用
- D10: SubAgent dispatch はデフォルト background
- D121: Lead は Auditor の監修役
- D197: Level chain 設計 L1-L7+L0
- D214: sdd-log スキル
- D220: NL trigger 廃止 + 全記録パスを /sdd-log 経由に統一
- D226: I33 初期判断 — .sdd/ 階層再設計で lib/ 導入
- D227: sdd-review-self 改修計画 — 7項目の設計決定を包括
- D228: リファレンス文書を全て英語に統一

### Warnings
- **リサーチエージェントの報告は鵜呑みにしない**: 公式ドキュメント原文と照合すること。本セッションでも agent-tool-reference.md の `model` 記載が実環境と乖離していた
- **公式ドキュメントも最新とは限らない**: hooks.md に `model` パラメータが記載されているが実際のスキーマからは削除済み
- **Agent tool model リグレッション (K27)**: v2.1.69 で tool スキーマから `model` 削除。v2.1.72 で修正予定 (#31027 wolffiex)。修正後に I59 の動作確認が必要
- **tmux wait-for close channel は 1:1 (K25)**: 複数 pane が同じ close channel を待つと waiter 数分の signal が必要
- **send-keys の task-notification は配信完了のみ (K26)**: Inspector 完了検知には別途 wait-for が必要

## Session Context

### Tone and Nuance
なし

### Steering Exceptions
なし

## Accomplished

### Work Summary (this session)
1. **Agent tool `model` パラメータ実機検証** — 全 7 パラメータを general-purpose で網羅テスト。`model` が tool スキーマに存在しないことを確認
2. **原因特定** — GitHub issues #31311, #31027, #18873 から v2.1.69 リグレッションと判明。バイナリ解析で resolver の override スロットに `void 0` がハードコードされていることが判明
3. **v2.1.72 修正確認** — Anthropic collaborator (wolffiex) が #31027 で修正明言
4. **リファレンス文書更新** — agent-tool-reference.md (Parameters, Model Control, Known Issues), agent-tool-sources.md (GitHub Issues, Parameter History, verification results)
5. **I59 更新** — status: deferred, detail を v2.1.69 リグレッションに修正
6. **K27 記録** — Agent tool model リグレッションの知見

### Previous Sessions (carry forward)
- v2.6.0 (session 21): B48 self-review fixes + I57 fix + D223 確定 + session handover
- v2.6.0 (session 20): references/index.yaml + sdd-review-self リファレンス動的参照 + 全文書英語化
- v2.6.0 (session 19): リファレンス文書の構造化・精査・更新手順書整備

### Modified Files
- `framework/claude/sdd/lib/references/claude/agent-tool-reference.md` — model パラメータ経緯追記, Priority Order 実テストベースに更新, Known Issues 追加
- `framework/claude/sdd/lib/references/claude/agent-tool-sources.md` — GitHub Issues 追加, Parameter History 新設, 検索クエリ追加
- `.sdd/lib/references/claude/agent-tool-reference.md` — install 先同期
- `.sdd/lib/references/claude/agent-tool-sources.md` — install 先同期
- `.sdd/session/issues.yaml` — I59 updated (deferred)
- `.sdd/session/knowledge.yaml` — K27 added
- `.sdd/session/state.yaml` — 新セッション Grid

## Open Issues
| ID | Sev | Type | Summary |
|----|-----|------|---------|
| **I45** | **H** | ENH | Briefer FILE_LIST がスキルディレクトリを再帰的に収集していない |
| **I58** | **H** | FEAT | sdd-review-self スコープ指定モード追加 |
| **I60** | **H** | ENH | 固定 Inspector プロンプトを汎用化 |
| **I62** | **H** | ENH | Router が review impl --cross-cutting を一貫して扱っていない |
| **I63** | **H** | ENH | Dispatch loop が auto-fix 前に batch 確定・退避 |
| I59 | M | BUG | Briefer SubAgent が Opus で起動 (v2.1.72 待ち) |
| I61 | M | ENH | inspector-compliance が検索しすぎ |
| I64 | M | ENH | Lookahead 依存 design 差し戻し時に旧 GO 無効化しない |
| I65 | M | ENH | --update 時 .claude/skills/ stale クリーンアップなし |
| I66 | M | BUG | codex L4 ENGINE_FAILURE (B48) |
| I29 | M | ENH | jq 可用性チェックを sdd-start に移動 |
| I32 | M | BUG | sdd-start がセキュリティヒューリスティクスを踏む |
| I33 | M | ENH | lib/ マイグレーション残り |
| I39 | M | FEAT | knowledge システム拡張 |
| I41 | M | ENH | sdd-review を dispatch/engine.md 参照に改修 |
| I42 | M | FEAT | Command Dispatch 汎用プロンプト |
| I55 | M | ENH | issues.yaml type フィールド再設計 |
| I56 | M | ENH | verdicts.yaml 仕様精査 |
| I18 | M | ENH | session データ SQLite 化検討 |
| I10 | L | ENH | ConventionsScanner issues.yaml 未参照 |

## Resume Instructions
1. `/sdd-start` でセッション開始
2. `claude --version` で v2.1.72 確認 → I59 動作検証
3. I58 設計着手 (sdd-review-self スコープ指定モード)
