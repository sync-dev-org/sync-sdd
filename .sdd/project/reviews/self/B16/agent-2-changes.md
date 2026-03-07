## Change-Focused Review Report

**レビュー対象コミット**: HEAD~5..HEAD (v1.5.1〜v1.6.1)
**変更ファイル数**: 21ファイル (framework/ + install.sh)

---

### Issues Found

- [MEDIUM] `Capabilities found` フィールドの意味論的ズレ — `framework/claude/agents/sdd-analyst.md:177`

  Analyst の Completion Report に `Capabilities found: {count}` フィールドが残っている。しかし v1.5.1 以降のリデザインで Step 2 は「Capability Inventory」から「Domain & Requirements Discovery」に完全に置き換えられた。現在の Analyst は capabilities を数えるのではなく requirements を抽出する。このフィールドの意味論は obsolete であり、Lead がこの値を解釈しようとすると混乱を招く可能性がある。

  **影響範囲**: Lead が ANALYST_COMPLETE サマリーを読む時。`Capabilities found` が実際には「識別した要件数」または「発見したユースケース数」を意味するようになったが、ラベルは変わっていない。機能的な障害ではないが、ドキュメントとして不正確。

  **修正案**: `Capabilities found` → `Requirements identified` に変更 (sdd-analyst.md:177)

- [MEDIUM] Release Skill Step 3.1 で CHANGELOG.md への言及が Step 3.2a との重複懸念 — `framework/claude/skills/sdd-release/SKILL.md:81-82, 88-99`

  Step 3.1 では「CHANGELOG.md — if exists, add release entry (or remind user to update)」と明示する。Step 3.2a では「変更内容を README.md と照合して更新要否を判断し、ユーザー承認後に適用する」という Change-Based Content Review を行う。CHANGELOG.md への記載は Step 3.1 で宣言されているが、Step 3.2a の「変更内容分析」スコープにも含まれうる。手順の分担が明確だが、Lead が Step 3.1 で CHANGELOG を処理し忘れたまま Step 3.2 に進むリスクはある。重大な問題ではなく、現状でも機能する。

- [LOW] `reboot.md` Phase 4 の「Wait for ANALYST_COMPLETE」と実際の検証ロジック不整合 — `framework/claude/skills/sdd-reboot/refs/reboot.md:61-63`

  Phase 4 Step 2 は「Wait for ANALYST_COMPLETE via TaskOutput」と記述。Step 3 は「Verify: analysis-report.md exists at output path」と記述。しかし ANALYST_COMPLETE メッセージには `Files to delete: {count}` フィールドが追加されたが、Lead がこのフィールドを Phase 4 で解釈・使用するという明示的な指示がない。Lead はフィールドを単に無視してもよく (Phase 9 でレポートから読む)、問題は軽微。ただし Lead がカウントを Phase 4 時点でログしたい場合の指示が欠けている。

- [LOW] `sdd-inspector-test.md` 新フラグ例と CPF 形式の一貫性確認 — `framework/claude/agents/sdd-inspector-test.md:210-217`

  追加されたサンプル出力 (`M|over-mocking|...`, `M|refactor-fragile|...`, `M|impl-coupled-test|...`, `L|duplicate-coverage|...`) は CPF フォーマットに準拠しており、既存の examples と一致している。ただし `refactor-fragile` と `impl-coupled-test` のカテゴリ名が他の標準カテゴリ (`false-positive-risk`, `strategy-gap` 等) と命名スタイルが統一されており問題なし。ただし `over-mocking` カテゴリが CPF ルール定義ファイル (`cpf-format.md`) に正式に登録されているか未確認。

---

### Confirmed OK

1. **Analyst frontmatter 整合性**: `sdd-analyst.md` の YAML frontmatter (`name: sdd-analyst`, `model: opus`, `tools: ...`, `background: true`) は正しく定義されており、`reboot.md` Phase 4 の `Task(subagent_type="sdd-analyst", run_in_background=true)` ディスパッチ参照と完全一致。

2. **ConventionsScanner frontmatter 整合性**: `sdd-conventions-scanner.md` の frontmatter (`name: sdd-conventions-scanner`, `model: sonnet`, `background: true`) は `run.md` Step 2.5、`impl.md` Pilot Stagger、`reboot.md` Phase 3、`revise.md` Part B の各ディスパッチ参照と一致。settings.json にも `Task(sdd-conventions-scanner)` が許可リストに追加されている。

3. **Analyst ディスパッチ参照整合性**: `sdd-analyst.md` は `reboot.md` Phase 4 からのみ dispatch される。CLAUDE.md の Analyst 説明 (`Produces analysis-report.md + updated steering`) もエージェント定義の実際の動作と整合している。`settings.json` に `Task(sdd-analyst)` が追加済み。

4. **ANALYST_COMPLETE フォーマット整合性**: CLAUDE.md 記載フォーマット `ANALYST_COMPLETE + counts + Files to delete: {count} + WRITTEN:{path}` は `sdd-analyst.md` Completion Report セクションのテンプレートと一致 (行順: `ANALYST_COMPLETE` → `New specs` → `Waves` → `Steering` → `Capabilities found` → `Files to delete` → `WRITTEN:`)。`reboot.md` Phase 4 は `ANALYST_COMPLETE` で待機後に `analysis-report.md` の存在を検証する流れで問題なし。

5. **Builder TDD 古典派プロトコルと CLAUDE.md 一貫性**: `sdd-builder.md` の追加内容 (Classical school, observable behavior, one-test-per-behavior, mock external boundaries only) は CLAUDE.md の T3 Builder 行 (`TDD implementation. RED→GREEN→REFACTOR→VERIFY→SELF-CHECK→MARK COMPLETE cycle`) と整合。CLAUDE.md は詳細プロトコルを明示しないが、Builder エージェント定義を参照させる記述 (`See sdd-builder agent definition`) があり、矛盾なし。

6. **Inspector Test エージェント TDD 哲学整合性**: `sdd-inspector-test.md` の追加チェック項目 (Over-mocking, Refactor-fragile, Impl-coupled test, Duplicate coverage) は Builder の Classical school TDD 追加内容と意味論的に整合。Builder が「内部実装を直接モックしない」と定め、Inspector が「内部実装モックを Over-mocking として検出する」という一貫したフローが構成されている。

7. **design.md テンプレートの Testing Strategy 更新**: `framework/claude/sdd/settings/templates/specs/design.md` の Unit Tests 説明に「real internal collaborators; mock only external boundaries」が追加されており、Builder・Inspector の TDD 哲学と整合。設計段階からテスト戦略を明示する意図が一貫している。

8. **Reboot SKILL.md Phase サマリーと reboot.md の整合**: SKILL.md Step 2 のリスト (Phase 9 = "Final Report & User Decision", Phase 10 = "Commit on branch (only if accepted). Never auto-merges.") は `reboot.md` Phase 9・Phase 10 の詳細定義と一致。エラーハンドリングテーブルに `User chooses Iterate (Phase 9)` が追加されており Phase 9 のユーザー選択肢 (Accept/Iterate/Reject) を正しく反映。

9. **Phase 10 削除確認フロー整合性**: `reboot.md` Phase 10 Step 1 の AskUserQuestion (Delete/Skip deletion/Cancel) と `final-report.md` テンプレートの "Next Steps" セクション (`Accept: delete old source files, commit on branch`) が整合している。削除後のコミットに「old source file deletions (if Delete was chosen)」が含まれる旨の記述も追加されており、フローが完全。

10. **analysis-report.md テンプレート更新**: 旧 `Boundary Quality` / `Capability Coverage` セクションが削除され、新たに `Ideal Architecture` / `Deletion Manifest` / `Requirements Coverage` セクションが追加。Analyst Step 6 (Deletion Manifest) と Step 7 (Write Analysis Report) のテンプレート参照と整合。`KEEP`/`DELETE` 分類テーブルも定義済み。

11. **run.md の `.sdd/` ハードコード修正**: 旧バージョンで `Output: .sdd/project/specs/...` と `{{SDD_DIR}}` ではなくハードコードされていた箇所が `{{SDD_DIR}}/project/specs/...` に修正済み (run.md 35行・53行)。テンプレート変数使用の一貫性が向上。

12. **Counter reset triggers の CLAUDE.md 更新**: `session resume (dead-code counters are in-memory only; see refs/run.md)` がトリガーリストに追加。`run.md` の Dead Code Review セクション (`counter restarts at 0 on session resume`) と整合している。

13. **revise.md 実行モデルの明確化**: Step 7 Tier Execution の説明が「Follows run.md Dispatch Loop pattern」から「NOT a concurrent dispatch loop — phases are strictly sequential」に変更され、run.md との動作の違いが明示された。重要な意味論的明確化。

14. **impl.md BUILDER_BLOCKED 条件付きタグ処理**: `If Tags > 0` から `If Tags > 0 (and not BUILDER_BLOCKED)` に変更。BUILDER_BLOCKED の場合はファイルレポートが存在しないため Grep を試みると失敗する。この防御的条件追加は正しい。

15. **sdd-auditor-dead-code.md SCOPE フィールド追加**: CPF 出力に `SCOPE:{feature} | cross-check` フィールドが追加。既存の CPF 仕様との整合性 (cpf-format.md 未読だが、他の auditor 出力形式への影響は直接変更ファイル外のため確認範囲外)。

16. **install.sh バージョン更新**: `--version v1.5.0` → `--version v1.6.1` に更新済み。

17. **settings.json 更新**: `includeCoAuthoredBy: false` 追加 (署名はコミットメッセージで管理する方針に対応)、`Bash(sed *)`, `Bash(cat *)`, `Bash(echo *)` のパーミッション追加。

18. **sdd-analyst.md が CLAUDE.md の Analyst 説明と整合**: CLAUDE.md の T2 Analyst 行 (`Holistic project analysis, zero-based redesign proposal, steering reform/generation. Produces analysis-report.md + updated steering.`) は sdd-analyst.md の Mission・Step 4・Step 7 と整合している。

---

### Overall Assessment

**重大な問題なし。** 変更セット全体を通じて内部整合性は高く維持されている。

**主要変更の品質評価**:

1. **Release Skill Step 3 再構成 (3.1/3.2/3.3)**: サブステップ間の責任分担が明確。3.1 (バージョン参照更新) → 3.2a (変更ベースのコンテンツレビュー、全エコシステム) → 3.2b (CLAUDE.md vs README 同期、SDD フレームワークのみ) → 3.3 (カウント検証、SDD フレームワークのみ) という構造は論理的で完全。旧来の一体的な記述より保守性が向上している。

2. **sdd-analyst.md 新規エージェント**: frontmatter、CLAUDE.md 参照、reboot.md ディスパッチが三者一致。Completion Report フォーマットも CLAUDE.md と整合。`Capabilities found` フィールドのラベルが古い意味論を持つが機能的影響は軽微 (MEDIUM)。

3. **sdd-conventions-scanner.md 新規エージェント**: ディスパッチ参照 (reboot.md/run.md/impl.md/revise.md) が全て一致。Generate/Supplement 二モード構造は各呼び出し元の期待と整合。

4. **Builder TDD プロトコル変更**: Classical school (Detroit) アプローチの追加は Inspector Test エージェント・design.md テンプレートと三者一致しており、フレームワーク全体の TDD 哲学が一貫している。CLAUDE.md の Builder 行は詳細を「See sdd-builder agent definition」に委譲しており矛盾なし。

5. **Reboot skill/refs + impl.md/run.md 変更**: Phase 9 ユーザー承認ゲート、Phase 10 削除確認・マニフェスト、Exit 条件の Skipped スペック除外、Deletion Manifest の final-report.md への追加、すべて内部整合している。セッション中断後の再開フローも session resume での dead-code カウンターリセット記述により完全。

**推奨アクション**: `sdd-analyst.md` の `Capabilities found` を `Requirements identified` に rename することで、v1.5.1 以降の意味論変更を完全に反映させることができる (MEDIUM、機能的影響は低い)。
