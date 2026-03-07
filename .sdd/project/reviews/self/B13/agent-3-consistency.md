## Consistency & Dead Ends Report

**レビュー対象**: SDD フレームワーク全ファイル
**レビュー日**: 2026-02-27
**レビュアー**: Agent 3 (Consistency & Dead Ends)

---

### Issues Found

#### CRITICAL

- [CRITICAL] `VERDICT:ERROR` の出力仕様が一部 Inspector にしか定義されていない / `sdd-inspector-impl-rulebase.md` のみが `VERDICT:ERROR` を定義。`review.md` では「Inspector CPF ファイルに `VERDICT:ERROR` が含まれる場合」の処理を規定しているが、他の設計レビュー系 Inspector (`sdd-inspector-rulebase.md`, `sdd-inspector-architecture.md` 等) や実装系 Inspector はエラー時に何を返すか未定義。エラーが発生した Inspector が `VERDICT:ERROR` を返さない場合、Auditor 側の未完了ファイル検出（`PARTIAL:{inspector-name}|file not found`）のみが頼りとなり、エラーと未実行の区別ができない。
  - 関連ファイル: `framework/claude/skills/sdd-roadmap/refs/review.md:120`, `framework/claude/agents/sdd-inspector-impl-rulebase.md:152-162`, 他 Inspector 各ファイルの Error Handling セクション

- [CRITICAL] 設計レビューの Inspector `sdd-inspector-rulebase.md` の Error Handling は「terminate」するのみで、CPF 形式の出力指示がない。`review.md` は CPF ファイルの存在を前提として Auditor を呼ぶが、terminate 後にファイルが存在しない場合の Auditor 挙動が未定義。`PARTIAL:{inspector-name}|file not found` で扱うとは Auditor 仕様に記述されているが、Inspector 側でそれを保証する記述がない。
  - 関連ファイル: `framework/claude/agents/sdd-inspector-rulebase.md:163-167`, `framework/claude/agents/sdd-auditor-design.md:50`

#### HIGH

- [HIGH] Dead-Code Review の `retry_count` が `spec.yaml` に永続化されない問題 / `run.md` Step 7b にて「Dead Code Review NO-GO: max 3 retries, tracked in-memory by Lead — not persisted to spec.yaml, **restarts at 0 on session resume**」と明示されている。セッション中断・再開時に Dead Code Review の再試行カウントがリセットされ、無限ループのリスクがある。CLAUDE.md では「Dead-Code Review NO-GO: max 3 retries」と記述されているが、この永続化の欠如については記述がなく、振る舞いが矛盾する可能性がある。
  - 関連ファイル: `framework/claude/CLAUDE.md:177`, `framework/claude/skills/sdd-roadmap/refs/run.md:248`

- [HIGH] `sdd-review-self` スキルが `Task(subagent_type="general-purpose", model="sonnet", ...)` を使用しているが、`settings.json` の `allow` リストに `"Task(general-purpose)"` が存在しない。他の Agent は全て `"Task(sdd-XXX)"` 形式で許可されている。`general-purpose` は特殊な組み込み型である可能性があるが、フレームワーク内の一貫性を損なっている。
  - 関連ファイル: `framework/claude/skills/sdd-review-self/SKILL.md:57`, `framework/claude/settings.json:13-38`

- [HIGH] Analyst の `WRITTEN:{path}` 返却仕様の矛盾 / CLAUDE.md では「Analyst: return structured summary (`ANALYST_COMPLETE` + counts + `WRITTEN:{path}`)」と記述。一方 `sdd-analyst.md` の Completion Report では `ANALYST_COMPLETE ... WRITTEN:{report_path}` を合わせて返すと定義。`reboot.md` Phase 4 では「Wait for `ANALYST_COMPLETE` via `TaskOutput`」のみを待つとあり、`WRITTEN:` も期待しているか曖昧。CLAUDE.md の記述と `reboot.md` の受け取り方が一部不整合。
  - 関連ファイル: `framework/claude/CLAUDE.md:41`, `framework/claude/agents/sdd-analyst.md:162-167`, `framework/claude/skills/sdd-reboot/refs/reboot.md:61-62`

- [HIGH] Builder `BUILDER_BLOCKED` 時のファイル未生成に対する Conventions Scanner Supplement フロー / `impl.md` Pilot Stagger Protocol (Step 3) では pilot Builder の `builder-report-{group}.md` パスを `(from WRITTEN:{path} in pilot's summary)` から取得するとある。しかし `BUILDER_BLOCKED` の場合はファイルが作成されず (`Note: BLOCKED reports include the blocker summary inline ... No file write required for BLOCKED`)、`WRITTEN:{path}` が返らない。Pilot が BLOCKED した場合の Supplement フローが未定義（スキップされるのか、フォールバックがあるのか）。
  - 関連ファイル: `framework/claude/skills/sdd-roadmap/refs/impl.md:63`, `framework/claude/agents/sdd-builder.md:156-163`

- [HIGH] Reboot の Phase 7 Design Pipeline では `reboot.md` の完了条件として「All specs have `phase = design-generated` AND a GO/CONDITIONAL design review verdict in `verdicts.md`」と定義されているが、`reboot.md` Phase 7 内の Review Decomposition は `refs/run.md` を参照して实行するとあるのに、verdicts.md の書き込みパスが `reboot.md` では明示されていない。`run.md` の Review Decomposition はパスを `{scope-dir}` に依存するが、reboot 実行時の `scope-dir` が何かを `reboot.md` では指定していない。
  - 関連ファイル: `framework/claude/skills/sdd-reboot/refs/reboot.md:177`, `framework/claude/skills/sdd-roadmap/refs/run.md:119-140`

- [HIGH] Cross-Cutting Mode の Wave Context Generation で ConventionsScanner 出力パスが未指定 / `revise.md` Part B Step 7 の「Wave Context Generation」では「Dispatch `sdd-conventions-scanner` (mode: Generate) per run.md Step 2.5」と記述されているが、run.md Step 2.5 の出力パスは「`.sdd/project/specs/.wave-context/{wave-N}/conventions-brief.md`（multi-spec）or `.sdd/project/specs/{feature}/conventions-brief.md`（1-spec）」と定義されており、Cross-Cutting の場合はどちらのパスを使うべきか不明確。cross-cutting は wave 構造でも 1-spec でもない。
  - 関連ファイル: `framework/claude/skills/sdd-roadmap/refs/revise.md:214`, `framework/claude/skills/sdd-roadmap/refs/run.md:38`

#### MEDIUM

- [MEDIUM] 設計レビュー Auditor (`sdd-auditor-design.md`) のフォーマット例と実際の記述が一部不一致 / Auditor の Output Format には `SCOPE:{feature} | cross-check | wave-scoped-cross-check` と記述されているが、実際には `|` で区切られた選択肢ではなく、モードによって異なる単一値が入る。初見では複数値を記述するように見える。CPF 形式規則では `|` はフィールド区切り文字であり、混乱を生む可能性がある。
  - 関連ファイル: `framework/claude/agents/sdd-auditor-design.md:189`, `framework/claude/agents/sdd-auditor-impl.md:244`

- [MEDIUM] `sdd-status` スキルが `--impact` フラグなしで `{{SDD_DIR}}/project/specs/.cross-cutting/*/` をスキャンするとしているが、一方で機能説明が「`[feature-name]` と `[--impact]` のオプション引数を受け付ける」とのみ記述されており、cross-cutting スキャンが常時実行されるかどうかが `argument-hint` と本文の間で曖昧。
  - 関連ファイル: `framework/claude/skills/sdd-status/SKILL.md:1-6`, `framework/claude/skills/sdd-status/SKILL.md:27-29`

- [MEDIUM] `reboot.md` Phase 8（Regression Check）では「Phase 7 completed spec `design.md` files」から新能力を抽出するが、Phase 7 で設計レビューが NO-GO で最終的に skip されたスペックの `design.md` が存在しない場合、Phase 8 での抽出ロジックに対応が記述されていない（そのスペックの design.md は seeded skeleton のまま）。
  - 関連ファイル: `framework/claude/skills/sdd-reboot/refs/reboot.md:201-232`

- [MEDIUM] `sdd-conventions-scanner.md` の Supplement モードでは入力として「Builder report path」「Existing brief path」「Output path」しか受け取らないが、Supplement の実行前提として Pilot Builder が正常完了していることが必要。`BUILDER_BLOCKED` の場合の対処を Supplement モード仕様が持っていない（HIGH 項目と関連）。
  - 関連ファイル: `framework/claude/agents/sdd-conventions-scanner.md:44-60`

- [MEDIUM] `impl.md` Step 3 の「COMPLETED WITHOUT TASK SPEC」ケースでユーザに A/B/C を提示するが、後続の動作として C (Abort) のみが自明で、A と B は impl.md 他ステップへの参照がない。A（task-numbers 指定）は「TASK RE-EXECUTION」モードになるだけとは読み取れるが、明示されていない。
  - 関連ファイル: `framework/claude/skills/sdd-roadmap/refs/impl.md:22-23`

- [MEDIUM] `design.md` テンプレートには `## Supporting References (Optional)` セクションがあるが、`sdd-inspector-rulebase.md` の SDD Compliance チェック（0.1 Template Conformance）では `design-review.md` のチェックリストに Supporting References は含まれておらず、存在・不存在どちらの状態が期待されるかが ambiguous。
  - 関連ファイル: `framework/claude/sdd/settings/templates/specs/design.md:298-302`, `framework/claude/sdd/settings/rules/design-review.md:28-39`, `framework/claude/agents/sdd-inspector-rulebase.md:50-70`

- [MEDIUM] `revise.md` Part A Step 6 の「downstream resolution」においてオプション (d) Cross-cutting revision を選択した際に「join Part B Step 2」とあるが、Part B Step 2 では `implementation-complete` フェーズのスペックが対象であると明示（Step 2 冒頭: "only `implementation-complete` phase is eligible for revision"）。Part A Step 4 でターゲットスペックは既に `phase = design-generated` にリセットされており、Part B に引き渡す前に対象が eligibility 条件を満たさなくなる矛盾がある。
  - 関連ファイル: `framework/claude/skills/sdd-roadmap/refs/revise.md:93-95`, `framework/claude/skills/sdd-roadmap/refs/revise.md:120-121`

- [MEDIUM] `sdd-review-self` スキルの Agent 3 プロンプト仕様（Consistency & Dead Ends エージェント）の出力形式に `### Cross-Reference Matrix` が要求されているが、Agent 2 (Change-Focused) と Agent 4 (Platform Compliance) にはそれぞれ異なるフォーマット（Compliance Status Table など）が指示されており、各エージェントの出力フォーマット要件が統一されていない。これは意図的な仕様であるが、review.md のどこにも説明がない。
  - 関連ファイル: `framework/claude/skills/sdd-review-self/SKILL.md:57-198`

#### LOW

- [LOW] `CLAUDE.md` の Inspector 説明「6 design, 6 impl +2 web (impl only, web projects), 4 dead-code」は合計 18（または 16 非 web + 2 web）だが、`settings.json` には 6+6+2+4 = 18 の Inspector が全て登録されている。CLAUDE.md の表現が「+2 web」という追加表記のため、常に 16 が基本で web が追加であると読めるが、settings.json では 18 全てが listed。web プロジェクトでない場合は sdd-inspector-e2e と sdd-inspector-visual が `allow` にあっても使われないだけであり、矛盾はないが、記述上の混乱を生む可能性がある。
  - 関連ファイル: `framework/claude/CLAUDE.md:27`, `framework/claude/settings.json:27-28`

- [LOW] `install.sh` の summary 出力で「skills」と「agent profiles」のカウント表示に差異がある。skills カウントは `SKILL.md` ファイルを数え、agent profiles は `sdd-*.md` ファイルを数えるため、カウント方法が異なる。`sdd-review-self` の SKILL.md には `agent-N-{name}.md` 形式のファイルが生成されるが、これは agents ディレクトリではなく `reviews/self/active/` に書かれるため、実際の agent カウントとは無関係。表示の一貫性には問題ないが、README などとの整合性確認が必要。
  - 関連ファイル: `install.sh:582-583`

- [LOW] `sdd-steering` スキルの profile 選択ロジックで「`spec.yaml.language` フィールドに profile identifier を保存する」と `profiles/_index.md` に記述されているが、`spec.yaml` テンプレート (`init.yaml`) には `language` フィールドが存在しており整合している。ただし、`CLAUDE.md` の Paths セクションや `init.yaml` の `language` フィールドの説明が不完全（どのような値が期待されるか未記述）。
  - 関連ファイル: `framework/claude/sdd/settings/profiles/_index.md:14`, `framework/claude/sdd/settings/templates/specs/init.yaml:4`

- [LOW] `run.md` Step 2（Cross-Spec File Ownership Analysis）と Step 2.5（Wave Context Generation）の順序について、Step 2 では「Design-generated specs の design.md を読む（`design.md` がない specs はスキップ）」とあるが、Step 2 は Run 開始時に一度のみ実行されるのか、各フェーズで都度実行されるのかが不明確。Step 4 Phase Handlers の「Implementation completion」では「Cross-Spec File Ownership (Layer 2): after TaskGenerator, detect file overlap...」と Layer 2 として再度言及されており、Step 2 との関係が「Layer 1」「Layer 2」という表現のみで説明されているが、両者の役割分担が一部 readers には曖昧。
  - 関連ファイル: `framework/claude/skills/sdd-roadmap/refs/run.md:14-25`, `framework/claude/skills/sdd-roadmap/refs/run.md:187`

---

### Confirmed OK

- **フェーズ名の統一性**: `initialized` → `design-generated` → `implementation-complete` → `blocked` の 4 値が CLAUDE.md、spec.yaml テンプレート、各 refs、status スキルで一貫して使用されている。
- **verdict 値の統一性**: `GO` / `CONDITIONAL` / `NO-GO` の 3 値（Impl Auditor は追加で `SPEC-UPDATE-NEEDED`）が全 Auditor 定義、review.md、run.md で一貫して使用されている。
- **SubAgent 名の一貫性**: `sdd-analyst`, `sdd-architect`, `sdd-builder`, `sdd-taskgenerator`, `sdd-conventions-scanner`, `sdd-auditor-design`, `sdd-auditor-impl`, `sdd-auditor-dead-code`, 各 Inspector 名が CLAUDE.md、settings.json、各 refs の dispatch 指示で一致している。
- **retry_count / spec_update_count の数値**: CLAUDE.md「max 5」「max 2」「aggregate cap 6」が run.md、revise.md と一貫している。Dead-Code Review の「max 3」も CLAUDE.md と run.md で一致。
- **CPF フォーマット**: Severity コード `C/H/M/L`、セクション区切り、`+` によるエージェント列挙が cpf-format.md と全 Inspector/Auditor 出力例で一致している。
- **ファイルパス構造**: `{{SDD_DIR}}/project/specs/{feature}/reviews/` 以下の構造（`active/`, `B{seq}/`, `verdicts.md`）が review.md と CLAUDE.md、各 Auditor で一致している。
- **builder-report パス**: `{{SDD_DIR}}/project/specs/{feature}/builder-report-{group}.md` が sdd-builder.md、impl.md（Pilot Stagger）、CLAUDE.md で一致している。
- **session.md auto-draft トリガ**: run pipeline 中は Wave QG / user escalation / pipeline completion のみ。個別フェーズ完了時はスキップ。run.md、impl.md、CLAUDE.md で一貫している。
- **WRITTEN:{path} 返却規約**: Inspector/Auditor/ConventionsScanner/Analyst が `WRITTEN:{path}` を返し、Lead が on-demand で読み込む。CLAUDE.md と各エージェント定義で一致している。
- **tasks.yaml フォーマット**: `tasks-generation.md` の YAML スキーマと sdd-builder.md の読み込み方法、sdd-taskgenerator.md の生成指示が一致している。
- **Blocking Protocol**: run.md Step 6 の `phase=blocked` 設定と CLAUDE.md Phase Gate の `blocked` チェック、revise.md Step 1 の BLOCK 条件が一致している。
- **ConventionsScanner の2モード（Generate/Supplement）**: run.md Step 2.5、impl.md Pilot Stagger、reboot.md Phase 3 での呼び出しと sdd-conventions-scanner.md のモード定義が整合している。
- **session.md テンプレートへの参照**: CLAUDE.md と sdd-handover SKILL.md の両方が `{{SDD_DIR}}/settings/templates/handover/session.md` を参照しており、ファイルが存在している。
- **install.sh のエージェントインストールパス**: `framework/claude/agents/` → `.claude/agents/`、`framework/claude/skills/` → `.claude/skills/` のマッピングが正しく、settings.json の `allow` エントリと整合している。
- **Steering Feedback Loop**: CLAUDE.md の `CODIFY`/`PROPOSE` 定義と review.md の処理手順、sdd-auditor-design/impl の `STEERING:` セクション定義が一貫している。
- **decisions.md のエントリ型**: CLAUDE.md と sdd-handover SKILL.md、revise.md の記述が一致（`USER_DECISION`, `STEERING_UPDATE`, `DIRECTION_CHANGE`, `ESCALATION_RESOLVED`, `REVISION_INITIATED`, `STEERING_EXCEPTION`, `SESSION_START`, `SESSION_END`）。
- **Reboot のブランチ命名**: `reboot/{name}` が sdd-reboot SKILL.md と reboot.md で一貫して使用されている。
- **Wave QG の skip 条件**: 1-Spec Roadmap では Wave QG をスキップ。CLAUDE.md、run.md Step 7 で明示されており一致している。
- **Design Review の Impl Auditor からの SPEC-UPDATE-NEEDED 除外**: 設計レビューでは SPEC-UPDATE-NEEDED は期待されない（escalate immediately）。run.md と revise.md で一致している。
- **sdd-release スキルのエコシステム検出優先度**: SDD Framework repo 検出 (`framework/claude/CLAUDE.md` の存在確認) が明確に定義されており、install.sh の SDD_VERSION 挿入機構と整合している。

---

### Cross-Reference Matrix

| ソースファイル | 参照先ファイル | 参照内容 | 整合性 |
|---|---|---|---|
| CLAUDE.md | refs/run.md | Auto-fix loop, Wave QG, Blocking Protocol | OK |
| CLAUDE.md | refs/review.md | Steering Feedback Loop 詳細 | OK |
| CLAUDE.md | refs/revise.md | Revision flow | OK |
| CLAUDE.md | cpf-format.md | CPF 仕様 | OK |
| sdd-roadmap/SKILL.md | refs/design.md | Design 実行 | OK |
| sdd-roadmap/SKILL.md | refs/impl.md | Impl 実行 | OK |
| sdd-roadmap/SKILL.md | refs/review.md | Review 実行 | OK |
| sdd-roadmap/SKILL.md | refs/run.md | Run 実行 | OK |
| sdd-roadmap/SKILL.md | refs/revise.md | Revise 実行 | OK |
| sdd-roadmap/SKILL.md | refs/crud.md | Create/Update/Delete | OK |
| refs/run.md | refs/design.md | Design Handler 参照 | OK |
| refs/run.md | refs/impl.md | Impl Handler 参照 (Steps 1-3) | OK |
| refs/run.md | refs/review.md | Review Decomposition 参照 | OK |
| refs/revise.md | refs/design.md | Design dispatch | OK |
| refs/revise.md | refs/impl.md | Impl dispatch | OK |
| refs/revise.md | refs/review.md | Review dispatch | OK |
| refs/revise.md | refs/run.md | Dispatch Loop pattern | OK |
| refs/revise.md | refs/crud.md | Spec split/merge | OK |
| sdd-reboot/SKILL.md | refs/reboot.md | 実行詳細 | OK |
| reboot.md | refs/run.md | Phase 7 Dispatch Loop 参照 | ISSUE（scope-dir 未指定 → HIGH） |
| sdd-review-self/SKILL.md | sdd-XXX agents | Task dispatch | ISSUE（general-purpose が settings.json 未登録 → HIGH） |
| sdd-auditor-design.md | cpf-format.md | CPF 出力形式 | OK |
| sdd-auditor-impl.md | cpf-format.md | CPF 出力形式 | OK |
| sdd-auditor-dead-code.md | cpf-format.md | CPF 出力形式 | OK |
| sdd-inspector-*.md | cpf-format.md | CPF 出力形式 | OK |
| sdd-inspector-impl-rulebase.md | review.md | VERDICT:ERROR 定義 | ISSUE（他 Inspector には定義なし → CRITICAL） |
| sdd-builder.md | impl.md | builder-report パス | OK |
| sdd-conventions-scanner.md | impl.md (Pilot Stagger) | Supplement モード呼び出し | ISSUE（BUILDER_BLOCKED 時未定義 → HIGH） |
| sdd-analyst.md | reboot.md | ANALYST_COMPLETE 返却 | ISSUE（WRITTEN: との組み合わせが曖昧 → HIGH） |
| sdd-taskgenerator.md | impl.md | TASKGEN_COMPLETE 返却 | OK |
| sdd-architect.md | design.md, run.md | ARCHITECT_COMPLETE 返却 | OK |
| init.yaml | SKILL.md (roadmap) | spec.yaml テンプレート | OK |
| design.md (template) | design-principles.md | 構造準拠 | OK |
| design-review.md | sdd-inspector-rulebase.md | Rulebase チェック内容 | ISSUE（Supporting References の扱いが曖昧 → MEDIUM） |
| session.md (template) | CLAUDE.md, sdd-handover | ハンドオーバー形式 | OK |
| buffer.md (template) | CLAUDE.md | buffer 形式 | OK |
| analysis-report.md (template) | sdd-analyst.md | 分析レポート形式 | OK |
| conventions-brief.md (template) | sdd-conventions-scanner.md | Brief 形式 | OK |
| settings.json | agents/*.md | Task 許可リスト | ISSUE（general-purpose 未登録 → HIGH） |
| install.sh | framework/claude/ | インストールパス | OK |
| install.sh | VERSION | バージョン取得 | OK |
| profiles/_index.md | sdd-steering/SKILL.md | プロファイル選択フロー | OK |
| steering-principles.md | sdd-steering/SKILL.md | ステアリング原則 | OK |
| tasks-generation.md | sdd-taskgenerator.md | タスク生成ルール | OK |
| design-discovery-full.md | sdd-architect.md | Discovery 手順 | OK |
| design-discovery-light.md | sdd-architect.md | Discovery 手順 | OK |

---

### Overall Assessment

全体的なフレームワークの一貫性は高水準であり、主要なプロトコル（フェーズ名、verdict 値、SubAgent 名、リトライカウント、CPF フォーマット、ファイルパス構造）は全ファイルを通じて正確に統一されている。

**最も重大な問題（CRITICAL）** は `VERDICT:ERROR` の Inspector 間での非均一な定義である。`review.md` が全 Inspector を対象に `VERDICT:ERROR` を処理規則として定めているにもかかわらず、それを出力する仕様を持つ Inspector は `sdd-inspector-impl-rulebase.md` のみである。エラー時に CPF ファイル自体が存在しない場合は Auditor の `PARTIAL:` ノートで対処されるが、Inspector がサイレントに終了した場合の区別が困難である。

**最も重要な修正優先度の高い問題（HIGH）** は以下の4点：
1. Dead-Code Review リトライカウントのセッション間非永続化（潜在的な無限ループリスク）
2. `sdd-review-self` における `general-purpose` Task type の settings.json 未登録
3. `BUILDER_BLOCKED` 時の Pilot Stagger フォールバック未定義
4. `reboot.md` Phase 7 での verdicts.md 書き込みパス未指定

これらのうち、2 の `general-purpose` 問題はフレームワーク自己レビューツールの動作に直接影響し、3 の BUILDER_BLOCKED 問題は pilot stagger を使用する任意の実装フローで発生しうる。

**修正推奨優先度**:

| 優先度 | ID | 概要 | 対象ファイル |
|---|---|---|---|
| 1 | C1 | 全 Inspector に VERDICT:ERROR 出力仕様を追加 | sdd-inspector-*.md (設計系 10+ ファイル) |
| 2 | H2 | settings.json に general-purpose を追加、または sdd-review-self のエージェント種別変更 | settings.json, sdd-review-self/SKILL.md |
| 3 | H3 | BUILDER_BLOCKED 時の Pilot Stagger スキップ/フォールバック明示 | refs/impl.md |
| 4 | H4 | reboot.md Phase 7 での verdicts.md パス明示 | refs/reboot.md |
| 5 | H5 | Dead-Code Review リトライカウントの永続化方針を明示（in-memory の意図的選択であれば CLAUDE.md に注記） | CLAUDE.md, refs/run.md |
| 6 | M6 | revise.md Part A Step 4 後に Part B に移行する際のフェーズ整合性修正 | refs/revise.md |
| 7 | M7 | Cross-Cutting Mode の conventions-brief 出力パスを明示 | refs/revise.md |
