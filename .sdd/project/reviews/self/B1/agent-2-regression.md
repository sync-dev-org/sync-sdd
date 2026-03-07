# Regression Detection Report

## Issues Found

- [MEDIUM] run.md Dispatch Loop 内の非正規フェーズ名 / file: framework/claude/skills/sdd-roadmap/refs/run.md:65
- [LOW] CLAUDE.md の Parallel Execution Model 参照 "Step 3-4" はハイフン表記 / file: framework/claude/CLAUDE.md:96

### Confirmed OK

- CLAUDE.md -> refs/run.md の参照整合性: "see sdd-roadmap `refs/run.md`" で run.md の Step 3 (Schedule Specs) と Step 4 (Parallel Dispatch Loop) が存在
- CLAUDE.md -> refs/crud.md の参照整合性: "See sdd-roadmap `refs/crud.md`" で crud.md の Foundation-First / Parallelism report が存在
- CLAUDE.md -> refs/review.md の参照整合性: "see sdd-roadmap `refs/review.md`" で Steering Feedback Loop 処理ルールが存在
- Auto-Fix Counter Limits: CLAUDE.md と run.md で数値が一致 (retry_count: max 5, spec_update_count: max 2, aggregate cap: 6, dead-code: max 3)
- Verdict handling: run.md Phase Handlers の全 verdict (GO/CONDITIONAL/NO-GO/SPEC-UPDATE-NEEDED) が CLAUDE.md の定義と一致
- Blocking Protocol: run.md Step 6 が CLAUDE.md SubAgent Failure Handling と一致
- Wave Quality Gate: run.md Step 7 が cross-check / dead-code / post-gate の完全なフローを保持
- SubAgent limit 削除: CLAUDE.md から "24" が除去され "No framework-imposed SubAgent limit" に変更済み -- CLAUDE.md と run.md 間に矛盾なし
- Consensus Mode: Router (SKILL.md) の Shared Protocols -> Consensus Mode protocol が完全
- Verdict Persistence Format: Router に完全定義あり
- Template 参照整合性: CLAUDE.md が参照する全テンプレートが存在
  - `{{SDD_DIR}}/settings/templates/handover/session.md` -- 存在、内容一致
  - `{{SDD_DIR}}/settings/templates/handover/buffer.md` -- 存在、内容一致
  - `{{SDD_DIR}}/settings/templates/specs/init.yaml` -- SKILL.md から参照、存在
  - `{{SDD_DIR}}/settings/templates/specs/design.md` -- Architect から参照、存在
  - `{{SDD_DIR}}/settings/templates/specs/research.md` -- Architect から参照、存在
  - `{{SDD_DIR}}/settings/templates/steering/product.md` -- sdd-steering から参照、存在
  - `{{SDD_DIR}}/settings/templates/steering/tech.md` -- 存在
  - `{{SDD_DIR}}/settings/templates/steering/structure.md` -- 存在
  - `{{SDD_DIR}}/settings/templates/knowledge/{type}.md` -- sdd-knowledge から参照、pattern/incident/reference 全て存在
- Rules 参照整合性: 全ルールファイルが参照元から正しくリンク
  - `cpf-format.md` -- CLAUDE.md から参照
  - `steering-principles.md` -- sdd-steering から参照
  - `design-principles.md` -- sdd-architect から参照
  - `design-review.md` -- sdd-inspector-rulebase から参照
  - `design-discovery-full.md` -- sdd-architect から参照
  - `design-discovery-light.md` -- sdd-architect から参照
  - `tasks-generation.md` -- sdd-taskgenerator から参照
- Agent 定義整合性: 全 23 agent が `.claude/agents/` に存在し、CLAUDE.md/SKILL.md/refs から参照される agent 名と一致
- Skills 数: CLAUDE.md Commands (6) テーブルに `sdd-steering, sdd-roadmap, sdd-status, sdd-handover, sdd-knowledge, sdd-release` = 6 スキル。SKILL.md ファイルは 7 個 (sdd-review-self は内部ツールで Commands テーブルに含まれない) -- 正当
- install.sh: framework/ 配下の全ディレクトリを正しくインストール先にコピー
- Phase Gate: CLAUDE.md, design.md, impl.md の全てで一貫したフェーズチェック
- Handover: session.md auto-draft + manual polish の 2 モード、decisions.md append-only、buffer.md overwrite -- 全て CLAUDE.md 定義通り
- Knowledge Auto-Accumulation: Builder -> buffer.md -> knowledge/ のフローが CLAUDE.md / impl.md / sdd-knowledge で一貫
- Product Intent: CLAUDE.md の更新トリガーと Auditor の参照チェックが完備
- Steering Feedback Loop: review.md に CODIFY/PROPOSE の完全処理ルールあり
- Pipeline Stop Protocol: CLAUDE.md に定義、run.md の Step 1 (Load State) で再構築可能
- Git Workflow: CLAUDE.md の Commit Timing / Release Flow が sdd-release SKILL.md と一致

## Overall Assessment

フレームワーク全体の整合性は良好。run.md の大規模書き換えにより、以前の逐次的パイプライン記述 ("Design Phase" -> "Design Review Phase" -> "Implementation Phase" -> "Implementation Review Phase") が並列ディスパッチループ + フェーズハンドラ構造に再編されたが、プロトコル内容 (verdict handling, auto-fix loop, counter limits, blocking protocol, Wave QG) は全て保持されている。

---

## 詳細分析

### 1. ダングリング参照の検証

| 参照元 | 参照先 | 状態 |
|--------|--------|------|
| CLAUDE.md "see sdd-roadmap `refs/run.md`" | refs/run.md | OK -- Step 3-4 に詳細あり |
| CLAUDE.md "See sdd-roadmap `refs/crud.md`" | refs/crud.md | OK -- Foundation-First / Parallelism report あり |
| CLAUDE.md "see sdd-roadmap `refs/review.md`" | refs/review.md | OK -- Steering Feedback Loop 処理ルールあり |
| CLAUDE.md "Full auto-fix loop... see sdd-roadmap `refs/run.md`" | refs/run.md | OK -- Phase Handlers に auto-fix loop 詳細あり |
| CLAUDE.md "`{{SDD_DIR}}/settings/rules/cpf-format.md`" | rules/cpf-format.md | OK -- ファイル存在 |
| CLAUDE.md "`{{SDD_DIR}}/settings/templates/handover/session.md`" | templates/handover/session.md | OK |
| CLAUDE.md "`{{SDD_DIR}}/settings/templates/handover/buffer.md`" | templates/handover/buffer.md | OK |
| Router "Read `refs/design.md`" | refs/design.md | OK |
| Router "Read `refs/impl.md`" | refs/impl.md | OK |
| Router "Read `refs/review.md`" | refs/review.md | OK |
| Router "Read `refs/run.md`" | refs/run.md | OK |
| Router "Read `refs/revise.md`" | refs/revise.md | OK |
| Router "Read `refs/crud.md`" | refs/crud.md | OK |
| run.md "Execute per `refs/design.md`" | refs/design.md | OK |
| run.md "Execute per `refs/impl.md`" | refs/impl.md | OK |
| run.md "Execute per `refs/review.md`" | refs/review.md | OK |
| run.md "see Router" (Consensus Mode) | Router -> Shared Protocols | OK |
| run.md "see Router 1-Spec Roadmap Optimizations" | Router -> 1-Spec Roadmap Optimizations | OK |
| run.md "see CLAUDE.md Auto-Fix Counter Limits" | CLAUDE.md -> Auto-Fix Counter Limits | OK |
| Architect "`{{SDD_DIR}}/settings/templates/specs/design.md`" | templates/specs/design.md | OK |
| Architect "`{{SDD_DIR}}/settings/rules/design-principles.md`" | rules/design-principles.md | OK |
| Architect "`{{SDD_DIR}}/settings/rules/design-discovery-full.md`" | rules/design-discovery-full.md | OK |
| Architect "`{{SDD_DIR}}/settings/rules/design-discovery-light.md`" | rules/design-discovery-light.md | OK |
| Architect "`{{SDD_DIR}}/settings/templates/specs/research.md`" | templates/specs/research.md | OK |
| TaskGenerator "`{{SDD_DIR}}/settings/rules/tasks-generation.md`" | rules/tasks-generation.md | OK |
| Inspector-rulebase "`{{SDD_DIR}}/settings/rules/design-review.md`" | rules/design-review.md | OK |
| Inspector-rulebase "`{{SDD_DIR}}/settings/templates/specs/design.md`" | templates/specs/design.md | OK |
| sdd-steering "`{{SDD_DIR}}/settings/rules/steering-principles.md`" | rules/steering-principles.md | OK |
| sdd-steering "`{{SDD_DIR}}/settings/templates/steering/`" | templates/steering/ (product, tech, structure) | OK |
| sdd-steering "`{{SDD_DIR}}/settings/templates/steering-custom/`" | templates/steering-custom/ (8 files) | OK |
| sdd-steering "`{{SDD_DIR}}/settings/profiles/`" | profiles/ (3 profiles + _index) | OK |
| sdd-knowledge "`{{SDD_DIR}}/settings/templates/knowledge/{type}.md`" | templates/knowledge/ (pattern, incident, reference) | OK |
| Router "`{{SDD_DIR}}/settings/templates/specs/init.yaml`" | templates/specs/init.yaml | OK |

**結果**: ダングリング参照なし

### 2. Split Loss の検証 (run.md 書き換え)

#### 書き換え前 (HEAD) の run.md 内容

| 旧セクション | 内容 | 移行先 | 状態 |
|-------------|------|--------|------|
| Step 3: Schedule Specs (スペック並列判定、パイプライン状態追跡) | "Determine which specs can run in parallel", 個別パイプライン図 | Step 3: Island Spec Detection + Wave Spec Scheduling + Step 4: Dispatch Loop | OK -- 概念拡張、内容保持 |
| "Design Review and Impl Review are **mandatory**" | 必須ルール | Step 3 "Design Review and Impl Review are **mandatory** in roadmap run." | OK -- 同文保持 |
| Step 4: Design Phase | "Execute per `refs/design.md`" | Step 4 Phase Handlers -> Design completion | OK |
| Step 4: Design Review Phase (verdict handling) | GO/CONDITIONAL/NO-GO 処理、retry_count、STEERING entries、consensus | Step 4 Phase Handlers -> Design Review completion | OK -- 全 verdict ハンドリング保持 |
| Step 4: Implementation Phase | "Execute per `refs/impl.md`", Layer 2 file ownership | Step 4 Phase Handlers -> Implementation completion | OK |
| Step 4: Implementation Review Phase (verdict handling) | GO/CONDITIONAL/NO-GO/SPEC-UPDATE-NEEDED 処理、aggregate cap、STEERING entries | Step 4 Phase Handlers -> Impl Review completion | OK -- 全 verdict ハンドリング保持 |
| Step 5: Auto/Gate Mode Handling | Full-Auto / Gate mode の動作定義 | Step 5 (同番号) | OK -- 無変更 |
| Step 6: Blocking Protocol | 下流ブロック、fix/skip/abort | Step 6 (同番号) | OK -- 無変更 |
| Step 7: Wave Quality Gate | cross-check, dead-code, post-gate | Step 7 (同番号) | OK -- 無変更 |
| Step 8: Roadmap Completion | 完了レポート | Step 8 (同番号) | OK -- 無変更 |

**結果**: Split loss なし。全プロトコル内容が新構造に保持。

#### 新規追加コンテンツ (run.md)

| 新セクション | 内容 | 整合性チェック |
|-------------|------|---------------|
| Island Spec Detection (Wave Bypass) | 独立スペックの高速パイプライン | CLAUDE.md Parallel Execution Model に "Wave Bypass" として参照済み |
| Dispatch Loop (擬似コード) | ADVANCE/LOOKAHEAD/WAIT/PROCESS/EXIT | 新規 -- CLAUDE.md "Spec Stagger" と整合 |
| Readiness Rules | フェーズ別の進行条件テーブル | 新規 -- CLAUDE.md に概要あり |
| Design Fan-Out | 並列 Architect ディスパッチ | CLAUDE.md "Design Fan-Out" に参照済み |
| Design Lookahead | 次 wave の先行設計 | CLAUDE.md "Design Lookahead" に参照済み |

#### 新規追加コンテンツ (crud.md)

| 新セクション | 内容 | 整合性チェック |
|-------------|------|---------------|
| Foundation-First wave scheduling | Wave 1 基盤スペック優先配置 | CLAUDE.md "Wave Scheduling" に参照済み |
| Parallelism report | Wave 構成の可視化 | CLAUDE.md "Wave Scheduling" に参照済み |
| Backfill optimization (Update Mode) | Wave 統合最適化 | Router の Backfill check と整合 |

#### 新規追加コンテンツ (SKILL.md Router)

| 新セクション | 内容 | 整合性チェック |
|-------------|------|---------------|
| Backfill check (Single-Spec Roadmap Ensure) | 既存 wave への追加判定 | crud.md Backfill optimization と対応 |

#### 新規追加コンテンツ (CLAUDE.md)

| 新セクション | 内容 | 整合性チェック |
|-------------|------|---------------|
| Parallel Execution Model | 7 項目の並列化概要 | refs/run.md, refs/crud.md に詳細あり -- 全参照有効 |
| "No framework-imposed SubAgent limit" | 旧 "24" 上限の削除 | run.md にも上限記述なし -- 整合 |

### 3. プロトコル完全性の検証

| プロトコル | 定義場所 | 処理ルール場所 | 状態 |
|-----------|---------|---------------|------|
| Phase Gate | CLAUDE.md | design.md, impl.md | OK |
| Auto-Fix Counter Loop | CLAUDE.md | run.md Phase Handlers, revise.md Step 5 | OK |
| Verdict Handling (Design Review) | CLAUDE.md | run.md Design Review completion, review.md | OK |
| Verdict Handling (Impl Review) | CLAUDE.md | run.md Impl Review completion, review.md | OK |
| Verdict Persistence | Router Shared Protocols | review.md Step 8 | OK |
| Consensus Mode | Router Shared Protocols | review.md Step 3 (N sets) | OK |
| Blocking Protocol | CLAUDE.md | run.md Step 6 | OK |
| Wave Quality Gate | (implicit in run.md) | run.md Step 7 | OK |
| Steering Feedback Loop | CLAUDE.md | review.md Steering Feedback Loop Processing | OK |
| File-based Review | CLAUDE.md Chain of Command | review.md Review Execution Flow | OK |
| SubAgent Failure Handling | CLAUDE.md | (Lead judgment, retry same prompt) | OK |
| Pipeline Stop Protocol | CLAUDE.md | (session.md auto-draft) | OK |
| Session Resume | CLAUDE.md | (7 steps) | OK |
| Knowledge Auto-Accumulation | CLAUDE.md | impl.md Step 4, run.md Post-gate | OK |
| Product Intent Updates | CLAUDE.md | sdd-steering, crud.md Step 9 | OK |
| decisions.md Recording | CLAUDE.md | (7 decision types) | OK |
| Artifact Ownership | CLAUDE.md | (Lead read-only table) | OK |
| Change Request Triage | CLAUDE.md Behavioral Rules | (revision workflow routing) | OK |
| SPEC-Code Atomicity | CLAUDE.md | (design -> impl cascade) | OK |
| Revision Pipeline | (implicit) | revise.md Steps 1-7 | OK |
| Island Spec / Wave Bypass | CLAUDE.md Parallel Execution Model | run.md Step 3 | OK |
| Design Fan-Out | CLAUDE.md Parallel Execution Model | run.md Step 4 Readiness Rules | OK |
| Design Lookahead | CLAUDE.md Parallel Execution Model | run.md Step 4 | OK |
| Spec Stagger | CLAUDE.md Parallel Execution Model | run.md Step 4 Dispatch Loop | OK |

### 4. テンプレート整合性の検証

| CLAUDE.md 参照 | テンプレートパス | 内容一致 |
|----------------|-----------------|---------|
| session.md Format -> Template | `templates/handover/session.md` | OK |
| buffer.md Format -> Template | `templates/handover/buffer.md` | OK |
| decisions.md Format (inline) | (テンプレートなし、CLAUDE.md にフォーマット直接記載) | OK |
| init.yaml (spec template) | `templates/specs/init.yaml` | OK |
| design.md template | `templates/specs/design.md` | OK |
| research.md template | `templates/specs/research.md` | OK |
| steering templates | `templates/steering/` (product/tech/structure) | OK |
| knowledge templates | `templates/knowledge/` (pattern/incident/reference) | OK |

### 5. 最近の変更による回帰検証 (git diff)

#### (A) CLAUDE.md: Parallel Execution Model 追加 + SubAgent limit 削除

**変更内容**: 新セクション "Parallel Execution Model" (7 項目) 追加、"Concurrent SubAgent limit: 24" を "No framework-imposed SubAgent limit" に変更。

**検証**:
- 新セクションは refs/run.md Step 3-4 および refs/crud.md の内容を要約したもの -- refs 側に詳細が完備しており、要約と詳細の間に矛盾なし
- "24" の上限は他のどのファイルにも参照されていなかったため、削除による破損なし

**結果**: 回帰なし

#### (B) SKILL.md Router: Backfill check 追加

**変更内容**: Single-Spec Roadmap Ensure 内の auto-add to roadmap ロジックに Backfill check を追加。

**検証**:
- 既存フローの `max + 1` はデフォルトフォールバックとして保持
- spec.yaml スキーマは従来と同じ

**結果**: 回帰なし

#### (C) crud.md: Foundation-First + Parallelism report + Backfill optimization

**変更内容**: Create Mode Step 4 を拡張、Update Mode にステップ追加。

**検証**:
- 既存内容の削除なし、詳細追加のみ
- Update Mode のステップ番号シフト (4->5, 5->6) は他ファイルから参照されていない

**結果**: 回帰なし

#### (D) run.md: 大規模書き換え

**検証**: Split Loss テーブル参照。全 verdict handling、counter logic、phase transition が Phase Handlers に移行済み。

**結果**: 回帰なし

---

## 検出された Issues 詳細

### [MEDIUM] M1: run.md Dispatch Loop 内の非正規フェーズ名

**Location**: `framework/claude/skills/sdd-roadmap/refs/run.md:65`
**Description**: Dispatch Loop の擬似コードに `design-reviewed` と `impl-done` というフェーズ名が使用されている。

```
     - Determine next phase (initialized->Design, design-generated->Design Review,
       design-reviewed->Impl, impl-done->Impl Review)
```

CLAUDE.md が定義する正規フェーズは `initialized`, `design-generated`, `implementation-complete`, `blocked` の 4 つのみ。`design-reviewed` と `impl-done` は spec.yaml に記録されるフェーズ値ではなく、ディスパッチループ内部での「次のアクション決定」ロジックを表す暗黙的な状態遷移ラベル。

**Evidence**:
- CLAUDE.md Phase-Driven Workflow (line 153): "Phases: `initialized` -> `design-generated` -> `implementation-complete`"
- design.md Phase Gate (line 19): valid phases are `initialized`, `design-generated`, `implementation-complete`, `blocked`
- init.yaml: `phase: initialized`
- run.md Readiness Rules テーブル (line 86-90): 正規フェーズ名のみ使用

**Impact**: Lead がディスパッチループの擬似コードを文字通り解釈した場合、`design-reviewed` を spec.yaml に書き込もうとする可能性がある。Readiness Rules テーブルと Phase Handlers は正規フェーズ名を使用しているため、実処理への影響は限定的。

**Suggested Fix**: 擬似コードを正規フェーズ + 条件ベースに修正:
```
     - Determine next phase based on current state:
       initialized -> dispatch Design
       design-generated (pre-review) -> dispatch Design Review
       design-generated (review passed) -> dispatch Impl
       implementation-complete (pre-review) -> dispatch Impl Review
```

### [LOW] L1: CLAUDE.md "Step 3-4" のハイフン表記

**Location**: `framework/claude/CLAUDE.md:96`
**Description**: "See sdd-roadmap `refs/run.md` Step 3-4" -- "Steps 3 and 4" の意図だが非標準表記。意図は明確で実害なし。

---

## Split Traceability Table (全体)

### fe54f2e: CLAUDE.md -> Router + refs 分割

| 旧所在 (CLAUDE.md) | 新所在 | 保持状態 |
|---------------------|--------|---------|
| Roadmap subcommand routing | Router SKILL.md Step 1: Detect Mode | OK |
| Single-Spec Roadmap Ensure | Router SKILL.md | OK |
| 1-Spec Roadmap Optimizations | Router SKILL.md | OK |
| Design execution steps | refs/design.md Steps 1-4 | OK |
| Impl execution steps | refs/impl.md Steps 1-4 | OK |
| Review types + execution | refs/review.md | OK |
| Run mode orchestration | refs/run.md Steps 1-8 | OK |
| Revise mode | refs/revise.md Steps 1-7 | OK |
| Create/Update/Delete | refs/crud.md | OK |
| Consensus Mode protocol | Router Shared Protocols | OK |
| Verdict Persistence Format | Router Shared Protocols | OK |
| Error handling messages | Router Error Handling | OK |

### 3e653be: Review architecture redesign

| 旧所在 | 新所在 | 保持状態 |
|--------|--------|---------|
| Inspector role descriptions | Individual agent .md files (23 agents) | OK |
| Auditor synthesis process | Individual auditor .md files (3 auditors) | OK |
| Review Execution Flow | refs/review.md Review Execution Flow | OK |
| Steering Feedback Loop rules | refs/review.md Steering Feedback Loop Processing | OK |
| Verdict destination paths | refs/review.md Verdict Destination by Review Type | OK |

### 未コミット: run.md 並列化書き換え + CLAUDE.md Parallel Execution Model

| 旧所在 (run.md HEAD) | 新所在 (run.md working) | 保持状態 |
|----------------------|------------------------|---------|
| Step 3 parallel scheduling | Step 3 Island Detection + Wave Scheduling + Step 4 Dispatch Loop | OK (拡張) |
| Step 3 pipeline diagram | Step 4 Dispatch Loop pseudocode | OK (再構成) |
| Step 4 Design Phase | Phase Handlers -> Design completion | OK |
| Step 4 Design Review verdict | Phase Handlers -> Design Review completion | OK |
| Step 4 Implementation Phase | Phase Handlers -> Implementation completion | OK |
| Step 4 Impl Review verdict | Phase Handlers -> Impl Review completion | OK |
| (none) | Island Spec Detection (Wave Bypass) | NEW |
| (none) | Dispatch Loop (ADVANCE/LOOKAHEAD/WAIT/PROCESS/EXIT) | NEW |
| (none) | Readiness Rules table | NEW |
| (none) | Design Fan-Out | NEW |
| (none) | Design Lookahead + Staleness guard | NEW |
| (none -- CLAUDE.md) | Parallel Execution Model section | NEW |
| (none -- crud.md) | Foundation-First + Parallelism report | NEW |
| (none -- crud.md) | Backfill optimization | NEW |
| (none -- Router) | Backfill check | NEW |
