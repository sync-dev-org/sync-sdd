## Consistency & Dead Ends Report

**レビュー対象**: SDD フレームワーク全ファイル
**レビュー日時**: 2026-03-03
**レビュアー**: Agent 3 (Consistency & Dead Ends)

---

### Issues Found

---

#### [HIGH] Inspector カウント不一致: CLAUDE.md「6 impl +2 web」vs 実ファイル構成

**ファイル**: `framework/claude/CLAUDE.md` (行 27)
**内容**: `T3 | Inspector | Individual review perspectives. 6 design, 6 impl +2 web (impl only, web projects), 4 dead-code.`

`review.md` の Impl Review セクション（行 33）:
```
- Standard impl Inspectors (6, sonnet): sdd-inspector-impl-rulebase, sdd-inspector-interface, sdd-inspector-test, sdd-inspector-quality, sdd-inspector-impl-consistency, sdd-inspector-impl-holistic
- Web projects: also spawn sdd-inspector-e2e and sdd-inspector-visual
```

- [HIGH] CLAUDE.md の記述は `6 impl +2 web` と正確で、review.md とも一致する。ただし `sdd-review-self/SKILL.md` の Agent 1 の説明では「up to 8 independent review agents」とあるのに、Agent 2 の設定では実際に渡される説明は説明文のみで具体的な数字は記載なし。`sdd-auditor-impl.md` は「up to 8 independent review agents」(行 14) と記述されており、これは 6+2=8 と一致する。問題なし。

---

#### [HIGH] `sdd-inspector-dead-specs.md` のSCOPEフィールドが不整合

**ファイル**: `framework/claude/agents/sdd-inspector-dead-specs.md` (行 48、60)

Dead Specs Inspector のアウトプット例:
- `SCOPE:dead-code` (行 48の仕様)
- 例 (行 60): `SCOPE:cross-check`

**問題**: `SCOPE` フィールドが同一ファイル内で矛盾している。仕様ブロック(行 48)では `SCOPE:dead-code` と定義されているが、実例(行 60)では `SCOPE:cross-check` となっている。

同様に `sdd-inspector-dead-tests.md`:
- 仕様(行 49): `SCOPE:dead-code`
- 例(行 57): `SCOPE:cross-check`

`sdd-inspector-dead-code.md` と `sdd-inspector-dead-settings.md` では仕様と例がともに `dead-code` または `cross-check` でそれぞれ記述されているが、dead-specs と dead-tests は不一致。

**影響**: Auditor (`sdd-auditor-dead-code.md`) が Inspector 出力ファイルを読む際、SCOPE フィールドの解釈が不安定になる可能性がある。

---

#### [HIGH] `sdd-inspector-dead-specs.md` の出力フォーマット カテゴリ不一致

**ファイル**: `framework/claude/agents/sdd-inspector-dead-specs.md`

- 仕様行 (行 49): `{sev}|spec-drift|{location}|{description}`
- `sdd-auditor-dead-code.md` の期待カテゴリ (行 162): `dead-config`, `dead-code`, `spec-drift`, `orphaned-test`, `unused-import`, `stale-fixture`, `unimplemented-spec`, `false-confidence-test`

`spec-drift` は両方に存在するため問題ない。ただし dead-specs と dead-tests の `SCOPE` 不一致は上記 HIGH 問題として記録済み。

---

#### [HIGH] `Analyst` の出力先パスの不整合

**ファイル A**: `framework/claude/CLAUDE.md` (行 41)
```
write analysis report to `{{SDD_DIR}}/project/reboot/analysis-report.md`
```

**ファイル B**: `framework/claude/skills/sdd-reboot/refs/reboot.md` Phase 4 (行 48)
```
Output path: `{{SDD_DIR}}/project/reboot/analysis-report.md`
```

**ファイル C**: `framework/claude/agents/sdd-analyst.md` (行 26, 127, 173)
```
Write to the output path provided by Lead
```

これら 3 ファイルは整合している。

しかし CLAUDE.md 行 41 の Analyst 完了メッセージ:
```
ANALYST_COMPLETE + New specs: + Waves: + Steering: + Requirements identified: + Files to delete: + WRITTEN:{path}
```

`sdd-analyst.md` 行 200-207 の完了レポートフォーマット:
```
ANALYST_COMPLETE
New specs: {count}
Waves: {count}
Steering: {created|updated} ({file_list})
Requirements identified: {count}
Files to delete: {count}
WRITTEN:{report_path}
```

両ファイルの形式は一致している。問題なし。

---

#### [HIGH] `sdd-reboot/SKILL.md` の Phase 番号と `refs/reboot.md` の不整合

**ファイル**: `framework/claude/skills/sdd-reboot/SKILL.md` (行 32-42)

SKILL.md では 10 フェーズ を次のように列挙:
1. Pre-Flight
2. Branch Setup
3. Setup
4. Deep Analysis
5. User Review
6. Roadmap Regeneration
7. Design Pipeline
8. Regression Check
9. Final Report & User Decision
10. Post-Completion

`refs/reboot.md` では:
- Phase 1: Pre-Flight
- Phase 2: Branch Setup
- Phase 3: Setup
- Phase 4: Deep Analysis
- Phase 5: User Review Checkpoint
- Phase 6: Roadmap Regeneration (6a-6d)
- Phase 7: Design Pipeline
- Phase 8: Regression Check
- Phase 9: Final Report & User Decision
- Phase 10: Post-Completion

両ファイルはフェーズ名・番号が一致している。問題なし。

---

#### [MEDIUM] `sdd-review-self/SKILL.md` の `$SCOPE_DIR` 参照パス不整合

**ファイル**: `framework/claude/skills/sdd-review-self/SKILL.md` (行 41-42)

```
Read `$SCOPE_DIR/verdicts.md` (where `$SCOPE_DIR` = `{{SDD_DIR}}/project/reviews/self/`)
```

しかし同ファイル行 55 では:
```
Create `$SCOPE_DIR/active/` directory
```

`review.md` の「Verdict Destination by Review Type」(行 147-149) では:
```
- **Self-review** (framework-internal): `{{SDD_DIR}}/project/reviews/self/verdicts.md`
```

これらは一致している。問題なし。

ただし `sdd-review-self/SKILL.md` のステップ 4 (行 56-57) では:
```
Each agent: Agent(subagent_type="general-purpose", model="sonnet", run_in_background=true)
```

`sdd-review-self` は `framework/claude/settings.json` に `Skill(sdd-review-self)` として登録されているが、`Agent(sdd-review-self)` としては登録されていない（適切）。一方、self-review 内でディスパッチするのは `general-purpose` サブエージェントであり、これは settings.json のエージェント一覧に存在しない。

**問題**: `sdd-review-self` が内部でディスパッチする `general-purpose` エージェントは `settings.json` の `Agent()` 許可リストに含まれていない。ただし self-review が Lead 自身から実行されるため、Lead の permissions が適用される可能性があるが、明示的な許可がない。

---

#### [MEDIUM] `run.md` の Wave QG dead-code Review の `SCOPE` フィールド指定と `review.md` の整合

**ファイル A**: `framework/claude/skills/sdd-roadmap/refs/run.md` (行 252-258)

```
2. Persist verdict to `{{SDD_DIR}}/project/reviews/wave/verdicts.md` (header: `[W{wave}-DC-B{seq}]`)
```

**ファイル B**: `framework/claude/skills/sdd-roadmap/refs/review.md` (行 144)

```
- **Dead-code review** (standalone): `{{SDD_DIR}}/project/reviews/dead-code/verdicts.md` (Wave QG context uses `reviews/wave/verdicts.md` with header `[W{wave}-DC-B{seq}]`; see run.md Step 7b)
```

両ファイルは整合している。

しかし `review.md` の Step 1「Parse Arguments」(行 86-89)で scope directory を決定する際:
```
- **Project-level** (dead-code): `{{SDD_DIR}}/project/reviews/dead-code/`
- **Project-level** (wave): `{{SDD_DIR}}/project/reviews/wave/`
```

Wave QG dead-code は `run.md` が直接 `reviews/wave/verdicts.md` に書き込むよう指定しているが、`review.md` の Step 1 フローでは `dead-code` サブコマンドは常に `reviews/dead-code/` を使用する。つまり Wave QG dead-code 実行時は `review.md` の Step 1 ではなく `run.md` の Step 7b が上書きするが、これは明示的に `review.md` に記載されている（行 144 の括弧書き）。整合している。

---

#### [MEDIUM] `sdd-steering/SKILL.md` でカスタムステアリングファイル数の不整合

**ファイル**: `framework/claude/skills/sdd-steering/SKILL.md` (行 83-85)

```
- `api-standards.md`, `authentication.md`, `database.md`, `deployment.md`, `error-handling.md`, `security.md`, `testing.md`, `ui.md`
```

実際のファイル:
```
framework/claude/sdd/settings/templates/steering-custom/api-standards.md
framework/claude/sdd/settings/templates/steering-custom/authentication.md
framework/claude/sdd/settings/templates/steering-custom/database.md
framework/claude/sdd/settings/templates/steering-custom/deployment.md
framework/claude/sdd/settings/templates/steering-custom/error-handling.md
framework/claude/sdd/settings/templates/steering-custom/security.md
framework/claude/sdd/settings/templates/steering-custom/testing.md
framework/claude/sdd/settings/templates/steering-custom/ui.md
```

8 ファイルが SKILL.md に列挙されており、実ファイルも 8 個。一致している。問題なし。

---

#### [MEDIUM] `revise.md` Part A Step 4 のフェーズ遷移の潜在的な問題

**ファイル**: `framework/claude/skills/sdd-roadmap/refs/revise.md` (行 61-67)

Part A Step 4: State Transition:
```
3. Set `phase = design-generated`
```

しかし CLAUDE.md (行 159) の Phase-Driven Workflow では:
```
Phases: `initialized` → `design-generated` → `implementation-complete` (also: `blocked`)
Revision: `implementation-complete` → `design-generated` → (full pipeline) → `implementation-complete`
```

`revise.md` Part A Step 1 (行 24) の Validate で:
```
2. Verify `spec.yaml` exists and `phase` is `implementation-complete`
```

これは `implementation-complete` → `design-generated` の遷移であり、CLAUDE.md に沿っている。問題なし。

---

#### [MEDIUM] `run.md` と `revise.md` でのカウンターリセットの相違

**ファイル A**: `framework/claude/skills/sdd-roadmap/refs/run.md` (行 261)
```
**Reset counters**: For each spec in wave: `retry_count=0`, `spec_update_count=0`
```
(Wave QG post-gate での Wave 単位リセット)

**ファイル B**: `framework/claude/skills/sdd-roadmap/refs/revise.md` Part A Step 4 (行 62-63)
```
2. Reset `orchestration.retry_count = 0`, `orchestration.spec_update_count = 0`
```

**CLAUDE.md** (行 180):
```
Counter reset triggers: wave completion, user escalation decision (including blocking protocol fix/skip), `/sdd-roadmap revise` start, session resume (dead-code counters are in-memory only)
```

これら 3 ファイルは整合している。問題なし。

---

#### [MEDIUM] `sdd-inspector-dead-specs.md` 出力の `SCOPE:dead-code` vs 実用途の不整合（再確認）

**ファイル**: `framework/claude/agents/sdd-inspector-dead-specs.md` (行 48)

フォーマット定義:
```
SCOPE:dead-code
```

しかし実例(行 60):
```
SCOPE:cross-check
```

**`sdd-inspector-dead-tests.md`** も同様（行 49 と 57-58 で `dead-code` vs `cross-check`）。

`sdd-auditor-dead-code.md` は `SCOPE` フィールドを明示的に検証していないため runtime error にはならないが、ドキュメント上の不一致として指摘する。

---

#### [MEDIUM] `design.md` テンプレートと `design-review.md` ルールの「System Flows」セクション扱い不一致

**ファイル A**: `framework/claude/sdd/settings/templates/specs/design.md`

テンプレートには `## System Flows` セクションが含まれる（行 94-102）。

**ファイル B**: `framework/claude/sdd/settings/rules/design-review.md` (行 29)

```
**design.md Design Sections Check** (compare against template):
- Has Overview (Purpose, Users, Impact)
- Has Architecture section
- Has System Flows section (if applicable)
- Has Specifications Traceability section (if applicable)
- Has Components and Interfaces section
- Has Data Models section (if applicable)
- Has Error Handling section
- Has Testing Strategy section
```

`design-review.md` は `System Flows section (if applicable)` と記載しており任意扱い。

**ファイル C**: `framework/claude/agents/sdd-inspector-rulebase.md` (行 53-62)

```
**Design Sections** (below Specifications):
- Has Overview (Purpose, Users, Impact)
- Has Architecture section
- Has Components and Interfaces section
- Has Data Models section (if applicable)
- Has Error Handling section
- Has Testing Strategy section
```

`sdd-inspector-rulebase.md` の Design Sections チェックリストに `System Flows` が含まれていない。`design-review.md` には含まれているが `sdd-inspector-rulebase.md` には欠落している。これは Inspector が `design-review.md` を参照していないためにルールの適用漏れが生じる可能性がある。

---

#### [MEDIUM] `sdd-analyst.md` が `reboot/refs/reboot.md` の Phase 5 再ディスパッチを完全には説明していない

**ファイル A**: `framework/claude/skills/sdd-reboot/refs/reboot.md` Phase 5 (行 67-68)

```
If user selects a non-recommended alternative: re-dispatch Analyst with `selected_alternative={name}` to regenerate steering and spec decomposition for that alternative. Max 1 re-dispatch.
```

**ファイル B**: `framework/claude/agents/sdd-analyst.md` (行 27)

```
**Selected alternative** (re-dispatch only): if the user selected a non-recommended architecture alternative, this field contains the alternative name. When present: skip Step 2-3, use the named alternative from the previous report as the basis, and regenerate Step 4 (Steering) and Step 5 (Spec Decomposition) for that alternative.
```

整合している。問題なし。

---

#### [LOW] `settings.json` の `Skill(sdd-publish-setup)` が欠落

**ファイル**: `framework/claude/settings.json`

`settings.json` の permissions.allow リストには以下の Skill が含まれる:
- `Skill(sdd-roadmap)`
- `Skill(sdd-steering)`
- `Skill(sdd-status)`
- `Skill(sdd-handover)`
- `Skill(sdd-reboot)`
- `Skill(sdd-release)`
- `Skill(sdd-review-self)`

しかし `framework/claude/skills/sdd-publish-setup/SKILL.md` が存在する。`settings.json` に `Skill(sdd-publish-setup)` が含まれていない。これは `sdd-publish-setup` が `sdd-steering` から自動的に呼び出される (SKILL.md 内の `Skill tool` 経由) ため、Lead が直接呼び出さない前提かもしれないが、ユーザーが直接 `/sdd-publish-setup` を実行しようとした場合に permissions エラーが発生する可能性がある。

---

#### [LOW] `CLAUDE.md` の Session Resume Step 2a の `verdicts.md` パスが不明確

**ファイル**: `framework/claude/CLAUDE.md` (行 277)

```
2a. Read `{{SDD_DIR}}/project/specs/*/reviews/verdicts.md` → active review state per spec
    Also check `{{SDD_DIR}}/project/reviews/*/verdicts.md` for project-level review state (dead-code, cross-check, wave).
```

`review.md` の「Verdict Destination by Review Type」(行 140-149):
```
- **Dead-code review** (standalone): `{{SDD_DIR}}/project/reviews/dead-code/verdicts.md`
- **Cross-check review**: `{{SDD_DIR}}/project/reviews/cross-check/verdicts.md`
- **Wave-scoped review**: `{{SDD_DIR}}/project/reviews/wave/verdicts.md`
- **Self-review**: `{{SDD_DIR}}/project/reviews/self/verdicts.md`
```

CLAUDE.md の `{{SDD_DIR}}/project/reviews/*/verdicts.md` というワイルドカードパターンは `dead-code`, `cross-check`, `wave`, `self` 全てを捕捉できる。問題なし。ただし Self-review のパスもヒットするため、Session Resume 時に不要なファイルも読む可能性がある（機能的には問題ない）。

---

#### [LOW] `buffer.md` テンプレートの `{role}` フィールドが Builder レポートと不整合

**ファイル A**: `framework/claude/sdd/settings/templates/handover/buffer.md` (行 5-7)
```
- [PATTERN] {description} (source: {spec} {role}, task {N})
```

**ファイル B**: `framework/claude/skills/sdd-roadmap/refs/impl.md` (行 91)
```
append to `{{SDD_DIR}}/handover/buffer.md` with source `(source: {feature} Builder, group {G})`
```

テンプレートは `{spec} {role}` としているが、impl.md は `{feature} Builder, group {G}` という形式を指定している。`{role}` = `Builder` と `{G}` = group 識別子が追加されている。テンプレートは概念的なもので actual フォーマットは impl.md が上書きするが、テンプレートとの乖離がある。

---

#### [LOW] `sdd-taskgenerator.md` が `research.md` の読み込みを「if exists」としているが SKILL.md には条件なし

**ファイル A**: `framework/claude/agents/sdd-taskgenerator.md` (行 22)
```
Research path: `{{SDD_DIR}}/project/specs/{feature}/research.md` (if exists)
```

**ファイル B**: `framework/claude/skills/sdd-roadmap/refs/impl.md` (行 29-30)
```
Research: `{{SDD_DIR}}/project/specs/{feature}/research.md` (if exists)
```

両ファイルとも `(if exists)` と記述しており整合している。問題なし。

---

#### [LOW] `sdd-review-self/SKILL.md` の `sdd-publish-setup` がコマンド数 (7) に含まれるかの確認

**ファイル**: `framework/claude/CLAUDE.md` (行 146)
```
### Commands (7)
```

実際のスキルファイル:
1. `sdd-steering`
2. `sdd-roadmap`
3. `sdd-reboot`
4. `sdd-status`
5. `sdd-handover`
6. `sdd-release`
7. `sdd-publish-setup`
8. `sdd-review-self`

`framework/claude/skills/` 配下のスキルは 8 個だが、`sdd-review-self` はフレームワーク内部専用（ユーザー向けコマンドではない）。CLAUDE.md のコマンド表は 7 コマンド列挙しており、`sdd-review-self` は含まれていない。これは意図的な設計と思われるが、`sdd-review-self` が `settings.json` の allow リストに含まれているため、実際には 8 スキルが存在する。CLAUDE.md の `### Commands (7)` とスキルファイル数の乖離は `/sdd-release` のカウント検証 (`sdd-release/SKILL.md` 行 133-134) で自動的にフラグが立つはずだが、`sdd-review-self` が除外されているかどうかの明示がない。

---

### Confirmed OK

- **フェーズ名の統一**: `initialized` → `design-generated` → `implementation-complete` (`blocked` も含む) が CLAUDE.md, SKILL.md, refs/*.md, spec テンプレート全体で一致している
- **SubAgent 名の統一**: settings.json の Agent() 許可リストと framework/claude/agents/ ディレクトリのファイル名が完全に一致している (sdd-analyst, sdd-architect, sdd-auditor-dead-code, sdd-auditor-design, sdd-auditor-impl, sdd-builder, sdd-conventions-scanner, 全 Inspector 名)
- **Verdict 値の統一**: `GO`, `CONDITIONAL`, `NO-GO` (デザインレビュー・Implレビュー・Dead-code)、`SPEC-UPDATE-NEEDED` (Implレビューのみ) が全 Auditor ファイルで一致
- **CPF フォーマットの統一**: `VERDICT:`, `SCOPE:`, `ISSUES:`, `NOTES:` セクション構造が Inspector/Auditor 全ファイルで一致。severity コード `C/H/M/L` が一貫
- **リトライ上限の統一**: `retry_count` max 5, `spec_update_count` max 2, aggregate cap 6 が CLAUDE.md, run.md, revise.md で一致。Dead-code max 3 retries も CLAUDE.md と run.md で一致
- **パス変数の統一**: `{{SDD_DIR}}` が全ファイルで一貫して使用されている。`.sdd` への展開も CLAUDE.md で明示
- **run_in_background: true の徹底**: CLAUDE.md (行 84), design.md Step 3, impl.md Step 3, run.md Step 2.5 等、全 SubAgent ディスパッチで `run_in_background: true` が要求されている
- **Architect 完了レポートフォーマット**: `ARCHITECT_COMPLETE` + フィールド群が sdd-architect.md と design.md で整合
- **Builder 完了レポートフォーマット**: `BUILDER_COMPLETE` / `BUILDER_BLOCKED` + フィールド群が sdd-builder.md と impl.md で整合
- **TaskGenerator 完了レポートフォーマット**: `TASKGEN_COMPLETE` + フィールド群が sdd-taskgenerator.md と impl.md で整合
- **Analyst 完了レポートフォーマット**: `ANALYST_COMPLETE` + フィールド群が sdd-analyst.md と CLAUDE.md, reboot.md で整合
- **ConventionsScanner**: `WRITTEN:{path}` のみ返す設計が sdd-conventions-scanner.md と run.md, impl.md で整合
- **Inspector の file-based output**: 全 Inspector が `WRITTEN:{output_file_path}` を返す設計で一致
- **Auditor の file-based output**: 全 Auditor が `WRITTEN:{verdict_file_path}` を返す設計で一致
- **design.md テンプレートと design-principles.md の整合**: Spec IDs の `N.M` 形式、Specifications セクション構造、Components/Interfaces 記述方式が両ファイルで一致
- **tasks.yaml フォーマット**: tasks-generation.md の YAML 仕様が sdd-taskgenerator.md の生成物と整合
- **Wave Bypass / Island spec**: CLAUDE.md と run.md Step 3 で一致
- **Design Lookahead**: CLAUDE.md と run.md Step 4 (Dispatch Loop) で一致
- **Steering Feedback Loop**: CLAUDE.md, review.md, sdd-auditor-design.md, sdd-auditor-impl.md で `CODIFY`/`PROPOSE` の扱いが一致
- **decisions.md フォーマット**: CLAUDE.md と sdd-handover/SKILL.md で一致
- **session.md Auto-draft / Manual Polish の区別**: CLAUDE.md と sdd-handover/SKILL.md で一致
- **Blocking Protocol**: run.md Step 6 と CLAUDE.md §Auto-Fix Counter Limits が整合
- **Phase Gate 実装**: design.md refs, impl.md refs, run.md readiness rules が CLAUDE.md の phase 定義と整合
- **ConventionsScanner の reboot 除外**: sdd-reboot/SKILL.md, refs/reboot.md Phase 3 の両方に「ConventionsScanner は NOT dispatched」と明記
- **Spec Traceability (AC markers)**: `AC: {feature}.S{N}.AC{M}` マーカー形式が sdd-builder.md, sdd-inspector-test.md, sdd-inspector-impl-rulebase.md で一致
- **sys.modules 禁止**: sdd-builder.md と sdd-inspector-test.md の両方で明示的に禁止
- **settings.json の Agent() リスト**: framework/claude/agents/ の全 .md ファイル名と対応する Agent() エントリが完全一致 (24 エージェント)
- **install.sh のバージョン**: `v1.11.0` が install.sh ヘッダーに記載され、framework/claude/CLAUDE.md の `{{SDD_VERSION}}` (実稼働版では v1.11.0) と対応

---

### クロスリファレンス・マトリクス

| ファイル参照元 | 参照先 | 状態 |
|---|---|---|
| CLAUDE.md | refs/run.md (dispatch, Step 3-4) | OK |
| CLAUDE.md | refs/review.md (Steering Feedback Loop) | OK |
| CLAUDE.md | settings/rules/cpf-format.md | OK |
| SKILL.md (sdd-roadmap) | refs/design.md | OK |
| SKILL.md (sdd-roadmap) | refs/impl.md | OK |
| SKILL.md (sdd-roadmap) | refs/review.md | OK |
| SKILL.md (sdd-roadmap) | refs/run.md | OK |
| SKILL.md (sdd-roadmap) | refs/revise.md | OK |
| SKILL.md (sdd-roadmap) | refs/crud.md | OK |
| SKILL.md (sdd-reboot) | refs/reboot.md | OK |
| refs/run.md | refs/impl.md (Step 3.5) | OK |
| refs/run.md | refs/review.md (Step 7a/7b) | OK |
| refs/run.md | refs/design.md (Phase Handlers) | OK |
| refs/revise.md Part B | refs/run.md Step 2 | OK |
| refs/revise.md Part B | refs/impl.md (E2E Gate) | OK |
| refs/revise.md Part B | refs/review.md | OK |
| sdd-architect.md | settings/rules/design-discovery-full.md | OK |
| sdd-architect.md | settings/rules/design-discovery-light.md | OK |
| sdd-architect.md | settings/templates/specs/design.md | OK |
| sdd-architect.md | settings/templates/specs/research.md | OK (テンプレートは存在する) |
| sdd-taskgenerator.md | settings/rules/tasks-generation.md | OK |
| sdd-inspector-rulebase.md | settings/templates/specs/design.md | OK |
| sdd-inspector-rulebase.md | settings/rules/design-review.md | OK |
| sdd-inspector-testability.md | settings/rules/design-review.md | OK (optional reference) |
| sdd-auditor-design.md → Inspector CPF files | reviews/active/{inspector-name}.cpf | OK |
| sdd-auditor-impl.md → Inspector CPF files | reviews/active/{inspector-name}.cpf | OK |
| sdd-analyst.md | settings/templates/reboot/analysis-report.md | OK |
| sdd-analyst.md | settings/templates/steering/ | OK |
| sdd-conventions-scanner.md | settings/templates/wave-context/conventions-brief.md | OK |
| settings.json Agent() | framework/claude/agents/sdd-*.md | OK (全24エージェント一致) |
| settings.json Skill() | framework/claude/skills/sdd-*/SKILL.md | **`sdd-publish-setup` 欠落** |
| sdd-inspector-dead-specs.md | SCOPE field定義 vs 実例 | **不一致 (dead-code vs cross-check)** |
| sdd-inspector-dead-tests.md | SCOPE field定義 vs 実例 | **不一致 (dead-code vs cross-check)** |
| sdd-inspector-rulebase.md | design-review.md (System Flows section) | **rulebase に System Flows チェック欠落** |

---

### Overall Assessment

**重要度の高い問題 (HIGH) が 3 件**検出された:

1. **`sdd-inspector-dead-specs.md` / `sdd-inspector-dead-tests.md` の SCOPE フィールド不整合**: 出力フォーマット定義と実例で `dead-code` / `cross-check` が逆になっており、ドキュメント上の混乱を招く。Auditor はSCOPEフィールドを厳密に検証しないため実害は小さいが、Inspector 実装の参考にする際に誤りが生じる。

2. **`settings.json` の `Skill(sdd-publish-setup)` 欠落**: ユーザーが直接 `/sdd-publish-setup` を実行した際に permissions 警告が出る可能性がある。(LOW に格下げ検討可)

3. **`sdd-inspector-rulebase.md` のチェックリストから `System Flows` セクション欠落**: `design-review.md` に定義されているルールが Inspector に反映されていない。

**MEDIUM 問題 2 件**:
- `sdd-review-self` が内部でディスパッチする `general-purpose` エージェントが `settings.json` の許可リストに存在しない
- `sdd-inspector-rulebase.md` と `design-review.md` の System Flows セクションの扱い差異

全体的には、フレームワークのコア概念（フェーズ名、Verdict 値、SubAgent 名、CPF フォーマット、リトライ上限）は **高い一貫性** を保っている。発見された問題はいずれもドキュメント品質・マイナーな欠落であり、フレームワークの実行を妨げるクリティカルな矛盾は検出されなかった。
