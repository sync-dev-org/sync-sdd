## Change-Focused Review Report

対象コミット: 32988bc (v1.13.1), 9e31976 (v1.13.0)
主要変更: E2E Gate → sdd-inspector-e2e 独立化、Web Inspector リネーム (e2e/visual → web-e2e/web-visual)

---

### Issues Found

- [MEDIUM] `sdd-inspector-e2e.md` の design.md parsing: プレースホルダーフィルタリングが未定義
  **ファイル**: `framework/claude/agents/sdd-inspector-e2e.md` L37-40
  **詳細**: design.md の Testing Strategy から E2E コマンドを抽出する際、"Extract inline code spans (backtick-wrapped commands)" と指示しているが、テンプレート (`design.md` L278) のプレースホルダー行 `- E2E command: \`[command]\`` を誤抽出するリスクがある。steering/tech.md のスキップ規則 (L63-65) はプレースホルダー文字列 `[...]` を除外するが、design.md の抽出ロジックには同等のフィルタがない。実行時に `[command]` という文字列が Bash に渡され `e2e-failure` が誤検知される可能性がある。
  **推奨**: design.md の抽出ロジックにも「ブラケットプレースホルダー (`[...]`) をスキップ」を追記する。

- [LOW] `sdd-inspector-test.md` Mission 文の変更が HEAD に未コミット
  **ファイル**: `framework/claude/agents/sdd-inspector-test.md`
  **詳細**: `git diff HEAD` で確認した未コミット変更に、Mission 行の E2E 文言削除および Step 5-7 再番号付けが含まれている。これらは v1.13.0 のコミット (9e31976) とは別の未コミット変更として残存しており、コミット境界が分断されている。機能的には v1.13.0 の意図と一致するが、アーカイブ上はコミットされていない。
  **推奨**: 未コミット変更を意図通りコミットする（すでに今回のセルフレビュー対象であることを確認済み）。

---

### Confirmed OK

1. **sdd-inspector-e2e.md フロントマター**: `name: sdd-inspector-e2e`, `model: sonnet`, `tools: Read, Glob, Grep, Write, Bash`, `background: true` — 全て有効な値であり完備。

2. **settings.json エントリ**: `Agent(sdd-inspector-e2e)` が `framework/claude/settings.json` L29 に追加済み。既存の `Agent(sdd-inspector-web-e2e)` (旧 `sdd-inspector-e2e`) とは別エントリで共存。

3. **review.md ディスパッチ条件**: `refs/review.md` L34 に `sdd-inspector-e2e` のディスパッチ条件 "Projects with E2E commands (steering/tech.md Common Commands contains `# E2E` with non-empty, non-placeholder command)" が追加済み。CLAUDE.md の "6 impl +1 e2e +2 web (impl only; e2e/web are conditional)" と一致している。

4. **sdd-auditor-impl.md Inspector 数 8→9**: L13 の Mission 文を "up to 9" に更新、L45-53 のリストに番号 1-9 が順番通り記載されており、7番が `sdd-inspector-e2e.cpf`、8番が `sdd-inspector-web-e2e.cpf`、9番が `sdd-inspector-web-visual.cpf` と正確に対応。CPF ファイル名が各エージェント名 (`name:` フィールド) と一致している。

5. **sdd-inspector-test.md Step 番号**: 未コミット変更後の状態を Read で確認済み。Single Spec Mode の実行ステップが 1→2→3→4→5→6 と連番になっており、旧 Step 5 (E2E) 削除後の再番号付けに欠番なし。

6. **E2E Gate 参照のダングリング除去**: `refs/impl.md`、`refs/run.md`、`refs/revise.md` に "Step 3.5" および "E2E Gate" の記述が残っていないことを Grep で確認。"Steps 1-3.5" の参照も全て "Steps 1-3" に更新済み。

7. **Web Inspector リネーム一貫性**:
   - `sdd-inspector-e2e.md` → `sdd-inspector-web-e2e.md` (ファイルリネーム)
   - `sdd-inspector-visual.md` → `sdd-inspector-web-visual.md` (ファイルリネーム)
   - `settings.json`: 旧名削除・新名追加済み
   - `review.md`: 全参照 (L35, L50, L65) 更新済み
   - `sdd/settings/templates/steering-custom/ui.md`: 参照更新済み (L49)
   - 旧名 `sdd-inspector-visual` の参照ゼロ件 (Grep 確認)

8. **review.md E2E ディスパッチ条件と CLAUDE.md の整合性**: review.md は「`# E2E` を含む non-empty, non-placeholder コマンドがある場合 `sdd-inspector-e2e` を追加ディスパッチ」と定義。CLAUDE.md は「e2e/web are conditional」と記載。矛盾なし。

9. **sdd-inspector-e2e.md の tech.md パースアルゴリズムとテンプレート形式の整合性**:
   - テンプレート形式: `# E2E: [single command]` および `# E2E (label): [command]`
   - インスペクターのパース規則: 単行形式と `# E2E (label):` ブロックヘッダ形式の両方に対応
   - プレースホルダー除外: `[...]` パターンのスキップが L63-65 に明記
   - 整合している。

10. **sdd-inspector-e2e.md の review.md Step 4 コンテキスト**: review.md L98 に "E2E inspector: no additional context needed (self-loads from steering and design.md)" と追記済み。インスペクター定義 (L31: "You are responsible for loading your own context.") と一致。

11. **sdd-inspector-test.md の E2E 参照除去**: Mission 文、Step 5、Example CPF の `e2e-failure` 行がいずれも削除済み (未コミット変更確認済み)。残存ダングリング参照なし。

---

### Overall Assessment

**主要変更は全体的に整合している。** リネーム (visual→web-visual, e2e→web-e2e) は全参照箇所で更新済み。E2E Gate の削除は impl.md / run.md / revise.md から漏れなく除去されており、sdd-inspector-e2e への機能移転も review.md のディスパッチ条件・Auditor の Inspector リストと整合している。

**要対応 1件 (MEDIUM)**: `sdd-inspector-e2e.md` が design.md からコマンドを抽出する際のプレースホルダーフィルタが未定義。テンプレートのプレースホルダー行 `` `[command]` `` を誤実行するリスクがある。

**確認事項 1件 (LOW)**: `sdd-inspector-test.md` の変更が未コミットのまま残存。機能的問題ではないが、コミット境界として不完全。
