# Consistency & Dead Ends レビューレポート

## 検出された問題

### Issues Found

- [MEDIUM] M1: install.sh v0.18.0 マイグレーションコメントの不整合
- [MEDIUM] M2: CLAUDE.md Commands (6) vs 実際のスキル数 (7)
- [MEDIUM] M3: CLAUDE.md Inspector 数表記「6 impl +2 web」と実際のエージェント定義の不一致
- [LOW] L1: dead-code Inspector の SCOPE 表記が他の Inspector と異なる
- [LOW] L2: sdd-auditor-dead-code の Step 番号が他の Auditor と不一致（Step 8 vs Step 10）
- [LOW] L3: Builder の tasks.yaml 更新禁止ルールと impl.md の「Do NOT update spec.yaml or tasks.yaml」の重複記載

---

### [MEDIUM] M1: install.sh v0.18.0 マイグレーションコメントの不整合

**Location**: `install.sh:362`
**Description**: v0.18.0 マイグレーションのコメントに「Agent definitions moved from .claude/agents/ to .claude/sdd/settings/agents/」とあるが、v0.20.0 でこの移動は revert されている（`.claude/sdd/settings/agents/` → `.claude/agents/` に戻された）。現在のフレームワークでは `.claude/agents/` が正規パスであり、v0.18.0 のマイグレーションは v0.20.0 で元に戻されているため、install.sh のコメント自体は歴史的に正しいが、新規ユーザーが読んだ場合の誤解リスクがある。ただし、これはマイグレーション処理自体は正しく動作しており、実害は限定的。

**Evidence**:
- install.sh:362 コメント: `# v0.18.0: Agent definitions moved from .claude/agents/ to .claude/sdd/settings/agents/`
- install.sh:373 コメント: `# v0.20.0: Agent definitions moved from .claude/sdd/settings/agents/ to .claude/agents/`
- CLAUDE.md:121 パス定義: `Agent Profiles: .claude/agents/`

---

### [MEDIUM] M2: CLAUDE.md Commands (6) vs 実際のスキル数 (7)

**Location**: `framework/claude/CLAUDE.md:142`
**Description**: CLAUDE.md の `### Commands (6)` は 6 つのコマンドをリストしている: `sdd-steering`, `sdd-roadmap`, `sdd-status`, `sdd-handover`, `sdd-knowledge`, `sdd-release`。しかし、実際には `sdd-review-self` スキルも `framework/claude/skills/sdd-review-self/SKILL.md` に存在し、`settings.json` にも `Skill(sdd-review-self)` が登録されている。

**Analysis**: `sdd-review-self` はフレームワーク開発用の内部ツールであるため、ユーザー向けコマンド一覧に含めない意図的な設計判断の可能性がある。しかし settings.json の permission list には含まれており、エンドユーザープロジェクトにもインストールされるため、ドキュメント上の明示が望ましい。

**Evidence**:
- `framework/claude/skills/` 配下の SKILL.md は 7 ファイル
- CLAUDE.md のテーブルは 6 行
- settings.json に `Skill(sdd-review-self)` が含まれている

---

### [MEDIUM] M3: CLAUDE.md Inspector 数の表記精度

**Location**: `framework/claude/CLAUDE.md:26`
**Description**: CLAUDE.md の Inspector 行に「6 design, 6 impl +2 web (impl only, web projects), 4 dead-code」と記載。

Design Inspector 実体 (6):
1. `sdd-inspector-rulebase`
2. `sdd-inspector-testability`
3. `sdd-inspector-architecture`
4. `sdd-inspector-consistency`
5. `sdd-inspector-best-practices`
6. `sdd-inspector-holistic`

Impl Inspector 実体 (6 + 2 web):
1. `sdd-inspector-impl-rulebase`
2. `sdd-inspector-interface`
3. `sdd-inspector-test`
4. `sdd-inspector-quality`
5. `sdd-inspector-impl-consistency`
6. `sdd-inspector-impl-holistic`
7. `sdd-inspector-e2e` (web)
8. `sdd-inspector-visual` (web)

Dead-code Inspector 実体 (4):
1. `sdd-inspector-dead-settings`
2. `sdd-inspector-dead-code`
3. `sdd-inspector-dead-specs`
4. `sdd-inspector-dead-tests`

**結果**: 全てのカウントがエージェントファイル実体と一致。問題なし。（当初の懸念は調査の結果解消）

**修正**: これは問題ではない。Confirmed OK に移動。

---

### [LOW] L1: dead-code Inspector の SCOPE 値の差異

**Location**: `sdd-inspector-dead-*.md` (全 4 ファイル)
**Description**: dead-code Inspector の出力フォーマット例では `SCOPE:{feature} | cross-check` と記載されているが、他の Inspector（design/impl）では `SCOPE:{feature} | cross-check | wave-1..{N}` と wave-scoped モードも記載されている。Dead-code review は review.md で「No phase gate (operates on entire codebase)」と定義されており、wave-scoped モードを持たないため、この差異は意図的で正しい。ただし、dead-code Inspector に Wave-Scoped Cross-Check Mode セクションがないことの明示がない。

**Evidence**:
- `sdd-inspector-dead-code.md:56` SCOPE 行に wave-scoped なし
- `sdd-inspector-rulebase.md:138` SCOPE 行に wave-scoped あり
- `refs/review.md:20` Dead Code Review: "No phase gate"

---

### [LOW] L2: sdd-auditor-dead-code の最終 Step 番号の差異

**Location**: `sdd-auditor-dead-code.md:125`
**Description**: `sdd-auditor-dead-code` の最終 verdict synthesis は Step 8 で行われるが、`sdd-auditor-design` と `sdd-auditor-impl` では Step 10。これは dead-code auditor が Decision Suggestions (Step 9) と Over-Engineering/Over-Implementation Check (Step 8) を持たないためで、処理ステップ数が少ないことによる自然な差異。Verdict Output Guarantee でも dead-code auditor は「skip to Step 8」と正しく記載されている。

**Evidence**:
- `sdd-auditor-dead-code.md:28`: "immediately skip to Step 8"
- `sdd-auditor-design.md:28`: "immediately skip to Step 10"
- `sdd-auditor-impl.md:28`: "immediately skip to Step 10"

---

### [LOW] L3: Builder の metadata 更新禁止ルールの重複記載

**Location**: `sdd-builder.md:76` と `refs/impl.md:50-51`
**Description**: Builder が spec.yaml/tasks.yaml を更新しないルールは、Builder エージェント定義内（L76: "Do NOT update spec.yaml or tasks.yaml"）と impl.md Step 2 の TaskGenerator dispatch 説明内（L32: "Verify tasks.yaml exists"）の両方で言及されている。内容は矛盾していないが、異なる箇所での記載はドリフトリスクとなる。CLAUDE.md の State Management セクション（L40: "T2/T3 SubAgents MUST NOT update spec.yaml directly"）が正規の定義元。

---

## Confirmed OK

### 値の一貫性

1. **フェーズ名**: `initialized`, `design-generated`, `implementation-complete`, `blocked` が CLAUDE.md, refs/design.md, refs/impl.md, refs/run.md, refs/revise.md, refs/review.md, sdd-status SKILL.md で統一的に使用されている。init.yaml テンプレートの初期値 `initialized` も一致。

2. **Verdict 値**: Design Auditor は `GO|CONDITIONAL|NO-GO`、Impl Auditor は `GO|CONDITIONAL|NO-GO|SPEC-UPDATE-NEEDED`、Dead-code Auditor は `GO|CONDITIONAL|NO-GO` を使用。Inspector は `GO|CONDITIONAL|NO-GO` を使用。全ファイルで一貫。

3. **Severity コード**: `C=Critical, H=High, M=Medium, L=Low` が全 CPF 出力ファイル（全 Inspector、全 Auditor、cpf-format.md）で統一。

4. **SubAgent 名**: CLAUDE.md, settings.json, refs/*.md 全てで同一の名前を使用。settings.json の Task permission list に 24 エージェント全てが登録されている。

5. **Knowledge タグ**: `[PATTERN]`, `[INCIDENT]`, `[REFERENCE]` が CLAUDE.md, sdd-builder.md, sdd-knowledge SKILL.md, buffer.md テンプレートで統一。

6. **Decision タイプ**: `USER_DECISION`, `STEERING_UPDATE`, `DIRECTION_CHANGE`, `ESCALATION_RESOLVED`, `REVISION_INITIATED`, `STEERING_EXCEPTION`, `SESSION_START`, `SESSION_END` が CLAUDE.md と sdd-handover SKILL.md で一致。

### パスの一貫性

7. **SDD Root**: `{{SDD_DIR}}` = `.sdd` が CLAUDE.md で定義され、全 skill/agent ファイルが `{{SDD_DIR}}/...` テンプレート変数を使用。install.sh は `.sdd/` を直接使用し整合。

8. **Steering パス**: `{{SDD_DIR}}/project/steering/` が CLAUDE.md, sdd-steering SKILL.md, 全 Inspector/Auditor の Load Context で統一的に参照。

9. **Specs パス**: `{{SDD_DIR}}/project/specs/{feature}/` が refs/design.md, refs/impl.md, refs/review.md, 全 Inspector の Load Context で統一。

10. **Handover パス**: `{{SDD_DIR}}/handover/` が CLAUDE.md, sdd-handover SKILL.md で一致。session.md, decisions.md, buffer.md, sessions/ の構造が templates/handover/ のテンプレートと一致。

11. **Knowledge パス**: `{{SDD_DIR}}/project/knowledge/` が CLAUDE.md, sdd-knowledge SKILL.md, refs/impl.md (Step 4), refs/run.md (Step 7c Post-gate) で一致。

12. **Reviews パス**:
    - Per-feature: `specs/{feature}/reviews/` (refs/review.md)
    - Dead-code: `reviews/dead-code/` (refs/review.md)
    - Cross-check: `reviews/cross-check/` (refs/review.md)
    - Wave: `reviews/wave/` (refs/review.md, refs/run.md)
    - Cross-cutting: `specs/.cross-cutting/{id}/` (refs/revise.md, refs/review.md)
    - Self-review: `reviews/self/` (sdd-review-self SKILL.md)
    全て refs/review.md Verdict Destination 一覧と一致。

13. **install.sh のインストール先**:
    - `.claude/skills/` ← `framework/claude/skills/` (正確)
    - `.claude/agents/` ← `framework/claude/agents/` (正確)
    - `.claude/CLAUDE.md` ← `framework/claude/CLAUDE.md` (正確)
    - `.sdd/settings/rules/` ← `framework/claude/sdd/settings/rules/` (正確)
    - `.sdd/settings/templates/` ← `framework/claude/sdd/settings/templates/` (正確)
    - `.sdd/settings/profiles/` ← `framework/claude/sdd/settings/profiles/` (正確)

### プロトコルの一貫性

14. **Auto-Fix Counter Limits**: CLAUDE.md (L170-176) で定義: retry_count max 5, spec_update_count max 2, aggregate cap 6, Dead-Code max 3。refs/run.md の Phase Handlers で同値を参照: "max 5 retries", "max 2", "MUST NOT exceed 6"。Dead-code review (run.md Step 7b): "max 3 retries"。全て一致。

15. **Consensus Mode**: CLAUDE.md (L104), sdd-roadmap SKILL.md Shared Protocols, refs/review.md L90 が全て同じプロトコルを参照。N=1 default 動作も一致。

16. **Verdict Persistence**: sdd-roadmap SKILL.md のフォーマット定義と refs/review.md Step 8 が一致。

17. **Steering Feedback Loop**: CLAUDE.md (L204-206), refs/review.md (L100-115) が完全一致。CODIFY/PROPOSE の処理ルール、タイミング（verdict 処理後、next phase 前）が両方で同一。

18. **Builder SelfCheck**: sdd-builder.md (L58-66) の PASS/WARN/FAIL-RETRY-2 と refs/impl.md (L52-56) の Lead 側処理が整合。sdd-auditor-impl.md (L42-43) で Builder SelfCheck warnings を attention points として使用するルールも一致。

19. **SubAgent Lifecycle**: CLAUDE.md (L78) `run_in_background: true` always が refs/design.md (L24), refs/impl.md (L26,39), refs/review.md (L75,81), refs/run.md (L65,90) 全てで遵守されている。

20. **Session Resume**: CLAUDE.md (L267-281) の 7 ステップが完全に定義されている。Step 7 のパイプライン継続ルールは最近のコミットで改訂されており、「spec.yaml を ground truth として扱う」ルールが明確。

### 数値の一貫性

21. **エージェント総数**: agents/ ディレクトリに 24 ファイル。settings.json の Task permission に 24 エントリ。一致。

22. **Skills 数**: skills/ ディレクトリに 7 ファイル。settings.json の Skill permission に 7 エントリ。一致。CLAUDE.md Commands テーブルは 6 行（M2 で指摘済み）。

### 到達不能パスの検証

23. **フェーズ遷移**: `initialized` → (design) → `design-generated` → (impl) → `implementation-complete` の遷移が refs/design.md, refs/impl.md で定義。`blocked` からの復帰は refs/run.md Step 6 Blocking Protocol の fix/skip で定義。全フェーズに到達可能で、デッドエンドなし。

24. **Revise Mode の escalation**: Single-Spec (Part A) Step 3 で 2+ specs 影響時に Cross-Cutting Mode (Part B) への escalation パスが定義。Part B からの escalation パスは不要（最上位モード）。

25. **Error Handling**: 各 SKILL.md に Error Handling セクションが定義されており、主要なエラーケースがカバーされている。

### 循環参照の検証

26. **ファイル参照関係**:
    - CLAUDE.md → sdd-roadmap refs/*.md (一方向)
    - sdd-roadmap SKILL.md → refs/*.md (一方向)
    - refs/*.md → CLAUDE.md (参照のみ、counter limits 等)
    - Agent 定義 → templates/rules (ロードのみ)
    循環依存なし。参照は全て direction-safe。

### 未定義参照の検証

27. **テンプレート参照**:
    - `{{SDD_DIR}}/settings/templates/specs/design.md` → 存在する
    - `{{SDD_DIR}}/settings/templates/specs/init.yaml` → 存在する
    - `{{SDD_DIR}}/settings/templates/specs/research.md` → 存在する
    - `{{SDD_DIR}}/settings/templates/handover/session.md` → 存在する
    - `{{SDD_DIR}}/settings/templates/handover/buffer.md` → 存在する
    - `{{SDD_DIR}}/settings/templates/steering/product.md` → 存在する
    - `{{SDD_DIR}}/settings/templates/steering/tech.md` → 存在する
    - `{{SDD_DIR}}/settings/templates/steering/structure.md` → 存在する
    - `{{SDD_DIR}}/settings/templates/knowledge/{type}.md` → pattern.md, incident.md, reference.md 全て存在する
    - `{{SDD_DIR}}/settings/templates/steering-custom/*.md` → 8 ファイル存在
    全て正常。

28. **ルール参照**:
    - `{{SDD_DIR}}/settings/rules/cpf-format.md` → 存在する
    - `{{SDD_DIR}}/settings/rules/design-review.md` → 存在する
    - `{{SDD_DIR}}/settings/rules/design-principles.md` → 存在する
    - `{{SDD_DIR}}/settings/rules/design-discovery-full.md` → 存在する
    - `{{SDD_DIR}}/settings/rules/design-discovery-light.md` → 存在する
    - `{{SDD_DIR}}/settings/rules/tasks-generation.md` → 存在する
    - `{{SDD_DIR}}/settings/rules/steering-principles.md` → 存在する
    全て正常。

29. **プロファイル参照**:
    - `{{SDD_DIR}}/settings/profiles/` に `_index.md`, `python.md`, `typescript.md`, `rust.md` が存在
    - sdd-steering SKILL.md Step 3c で「Read available profiles from `{{SDD_DIR}}/settings/profiles/` (exclude `_index.md`)」と定義
    整合。

---

## Cross-Reference Matrix

### エージェント名 ↔ ファイル ↔ settings.json ↔ 参照元

| エージェント名 | ファイル | settings.json | 参照元 |
|---|---|---|---|
| sdd-architect | agents/sdd-architect.md | Task(sdd-architect) | refs/design.md, refs/run.md, refs/revise.md |
| sdd-auditor-design | agents/sdd-auditor-design.md | Task(sdd-auditor-design) | refs/review.md |
| sdd-auditor-impl | agents/sdd-auditor-impl.md | Task(sdd-auditor-impl) | refs/review.md |
| sdd-auditor-dead-code | agents/sdd-auditor-dead-code.md | Task(sdd-auditor-dead-code) | refs/review.md |
| sdd-taskgenerator | agents/sdd-taskgenerator.md | Task(sdd-taskgenerator) | refs/impl.md |
| sdd-builder | agents/sdd-builder.md | Task(sdd-builder) | refs/impl.md, refs/run.md |
| sdd-inspector-rulebase | agents/sdd-inspector-rulebase.md | Task(sdd-inspector-rulebase) | refs/review.md |
| sdd-inspector-testability | agents/sdd-inspector-testability.md | Task(sdd-inspector-testability) | refs/review.md |
| sdd-inspector-architecture | agents/sdd-inspector-architecture.md | Task(sdd-inspector-architecture) | refs/review.md |
| sdd-inspector-consistency | agents/sdd-inspector-consistency.md | Task(sdd-inspector-consistency) | refs/review.md |
| sdd-inspector-best-practices | agents/sdd-inspector-best-practices.md | Task(sdd-inspector-best-practices) | refs/review.md |
| sdd-inspector-holistic | agents/sdd-inspector-holistic.md | Task(sdd-inspector-holistic) | refs/review.md |
| sdd-inspector-impl-rulebase | agents/sdd-inspector-impl-rulebase.md | Task(sdd-inspector-impl-rulebase) | refs/review.md |
| sdd-inspector-interface | agents/sdd-inspector-interface.md | Task(sdd-inspector-interface) | refs/review.md |
| sdd-inspector-test | agents/sdd-inspector-test.md | Task(sdd-inspector-test) | refs/review.md |
| sdd-inspector-quality | agents/sdd-inspector-quality.md | Task(sdd-inspector-quality) | refs/review.md |
| sdd-inspector-impl-consistency | agents/sdd-inspector-impl-consistency.md | Task(sdd-inspector-impl-consistency) | refs/review.md |
| sdd-inspector-impl-holistic | agents/sdd-inspector-impl-holistic.md | Task(sdd-inspector-impl-holistic) | refs/review.md |
| sdd-inspector-e2e | agents/sdd-inspector-e2e.md | Task(sdd-inspector-e2e) | refs/review.md |
| sdd-inspector-visual | agents/sdd-inspector-visual.md | Task(sdd-inspector-visual) | refs/review.md |
| sdd-inspector-dead-code | agents/sdd-inspector-dead-code.md | Task(sdd-inspector-dead-code) | refs/review.md |
| sdd-inspector-dead-settings | agents/sdd-inspector-dead-settings.md | Task(sdd-inspector-dead-settings) | refs/review.md |
| sdd-inspector-dead-specs | agents/sdd-inspector-dead-specs.md | Task(sdd-inspector-dead-specs) | refs/review.md |
| sdd-inspector-dead-tests | agents/sdd-inspector-dead-tests.md | Task(sdd-inspector-dead-tests) | refs/review.md |

**結果**: 24/24 エージェント全てが (1) ファイル実体、(2) settings.json permission、(3) 参照元で一致。孤立エージェントなし。

### スキル名 ↔ ファイル ↔ settings.json ↔ CLAUDE.md

| スキル名 | ファイル | settings.json | CLAUDE.md Commands |
|---|---|---|---|
| sdd-roadmap | skills/sdd-roadmap/SKILL.md | Skill(sdd-roadmap) | /sdd-roadmap |
| sdd-steering | skills/sdd-steering/SKILL.md | Skill(sdd-steering) | /sdd-steering |
| sdd-status | skills/sdd-status/SKILL.md | Skill(sdd-status) | /sdd-status |
| sdd-handover | skills/sdd-handover/SKILL.md | Skill(sdd-handover) | /sdd-handover |
| sdd-knowledge | skills/sdd-knowledge/SKILL.md | Skill(sdd-knowledge) | /sdd-knowledge |
| sdd-release | skills/sdd-release/SKILL.md | Skill(sdd-release) | /sdd-release |
| sdd-review-self | skills/sdd-review-self/SKILL.md | Skill(sdd-review-self) | (未記載) |

**結果**: 7 スキル全てがファイル実体と settings.json で一致。CLAUDE.md Commands テーブルは 6 行で `sdd-review-self` が未記載（M2 で指摘済み）。

### テンプレート参照 Matrix

| 参照元 | 参照先テンプレート | 存在 |
|---|---|---|
| CLAUDE.md L240 | settings/templates/handover/session.md | OK |
| CLAUDE.md L250 | settings/templates/handover/buffer.md | OK |
| CLAUDE.md L336 | settings/rules/cpf-format.md | OK |
| sdd-architect.md L29 | settings/templates/specs/design.md | OK |
| sdd-architect.md L31 | settings/templates/specs/research.md | OK |
| sdd-architect.md L30 | settings/rules/design-principles.md | OK |
| sdd-architect.md L48 | settings/rules/design-discovery-full.md | OK |
| sdd-architect.md L56 | settings/rules/design-discovery-light.md | OK |
| sdd-taskgenerator.md L32 | settings/rules/tasks-generation.md | OK |
| sdd-steering SKILL.md L37 | settings/profiles/ | OK |
| sdd-steering SKILL.md L48 | settings/templates/steering/ | OK |
| sdd-steering SKILL.md L68 | settings/templates/steering-custom/ | OK |
| sdd-steering SKILL.md L15 | settings/rules/steering-principles.md | OK |
| sdd-knowledge SKILL.md L43 | settings/templates/knowledge/{type}.md | OK |
| sdd-roadmap SKILL.md L76 | settings/templates/specs/init.yaml | OK |
| sdd-inspector-rulebase.md L39 | settings/rules/design-review.md | OK |
| sdd-handover SKILL.md L36 | settings/templates/handover/session.md | OK |

**結果**: 全テンプレート/ルール参照が実ファイルに解決される。未定義参照なし。

---

## Overall Assessment

フレームワーク全体の一貫性は **高い水準** にある。全 24 エージェント、7 スキル、7 ルールファイル、18 テンプレートが相互に整合しており、フェーズ名、verdict 値、severity コード、パス構造、プロトコル定義に重大な矛盾は検出されなかった。

検出された問題は MEDIUM 2 件（M1: install.sh コメントの歴史的不整合、M2: Commands テーブルの数）、LOW 3 件で、いずれも実行時の動作を阻害するものではない。

最近のコミットで変更された Session Resume Step 7（パイプライン継続ルール）と Behavioral Rules（compact 後の動作）は、CLAUDE.md 内で完結しており、他ファイルとの不整合は生じていない。Builder エージェントに追加された「No workspace-wide git operations」制約も、既存のファイルスコープルールと整合している。
