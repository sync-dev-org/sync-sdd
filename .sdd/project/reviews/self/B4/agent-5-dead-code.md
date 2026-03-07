# Dead Code & Unused References Report

**Date**: 2026-02-24
**Scope**: framework全体 (CLAUDE.md, skills, agents, rules, templates, install.sh)
**変更コンテキスト**: revise.md の全面書き換え (Part A + Part B)、CLAUDE.md の Cross-Cutting Parallelism 追加

---

## Issues Found

### [MEDIUM] M1: CLAUDE.md decisions.md Format セクションに `(cross-cutting)` 注記の欠落

**Location**: `framework/claude/CLAUDE.md:244`
**Description**: decisions.md Recording セクション (L183) では `REVISION_INITIATED` に `(append (cross-cutting) for multi-spec revisions)` が追加されたが、decisions.md Format セクション (L244) の記述は旧来のまま `(user-initiated past-wave spec revision)` のみ。同一ファイル内で定義が不一致。

```
L183: - `REVISION_INITIATED`: user-initiated past-wave spec revision (append `(cross-cutting)` for multi-spec revisions)
L244: Decision types: ... `REVISION_INITIATED` (user-initiated past-wave spec revision), ...
```

**分類**: 未完了変更の残骸 (Remnant of incomplete change propagation)

---

### [LOW] L1: `sdd-review-self` スキルが CLAUDE.md Commands テーブルに未記載

**Location**: `framework/claude/CLAUDE.md:140-149` vs `framework/claude/skills/sdd-review-self/SKILL.md`
**Description**: `sdd-review-self` は `framework/claude/skills/sdd-review-self/SKILL.md` として存在するが、CLAUDE.md の `### Commands (6)` テーブルには含まれていない。カウントも6のまま。

**判定**: これは意図的な可能性が高い。`sdd-review-self` は "framework-internal use only" と記述されており (SKILL.md L2)、フレームワーク開発者向けツールであるため、ユーザー向けの Commands テーブルに含めない設計判断と推定。ただし、`review.md` L128 で verdict destination に `Self-review (framework-internal)` が記載されており、フレームワーク内で参照はされている。

**推奨**: 問題なし (意図的設計)。ドキュメント上の注記追加は任意。

---

## Confirmed OK

### Agent Reference Matrix

全24エージェントが定義され、各エージェントのディスパッチ元を確認:

| Agent | 定義ファイル | ディスパッチ元 | 状態 |
|-------|-----------|-------------|------|
| `sdd-architect` | agents/sdd-architect.md | design.md L24, run.md L90 | OK |
| `sdd-taskgenerator` | agents/sdd-taskgenerator.md | impl.md L26 | OK |
| `sdd-builder` | agents/sdd-builder.md | impl.md L39 | OK |
| `sdd-auditor-design` | agents/sdd-auditor-design.md | review.md L26 | OK |
| `sdd-auditor-impl` | agents/sdd-auditor-impl.md | review.md L35 | OK |
| `sdd-auditor-dead-code` | agents/sdd-auditor-dead-code.md | review.md L45 | OK |
| `sdd-inspector-rulebase` | agents/sdd-inspector-rulebase.md | review.md L25 | OK |
| `sdd-inspector-testability` | agents/sdd-inspector-testability.md | review.md L25 | OK |
| `sdd-inspector-architecture` | agents/sdd-inspector-architecture.md | review.md L25 | OK |
| `sdd-inspector-consistency` | agents/sdd-inspector-consistency.md | review.md L25 | OK |
| `sdd-inspector-best-practices` | agents/sdd-inspector-best-practices.md | review.md L25 | OK |
| `sdd-inspector-holistic` | agents/sdd-inspector-holistic.md | review.md L25 | OK |
| `sdd-inspector-impl-rulebase` | agents/sdd-inspector-impl-rulebase.md | review.md L33 | OK |
| `sdd-inspector-interface` | agents/sdd-inspector-interface.md | review.md L33 | OK |
| `sdd-inspector-test` | agents/sdd-inspector-test.md | review.md L33 | OK |
| `sdd-inspector-quality` | agents/sdd-inspector-quality.md | review.md L33 | OK |
| `sdd-inspector-impl-consistency` | agents/sdd-inspector-impl-consistency.md | review.md L33 | OK |
| `sdd-inspector-impl-holistic` | agents/sdd-inspector-impl-holistic.md | review.md L33 | OK |
| `sdd-inspector-e2e` | agents/sdd-inspector-e2e.md | review.md L34 | OK |
| `sdd-inspector-visual` | agents/sdd-inspector-visual.md | review.md L34 | OK |
| `sdd-inspector-dead-settings` | agents/sdd-inspector-dead-settings.md | review.md L44 | OK |
| `sdd-inspector-dead-code` | agents/sdd-inspector-dead-code.md | review.md L44 | OK |
| `sdd-inspector-dead-specs` | agents/sdd-inspector-dead-specs.md | review.md L44 | OK |
| `sdd-inspector-dead-tests` | agents/sdd-inspector-dead-tests.md | review.md L44 | OK |

**結果**: 未参照エージェントなし。全24エージェントが review.md (または design.md / impl.md / run.md) から正しくディスパッチされている。

---

### Template Reference Matrix

| Template / Rule | パス | 参照元 | 状態 |
|----------------|------|--------|------|
| `specs/init.yaml` | templates/specs/init.yaml | sdd-roadmap SKILL.md L76 | OK |
| `specs/design.md` | templates/specs/design.md | sdd-architect L28, sdd-inspector-rulebase L37,L121 | OK |
| `specs/research.md` | templates/specs/research.md | sdd-architect L30 | OK |
| `steering/product.md` | templates/steering/product.md | sdd-steering SKILL.md L48 | OK |
| `steering/tech.md` | templates/steering/tech.md | sdd-steering SKILL.md L48 | OK |
| `steering/structure.md` | templates/steering/structure.md | sdd-steering SKILL.md L48 | OK |
| `steering-custom/api-standards.md` | templates/steering-custom/api-standards.md | sdd-steering SKILL.md L69 | OK |
| `steering-custom/authentication.md` | templates/steering-custom/authentication.md | sdd-steering SKILL.md L69 | OK |
| `steering-custom/database.md` | templates/steering-custom/database.md | sdd-steering SKILL.md L69 | OK |
| `steering-custom/deployment.md` | templates/steering-custom/deployment.md | sdd-steering SKILL.md L69 | OK |
| `steering-custom/error-handling.md` | templates/steering-custom/error-handling.md | sdd-steering SKILL.md L69 | OK |
| `steering-custom/security.md` | templates/steering-custom/security.md | sdd-steering SKILL.md L69 | OK |
| `steering-custom/testing.md` | templates/steering-custom/testing.md | sdd-steering SKILL.md L69 | OK |
| `steering-custom/ui.md` | templates/steering-custom/ui.md | sdd-steering SKILL.md L69, sdd-inspector-visual | OK |
| `handover/session.md` | templates/handover/session.md | CLAUDE.md L238, sdd-handover SKILL.md L36 | OK |
| `handover/buffer.md` | templates/handover/buffer.md | CLAUDE.md L248 | OK |
| `knowledge/incident.md` | templates/knowledge/incident.md | sdd-knowledge SKILL.md L43 | OK |
| `knowledge/pattern.md` | templates/knowledge/pattern.md | sdd-knowledge SKILL.md L43 | OK |
| `knowledge/reference.md` | templates/knowledge/reference.md | sdd-knowledge SKILL.md L43 | OK |
| `rules/cpf-format.md` | rules/cpf-format.md | CLAUDE.md L330 | OK |
| `rules/design-principles.md` | rules/design-principles.md | sdd-architect L29 | OK |
| `rules/design-discovery-full.md` | rules/design-discovery-full.md | sdd-architect L47 | OK |
| `rules/design-discovery-light.md` | rules/design-discovery-light.md | sdd-architect L55 | OK |
| `rules/design-review.md` | rules/design-review.md | sdd-inspector-rulebase L38,L122, sdd-inspector-testability L42 | OK |
| `rules/tasks-generation.md` | rules/tasks-generation.md | sdd-taskgenerator L31 | OK |
| `rules/steering-principles.md` | rules/steering-principles.md | sdd-steering SKILL.md L15 | OK |
| `profiles/python.md` | profiles/python.md | sdd-steering SKILL.md L37 (dynamic) | OK |
| `profiles/typescript.md` | profiles/typescript.md | sdd-steering SKILL.md L37 (dynamic) | OK |
| `profiles/rust.md` | profiles/rust.md | sdd-steering SKILL.md L37 (dynamic) | OK |
| `profiles/_index.md` | profiles/_index.md | sdd-steering SKILL.md L37 (exclude) | OK |

**結果**: 未参照テンプレート/ルールなし。全ファイルが少なくとも1箇所から参照されている。

---

### Skills vs CLAUDE.md Commands テーブル整合

| Skill | SKILL.md 存在 | Commands テーブル | 状態 |
|-------|-------------|-----------------|------|
| `sdd-steering` | OK | OK | OK |
| `sdd-roadmap` | OK | OK | OK |
| `sdd-status` | OK | OK | OK |
| `sdd-handover` | OK | OK | OK |
| `sdd-knowledge` | OK | OK | OK |
| `sdd-release` | OK | OK | OK |
| `sdd-review-self` | OK | 未記載 (意図的) | OK (L1参照) |

**結果**: テーブル記載は6件、SKILL.md は7件。差分は `sdd-review-self` (framework-internal use only)。意図的設計。

---

### 旧コンセプト残骸チェック

| 旧コンセプト | 削除バージョン | framework/claude 内残骸 | install.sh 内残骸 | 状態 |
|------------|-------------|----------------------|-----------------|------|
| coordinator | v0.7.0 | なし | 移行スクリプトのみ (正常) | OK |
| conductor | v0.9.0 | なし | 移行スクリプトのみ (正常) | OK |
| planner | v0.10.0 | なし | 移行スクリプトのみ (正常) | OK |
| spec.json | v0.10.0 | なし | 移行スクリプトのみ (正常) | OK |
| state.md / log.md | v0.9.0 | なし | 移行スクリプトのみ (正常) | OK |
| commands/ | v0.15.0 | なし | 移行スクリプト+uninstall (正常) | OK |
| sdd/settings/agents/ | v0.18.0→v0.20.0 | なし | 移行スクリプトのみ (正常) | OK |

**結果**: 全旧コンセプトの残骸はクリーン。install.sh の移行スクリプト内参照は後方互換に必要な正常コード。

---

### 直近変更コンテキスト: revise.md 書き換えの検証

| チェック項目 | 状態 | 詳細 |
|-----------|------|------|
| 旧7-step 構造の残骸 | なし | Part A (Step 1-7) + Part B (Step 1-9) に完全置換 |
| sdd-roadmap SKILL.md ルーター対応 | OK | L34-35 で Single-Spec / Cross-Cutting 両モード記載 |
| CLAUDE.md 参照更新 | OK | L95 で `refs/revise.md Part B` 参照追加 |
| CLAUDE.md の `REVISION_INITIATED` | 部分的 | L183 は更新済、L244 は未更新 (M1) |
| CLAUDE.md の commit message format | OK | L320 に `cross-cutting: {summary}` 追加済 |
| design.md の cross-cutting brief 参照 | OK | L29 に brief path 対応記載 |
| run.md への影響 | なし | revise は独立フロー、run.md は変更不要 |

---

### 直近変更コンテキスト: CLAUDE.md "Step 3-4" 参照削除の検証

| チェック項目 | 状態 | 詳細 |
|-----------|------|------|
| `Step 3-4` 参照の残骸 | なし | framework/claude 全体で検索済、ヒットなし |
| 代替の Cross-Cutting Parallelism | OK | L95 に追加済 |
| 他ファイルからの `Step 3-4` 参照 | なし | refs/run.md 含め全ファイルで不使用 |

---

### その他のチェック

| チェック項目 | 状態 |
|-----------|------|
| TODO / FIXME / HACK マーカー | なし (参照のみ: builder self-check, review-self 定義) |
| 空セクション | なし |
| 到達不能コードパス | なし |
| 重複コンテンツ (同一内容の冗長複製) | decisions.md Recording/Format は同概念を2箇所に記載するが、用途が異なる (行動ルール vs フォーマット定義) ため冗長ではない |
| Inspector 数の整合 | OK (design: 6, impl: 6+2web, dead-code: 4 = CLAUDE.md L26 と review.md 一致) |
| Agent 総数 | OK (24 files = 24 definitions) |
| settings.json | OK (最小構成、問題なし) |

---

## Overall Assessment

フレームワークのデッドコード状態は極めてクリーン。

**検出された問題**: 1件 (MEDIUM)
- M1: CLAUDE.md 内の `REVISION_INITIATED` 記述不一致 (decisions.md Format セクションに `(cross-cutting)` 注記の伝播漏れ)

**意図的な設計**: 1件 (LOW, 情報提供)
- L1: `sdd-review-self` の Commands テーブル非記載は framework-internal 設計として妥当

**確認済み OK 項目**:
- 全24エージェントがディスパッチ元を持つ
- 全テンプレート/ルールが参照元を持つ
- 全スキルが整合
- 旧コンセプトの残骸なし
- revise.md 書き換え関連の伝播は M1 以外完了
- CLAUDE.md "Step 3-4" 参照の除去は完全

---

## Recommended Fix Priority

| Priority | ID | Summary | Target Files |
|----------|-----|---------|-------------|
| 1 | M1 | CLAUDE.md L244 の `REVISION_INITIATED` に `(cross-cutting)` 注記を追加 | `framework/claude/CLAUDE.md` |
