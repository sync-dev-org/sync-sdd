## Dead Code & Unused References Report

### Issues Found

- [LOW] CLAUDE.md Commands (6) は sdd-review-self を除外しているが、install.sh のサマリ出力は `sdd-*/SKILL.md` を全数カウントするため、ユーザーには 7 skills と表示される。CLAUDE.md 側のテーブルに internal/framework-only ツールの注記を追加するか、カウントを 7(+1 internal) に調整すると整合する。
  - 場所: `framework/claude/CLAUDE.md:141` (`### Commands (6)`)
  - install.sh:545 は `find .claude/skills -name 'SKILL.md' -path '*/sdd-*/*'` で 7 を返す

- [LOW] Wave-Scoped Cross-Check Mode ボイラープレートが 13 Inspector エージェント全てに同一内容で重複。SubAgent アーキテクチャ上の設計上の冗長であり、自己完結性のために必要。ただし、将来的にルールファイルに抽出して `Read` 指示に置き換える余地がある。合計約130行の重複。
  - 場所: `framework/claude/agents/sdd-inspector-*.md` (13ファイル)

- [LOW] `sdd-review-self/SKILL.md` が `Task(subagent_type="general-purpose")` でエージェントをディスパッチするが、`framework/claude/agents/` に `general-purpose.md` は存在しない。Claude Code のビルトイン SubAgent タイプを利用していると推定されるが、明示的な記載がない。
  - 場所: `framework/claude/skills/sdd-review-self/SKILL.md:65`

### Confirmed OK

- 全 23 エージェント定義が少なくとも 1 箇所から参照されている (下記マトリクス参照)
- 全 7 ルールファイルが少なくとも 1 箇所から参照されている (下記マトリクス参照)
- 全 19 テンプレートファイルが少なくとも 1 箇所から参照されている (下記マトリクス参照)
- CLAUDE.md Commands テーブルの 6 スキルは全て SKILL.md が存在する
- 逆方向: 7 SKILL.md のうち 6 が CLAUDE.md テーブルに記載、1 (sdd-review-self) は意図的にフレームワーク内部用として除外
- 削除済みコンセプトの残留なし: `Coordinator`, `Conductor`, `Planner`, `sdd-tasks`, `spec.json`, `state.md`, `log.md` への参照ゼロ
- install.sh マイグレーションコードは過去バージョン対応のため残留しているが、これは意図的 (新規インストール時はスキップされる)
- TODO/FIXME/HACK: フレームワークコード内に実際のマーカーなし (検出ターゲットとしての言及のみ)
- 空セクション: なし
- 到達不能コードパス: なし
- `refs/` 参照 ("see sdd-roadmap refs/X") は全て実在するファイルの実在するセクションを指す

### 未コミット変更に関する分析

#### Builder SELF-CHECK 追加 (sdd-builder.md)
- 旧: Step 5 "MARK COMPLETE" に AC verification 内容
- 新: Step 5 "SELF-CHECK" として独立、Step 6 "MARK COMPLETE" は確認のみ
- `SelfCheck` フィールドが Builder 完了レポートに追加
- `refs/impl.md` も `SelfCheck` 処理を追加済み
- **残留チェック**: CLAUDE.md に `SelfCheck` への言及なし。現状は refs/impl.md と sdd-builder.md のみが知る概念。Lead が SelfCheck を処理するための指示は refs/impl.md にあるため動作上の問題はないが、CLAUDE.md の Role Architecture テーブル (Builder 行) の Responsibility 記述が更新されていない。

#### tasks-generation.md Steering Integration 追加
- 旧: "Avoid: File paths and directory structure" (絶対禁止)
- 新: "Avoid: Inventing file paths" (structure.md 参照は許可) + Steering Integration セクション追加
- sdd-taskgenerator.md にも対応する行が追加済み
- **残留チェック**: 問題なし。旧表現の残留なし。

---

## エージェント参照マトリクス

| エージェント | 定義 | 参照元 |
|---|---|---|
| `sdd-architect` | agents/sdd-architect.md | CLAUDE.md, refs/design.md, refs/run.md |
| `sdd-auditor-dead-code` | agents/sdd-auditor-dead-code.md | refs/review.md |
| `sdd-auditor-design` | agents/sdd-auditor-design.md | refs/review.md |
| `sdd-auditor-impl` | agents/sdd-auditor-impl.md | refs/review.md |
| `sdd-taskgenerator` | agents/sdd-taskgenerator.md | refs/impl.md |
| `sdd-builder` | agents/sdd-builder.md | refs/impl.md |
| `sdd-inspector-architecture` | agents/sdd-inspector-architecture.md | refs/review.md, sdd-auditor-design.md |
| `sdd-inspector-best-practices` | agents/sdd-inspector-best-practices.md | refs/review.md, sdd-auditor-design.md |
| `sdd-inspector-consistency` | agents/sdd-inspector-consistency.md | refs/review.md, sdd-auditor-design.md |
| `sdd-inspector-holistic` | agents/sdd-inspector-holistic.md | refs/review.md, sdd-auditor-design.md |
| `sdd-inspector-rulebase` | agents/sdd-inspector-rulebase.md | refs/review.md, sdd-auditor-design.md |
| `sdd-inspector-testability` | agents/sdd-inspector-testability.md | refs/review.md, sdd-auditor-design.md |
| `sdd-inspector-impl-consistency` | agents/sdd-inspector-impl-consistency.md | refs/review.md, sdd-auditor-impl.md |
| `sdd-inspector-impl-holistic` | agents/sdd-inspector-impl-holistic.md | refs/review.md, sdd-auditor-impl.md |
| `sdd-inspector-impl-rulebase` | agents/sdd-inspector-impl-rulebase.md | refs/review.md, sdd-auditor-impl.md |
| `sdd-inspector-interface` | agents/sdd-inspector-interface.md | refs/review.md, sdd-auditor-impl.md |
| `sdd-inspector-quality` | agents/sdd-inspector-quality.md | refs/review.md, sdd-auditor-impl.md |
| `sdd-inspector-test` | agents/sdd-inspector-test.md | refs/review.md, sdd-auditor-impl.md |
| `sdd-inspector-e2e` | agents/sdd-inspector-e2e.md | refs/review.md, sdd-auditor-impl.md, steering-custom/ui.md |
| `sdd-inspector-dead-code` | agents/sdd-inspector-dead-code.md | refs/review.md, sdd-auditor-dead-code.md |
| `sdd-inspector-dead-settings` | agents/sdd-inspector-dead-settings.md | refs/review.md, sdd-auditor-dead-code.md |
| `sdd-inspector-dead-specs` | agents/sdd-inspector-dead-specs.md | refs/review.md, sdd-auditor-dead-code.md |
| `sdd-inspector-dead-tests` | agents/sdd-inspector-dead-tests.md | refs/review.md, sdd-auditor-dead-code.md |

**結果**: 未参照エージェント 0 件。全 23 エージェントが参照チェーン内に存在。

---

## テンプレート参照マトリクス

| テンプレート | パス | 参照元 |
|---|---|---|
| specs/design.md | templates/specs/design.md | sdd-architect.md, sdd-inspector-rulebase.md |
| specs/research.md | templates/specs/research.md | sdd-architect.md |
| specs/init.yaml | templates/specs/init.yaml | sdd-roadmap/SKILL.md |
| steering/product.md | templates/steering/product.md | sdd-steering/SKILL.md |
| steering/tech.md | templates/steering/tech.md | sdd-steering/SKILL.md |
| steering/structure.md | templates/steering/structure.md | sdd-steering/SKILL.md |
| steering-custom/api-standards.md | templates/steering-custom/api-standards.md | sdd-steering/SKILL.md |
| steering-custom/authentication.md | templates/steering-custom/authentication.md | sdd-steering/SKILL.md |
| steering-custom/database.md | templates/steering-custom/database.md | sdd-steering/SKILL.md |
| steering-custom/deployment.md | templates/steering-custom/deployment.md | sdd-steering/SKILL.md |
| steering-custom/error-handling.md | templates/steering-custom/error-handling.md | sdd-steering/SKILL.md |
| steering-custom/security.md | templates/steering-custom/security.md | sdd-steering/SKILL.md |
| steering-custom/testing.md | templates/steering-custom/testing.md | sdd-steering/SKILL.md |
| steering-custom/ui.md | templates/steering-custom/ui.md | sdd-steering/SKILL.md, sdd-inspector-e2e.md |
| handover/session.md | templates/handover/session.md | CLAUDE.md, sdd-handover/SKILL.md |
| handover/buffer.md | templates/handover/buffer.md | CLAUDE.md |
| knowledge/pattern.md | templates/knowledge/pattern.md | sdd-knowledge/SKILL.md |
| knowledge/incident.md | templates/knowledge/incident.md | sdd-knowledge/SKILL.md |
| knowledge/reference.md | templates/knowledge/reference.md | sdd-knowledge/SKILL.md |

**結果**: 未参照テンプレート 0 件。全 19 テンプレートが参照チェーン内に存在。

---

## ルール参照マトリクス

| ルール | パス | 参照元 |
|---|---|---|
| cpf-format.md | rules/cpf-format.md | CLAUDE.md |
| design-principles.md | rules/design-principles.md | sdd-architect.md |
| design-review.md | rules/design-review.md | sdd-inspector-rulebase.md, sdd-inspector-testability.md |
| design-discovery-full.md | rules/design-discovery-full.md | sdd-architect.md |
| design-discovery-light.md | rules/design-discovery-light.md | sdd-architect.md |
| steering-principles.md | rules/steering-principles.md | sdd-steering/SKILL.md |
| tasks-generation.md | rules/tasks-generation.md | sdd-taskgenerator.md |

**結果**: 未参照ルール 0 件。全 7 ルールが参照チェーン内に存在。

---

## スキル-CLAUDE.md 対応マトリクス

| CLAUDE.md コマンド | SKILL.md 存在 | 備考 |
|---|---|---|
| `/sdd-steering` | sdd-steering/SKILL.md | OK |
| `/sdd-roadmap` | sdd-roadmap/SKILL.md | OK |
| `/sdd-status` | sdd-status/SKILL.md | OK |
| `/sdd-handover` | sdd-handover/SKILL.md | OK |
| `/sdd-knowledge` | sdd-knowledge/SKILL.md | OK |
| `/sdd-release` | sdd-release/SKILL.md | OK |
| (未記載) | sdd-review-self/SKILL.md | 意図的除外 (framework-internal) |

**結果**: 不整合 0 件。

---

### Overall Assessment

フレームワークのデッドコード状態は非常にクリーン。

**検出された問題**:
- CRITICAL: 0件
- HIGH: 0件
- MEDIUM: 0件
- LOW: 3件

**主要な所見**:
1. 全 23 エージェント、全 19 テンプレート、全 7 ルール、全 7 スキルが参照チェーン内に存在し、孤立したアーティファクトはない
2. 削除済みコンセプト (Coordinator, Planner, conductor, spec.json 等) の残留参照はゼロ
3. 未コミット変更 (Builder SELF-CHECK, Steering Integration) は適切に伝播されており、残留する旧コンセプトはない
4. Wave-Scoped Cross-Check Mode の 13 ファイル間重複は SubAgent アーキテクチャの設計上の制約による意図的冗長
5. CLAUDE.md の Commands (6) カウントは sdd-review-self を意図的に除外しているが、install.sh 出力との微小な不整合がある
