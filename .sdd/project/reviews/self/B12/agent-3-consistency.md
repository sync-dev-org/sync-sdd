## Consistency & Dead Ends Report

**レビュー日時**: 2026-02-27
**対象バージョン**: framework v{{SDD_VERSION}} (sdd-reboot + sdd-analyst 追加後)

---

### Issues Found

---

#### [HIGH] Analyst 2回目失敗時の挙動がSKILL.mdとreboot.mdで矛盾

- **ファイル**: `framework/claude/skills/sdd-reboot/SKILL.md:52` vs `framework/claude/skills/sdd-reboot/refs/reboot.md:63`
- **内容**:
  - `SKILL.md` Error Handling テーブル: `"Analyst failure | Retry once. Second failure → delete branch, return to main, report error"`
  - `reboot.md` Phase 4 Step 3: `"On second failure, BLOCK with error"`
- **問題**: SKILL.md は「ブランチ削除 → main に戻る → エラー報告」という明示的クリーンアップを定義しているが、reboot.md は単に `BLOCK` と記述するのみで、ブランチの削除も main への切り戻しも言及していない。同一フェーズの同一失敗パスに2つの異なる定義が存在する。
- **影響**: Lead が reboot.md に従った場合、ブランチが残留したまま BLOCK されユーザーを混乱させる可能性がある。

---

#### [MEDIUM] run.md ConventionsScanner 出力パスで `{{SDD_DIR}}` と `.sdd/` が混在

- **ファイル**: `framework/claude/skills/sdd-roadmap/refs/run.md:35-54`
- **内容**:
  - 入力パラメータ (Steering, Buffer, Template): `{{SDD_DIR}}/...` 形式
  - 出力パス (Output, shared-research): `.sdd/project/specs/.wave-context/{wave-N}/...` 形式（ハードコード）
- **問題**: 同一の `Task` ディスパッチプロンプト内で `{{SDD_DIR}}` と `.sdd/` の表記が混在している。ConventionsScanner や Lead が出力パスを機械的に解釈する場合、変数展開の期待値と異なる可能性がある。`reboot.md` Phase 3 では同じ ConventionsScanner に対して `{{SDD_DIR}}/project/reboot/conventions-brief.md` と一貫して `{{SDD_DIR}}` を使用しており、`run.md` との表記不一致がある。

---

#### [MEDIUM] CLAUDE.md コミットメッセージ形式一覧に `reboot:` プレフィックスが未記載

- **ファイル**: `framework/claude/CLAUDE.md:329` vs `framework/claude/skills/sdd-reboot/refs/reboot.md:274`
- **内容**:
  - `CLAUDE.md` Git Workflow §Commit Timing: `Wave {N}: {summary}` / `{feature}: {summary}` / `cross-cutting: {summary}` の3形式のみ列挙
  - `reboot.md` Phase 10: `"reboot: {1-line summary of redesign}"` を使用
- **問題**: `reboot:` プレフィックスの形式が CLAUDE.md の定義一覧に存在しない。他の開発者やレビュアーが git log を見た際にフォーマット不整合と見なす可能性がある。

---

#### [MEDIUM] CLAUDE.md SubAgent Failure Handling から Analyst が漏れている

- **ファイル**: `framework/claude/CLAUDE.md:115`
- **内容**: 「This applies to all file-writing SubAgents (Inspectors → CPF files, Auditors → verdict.cpf, Builders → builder-report files, ConventionsScanner → conventions-brief)」という記述が Analyst を含まない
- **問題**: Analyst も `analysis-report.md` を書き出す file-writing SubAgent であるが、SubAgent Failure Handling の列挙から抜けている。`reboot.md` Phase 4 には Analyst 固有の失敗処理が記述されているが、CLAUDE.md の一般原則との整合性が明確でない。
- **備考**: 機能的には `reboot.md` Phase 4 がカバーしているが、CLAUDE.md の説明として不完全。

---

#### [MEDIUM] sdd-analyst.md Step 1 でテンプレートファイルの読み込みが指示されていない

- **ファイル**: `framework/claude/agents/sdd-analyst.md:29-34` (Step 1 Context Absorption) vs `:132` (Step 6)
- **内容**:
  - Step 6: `"Write the analysis report to the provided output path, following the template structure"`
  - Step 1: テンプレートファイルを読む指示が存在しない
- **問題**: Lead からテンプレートパス (`{{SDD_DIR}}/settings/templates/reboot/analysis-report.md`) が渡されるが、Analyst の Step 1 コンテキスト吸収フェーズにそのテンプレートを読む指示がない。Step 6 の「following the template structure」という表現は、テンプレートを読まずに守ることを期待する曖昧な要求となっている。
- **影響**: テンプレートが実際には読まれずに分析レポートが生成される可能性がある（構造が合わない出力になるリスク）。

---

#### [MEDIUM] sdd-review-self Agent 3 のクライテリアに sdd-reboot/sdd-analyst 固有検証が未追加

- **ファイル**: `framework/claude/skills/sdd-review-self/SKILL.md:139-156`
- **内容**: Agent 3 (Consistency & Dead Ends) のレビュークライテリアは 7 項目のみ。sdd-reboot/sdd-analyst 統合の整合性検証（本タスクの 8-10 クライテリア）が含まれない。
- **問題**: フレームワーク自体のセルフレビューが新機能（reboot/analyst）の整合性を自動検証できない。今後の変更で不整合が蓄積するリスクがある。

---

#### [MEDIUM] reboot.md Phase 7 マルチウェーブ実行時の中間 session.md 自動ドラフトが未定義

- **ファイル**: `framework/claude/skills/sdd-reboot/refs/reboot.md:275`
- **内容**: reboot.md は Phase 10 でのみ `session.md` 自動ドラフトを指示している。
- **問題**: `run.md` では「Wave QG post-gate、user escalation、pipeline completion のみで auto-draft」と明示されているが、reboot.md にはウェーブ境界での auto-draft ルールが全く記述されていない。複数ウェーブの reboot 処理が中断された場合、`session.md` がウェーブ単位で更新されないため、再開時にコンテキストが失われる可能性がある。

---

#### [LOW] CLAUDE.md の Analyst 完了レポート説明と sdd-analyst.md の実際の出力形式が微妙に不整合

- **ファイル**: `framework/claude/CLAUDE.md:41` vs `framework/claude/agents/sdd-analyst.md:155-162`
- **内容**:
  - `CLAUDE.md`: `"return only structured summary (spec count, wave count, steering changes, report path)"`
  - `sdd-analyst.md` 実際の出力: `ANALYST_COMPLETE` キーワード + `New specs:` + `Waves:` + `Steering:` + `Capabilities found:` + `WRITTEN:{report_path}`
- **問題**: `CLAUDE.md` は「structured summary のみ返す」と述べているが、Analyst は `WRITTEN:{report_path}` を含んだ複合フォーマットを返す。`WRITTEN:` は他の Review SubAgent の返却形式（`return ONLY WRITTEN:{path}`）と混同される可能性がある。実質的に矛盾ではないが、説明の粒度が異なる。

---

#### [LOW] reboot.md Phase 6a でドット接頭辞ディレクトリ（.wave-context/, .cross-cutting/）がアーカイブされない

- **ファイル**: `framework/claude/skills/sdd-reboot/refs/reboot.md:85-86`
- **内容**:
  - Phase 6a: `"excluding dot-prefixed like .wave-context/, .cross-cutting/"` → アーカイブ対象外
  - Phase 6b: `"including dot-prefixed meta-dirs"` → 削除対象
- **問題**: `.wave-context/` や `.cross-cutting/` に保存されている波構造コンテキストや cross-cutting ブリーフが削除されるが旧スペックバックアップには含まれない。old-specs/ アーカイブからの完全な状態復元が不可能になる可能性がある。ただし、これは設計上意図された挙動の可能性もある（transient context として扱う）。

---

### Confirmed OK

- **フェーズ名の一貫性**: `initialized` → `design-generated` → `implementation-complete` (also: `blocked`) が CLAUDE.md、run.md、design.md、impl.md、reboot.md、init.yaml 全てで統一されている
- **SubAgent 名の一貫性**: settings.json の全 `Task(sdd-*)` エントリに対応する `framework/claude/agents/sdd-*.md` ファイルが存在する（26エージェント全確認済み）
- **Skill エントリの一貫性**: settings.json の全 `Skill(sdd-*)` エントリに対応する `framework/claude/skills/sdd-*/` ディレクトリが存在する（7スキル全確認済み）
- **CPF 形式**: severity codes (C/H/M/L)、VERDICT 値 (GO/CONDITIONAL/NO-GO/SPEC-UPDATE-NEEDED) が Auditor 定義と review.md で統一されている
- **リトライ上限の一貫性**: retry_count max 5、aggregate cap 6 が CLAUDE.md:176、run.md:179,194,196、reboot.md:180 で一致している
- **Dead-Code Review リトライ例外**: CLAUDE.md:177 の「max 3 retries」が run.md:248 の記述と一致している
- **Readiness Rules の一致**: reboot.md Phase 7 の Modified Readiness Rules が run.md §Readiness Rules のサブセット（Design + Design Review のみ）として正確に記述されている
- **Review Decomposition プロトコルの参照一致**: reboot.md Phase 7 が `refs/run.md §Review Decomposition` を明示的に参照し、DISPATCH-INSPECTORS / INSPECTORS-COMPLETE / AUDITOR-COMPLETE の3ステップを同一内容で記述している
- **Design Inspector 6名の一致**: CLAUDE.md:27、review.md:25、reboot.md:173 が `rulebase, testability, architecture, consistency, best-practices, holistic` の6名で一致している
- **ConventionsScanner Mode: Generate の入力パラメータ一致**: reboot.md Phase 3 と run.md Step 2.5 のディスパッチプロンプト構造 (Mode, Steering, Buffer, Template, Output, Identifier/Wave) が一致している
- **Analyst MUST NOT read specs 制約の一致**: sdd-analyst.md:15,34 と reboot.md Phase 4 の `"DO NOT pass specs path"` が同じ設計意図を異なる視点から記述しており矛盾しない
- **analysis-report.md テンプレートの実在**: `framework/claude/sdd/settings/templates/reboot/analysis-report.md` が存在し、reboot.md Phase 4 で渡されるテンプレートパスが解決できる
- **sdd-analyst background: true**: YAML frontmatter の `background: true` が CLAUDE.md「run_in_background: true always」ルールと整合している
- **Input state 定義の一致**: reboot.md Phase 1 の `full-reboot / code-only / partial` 判定ロジックが sdd-analyst.md の Input state 説明と一致している
- **Steering テンプレートの実在**: sdd-analyst.md が参照する `{{SDD_DIR}}/settings/templates/steering/` 配下に product.md / tech.md / structure.md が存在する
- **Phase 10 コミット対象**: reboot.md Phase 10 はブランチ上の全変更をステージング・コミット。Phase 2 でブランチを作成し作業するため、main への意図しない変更はない
- **sdd-reboot SKILL.md の allowed-tools**: `Task, Bash, Glob, Grep, Read, Write, Edit, AskUserQuestion` が reboot.md の全操作（git コマンド Bash、ConventionsScanner/Analyst Task ディスパッチ、Phase 5 AskUserQuestion）をカバーしている
- **abort/Abort フロー一致**: SKILL.md「User aborts at Phase 5 → Return to main, delete branch, record in decisions.md」と reboot.md Phase 5 `"git checkout main && git branch -D reboot/{branch_name}. Record USER_DECISION in decisions.md. Stop."` が一致している
- **Design Review 枯渇時の対応一致**: SKILL.md「Design Review exhaustion | Escalate to user: fix / skip / abort」と reboot.md Phase 7 Verdict Handling「On exhaustion: escalate to user (fix/skip/abort)」が一致している
- **CLAUDE.md Commands (6) カウント**: framework 版 CLAUDE.md の Commands 表に sdd-reboot が追加され、count が正しく (6) になっている
- **Profiles ディレクトリの実在**: CLAUDE.md:126 に `Profiles: {{SDD_DIR}}/settings/profiles/` と記載されており、`framework/claude/sdd/settings/profiles/` ディレクトリが存在する（python.md, rust.md, typescript.md, _index.md）
- **verdicts.md パスの一貫性**: review.md が定義する `self-review → {{SDD_DIR}}/project/reviews/self/verdicts.md` が sdd-review-self SKILL.md の `$SCOPE_DIR = {{SDD_DIR}}/project/reviews/self/` と一致している

---

### Cross-Reference Matrix

| Source | References | Target | Status |
|--------|-----------|--------|--------|
| CLAUDE.md | Analyst T2 ロール定義 | sdd-analyst.md | OK |
| CLAUDE.md | Analyst 出力: analysis-report.md | reboot.md Phase 4 output path | OK |
| CLAUDE.md | SubAgent Failure Handling | Analyst 未列挙 | **GAP (MEDIUM)** |
| CLAUDE.md | Commands (6) | sdd-reboot SKILL.md 存在 | OK |
| CLAUDE.md | commit 形式 3種 | reboot.md Phase 10 `reboot:` | **MISSING (MEDIUM)** |
| SKILL.md(reboot) | Analyst failure: BLOCK+cleanup | reboot.md Phase 4: BLOCK only | **CONFLICT (HIGH)** |
| SKILL.md(reboot) | refs/reboot.md | reboot.md 全フェーズ (10) | OK |
| reboot.md Phase 3 | sdd-conventions-scanner | sdd-conventions-scanner.md | OK |
| reboot.md Phase 3 | template/wave-context/conventions-brief.md | テンプレート存在 | OK |
| reboot.md Phase 4 | sdd-analyst | sdd-analyst.md | OK |
| reboot.md Phase 4 | template/reboot/analysis-report.md | テンプレート存在 | OK |
| reboot.md Phase 4 | ANALYST_COMPLETE 待機 | sdd-analyst.md 出力形式 | OK |
| reboot.md Phase 6c | template/specs/init.yaml | ファイル存在 | OK |
| reboot.md Phase 6c | template/specs/design.md | ファイル存在 | OK |
| reboot.md Phase 7 | run.md §Review Decomposition | run.md 一致 | OK |
| reboot.md Phase 7 | run.md §Readiness Rules | run.md 一致(サブセット) | OK |
| reboot.md Phase 7 | Wave Context(conventions-brief) | reboot/conventions-brief.md (Phase 3 出力) | OK |
| reboot.md Phase 7 | shared-research → .wave-context/{wave-N}/ | run.md Step 2.5 と一致 | OK |
| sdd-analyst.md | steering templates | 実在 | OK |
| sdd-analyst.md | Step 1: テンプレート読み込み | 指示なし | **GAP (MEDIUM)** |
| sdd-analyst.md | WRITTEN:{report_path} を含む出力 | CLAUDE.md「return only structured summary」 | **MINOR MISMATCH (LOW)** |
| run.md Step 2.5 | ConventionsScanner Output: `.sdd/` ハードコード | 他パス: `{{SDD_DIR}}` 使用 | **NOTATION INCONSISTENCY (MEDIUM)** |
| settings.json | Task(sdd-analyst) | sdd-analyst.md 存在 | OK |
| settings.json | Skill(sdd-reboot) | sdd-reboot/ 存在 | OK |
| settings.json | 全 Task/Skill エントリ | 全ファイル/ディレクトリ存在 | OK |
| sdd-review-self | Agent 3 クライテリア 7項目 | reboot/analyst 固有チェック未定義 | **GAP (MEDIUM)** |
| CLAUDE.md | run.md Step 2.5, impl.md Pilot Stagger | Wave Context 参照先存在 | OK |
| review.md | self-review verdicts パス | sdd-review-self SCOPE_DIR | OK |

---

### Overall Assessment

**合計 Issues**: HIGH 1件、MEDIUM 5件、LOW 2件

**最重要**: HIGH の Analyst 失敗時ハンドリング矛盾（SKILL.md vs reboot.md）は同一失敗シナリオに対する異なる動作定義であり、Lead が `reboot.md` に従うと Git ブランチクリーンアップが実行されない可能性がある。`reboot.md` Phase 4 を SKILL.md と整合させる修正が必要。

**新規追加コンポーネント（sdd-reboot/sdd-analyst）の全体評価**: 既存フレームワーク概念（Readiness Rules、Review Decomposition、Wave Context）との整合は概ね良好。主要な参照先テンプレート・エージェント・スキルファイルは全て実在する。既存フレームワークとの接続点（SubAgent Failure Handling の列挙漏れ、commit 形式の未登録、sdd-review-self Agent 3 クライテリア不足）に中程度のドキュメント不整合が残る。機能的なブロッカーは HIGH の1件のみ。
