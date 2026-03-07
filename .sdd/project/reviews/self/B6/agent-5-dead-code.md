## Dead Code & Unused References Report

### Issues Found

- [MEDIUM] CLAUDE.md Commands (6) はユーザー向けコマンドとして正確だが、settings.json には `Skill(sdd-review-self)` が許可されており、合計7スキルが存在する。sdd-review-self は「framework-internal use only」と明記されておりCLAUDE.mdのコマンド表から意図的に除外されているが、ユーザーが `/sdd-review-self` を実行可能であることの説明がCLAUDE.md上にない。ユーザーから見えるスキルとして登録されているにもかかわらず、存在自体が文書化されていない。 / framework/claude/CLAUDE.md:142, framework/claude/settings.json:11

- [LOW] Wave-Scoped Cross-Check Mode セクションが14個のInspectorエージェント全てにほぼ同一の内容で重複している。各Inspectorにおいて5ステップ（Resolve Wave Scope → Load Steering → Load Roadmap → Load Wave-Scoped Specs → Execute Wave-Scoped Cross-Check）がコピーペーストで記載されている。これは冗長だが、SubAgentは共有コンテキストを持たないため、各エージェントファイルに完結した手順が必要というアーキテクチャ上の制約から正当化される。ただし変更時のメンテナンスリスクは存在する。 / framework/claude/agents/sdd-inspector-*.md

### Agent Reference Matrix

全24エージェントの参照・ディスパッチ状況:

| Agent | 定義ファイル | settings.json | ディスパッチ元 | 状態 |
|-------|------------|---------------|-------------|------|
| sdd-architect | agents/sdd-architect.md | Task(sdd-architect) | refs/design.md, refs/run.md, refs/revise.md | OK |
| sdd-auditor-dead-code | agents/sdd-auditor-dead-code.md | Task(sdd-auditor-dead-code) | refs/review.md | OK |
| sdd-auditor-design | agents/sdd-auditor-design.md | Task(sdd-auditor-design) | refs/review.md | OK |
| sdd-auditor-impl | agents/sdd-auditor-impl.md | Task(sdd-auditor-impl) | refs/review.md | OK |
| sdd-builder | agents/sdd-builder.md | Task(sdd-builder) | refs/impl.md, refs/run.md | OK |
| sdd-taskgenerator | agents/sdd-taskgenerator.md | Task(sdd-taskgenerator) | refs/impl.md | OK |
| sdd-inspector-architecture | agents/sdd-inspector-architecture.md | Task(sdd-inspector-architecture) | refs/review.md (design) | OK |
| sdd-inspector-best-practices | agents/sdd-inspector-best-practices.md | Task(sdd-inspector-best-practices) | refs/review.md (design) | OK |
| sdd-inspector-consistency | agents/sdd-inspector-consistency.md | Task(sdd-inspector-consistency) | refs/review.md (design) | OK |
| sdd-inspector-holistic | agents/sdd-inspector-holistic.md | Task(sdd-inspector-holistic) | refs/review.md (design) | OK |
| sdd-inspector-rulebase | agents/sdd-inspector-rulebase.md | Task(sdd-inspector-rulebase) | refs/review.md (design) | OK |
| sdd-inspector-testability | agents/sdd-inspector-testability.md | Task(sdd-inspector-testability) | refs/review.md (design) | OK |
| sdd-inspector-impl-rulebase | agents/sdd-inspector-impl-rulebase.md | Task(sdd-inspector-impl-rulebase) | refs/review.md (impl) | OK |
| sdd-inspector-interface | agents/sdd-inspector-interface.md | Task(sdd-inspector-interface) | refs/review.md (impl) | OK |
| sdd-inspector-test | agents/sdd-inspector-test.md | Task(sdd-inspector-test) | refs/review.md (impl) | OK |
| sdd-inspector-quality | agents/sdd-inspector-quality.md | Task(sdd-inspector-quality) | refs/review.md (impl) | OK |
| sdd-inspector-impl-consistency | agents/sdd-inspector-impl-consistency.md | Task(sdd-inspector-impl-consistency) | refs/review.md (impl) | OK |
| sdd-inspector-impl-holistic | agents/sdd-inspector-impl-holistic.md | Task(sdd-inspector-impl-holistic) | refs/review.md (impl) | OK |
| sdd-inspector-e2e | agents/sdd-inspector-e2e.md | Task(sdd-inspector-e2e) | refs/review.md (impl, web) | OK |
| sdd-inspector-visual | agents/sdd-inspector-visual.md | Task(sdd-inspector-visual) | refs/review.md (impl, web) | OK |
| sdd-inspector-dead-code | agents/sdd-inspector-dead-code.md | Task(sdd-inspector-dead-code) | refs/review.md (dead-code) | OK |
| sdd-inspector-dead-settings | agents/sdd-inspector-dead-settings.md | Task(sdd-inspector-dead-settings) | refs/review.md (dead-code) | OK |
| sdd-inspector-dead-specs | agents/sdd-inspector-dead-specs.md | Task(sdd-inspector-dead-specs) | refs/review.md (dead-code) | OK |
| sdd-inspector-dead-tests | agents/sdd-inspector-dead-tests.md | Task(sdd-inspector-dead-tests) | refs/review.md (dead-code) | OK |

**結果**: 全24エージェントが定義・登録・ディスパッチの全レベルで正しく参照されている。未参照エージェントなし。

### Template Reference Matrix

| テンプレート | パス | 参照元 | 状態 |
|------------|------|--------|------|
| specs/design.md | templates/specs/design.md | sdd-architect, sdd-inspector-rulebase | OK |
| specs/research.md | templates/specs/research.md | sdd-architect | OK |
| specs/init.yaml | templates/specs/init.yaml | sdd-roadmap SKILL.md | OK |
| handover/session.md | templates/handover/session.md | CLAUDE.md, sdd-handover | OK |
| handover/buffer.md | templates/handover/buffer.md | CLAUDE.md | OK |
| knowledge/pattern.md | templates/knowledge/pattern.md | sdd-knowledge | OK |
| knowledge/incident.md | templates/knowledge/incident.md | sdd-knowledge | OK |
| knowledge/reference.md | templates/knowledge/reference.md | sdd-knowledge | OK |
| steering/product.md | templates/steering/product.md | sdd-steering | OK |
| steering/tech.md | templates/steering/tech.md | sdd-steering | OK |
| steering/structure.md | templates/steering/structure.md | sdd-steering | OK |
| steering-custom/api-standards.md | templates/steering-custom/api-standards.md | sdd-steering | OK |
| steering-custom/authentication.md | templates/steering-custom/authentication.md | sdd-steering | OK |
| steering-custom/database.md | templates/steering-custom/database.md | sdd-steering | OK |
| steering-custom/deployment.md | templates/steering-custom/deployment.md | sdd-steering | OK |
| steering-custom/error-handling.md | templates/steering-custom/error-handling.md | sdd-steering | OK |
| steering-custom/security.md | templates/steering-custom/security.md | sdd-steering | OK |
| steering-custom/testing.md | templates/steering-custom/testing.md | sdd-steering | OK |
| steering-custom/ui.md | templates/steering-custom/ui.md | sdd-steering | OK |

**結果**: 全18テンプレートが正しく参照されている。未参照テンプレートなし。

### Rules Reference Matrix

| ルールファイル | パス | 参照元 | 状態 |
|-------------|------|--------|------|
| cpf-format.md | rules/cpf-format.md | CLAUDE.md | OK |
| design-principles.md | rules/design-principles.md | sdd-architect | OK |
| design-discovery-full.md | rules/design-discovery-full.md | sdd-architect | OK |
| design-discovery-light.md | rules/design-discovery-light.md | sdd-architect | OK |
| design-review.md | rules/design-review.md | sdd-inspector-rulebase, sdd-inspector-testability | OK |
| tasks-generation.md | rules/tasks-generation.md | sdd-taskgenerator | OK |
| steering-principles.md | rules/steering-principles.md | sdd-steering | OK |

**結果**: 全7ルールファイルが正しく参照されている。未参照ルールなし。

### Skill Reference Matrix

| スキル | SKILL.md | CLAUDE.md表 | settings.json | 状態 |
|--------|----------|-------------|---------------|------|
| sdd-steering | 存在 | 記載 | Skill(sdd-steering) | OK |
| sdd-roadmap | 存在 | 記載 | Skill(sdd-roadmap) | OK |
| sdd-status | 存在 | 記載 | Skill(sdd-status) | OK |
| sdd-handover | 存在 | 記載 | Skill(sdd-handover) | OK |
| sdd-knowledge | 存在 | 記載 | Skill(sdd-knowledge) | OK |
| sdd-release | 存在 | 記載 | Skill(sdd-release) | OK |
| sdd-review-self | 存在 | 未記載 (意図的) | Skill(sdd-review-self) | OK (framework-internal) |

**結果**: 全7スキルが正しく対応している。sdd-review-selfはフレームワーク内部ツールとして意図的にCLAUDE.mdコマンド表から除外。

### Profile Reference Check

| プロファイル | パス | 参照元 | 状態 |
|------------|------|--------|------|
| _index.md | profiles/_index.md | sdd-steering (exclude指定) | OK |
| python.md | profiles/python.md | sdd-steering (動的ロード) | OK |
| typescript.md | profiles/typescript.md | sdd-steering (動的ロード) | OK |
| rust.md | profiles/rust.md | sdd-steering (動的ロード) | OK |

**結果**: 全プロファイルが正しく参照されている。

### Remnants of Removed Concepts Check

最近のコミットで削除・リネームされた概念の残留チェック:

| 概念 | 状態 | 詳細 |
|------|------|------|
| sdd-coordinator (v0.7.0で削除) | 残留なし | frameworkコード内に参照なし |
| sdd-planner (v0.10.0で削除) | 残留なし | frameworkコード内に参照なし |
| conductor.md (v0.9.0でsession.mdにリネーム) | 残留なし | frameworkコード内に参照なし |
| state.md (v0.9.0でsession.mdにリネーム) | 残留なし | frameworkコード内に参照なし |
| log.md (v0.9.0でdecisions.mdにリネーム) | 残留なし | frameworkコード内に参照なし |
| spec.json / init.json (v0.10.0でYAML化) | 残留なし | frameworkコード内に参照なし |
| tasks.md (v0.10.0でtasks.yamlに移行) | 残留なし | frameworkコード内に参照なし |
| .kiro/ (v0.4.0で.claude/sdd/に移行) | 残留なし | frameworkコード内に参照なし |
| .claude/commands/ (v0.15.0でskillsに移行) | 残留なし | frameworkコード内に参照なし |
| Agent Teams env var (v0.20.0で廃止) | 残留なし | frameworkコード内に参照なし |
| .claude/sdd/ (v1.2.0で.sdd/に移行) | 残留なし | frameworkコード内に参照なし (install.shのmigrationブロックは正当) |
| foreground dispatch例外 (v1.0.3で削除) | 残留なし | CLAUDE.mdで「No exceptions」と明記 |

**結果**: 削除済み概念の残留は検出されなかった。

### Stale Comments / Empty Sections Check

- TODO/FIXME/HACK: frameworkコード内にTODO/FIXME/HACKコメントは存在しない（sdd-review-selfのレビュー基準定義内とsdd-builderのSelfCheck基準内での言及のみ。これらはメタ的な参照であり、実際のTODOではない）
- 空セクション: 検出なし

### Unreachable Code Paths Check

- install.sh migration blocks: 全migration関数はバージョン比較ゲートで保護されており、適切なバージョンからのアップグレード時のみ実行される。到達不能パスなし。
- SKILL.md条件分岐: 全サブコマンドルーティングが網羅的。デッドブランチなし。
- Review types: design, impl, dead-codeの3タイプが refs/review.md で定義されており、SKILL.md のDetect Modeと一致。

### Confirmed OK

- 全24エージェント: 定義 <-> settings.json <-> ディスパッチ参照が完全一致
- 全7スキル: SKILL.md <-> settings.json が完全一致、CLAUDE.md表は意図的にユーザー向け6コマンドのみ記載
- 全18テンプレート: 全て少なくとも1箇所から参照されている
- 全7ルール: 全て少なくとも1箇所から参照されている
- 全4プロファイル: sdd-steeringから動的にロードされる
- `{{SDD_DIR}}` = `.sdd` 定義: CLAUDE.md内で一貫 (v1.2.0移行完了)
- install.sh: `.sdd/` パスを使用、旧パスはmigrationブロック内のみ
- 削除概念の残留: 検出なし
- TODO/FIXME: 検出なし
- 空セクション: 検出なし
- 到達不能コードパス: 検出なし
- steering-principles.md: `.sdd/` パスを使用 (uncommitted changesで確認済み)

### Overall Assessment

フレームワークのデッドコード・未使用参照の状態は**非常に良好**。

24エージェント、7スキル、18テンプレート、7ルール、4プロファイルの全てが正しく参照され、孤立したアーティファクトは存在しない。過去の概念（coordinator, planner, conductor, state.md, log.md, spec.json, .kiro, commands, Agent Teams, .claude/sdd）の残留も検出されなかった。

検出された問題は以下のみ:
1. **[MEDIUM]** sdd-review-selfがCLAUDE.md上で全く言及されていない点。settings.jsonに登録されユーザーが実行可能だが、その存在がCLAUDE.mdに記載されていないため、フレームワーク利用者が発見できない可能性がある。
2. **[LOW]** 14個のInspectorエージェントにおけるWave-Scoped Cross-Check Modeセクションの冗長な重複。アーキテクチャ上の制約（SubAgentの独立性）から正当化されるが、将来の変更時にメンテナンスリスクを生む。

総合判定: **GO** (重大な問題なし)
