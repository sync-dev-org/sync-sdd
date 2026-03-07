## Consistency Report

### Issues Found

- [MEDIUM] **CLAUDE.md「Commands (5)」はsdd-review-selfを含まない** / `framework/claude/CLAUDE.md:140`
  CLAUDE.mdの`### Commands (5)`テーブルには5つのコマンドが記載されているが、実際には`sdd-review-self`を含む6つのスキルが存在する。sdd-review-selfはフレームワーク内部用ツールのため意図的に除外されている可能性が高いが、settings.jsonには`Skill(sdd-review-self)`が許可リストに含まれている。ユーザー向けコマンドとフレームワーク内部ツールの区別が明示されていない。

- [MEDIUM] **sdd-auditor-design: Verification Stepの番号飛び（Step 8→Step 10）** / `framework/claude/agents/sdd-auditor-design.md:131-164`
  Step 8（Over-Engineering Check）の後にStep 9（Decision Suggestions）が存在し、Step 10（Synthesize Final Verdict）が続く。正しいシーケンスだが、Verdict Output Guarantee のテキストで「Step 10 (Synthesize Final Verdict)」と参照しており、実際のステップ数は10ステップ。一方、dead-code AuditorではStep 8が最終ステップ。同じ「skip to Step N」パターンだがNが異なる点は一貫性の問題ではなく、各Auditorのステップ数の違いを正しく反映している。**OK（自己完結的）。**

- [MEDIUM] **review.mdのInspector一覧でsdd-inspector-best-practicesにWebSearchがない** / `framework/claude/agents/sdd-inspector-best-practices.md:6` vs `framework/claude/skills/sdd-roadmap/refs/review.md:25`
  review.mdではDesign Inspectors全6体にmodel=sonnetと記載。sdd-inspector-best-practicesのfrontmatterは`tools: Read, Glob, Grep, Write`（WebSearch/WebFetchなし）。しかし本文では"Research Depth (Autonomous)"セクションがあり、WebSearch使用を示唆するが、toolsリストにWebSearch/WebFetchが含まれていない。エージェント定義のtools行を更新するか、本文からリサーチ参照を削除すべき。

- [MEDIUM] **sdd-architect にWebSearch/WebFetchツールがあるが、他のDesign Inspectorにはない不均一性** / `framework/claude/agents/sdd-architect.md:6`
  Architectは`tools: Read, Glob, Grep, Write, Edit, WebSearch, WebFetch`。6つのDesign Inspectorは全て`tools: Read, Glob, Grep, Write`のみ。best-practices Inspectorは本文でリサーチ深度に言及しているが、ツールアクセスがない。これは意図的設計（InspectorはArchitectが生成したdesign.mdをレビューするのみ）である可能性が高いが、best-practices.mdの本文との不整合がある。

- [LOW] **install.sh のv0.18.0マイグレーション: agentsを.claude/sdd/settings/agents/に移動と記載** / `install.sh:361-371`
  install.shのv0.18.0マイグレーションコメントは「Agent definitions moved from .claude/agents/ to .claude/sdd/settings/agents/」と記載。その後v0.20.0で「Agent definitions moved from .claude/sdd/settings/agents/ to .claude/agents/」に戻している。最終的なインストール先は`.claude/agents/`であり正しい。マイグレーション履歴としては正確だが、コメントの記載が混乱を招く可能性がある。

- [LOW] **Profiles path: CLAUDE.md vs install.sh の差異** / `framework/claude/CLAUDE.md:120` vs `install.sh:514`
  CLAUDE.mdの Paths セクションで`Profiles: {{SDD_DIR}}/settings/profiles/`と記載。install.shは`install_dir "$SRC/framework/claude/sdd/settings/profiles" ".sdd/settings/profiles"`で正しくインストールしている。実際にプロファイルファイルは`framework/claude/sdd/settings/profiles/`に存在し、`.sdd/settings/profiles/`にインストールされる。CLAUDE.mdの`{{SDD_DIR}}/settings/profiles/`は`.sdd/settings/profiles/`に展開されるため一致している。**OK。**

- [LOW] **CLAUDE.md Wave Contextの詳細がrun.mdにあるが、CLAUDE.md自体にも概要が含まれる二重記載** / `framework/claude/CLAUDE.md:96` vs `framework/claude/skills/sdd-roadmap/refs/run.md:25-61`
  CLAUDE.md の Parallel Execution Model セクションにWave Contextの説明があり、run.md Step 2.5にも同じ情報の詳細版がある。これは「概要→詳細参照」パターンで一貫性問題ではないが、CLAUDE.mdに「Pilot Stagger seeds conventions from the first Builder group's output」とある一方、impl.mdのPilot Stagger Protocolでより詳細な手順が記載されている。記述間に矛盾はない。

- [LOW] **CPFフォーマットのcategory値が各Inspector/Auditorで統一されていない** / 各agentファイル
  - Design Inspectors: 各自固有のcategory値を使用（例: `spec-quality`, `template-drift`, `interface-contract`等）
  - Impl Inspectors: 各自固有のcategory値（例: `signature-mismatch`, `test-failure`, `error-handling-drift`等）
  - Dead-code Inspectors: 統一された値（`dead-config`, `dead-code`, `spec-drift`, `orphaned-test`）
  - Auditor dead-code: category値を明示的にリスト化（`dead-config`, `dead-code`, `spec-drift`, `orphaned-test`, `unused-import`, `stale-fixture`, `unimplemented-spec`, `false-confidence-test`）
  - Design/Impl Auditor: category値の明示的リストなし
  CPF仕様（cpf-format.md）自体にはcategory値の制約定義がなく、各agentが自由に定義している。これは柔軟性を確保する意図的設計と考えられるが、Auditorがcross-checkする際の統一性に影響する可能性がある。

### Confirmed OK

- **フェーズ名の一貫性**: `initialized`, `design-generated`, `implementation-complete`, `blocked` の4フェーズがCLAUDE.md、design.md ref、impl.md ref、run.md、revise.md、status SKILL.md、spec.yaml init templateで統一されている
- **Verdict値の一貫性**: Design Review: `GO`/`CONDITIONAL`/`NO-GO`。Impl Review: `GO`/`CONDITIONAL`/`NO-GO`/`SPEC-UPDATE-NEEDED`。Dead-code Review: `GO`/`CONDITIONAL`/`NO-GO`。全Auditorの出力フォーマットと verdict formula が review.md、run.md、CLAUDE.md間で一致
- **SubAgent名の一貫性**: CLAUDE.md、review.md、settings.json、全agent定義ファイル間でSubAgent名が完全一致。settings.jsonの`Task(sdd-xxx)`エントリは24個のagent定義ファイルと完全対応
- **Skills名の一貫性**: settings.jsonの`Skill(sdd-xxx)`エントリは6つのスキルファイルと完全対応
- **retry/counter制限**: CLAUDE.md（retry_count max 5, spec_update_count max 2, aggregate cap 6, dead-code max 3）とrun.md Phase Handlers、revise.md Step 5で値が一致
- **パス体系**: `{{SDD_DIR}}`は全ファイルで`.sdd`に展開。steering path (`{{SDD_DIR}}/project/steering/`)、specs path (`{{SDD_DIR}}/project/specs/`)、handover path (`{{SDD_DIR}}/handover/`)、rules path (`{{SDD_DIR}}/settings/rules/`)、templates path (`{{SDD_DIR}}/settings/templates/`)が全参照で一致。install.shのインストール先も対応
- **Review scope directory パス**: review.md Step 1 の4パターン（per-feature, dead-code, cross-check, wave）がverdict destination一覧（review.md最下部）と完全一致。cross-cutting verdicts pathもrevise.md Part B Step 8と一致
- **Verdict persistence format**: SKILL.md Router の Verdict Persistence Format定義がreview.md Step 8-9と一致。B{seq}採番ルール、archive rename パターンが統一
- **Consensus mode protocol**: SKILL.md Router と review.md、run.md間で active-{p}/ 命名規則、B{seq} 共有ルール、threshold計算（ceil(N*0.6)）が一致
- **Dispatch loop / Review Decomposition**: run.md の3 sub-phases（DISPATCH-INSPECTORS → INSPECTORS-COMPLETE → AUDITOR-COMPLETE）がreview.md のsequential flowの対応ステップと整合
- **Artifact Ownership**: CLAUDE.md所有権テーブルがdesign.md ref（Architectが生成）、impl.md ref（TaskGenerator/Builderが生成、Leadはtask status update のみ）、全SubAgentの「Do NOT update spec.yaml」制約と一致
- **Knowledge tags**: Builder定義の`[PATTERN]`/`[INCIDENT]`/`[REFERENCE]`タグがCLAUDE.md Knowledge Auto-Accumulation、impl.md Step 3のbuffer.md追記処理、buffer.md templateで一致
- **Handover file体系**: CLAUDE.md Handoverテーブル（session.md, decisions.md, buffer.md, sessions/）がhandover SKILL.md Step 4、session.md template、buffer.md templateと完全対応
- **Design Review Inspector セット（6体）**: review.md → `sdd-inspector-{rulebase,testability,architecture,consistency,best-practices,holistic}`。auditor-design.mdのInput Handling（6ファイル一覧）と完全一致
- **Impl Review Inspector セット（6+2体）**: review.md → `sdd-inspector-{impl-rulebase,interface,test,quality,impl-consistency,impl-holistic}` + web: `{e2e,visual}`。auditor-impl.mdのInput Handling（8ファイル一覧）と完全一致
- **Dead-code Inspector セット（4体）**: review.md → `sdd-inspector-{dead-settings,dead-code,dead-specs,dead-tests}`。auditor-dead-code.mdのInput Handling（4ファイル一覧）と完全一致
- **Spec Stagger / Design Lookahead / Wave Bypass**: CLAUDE.md Parallel Execution Model の各概念がrun.md Step 3-4の詳細実装と矛盾なく対応
- **Wave Context / Conventions Brief**: CLAUDE.md概要、run.md Step 2.5詳細、impl.md Pilot Stagger Protocol、conventions-brief.md template間で整合
- **Cross-Cutting Revision**: CLAUDE.md概要、revise.md Part B全ステップ間でターミノロジーとフローが一致。`specs/.cross-cutting/{id}/`パスがrevise.md、review.md、status SKILL.md間で統一
- **Steering Feedback Loop**: CLAUDE.md概要とreview.md Steering Feedback Loop Processing間でCODIFY/PROPOSEプロトコルが一致。Auditor CPF出力のSTEERING:セクション形式がauditor-design.md、auditor-impl.mdで統一
- **Git Workflow / Commit Timing**: CLAUDE.md Git WorkflowとCRUD.md、run.md Step 7c Post-gate、revise.md Step 9間でコミットメッセージ形式が一致
- **Template変数展開**: `{{SDD_DIR}}`、`{{SDD_VERSION}}`、`{{FEATURE_NAME}}`等のテンプレート変数がinstall.sh（SDD_VERSION置換）とspec init template（FEATURE_NAME, TIMESTAMP等）で正しく使用
- **install.sh インストールパス**: framework/claude/skills → .claude/skills、framework/claude/agents → .claude/agents、framework/claude/sdd/settings → .sdd/settings。CLAUDE.md Pathsセクションのインストール先と一致
- **Blocking Protocol**: CLAUDE.md Phase Gate → run.md Step 6 Blocking Protocol間で`blocked_info`フィールド（blocked_by, blocked_at_phase, reason）が一致。spec.yaml init template に`blocked_info: null`が含まれる
- **Phase Gate定義**: CLAUDE.md Phase Gateの3条件（appropriate phase, blocked → BLOCK, unrecognized → BLOCK）がdesign.md ref Step 2、impl.md ref Step 1で一貫して適用
- **1-Spec Roadmap Optimizations**: SKILL.md Router定義がrun.md Step 7（Skip Wave QG）、review.md Step 1（1-Spec guard for cross-check）と一致
- **DAG validation**: run.md Step 1にサイクル検出、crud.md Update Step 3/5にサイクル再検証が記載。依存グラフ整合性チェックが複数箇所で一貫して実施
- **orchestration.last_phase_action**: spec.yaml initでnull、design.md refでnull設定、impl.md refで"tasks-generated"→"implementation-complete"遷移。revise.md Step 4でnullリセット。全箇所で一貫
- **SelfCheck protocol**: Builder定義のPASS/WARN/FAIL-RETRY-2がimpl.md Step 3のSelfCheck処理、auditor-impl.mdのBuilder SelfCheck warnings入力と一致

### Cross-Reference Matrix

| Source Document | 参照先 | 参照の正確性 |
|---|---|---|
| CLAUDE.md → sdd-roadmap refs/run.md | Step 3-4 dispatch loop | OK |
| CLAUDE.md → sdd-roadmap refs/crud.md | Wave Scheduling | OK |
| CLAUDE.md → sdd-roadmap refs/revise.md Part B | Cross-Cutting Parallelism | OK |
| CLAUDE.md → sdd-roadmap refs/review.md | Steering Feedback Loop | OK |
| CLAUDE.md → cpf-format.md | CPF specification | OK |
| SKILL.md Router → refs/design.md | Design subcommand | OK |
| SKILL.md Router → refs/impl.md | Impl subcommand | OK |
| SKILL.md Router → refs/review.md | Review subcommand | OK |
| SKILL.md Router → refs/run.md | Run mode | OK |
| SKILL.md Router → refs/revise.md | Revise mode | OK |
| SKILL.md Router → refs/crud.md | Create/Update/Delete | OK |
| refs/design.md → sdd-architect agent | Architect dispatch | OK |
| refs/impl.md → sdd-taskgenerator agent | TaskGenerator dispatch | OK |
| refs/impl.md → sdd-builder agent | Builder dispatch | OK |
| refs/impl.md → run.md Step 2.5 | Conventions brief | OK |
| refs/review.md → 6 design inspector agents | Inspector dispatch | OK |
| refs/review.md → 8 impl inspector agents | Inspector dispatch | OK |
| refs/review.md → 4 dead-code inspector agents | Inspector dispatch | OK |
| refs/review.md → 3 auditor agents | Auditor dispatch | OK |
| refs/run.md → refs/design.md | Phase Handler Design | OK |
| refs/run.md → refs/impl.md | Phase Handler Impl | OK |
| refs/run.md → refs/review.md | Phase Handler Review | OK |
| refs/run.md → CLAUDE.md Auto-Fix Counter Limits | Counter handling | OK |
| refs/revise.md → refs/design.md | Revision pipeline Design | OK |
| refs/revise.md → refs/impl.md | Revision pipeline Impl | OK |
| refs/revise.md → refs/review.md | Revision pipeline Review | OK |
| refs/revise.md → refs/crud.md | Restructuring Check | OK |
| refs/revise.md → run.md Dispatch Loop | Tier execution | OK |
| sdd-steering SKILL → steering-principles.md | Principles reference | OK |
| sdd-steering SKILL → templates/steering/ | Template reference | OK |
| sdd-steering SKILL → templates/steering-custom/ | Custom template reference | OK |
| sdd-steering SKILL → settings/profiles/ | Profile reference | OK |
| sdd-architect → design-principles.md | Design rules | OK |
| sdd-architect → design-discovery-full.md | Full discovery | OK |
| sdd-architect → design-discovery-light.md | Light discovery | OK |
| sdd-architect → templates/specs/design.md | Design template | OK |
| sdd-architect → templates/specs/research.md | Research template | OK |
| sdd-taskgenerator → tasks-generation.md | Task rules | OK |
| sdd-handover SKILL → templates/handover/session.md | Session template | OK |
| All inspectors → design-review.md | Review rules | OK (referenced by rulebase+testability) |
| install.sh → framework/ file structure | Install mapping | OK |
| settings.json → all agent/skill files | Permission mapping | OK |

### Overall Assessment

フレームワーク全体の一貫性は**非常に高い水準**にある。Phase名、Verdict値、SubAgent名、パス体系、カウンター制限、プロトコル記述が全ファイル間で統一されており、致命的な矛盾や到達不能パスは検出されなかった。

検出された問題は全てMEDIUM以下であり、運用に影響するCRITICAL/HIGHレベルの不整合は存在しない。

**要対応（MEDIUM）**:
1. sdd-inspector-best-practices のfrontmatter `tools`行にWebSearch/WebFetchが含まれていないが、本文でリサーチ深度に言及している点 → toolsを追加するか、本文を修正
2. CLAUDE.md「Commands (5)」がsdd-review-selfを含まない点の明示化 → 「User Commands (5)」等に変更、またはsdd-review-selfを注記に追加することを検討

**情報提供（LOW）**: CPFのcategory値標準化、install.shマイグレーションコメントの整理は将来的な改善候補。
