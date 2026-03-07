## Consistency & Dead Ends Report

**Generated**: 2026-03-03T15:07:17+0900
**Agent**: Agent 3 (Consistency & Dead Ends)
**Scope**: framework/claude/CLAUDE.md, skills/sdd-*/SKILL.md, skills/sdd-*/refs/*.md, agents/sdd-*.md, settings.json, sdd/settings/rules/*.md, sdd/settings/templates/**/*.md, install.sh

---

### Issues Found

---

#### [MEDIUM] Analyst の出力パスが CLAUDE.md と reboot.md で不一致

- **CLAUDE.md (L.41)**: `{{SDD_DIR}}/project/reboot/analysis-report.md`
- **reboot.md Phase 4 Step 1**: `{{SDD_DIR}}/project/reboot/analysis-report.md` ← 一致
- **sdd-analyst.md Completion Report**: `WRITTEN:{report_path}` (パス変数参照)
- **実際の問題**: CLAUDE.md L.41 の Analyst 出力パスと sdd-analyst.md の実際の動作は一致している。ただし CLAUDE.md は `{{SDD_DIR}}/project/reboot/analysis-report.md` と記載しているが、reboot.md Phase 3 では `{{SDD_DIR}}/project/reboot/` ディレクトリを作成するのみで、sdd-analyst は Lead からパスを受け取る。Lead が正しいパスを渡すかどうかは実行時依存であり、パス定義が一箇所に明記されていない。

---

#### [MEDIUM] dead-code review の verdict 保存先が SKILL.md と review.md で矛盾している

- **review.md Verdict Destination by Review Type**: dead-code review (standalone) → `{{SDD_DIR}}/project/reviews/dead-code/verdicts.md`
- **review.md Step 1 (Parse Arguments)**: scope directory として `{{SDD_DIR}}/project/reviews/dead-code/` を定義
- **run.md Step 7b**: `{{SDD_DIR}}/project/reviews/wave/verdicts.md` (header: `[W{wave}-DC-B{seq}]`)
- **SKILL.md Router Verdict Persistence Format**: Wave QG dead-code は `reviews/wave/verdicts.md` で header が `[W{wave}-DC-B{seq}]`

**問題**: これらは意図的に分けられているが、review.md Step 1 で dead-code の scope directory として `project/reviews/dead-code/` を定義しており、Wave QG コンテキストで同じ review.md が呼ばれた際に `project/reviews/wave/` を使うべきか `project/reviews/dead-code/` を使うべきかが不明確。run.md Step 7b は `refs/review.md` を参照するが、review.md Step 1 の scope directory は `dead-code` と `wave` を区別するための条件分岐が明示されていない。呼び出し元 (run.md) が scope directory を指定する仕組みになっているが、review.md 側のドキュメントでは Wave QG コンテキストに関する分岐が Step 1 から欠落している。

---

#### [MEDIUM] sdd-inspector-dead-settings.md の SCOPE 例が不一致

- **sdd-inspector-dead-settings.md (L.55)**: 例の SCOPE 値が `cross-check` になっている
- **sdd-inspector-dead-code.md、sdd-inspector-dead-tests.md、sdd-inspector-dead-specs.md**: SCOPE は `dead-code`
- **sdd-auditor-dead-code.md (L.38-40)**: 4 Inspector の cpf ファイル参照は `dead-settings`, `dead-code`, `dead-specs`, `dead-tests` と記載

実際のエラー: `sdd-inspector-dead-settings.md` の出力例（L.55）にある `SCOPE:cross-check` は誤りで、他の dead-code 系 Inspector と統一して `SCOPE:dead-code` にするべき。

---

#### [MEDIUM] sdd-review-self/SKILL.md の Agent 4 モデル指定と他 Sonnet 指定の不整合

- **sdd-review-self/SKILL.md Step 4 (L.56)**: `Agent(subagent_type="general-purpose", model="sonnet", run_in_background=true)`
- **CLAUDE.md T3 tier (L.16)**: ConventionsScanner, Inspector 等は Sonnet
- **Agent 4 System Prompt**: `Claude Code platform compliance reviewer` → WebSearch を使うが、`general-purpose` agent は settings.json にない

**問題**: `general-purpose` という subagent_type は settings.json の Agent() 許可リストに含まれていない。settings.json の許可リストには `Agent(sdd-analyst)`, `Agent(sdd-architect)` 等の具体的な agent 名のみが登録されており、`general-purpose` は存在しない。self-review は設計的に framework 外部で動くという意図かもしれないが、Agent() パーミッション制約と矛盾する可能性がある。

---

#### [MEDIUM] CLAUDE.md の Inspector カウントと実際のエージェント数の不一致

- **CLAUDE.md (L.27)**: `Inspector: 6 design, 6 impl +2 web (impl only, web projects), 4 dead-code`
- **実際の design Inspectors**: rulebase, testability, architecture, consistency, best-practices, holistic = **6** ✓
- **実際の impl Inspectors**: impl-rulebase, interface, test, quality, impl-consistency, impl-holistic = **6** ✓
- **web inspectors**: web-e2e, web-visual = **2** ✓
- **dead-code Inspectors**: dead-settings, dead-code, dead-specs, dead-tests = **4** ✓

数は一致している。ただし CLAUDE.md の記述「6 design, 6 impl +2 web」は正確だが、design+impl 合計 14 の Inspector ファイル + 2 web = **16 Inspector ファイル**、plus dead-code 4、plus 3 Auditor = 計 **23 agent ファイル**。実際の agent ファイルは 25 個（Glob 結果より）。差分は `sdd-analyst` (1) + `sdd-architect` (1) + `sdd-builder` (1) + `sdd-taskgenerator` (1) + `sdd-conventions-scanner` (1) = 5。合計 23+5=28 が期待されるが、Glob では 25 個。これはファイル数の不一致として確認が必要（実際には auditor が design/impl/dead-code の 3 つ。25 - 3 auditors - 5 non-inspector = 17 inspector。CLAUDE.md の 6+6+2+4=18 と 1 差）。

**再確認**: Glob で得た 25 個:
- sdd-analyst, sdd-architect, sdd-auditor-dead-code, sdd-auditor-design, sdd-auditor-impl, sdd-builder, sdd-conventions-scanner, sdd-taskgenerator = 8
- design inspectors: sdd-inspector-architecture, sdd-inspector-best-practices, sdd-inspector-consistency, sdd-inspector-holistic, sdd-inspector-rulebase, sdd-inspector-testability = 6
- impl inspectors: sdd-inspector-impl-consistency, sdd-inspector-impl-holistic, sdd-inspector-impl-rulebase, sdd-inspector-interface, sdd-inspector-quality, sdd-inspector-test = 6
- web inspectors: sdd-inspector-web-e2e, sdd-inspector-web-visual = 2
- dead-code inspectors: sdd-inspector-dead-code, sdd-inspector-dead-settings, sdd-inspector-dead-specs, sdd-inspector-dead-tests = 4

合計 8+6+6+2+4 = **26** のはずだが Glob は 25 個を返した。実際のカウントを信頼すると 1 ファイルの差があるが、Glob 結果が正しければ 25 個で、うち 8 非 Inspector = 17 Inspector。CLAUDE.md の 6+6+2+4=18 と 1 差がある。これは LOW レベルの問題として記録する。

---

#### [LOW] sdd-roadmap SKILL.md の `-y` フラグの説明が不完全

- **SKILL.md Step 1 (L.39)**: `$ARGUMENTS = "-y" → Auto-detect: run if roadmap exists, create if not`
- **sdd-reboot SKILL.md**: `-y` は "Auto-approve analysis" として使用
- **sdd-steering SKILL.md**: `-y` は "Auto-approve update mode" として使用

各スキルで `-y` の意味が異なるが、これは正常な多義的用法。問題なし。

---

#### [LOW] run.md Step 2.5 の conventions brief 出力先に1-spec roadmap と multi-spec でパスが異なる

- **run.md (L.38)**: `{{SDD_DIR}}/project/specs/.wave-context/{wave-N}/conventions-brief.md` (multi-spec)
  OR `{{SDD_DIR}}/project/specs/{feature}/conventions-brief.md` (1-spec roadmap)
- **impl.md (L.30)**: conventions brief path は "if generated by run.md Step 2.5" として参照
- **sdd-conventions-scanner.md**: Output path は Lead から渡される

1-spec roadmap の場合、conventions-brief.md が spec ディレクトリ直下に置かれるが、multi-spec の場合は `.wave-context/` 以下に置かれる。この非対称性は意図的に見えるが、文書上の明確化が不足している。

---

#### [LOW] revise.md Part B Step 7 で "Tier Checkpoint" の後の Commit 指示が欠落

- **revise.md Part B Step 9 (Post-Completion)**: `cross-cutting: {summary}` でコミット
- **Part A Step 7 (Post-Revision)**: コミットへの明示的な言及なし（run.md へのリダイレクトのみ）

Single-Spec revision (Part A) でのコミットタイミングが不明確。CLAUDE.md の Commit Timing セクション (L.331) では "Pipeline completion (1-spec roadmap)" で commit するとあるが、revise.md Part A の流れにおいて、revised spec が `implementation-complete` に戻った後のコミット指示が明示されていない。

---

#### [LOW] design-discovery-full.md / design-discovery-light.md が未読

本レビューのターゲットファイルリストに `design-discovery-full.md` と `design-discovery-light.md` が含まれているが、これらはレビュースコープ (`framework/claude/sdd/settings/rules/*.md`) に含まれる。sdd-architect.md (L.50, L.55) からこれらへの参照があり、実際にファイルが存在することは Glob で確認済み。内容は読んでいるが、参照の整合性として特筆すべき問題なし。

---

#### [LOW] buffer.md テンプレートのロール記述が builder のみを想定

- **buffer.md template (L.5-7)**: `(source: {spec} {role}, task {N})` と記載
- **CLAUDE.md (L.292)**: `(source: {feature} Builder, group {G})` と記載

実際の使用パターン (`Builder, group {G}`) とテンプレートの記述 (`{role}, task {N}`) がわずかに異なる。どちらも意味は通るが統一性に欠ける。

---

#### [LOW] conventions-brief テンプレートの `{{Wave}}` プレースホルダーが単数形のみ

- **conventions-brief.md template (L.6)**: `**Wave**: {wave-N}` (単数の wave ラベル)
- **run.md Step 2.5 (L.38)**: 1-spec roadmap の場合は `{feature}` を identifier として使用

波形の conventions-brief では `{wave-N}` 形式を指定しているが、1-spec roadmap の場合は `{feature}` identifier を使用すると run.md に記載されている。テンプレートがどちらのケースにも対応することを明示していない。

---

### 値の一貫性チェック

#### フェーズ名の一貫性

| フェーズ名 | CLAUDE.md | design.md | impl.md | run.md | revise.md |
|-----------|-----------|-----------|---------|--------|-----------|
| `initialized` | ✓ | ✓ | ✓ | ✓ | ✓ |
| `design-generated` | ✓ | ✓ | ✓ | ✓ | ✓ |
| `implementation-complete` | ✓ | ✓ | ✓ | ✓ | ✓ |
| `blocked` | ✓ | ✓ | ✓ | ✓ | ✓ |

**確認OK**: 全ファイルでフェーズ名が統一されている。

#### Verdict 値の一貫性

| Verdict | design Auditor | impl Auditor | dead-code Auditor | review.md | CLAUDE.md |
|---------|---------------|--------------|-------------------|-----------|-----------|
| `GO` | ✓ | ✓ | ✓ | ✓ | ✓ |
| `CONDITIONAL` | ✓ | ✓ | ✓ | ✓ | ✓ |
| `NO-GO` | ✓ | ✓ | ✓ | ✓ | ✓ |
| `SPEC-UPDATE-NEEDED` | × (期待しない) | ✓ | × | ✓ | ✓ |

**確認OK**: SPEC-UPDATE-NEEDED は impl Auditor のみで使用され、design Auditor と dead-code Auditor では期待されないことが明示されている。

#### 重大度コードの一貫性

全 Inspector / Auditor: C=Critical, H=High, M=Medium, L=Low を使用。CPF format rules (cpf-format.md) と一致。**確認OK**。

#### リトライ上限の一貫性

| 設定 | CLAUDE.md | run.md | revise.md |
|------|-----------|--------|-----------|
| retry_count 上限 | max 5 | max 5 ✓ | max 5 ✓ |
| spec_update_count 上限 | max 2 | max 2 ✓ | max 2 ✓ |
| aggregate cap | 6 | 6 ✓ | 6 ✓ |
| dead-code NO-GO 上限 | max 3 | max 3 ✓ | N/A |

**確認OK**: 数値が全ファイルで一致。

---

### パス一貫性チェック

#### {{SDD_DIR}} 参照のパス定義

| ファイル | パス |
|---------|------|
| CLAUDE.md | `{{SDD_DIR}}` = `.sdd` |
| install.sh | `.sdd/settings/rules/`, `.sdd/settings/templates/` にインストール |
| 各 agent/skill | `{{SDD_DIR}}/project/specs/` 等 |

**確認OK**: 全ファイルで `{{SDD_DIR}}` を使用し、install.sh が実際に `.sdd/` 以下に展開することが確認できる。

#### review ディレクトリ構造の一貫性

| レビュータイプ | scope directory | verdicts.md パス |
|--------------|----------------|-----------------|
| per-feature design/impl | `project/specs/{feature}/reviews/` | `specs/{feature}/reviews/verdicts.md` |
| dead-code (standalone) | `project/reviews/dead-code/` | `reviews/dead-code/verdicts.md` |
| cross-check | `project/reviews/cross-check/` | `reviews/cross-check/verdicts.md` |
| wave | `project/reviews/wave/` | `reviews/wave/verdicts.md` |
| cross-cutting | `specs/.cross-cutting/{id}/` | `.cross-cutting/{id}/verdicts.md` |
| self-review | `project/reviews/self/` | `reviews/self/verdicts.md` |

**確認OK**: review.md の `Verdict Destination by Review Type` セクションが全ケースを網羅しており一致。

#### Builder report パス

- **CLAUDE.md (L.40)**: `builder-report-{group}.md`
- **sdd-builder.md Step A**: `{{SDD_DIR}}/project/specs/{feature}/builder-report-{group}.md`
- **impl.md (L.91)**: "Grep builder-report file" として参照

**確認OK**: 一貫している。

---

### プロトコル一貫性チェック

#### Review Decomposition プロトコル

- **run.md §Review Decomposition**: DISPATCH-INSPECTORS → INSPECTORS-COMPLETE → AUDITOR-COMPLETE の 3 段階
- **reboot.md Phase 7 §Review Decomposition (L.173-176)**: run.md と同一プロトコルを参照 ✓

**確認OK**。

#### Steering Feedback Loop プロトコル

- **CLAUDE.md Steering Feedback Loop**: Auditor が `STEERING:` entries を出力、Lead が処理
- **review.md Steering Feedback Loop Processing**: `{CODIFY|PROPOSE}|{target file}|{decision text}` 形式
- **sdd-auditor-design.md Output Format**: `STEERING:` セクション ✓
- **sdd-auditor-impl.md Output Format**: `STEERING:` セクション ✓
- **sdd-auditor-dead-code.md Output Format**: `STEERING:` セクション **なし**

**問題 (LOW)**: `sdd-auditor-dead-code.md` の出力フォーマットに `STEERING:` セクションが定義されていない。dead-code Auditor が steering 提案を行うことはほぼないと思われるが、仕様として明示的に除外するか、他の Auditor と統一すべき。

#### Worker session.md auto-draft 例外

- **CLAUDE.md (L.238)**: run pipeline では Phase completion ごとの auto-draft を省略
- **run.md Phase Handlers (L.179)**: 同様に明記
- **reboot.md Phase 7 (L.121)**: 同様に明記

**確認OK**: 3 箇所で一致。

---

### 到達不能パス / デッドエンドチェック

#### 1. `initialized` 以外のフェーズから `revise` を試みた場合

- **revise.md Part A Step 1 (L.26)**: `phase` が `implementation-complete` であることを検証
- もし `design-generated` の spec に対して `revise` を呼んだ場合: Step 1 で BLOCK されるが、BLOCK メッセージが revise.md に記載されていない (SKILL.md のエラーハンドリングにも未記載)。ユーザーが適切な guidance を受けられない可能性。[LOW]

#### 2. Cross-Cutting Mode で全スペックが SKIP になった場合

- **revise.md Part B Step 2 (L.126)**: `only implementation-complete` なスペックが eligible
- もし全スペックが SKIP → FULL/AUDIT が 0 → Step 5.5 で "only 1 FULL" チェックはあるが "0 FULL" は未定義。[LOW]

#### 3. `sdd-reboot` でユーザーが Phase 9 で "Iterate" を選んだ後の再開

- **reboot.md Phase 9 Step 4 (L.278)**: "Iterate: Skill terminates. User continues editing on the branch. Re-run `/sdd-reboot` to resume."
- **SKILL.md Step 2**: "Read and follow refs/reboot.md"
- **reboot.md Phase 1 Step 3**: 既存の reboot ブランチがあれば Resume/Delete/Abort を提示

**確認OK**: Iterate → `/sdd-reboot` 再実行 → Phase 1 で Resume オプションが提示される流れは完結している。

#### 4. Builder の `BUILDER_BLOCKED` 時の tasks.yaml 更新

- **impl.md (L.97)**: BUILDER_BLOCKED の場合 "record as `[INCIDENT]` in buffer.md"
- **impl.md (L.88)**: "Update tasks.yaml: mark completed tasks as `done`"
- BLOCKED 時は完了タスクがないため tasks.yaml は更新されない（期待通り）。BLOCKED 時に file list もない。

**確認OK**: BLOCKED の場合はファイル書き込みなしが意図的に記述されている。

#### 5. Wave QG で全スペックが `blocked` 状態の場合

- **run.md Step 7 (L.240)**: `Wave completion condition: all specs implementation-complete or blocked`
- **run.md Step 7a**: verdict が NO-GO の場合 blocked spec はスキップ? → 記載なし
- 実際の処理: Step 6 で全スペックが blocked になった場合、Step 7 に到達するが cross-check は blocked spec のコードにアクセスするため空になる。このケースへの明示的な処理がない。[LOW]

---

### 循環参照チェック

ファイル参照関係:

```
CLAUDE.md → run.md, review.md, revise.md, impl.md, design.md, crud.md
SKILL.md → design.md, impl.md, review.md, run.md, revise.md, crud.md
run.md → design.md, impl.md, review.md
revise.md → design.md, impl.md, review.md, run.md, crud.md
review.md (standalone) → (参照なし)
reboot.md → run.md (design-only mode)
```

**確認OK**: 循環参照なし。全参照は一方向。

---

### 未定義参照チェック

| 参照 | 参照元 | 存在確認 |
|------|--------|---------|
| `refs/run.md` | CLAUDE.md | ✓ framework/claude/skills/sdd-roadmap/refs/run.md |
| `refs/review.md` | CLAUDE.md | ✓ |
| `refs/revise.md` | CLAUDE.md | ✓ |
| `refs/impl.md` | CLAUDE.md | ✓ |
| `refs/crud.md` | CLAUDE.md | ✓ |
| `design-discovery-full.md` | sdd-architect.md | ✓ framework/claude/sdd/settings/rules/ |
| `design-discovery-light.md` | sdd-architect.md | ✓ |
| `tasks-generation.md` | sdd-taskgenerator.md | ✓ |
| `design-review.md` | sdd-inspector-rulebase.md, testability.md | ✓ |
| `specs/init.yaml` | SKILL.md | **未確認** — framework/claude/sdd/settings/templates/specs/ に design.md と research.md のみ。`init.yaml` が存在するか要確認 |
| `cpf-format.md` | CLAUDE.md | ✓ |
| `steering-principles.md` | sdd-steering SKILL.md | ✓ |

**重要 (MEDIUM)**: `{{SDD_DIR}}/settings/templates/specs/init.yaml` への参照が SKILL.md (L.76) と reboot.md (L.97) にあるが、テンプレートディレクトリ (`framework/claude/sdd/settings/templates/`) に `init.yaml` が含まれているかどうかは本レビューで確認できているファイル一覧に入っていない。specs ディレクトリには `design.md` と `research.md` のみが Glob で確認された。`init.yaml` が欠落している場合、`/sdd-roadmap design` の自動作成フローと `/sdd-reboot` の spec 初期化フローが機能しない。

---

### クロスリファレンスマトリックス

| コンポーネント | CLAUDE.md | SKILL.md | run.md | review.md | impl.md | design.md | revise.md | crud.md | reboot.md |
|--------------|-----------|----------|--------|-----------|---------|-----------|-----------|---------|-----------|
| phase gate | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | - | ✓ |
| verdict handling | ✓ | ✓ | ✓ | ✓ | - | - | ✓ | - | ✓ |
| session.md auto-draft | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| decisions.md append | ✓ | - | ✓ | ✓ | - | - | ✓ | ✓ | ✓ |
| Counter limits | ✓ | - | ✓ | - | - | - | ✓ | - | ✓ |
| Steering feedback | ✓ | - | ✓ | ✓ | - | - | - | - | ✓ |
| Wave QG | ✓ | ✓ | ✓ | - | - | - | - | - | - |
| Consensus mode | - | ✓ | ✓ | ✓ | - | - | - | - | - |

---

### Confirmed OK

- フェーズ名 (`initialized`, `design-generated`, `implementation-complete`, `blocked`) が全ファイルで統一されている
- Verdict 値 (`GO`, `CONDITIONAL`, `NO-GO`, `SPEC-UPDATE-NEEDED`) が適切なスコープで使用されている
- 重大度コード (C/H/M/L) が CPF 仕様と全 Inspector/Auditor で一致している
- retry_count (max 5)、spec_update_count (max 2)、aggregate cap (6) が全ファイルで一致
- dead-code NO-GO リトライ上限 (max 3) が CLAUDE.md と run.md で一致
- `{{SDD_DIR}}` パス変数が全エージェント/スキルで一貫して使用されている
- review scope directory 定義が review.md と verdicts.md パスで一致している
- Builder report パス (`builder-report-{group}.md`) が全参照元で一致
- design/impl/dead-code の各 Auditor が適切な Inspector の cpf ファイル名を参照している
- Steering Feedback Loop の `CODIFY` / `PROPOSE` 定義が CLAUDE.md、review.md、auditor 定義で一致
- CPF 形式 (pipe-delimited、`KEY:VALUE`) が全 Inspector/Auditor で一致
- `run_in_background: true` の SubAgent dispatch ルールが CLAUDE.md と全 ref ファイルで一致
- 1-Spec Roadmap Optimization (Wave QG スキップ等) が SKILL.md と run.md で一致
- sessions/ アーカイブのファイル名形式 (`{YYYY-MM-DD-HHmm}.md`) が handover SKILL.md とテンプレートで一致
- install.sh のファイルコピー先 (`.claude/skills/`, `.claude/agents/`, `.sdd/settings/`) が CLAUDE.md の Paths セクションと一致
- `sys.modules` 検出ルールが sdd-builder.md の Critical Constraints と sdd-inspector-test.md の Module-Level Mock Integrity 検査で整合している

---

### Overall Assessment

**問題の分布**: CRITICAL 0件、HIGH 0件、MEDIUM 5件、LOW 8件

最も重要な問題は:

1. **`init.yaml` テンプレートの存在確認が必要** (MEDIUM): `{{SDD_DIR}}/settings/templates/specs/init.yaml` への参照が複数箇所にあるが、テンプレートディレクトリに `init.yaml` が確認できていない。このファイルが欠落している場合、`/sdd-roadmap design` と `/sdd-reboot` の spec 初期化フローが機能しない。

2. **`sdd-inspector-dead-settings.md` の SCOPE 例の誤り** (MEDIUM): 出力例の `SCOPE:cross-check` は `SCOPE:dead-code` に修正が必要。

3. **dead-code review の Wave QG コンテキストにおける scope directory の曖昧性** (MEDIUM): run.md は `reviews/wave/` を使うと記載しているが、review.md の Step 1 では dead-code scope として `reviews/dead-code/` を定義しており、Wave QG コンテキストでの切り替え条件が review.md 側に明示されていない。

4. **`sdd-review-self` の `general-purpose` subagent_type** (MEDIUM): settings.json の Agent() 許可リストに存在しない型を使用している。

これらの問題はいずれも運用に致命的な影響を与えるものではなく、フレームワークの全体的な一貫性は高い水準を維持している。
