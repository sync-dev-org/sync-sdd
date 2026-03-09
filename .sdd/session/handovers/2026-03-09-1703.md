# Session Handover
**Generated**: 2026-03-09T16:24:47+0900
**Branch**: main
**Session Goal**: リファレンス文書の構造化・精査・更新手順書整備

## Direction

### Immediate Next Action
1. I57 (pane タイトル復元) を修正 — dispatch/engine.md に slot release 時のタイトル復元追加
2. D223 (Builder 廃止) を確定 decision 記録
3. コミット

### Active Goals
- **リファレンス文書整備**: references/claude/ にサブフォルダ化完了。3文書を公式ドキュメント+GitHub Issues で全面精査済み。更新手順書も完備。他の領域 (engines.yaml 仕様等) も文書化候補
- **I33 lib/ マイグレーション**: prompts/log/, prompts/review-self/, prompts/dispatch/, references/ 完了。残り: scripts, rules, templates, profiles
- **I41 sdd-review 改修**: dispatch/engine.md 参照に改修。sdd-review-self で先行実証済み
- **I55 issue type 再設計**: GitHub 慣例との整合性検討
- **I56 verdicts.yaml 精査**: スキーマ・役割・session data との分担

### Key Decisions
**Continuing from previous sessions:**
- D2: 本リポは spec/steering/roadmap 不使用
- D10: SubAgent dispatch はデフォルト background
- D121: Lead は Auditor の監修役
- D197: Level chain 設計 L1-L7+L0
- D214: sdd-log スキル
- D220: NL trigger 廃止 + 全記録パスを /sdd-log 経由に統一
- D223: sdd-review-self Builder 廃止 → Lead 直接修正 (B47 で動作確認済み、確定待ち)
- D226: I33 初期判断 — .sdd/ 階層再設計で lib/ 導入
- D227: sdd-review-self 改修計画 — 7項目の設計決定を包括

**Added this session:**
- (正式 decision なし。リファレンス文書の構造化・精査は既存 D226/D227 の延長作業)

### Warnings
- **リサーチエージェントの報告は鵜呑みにしない**: 本セッションで「CLAUDE.md が SubAgent にも読み込まれる」という誤報告を受けた。公式ドキュメント原文と照合すると SubAgent には渡されない。Agent Team の Teammate についての記述を混同した誤り。リサーチ結果は必ず公式ドキュメント原文 (WebFetch) で裏取りすること
- **公式ドキュメントも最新とは限らない**: GitHub Issues で公式ドキュメントの記述と実動作の乖離が報告されることがある。更新手順書の「要注意エビデンス」セクションに検証ポイントを記載済み
- **I57 は UX デグレ**: pane タイトルが busy 表示のまま戻らない

## Session Context

### Tone and Nuance
- リファレンス文書は開発の道標。間違った前提で開発すると全てが間違う。公式原文のエビデンスベースで精度を保つ
- リサーチエージェントの結果だけでなく、公式ドキュメント原文を WebFetch で直接取得して照合する習慣を徹底

### Steering Exceptions
なし

## Accomplished

### Work Summary (this session)
1. `.sdd/lib/references/` をサブフォルダ化: `claude/` 以下に Claude Code 仕様文書4件を移動、直下にはフレームワーク全体文書 (`bash-security-heuristics.md`) のみ
2. `skill-reference-sources.md` を `references/claude/` にコピー
3. 3つのリファレンス文書を公式ドキュメント + GitHub Issues で全面精査・修正:
   - **agent-tool-reference.md**: Plan tools 修正、Built-in types 追加 (Bash/statusline-setup/claude-code-guide)、Model aliases 拡充 (default/sonnet[1m]/opusplan)、CLAUDE_CODE_SUBAGENT_MODEL 追加、CLAUDE.md 継承問題解消、Bug #3903 stateReason 修正、Model 優先順位を「推定」明記
   - **subagent-definition-reference.md**: name 制約修正 ("親ディレクトリ"→"ファイル名")、tools 形式修正、Context セクション公式原文準拠、hooks 追加 (SubagentStart/Stop)、SubAgent 無効化セクション追加
   - **agent-team-reference.md**: トークンコスト修正 ("3-4x"→"approximately 7x")、teammateMode `tmux` 値追加、推奨チームサイズ追加、Plan Approval 追加、Hooks タイプ制限明記、比較表の CLAUDE.md 残存エラー修正
4. 3つの更新手順書を新規作成 (agent-tool-sources.md, subagent-definition-sources.md, agent-team-sources.md) — 公式ドキュメント原文引用の「要注意エビデンス」セクション付き
5. `inspector-compliance.md` のパス更新 (framework/ + install 先)
6. 全ファイルを framework/ 側にも同期

### Previous Sessions (carry forward)
- v2.6.0 (session 18): D227 改修実装 + B47 review + リファレンス文書3件作成
- v2.6.0 (session 17): D227 改修実装 + B47 review + session consolidation
- v2.6.0 (session 16): sdd-review-self 改修計画設計 (D227)
- v2.6.0 (session 15): I40 fix — sdd-log Read-inline化 + .sdd/lib/ 導入
- v2.6.0 (session 14): B46 テスト実行 + codex/SKILL.md 問題検出

### Modified Files
- `.sdd/lib/references/claude/` — サブフォルダ化 (4ファイル移動)
- `.sdd/lib/references/claude/agent-tool-reference.md` — 全面精査・修正
- `.sdd/lib/references/claude/subagent-definition-reference.md` — 全面精査・修正
- `.sdd/lib/references/claude/agent-team-reference.md` — 全面精査・修正
- `.sdd/lib/references/claude/agent-tool-sources.md` — 新規作成
- `.sdd/lib/references/claude/subagent-definition-sources.md` — 新規作成
- `.sdd/lib/references/claude/agent-team-sources.md` — 新規作成
- `.sdd/lib/references/claude/skill-reference-sources.md` — コピー追加
- `.sdd/lib/prompts/review-self/inspector-compliance.md` — パス更新
- `framework/claude/sdd/lib/references/claude/` — 上記全ファイルの framework 同期
- `framework/claude/sdd/lib/prompts/review-self/inspector-compliance.md` — パス更新

## Open Issues
| ID | Sev | Type | Summary |
|----|-----|------|---------|
| **I45** | **H** | ENH | Briefer FILE_LIST に refs/*.md 未収集 (deferred) |
| **I57** | **M** | BUG | tmux slot 解放時に pane タイトルが元に戻らない |
| I29 | M | ENH | jq 可用性チェックを sdd-start に移動 |
| I32 | M | BUG | sdd-start がセキュリティヒューリスティクスを踏む |
| I33 | M | ENH | .sdd/settings/ 階層再設計 (lib/ マイグレーション中) |
| I39 | M | FEAT | knowledge システム拡張 |
| I41 | M | ENH | sdd-review を dispatch/engine.md 参照に改修 |
| I42 | M | FEAT | Command Dispatch 汎用プロンプト作成 |
| I55 | M | ENH | issues.yaml type フィールド GitHub 慣例再設計 |
| I56 | M | ENH | verdicts.yaml 仕様精査 |
| I18 | M | ENH | session データ SQLite 化検討 |
| I10 | L | ENH | ConventionsScanner が issues.yaml を参照しない (deferred) |

## Resume Instructions
1. `/sdd-start` でセッション開始
2. I57 を修正 (dispatch/engine.md に pane タイトル復元追加)
3. D223 確定を decision 記録
4. コミット
