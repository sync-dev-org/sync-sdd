## Consistency & Dead Ends レビュー報告

### 概要
- **対象**: SDD フレームワーク全ファイル (CLAUDE.md, Skills, Agents, Rules, Templates, install.sh)
- **レビュー日時**: 2026-02-24
- **バージョン**: v1.0.4

---

### 検出された問題

---

#### [HIGH] H1: コマンド数カウントの不一致 — CLAUDE.md vs 実ファイル数

**場所**: `framework/claude/CLAUDE.md` 行140
**説明**: `### Commands (6)` と記載されているが、実際の Skills は **7個**。

| # | Skill | CLAUDE.md Commands テーブル |
|---|-------|-----------------------------|
| 1 | sdd-steering | 記載あり |
| 2 | sdd-roadmap | 記載あり |
| 3 | sdd-status | 記載あり |
| 4 | sdd-handover | 記載あり |
| 5 | sdd-knowledge | 記載あり |
| 6 | sdd-release | 記載あり |
| 7 | sdd-review-self | **テーブルに未記載** |

`sdd-review-self` は `framework/claude/skills/sdd-review-self/SKILL.md` に存在するが、CLAUDE.md の Commands テーブルに含まれていない。「Commands (6)」は「Commands (7)」であるべき、または `sdd-review-self` がフレームワーク内部専用ツールであり意図的にユーザー向けテーブルから除外されている場合はその旨を注記すべき。

**評価**: `sdd-review-self` の description に "framework-internal use only" とあるため、意図的な除外の可能性あり。ただし install.sh はこの Skill もインストールするため、ユーザーからは見える状態。review.md の Verdict Destination に `self-review` が記載されている（行128）ことからフレームワーク公式機能。カウント不一致は混乱を招く。

---

#### [HIGH] H2: `specs/.cross-cutting/{id}/` パス — Paths セクションに未記載

**場所**: `framework/claude/CLAUDE.md` Paths セクション (行110-119) / `framework/claude/skills/sdd-roadmap/refs/revise.md` Part B
**説明**: revise.md Part B は `specs/.cross-cutting/{id}/` というディレクトリパスを導入している（brief.md, verdicts.md の格納先）。しかし CLAUDE.md の Paths セクションにはこのパスの記載がない。

- revise.md 行161: `specs/.cross-cutting/{id}/brief.md`
- revise.md 行243: `specs/.cross-cutting/{id}/verdicts.md`
- revise.md 行250: `specs/.cross-cutting/{id}/` for reference

CLAUDE.md Paths セクションでは `Specs: {{SDD_DIR}}/project/specs/` のみ記載。`.cross-cutting` サブディレクトリの存在をどこにも定義していない。

また、install.sh の uninstall ロジック（行132-157）はこのディレクトリをクリーンアップ対象としていない（`specs/` は User Files として保護されるため問題にはならないが、ドキュメントとしての不整合）。

---

#### [HIGH] H3: CLAUDE.md の `See sdd-roadmap refs/run.md` 参照が Step 番号なし

**場所**: `framework/claude/CLAUDE.md` 行82, 行174
**説明**: CLAUDE.md の以下2箇所で `refs/run.md` を参照しているが、具体的な Step 番号が含まれていない:

- 行82: `Operational details (dispatch prompts, review protocol, incremental processing): see sdd-roadmap refs/run.md.`
- 行174: `Full auto-fix loop, wave quality gate, and blocking protocol details: see sdd-roadmap refs/run.md.`

一方、タスク指示で言及された「See sdd-roadmap refs/run.md Step 3-4」という表現は現在 CLAUDE.md には**存在しない**。CLAUDE.md Parallel Execution Model セクション (行84-95) には run.md の Step 3-4 の概要が直接記述されている。refs/run.md 参照は Step 番号なしでは到達すべき情報が不明確。

参考: run.md の構成:
- Step 1: Load State
- Step 2: Cross-Spec File Ownership Analysis
- Step 3: Schedule Specs (Island Spec Detection, Wave Spec Scheduling)
- Step 4: Parallel Dispatch Loop
- Step 5: Auto/Gate Mode Handling
- Step 6: Blocking Protocol
- Step 7: Wave Quality Gate
- Step 8: Roadmap Completion

**推奨**: 行82 は `see sdd-roadmap refs/run.md Step 3-4` に、行174 は `see sdd-roadmap refs/run.md Step 5-7` に修正。

---

#### [MEDIUM] M1: Cross-Cutting カウンタリミットの整合性

**場所**: `framework/claude/CLAUDE.md` 行170-174 / `framework/claude/skills/sdd-roadmap/refs/revise.md` Part B Step 7
**説明**: CLAUDE.md Auto-Fix Counter Limits セクションのカウンタリミット定義:

- `retry_count`: max 5 (NO-GO only)
- `spec_update_count`: max 2 (SPEC-UPDATE-NEEDED only)
- Aggregate cap: 6
- Dead-Code Review NO-GO: max 3

revise.md Part B Step 7 (行234):
> Auto-fix loop applies per spec (standard counter limits)

revise.md Part B Step 8 (行246):
> Max 5 retries (aggregate cap 6). On exhaustion: escalate to user

**整合性**: revise.md は CLAUDE.md のカウンタリミットを「standard counter limits」として参照し、具体的な数値を Step 8 で再掲。数値は一致している。**問題なし**。

ただし、CLAUDE.md のカウンタリセットトリガー (行173) に `/sdd-roadmap revise start` が含まれており、cross-cutting revision の各 tier checkpoint でもリセットされるべきかが不明。revise.md Part B Step 7 行208-209 でリセットが明記されているため動作上は問題ないが、CLAUDE.md のリセットトリガーリストに「tier completion (cross-cutting)」が含まれていない。

---

#### [MEDIUM] M2: CLAUDE.md Parallel Execution Model — "See sdd-roadmap refs/run.md Step 3-4" が不存在

**場所**: `framework/claude/CLAUDE.md` 行82-95
**説明**: 以前のバージョンで「See sdd-roadmap refs/run.md Step 3-4 for dispatch loop details」のような参照が存在していた可能性がある（タスク指示の special focus で言及）。現在の CLAUDE.md には Parallel Execution Model セクションが7つの bullet point でインライン記述されており、refs/run.md への Step 番号付き参照は**行82の一般的な参照のみ**。

Parallel Execution Model セクション末尾（行95）に新しく `Cross-Cutting Parallelism` 項目が追加され `See sdd-roadmap refs/revise.md Part B` と参照している。これは正しい。

**問題**: 行82 の `see sdd-roadmap refs/run.md` が具体的な Step を指さないため、Lead が「dispatch prompts, review protocol, incremental processing」の詳細をどの Step で見つけるべきか不明確。

---

#### [MEDIUM] M3: Revise Mode — Single-Spec Step 3 の Cross-Cutting エスカレーション先の表記不一致

**場所**: `framework/claude/skills/sdd-roadmap/refs/revise.md` 行47 vs 行95
**説明**:
- 行47: `join Part B Step 2 with revision intent and target spec pre-populated`
- 行95: `join Part B Step 2 with completed target spec + affected dependents pre-populated`

Step 3 (行43) では `2+ specs are affected (target + dependents)` で Part B への合流を提案。
Step 6 option (d) (行93-95) でも Part B への合流を提案。

Step 3 からの合流: `Part B Step 2 with revision intent and target spec pre-populated`
Step 6 からの合流: `Part B Step 2 with completed target spec + affected dependents pre-populated`

Part B Step 2 は Impact Analysis だが、Step 3 からの合流時にはまだ Impact Analysis が完了していない。Step 6 からは既に target spec の revision が完了している。動作的には正しいが、合流先が同じ `Step 2` でありながらコンテキストが大きく異なるため、合流後の処理フローが不明瞭。

---

#### [MEDIUM] M4: `design-review.md` の Severity Classification が CPF 仕様と完全一致しない

**場所**: `framework/claude/sdd/settings/rules/design-review.md` 行190-211 / `framework/claude/sdd/settings/rules/cpf-format.md`
**説明**: `design-review.md` は Severity Classification で:
- Critical (赤丸) → C or H
- Warning (黄丸) → M or L

CPF Format は:
- C=Critical, H=High, M=Medium, L=Low

design-review.md は独自の2段階(Critical/Warning)を CPF の4段階にマッピングしているが、このマッピングルールは design-review.md にのみ存在し、Inspector エージェントの Output Format セクションでは直接 C/H/M/L を使用している。Inspector は design-review.md を参照して review を実行するが、Output Format では直接 CPF severity を使う。二重のマッピングは混乱を招く可能性がある。

---

#### [MEDIUM] M5: `sdd-auditor-design` — 入力 Inspector 一覧がコメント形式で不整合

**場所**: `framework/claude/agents/sdd-auditor-design.md` 行42-47 / `framework/claude/skills/sdd-roadmap/refs/review.md` 行25-26
**説明**:
review.md は Design Inspector を以下のように列挙:
> `sdd-inspector-{rulebase,testability,architecture,consistency,best-practices,holistic}`

sdd-auditor-design.md は Input Handling で以下のファイル名を列挙:
1. `sdd-inspector-rulebase.cpf`
2. `sdd-inspector-testability.cpf`
3. `sdd-inspector-architecture.cpf`
4. `sdd-inspector-consistency.cpf`
5. `sdd-inspector-best-practices.cpf`
6. `sdd-inspector-holistic.cpf`

これらは一致している。**問題なし**。

---

#### [MEDIUM] M6: `sdd-auditor-impl` — "up to 8 independent review agents" vs 実際の数

**場所**: `framework/claude/agents/sdd-auditor-impl.md` 行12
**説明**: `Cross-check, verify, and integrate findings from up to 8 independent review agents` とあるが、実際には:
- 6 standard impl inspectors
- 2 web inspectors (e2e, visual) — web projects only

最大で 8 は正しい。ただし CLAUDE.md (行26) は `6 impl +2 web (impl only, web projects)` と記述。**整合性あり — 問題なし**。

---

#### [LOW] L1: Verdict Persistence Format — Disposition 値の定義箇所

**場所**: `framework/claude/skills/sdd-roadmap/SKILL.md` 行135
**説明**: Disposition 値として以下が列挙されている:
> `GO-ACCEPTED`, `CONDITIONAL-TRACKED`, `NO-GO-FIXED`, `SPEC-UPDATE-CASCADED`, `ESCALATED`

これらの値がフレームワーク内で他の場所で参照・使用されることはなく、定義はこの1箇所のみ。Auditor や Inspector はこれらの値を出力しない（Auditor の出力は `VERDICT:GO|CONDITIONAL|NO-GO|SPEC-UPDATE-NEEDED`）。Disposition は Lead が verdict 処理後に追記するメタデータだが、その処理ルールが refs ファイルに分散しており、Disposition の選択ロジックが明示的でない。

---

#### [LOW] L2: review.md — Verdict Destination テーブル内の `self-review` パス

**場所**: `framework/claude/skills/sdd-roadmap/refs/review.md` 行128
**説明**:
> `**Self-review** (framework-internal): {{SDD_DIR}}/project/reviews/self/verdicts.md`

このパスは `sdd-review-self/SKILL.md` の `$SCOPE_DIR` = `{{SDD_DIR}}/project/reviews/self/` と一致している。**問題なし**。ただし、`sdd-review-self` は review subcommand (`/sdd-roadmap review`) からは呼び出されず、独立した skill として存在するため、review.md の Verdict Destination テーブルに含めるのは少し紛らわしい。

---

#### [LOW] L3: install.sh の v0.18.0 マイグレーション — agents 移動先と v0.20.0 の戻し

**場所**: `install.sh` 行354-377
**説明**:
- v0.18.0 マイグレーション (行354-364): `.claude/agents/sdd-*.md` を削除（`.claude/sdd/settings/agents/` への移行を想定）
- v0.20.0 マイグレーション (行365-377): `.claude/sdd/settings/agents/sdd-*.md` を `.claude/agents/` に移動

v0.18.0 でエージェントを `.claude/agents/` から削除し、v0.20.0 で `.claude/sdd/settings/agents/` から `.claude/agents/` に戻す。この一連の流れ自体は論理的に正しいが、v0.18.0 マイグレーションではソースの `.claude/sdd/settings/agents/` へのコピーは行わない（インストールスクリプトの後続処理が担当）。`install_dir` は v0.18.0 時点では `.claude/sdd/settings/agents/` にインストールしていたと推定されるが、その install ロジックは現在のコードには存在しない（現在は行487: `install_dir "$SRC/framework/claude/agents" ".claude/agents"`）。バージョン間の install ロジック変更を前提としたマイグレーション設計。

**問題なし** — ただし v0.18.0 未満から v1.0.4 に直接アップデートした場合、v0.18.0 マイグレーションがエージェントを削除し、v0.20.0 マイグレーションが空ディレクトリからの移動を試み(効果なし)、最終的に `install_dir` で再インストールされる。正しく動作するが冗長。

---

#### [LOW] L4: CLAUDE.md の Phase 列挙の完全性

**場所**: `framework/claude/CLAUDE.md` 行152 / `framework/claude/skills/sdd-roadmap/refs/design.md` 行19
**説明**: CLAUDE.md Phase-Driven Workflow:
> Phases: `initialized` -> `design-generated` -> `implementation-complete` (also: `blocked`)

design.md Step 2 Phase Gate:
> If `spec.yaml.phase` is not one of `initialized`, `design-generated`, `implementation-complete`, `blocked`: BLOCK

init.yaml テンプレート:
> `phase: initialized`

spec.yaml のフェーズとして認識されるのは4種: `initialized`, `design-generated`, `implementation-complete`, `blocked`。

run.md では `orchestration.last_phase_action` として以下の値を使用:
- `null` (初期/リセット後)
- `"tasks-generated"` (impl.md 行20)
- `"impl-complete"` (impl.md 行64)

これらは `phase` とは別のフィールドで管理されているため矛盾はない。**問題なし**。

---

#### [LOW] L5: `sdd-review-self` のエージェント dispatch 方式の不一致

**場所**: `framework/claude/skills/sdd-review-self/SKILL.md` 行65-66
**説明**:
> Launch review agents via `Task(subagent_type="general-purpose")`.

一方、CLAUDE.md の Chain of Command (行30):
> Lead dispatches T2/T3 SubAgents using `Task` tool with `subagent_type` parameter (e.g., `Task(subagent_type="sdd-architect", prompt="...")`).

`sdd-review-self` は `subagent_type="general-purpose"` を使用しており、SDD 定義のエージェント（`sdd-*`）を使用していない。これはフレームワーク自体のレビューツールであるため、プロジェクトの SDD エージェントではなく汎用エージェントを使うのは妥当。しかし、CLAUDE.md の SubAgent 説明とは一貫していない。

---

### 確認済み (問題なし)

| チェック項目 | 結果 |
|-------------|------|
| Phase 名の一貫性 (initialized, design-generated, implementation-complete, blocked) | OK |
| Verdict 値の一貫性 (GO, CONDITIONAL, NO-GO, SPEC-UPDATE-NEEDED) | OK |
| Severity コードの一貫性 (C/H/M/L) | OK |
| SubAgent 名の一貫性 (Architect, Auditor, TaskGenerator, Builder, Inspector) | OK |
| 3-Tier Hierarchy の一貫性 | OK |
| CPF フォーマットの一貫性 | OK |
| Knowledge タグの一貫性 ([PATTERN], [INCIDENT], [REFERENCE]) | OK |
| Decision type の一貫性 (USER_DECISION, STEERING_UPDATE, etc.) | OK |
| Builder SelfCheck 値の一貫性 (PASS, WARN, FAIL-RETRY-2) | OK |
| 6 design Inspectors の名前一致 | OK |
| 6 impl Inspectors の名前一致 | OK |
| 4 dead-code Inspectors の名前一致 | OK |
| 2 web Inspectors の名前一致 (e2e, visual) | OK |
| 3 Auditor の名前一致 (design, impl, dead-code) | OK |
| Auto-fix counter limits (retry:5, spec-update:2, aggregate:6, dead-code:3) | OK — run.md, review.md, revise.md 全て一致 |
| Steering Feedback Loop (CODIFY/PROPOSE) | OK — CLAUDE.md, review.md, auditor-design.md, auditor-impl.md 全て一致 |
| Consensus Mode protocol | OK — SKILL.md と review.md で一致 |
| spec.yaml フィールド名 | OK — init.yaml テンプレート、CLAUDE.md、各 refs で一致 |
| `{{SDD_DIR}}` テンプレート変数の展開 | OK — 全ファイルで `.claude/sdd` を前提 |
| CLAUDE.md FULL/AUDIT/SKIP 用語 — revise.md Part B で定義・使用 | OK |
| Cross-cutting brief — revise.md Part B で完結した定義 | OK |
| Tier 概念 — revise.md Part B で定義、CLAUDE.md Parallel Execution Model で参照 | OK |
| install.sh のインストール先パス | OK — framework/ → .claude/ マッピング正しい |
| Templates が参照元から正しく参照されている | OK |
| Rules が参照元 (Architect, Inspector) から正しく参照されている | OK |

---

### クロスリファレンスマトリクス

#### CLAUDE.md → refs ファイル参照

| CLAUDE.md セクション | 参照先 | 参照内容 | 存在確認 |
|---------------------|--------|---------|---------|
| SubAgent Lifecycle (行82) | refs/run.md | dispatch prompts, review protocol, incremental processing | OK (ただし Step 番号なし) |
| Parallel Execution - Wave Scheduling (行88) | refs/crud.md | Foundation-First, wave assignment | OK |
| Parallel Execution - Cross-Cutting (行95) | refs/revise.md Part B | Tier-based parallel revision | OK |
| Auto-Fix Counter Limits (行174) | refs/run.md | auto-fix loop, wave QG, blocking | OK (ただし Step 番号なし) |
| Steering Feedback Loop (行204) | refs/review.md | processing rules | OK |
| Phase-Driven Workflow (行152-154) | -- | inline 定義 | OK |
| Handover session.md format (行238) | templates/handover/session.md | テンプレート | OK |
| Handover buffer.md format (行248) | templates/handover/buffer.md | テンプレート | OK |
| CPF format (行330) | rules/cpf-format.md | フォーマット仕様 | OK |

#### refs ファイル間の相互参照

| 参照元 | 参照先 | 内容 | 存在確認 |
|--------|--------|------|---------|
| SKILL.md (router) | refs/design.md | Design execution | OK |
| SKILL.md (router) | refs/impl.md | Impl execution | OK |
| SKILL.md (router) | refs/review.md | Review execution | OK |
| SKILL.md (router) | refs/run.md | Run orchestration | OK |
| SKILL.md (router) | refs/revise.md | Revise orchestration | OK |
| SKILL.md (router) | refs/crud.md | Create/Update/Delete | OK |
| refs/run.md Step 3 | refs/design.md Steps 1-3 | Design completion handler | OK |
| refs/run.md Step 3 | refs/review.md | Design Review | OK |
| refs/run.md Step 3 | refs/impl.md Steps 1-3 | Implementation | OK |
| refs/run.md Step 3 | refs/review.md | Impl Review | OK |
| refs/revise.md Part A Step 5 | refs/design.md | Design with revision context | OK |
| refs/revise.md Part A Step 5 | refs/review.md | Design Review | OK |
| refs/revise.md Part A Step 5 | refs/impl.md | Implementation | OK |
| refs/revise.md Part A Step 5 | refs/review.md | Impl Review | OK |
| refs/revise.md Part B Step 3 | refs/crud.md | Create/Update logic | OK |
| refs/revise.md Part B Step 7 | refs/run.md | Dispatch Loop pattern | OK |
| refs/revise.md Part B Step 8 | refs/run.md Step 7a | Cross-check mechanism | OK |
| refs/review.md | CLAUDE.md Auto-Fix | counter limits ref | OK (implicit) |

#### Agent → Rule/Template 参照

| Agent | 参照先ルール | 参照先テンプレート | 存在確認 |
|-------|-------------|------------------|---------|
| sdd-architect | rules/design-principles.md | templates/specs/design.md, research.md | OK |
| sdd-architect | rules/design-discovery-full.md | -- | OK |
| sdd-architect | rules/design-discovery-light.md | -- | OK |
| sdd-inspector-rulebase | rules/design-review.md | templates/specs/design.md | OK |
| sdd-inspector-testability | rules/design-review.md (optional) | -- | OK |
| sdd-taskgenerator | rules/tasks-generation.md | -- | OK |
| sdd-builder | steering/ (tech.md Common Commands) | -- | OK (runtime) |

#### 循環参照チェック

参照グラフ: CLAUDE.md → SKILL.md → refs → agents (各 agent は自身のルール/テンプレートのみ参照)

循環参照: **検出なし**。全ての参照は DAG 構造。

---

### 総合評価

**全体的な整合性: 良好**

重大な矛盾や到達不能パスは検出されなかった。検出された問題の大半はドキュメント上の軽微な不整合であり、実行時の動作を阻害するものではない。

**対応推奨優先度**:

| 優先度 | ID | 概要 | 対象ファイル |
|-------|-----|------|------------|
| HIGH | H1 | Commands カウント不一致 (6 vs 7) | CLAUDE.md |
| HIGH | H2 | `.cross-cutting/` パスの Paths セクション欠落 | CLAUDE.md |
| HIGH | H3 | refs/run.md 参照の Step 番号欠如 | CLAUDE.md |
| MEDIUM | M1 | Cross-cutting カウンタリセットトリガー欠落 | CLAUDE.md |
| MEDIUM | M2 | Parallel Execution Model の参照精度 | CLAUDE.md |
| MEDIUM | M3 | Revise Single->Cross-Cutting 合流先の曖昧さ | revise.md |
| MEDIUM | M4 | design-review.md Severity mapping の二重性 | design-review.md |
| LOW | L1-L5 | 各種軽微な不整合 | 各所 |
