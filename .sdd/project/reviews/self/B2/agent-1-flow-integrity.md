## Flow Integrity Report

### Issues Found

- [MEDIUM] SelfCheck FAIL-RETRY-2 処理パスにおける spec.yaml 更新タイミングの曖昧性 / impl.md + sdd-builder.md
- [MEDIUM] Design Auditor が SPEC-UPDATE-NEEDED を出せない設計と run.md の矛盾 / review.md + run.md + sdd-auditor-design.md
- [LOW] Consensus mode 時の wave-scoped review における active ディレクトリ命名パターン未定義 / review.md + run.md
- [LOW] review dead-code の phase gate スキップに関する記述が review.md のみで CLAUDE.md に不在 / review.md + CLAUDE.md

### Confirmed OK

- Router dispatch completeness: 全 subcommand (design, impl, review, run, revise, create, update, delete, -y) が正しい ref にルーティングされている
- Phase gate consistency: design.md (initialized/design-generated/implementation-complete/blocked), impl.md (design-generated/implementation-complete/blocked), review.md (design=design-generated+, impl=implementation-complete, dead-code=none) が CLAUDE.md の phase 定義と整合
- Auto-fix counter limits: CLAUDE.md の retry_count max 5 / spec_update_count max 2 / aggregate cap 6 が run.md Step 4 Phase Handlers と完全一致。Dead-code max 3 も run.md Step 7b と一致
- Wave quality gate flow: Step 7a (cross-check) -> 7b (dead-code) -> 7c (post-gate) の完全なフロー。1-spec roadmap skip も Router と run.md で一致
- Verdict persistence format: Router の Shared Protocols セクションで定義された B{seq} 形式が review.md, run.md の全箇所で一致
- Edge case: empty roadmap はブロック (create/update/delete)、1-spec は Wave QG スキップ、blocked spec は全 ref で BLOCK 処理、retry limit exhaustion は Blocking Protocol (Step 6) で処理
- Read clarity: Router の "Execution Reference" セクションが明示的に "Read refs/X.md" と指定。各 ref は "Assumes Single-Spec Roadmap Ensure already completed by router" と前提を明記
- Consensus mode: Router Shared Protocols で N=1 デフォルト動作、active-{p} サフィックス、B{seq}/pipeline-{p} アーカイブが明確に定義。review.md Step 9 のアーカイブパスと一致
- Counter reset: CLAUDE.md "Counter reset triggers: wave completion" と run.md Step 7c Post-gate "Reset counters" が一致
- Verdict destination by review type: review.md に5種類 (single-spec, dead-code, cross-check, wave, self) の全パスが定義済み
- Builder parallel coordination: CLAUDE.md "As each Builder completes, immediately update tasks.yaml" と impl.md "Builder incremental processing" が一致
- Steering Feedback Loop: CLAUDE.md の概要が review.md の Steering Feedback Loop Processing セクションで詳細化されており、整合している
- Island spec (Wave Bypass): run.md Step 3 で定義、1-Spec Roadmap Optimizations 適用、Wave QG 不参加が明記
- Design Lookahead: run.md Step 4 で staleness guard 含む完全な定義
- Revise mode: Step 4 で counter reset (retry_count=0, spec_update_count=0) が CLAUDE.md "Counter reset triggers: /sdd-roadmap revise start" と一致
- Blocking Protocol: run.md Step 6 で downstream traversal -> phase save -> blocked 設定 -> user options の完全フロー
- Knowledge flush timing: impl.md Step 4 で 1-spec のみ flush、multi-spec は run.md Post-gate で flush。buffer.md の overwrite と一致
- SelfCheck (新規変更): sdd-builder.md の completion report に SelfCheck フィールド追加、impl.md の Builder incremental processing に処理ロジック追加。整合している
- TaskGenerator Steering Integration (新規変更): sdd-taskgenerator.md Step 2 に steering context 参照追加、tasks-generation.md に Steering Integration セクション追加。整合している

### Overall Assessment

全体的なフロー整合性は高い。Router -> refs のディスパッチは明確で、各 ref の前提条件も正しく記述されている。Phase gate、auto-fix loop、verdict persistence の各プロトコルは CLAUDE.md と refs 間で一貫している。

未コミット変更 (SelfCheck, Steering Integration) は既存フローに適切に統合されており、破壊的な影響はない。

以下に各レビュー基準の詳細分析を記載する。

---

## 詳細分析

### 1. Router Dispatch Completeness

全 subcommand のルーティングを検証:

| Subcommand | Router 判定 | Dispatch 先 | 結果 |
|---|---|---|---|
| `design {feature}` | Design Subcommand | `refs/design.md` | OK |
| `impl {feature} [tasks]` | Impl Subcommand | `refs/impl.md` | OK |
| `review design {feature}` | Review Subcommand | `refs/review.md` | OK |
| `review impl {feature} [tasks]` | Review Subcommand | `refs/review.md` | OK |
| `review dead-code` | Review Subcommand | `refs/review.md` | OK |
| `review {type} --consensus N` | Review Subcommand | `refs/review.md` | OK |
| `review design --cross-check` | Review Subcommand | `refs/review.md` | OK |
| `review impl --cross-check` | Review Subcommand | `refs/review.md` | OK |
| `review design --wave N` | Review Subcommand | `refs/review.md` | OK |
| `review impl --wave N` | Review Subcommand | `refs/review.md` | OK |
| `run` / `run --gate` / `run --consensus N` | Run Mode | `refs/run.md` | OK |
| `revise {feature} [instructions]` | Revise Mode | `refs/revise.md` | OK |
| `create` / `create -y` | Create Mode | `refs/crud.md` | OK |
| `update` | Update Mode | `refs/crud.md` | OK |
| `delete` | Delete Mode | `refs/crud.md` | OK |
| `-y` | Auto-detect | run or create | OK |
| (empty) | Auto-detect | user choice | OK |

Router の "Execution Reference" セクション (SKILL.md L96-104) が各モードに対する ref ファイルを明示的に列挙しており、漏れはない。

### 2. Phase Gate Consistency

各 ref が要求するフェーズと CLAUDE.md の定義を照合:

**CLAUDE.md Phase 定義** (L153):
- `initialized` -> `design-generated` -> `implementation-complete`
- `blocked` (特殊状態)

**design.md Step 2**:
- `blocked` -> BLOCK
- `implementation-complete` -> warn + confirm
- `initialized`, `design-generated` -> proceed
- それ以外 -> BLOCK "Unknown phase"

**impl.md Step 1**:
- `blocked` -> BLOCK
- `design-generated` -> proceed
- `implementation-complete` -> proceed (re-execution)
- それ以外 -> BLOCK "Phase is '{phase}'"

**review.md Step 2**:
- Design Review: `design.md` 存在確認 + `blocked` ブロック
- Impl Review: `design.md` + `tasks.yaml` 存在 + phase=`implementation-complete` + `blocked` ブロック
- Dead-code Review: phase gate なし

**run.md Readiness Rules**:
- Design: phase=`initialized` + intra-wave deps at `design-generated`
- Design Review: phase=`design-generated`
- Implementation: phase=`design-generated` + design review GO/CONDITIONAL + no file overlap + inter-wave deps `implementation-complete`
- Impl Review: all Builders complete

全て CLAUDE.md 定義と整合している。

### 3. Auto-Fix Loop Consistency

**CLAUDE.md (L169-175)**:
- retry_count: max 5 (NO-GO)
- spec_update_count: max 2 (SPEC-UPDATE-NEEDED)
- Aggregate cap: 6
- Dead-Code: max 3
- CONDITIONAL = GO
- Counter reset: wave completion, user escalation, `/sdd-roadmap revise`

**run.md Phase Handlers**:
- Design Review NO-GO: "max 5 retries, aggregate cap 6" (L113) -> OK
- Design Review SPEC-UPDATE-NEEDED: "not expected for design review. If received, escalate immediately" (L114) -> OK (Design Auditor の verdict は GO/CONDITIONAL/NO-GO のみ)
- Impl Review NO-GO: "max 5 retries" (L128) -> OK
- Impl Review SPEC-UPDATE-NEEDED: "max 2, reset phase=design-generated, cascade" (L129) -> OK
- Aggregate cap: "Total cycles MUST NOT exceed 6" (L130) -> OK
- Wave QG Cross-Check NO-GO: "Max 5 retries (aggregate cap 6)" (L171) -> OK
- Wave QG Dead-Code NO-GO: "max 3 retries -> escalate" (L182) -> OK

**run.md Post-gate (L185)**:
- "Reset counters: retry_count=0, spec_update_count=0" -> Counter reset at wave completion OK

**revise.md Step 4 (L37-38)**:
- "Reset orchestration.retry_count = 0, orchestration.spec_update_count = 0" -> Counter reset at revise start OK

全て整合。

### 4. Wave Quality Gate Flow

**run.md Step 7**:
1. 1-Spec Roadmap: Skip (Router 1-Spec Optimizations と一致)
2. Wave completion condition: all specs `implementation-complete` or `blocked`
3. Step 7a: Cross-Check Review (wave-scoped impl review)
   - verdict を `project/reviews/wave/verdicts.md` に永続化 (header: `[W{wave}-B{seq}]`)
   - GO/CONDITIONAL -> dead-code
   - NO-GO -> Builder auto-fix (max 5, aggregate 6), SPEC-UPDATE-NEEDED -> cascade
4. Step 7b: Dead Code Review
   - verdict を `project/reviews/wave/verdicts.md` に永続化 (header: `[W{wave}-DC-B{seq}]`)
   - GO/CONDITIONAL -> Wave complete
   - NO-GO -> max 3 retries -> escalate
5. Step 7c: Post-gate
   - Counter reset, Knowledge flush, Commit, session.md auto-draft

このフローは完全で隙間なく定義されている。

### 5. Consensus Mode

**Router Shared Protocols (SKILL.md L110-126)**:
- N パイプライン並列
- active-{p}/ ディレクトリ分離
- 各パイプラインに独立 Inspector セット + Auditor
- threshold: ceil(N*0.6)
- 集約: key by `{category}|{location}`, frequency counting
- Consensus verdict 判定ロジック
- Archive: `B{seq}/pipeline-{p}/`

**review.md (L68)**:
- "If `--consensus N`, apply Consensus Mode protocol (see Router)."

**run.md (L118, L134)**:
- "For `--consensus N`, apply Consensus Mode protocol (see Router)."

参照先が一元化されており矛盾なし。

### 6. Verdict Persistence Format

**Router Shared Protocols (SKILL.md L127-137)**:
- B{seq} 番号付け
- Batch entry header format
- Raw / Consensus / Noise / Disposition / Tracked / Resolved セクション

**review.md (L65)**:
- "Persist verdict to `{scope-dir}/verdicts.md` (see Router -> Verdict Persistence Format)"

**run.md**:
- Wave QG: `project/reviews/wave/verdicts.md` (header: `[W{wave}-B{seq}]`) -> Wave-scoped format
- Dead-code: `project/reviews/wave/verdicts.md` (header: `[W{wave}-DC-B{seq}]`)

**review.md Verdict Destination** (L98-106):
- 5 パス全定義済み

全フォーマットが一貫している。

### 7. Edge Cases

| Edge Case | 処理場所 | 結果 |
|---|---|---|
| Empty roadmap (run/update/revise) | Router Error Handling | "No roadmap found" BLOCK -> OK |
| Empty roadmap (review dead-code/cross-check/wave) | Router Single-Spec Ensure #3 | BLOCK "No roadmap found" -> OK |
| 1-spec roadmap | Router 1-Spec Optimizations | Wave QG skip, dead-code skip, commit format -> OK |
| Blocked spec | design.md/impl.md/review.md/run.md | 全箇所で BLOCK -> OK |
| Retry limit exhaustion | run.md Blocking Protocol (Step 6) | Downstream cascade + user options -> OK |
| Spec not in roadmap | Router Single-Spec Ensure | BLOCK + guidance -> OK |
| Circular dependency | run.md Step 1 DAG validation | BLOCK "Circular dependency detected" -> OK |
| All Builders blocked | impl.md BUILDER_BLOCKED handling | Classify + escalate -> OK |
| Inspector failure | review.md Step 5 | "retry, skip, or proceed with available results" -> OK |
| Auditor timeout | Auditor agents: Verdict Output Guarantee | Partial verdict output -> OK |

### 8. Read Clarity

Router SKILL.md L95-104:
```
After mode detection and roadmap ensure, Read the reference file for the detected mode:
- Design -> Read refs/design.md
- Impl -> Read refs/impl.md
- Review -> Read refs/review.md
- Run -> Read refs/run.md
- Revise -> Read refs/revise.md
- Create / Update / Delete -> Read refs/crud.md

Then follow the instructions in the loaded file.
```

明示的かつ完全。

---

## 発見事項の詳細

### [MEDIUM] M1: SelfCheck FAIL-RETRY-2 処理パスにおける spec.yaml 更新タイミングの曖昧性

**Location**: `framework/claude/skills/sdd-roadmap/refs/impl.md` L53-56 + `framework/claude/agents/sdd-builder.md` L57-64

**Description**: impl.md の Builder incremental processing に新しく追加された SelfCheck 処理ロジックでは、`FAIL-RETRY-2({items})` の場合 "Lead judgment: continue (if items are minor) or re-dispatch Builder with fix context" とある。しかし、re-dispatch した場合の tasks.yaml 更新タイミングが不明確。

具体的には:
1. Builder A が FAIL-RETRY-2 を報告 -> Lead が re-dispatch を選択
2. この時点で tasks.yaml の `done` マーキングは行うのか? (初回 Builder の出力にはファイルリストが含まれる)
3. Re-dispatch された Builder が完了した場合、`implementation.files_created` のマージは union なのか replace なのか?

impl.md L62 には "For TASK RE-EXECUTION mode, merge new files into existing list (union)" とあるが、SelfCheck re-dispatch は TASK RE-EXECUTION とは別のパス。

**Recommendation**: impl.md の SelfCheck FAIL-RETRY-2 処理に「re-dispatch 時は tasks.yaml の done マーキングを保留し、re-dispatch 完了後に最終結果で更新する。files_created は union マージ」と明記すべき。

### [MEDIUM] M2: Design Auditor が SPEC-UPDATE-NEEDED を出せない設計と run.md の整合

**Location**:
- `framework/claude/agents/sdd-auditor-design.md` L184 (verdict: `GO|CONDITIONAL|NO-GO` のみ)
- `framework/claude/skills/sdd-roadmap/refs/run.md` L114 ("SPEC-UPDATE-NEEDED -> not expected for design review. If received, escalate immediately")

**Description**: Design Auditor の Output Format では verdict 選択肢が `GO|CONDITIONAL|NO-GO` の3つのみで、SPEC-UPDATE-NEEDED は含まれない。run.md もこれを "not expected" として扱い、受信時は即座に escalate するとしている。これは設計意図として整合している。

しかし、review.md の Review Execution Flow (共通フロー) では design/impl/dead-code 全てで同じ Auditor verdict 読み取りステップを通る。review.md の "Next Steps by Verdict" (L108-113) では NO-GO と SPEC-UPDATE-NEEDED を列挙しているが、Design Review 固有の制約 (SPEC-UPDATE-NEEDED は出ない) が review.md 側に明記されていない。

Standalone 実行時 (review.md Standalone Verdict Handling) で Design Review verdict が SPEC-UPDATE-NEEDED だった場合の処理が review.md に未定義。run.md には escalate 規定があるが、standalone review のパスは run.md を通らない。

**Recommendation**: review.md の Design Review セクション (L22-28) または Standalone Verdict Handling (L72-76) に「Design Review で SPEC-UPDATE-NEEDED verdict を受信した場合は escalate (この verdict は Design Auditor の定義外であり、受信した場合は Auditor の異常動作を示す)」の明記が望ましい。ただしこれは実運用でほぼ発生しないため、MEDIUM としている。

### [LOW] L1: Consensus mode 時の wave-scoped review における active ディレクトリ命名パターン

**Location**: `framework/claude/skills/sdd-roadmap/refs/review.md` L53 + Router Shared Protocols

**Description**: review.md Step 3 で `{scope-dir}/active/` (consensus: `{scope-dir}/active-{p}/`) と定義されている。Router の Consensus Mode プロトコルでも `reviews/active-{p}/` を使用。

wave-scoped review の scope-dir は `project/reviews/wave/` (review.md L53)。通常の wave QG (run.md Step 7a) では consensus mode は `run --consensus N` 経由でのみ発動するが、standalone で `review impl --wave N --consensus 3` を実行した場合、`project/reviews/wave/active-1/`, `project/reviews/wave/active-2/`, `project/reviews/wave/active-3/` が作成される。

この場合のアーカイブ先は `project/reviews/wave/B{seq}/pipeline-{p}/` になるはずだが、wave-scoped の verdicts.md header は `[W{wave}-B{seq}]` (run.md 定義) なのか通常の `[B{seq}]` (review.md 定義) なのかが standalone 実行パスでは曖昧。

**Recommendation**: 実運用上は Wave QG が run pipeline 内で実行されるため run.md の header format が使われる。Standalone wave review は稀なケースだが、review.md に wave-scoped verdicts.md の header format を明記するとより完全になる。

### [LOW] L2: review dead-code の phase gate スキップ記述の所在

**Location**: `framework/claude/skills/sdd-roadmap/refs/review.md` L20

**Description**: review.md Step 2 で "Dead Code Review: No phase gate (operates on entire codebase)" と明記されている。CLAUDE.md の Phase Gate セクション (L69-74) では「Before dispatching any SubAgent, Lead MUST verify spec.yaml.phase」とあるが、dead-code review はプロジェクトレベルの review であり個別 spec に紐づかないため、この phase gate 規定が適用されないことは文脈から推論できる。

ただし、CLAUDE.md の Phase Gate セクションには dead-code review が例外であることの明示的な言及がない。Router の Single-Spec Roadmap Ensure でも dead-code は enrollment check skip と書かれている (SKILL.md L71) が、Phase Gate セクションとの関連付けはない。

**Recommendation**: 軽微な明確化事項。CLAUDE.md Phase Gate セクションに「Note: dead-code review, cross-check, wave-scoped review はプロジェクトレベル操作のため個別 spec の phase gate は適用されない」を追記するとより明確になる。

---

## 未コミット変更の影響分析

### sdd-builder.md: SELF-CHECK ステップ追加

**変更内容**: Step 4 (VERIFY) と Step 6 (MARK COMPLETE) の間に Step 5 (SELF-CHECK) を挿入。5つの品質チェック (AC coverage, scope compliance, no TODOs, import resolution, design alignment)。Completion report に SelfCheck フィールド追加。

**フロー影響**:
- Builder の内部ステップ追加のみ。外部 API (completion report format) への変更は SelfCheck フィールドの追加。
- impl.md の Builder incremental processing が SelfCheck を処理するロジックを追加済み。
- run.md Phase Handlers の Impl completion は impl.md を参照しているため間接的に対応済み。
- CLAUDE.md への影響なし (SelfCheck は Builder 内部の品質ゲートであり、フレームワークレベルのプロトコルではない)。

**結論**: 整合している。M1 の曖昧性を除き、既存フローへの破壊的影響なし。

### sdd-taskgenerator.md: Steering context 参照追加

**変更内容**: Step 2 に "Apply steering context to detail bullets" を追加。tech.md Common Commands, structure.md Directory Patterns, custom steering の参照を detail bullets に埋め込む指示。

**フロー影響**:
- TaskGenerator の内部動作の改善。tasks.yaml の出力フォーマットは変更なし。
- tasks-generation.md に Steering Integration セクションが対応して追加済み。
- Builder への影響: detail bullets がより具体的になるため、Builder の解釈ドリフトが減少する (改善)。
- 外部フローへの影響なし。

**結論**: 整合している。フロー破壊なし。

### tasks-generation.md: "Avoid file paths" ルール緩和 + Steering Integration

**変更内容**: "File paths and directory structure" を避けるルールが "Inventing file paths" を避ける (structure.md 参照は許可) に緩和。Steering Integration セクション追加。

**フロー影響**:
- tasks-generation.md は TaskGenerator が読み込むルールファイル。TaskGenerator agent (sdd-taskgenerator.md) が Step 1 で読み込む。
- sdd-taskgenerator.md Step 2 の新規追加行と tasks-generation.md の Steering Integration セクションが整合。
- design-review.md への影響なし (review は design.md を対象とし、tasks.yaml は直接レビュー対象ではない)。

**結論**: 整合している。フロー破壊なし。

### impl.md: SelfCheck 処理ロジック追加

**変更内容**: Builder incremental processing に SelfCheck result の処理を追加 (PASS/WARN/FAIL-RETRY-2)。

**フロー影響**:
- sdd-builder.md の completion report 変更と対応。
- WARN の場合、Auditor dispatch 時に attention points として渡す -> review.md では Auditor の spawn context にこの情報を含める必要がある。review.md の Auditor spawn context (Step 6) には "Feature/scope context" とあり、attention points の明示的な記述はないが、Lead が context に含めれば問題ない。
- FAIL-RETRY-2 の re-dispatch パスは M1 で指摘した曖昧性がある。

**結論**: 概ね整合。M1 の曖昧性を除き問題なし。

---

## Inspector/Auditor 完全性チェック

### Design Review Pipeline

| Agent | ファイル | review.md での参照 | OK |
|---|---|---|---|
| sdd-inspector-rulebase | agents/sdd-inspector-rulebase.md | L25 | OK |
| sdd-inspector-testability | agents/sdd-inspector-testability.md | L25 | OK |
| sdd-inspector-architecture | agents/sdd-inspector-architecture.md | L25 | OK |
| sdd-inspector-consistency | agents/sdd-inspector-consistency.md | L25 | OK |
| sdd-inspector-best-practices | agents/sdd-inspector-best-practices.md | L25 | OK |
| sdd-inspector-holistic | agents/sdd-inspector-holistic.md | L25 | OK |
| sdd-auditor-design | agents/sdd-auditor-design.md | L26 | OK |

6 design inspectors + 1 auditor = CLAUDE.md L26 "6 design" と一致。

### Impl Review Pipeline

| Agent | ファイル | review.md での参照 | OK |
|---|---|---|---|
| sdd-inspector-impl-rulebase | agents/sdd-inspector-impl-rulebase.md | L33 | OK |
| sdd-inspector-interface | agents/sdd-inspector-interface.md | L33 | OK |
| sdd-inspector-test | agents/sdd-inspector-test.md | L33 | OK |
| sdd-inspector-quality | agents/sdd-inspector-quality.md | L33 | OK |
| sdd-inspector-impl-consistency | agents/sdd-inspector-impl-consistency.md | L33 | OK |
| sdd-inspector-impl-holistic | agents/sdd-inspector-impl-holistic.md | L33 | OK |
| sdd-inspector-e2e | agents/sdd-inspector-e2e.md | L34 (web projects only) | OK |
| sdd-auditor-impl | agents/sdd-auditor-impl.md | L35 | OK |

6 impl inspectors + 1 E2E (conditional) + 1 auditor = CLAUDE.md L26 "6 impl inspectors +1 E2E" と一致。
Auditor-impl の Input Handling (L46-49) で 7 Inspector CPF ファイル名が review.md の Inspector リストと一致。

### Dead-Code Review Pipeline

| Agent | ファイル | review.md での参照 | OK |
|---|---|---|---|
| sdd-inspector-dead-settings | agents/sdd-inspector-dead-settings.md | L44 | OK |
| sdd-inspector-dead-code | agents/sdd-inspector-dead-code.md | L44 | OK |
| sdd-inspector-dead-specs | agents/sdd-inspector-dead-specs.md | L44 | OK |
| sdd-inspector-dead-tests | agents/sdd-inspector-dead-tests.md | L44 | OK |
| sdd-auditor-dead-code | agents/sdd-auditor-dead-code.md | L45 | OK |

4 dead-code inspectors + 1 auditor = CLAUDE.md L26 "4 (dead-code)" と一致。

### Agent 定義ファイル数

agents/ 内の sdd-*.md: 23 ファイル。内訳:
- 1 architect
- 1 taskgenerator
- 1 builder
- 6 design inspectors
- 7 impl inspectors (6 standard + 1 e2e)
- 4 dead-code inspectors
- 3 auditors (design, impl, dead-code)

合計: 1+1+1+6+7+4+3 = 23。全て review.md/CLAUDE.md から参照されている。

---

## install.sh 整合性チェック

- Skills コピー: `install_dir "$SRC/framework/claude/skills" ".claude/skills"` -> framework/claude/skills/ 配下の全ファイル (7 skills) がコピーされる
- Agents コピー: `install_dir "$SRC/framework/claude/agents" ".claude/agents"` -> framework/claude/agents/ 配下の全ファイル (23 agents) がコピーされる
- CLAUDE.md: marker-based 管理、`{{SDD_VERSION}}` 置換
- Settings: rules, templates, profiles がコピーされる
- Stale file cleanup: skills (sdd-* scope), agents (sdd-*.md scope), rules, templates, profiles
- Migration パス: v0.4.0 (kiro), v0.7.0 (coordinator), v0.9.0 (handover), v0.10.0 (spec.yaml), v0.15.0 (commands->skills), v0.18.0/v0.20.0 (agents location)

install.sh と framework/ のディレクトリ構造は一致。refs/ は skills/ の subdirectory として自動的にコピーされる。
