# Consistency Review Report

**Date**: 2026-02-27
**Reviewer**: Agent 3 — Consistency & Dead Ends
**Scope**: framework/claude/ 全ファイル (CLAUDE.md, skills, refs, agents, settings.json, rules, templates)

---

## Issues Found

### [HIGH] Inspectorカウントの不整合: CLAUDE.md vs review.md

- **CLAUDE.md** (L26): Inspectorの説明に `6 design, 6 impl +2 web (impl only, web projects), 4 dead-code` と記載
- **review.md** (Design Review節): `sdd-inspector-rulebase`, `sdd-inspector-testability`, `sdd-inspector-architecture`, `sdd-inspector-consistency`, `sdd-inspector-best-practices`, `sdd-inspector-holistic` — 正しく6名
- **sdd-auditor-design.md** (L13): "6 independent review agents" と記述 — 一致
- **sdd-auditor-impl.md** (L13): "up to 8 independent review agents" と記述
- **review.md** (Impl Review節): 標準6名 + web 2名 = 最大8名 — 一致
- **settings.json**: ConventionsScannerの `Task(sdd-conventions-scanner)` エントリが**存在しない**
  - CLAUDE.md L100, run.md L32では `sdd-conventions-scanner` をTask経由でdispatchすると明記
  - settings.jsonのTask()エントリリストに `sdd-conventions-scanner` が含まれていない
  - **影響**: Leadが `Task(sdd-conventions-scanner, ...)` を呼ぼうとしても、settings.jsonのpermissionsで許可されていない可能性
  - **ファイル**: `framework/claude/settings.json`

### [HIGH] CLAUDE.md と SKILL.md のOutput最小化ポリシーの記述差異

- **CLAUDE.md** (L37-40): 全SubAgentについてTask result最小化を求め、具体的ポリシーを記述 (`Review SubAgents: WRITTEN:{path}のみ`, `Builder: 構造化サマリー`, `Architect/TaskGenerator: 現状は詳細不要`)
- **install先の .claude/CLAUDE.md** (L37-38): "Review SubAgents (Inspector/Auditor): return ONLY `WRITTEN:{path}`." と記述 — しかしBuilderもfile-based outputを要求しており、`sdd-builder.md` の完了レポート形式と矛盾の可能性
- **sdd-builder.md** (L114): "Write your full report to a file, then output a minimal summary as your final text." → WRITTEN:{path} をサマリー末尾に含め、詳細レポートはファイルに書く — これはCLAUDE.mdのポリシーと整合
- **問題点**: CLAUDE.md L40で "Architect / TaskGenerator: current report format is already concise — no file-based output required unless reports grow" と言いつつ、Architect完了レポートは直接テキスト出力する形式 (ARCHITECT_COMPLETE ... Key findings: ...) —これは矛盾なし。ただし明確なサイズ基準が不明確
- **ファイル**: `framework/claude/CLAUDE.md:37-40`

### [HIGH] sdd-inspector-testabilityのWave-Scoped Cross-Checkモードで `design-review.md` を読み込まない

- **sdd-inspector-testability.md** (L43): Single Spec Modeでは `design-review.md` を "optional" として読む
- **Wave-Scoped Cross-Check Mode** (L107-129): `design-review.md` の読み込みが明記されていない
- **Cross-Check Mode** (L133): `design-review.md` の読み込みが明記されていない
- 同じInspectorがモードによって参照するルールファイルが異なる可能性があり、レビュー品質に差が生じる
- **ファイル**: `framework/claude/agents/sdd-inspector-testability.md:107-133`

### [MEDIUM] `reviews/active/` アーカイブパスの不整合

- **CLAUDE.md** (L35): "After verdict is persisted, the directory is renamed to `reviews/B{seq}/` for archival."
- **review.md** (L90): "Archive: rename `{scope-dir}/active/` → `{scope-dir}/B{seq}/`" — 一致
- **run.md** (L120-121): "Archive: rename `reviews/active-{p}/` → `reviews/B{seq}/pipeline-{p}/`" (consensus mode)
- **run.md** (L126): "N=1 (default): use `specs/{feature}/reviews/active/` (no `-{p}` suffix). Archive to `reviews/B{seq}/`." — 一致
- **sdd-roadmap/SKILL.md** (Consensus Mode L123): "`reviews/active-{p}/` → `reviews/B{seq}/pipeline-{p}/`" — review.mdのL123と一致
- **軽微な問題**: SKILL.md L116では `specs/{feature}/reviews/active-{p}/` と書かれているが、review.mdではそのパスが `{scope-dir}/active-{p}/` として定義され、dead-codeやcross-checkでは feature パスとは異なる scope-dir を使う。これは整合しているが、Consensus Modeのパス記述においてfeatureとscope-dirが混在している
- **ファイル**: `framework/claude/skills/sdd-roadmap/SKILL.md:116-117`

### [MEDIUM] `design-review.md` (ルールファイル) と Inspector ファイル群の重複記述

- `design-review.md` は詳細なレビューチェックリストを持つ
- `sdd-inspector-rulebase.md` はほぼ同じ内容を独自に詳述 (Template Conformanceチェック、Specifications Qualityチェック等)
- `sdd-inspector-testability.md` は `design-review.md` をオプションで読むが、自前でも同様のチェックリストを内包
- **問題**: ルールファイルとInspector定義の責務境界が曖昧。Inspectorが `design-review.md` を読まずに独立した基準で動作すると、ルールファイルの変更が反映されないリスクがある
- **ファイル**: `framework/claude/sdd/settings/rules/design-review.md`, `framework/claude/agents/sdd-inspector-rulebase.md`

### [MEDIUM] `sdd-inspector-dead-code.md` と `sdd-inspector-dead-settings.md` のSCOPEフォーマットの差異

- **sdd-inspector-dead-code.md** (L55): `SCOPE:{feature} | cross-check` — wave-scoped modeなし
- **sdd-inspector-dead-settings.md** (L46): `SCOPE:{feature} | cross-check` — wave-scoped modeなし
- **sdd-inspector-dead-specs.md** (L48): `SCOPE:{feature} | cross-check` — wave-scoped modeなし
- **sdd-inspector-dead-tests.md** (L51): `SCOPE:{feature} | cross-check` — wave-scoped modeなし
- Dead-code Inspectorは全員 wave-scoped モードをサポートしない (design/implのInspectorはサポートする)
- **review.md** の Dead-Code Review節にはwave-scopedモードについての言及なし
- **run.md** Step 7b: dead-code reviewは `refs/review.md (Dead-Code Review section)` を参照するが、wave-scoped contextは不明
- **一貫性**: dead-code InspectorのSCOPEフォームに `wave-1..{N}` がないことは設計上正しい可能性があるが、明示的な文書化が不足
- **ファイル**: `framework/claude/skills/sdd-roadmap/refs/run.md:243-248`

### [MEDIUM] `sdd-auditor-dead-code.md` のOutput FormatにSCOPEフィールドがない

- **sdd-auditor-design.md** (L186-200): `VERDICT:`, `SCOPE:`, `WAVE_SCOPE:` フィールドを含む詳細なCPF形式
- **sdd-auditor-impl.md** (L240-266): 同様に `VERDICT:`, `SCOPE:`, `WAVE_SCOPE:` フィールドを含む
- **sdd-auditor-dead-code.md** (L145-155): `SCOPE:` フィールドが**存在しない**
  ```
  VERDICT:{GO|CONDITIONAL|NO-GO}
  VERIFIED: ...
  ```
  SCOPEフィールドがなく、`cross-check` や feature 名を示す手段がない
- **影響**: Lead が audit結果を処理する際に、どのスコープのverdictかを判断できない
- **ファイル**: `framework/claude/agents/sdd-auditor-dead-code.md:145-155`

### [MEDIUM] revise.md Part B Step 7のPhase Handlerに対するDesign Review条件の記述が欠如

- **run.md** (Readiness Rules): Design Review の条件 = "No GO/CONDITIONAL verdict in verdicts.md latest design batch"
- **revise.md Part B Step 7**: Design Review について `refs/review.md` を参照するが、NO-GO時のArchitect再dispatchやverdictループの詳細がrun.mdのPhase Handlerほど明示されていない
- "Handle verdicts per CLAUDE.md counter limits." とだけ書かれており、revise.md固有のNO-GO処理フローが不完全
- **ファイル**: `framework/claude/skills/sdd-roadmap/refs/revise.md:228-230`

### [MEDIUM] `sdd-inspector-interface.md` のWave-Scoped Cross-Check Modeで `tasks.yaml` を読む記述が他のimplインスペクターと不一致

- **sdd-inspector-interface.md** Wave-Scoped Mode (L141-164): Step 4で `design.md + tasks.yaml` を読む
- **sdd-inspector-quality.md** Wave-Scoped Mode: `design.md + tasks.yaml` を読む
- **sdd-inspector-impl-consistency.md** Wave-Scoped Mode: `design.md + tasks.yaml` を読む
- しかし `sdd-inspector-interface.md` の主要ミッション (署名検証) にはtasks.yamlは不要であり、他のimpl inspectorと揃えた形式的なコピーである可能性が高い
- **軽微**: 機能上の問題ではないが、不要なファイル読み込みのコスト
- **ファイル**: `framework/claude/agents/sdd-inspector-interface.md:154-155`

### [LOW] `sdd-inspector-testability.md` がWave-Scoped Cross-Check Modeを説明するが実装手順が不完全

- Single Spec Mode (L99-105): 詳細な調査手順あり
- Wave-Scoped Cross-Check Mode (L107-129): スコープ解決の手順はあるが "Execute Wave-Scoped Cross-Check: Same analysis as Cross-Check Mode, limited to wave scope" と書くのみで、実際のtestability調査手順が省かれている
- Cross-Check Mode (L132): "Look for systemic testability issues across specs" — 内容あり
- **ファイル**: `framework/claude/agents/sdd-inspector-testability.md:124-129`

### [LOW] `revise.md` Part A Step 4でフェーズ遷移が `design-generated` に設定されるが `initialized` への遷移ルートが不明

- Phase-Driven Workflow (CLAUDE.md L155): `initialized` → `design-generated` → `implementation-complete`
- revise.md Part A Step 4 (L61-66): `phase = design-generated` に設定 — 正しい
- design.md (Step 2 Phase Gate): `implementation-complete` → 再設計警告後に `design-generated` に戻る — 一致
- しかし `initialized` に戻るパスが仕様上存在しない (削除・再作成以外では)
- これは設計上の意図的な制約だが、明示的な記述がない
- **ファイル**: `framework/claude/skills/sdd-roadmap/refs/design.md:16-19`

### [LOW] `sdd-review-self/SKILL.md` のAgent 3の出力パス指定と実際の呼び出し方の差異

- **sdd-review-self/SKILL.md** (L55-58): "Each agent: `Task(subagent_type="general-purpose", model="sonnet", run_in_background=true)`"
- **Step 4 Agent 3** (L139-158): `{$REVIEW_SCOPE}` としてreview scopeをプロンプトに含めるが、実際のファイルパスは変数展開されたもの
- Agent 3の出力先パスとして `$SCOPE_DIR/active/agent-3-consistency.md` が指定される (L59) が、`$SCOPE_DIR` = `{{SDD_DIR}}/project/reviews/self/` の変数展開がskillファイル内で明示されているかどうかは Step 3 (L42) に依存
- **ファイル**: `framework/claude/skills/sdd-review-self/SKILL.md:41-43`

### [LOW] `crud.md` Delete ModeでProject-level reviews削除は明示されるがSpec-level reviewsは言及なし

- **crud.md** (L80-82): "Delete roadmap.md, all spec directories, and project-level reviews directory (`{{SDD_DIR}}/project/reviews/`)"
- Spec-level reviews (`specs/{feature}/reviews/`) はspec directories削除時に暗黙的に消える
- 明示的な記述があれば誤解を防げる
- **ファイル**: `framework/claude/skills/sdd-roadmap/refs/crud.md:80-82`

---

## クロスリファレンスマトリクス

| 参照元 | 参照先 | 内容 | 状態 |
|--------|--------|------|------|
| CLAUDE.md L86 | sdd-roadmap refs/run.md | "Operational details" | OK (refs/run.md存在) |
| CLAUDE.md L92 | sdd-roadmap refs/crud.md | "Wave Scheduling" | OK |
| CLAUDE.md L99 | sdd-roadmap refs/revise.md | "Cross-Cutting Parallelism" | OK |
| CLAUDE.md L100 | sdd-roadmap refs/run.md Step 2.5 | "Wave Context" | OK |
| CLAUDE.md L100 | sdd-roadmap refs/impl.md | "Pilot Stagger Protocol" | OK |
| CLAUDE.md L173 | sdd-roadmap refs/run.md | "Auto-fix loop details" | OK |
| CLAUDE.md L207 | sdd-roadmap refs/review.md | "Steering Feedback Loop" | OK |
| SKILL.md:CLAUDE.md | refs/design.md, impl.md, review.md, run.md, revise.md, crud.md | Execution Reference | OK (全refs存在) |
| run.md L32 | sdd-conventions-scanner | Task dispatch | **settings.jsonに未登録** |
| run.md L84 | review.md | "Design Review" cross-ref | OK |
| run.md L151 | verdicts.md (latest batch) | Readiness Rules | OK (手順はreview.mdで定義) |
| run.md L187 | impl.md | "Implementation completion" | OK |
| run.md L233 | review.md | "Impl Cross-Check Review" | OK |
| review.md L70-73 | scope-dir paths | パスパターン定義 | OK |
| revise.md Part B L213 | run.md Step 2.5 | ConventionsScanner dispatch | OK |
| impl.md L30 | design.md, research.md | "TaskGenerator dispatch" | OK |
| impl.md L62 | sdd-conventions-scanner | Supplement mode dispatch | settings.jsonに未登録 (同上) |
| sdd-architect.md | design-principles.md, design-discovery-*.md | Load Context | OK |
| sdd-taskgenerator.md | tasks-generation.md | Load Context | OK |
| sdd-auditor-design.md | Inspector 6ファイル (.cpf) | Input Handling | OK |
| sdd-auditor-impl.md | Inspector 8ファイル (.cpf) | Input Handling | OK (web: optional) |
| sdd-auditor-dead-code.md | Inspector 4ファイル (.cpf) | Input Handling | OK |
| sdd-inspector-rulebase.md | design-review.md | Load Templates | OK |
| sdd-inspector-testability.md | design-review.md | Optional load | OK |
| CLAUDE.md L336 | cpf-format.md | CPF spec reference | OK |

---

## Confirmed OK

- フェーズ名 (`initialized`, `design-generated`, `implementation-complete`, `blocked`) は全ファイルで統一されている
- バーディクト値 (`GO`, `CONDITIONAL`, `NO-GO`, `SPEC-UPDATE-NEEDED`) はdesign/impl Auditorで正確に定義されており、CLAUDE.md記述と一致している
- Dead-code AuditorはSPEC-UPDATE-NEEDEDを出力しない (設計通り)
- CPF重大度コード (`C`, `H`, `M`, `L`) は全Inspector/Auditorファイルで統一されている
- リトライ上限 (retry_count: max 5, spec_update_count: max 2, aggregate cap: 6) はCLAUDE.md、run.md、revise.mdで一致している
- Dead-Code ReviewのNO-GO時リトライ上限 (max 3) はCLAUDE.mdとrun.mdで一致している
- SubAgentの `background: true` フロントマターはarchitect, builder, taskgenerator, conventions-scanner, 全Inspector・Auditorで設定されている
- Inspectorの出力プロトコル (`WRITTEN:{path}` のみを返す) は全Inspector・Auditor定義で一致している
- `{{SDD_DIR}}` = `.sdd` はCLAUDE.mdで定義され、全エージェント/スキルで一貫して使用されている
- TaskGenerator の `tasks.yaml` 書き込みパスとBuilderのspec.yaml非更新ルールは全関係ファイルで一致している
- Pilot Stagger Protocol (impl.md) とConventionsScanner Supplementモード (sdd-conventions-scanner.md) の入出力インターフェースが一致している
- Wave Context生成の出力パス (`.sdd/project/specs/.wave-context/{wave-N}/conventions-brief.md` または `{feature}/conventions-brief.md`) はrun.mdとrevise.mdで一致している
- Inspector のSCOPE出力フォーマット (`{feature} | cross-check | wave-1..{N}`) はdesign/impl Inspector群で統一されている
- sdd-review-self の self-review scope設定はCLAUDE.md等の実際の配置と一致している
- `decisions.md` のエントリ形式 (`[{ISO-8601}] D{seq}: {DECISION_TYPE} | {summary}`) はCLAUDE.md、handover/SKILL.md、session.md templateで統一されている
- Steering Feedback Loop (`CODIFY` / `PROPOSE`) の動作定義はCLAUDE.md、review.md、Auditor定義ファイルで一致している
- Session Resume手順 (1-7) はCLAUDE.md とHandover SKILL.mdで補完し合っており、矛盾なし
- `builder-report-{group}.md` 命名規則はBuilder定義、impl.md、run.mdで一致している
- ConventionsBriefのheader note "Steering overrides this brief on conflict." は template、run.md、sdd-conventions-scanner.mdで一致している

---

## Overall Assessment

**全体状態: 概ね良好。高優先度の修正が2点、中優先度が5点。**

**最重要対応事項:**

1. **[HIGH] settings.json に `sdd-conventions-scanner` のTask許可が欠如** — CLAUDE.mdとrun.md/impl.mdがConventionsScannerをTask経由でdispatchすることを明記しているにもかかわらず、settings.jsonのperissionsリストに `Task(sdd-conventions-scanner)` が含まれていない。実行環境によってはpermission deniedエラーが発生する可能性がある。

2. **[HIGH] `sdd-auditor-dead-code.md` の出力FormatにSCOPEフィールドがない** — 他のAuditorと異なり、dead-code AuditorのOutput Formatに `SCOPE:` フィールドが欠如している。Leadがverdictを処理する際のスコープ識別に支障をきたす可能性がある。

**低リスク事項:**

- `design-review.md` とInspector定義の重複は、Inspectorの独立動作の設計意図の結果であり、実害は少ない
- Inspector間のminor inconsistency (testability agent の wave-mode実装省略等) は機能には影響しないが文書整合性を下げる
- Dead-code Inspectorがwave-scoped modeをサポートしないことは設計通りと推定されるが、明示的な文書化が望ましい

**循環参照**: なし確認済み。参照グラフはDAG構造を維持している。

**未定義参照**:
- `{{SDD_DIR}}/project/specs/*/reviews/verdicts.md` (Session Resume Step 2a) — これはruntime生成ファイルであり未定義参照ではない
- `specs/.cross-cutting/{id}/` パス — revise.mdで定義され、review.mdおよびstatus SKILL.mdで参照。整合している
