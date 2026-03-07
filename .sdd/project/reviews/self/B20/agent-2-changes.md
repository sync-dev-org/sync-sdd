## Change-Focused Review Report

Generated: 2026-03-03T15:07:06+0900
Scope: framework/ + install.sh (HEAD uncommitted diff + HEAD~5..HEAD)

---

### Issues Found

なし — 全フォーカスターゲットで問題なし。

---

### Confirmed OK

#### Focus Target 1: E2E Gate 削除完全性

- `framework/claude/skills/sdd-roadmap/refs/impl.md` — Step 3.5 ブロック全体が削除済み。Step 4 が直後に続き、ステップ番号の連続性に問題なし（Step 1 → 2 → 2.5 → 3 → 4）。
- `framework/claude/skills/sdd-roadmap/refs/run.md` — Readiness Rules の "Impl Review" 行から E2E gate 条件が削除済み（`E2E gate passed (if E2E command defined...)` の記述なし）。Implementation completion 段落の `Steps 1-3.5` も `Steps 1-3` に更新済み。
- `framework/claude/skills/sdd-roadmap/refs/revise.md` — Part A Step 5 の `Steps 1-3.5, including E2E Gate` が `Steps 1-3` に更新済み。Part B Step 7 Tier Execution の `execute E2E Gate per impl.md Step 3.5` も削除済み。
- `framework/claude/CLAUDE.md` — E2E Gate への dangling reference なし。Auto-Fix Counter Limits セクションに E2E 専用カウンター（"Max 3 E2E fix attempts"）の言及なし（適切に削除済み）。
- リポジトリ全体に `E2E Gate`, `Step 3.5`, `3.5` のいずれも残存しない（Grep 確認済み）。

#### Focus Target 2: Inspector リネーム整合性

以下のすべてのファイルで `sdd-inspector-e2e` → `sdd-inspector-web-e2e`、`sdd-inspector-visual` → `sdd-inspector-web-visual` に統一済み:

- `framework/claude/agents/sdd-auditor-impl.md` — CPF ファイル名 7/8 番が `sdd-inspector-web-e2e.cpf` / `sdd-inspector-web-visual.cpf` に更新済み。
- `framework/claude/skills/sdd-roadmap/refs/review.md` — Impl Review セクション、Web Inspector Server Protocol の見出し行・Step 2 Inspector Dispatch の 3 箇所すべてで新名称使用。
- `framework/claude/settings.json` — `Agent(sdd-inspector-web-e2e)` / `Agent(sdd-inspector-web-visual)` に更新済み。旧エントリなし。
- `framework/claude/sdd/settings/templates/steering-custom/ui.md` — `sdd-inspector-web-visual` に更新済み。
- `framework/claude/agents/sdd-inspector-e2e.md` — 削除済み（ファイルなし確認）。
- `framework/claude/agents/sdd-inspector-visual.md` — 削除済み（ファイルなし確認）。
- `framework/claude/agents/sdd-inspector-web-e2e.md` — 存在確認。YAML frontmatter `name: sdd-inspector-web-e2e`、description 更新済み。
- `framework/claude/agents/sdd-inspector-web-visual.md` — 存在確認。YAML frontmatter `name: sdd-inspector-web-visual`、description 更新済み。
- リポジトリ全体に `sdd-inspector-e2e` / `sdd-inspector-visual`（旧名称）の残存なし（Grep 確認済み）。

CPF 出力パス整合性: review.md が Lead に `{scope-dir}/active/{inspector-name}.cpf` として渡すため、`sdd-inspector-web-e2e.cpf` / `sdd-inspector-web-visual.cpf` が生成される。Auditor がリスト #7/#8 で期待するファイル名と一致。

**install.sh**: stale file 削除ロジック (`remove_stale ".claude/agents" "$SRC/framework/claude/agents" "sdd-*.md"`) が `--update`/`--force` 時に旧 `sdd-inspector-e2e.md` / `sdd-inspector-visual.md` を自動削除する。明示的な migration ブロックは不要（agent リネームはファイル置き換えで十分）。

#### Focus Target 3: sdd-inspector-test E2E 統合

- `framework/claude/agents/sdd-inspector-test.md` — 新 Step 5 "E2E Command Execution" が追加済み。
  - Step 番号: 1→2→3→4→5→6→7 の連続性が保たれている（Grep 確認済み）。
  - 処理内容: `steering/tech.md` の `# E2E:` 行を読み、コマンドが存在すれば実行・結果を記録。失敗時は `e2e-failure`（severity: C）としてフラグ。コマンドなし時は E2E スクリプトを Glob して未設定を L で通知。
  - 出力 Example に `C|e2e-failure|E2E command|...` のサンプル行が追加済み。
  - E2E Gate として Lead が実行していた重複ロジックが Inspector に移管されており、設計意図と一致。

#### Focus Target 4: CLAUDE.md 整合

- Inspector カウント: `6 design, 6 impl +2 web (impl only, web projects), 4 dead-code` — 正確（web Inspector 2 本は web プロジェクト時のみ）。
- E2E Gate 言及: CLAUDE.md 内に E2E Gate / Step 3.5 への参照なし（完全削除確認済み）。
- Auto-Fix Counter Limits: `retry_count: max 5`、`spec_update_count: max 2`、`Aggregate cap: 6`。Dead-Code Review 例外: max 3。E2E 専用カウンター記述なし（適切）。
- Commands (7): `/sdd-publish-setup` が追加されてコマンド数が 7 に更新済み。

#### Focus Target 5: review.md Web Inspector Server Protocol

- プロトコル見出し: `When impl review includes web inspectors (sdd-inspector-web-e2e and sdd-inspector-web-visual)` — 新名称で統一。
- Step 2 Inspector Dispatch: `sdd-inspector-web-e2e` / `sdd-inspector-web-visual` を正しく参照。
- tmux Mode / Fallback Mode の構造に変更なし。プロトコル完全性に問題なし。

---

### Overall Assessment

**全フォーカスターゲットで dangling reference、split loss、protocol gap は検出されなかった。**

変更セット (v1.12.0 / uncommitted diff) の整合性は良好:

1. E2E Gate の削除が impl.md・run.md・revise.md の 3 ファイルすべてで一貫して行われており、CLAUDE.md への波及も正しく処理されている。
2. sdd-inspector-e2e → sdd-inspector-web-e2e / sdd-inspector-visual → sdd-inspector-web-visual のリネームがエージェント定義・YAML frontmatter・Auditor CPF期待値・review.md プロトコル・settings.json・テンプレートの全箇所で統一されている。
3. sdd-inspector-test への E2E 統合はステップ番号連続性・出力 Example・エラーハンドリングが適切に実装されている。
4. install.sh の stale file 除去ロジックにより、旧エージェントファイルは `--update` 時に自動クリーンアップされる（明示的 migration 不要）。

**判定: PASS — 検出 issue なし。**
