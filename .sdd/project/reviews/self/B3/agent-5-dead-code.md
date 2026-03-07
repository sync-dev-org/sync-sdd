# Dead Code & Unused References Report

## 概要

SDD フレームワーク全体のデッドコード、孤立参照、冗長コンテンツの検出レポート。

**対象ファイル**: CLAUDE.md, SKILL.md (7), refs/*.md (6), agents/*.md (24), settings.json, rules/*.md (7), templates/**/*.md (18), install.sh

---

## 検出結果

### Issue 一覧

| # | 重大度 | カテゴリ | 場所 | 説明 |
|---|--------|---------|------|------|
| 1 | MEDIUM | skill-count-mismatch | `CLAUDE.md:141` | Commands (6) と記載されているが、実際のスキルは 7 個 (`sdd-review-self` が未掲載) |
| 2 | LOW | redundant-duplication | 複数ファイル | Wave-Scoped Cross-Check Mode セクションが 12 Inspector エージェントファイルで実質同一のテンプレートテキストとして重複 |
| 3 | LOW | unused-template-low-frequency | `templates/steering-custom/*.md` | steering-custom テンプレート 7 個中 `ui.md` のみ sdd-inspector-visual からも参照。残り 6 個は steering カスタム作成時のみ使用。未使用ではないが利用頻度は低い |

---

### 1. 未参照エージェント検出

#### エージェント参照マトリックス

| エージェント | 定義ファイル | ディスパッチ元 | 状態 |
|------------|------------|-------------|------|
| `sdd-architect` | agents/sdd-architect.md | refs/design.md, refs/run.md | OK |
| `sdd-auditor-design` | agents/sdd-auditor-design.md | refs/review.md | OK |
| `sdd-auditor-impl` | agents/sdd-auditor-impl.md | refs/review.md | OK |
| `sdd-auditor-dead-code` | agents/sdd-auditor-dead-code.md | refs/review.md | OK |
| `sdd-taskgenerator` | agents/sdd-taskgenerator.md | refs/impl.md | OK |
| `sdd-builder` | agents/sdd-builder.md | refs/impl.md, refs/run.md | OK |
| `sdd-inspector-rulebase` | agents/sdd-inspector-rulebase.md | refs/review.md | OK |
| `sdd-inspector-testability` | agents/sdd-inspector-testability.md | refs/review.md | OK |
| `sdd-inspector-architecture` | agents/sdd-inspector-architecture.md | refs/review.md | OK |
| `sdd-inspector-consistency` | agents/sdd-inspector-consistency.md | refs/review.md | OK |
| `sdd-inspector-best-practices` | agents/sdd-inspector-best-practices.md | refs/review.md | OK |
| `sdd-inspector-holistic` | agents/sdd-inspector-holistic.md | refs/review.md | OK |
| `sdd-inspector-impl-rulebase` | agents/sdd-inspector-impl-rulebase.md | refs/review.md | OK |
| `sdd-inspector-interface` | agents/sdd-inspector-interface.md | refs/review.md | OK |
| `sdd-inspector-test` | agents/sdd-inspector-test.md | refs/review.md | OK |
| `sdd-inspector-quality` | agents/sdd-inspector-quality.md | refs/review.md | OK |
| `sdd-inspector-impl-consistency` | agents/sdd-inspector-impl-consistency.md | refs/review.md | OK |
| `sdd-inspector-impl-holistic` | agents/sdd-inspector-impl-holistic.md | refs/review.md | OK |
| `sdd-inspector-e2e` | agents/sdd-inspector-e2e.md | refs/review.md | OK |
| `sdd-inspector-visual` | agents/sdd-inspector-visual.md | refs/review.md, sdd-auditor-impl | OK (NEW) |
| `sdd-inspector-dead-settings` | agents/sdd-inspector-dead-settings.md | refs/review.md | OK |
| `sdd-inspector-dead-code` | agents/sdd-inspector-dead-code.md | refs/review.md | OK |
| `sdd-inspector-dead-specs` | agents/sdd-inspector-dead-specs.md | refs/review.md | OK |
| `sdd-inspector-dead-tests` | agents/sdd-inspector-dead-tests.md | refs/review.md | OK |

**結果**: 全 24 エージェントが適切にディスパッチされている。未参照エージェントなし。

---

### 2. 未参照テンプレート/ルール検出

#### テンプレート参照マトリックス

| テンプレート | パス | 参照元 | 状態 |
|-----------|------|-------|------|
| `specs/init.yaml` | templates/specs/init.yaml | sdd-roadmap SKILL.md (Single-Spec Roadmap Ensure) | OK |
| `specs/design.md` | templates/specs/design.md | sdd-architect, sdd-inspector-rulebase | OK |
| `specs/research.md` | templates/specs/research.md | sdd-architect | OK |
| `steering/product.md` | templates/steering/product.md | sdd-steering SKILL.md | OK |
| `steering/tech.md` | templates/steering/tech.md | sdd-steering SKILL.md | OK |
| `steering/structure.md` | templates/steering/structure.md | sdd-steering SKILL.md | OK |
| `handover/session.md` | templates/handover/session.md | CLAUDE.md, sdd-handover SKILL.md | OK |
| `handover/buffer.md` | templates/handover/buffer.md | CLAUDE.md | OK |
| `knowledge/pattern.md` | templates/knowledge/pattern.md | sdd-knowledge SKILL.md | OK |
| `knowledge/incident.md` | templates/knowledge/incident.md | sdd-knowledge SKILL.md | OK |
| `knowledge/reference.md` | templates/knowledge/reference.md | sdd-knowledge SKILL.md | OK |
| `steering-custom/api-standards.md` | templates/steering-custom/ | sdd-steering SKILL.md (custom mode) | OK |
| `steering-custom/authentication.md` | templates/steering-custom/ | sdd-steering SKILL.md (custom mode) | OK |
| `steering-custom/database.md` | templates/steering-custom/ | sdd-steering SKILL.md (custom mode) | OK |
| `steering-custom/deployment.md` | templates/steering-custom/ | sdd-steering SKILL.md (custom mode) | OK |
| `steering-custom/error-handling.md` | templates/steering-custom/ | sdd-steering SKILL.md (custom mode) | OK |
| `steering-custom/security.md` | templates/steering-custom/ | sdd-steering SKILL.md (custom mode) | OK |
| `steering-custom/testing.md` | templates/steering-custom/ | sdd-steering SKILL.md (custom mode) | OK |
| `steering-custom/ui.md` | templates/steering-custom/ | sdd-steering SKILL.md, sdd-inspector-visual | OK |

#### ルール参照マトリックス

| ルール | パス | 参照元 | 状態 |
|-------|------|-------|------|
| `cpf-format.md` | rules/cpf-format.md | CLAUDE.md | OK |
| `design-principles.md` | rules/design-principles.md | sdd-architect | OK |
| `design-discovery-full.md` | rules/design-discovery-full.md | sdd-architect | OK |
| `design-discovery-light.md` | rules/design-discovery-light.md | sdd-architect | OK |
| `design-review.md` | rules/design-review.md | sdd-inspector-rulebase, sdd-inspector-testability | OK |
| `steering-principles.md` | rules/steering-principles.md | sdd-steering SKILL.md | OK |
| `tasks-generation.md` | rules/tasks-generation.md | sdd-taskgenerator | OK |

#### プロファイル参照マトリックス

| プロファイル | パス | 参照元 | 状態 |
|------------|------|-------|------|
| `_index.md` | profiles/_index.md | sdd-steering SKILL.md (exclude filter) | OK |
| `python.md` | profiles/python.md | sdd-steering SKILL.md (profile selection) | OK |
| `typescript.md` | profiles/typescript.md | sdd-steering SKILL.md (profile selection) | OK |
| `rust.md` | profiles/rust.md | sdd-steering SKILL.md (profile selection) | OK |

**結果**: 全テンプレート、ルール、プロファイルが参照されている。未参照ファイルなし。

---

### 3. スキル-CLAUDE.md 不整合検出

| CLAUDE.md Commands テーブル | SKILL.md 存在 | 状態 |
|---------------------------|--------------|------|
| `/sdd-steering` | sdd-steering/SKILL.md | OK |
| `/sdd-roadmap` | sdd-roadmap/SKILL.md | OK |
| `/sdd-status` | sdd-status/SKILL.md | OK |
| `/sdd-handover` | sdd-handover/SKILL.md | OK |
| `/sdd-knowledge` | sdd-knowledge/SKILL.md | OK |
| `/sdd-release` | sdd-release/SKILL.md | OK |
| (未掲載) | sdd-review-self/SKILL.md | **MISMATCH** |

**[MEDIUM] Issue #1**: `sdd-review-self` はスキルとして存在するが、CLAUDE.md の Commands (6) テーブルに掲載されていない。テーブルの数値も 6 のまま。

**判定**: これは意図的な可能性がある。`sdd-review-self` はフレームワーク内部開発用ツールであり、ユーザー向けコマンドではない (description: "framework-internal use only")。ただし CLAUDE.md ではスキル数のカウントが実態と乖離している。

**推奨**: Commands テーブルの注釈に「`/sdd-review-self` は開発専用 (内部ツール)」と追記するか、テーブルに含めて Commands (7) に更新するかを判断すべき。

---

### 4. 冗長コンテンツ検出

#### Wave-Scoped Cross-Check Mode テンプレートの重複

以下の 12 エージェント定義に、ほぼ同一の "Wave-Scoped Cross-Check Mode" セクションが重複している:

**Design Inspectors** (6):
- `sdd-inspector-rulebase.md`
- `sdd-inspector-testability.md`
- `sdd-inspector-architecture.md`
- `sdd-inspector-consistency.md`
- `sdd-inspector-best-practices.md`
- `sdd-inspector-holistic.md`

**Impl Inspectors** (6):
- `sdd-inspector-impl-rulebase.md`
- `sdd-inspector-interface.md`
- `sdd-inspector-test.md`
- `sdd-inspector-quality.md`
- `sdd-inspector-impl-consistency.md`
- `sdd-inspector-impl-holistic.md`

各セクションの内容は 5 ステップ構造（Resolve Wave Scope → Load Steering → Load Roadmap → Load Wave-Scoped Specs → Execute Wave-Scoped Cross-Check）で本質的に同一。

**判定**: [LOW] SubAgent はコンテキストを共有しないため、各エージェント定義に同一内容をインラインで持つ必要がある。これは SubAgent プラットフォーム制約による意図的な重複であり、デッドコードではない。ただし保守コストが高い（変更時に 12 ファイルを同時更新する必要がある）。

---

### 5. 到達不能コードパス検出

検出なし。

フェーズ遷移（`initialized` → `design-generated` → `implementation-complete`、`blocked`）は CLAUDE.md と各 refs で一貫しており、到達不能な分岐はない。

---

### 6. 削除/改名済みコンセプトの残骸検出

#### 確認対象: 最近の変更コンテキスト

| 削除/改名されたコンセプト | 検索結果 | 状態 |
|------------------------|---------|------|
| `e2e-visual-system` (旧 E2E カテゴリ) | framework/ 内にヒットなし | **CLEAN** |
| `e2e-visual-quality` (旧 E2E カテゴリ) | framework/ 内にヒットなし | **CLEAN** |
| `sdd-inspector-e2e` Phase B (旧) | 最新ファイルに Phase B なし | **CLEAN** |
| `visual-system`, `visual-quality`, `visual-a11y` (新カテゴリ) | `sdd-inspector-visual.md` のみで使用 | **CLEAN** |

#### 過去の削除済みコンセプト

| コンセプト | 検索結果 | 状態 |
|----------|---------|------|
| `sdd-coordinator` (v0.7.0 で削除) | framework/ 内にヒットなし | **CLEAN** |
| `sdd-planner` (v0.10.0 で削除) | framework/ 内にヒットなし | **CLEAN** |
| `conductor.md` (v0.9.0 で改名) | framework/ 内にヒットなし | **CLEAN** |
| `spec.json` (v0.10.0 で spec.yaml に移行) | framework/claude/ 内にヒットなし | **CLEAN** |
| `version_refs.tasks` (v0.10.0 で削除) | framework/ 内にヒットなし | **CLEAN** |
| `templates/specs/tasks.md` (v0.10.0 で削除) | framework/ 内にヒットなし | **CLEAN** |
| `templates/specs/init.json` (v0.10.0 で削除) | framework/ 内にヒットなし。init.yaml に移行済み | **CLEAN** |

**結果**: 削除済みコンセプトの残骸なし。install.sh のマイグレーションコードのみが旧コンセプト名を含むが、これはマイグレーション処理として正当。

---

### 7. TODO/FIXME/空セクション検出

| 場所 | 内容 | 状態 |
|------|------|------|
| `sdd-review-self/SKILL.md:224` | "TODO, FIXME, empty sections" | OK — 検出対象として言及しているだけ |
| `sdd-builder.md:60` | "`TODO`, `FIXME`, `HACK`" | OK — セルフチェック基準として言及しているだけ |

**結果**: フレームワークコード内に実際の TODO/FIXME/HACK コメントなし。

---

## Auditor のクロスドメイン分析

### sdd-auditor-impl の Inspector 数記述

`sdd-auditor-impl.md` line 12: "up to 8 independent review agents" と記述。

実際の Inspector 列挙 (lines 43-51):
1. `sdd-inspector-impl-rulebase.cpf`
2. `sdd-inspector-interface.cpf`
3. `sdd-inspector-test.cpf`
4. `sdd-inspector-quality.cpf`
5. `sdd-inspector-impl-consistency.cpf`
6. `sdd-inspector-impl-holistic.cpf`
7. `sdd-inspector-e2e.cpf` (web only)
8. `sdd-inspector-visual.cpf` (web only)

**判定**: "up to 8" は正確。6 基本 + 2 web = 最大 8。問題なし。

### CLAUDE.md Inspector カウント

`CLAUDE.md:26`: "6 design + 6 impl inspectors +2 web (web projects), 4 (dead-code)"

実際のカウント:
- Design Inspectors: rulebase, testability, architecture, consistency, best-practices, holistic = **6** (正確)
- Impl Inspectors: impl-rulebase, interface, test, quality, impl-consistency, impl-holistic = **6** (正確)
- Web Inspectors: e2e, visual = **2** (正確)
- Dead-code Inspectors: dead-settings, dead-code, dead-specs, dead-tests = **4** (正確)

**判定**: 全カウント正確。

---

## 総合評価

### 検出サマリー

| 重大度 | 件数 |
|--------|------|
| CRITICAL | 0 |
| HIGH | 0 |
| MEDIUM | 1 |
| LOW | 2 |

### 主要所見

1. **フレームワーク全体の参照整合性は良好**。全 24 エージェント、全テンプレート、全ルールファイルが適切に参照されている。
2. **削除済みコンセプトの残骸はゼロ**。install.sh マイグレーションコード内の旧名称参照は正当な用途。
3. **Issue #1 (MEDIUM)**: `sdd-review-self` スキルが CLAUDE.md Commands テーブルに未掲載。内部ツールとして意図的に除外している可能性が高いが、コマンド数カウント (6) が実態 (7 スキルファイル) と乖離している。
4. **Wave-Scoped Cross-Check Mode の 12 ファイル重複**は SubAgent プラットフォーム制約による意図的設計。保守コストは高いが、現在の SubAgent アーキテクチャでは避けられない。

### 推奨アクション

| 優先度 | 対象 | アクション |
|--------|------|----------|
| P2 | CLAUDE.md Commands テーブル | `sdd-review-self` の扱いを明確化 (注釈追加 or テーブル追加) |
