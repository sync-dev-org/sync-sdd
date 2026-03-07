## Consistency & Dead Ends Report

**Generated**: 2026-03-03T16:38:37+0900
**Agent**: 3 (Consistency & Dead Ends)
**Scope**: framework/ 全ファイル + install.sh

---

### Issues Found

#### [HIGH] H1: `sdd-release` Step 3.3 カウント検証ロジックと実態の乖離

**Location**: `framework/claude/skills/sdd-release/SKILL.md:134`

**内容**:
```
Count `framework/claude/skills/sdd-*/SKILL.md` files → verify `### Commands (N)` matches
```
現在、`framework/claude/skills/sdd-*/SKILL.md` は **8 ファイル**存在する:
`sdd-reboot`, `sdd-status`, `sdd-release`, `sdd-publish-setup`, `sdd-steering`, `sdd-handover`, `sdd-roadmap`, `sdd-review-self`

一方、`framework/claude/CLAUDE.md` の `### Commands (7)` テーブルにはユーザー向け 7 コマンドのみ列挙されており、`sdd-review-self` は意図的に除外されている（フレームワーク内部ツール）。

**問題**: `sdd-release` は「全 SKILL.md ファイル数を数えて Commands (N) と照合せよ」と指示しているが、この手順に従うと「8 ≠ 7」となり誤ったカウント不一致を報告してしまう。`sdd-review-self` を除外する条件が未記述。

**影響**: リリース時に誤ったエラーが発生するか、リリース担当者が CLAUDE.md の Commands 数を 8 に更新してしまう（意図と逆行）。

**修正案**: Step 3.3 を「`sdd-review-self` を除く SKILL.md ファイル数 → Commands (N) と照合」に修正する。

---

#### [HIGH] H2: `sdd-auditor-dead-code` の SCOPE フィールドが dead-code 専用スコープを定義していない

**Location**: `framework/claude/agents/sdd-auditor-dead-code.md:147`

**内容**: Output Format の `SCOPE` フィールドが:
```
SCOPE:{feature} | cross-check
```
と定義されているが、dead-code review において SCOPE に `feature` が渡されることはない。実際の review.md では dead-code review のスコープは固定でプロジェクト全体。

対して dead-code Inspector 4 本 (`sdd-inspector-dead-code.md` 等) の Output Format はすべて `SCOPE:dead-code` (固定文字列) を使用している。

**問題**: Auditor と Inspector の SCOPE フィールドが不一致。Auditor が `SCOPE:dead-code` を出力するのか `SCOPE:cross-check` を出力するのか不明確。

**影響**: verdicts.md に記録されるスコープ文字列が不統一になる可能性がある（verdicts.md 解析ロジックへの影響）。

**修正案**: Auditor dead-code の SCOPE を `SCOPE:dead-code` に統一する。

---

#### [MEDIUM] M1: `run.md` Step 2 末尾の `buffer.md` 注記が文脈から逸脱している

**Location**: `framework/claude/skills/sdd-roadmap/refs/run.md:23`

**内容**:
```
6. buffer.md: Lead has exclusive write access
```
これは「Cross-Spec File Ownership Analysis」セクション（Step 2）の手順リストの第 6 項として記述されている。しかし、ファイルオーナーシップ分析の文脈（「どの spec の Builder がどのファイルを担当するか」）に `buffer.md` の書き込み権限は無関係。

**問題**: ファイルオーナーシップ分析の手順に、関係のない `buffer.md` アクセス制約が混入している。他のすべての buffer.md 記述は `handover/` セクションや CLAUDE.md にある。

**影響**: 読み手の混乱（Step 2 の 5 ステップは 1-5 の番号付きリストだが、6 番目として唐突に buffer.md の注記が出現）。

**修正案**: この行を Step 2 から削除するか、CLAUDE.md の Handover セクションや別の適切な場所に移動する。

---

#### [MEDIUM] M2: `conventions-brief.md` テンプレートの `Wave` ヘッダーが 1-spec ロードマップ時に不適切

**Location**: `framework/claude/sdd/settings/templates/wave-context/conventions-brief.md:5`

**内容**:
```
**Wave**: {wave-N}
```

しかし `run.md` Step 2.5 では、1-spec ロードマップの場合の出力先が:
```
{{SDD_DIR}}/project/specs/{feature}/conventions-brief.md
```
と指定されており、Wave 番号ではなく feature 名でパスが決まる。

**問題**: テンプレートヘッダーは常に `Wave: {wave-N}` を要求するが、1-spec ロードマップでは wave 番号は存在せず、ファイルは wave-context ディレクトリではなく feature ディレクトリに置かれる。`Wave: {wave-N}` を feature 名に置き換えるかどうか不明確。

**影響**: 1-spec ロードマップで生成された conventions-brief にリテラル `{wave-N}` または不適切な波番号が記録される可能性。

**修正案**: テンプレートヘッダーを `**Wave/Feature**: {wave-N|feature}` とし、記入ルールを明記する。

---

#### [MEDIUM] M3: `sdd-auditor-dead-code` の Agent 省略名が非公式・未定義

**Location**: `framework/claude/agents/sdd-auditor-dead-code.md:161`

**内容**:
```
Agent names: `settings`, `code`, `specs`, `tests`
```

CPF の Agents フィールド（VERIFIED/REMOVED 行）で使用する省略エージェント名が、このファイル内でのみ定義されている。他の Auditor (`sdd-auditor-impl.md`, `sdd-auditor-design.md`) はエージェント名をフルネーム形式（`rulebase`, `interface`, `test` 等）で使用しており、命名規則が異なる。

また `sdd-inspector-dead-code` の正式 Agent 名は `sdd-inspector-dead-code` だが、CPF 出力での省略名は `code` となる。

**問題**: 省略名 `code` と正式エージェント名 `sdd-inspector-dead-code` の対応が Auditor ファイル内にしか記載されておらず、フレームワーク横断的な規則が存在しない。verdicts.md を解析するロジックがあれば混乱の元になる。

**影響**: LOW〜MEDIUM。現状は Auditor 内で完結しているが、将来の拡張時に混乱リスク。

**修正案**: CPF フォーマットルール (`cpf-format.md`) にエージェント省略名の慣例を記載するか、または dead-code Auditor もフルネームに統一する。

---

#### [LOW] L1: Session Resume ステップ番号が非連番（2a, 5a）

**Location**: `framework/claude/CLAUDE.md` — Session Resume セクション

**内容**: セッション再開手順のステップが `1, 2, 2a, 3, 4, 5, 5a, 6, 7` と非連番になっている。`2a` と `5a` は既存ステップへの追記として挿入されたと思われる。

**問題**: 「ステップ 5a」を実行するためにステップ 5 が先に完了している必要があるのか、独立して実行できるのか（tmux オーファンクリーンアップは「ロードマップがアクティブな場合」と条件付きではない）が番号体系から読み取りにくい。

**影響**: 軽微。読み手の混乱リスクのみ。

**修正案**: 連番化 (1〜9) するか、「2a」「5a」がサブステップである旨をコメントで明記する。

---

#### [LOW] L2: `revise.md` Part A Step 3 の Cross-Cutting エスカレーション条件が Step 4 実行前に判定される旨が不明確

**Location**: `framework/claude/skills/sdd-roadmap/refs/revise.md:43-47`

**内容**:
Step 3 において「User accepts → join Part B Step 2 with target spec pre-populated **(Step 4 has NOT executed — target spec's phase is still `implementation-complete`)**」というカッコ注記がある。

これは Step 3 で Cross-Cutting モードに移行する場合に重要な前提条件だが、このカッコ書きは括弧内の注記として埋め込まれており目立ちにくい。

**問題**: Part B の実行者がこの前提（target spec の phase が `implementation-complete` のまま）を見落とすと、既に phase が遷移した状態で Part B に入り分類ロジックが誤作動する可能性がある。

**影響**: 軽微。ドキュメントの明瞭性の問題。

**修正案**: カッコ注記を独立した注意書き（`> Note: ...`）として明記する。

---

### Confirmed OK

以下の項目は精査の結果、一貫性が確認された。

1. **Inspector 数の一貫性**: CLAUDE.md (framework) の T3 Inspector 記述「6 design, 6 impl +1 e2e +2 web (impl only; e2e/web are conditional), 4 dead-code」は review.md のスポーン一覧、Auditor の CPF 期待ファイル一覧と完全一致。

2. **エージェントファイル と settings.json の一致**: `framework/claude/agents/sdd-*.md` が 27 ファイル、`settings.json` の `Agent()` エントリも 27 個、名前が完全一致。

3. **SKILL.md と settings.json Skill() エントリの一致**: 8 SKILL.md ファイルに対して 8 個の `Skill()` エントリが存在し完全一致。

4. **バーディクト値の一貫性**: Design/Dead-code Auditor は `GO|CONDITIONAL|NO-GO`、Impl Auditor は `GO|CONDITIONAL|NO-GO|SPEC-UPDATE-NEEDED` — これは CLAUDE.md の「Impl Auditor also: SPEC-UPDATE-NEEDED」記述と一致。

5. **フェーズ名の一貫性**: `initialized → design-generated → implementation-complete`（`blocked` 含む）がすべてのファイルで統一されている。

6. **自動修正カウンター上限の一貫性**: CLAUDE.md、run.md Phase Handlers、revise.md Part B すべてで `retry_count` 最大 5、`spec_update_count` 最大 2、集計上限 6、dead-code 最大 3 が一致。

7. **バーディクト保存パスの一貫性**: review.md の Verdict Destination テーブルは run.md、revise.md の記述と整合。`{{SDD_DIR}}/project/reviews/self/verdicts.md` が sdd-review-self の `$SCOPE_DIR/verdicts.md` と一致。

8. **install.sh のインストールパスと CLAUDE.md のパス参照の一致**: Rules → `.sdd/settings/rules/`、Templates → `.sdd/settings/templates/`、Profiles → `.sdd/settings/profiles/`、Agent Profiles → `.claude/agents/` が全箇所で一致。

9. **CPF ファイル名の一致**: sdd-auditor-impl が期待する 9 CPF ファイル名は review.md の Impl Review スポーンリストと完全一致。sdd-auditor-design の 6 CPF ファイルも同様に一致。sdd-auditor-dead-code の 4 CPF ファイルも一致。

10. **sdd-auditor-impl の「最大 9 エージェント」記述の正確性**: 6 標準 + 1 e2e + 2 web = 9、定義と一致。

11. **Pilot Stagger の「実行 wave」と「ロードマップ wave」の区別**: `impl.md` 内で明確に「refers to tasks.yaml execution waves, not roadmap waves」と明記されており、曖昧さなし。

12. **revise.md の Cross-Cutting エスカレーションパスと Part B 接続**: Part A Step 3 → Part B Step 2 の接続は明示されており、既存ステップとの整合が確認できる。

13. **blocked_info サブフィールドの整合性**: `init.yaml` では `blocked_info: null`（初期値）、run.md Step 6 で `blocked_info.blocked_at_phase`, `blocked_by`, `reason` をセット — テンプレートは初期値のみ定義し runtime に委ねる設計で矛盾なし。

14. **decisions.md のエントリタイプ一貫性**: CLAUDE.md と revise.md の両方で `REVISION_INITIATED`, `USER_DECISION`, `DIRECTION_CHANGE`, `ESCALATION_RESOLVED`, `STEERING_UPDATE`, `STEERING_EXCEPTION`, `SESSION_START/END` が同一セットとして定義。

15. **Wave QG dead-code review のパス**: run.md Step 7b で `reviews/wave/verdicts.md` への保存が明示され、review.md Verdict Destination テーブルの「Wave QG context uses `reviews/wave/verdicts.md`」と一致。

16. **`general-purpose` が settings.json 不要な Built-in**: sdd-review-self での `Agent(subagent_type="general-purpose", ...)` 使用については、SKILL.md Agent 3 説明欄に「`general-purpose` is a Claude Code built-in agent type — it does NOT require a settings.json Agent() entry」と明記されており、settings.json との不一致ではない。

17. **ConventionsScanner 出力パスの一貫性**: run.md Step 2.5 で出力先を Lead が指定（multi-spec: `.wave-context/{wave-N}/conventions-brief.md`、1-spec: `{feature}/conventions-brief.md`）。Scanner 自体は出力先を引数で受け取るため、テンプレートのヘッダーと格納パスは別の問題（M2 参照）。

---

### Overall Assessment

**重大な矛盾や到達不能パスは存在しない。** フレームワークは全体として高い一貫性を保っている。

検出された 7 件の問題:
- **HIGH (2件)**: sdd-release のカウント検証ロジックが `sdd-review-self` を除外していないため、リリース手順で誤ったカウント不一致を報告する可能性がある（H1）。dead-code Auditor の SCOPE フィールドが Inspector と不一致（H2）。
- **MEDIUM (3件)**: run.md Step 2 の buffer.md 注記が文脈から逸脱（M1）、1-spec 用の conventions-brief テンプレートヘッダー問題（M2）、dead-code Auditor の省略エージェント名が非公式（M3）。
- **LOW (2件)**: Session Resume の非連番ステップ番号（L1）、revise.md の前提条件の視認性（L2）。

最も優先度が高い修正対象は **H1**（sdd-release Step 3.3）—次回リリース時に実際に問題が発生するため。**H2** は dead-code review の verdicts.md 記録に影響する可能性があるため次に対処を推奨する。

---

### Cross-Reference Matrix

以下の表は、主要な横断的概念がどのファイルで定義・参照されているかを示す。「○」は定義または整合確認済みを意味する。「△」は部分的問題あり（上記 Issues 参照）。

| 概念 | CLAUDE.md | run.md | review.md | impl.md | revise.md | sdd-auditor-impl | sdd-auditor-dead-code | sdd-release SKILL.md |
|------|-----------|--------|-----------|---------|-----------|-------------------|-----------------------|----------------------|
| フェーズ名 (initialized/design-generated/implementation-complete/blocked) | ○ | ○ | ○ | ○ | ○ | ○ | — | — |
| バーディクト値 (GO/CONDITIONAL/NO-GO/SPEC-UPDATE-NEEDED) | ○ | ○ | ○ | — | ○ | ○ | ○ | — |
| Inspector 数 (6+1+2, 6, 4) | ○ | — | ○ | — | — | ○ | ○ | — |
| SKILL.md カウント検証 | ○ (7) | — | — | — | — | — | — | △ (全ファイル数=8と照合) |
| 自動修正カウンター上限 (5/2/6/3) | ○ | ○ | — | — | ○ | — | — | — |
| buffer.md 書き込み権限 | ○ | △ (Step 2 末尾に脈絡なく出現) | — | ○ | — | — | — | — |
| Conventions brief 出力パス | — | ○ | — | ○ | — | — | — | — |
| Conventions brief テンプレートヘッダー | — | ○ | — | — | — | — | — | — |
| dead-code Auditor SCOPE フィールド | — | — | — | — | — | — | △ (feature|cross-check、inspectorはdead-code) | — |
| decisions.md エントリタイプ | ○ | — | — | — | ○ | — | — | — |
| Wave QG dead-code パス | ○ | ○ | ○ | — | — | — | — | — |
| install.sh → CLAUDE.md パス対応 | ○ | — | — | — | — | — | — | — |
| blocked_info サブフィールド | ○ | ○ | — | — | — | — | — | — |
| Pilot Stagger (execution wave ≠ roadmap wave) | — | — | — | ○ | — | — | — | — |
| Session Resume ステップ体系 | △ (非連番 2a/5a) | — | — | — | — | — | — | — |
| Agent省略名 (settings/code/specs/tests) | — | — | — | — | — | — | △ (このファイル内のみ定義) | — |

**記号凡例**: ○=問題なし、△=問題あり（Issues 参照）、—=このファイルでは言及なし
