## Dead Code & Unused References Report

### Issues Found

- [MEDIUM] install.sh:339,341 - 削除済みコマンド `/sdd-impl` への参照残存
- [LOW] CLAUDE.md:141 - Commands数が実際のskill数と不一致 (6と記載、実際は7: sdd-review-selfが未記載)
- [LOW] run.md:65 - 非公式フェーズ名 `design-reviewed`, `impl-done` が疑似コード中で使用されている

### Confirmed OK

- 全23エージェント定義が正しくディスパッチ元から参照されている
- 全7ルールファイルが少なくとも1つのファイルから参照されている
- 全テンプレートファイルが少なくとも1つのファイルから参照されている
- 削除済みスキル (sdd-design, sdd-impl, sdd-review) への参照はフレームワーク内に残存していない
- SubAgent上限24の旧参照は完全に除去済み
- 旧概念 (Coordinator, Planner, conductor) への参照は完全に除去済み
- `_review` ディレクトリ参照は完全に除去済み
- Foundation-First スケジューリングとrun.mdの並列ディスパッチループ間に矛盾なし
- steering-custom テンプレート8件は全て sdd-steering/SKILL.md の一覧と一致
- install.sh のマイグレーションブロックは古いバージョンからのアップグレードパスとして適切に機能
- CPFフォーマット仕様はcpf-format.mdで定義、CLAUDE.mdから参照、全Auditor/Inspectorが使用
- verdict.cpf → verdicts.md のフローはreview.mdで正しく定義

### Overall Assessment

フレームワーク全体としてデッドコード・未参照リソースの状態は良好。重大な問題はない。

---

## 詳細分析

### 1. 未参照エージェント検出

全23エージェント定義について、SKILL.md/refs またはAuditorからの参照を検証した。

#### エージェント参照マトリクス

| エージェント | 定義ファイル | ディスパッチ元 | 状態 |
|---|---|---|---|
| sdd-architect | agents/sdd-architect.md | CLAUDE.md, refs/run.md, refs/design.md | OK |
| sdd-taskgenerator | agents/sdd-taskgenerator.md | refs/impl.md | OK |
| sdd-builder | agents/sdd-builder.md | refs/impl.md | OK |
| sdd-auditor-design | agents/sdd-auditor-design.md | refs/review.md | OK |
| sdd-auditor-impl | agents/sdd-auditor-impl.md | refs/review.md | OK |
| sdd-auditor-dead-code | agents/sdd-auditor-dead-code.md | refs/review.md | OK |
| sdd-inspector-rulebase | agents/sdd-inspector-rulebase.md | refs/review.md, auditor-design.md | OK |
| sdd-inspector-testability | agents/sdd-inspector-testability.md | refs/review.md, auditor-design.md | OK |
| sdd-inspector-architecture | agents/sdd-inspector-architecture.md | refs/review.md, auditor-design.md | OK |
| sdd-inspector-consistency | agents/sdd-inspector-consistency.md | refs/review.md, auditor-design.md | OK |
| sdd-inspector-best-practices | agents/sdd-inspector-best-practices.md | refs/review.md, auditor-design.md | OK |
| sdd-inspector-holistic | agents/sdd-inspector-holistic.md | refs/review.md, auditor-design.md | OK |
| sdd-inspector-impl-rulebase | agents/sdd-inspector-impl-rulebase.md | refs/review.md, auditor-impl.md | OK |
| sdd-inspector-interface | agents/sdd-inspector-interface.md | refs/review.md, auditor-impl.md | OK |
| sdd-inspector-test | agents/sdd-inspector-test.md | refs/review.md, auditor-impl.md | OK |
| sdd-inspector-quality | agents/sdd-inspector-quality.md | refs/review.md, auditor-impl.md | OK |
| sdd-inspector-impl-consistency | agents/sdd-inspector-impl-consistency.md | refs/review.md, auditor-impl.md | OK |
| sdd-inspector-impl-holistic | agents/sdd-inspector-impl-holistic.md | refs/review.md, auditor-impl.md | OK |
| sdd-inspector-e2e | agents/sdd-inspector-e2e.md | refs/review.md, auditor-impl.md, templates/steering-custom/ui.md | OK |
| sdd-inspector-dead-settings | agents/sdd-inspector-dead-settings.md | refs/review.md, auditor-dead-code.md | OK |
| sdd-inspector-dead-code | agents/sdd-inspector-dead-code.md | refs/review.md, auditor-dead-code.md | OK |
| sdd-inspector-dead-specs | agents/sdd-inspector-dead-specs.md | refs/review.md, auditor-dead-code.md | OK |
| sdd-inspector-dead-tests | agents/sdd-inspector-dead-tests.md | refs/review.md, auditor-dead-code.md | OK |

**結果**: 未参照エージェントなし。全23エージェントが適切にディスパッチされている。

### 2. 未参照テンプレート/ルール検出

#### テンプレート参照マトリクス

| テンプレート | パス | 参照元 | 状態 |
|---|---|---|---|
| specs/init.yaml | templates/specs/init.yaml | sdd-roadmap/SKILL.md | OK |
| specs/design.md | templates/specs/design.md | sdd-architect.md, sdd-inspector-rulebase.md | OK |
| specs/research.md | templates/specs/research.md | sdd-architect.md | OK |
| steering/product.md | templates/steering/product.md | sdd-steering/SKILL.md (テンプレートディレクトリ参照) | OK |
| steering/tech.md | templates/steering/tech.md | sdd-steering/SKILL.md | OK |
| steering/structure.md | templates/steering/structure.md | sdd-steering/SKILL.md | OK |
| handover/session.md | templates/handover/session.md | CLAUDE.md, sdd-handover/SKILL.md | OK |
| handover/buffer.md | templates/handover/buffer.md | CLAUDE.md | OK |
| knowledge/pattern.md | templates/knowledge/pattern.md | sdd-knowledge/SKILL.md (テンプレートディレクトリ参照) | OK |
| knowledge/incident.md | templates/knowledge/incident.md | sdd-knowledge/SKILL.md | OK |
| knowledge/reference.md | templates/knowledge/reference.md | sdd-knowledge/SKILL.md | OK |
| steering-custom/api-standards.md | templates/steering-custom/ | sdd-steering/SKILL.md | OK |
| steering-custom/authentication.md | templates/steering-custom/ | sdd-steering/SKILL.md | OK |
| steering-custom/database.md | templates/steering-custom/ | sdd-steering/SKILL.md | OK |
| steering-custom/deployment.md | templates/steering-custom/ | sdd-steering/SKILL.md | OK |
| steering-custom/error-handling.md | templates/steering-custom/ | sdd-steering/SKILL.md | OK |
| steering-custom/security.md | templates/steering-custom/ | sdd-steering/SKILL.md | OK |
| steering-custom/testing.md | templates/steering-custom/ | sdd-steering/SKILL.md | OK |
| steering-custom/ui.md | templates/steering-custom/ | sdd-steering/SKILL.md | OK |

#### ルール参照マトリクス

| ルール | パス | 参照元 | 状態 |
|---|---|---|---|
| cpf-format.md | rules/cpf-format.md | CLAUDE.md | OK |
| design-principles.md | rules/design-principles.md | sdd-architect.md | OK |
| design-review.md | rules/design-review.md | sdd-inspector-rulebase.md, sdd-inspector-testability.md | OK |
| steering-principles.md | rules/steering-principles.md | sdd-steering/SKILL.md | OK |
| tasks-generation.md | rules/tasks-generation.md | sdd-taskgenerator.md | OK |
| design-discovery-full.md | rules/design-discovery-full.md | sdd-architect.md | OK |
| design-discovery-light.md | rules/design-discovery-light.md | sdd-architect.md | OK |

#### プロファイル参照

| プロファイル | パス | 参照元 | 状態 |
|---|---|---|---|
| _index.md | profiles/_index.md | sdd-steering/SKILL.md (ディレクトリ参照) | OK |
| python.md | profiles/python.md | sdd-steering/SKILL.md | OK |
| typescript.md | profiles/typescript.md | sdd-steering/SKILL.md | OK |
| rust.md | profiles/rust.md | sdd-steering/SKILL.md | OK |

**結果**: 未参照テンプレート/ルール/プロファイルなし。全ファイルが適切に参照されている。

### 3. スキルとCLAUDE.md Commandsテーブルの整合性

| スキル | SKILL.mdの存在 | CLAUDE.md Commands表 | 状態 |
|---|---|---|---|
| /sdd-steering | OK | OK | OK |
| /sdd-roadmap | OK | OK | OK |
| /sdd-status | OK | OK | OK |
| /sdd-handover | OK | OK | OK |
| /sdd-knowledge | OK | OK | OK |
| /sdd-release | OK | OK | OK |
| /sdd-review-self | OK | **未記載** | 注意 (LOW) |

`sdd-review-self` は `description: "Self-review for SDD framework development (framework-internal use only)"` と記載されており、フレームワーク内部用ツールとして意図的にCommandsテーブルから除外されている可能性がある。ただし、CLAUDE.md `### Commands (6)` のカウントは、install対象のスキルファイル数 (7) と不一致。

**影響**: sdd-release/SKILL.md Step 3でスキル数を自動カウントする際、`sdd-review-self` を含めてカウントするため、CLAUDE.mdの `Commands (6)` とのずれが発生する可能性がある。

### 4. 冗長コンテンツ (意図的重複)

以下は意図的な設計による重複であり、問題ではない:

- **Wave-Scoped Cross-Check Mode セクション**: 全13 Inspector エージェントに同一構造で存在。各エージェントが自己完結的に動作するための設計。
- **Verdict Output Guarantee セクション**: 全3 Auditor エージェントに同一構造で存在。同上。
- **Output Format / CPF仕様**: Inspector/Auditor間で統一フォーマット。CPF仕様の参照元はcpf-format.md。

### 5. 到達不能コードパス

到達不能なコードパスは検出されなかった。

- フェーズゲートは全てのブランチで適切にエラーを返す
- Auto-fixループは上限に達した場合エスカレーションにフォールバック
- コンセンサスモードのN=1は通常モードに正しく縮退

### 6. 削除済み概念の残存

| 概念 | 削除バージョン | フレームワーク内残存 | install.sh内残存 | 状態 |
|---|---|---|---|---|
| sdd-design (旧スキル) | v0.22.0 | なし | なし | OK |
| sdd-impl (旧スキル) | v0.22.0 | なし | install.sh:339,341 (v0.10.0マイグレーション内) | 注意 (MEDIUM) |
| sdd-review (旧スキル) | v0.22.0 | なし | なし | OK |
| Coordinator (旧エージェント) | v0.7.0 | なし | install.sh (マイグレーション内、適切) | OK |
| Planner (旧エージェント) | v0.10.0 | なし | install.sh (マイグレーション内、適切) | OK |
| SubAgent上限24 | v0.23.0以降 | なし | なし | OK |
| `_review` ディレクトリ名 | v0.21.0 | なし | なし | OK |

**install.sh:339,341の詳細**:
```
# tasks.md files are left as-is; TaskGenerator will regenerate on next /sdd-impl run
info "Note: Existing tasks.md files are preserved but will be regenerated by TaskGenerator on next /sdd-impl run."
```
v0.10.0マイグレーションブロック内で `/sdd-impl` を参照している。v0.10.0時点ではこのコマンドは存在していたため、マイグレーション文脈としては正しい。しかし現在のフレームワークでは `/sdd-roadmap impl` が正しいコマンドであり、v0.10.0からアップグレードするユーザーが混乱する可能性がある。

**推奨**: マイグレーションメッセージを `/sdd-roadmap impl` に更新する (低優先度)。

### 7. 非公式フェーズ名の使用

run.md:65の疑似コード内で `design-reviewed` と `impl-done` が使用されている:
```
Determine next phase (initialized→Design, design-generated→Design Review,
  design-reviewed→Impl, impl-done→Impl Review)
```

CLAUDE.mdで定義されている公式フェーズは `initialized`, `design-generated`, `implementation-complete`, `blocked` の4つ。

`design-reviewed` と `impl-done` はディスパッチループ内部の概念的な遷移状態を示す非公式ラベルであり、spec.yamlに保存されるフェーズ名ではない。ただし、Leadがこれを実際のフェーズ名と誤解するリスクは低い (Readiness Rules表で正しいフェーズ条件が明示されているため)。

**推奨**: 疑似コードのコメントを公式フェーズ名に揃える (例: `design-generated + review passed → Impl`) (低優先度)。

### 8. TODO/FIXME/空セクション

- TODO/FIXME/HACK/XXX/TEMP: フレームワーク内に該当なし (sdd-review-self/SKILL.md内のリテラル記述を除く)
- 空セクション: 検出なし

---

## 修正優先度

| 優先度 | ID | 概要 | 対象ファイル |
|---|---|---|---|
| M | DC-1 | install.sh v0.10.0マイグレーション内の `/sdd-impl` 参照を更新 | install.sh:339,341 |
| L | DC-2 | CLAUDE.md Commands数 (6) を実態 (7) に合わせるか、sdd-review-selfの扱いを明確化 | framework/claude/CLAUDE.md:141 |
| L | DC-3 | run.md疑似コード内の非公式フェーズ名を公式名に揃える | framework/claude/skills/sdd-roadmap/refs/run.md:65 |
