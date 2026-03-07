## Change-Focused Review Report

**対象コミット範囲**: HEAD~5..HEAD (framework/, install.sh)
**レビュー日時**: 2026-03-03
**フォーカスターゲット**:
- sdd-review-self-ext 新設: engines.yaml 連携、エンジン別コマンド構築、tmux dispatch
- sdd-inspector-e2e 分離: inspector-test から E2E 責務を分離、新 Agent 定義
- Web Inspector リネーム: sdd-inspector-visual → sdd-inspector-web-visual、新設 sdd-inspector-web-e2e
- tmux-integration.md: One-Shot Command パターン追加、エンジン汎用化
- engines.yaml テンプレート新設: 2層構造 (Tier 1 トレイト + Tier 2 ロール設定)

---

### Issues Found

- [MEDIUM] sdd-review-self-ext が settings.json に未登録のため、ユーザーが初回実行時に手動承認が必要。sdd-review-self は登録済みだが ext 版は未登録。意図的設計の可能性があるが、明記されていない。
  ファイル: framework/claude/settings.json

- [MEDIUM] engines.yaml テンプレート先頭コメントに `# This file is NOT overwritten by install.sh --update.` と記載されているが、これはアクティブファイル (`.sdd/settings/engines.yaml`) に対する記述であり、テンプレートファイル自体 (`.sdd/settings/templates/engines.yaml`) は install.sh --update によって上書きされる。コメントの対象が曖昧で誤読を招く可能性がある。
  ファイル: framework/claude/sdd/settings/templates/engines.yaml:4

- [LOW] sdd-review-self-ext SKILL.md の Step 5 (Parallel Dispatch) で tmux mode の説明に「4 pane を一気に作成した後、4 つの `tmux wait-for` を background Bash で並行発行し、全完了を待つ」とあるが、tmux-integration.md Pattern B の `Wait for completion` ステップは blocking (順次) である。並行 wait-for を複数の Bash run_in_background で発行する方法は tmux-integration.md に記述されておらず、実装詳細がスキルファイル側にのみ存在する。パターン文書との乖離。
  ファイル: framework/claude/skills/sdd-review-self-ext/SKILL.md:163, framework/claude/sdd/settings/rules/tmux-integration.md

- [LOW] sdd-inspector-e2e.md の Output Format に `SCOPE:{feature} | cross-check | wave-1..{N}` とあるが、wave スコープの書式 `wave-1..{N}` は他の Inspector (例: sdd-inspector-test) の SCOPE フォーマットと統一されているか確認が必要。sdd-inspector-test.md では SCOPE 書式の明示的な記載がなく、比較できない。軽微な不一致リスク。
  ファイル: framework/claude/agents/sdd-inspector-e2e.md:88

---

### Confirmed OK

**sdd-review-self-ext 新設**
- engines.yaml の 2層構造 (Tier 1: engines, Tier 2: roles) を正しく参照している
- Step 0 でエンジン可用性確認 (install_check) を実施してから処理を進める設計になっている
- engines.yaml 不在時のフォールバック (テンプレートからコピー → さらに不在時はハードコードデフォルト) が明確に定義されている
- エンジン別コマンド構築 (codex/claude/gemini) が `$RESULT_MODE` (file/stdout) に基づいて正しく分岐している
- codex の `-o` フラグは `--output-last-message <FILE>` の短縮形として有効 (npx @openai/codex exec --help で確認済み)
- `--full-auto` フラグは codex exec の有効なオプションとして存在する (確認済み)
- Pane 自身 (`$MY_PANE`) を保護してから kill 操作を行う安全機構が Step 4 と Step 6 に実装されている
- CPF 出力形式 (EXT_REVIEW_COMPLETE / AGENT / ISSUES / WRITTEN) が 4 Agent 共通で定義されている
- $SCOPE_DIR = `.sdd/project/reviews/self-ext` として sdd-review-self (`.sdd/project/reviews/self`) と分離されている

**sdd-inspector-e2e 分離**
- sdd-inspector-test.md から E2E 実行責務 (Step 5) が完全に削除され、sdd-inspector-e2e.md に移植された
- 新 Agent の YAML frontmatter が適切: `name`, `model: sonnet`, `tools: Read, Glob, Grep, Write, Bash`, `background: true`
- settings.json に `Agent(sdd-inspector-e2e)` が正しく追加されている
- review.md の Impl Inspector リスト (Standard 6 + E2E 条件付き + Web 条件付き) が更新されている
- sdd-auditor-impl.md のファイル一覧 (最大 9 Inspector) に `sdd-inspector-e2e.cpf` (#7) が追加されている
- CPF ファイル名 `sdd-inspector-e2e.cpf` が review.md の dispatch 命名規則と一致している
- E2E コマンドがない場合の VERDICT:GO フォールバックが定義されている
- エラー処理 (no commands / command not found / timeout / majority failure) が明確に定義されている

**Web Inspector リネーム**
- `sdd-inspector-visual` への dangling reference がフレームワーク全体でゼロであることを確認
- `sdd-inspector-web-visual` として settings.json に正しく登録されている
- sdd-auditor-impl.md (#9) でも `sdd-inspector-web-visual.cpf` として正しく参照されている

**tmux-integration.md 新設**
- Pattern A (Server Lifecycle) と Pattern B (One-Shot Command) の 2 パターンが明確に定義されている
- Orphan Cleanup セクション (`ssd-` プレフィックスで全パターン一括検出) が存在し、CLAUDE.md の Step 5a から正しく参照されている
- pane ID ベース targeting の安全ルール (index 指定禁止) が明記されている
- Fallback (tmux 未使用時) が両パターンに定義されている
- review.md (Web Inspector Server Protocol) から `Server Lifecycle pattern from tmux-integration.md` として正しく参照されている
- sdd-review-self-ext から `One-Shot Command pattern from tmux-integration.md` として正しく参照されている

**engines.yaml テンプレート新設**
- Tier 1 (engines: result_mode, install_check) と Tier 2 (defaults + roles) の 2層構造が正確
- deny_patterns セクションが存在し、sdd-review-self-ext が Agent プロンプトへ注入するよう設計されている
- テンプレートが install.sh の `install_dir` によって `.sdd/settings/templates/engines.yaml` に正しくインストールされる
- sdd-steering Engines Mode が `.sdd/settings/engines.yaml` (アクティブ) と `.sdd/settings/templates/engines.yaml` (テンプレート) を正しく区別している

**CLAUDE.md 更新**
- Inspector カウント記述 `6 impl +1 e2e +2 web` が sdd-inspector-e2e 追加に対応して更新されている
- Session Resume Step 5a の Orphan Cleanup 記述が tmux-integration.md への参照に置き換えられている (旧: インライン手順、新: ファイル参照)
- tmux Integration の説明が Web Inspector Server Protocol への参照から tmux-integration.md への参照に更新されている
- README check ルールが Commit Timing セクションに追加されている

**sdd-release 更新**
- Count Verification に `sdd-review-self-ext` が除外リストに追加されている (`sdd-review-self` と並列)

**install.sh 更新**
- `--version v1.14.1` に更新されている

**settings.json 更新**
- `Bash(curl *)` が新規追加されている (外部エンジン接続等で必要)

---

### Overall Assessment

今回の変更は全体的に一貫性が高く、分離・リネーム・新設のいずれも対応するファイル間の整合性が取れている。

**主な懸念事項 2 件**:

1. **MEDIUM**: `sdd-review-self-ext` が settings.json に未登録 — ユーザーが初回起動時に手動承認を求められる。`sdd-review-self` との対称性が欠けており、意図的であればドキュメントへの明記を推奨。

2. **MEDIUM**: engines.yaml テンプレートのコメント `# This file is NOT overwritten by install.sh --update.` はアクティブファイル (`.sdd/settings/engines.yaml`) について正しいが、テンプレートファイル自体は install.sh によって更新される。コメントの対象を明確化することを推奨。

**重大問題 (CRITICAL) はなし**。プロトコルの完全性 (E2E Inspector の分離、tmux パターンの集約、engines.yaml の参照チェーン) に欠落は検出されなかった。
