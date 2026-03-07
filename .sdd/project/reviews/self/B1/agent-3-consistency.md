# Consistency & Dead Ends Report

## Issues Found

### [CRITICAL] C1: フェーズ名 `design-reviewed` / `impl-done` が CLAUDE.md のフェーズ定義に未定義

**Location**: `framework/claude/skills/sdd-roadmap/refs/run.md:64-65`
**Description**: Dispatch Loop の疑似コードに `design-reviewed→Impl, impl-done→Impl Review` という遷移が記述されている。しかし CLAUDE.md (line 153) のフェーズ定義は `initialized → design-generated → implementation-complete (also: blocked)` のみであり、`design-reviewed` と `impl-done` は定義されていない。

これは2つの解釈がありえる:
1. **疑似コード内の可読性のためのラベル** (実際のフェーズ値ではない) — だが、同じ run.md の Readiness Rules テーブル (line 87-90) では正規フェーズ名 `initialized`, `design-generated` を使っており、疑似コードとテーブルで表記が不統一。
2. **新しいフェーズ値** — Design Review 通過後に `design-reviewed` を設定し、Impl 完了後に `impl-done` を設定する意図だが、CLAUDE.md Phase-Driven Workflow に反映されていない。

**Evidence**:
- CLAUDE.md line 153: `Phases: initialized → design-generated → implementation-complete (also: blocked)`
- run.md line 64-65: `initialized→Design, design-generated→Design Review, design-reviewed→Impl, impl-done→Impl Review`
- run.md Readiness Rules (line 87): `Design: Phase is initialized` — 正規フェーズ名を使用
- run.md Readiness Rules (line 88): `Design Review: Phase is design-generated` — 正規フェーズ名を使用
- run.md Readiness Rules (line 89): `Implementation: Design Review verdict is GO/CONDITIONAL` — フェーズ名を使わず条件で記述
- design.md ref Step 3: `Set phase = design-generated` — `design-reviewed` への遷移なし
- impl.md ref Step 3: `Set phase = implementation-complete` — `impl-done` への遷移なし

**Impact**: run.md の Dispatch Loop 疑似コードが Design Review → Implementation / Impl 完了 → Impl Review の遷移を `design-reviewed` / `impl-done` で記述しているが、design.md/impl.md の Phase Handler で実際に設定されるフェーズ値と一致しない。Lead が疑似コードをフェーズ値として解釈する可能性がある。

---

### [HIGH] H1: run.md Readiness Rules の Implementation 条件に「Design Review verdict」を使用 — フェーズベースではない混合方式

**Location**: `framework/claude/skills/sdd-roadmap/refs/run.md:89`
**Description**: Readiness Rules テーブルで Implementation の条件は「Design Review verdict is GO/CONDITIONAL」と記述されている。他の3つの条件はすべてフェーズベース (`Phase is initialized`, `Phase is design-generated`) なのに対し、Implementation だけ verdict ベース。

実際のフローでは:
1. Design Review が GO → `design-generated` フェーズのまま (フェーズ変更なし)
2. Implementation へ進む判定が「フェーズ」ではなく「前回の verdict 結果」に依存

これ自体は正しい設計判断だが、Dispatch Loop 疑似コードの `design-reviewed→Impl` と矛盾する。`design-reviewed` はフェーズとして設定されないため、Dispatch Loop の疑似コードは誤解を招く。

---

### [HIGH] H2: SubAgent 上限値の残存参照 — CLAUDE.md で削除済みだが install 先 CLAUDE.md にまだ残存

**Location**: `.claude/CLAUDE.md` (install先、git status で D マーク付き handover ファイルと共存)
**Description**: `framework/claude/CLAUDE.md` (line 103) では `No framework-imposed SubAgent limit` に更新済みだが、このプロジェクトの `.claude/CLAUDE.md` (session instructions に引用されている version) には旧記述 `Concurrent SubAgent limit: 24 (max 8 per pipeline × 3 types + headroom)` が残っている。

**Evidence**:
- framework/claude/CLAUDE.md line 103: `Concurrency: No framework-imposed SubAgent limit. Platform manages concurrent execution.`
- CLAUDE.md in system prompt: `Concurrent SubAgent limit: 24 (max 8 per pipeline × 3 types + headroom). Consensus mode...`

**Impact**: install 先の CLAUDE.md が未更新のため、現在のセッションでは旧制限が適用されている。ただしこれは install.sh で更新すべきインスタンスの問題であり、framework ソースは正しい。

---

### [HIGH] H3: `lookahead: true` の追跡方式が未定義 — "internal tracking" と記載されるのみ

**Location**: `framework/claude/skills/sdd-roadmap/refs/run.md:101`
**Description**: `Track as lookahead: true (internal tracking, NOT in spec.yaml)` — Lead がどのように追跡するかの具体的メカニズムが定義されていない。spec.yaml に記録しないなら、Lead の会話コンテキスト内の変数として保持するしかないが、compact 後にロストする。

session.md auto-draft にも lookahead 状態の記録は言及されていない。Pipeline Stop Protocol (CLAUDE.md line 287-291) や Session Resume (CLAUDE.md line 266-276) にも lookahead 状態の復元手段がない。

**Impact**: 長時間のパイプライン実行中に compact が発生した場合、lookahead 状態が失われる。再開時に `/sdd-roadmap run` で spec.yaml をスキャンしても lookahead 情報は復元できない。

---

### [HIGH] H4: "Island spec" / "fast-track lane" 用語の CLAUDE.md と run.md 間の不一致

**Location**: `framework/claude/CLAUDE.md:92` vs `framework/claude/skills/sdd-roadmap/refs/run.md:27-41`
**Description**:
- CLAUDE.md line 92: `Wave Bypass: Island specs (no dependencies, no dependents) run as independent fast-track pipelines outside the wave structure.`
- run.md Step 3: Island Spec Detection (Wave Bypass) セクションで詳細に定義 — `fast-track lane` という用語を使用

CLAUDE.md では `fast-track pipelines` (複数形), run.md では `fast-track lane` (単数形で別名)。用語の揺れは軽微だが、概念の正式名称が不統一。

また、CLAUDE.md の Parallel Execution Model セクションに `Wave Bypass` が記載されているが、crud.md の Create Mode には Island spec 検出やFast-track lane 対応の記述がない。Create Mode は wave 割り当てを行うが、Island spec を自動検出して fast-track 指定する処理が欠落。

**Impact**: crud.md で roadmap を作成する時点で island spec を検出・タグ付けしなければ、run.md Step 3 での検出は毎回動的計算が必要になる。設計上は問題ないが、crud.md の Parallelism Report にも Island spec の表示がない。

---

### [MEDIUM] M1: Foundation-First ヒューリスティクスと既存のスケジューリングの潜在的矛盾

**Location**: `framework/claude/skills/sdd-roadmap/refs/crud.md:14-19`
**Description**: crud.md Create Mode Step 4b に Foundation-First ヒューリスティクスが定義されている:
- Model/Schema definitions, Error handling infrastructure, Shared libraries → Wave 1
- Heuristics: name keywords (`model`, `schema`, `shared`, `common`, `core`, `base`, `error`, `logging`, `config`)

これ自体は合理的だが、run.md の Wave Scheduling には Foundation-First への言及がない。run.md は crud.md で作成された wave 割り当てを読み取るのみ。

潜在的矛盾: Foundation-First は依存関係ベースではなくヒューリスティクスベースで Wave 1 に配置する。しかし topological sort (crud.md Step 4c) は依存関係ベースで割り当てる。ヒューリスティクスで Wave 1 に入れたスペックが実際には依存関係上 Wave 2 以降にあるべき場合の優先順位ルールが明示されていない。

crud.md Step 4c: `Topological sort remaining specs → assign wave = dependency level (foundation deps go to Wave 2+)` — "remaining specs" は Foundation-First で選ばれなかったスペックのみ。Foundation specs が他の foundation spec に依存する場合の処理が未定義。

---

### [MEDIUM] M2: Backfill チェックのスコープ曖昧性

**Location**: `framework/claude/skills/sdd-roadmap/SKILL.md:58-65`
**Description**: Single-Spec Roadmap Ensure の backfill check:
- `a. New spec has dependencies: [] (no dependencies yet at design time)`
- `b. Find highest incomplete wave where adding a dependency-free spec causes no conflict`

"no conflict" の定義が不明。File ownership conflict なのか、dependency conflict なのか、wave capacity limit なのか。run.md Step 2 の Cross-Spec File Ownership Analysis は design.md の Components セクションを読むが、design 前のスペックには design.md が存在しない。

---

### [MEDIUM] M3: Verdict persistence format の `verdict.cpf` vs `verdicts.md` の参照不一致

**Location**: 複数ファイル
**Description**:
- review.md Step 7: `Read {scope-dir}/active/verdict.cpf` — Auditor が書く個別 verdict ファイルは `.cpf`
- review.md Step 8: `Persist verdict to {scope-dir}/verdicts.md` — 永続化先は `.md`
- CLAUDE.md line 34: `Auditor reads them and writes verdict.cpf` — `.cpf`
- SKILL.md (Router): Verdict Persistence Format で `verdicts.md` を参照

これ自体は一貫している (Auditor が `.cpf` を書き、Lead が `.md` に永続化) が、名前が紛らわしい。`verdict.cpf` (単一 batch の Auditor output) と `verdicts.md` (全 batch の累積ログ) の区別が暗黙的。

---

### [MEDIUM] M4: sdd-review-self SKILL.md の スキルカウント不一致

**Location**: CLAUDE.md Commands テーブル
**Description**: CLAUDE.md Commands (6) テーブルには `/sdd-review-self` が含まれていない。Skills ディレクトリには 7 つの sdd-* SKILL.md が存在するが、CLAUDE.md は「Commands (6)」と記載。

**Evidence**:
- CLAUDE.md line 141: `### Commands (6)`
- Glob 結果: sdd-release, sdd-knowledge, sdd-steering, sdd-handover, sdd-status, sdd-review-self, sdd-roadmap = 7個

**Impact**: `/sdd-review-self` はフレームワーク開発専用であり、ユーザー向けコマンドではないため意図的に除外されている可能性が高い。ただし、カウントとの不一致は存在する。

---

### [MEDIUM] M5: Design Lookahead の Staleness Guard でのフェーズ遷移が未詳細

**Location**: `framework/claude/skills/sdd-roadmap/refs/run.md:103`
**Description**: `If a Wave N spec's design changes (SPEC-UPDATE-NEEDED → re-design), check if any lookahead spec depends on it. If yes: invalidate lookahead design, mark for re-design after Wave N QG`

"invalidate lookahead design" の具体的操作が未定義。
- design.md を削除するのか？
- spec.yaml.phase を `initialized` に戻すのか？
- `design-generated` のままで re-design フラグを立てるのか？
- lookahead: true の追跡 (H3 で指摘) がないため、どのスペックが lookahead かの判定も不明確。

---

### [MEDIUM] M6: run.md Step 7 Wave QG の verdict persistence パスと review.md の scope-dir 定義の重複

**Location**: `run.md:170,181` vs `review.md:53`
**Description**:
- run.md Step 7a: `Persist verdict to {{SDD_DIR}}/project/reviews/wave/verdicts.md`
- run.md Step 7b: `Persist verdict to {{SDD_DIR}}/project/reviews/wave/verdicts.md`
- review.md: `Project-level (wave): {{SDD_DIR}}/project/reviews/wave/`

Cross-check review と Wave QG review は同じ `wave/` ディレクトリを使うが、header フォーマットが異なる:
- run.md Step 7a: `[W{wave}-B{seq}]`
- run.md Step 7b: `[W{wave}-DC-B{seq}]`
- review.md の wave-scoped cross-check は同じパスだが header は未指定 (SKILL.md の Verdict Persistence Format に準拠?)

Wave QG (run.md) が review.md の Review Execution Flow を呼び出す場合 (`Execute impl review per refs/review.md`), review.md のデフォルト verdict persistence と run.md の固有 header の優先順位が曖昧。

---

### [LOW] L1: design.md ref の Phase Gate での `implementation-complete` 用語

**Location**: `framework/claude/skills/sdd-roadmap/refs/design.md:18`
**Description**: `If spec.yaml.phase is implementation-complete: warn user that re-designing will invalidate existing implementation.` — これは正しいが、revision workflow との関係が複雑。design.md ref は CLAUDE.md の `Use /sdd-roadmap revise {feature} for completed specs` とも整合しており、design subcommand は revision を推奨する。

---

### [LOW] L2: Inspector エージェント数の表記

**Location**: `framework/claude/CLAUDE.md:26`
**Description**: `6 design + 6 impl inspectors +1 E2E (web projects), 4 (dead-code)` — 総計は条件付きで 6+7+4 = 17 (E2E 含む)。Agent ファイル数は 23 個:
- 6 design inspectors: rulebase, testability, architecture, consistency, best-practices, holistic
- 6 impl inspectors: impl-rulebase, interface, test, quality, impl-consistency, impl-holistic
- 1 E2E: e2e
- 4 dead-code: dead-settings, dead-code, dead-specs, dead-tests
- 3 auditors: auditor-design, auditor-impl, auditor-dead-code
- 2 other T2: architect, taskgenerator
- 1 other T3: builder

合計 = 6 + 6 + 1 + 4 + 3 + 2 + 1 = 23 — ファイル数と一致。

---

### [LOW] L3: CLAUDE.md の Profiles パス

**Location**: `framework/claude/CLAUDE.md:119`
**Description**: `Profiles: {{SDD_DIR}}/settings/profiles/` — このパスは CLAUDE.md の Paths セクションに記載されているが、ほかのどの ref ファイルにも言及されていない。sdd-steering SKILL.md (line 37) が `{{SDD_DIR}}/settings/profiles/` を参照している。Install.sh (line 486) でも正しくインストールされる。一貫性あり。

---

## Confirmed OK

- **フェーズ名 (initialized, design-generated, implementation-complete, blocked)**: CLAUDE.md, spec.yaml テンプレート, design.md ref, impl.md ref, run.md Readiness Rules, revise.md, status SKILL.md で一貫して使用 (C1 の疑似コードを除く)
- **Verdict 値 (GO, CONDITIONAL, NO-GO, SPEC-UPDATE-NEEDED)**: CLAUDE.md, review.md, 全 Auditor/Inspector エージェントで一貫
- **Severity コード (C/H/M/L)**: CPF フォーマット仕様, 全 Inspector/Auditor 出力フォーマットで一貫
- **Knowledge タグ ([PATTERN], [INCIDENT], [REFERENCE])**: CLAUDE.md, Builder エージェント, Knowledge SKILL.md, buffer.md テンプレートで一貫
- **Retry 制限値**: CLAUDE.md (retry_count: max 5, spec_update_count: max 2, aggregate cap: 6, dead-code: max 3) と run.md (Step 4 Phase Handlers, Step 7) で一貫
- **Review ディレクトリ構造 (reviews/active/ → reviews/B{seq}/)**: CLAUDE.md, review.md, SKILL.md Router で一貫
- **SubAgent 名**: 全 agent .md ファイルの `name:` フィールドが SKILL.md や review.md の参照と一致
- **spec.yaml テンプレート**: init.yaml の全フィールドが CLAUDE.md, impl.md, design.md ref で参照されるフィールドと一致
- **Handover ファイル構造**: session.md, decisions.md, buffer.md のテンプレートが CLAUDE.md の記述と一致
- **Steering テンプレート**: product.md, tech.md, structure.md が CLAUDE.md, sdd-steering SKILL.md で参照
- **install.sh のパス**: framework/ → .claude/ のマッピングが全ファイルで一貫
- **circular reference なし**: ファイル参照関係にサイクルなし (CLAUDE.md → SKILL.md → refs → agents, 逆方向参照なし)
- **CPF フォーマット**: cpf-format.md の仕様と全 Inspector/Auditor の出力フォーマットが一貫
- **Decision types**: CLAUDE.md の Recording セクションと Format セクションで同一の7種類

---

## Cross-Reference Matrix

### フェーズ名の使用箇所

| フェーズ名 | CLAUDE.md | design.md ref | impl.md ref | run.md | revise.md | status SKILL | spec.yaml template |
|-----------|-----------|---------------|-------------|--------|-----------|-------------|-------------------|
| `initialized` | L153 | L12 | - | L64,L87 | - | L35 | L10 |
| `design-generated` | L153 | L35 | L12-13 | L64,L88 | L39 | L35 | - |
| `implementation-complete` | L153 | L18 | L57 | L78,L129 | L8 | L35 | - |
| `blocked` | L153 | L17 | L10 | L78 | L11 | L36 | - |
| **`design-reviewed`** | **ABSENT** | - | - | **L64** | - | - | - |
| **`impl-done`** | **ABSENT** | - | - | **L64** | - | - | - |

### Verdict 値の使用箇所

| Verdict | CLAUDE.md | review.md | run.md | Auditor-design | Auditor-impl | Auditor-dead-code |
|---------|-----------|-----------|--------|----------------|--------------|-------------------|
| GO | L23 | L110 | L114 | L167 | L220 | L133 |
| CONDITIONAL | L23 | L110 | L114 | L167 | L218 | L133 |
| NO-GO | L23 | L112 | L115 | L167 | L211 | L129 |
| SPEC-UPDATE-NEEDED | L23 (impl only) | L113 | L131 | - | L215 | - |

### SubAgent 名の使用箇所

| Agent Name | Agent File | review.md | run.md | design.md ref | impl.md ref |
|------------|-----------|-----------|--------|---------------|-------------|
| sdd-architect | OK | - | L108 | L24 | - |
| sdd-taskgenerator | OK | - | - | - | L26 |
| sdd-builder | OK | - | L93,L123 | - | L39 |
| sdd-auditor-design | OK | L27 | - | - | - |
| sdd-auditor-impl | OK | L35 | - | - | - |
| sdd-auditor-dead-code | OK | L45 | - | - | - |
| sdd-inspector-rulebase | OK | L25 | - | - | - |
| sdd-inspector-testability | OK | L25 | - | - | - |
| sdd-inspector-architecture | OK | L25 | - | - | - |
| sdd-inspector-consistency | OK | L25 | - | - | - |
| sdd-inspector-best-practices | OK | L25 | - | - | - |
| sdd-inspector-holistic | OK | L25 | - | - | - |
| sdd-inspector-impl-rulebase | OK | L33 | - | - | - |
| sdd-inspector-interface | OK | L33 | - | - | - |
| sdd-inspector-test | OK | L33 | - | - | - |
| sdd-inspector-quality | OK | L33 | - | - | - |
| sdd-inspector-impl-consistency | OK | L33 | - | - | - |
| sdd-inspector-impl-holistic | OK | L33 | - | - | - |
| sdd-inspector-e2e | OK | L34 | - | - | - |
| sdd-inspector-dead-settings | OK | L44 | - | - | - |
| sdd-inspector-dead-code | OK | L44 | - | - | - |
| sdd-inspector-dead-specs | OK | L44 | - | - | - |
| sdd-inspector-dead-tests | OK | L44 | - | - | - |

### Numeric 制限値の整合性

| 制限 | CLAUDE.md | run.md | 一致 |
|------|-----------|--------|------|
| retry_count max | 5 (L171) | 5 (L115,L130,L173) | OK |
| spec_update_count max | 2 (L171) | 2 (L131) | OK |
| Aggregate cap | 6 (L171) | 6 (L132,L173) | OK |
| Dead-code retry max | 3 (L172) | 3 (L184) | OK |
| SubAgent limit | なし (L103) | 記載なし | OK |
| Consensus threshold | ceil(N*0.6) (SKILL.md L112) | 記載なし | OK (SKILL.md で一元定義) |

### ファイルパス参照の整合性

| パス | 定義元 | 参照元 | 一致 |
|------|--------|--------|------|
| `{{SDD_DIR}}/project/steering/` | CLAUDE.md L113 | Architect, TaskGenerator, 全Inspector, sdd-steering | OK |
| `{{SDD_DIR}}/project/specs/` | CLAUDE.md L114 | SKILL.md, refs/*, sdd-status | OK |
| `{{SDD_DIR}}/project/knowledge/` | CLAUDE.md L115 | sdd-knowledge, run.md L188, impl.md L65 | OK |
| `{{SDD_DIR}}/handover/` | CLAUDE.md L116 | sdd-handover, refs/*, session resume | OK |
| `{{SDD_DIR}}/settings/rules/` | CLAUDE.md L117 | Architect, Inspector-rulebase, TaskGenerator | OK |
| `{{SDD_DIR}}/settings/templates/` | CLAUDE.md L118 | Architect, sdd-steering, sdd-knowledge | OK |
| `{{SDD_DIR}}/settings/profiles/` | CLAUDE.md L119 | sdd-steering L37 | OK |
| `.claude/agents/` | CLAUDE.md L120 | install.sh L487 | OK |
| `reviews/active/` to `reviews/B{seq}/` | CLAUDE.md L34,L102 | review.md L55-66 | OK |
| `reviews/wave/verdicts.md` | review.md L105 | run.md L170,L181 | OK |
| `reviews/cross-check/verdicts.md` | review.md L104 | - | OK (定義のみ) |
| `reviews/self/verdicts.md` | review.md L106 | sdd-review-self | OK |
| `{{SDD_DIR}}/project/reviews/dead-code/` | review.md L51 | review.md L104 | OK |
| `init.yaml` template | SKILL.md L75 | framework存在確認済 | OK |

---

## Overall Assessment

フレームワーク全体の整合性は高いが、**最重要の問題は C1: run.md の Dispatch Loop 疑似コードに未定義フェーズ名 `design-reviewed` と `impl-done` が使用されていること**。これは Lead がフェーズ遷移を誤解する原因になりうる。

次に重要なのは **H3: lookahead 追跡方式の未定義**。compact 後の状態復元手段がないため、long-running パイプラインで lookahead 情報が失われるリスクがある。

新概念 (Island spec, fast-track lane, Foundation-First, Design Lookahead, Backfill) はそれぞれ合理的な設計だが、一部の具体的な操作手順 (M5: lookahead invalidation, M1: Foundation-First vs topological sort の優先順位, M2: backfill の conflict 定義) が未定義。

SubAgent 制限の削除は framework/claude/CLAUDE.md では完了しているが、install 先には反映されていない (H2) — これは install 操作で解決される。
