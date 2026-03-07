# Regression Detection Report

## 対象コミット

| コミット | 概要 |
|---------|------|
| `6a0a69b` | SDD data root を `.claude/sdd/` から `.sdd/` に移動 (v1.2.0) |
| `dd14ce8` | acceptEdits モード追加 (v1.1.2) |
| `c81d77a` | settings.json 権限精査 + プロファイル構文修正 (v1.1.1) |
| `c463c91` | Cross-cutting revision support (v1.1.0) |
| `ea1a23e` | E2E Inspector を functional (E2E) と visual (Visual) に分割 (v1.0.4) |

**未コミット変更**:
- `framework/claude/CLAUDE.md`: Session Resume Step 7 改訂、Behavioral Rules の compact 時動作改訂
- `framework/claude/agents/sdd-builder.md`: workspace-wide git 操作禁止制約を追加

---

## 検証結果サマリー

| 重要度 | 件数 | 説明 |
|--------|------|------|
| CRITICAL | 0 | - |
| HIGH | 0 | - |
| MEDIUM | 1 | `design-discovery-full.md` に旧セクション名残 |
| LOW | 0 | - |

---

## Issues Found

### [MEDIUM] M1: `design-discovery-full.md` のセクション名不一致

**場所**: `framework/claude/sdd/settings/rules/design-discovery-full.md:91`

**内容**: v1.1.1 (c81d77a) で `Components & Interfaces` を `Components and Interfaces` にリネームした際、`design-principles.md` と `design-review.md` と `design template` は修正されたが、`design-discovery-full.md` の以下の行が未修正:

```
- Updated domain boundaries that inform Components & Interface Contracts
```

他の全ファイルでは `Components and Interfaces` に統一済み:
- `framework/claude/sdd/settings/templates/specs/design.md:117`: `## Components and Interfaces`
- `framework/claude/sdd/settings/rules/design-principles.md:68`: `Components and Interfaces`
- `framework/claude/sdd/settings/rules/design-principles.md:96`: `### Components and Interfaces Authoring`
- `framework/claude/sdd/settings/rules/design-review.md:31`: `Has Components and Interfaces section`
- `framework/claude/agents/sdd-inspector-rulebase.md:56`: `Has Components and Interfaces section`

**影響**: Architect が Full Discovery Process を実行する際、セクション名の微妙な不一致が混乱を招く可能性がある。ただし "Components & Interface Contracts" はフリーテキスト（セクションヘッダへの直接参照ではない）のため、実際のフロー阻害リスクは低い。

---

## Confirmed OK

### 1. `.claude/sdd/` から `.sdd/` への移行完全性

v1.2.0 (6a0a69b) で SDD data root を `.claude/sdd/` から `.sdd/` に移動。以下を検証:

- **CLAUDE.md**: `{{SDD_DIR}}` = `.sdd` に更新済み (L113)
- **install.sh**: 全パスが `.sdd/` に更新済み (install先、help表示、uninstall、migration)
- **install.sh migration**: v1.2.0 migration セクションあり (settings, project, handover の移動 + .version の移動)
- **install.sh version check**: `.sdd/.version` を優先チェック、fallback で `.claude/sdd/.version` もチェック
- **install.sh uninstall**: `.sdd/` 側と `.claude/sdd/` 側の両方をクリーンアップ
- **steering-principles.md**: `.sdd/` パスに更新済み (L25, L80)
- **framework/ 内の `.claude/sdd` 参照**: 0件 (grep で確認済み)

**判定**: 完全。残存参照なし。

### 2. E2E/Visual Inspector 分割の完全性

v1.0.4 (ea1a23e) で `sdd-inspector-e2e` を functional (E2E) と visual (Visual) に分割。

- **新エージェント `sdd-inspector-visual.md`**: 作成済み、正しい frontmatter
- **`sdd-inspector-e2e.md`**: visual 関連の責務を除去、functional テストに特化
- **`sdd-auditor-impl.md`**: Inspector リスト更新 (7→8個)、E2E/Visual クロスチェックルール追加
- **`refs/review.md`**: Web Inspector Server Protocol 追加、Impl Review セクションで `sdd-inspector-visual` 追加
- **Review Execution Flow**: Step 3a (server start)、Step 5a (server stop) 追加
- **settings.json**: `Task(sdd-inspector-visual)` 追加済み
- **`ui.md` テンプレート**: 参照先を `sdd-inspector-visual` に更新
- **CLAUDE.md Inspector 記述**: `6 impl +2 web (impl only, web projects), 4 dead-code` に更新

**判定**: 完全。旧 E2E の visual 責務は全て Visual Inspector に移行済み。

### 3. settings.json 権限精査 (v1.1.1/v1.1.2)

- **defaultMode**: `acceptEdits` 追加 (v1.1.2)
- **Skill 許可**: 7 skills (sdd-roadmap, sdd-steering, sdd-status, sdd-handover, sdd-knowledge, sdd-release, sdd-review-self)
- **Task 許可**: 24 agents 全てカバー (sdd-architect, 3 auditors, sdd-builder, 18 inspectors, sdd-taskgenerator)
- **Bash 許可**: git, mkdir, ls, mv, cp, wc, which, diff, playwright-cli, npm, npx
- **プロファイル構文修正**: `Bash(uv:*)` → `Bash(uv *)` (python.md)、rust.md、typescript.md 同様

**判定**: 完全。全 agent/skill がカバーされている。

### 4. Cross-cutting revision (v1.1.0) の完全性

- **refs/revise.md**: Part B (Cross-Cutting Mode) 全ステップ完備 (Step 1-9)
- **CLAUDE.md**: Cross-Cutting Parallelism 項目追加、`refs/revise.md` Part B 参照
- **SKILL.md router**: Revise Mode detection に Single-Spec / Cross-Cutting の分岐あり
- **decisions.md**: `REVISION_INITIATED` に `(cross-cutting)` 付与ルール記載
- **commit message format**: `cross-cutting: {summary}` 追加
- **sdd-status SKILL.md**: Cross-Cutting Revisions セクション追加
- **Verdict destination**: `specs/.cross-cutting/{id}/verdicts.md` 追加

**判定**: 完全。

### 5. 未コミット変更の整合性

#### Session Resume Step 7 改訂

旧: "Resume from session.md Immediate Next Action (or await user instruction if first session)"
新: pipeline が active なら spec.yaml を ground truth として continue、そうでなければ await user instruction

- **Behavioral Rules**: compact 時の動作も整合的に改訂 (pipeline active → Session Resume 1-6 実行後 continue、非 pipeline → user 指示待ち)
- `run.md` の Pipeline Stop Protocol / Resume との整合: `run.md` は「`/sdd-roadmap run` scans all `spec.yaml` files to rebuild pipeline state and resumes」と記述しており、Step 7 の「spec.yaml as ground truth」方針と整合

**判定**: 整合。旧 Step 7 の内容は新 Step 7 に完全に包含されている（より詳細になった）。

#### Builder の git 操作制約追加

新規制約: `git stash`, `git checkout .`, `git restore .`, `git reset`, `git clean` を禁止
- File Scope Rules セクションと整合（scope 外ファイルへの副作用を防ぐ目的）
- 既存の "File Scope: Stay within your assigned file scope" 制約の補強

**判定**: 新規追加。既存内容との矛盾なし。

### 6. テンプレート参照の健全性

CLAUDE.md が参照するテンプレートの存在確認:

| 参照元 | テンプレートパス | 存在 |
|--------|-----------------|------|
| CLAUDE.md L240 | `{{SDD_DIR}}/settings/templates/handover/session.md` | OK |
| CLAUDE.md L250 | `{{SDD_DIR}}/settings/templates/handover/buffer.md` | OK |
| CLAUDE.md L336 | `{{SDD_DIR}}/settings/rules/cpf-format.md` | OK |
| sdd-steering L48 | `{{SDD_DIR}}/settings/templates/steering/*` | OK (product.md, tech.md, structure.md) |
| sdd-steering L68 | `{{SDD_DIR}}/settings/templates/steering-custom/*` | OK (7 files) |
| sdd-roadmap L76 | `{{SDD_DIR}}/settings/templates/specs/init.yaml` | OK |
| sdd-architect L29 | `{{SDD_DIR}}/settings/templates/specs/design.md` | OK |
| sdd-architect L31 | `{{SDD_DIR}}/settings/templates/specs/research.md` | OK |
| sdd-architect L48 | `{{SDD_DIR}}/settings/rules/design-discovery-full.md` | OK |
| sdd-architect L57 | `{{SDD_DIR}}/settings/rules/design-discovery-light.md` | OK |
| sdd-architect L28 | `{{SDD_DIR}}/settings/rules/design-principles.md` | OK |
| sdd-taskgenerator L32 | `{{SDD_DIR}}/settings/rules/tasks-generation.md` | OK |
| sdd-steering L15 | `{{SDD_DIR}}/settings/rules/steering-principles.md` | OK |
| sdd-knowledge L43 | `{{SDD_DIR}}/settings/templates/knowledge/{type}.md` | OK (pattern.md, incident.md, reference.md) |

**判定**: 全テンプレート/ルール参照が健全。

### 7. プロトコル完全性

| プロトコル | 定義場所 | 処理ルール場所 | 完全性 |
|-----------|---------|--------------|--------|
| Phase Gate | CLAUDE.md §Phase Gate | design.md Step 2, impl.md Step 1, revise.md Step 1 | OK |
| SubAgent Lifecycle | CLAUDE.md §SubAgent Lifecycle | run.md Step 4, review.md Step 4-6 | OK |
| Verdict Persistence | SKILL.md §Verdict Persistence Format | review.md Step 7-9 | OK |
| Consensus Mode | SKILL.md §Consensus Mode | review.md (末尾参照) | OK |
| Auto-Fix Counter | CLAUDE.md §Auto-Fix Counter Limits | run.md Step 4 Phase Handlers | OK |
| Blocking Protocol | run.md Step 6 | run.md Step 6 (自己完結) | OK |
| Wave Quality Gate | run.md Step 7 | run.md Step 7a-c (自己完結) | OK |
| Web Inspector Server Protocol | review.md §Web Inspector Server Protocol | review.md Step 3a, 5a | OK |
| Steering Feedback Loop | CLAUDE.md §Steering Feedback Loop | review.md §Steering Feedback Loop Processing | OK |
| Pipeline Stop Protocol | CLAUDE.md §Pipeline Stop Protocol | run.md (Resume 記述) | OK |
| Session Resume | CLAUDE.md §Session Resume | CLAUDE.md Steps 1-7 (自己完結) | OK |
| Knowledge Auto-Accumulation | CLAUDE.md §Knowledge Auto-Accumulation | impl.md Step 4, run.md Step 7c Post-gate | OK |
| Cross-Cutting Revision | revise.md Part B | revise.md Steps 1-9 (自己完結) | OK |
| Decision Recording | CLAUDE.md §decisions.md Recording | handover SKILL.md Step 4 | OK |

**判定**: 全プロトコルの処理ルールが少なくとも1箇所に完全に記述されている。

### 8. Dangling Reference チェック

| 参照テキスト | 参照先 | 存在確認 |
|-------------|--------|---------|
| "see sdd-roadmap `refs/run.md`" (CLAUDE.md L82, L97, L176) | refs/run.md | OK |
| "see sdd-roadmap `refs/crud.md`" (CLAUDE.md L88) | refs/crud.md | OK |
| "see sdd-roadmap `refs/revise.md` Part B" (CLAUDE.md L95) | refs/revise.md Part B | OK |
| "see sdd-roadmap `refs/review.md`" (CLAUDE.md L206) | refs/review.md §Steering Feedback Loop Processing | OK |
| "see Router" (refs/run.md L162) | SKILL.md §Verdict Persistence Format | OK |
| "see Router" (refs/run.md L118, L134) | SKILL.md §Consensus Mode | OK |
| "per `refs/design.md`" (run.md L106) | refs/design.md | OK |
| "per `refs/review.md`" (run.md L109, L124, L167) | refs/review.md | OK |
| "per `refs/impl.md`" (run.md L121) | refs/impl.md | OK |
| "See Artifact Ownership" (CLAUDE.md L300) | CLAUDE.md §Artifact Ownership | OK |

**判定**: dangling reference なし。

---

## Split Traceability Table

v1.0.4 (E2E/Visual 分割) で移動されたコンテンツの追跡:

| 旧場所 (sdd-inspector-e2e.md) | 新場所 | 状態 |
|-------------------------------|--------|------|
| Phase B: Visual Design Evaluation | sdd-inspector-visual.md §Execution | 移行済み |
| Design System Compliance チェック | sdd-inspector-visual.md §Design System Compliance | 移行済み |
| Aesthetic Quality Assessment | sdd-inspector-visual.md §Aesthetic Quality | 移行済み |
| Design-Spec Alignment | sdd-inspector-visual.md §Design-Spec Alignment | 移行済み |
| `e2e-visual-system` カテゴリ | `visual-system` (visual.md) | リネームして移行 |
| `e2e-visual-quality` カテゴリ | `visual-quality` (visual.md) | リネームして移行 |
| Dev server start/stop (E2E 内) | review.md §Web Inspector Server Protocol (Lead管理) | アーキテクチャ変更: Inspector→Lead へ責務移動 |
| steering/ui.md 読み込み (E2E 内) | sdd-inspector-visual.md §Load Context | 移行済み (Visual の責務) |
| "up to 7 independent review agents" (auditor-impl) | "up to 8 independent review agents" | 更新済み |
| -- | sdd-inspector-visual.md §Accessibility (新規) | 新規追加 (visual-a11y) |
| -- | sdd-inspector-visual.md §Cross-Page Consistency (新規) | 新規追加 |
| -- | sdd-inspector-visual.md §Viewport Configuration (新規) | 新規追加 |
| -- | sdd-auditor-impl.md E2E/Visual クロスチェック (新規) | 新規追加 |

v1.2.0 (SDD root 移動) のパス更新追跡:

| 更新対象 | 旧パス | 新パス | 状態 |
|---------|--------|--------|------|
| CLAUDE.md SDD Root | `.claude/sdd` | `.sdd` | 更新済み |
| install.sh install先 | `.claude/sdd/settings/` | `.sdd/settings/` | 更新済み |
| install.sh version | `.claude/sdd/.version` | `.sdd/.version` | 更新済み |
| install.sh help 表示 | `.claude/sdd/` パス | `.sdd/` パス | 更新済み |
| install.sh uninstall | `.claude/sdd/` のみ | `.sdd/` + `.claude/sdd/` (互換) | 更新済み |
| install.sh stale removal | `.claude/sdd/settings/` | `.sdd/settings/` | 更新済み |
| install.sh summary | `.claude/sdd/` | `.sdd/` | 更新済み |
| install.sh migration | -- | v1.2.0 migration セクション新設 | 新規追加 |
| install.sh gitignore | -- | `.sdd/` 追加処理 | 新規追加 |
| steering-principles.md | `.claude/sdd/` | `.sdd/` | 更新済み |

v1.1.1 (プロファイル構文修正):

| ファイル | 旧構文 | 新構文 | 状態 |
|---------|--------|--------|------|
| profiles/python.md | `Bash(uv:*)` | `Bash(uv *)` | 更新済み |
| profiles/rust.md | `Bash(cargo:*)` 等 | `Bash(cargo *)` 等 | 更新済み |
| profiles/typescript.md | `Bash(npm:*)` 等 | `Bash(npm *)` 等 | 更新済み |

v1.1.1 (セクション名修正):

| ファイル | 旧名 | 新名 | 状態 |
|---------|------|------|------|
| design-principles.md L68 | `Components & Interfaces` | `Components and Interfaces` | 更新済み |
| design-principles.md L96 | `Components & Interfaces Authoring` | `Components and Interfaces Authoring` | 更新済み |
| design-discovery-full.md L91 | `Components & Interface Contracts` | 未更新 | **M1 (MEDIUM)** |

未コミット変更の追跡:

| 変更 | 旧内容 | 新内容 | 影響 |
|------|--------|--------|------|
| CLAUDE.md Step 7 | 単純な resume/await | pipeline 判定付き条件分岐 | 旧内容は新内容に完全包含 |
| CLAUDE.md Behavioral Rules | compact 後は常に wait | pipeline active なら continue | Session Resume との整合性改善 |
| sdd-builder.md | git 制約なし | workspace-wide git 操作禁止 | 新規追加、矛盾なし |

---

## Overall Assessment

直近 5 コミット + 未コミット変更に対するリグレッション検査の結果、**重大な機能喪失やプロトコル欠落は検出されなかった**。

v1.0.4 の E2E/Visual 分割は徹底的に実施されており、旧 E2E Inspector の全 visual 責務が新 Visual Inspector に移行され、Auditor のクロスチェックルールも追加されている。v1.2.0 の `.sdd/` 移行も framework/ 内の全参照が更新済みで、install.sh に適切な migration パスが用意されている。

唯一の指摘事項は `design-discovery-full.md` のセクション名残 (MEDIUM) のみであり、フリーテキスト内の参照であるため実動作への影響は限定的。
