# SDD Framework Improvement Handover

Generated: 2026-02-12
Source project: authflow (Google OAuth2 + RBAC)
Purpose: SDDフレームワーク自体の改修を別リポジトリで実施するための引き継ぎ

---

## 1. 現行SDDフレームワーク構成

### ファイル構成

```
.claude/
├── commands/          # Skill定義 (ユーザーが /sdd-xxx で呼ぶ)
│   ├── sdd-requirements.md    # 要件生成
│   ├── sdd-design.md          # 設計生成
│   ├── sdd-tasks.md           # タスク生成
│   ├── sdd-impl.md            # TDD実装
│   ├── sdd-review-requirement.md  # 要件レビュー (Router)
│   ├── sdd-review-design.md       # 設計レビュー (Router)
│   ├── sdd-review-impl.md         # 実装レビュー (Router)
│   ├── sdd-roadmap.md         # ロードマップRouter
│   ├── sdd-roadmap-create.md  # ロードマップ生成
│   ├── sdd-roadmap-run.md     # Wave実行
│   ├── sdd-roadmap-update.md  # ロードマップ更新
│   ├── sdd-roadmap-delete.md  # ロードマップ削除
│   ├── sdd-steering.md        # Steeringルーター
│   ├── sdd-steering-create.md
│   ├── sdd-steering-update.md
│   ├── sdd-steering-delete.md
│   ├── sdd-steering-custom.md
│   ├── sdd-status.md          # 進捗表示
│   ├── sdd-analyze-gap.md     # 既存コードとのギャップ分析
│   ├── sdd-review-dead-code.md
│   ├── sdd-knowledge.md       # ナレッジ記録
│   └── sdd-handover.md        # セッション引き継ぎ
│
├── agents/            # サブエージェント定義 (Task toolで呼ばれる)
│   ├── sdd-review-requirement-rulebase.md
│   ├── sdd-review-requirement-explore-completeness.md
│   ├── sdd-review-requirement-explore-contradiction.md
│   ├── sdd-review-requirement-explore-common-sense.md
│   ├── sdd-review-requirement-explore-edge-case.md
│   ├── sdd-review-requirement-verifier.md
│   ├── sdd-review-design-rulebase.md
│   ├── sdd-review-design-explore-architecture.md
│   ├── sdd-review-design-explore-best-practices.md
│   ├── sdd-review-design-explore-consistency.md
│   ├── sdd-review-design-explore-testability.md
│   ├── sdd-review-design-verifier.md
│   ├── sdd-review-impl-rulebase.md
│   ├── sdd-review-impl-explore-interface.md
│   ├── sdd-review-impl-explore-test.md
│   ├── sdd-review-impl-explore-quality.md
│   ├── sdd-review-impl-explore-consistency.md
│   └── sdd-review-impl-verifier.md
│
└── settings.json      # Claude Code設定

.kiro/
├── steering/          # プロジェクト横断のルール・コンテキスト
│   ├── product.md
│   ├── tech.md
│   └── structure.md
│
├── specs/             # 機能仕様 (1ディレクトリ = 1 feature)
│   ├── roadmap.md     # Wave構成・依存グラフ・実行フロー
│   └── {feature}/
│       ├── spec.json       # メタデータ (phase, approvals, roadmap)
│       ├── requirements.md # EARS形式の要件
│       ├── research.md     # 設計前調査ログ
│       ├── design.md       # 技術設計
│       └── tasks.md        # 実装タスク (チェックリスト)
│
├── knowledge/         # 再利用可能な知見
│
└── settings/          # テンプレート・ルール
    ├── rules/
    │   ├── ears-format.md
    │   ├── requirement-review.md
    │   ├── design-principles.md
    │   ├── design-discovery-full.md
    │   ├── design-discovery-light.md
    │   ├── design-review.md
    │   ├── tasks-generation.md
    │   ├── tasks-parallel-analysis.md
    │   ├── gap-analysis.md
    │   └── steering-principles.md
    │
    └── templates/
        ├── specs/
        │   ├── init.json          # spec.jsonテンプレート
        │   ├── requirements.md
        │   ├── design.md
        │   ├── research.md
        │   └── tasks.md
        ├── steering/
        │   ├── product.md
        │   ├── tech.md
        │   └── structure.md
        ├── steering-custom/
        │   └── (複数のカスタムテンプレート)
        └── knowledge/
            ├── pattern.md
            ├── incident.md
            └── reference.md
```

### 現行フロー

```
Requirements → Design → Tasks → Implementation
    ↓            ↓        ↓          ↓
  Review      Review   (auto)    Review
    ↓            ↓                   ↓
  Approve    Approve              Approve → Next Wave
```

各レビューは **Router + 5並列Agent + Verifier** のパターン:
- Router: Pre-flight検証 → Agent起動 → Verifier起動 → 結果フォーマット
- Agent: 独立コンテキストで各観点をレビュー → CPF形式で出力
- Verifier: 5 Agent結果をクロスチェック → GO/CONDITIONAL/NO-GO判定

### spec.json 現行スキーマ

```json
{
  "feature_name": "auth-flow",
  "created_at": "2026-02-10T00:00:00Z",
  "updated_at": "2026-02-12T00:00:00Z",
  "language": "ja",
  "phase": "requirements-generated",
  "approvals": {
    "requirements": { "generated": true, "approved": false },
    "design": { "generated": false, "approved": false },
    "tasks": { "generated": false, "approved": false }
  },
  "ready_for_implementation": false,
  "roadmap": {
    "wave": 2,
    "dependencies": ["data-models", "logging"],
    "parallel": false,
    "description": "..."
  }
}
```

### Wave実行フロー (roadmap.md内で定義)

9ステップの固定フロー:
1. Wave内spec特定
2. Requirements有無チェック
3. Requirements Review (並列Agent)
4. User Confirmation [REQUIRED]
5. Design Generation (並列subagent)
6. Design Review (並列Agent)
7. Task Generation
8. Implementation (並列subagent)
9. Implementation Review & Completion Report

---

## 2. 分析に使ったドキュメント

ユーザー提供のドキュメントは「SPECが唯一の真実」と「アジャイルの変化への適応」の両立を論じたもの。以下5つのパターンを提案:

1. **SPECをLiving Documentとして扱う** — バージョン管理、SPEC変更が先/実装変更が後
2. **SPECの階層化** — L0(不変の制約) / L1(スプリント変更可) / L2(随時変更可) で変化速度を分離
3. **SPEC変更をPRとして扱う** — SPECとコードの変更を同一PRで原子的に
4. **Contract-First + 遅延詳細化** — まずインターフェースだけ、詳細は段階的に
5. **SPECとテストの双方向同期** — SPEC変更 → テスト更新 → テスト失敗 → 実装修正 のサイクル

---

## 3. 特定された改善点 (7項目)

### 改善1: SPECバージョニングの導入 [優先度: 高]

**現状の問題**:
- spec.json の `updated_at` は最終更新日のみ。何が変わったか不明
- requirements.md を直接上書きするだけで変更履歴が消失
- 「v1.0の要件でdesignを作ったが、v1.1で要件が変わった」場合の不整合検知手段がない

**改修対象ファイル**:
- `.kiro/settings/templates/specs/init.json` — `version`, `changelog` フィールド追加
- `.claude/commands/sdd-requirements.md` — 既存specの編集時にバージョンインクリメント
- `.claude/commands/sdd-design.md` — requirements_version を記録し、不整合時に警告
- `.claude/commands/sdd-tasks.md` — design_version を記録
- `.claude/commands/sdd-status.md` — バージョン情報の表示

**改修案**:
```json
{
  "version": "1.1.0",
  "changelog": [
    {
      "version": "1.1.0",
      "date": "2026-02-12",
      "phase": "requirements",
      "summary": "Redirect要件にオープンリダイレクト防止を追加",
      "affected_requirements": ["R2.AC8"]
    },
    {
      "version": "1.0.0",
      "date": "2026-02-10",
      "phase": "requirements",
      "summary": "Initial requirements"
    }
  ],
  "version_refs": {
    "requirements": "1.1.0",
    "design": "1.0.0",
    "tasks": "1.0.0"
  }
}
```

`version_refs` により「designはrequirements v1.0.0を元に作られたが、requirementsは既にv1.1.0」という不整合を検知可能。

---

### 改善2: SPEC階層化 (変化速度の分離) [優先度: 中]

**現状の問題**:
- requirements.md 内の全ACが同列。「HS256で署名」(制約) と「Cookie属性」(振る舞い) が区別不能
- 変更時のインパクト判断ができない

**改修対象ファイル**:
- `.kiro/settings/rules/ears-format.md` — ACに `stability` 属性の規約追加
- `.kiro/settings/templates/specs/requirements.md` — 階層表記のガイド
- `.claude/agents/sdd-review-requirement-rulebase.md` — 階層整合性チェック
- `.claude/commands/sdd-requirements.md` — 生成時に階層付与

**改修案**: 各ACに安定度タグを付与

```markdown
#### Acceptance Criteria
1. [constraint] The JWT shall HS256 アルゴリズムで署名する
2. [contract] The JWT payload shall sub, email, exp を含む
3. [behavior] The Cookie shall HttpOnly=True, SameSite=Lax の属性を持つ
```

- `constraint`: ほぼ不変。変更時は全下流の再レビュー必須
- `contract`: インターフェース契約。変更時はdesign再生成
- `behavior`: 振る舞い。随時変更可、tasks再生成で対応

---

### 改善3: フィードバックループの追加 [優先度: 高]

**現状の問題**:
- フローが Requirements → Implementation の一方通行
- Implementation Reviewの結果は GO/CONDITIONAL/NO-GO のみで、「SPECが間違っていた」を表現するパスがない
- Wave完了後に次Waveに進むだけで、実装中の知見をSPECに還流する仕組みがない

**改修対象ファイル**:
- `.claude/agents/sdd-review-impl-verifier.md` — `SPEC-UPDATE-NEEDED` 判定の追加
- `.claude/commands/sdd-review-impl.md` — SPEC-UPDATE-NEEDED時のフロー定義
- `.claude/commands/sdd-roadmap-run.md` — Step 9にSPECフィードバックループ追加
- `.kiro/specs/roadmap.md` (テンプレートとして) — Wave実行フローにStep 9.5追加

**改修案**:

sdd-review-impl-verifier.md の判定ロジックに追加:
```
IF findings indicate spec defect (not implementation defect):
    SPEC_FEEDBACK: {phase}|{spec}|{description}
    # phase = requirements | design
    # 例: requirements|auth-flow|Req 2.AC8 のリダイレクト仕様が実運用と矛盾
```

sdd-roadmap-run.md の Step 9 後に:
```
9.5. SPEC Feedback Loop (if SPEC-UPDATE-NEEDED)
   a. 該当SPECのphaseをロールバック (e.g., design-generated → requirements-generated)
   b. version_refs の不整合をマーク
   c. ユーザーに変更内容を提示し、SPEC更新を促す
   d. SPEC更新後、影響を受ける下流SPECを特定 (改善7のimpact analysis)
```

---

### 改善4: SPEC/コード変更の原子性 [優先度: 中]

**現状の問題**:
- `.kiro/specs/` と `src/` の変更が別々のステップで行われる
- SPECを更新してもコードが追随しない、またはその逆が発生しうる
- 「SPEC変更 → 実装変更」の順序を制度的に保証する仕組みがない

**改修対象ファイル**:
- `.claude/commands/sdd-impl.md` — 実装前にspec version_refsチェックを追加
- `.claude/commands/sdd-requirements.md` — 既存specのEdit時にバージョンインクリメント + downstream警告
- CLAUDE.md — Git convention セクションに原子性ルールを追記

**改修案**:

sdd-impl.md の Step 1 (Load Context) に追加:
```
### Version Consistency Check
- Read spec.json.version_refs
- If version_refs.requirements != version_refs.design:
    WARN: "Design is based on requirements v{X} but requirements are now v{Y}"
    SUGGEST: "Re-run /sdd-design {feature} to update design"
    BLOCK: Do not proceed with implementation
```

CLAUDE.md に追記:
```markdown
### SPEC-Code Atomicity Convention
- SPEC変更を含むコミットは `spec({feature}): {description}` プレフィックス
- SPEC変更コミットの直後に対応する実装コミットを置く
- PRレベルではSPEC変更と実装変更を同一PRに含める
```

---

### 改善5: Contract-First / 遅延詳細化 [優先度: 中]

**現状の問題**:
- sdd-requirements は初回で全ACを書き切る前提
- 不確実性の高いエッジケースまで初期段階で定義しようとする
- 「インターフェースだけ先に決めて詳細は後から」ができない

**改修対象ファイル**:
- `.kiro/settings/templates/specs/requirements.md` — `detail_level` セクション追加
- `.claude/commands/sdd-requirements.md` — detail_level パラメータ対応
- `.claude/commands/sdd-design.md` — interface-only モード追加
- `.kiro/settings/rules/ears-format.md` — 段階的詳細化のガイドライン

**改修案**:

requirements.md テンプレートに:
```markdown
## Detail Level: interface
<!-- interface | normal | edge-cases -->
<!-- interface: インターフェース契約のみ (input/output/エラー区分) -->
<!-- normal: 正常系の振る舞い詳細化 -->
<!-- edge-cases: エッジケース・エラーハンドリング追加 -->
```

sdd-requirements の Case B (既存specの編集) に新オプション追加:
```
E. Deepen detail level (interface → normal → edge-cases)
```

段階的な詳細化フロー:
```
1. /sdd-requirements "description"     → detail_level: interface
2. /sdd-design {feature}               → インターフェース設計のみ
3. /sdd-requirements {feature}         → Option E: normal に深化
4. /sdd-design {feature}               → 正常系の設計追加
5. /sdd-tasks {feature}                → タスク生成
6. /sdd-impl {feature}                 → 実装
7. /sdd-requirements {feature}         → Option E: edge-cases に深化 (必要に応じて)
```

---

### 改善6: AC↔テスト Traceability [優先度: 高]

**現状の問題**:
- sdd-impl は TDD で実装するが、AC とテストケースの対応は暗黙的
- AC 変更時にどのテストを更新すべきか機械的に特定できない
- sdd-review-impl の rulebase agent は「Requirement not implemented」を検知するが、テスト側からの逆引きはない

**改修対象ファイル**:
- `.claude/commands/sdd-impl.md` — テスト生成時にトレーサビリティマーカー付与
- `.claude/agents/sdd-review-impl-rulebase.md` — マーカーベースのtraceability検証
- `.claude/agents/sdd-review-impl-explore-test.md` — AC↔テスト対応の網羅性チェック
- `.kiro/settings/rules/tasks-generation.md` — タスク記述にAC参照を必須化

**改修案**:

sdd-impl.md の TDD RED ステップに:
```
1. **RED - Write Failing Test**:
   - Write test for the next small piece of functionality
   - **Add traceability marker**: `# AC: {feature}.R{N}.AC{M}`
   - Example:
     ```python
     def test_login_redirects_to_google():
         """AC: auth-flow.R1.AC1"""
         ...
     ```
```

sdd-review-impl-rulebase.md の Requirements Traceability に:
```
3. **AC-Test Traceability**:
   - Grep for `AC: {feature}` pattern in test files
   - For each AC in requirements.md, verify at least one test references it
   - Flag: "AC not covered by any test" if no marker found
   - Flag: "Test references non-existent AC" if marker doesn't match requirements
```

---

### 改善7: Cross-Wave SPEC影響分析 [優先度: 低]

**現状の問題**:
- Wave間の依存は実行順序の依存のみ (roadmap.md の dependency graph)
- 「Wave 1 のSPEC変更がWave 2以降にどう影響するか」の分析手段がない
- data-models のSPEC変更 → auth-flow / org-management / user-management 全てに波及する可能性

**改修対象ファイル**:
- 新規: `.claude/commands/sdd-impact-analysis.md`
- `.claude/commands/sdd-requirements.md` — SPEC変更時に自動で影響分析を提案
- `.kiro/specs/roadmap.md` (テンプレート) — 依存グラフの逆引き情報

**改修案**:

新コマンド `/sdd-impact-analysis {feature}`:
```
## Execution Steps

1. Read roadmap.md dependency graph
2. Build reverse dependency map:
   data-models → [auth-flow, org-management, user-management, admin-ui, app-integration]
3. For changed feature, list all downstream specs
4. For each downstream spec:
   a. Check if design references changed requirements (via version_refs)
   b. Check if implementation imports/uses changed interfaces
   c. Classify impact: BREAKING / COMPATIBLE / UNKNOWN
5. Report:
   - Directly affected specs
   - Transitively affected specs
   - Recommended actions (re-design, re-test, etc.)
```

---

## 4. 改善間の依存関係

```
改善1 (バージョニング) ←── 基盤。他の改善の多くが依存
    ↓
改善4 (原子性) ←── version_refs による不整合検知
    ↓
改善3 (フィードバックループ) ←── バージョンロールバックの仕組み
    ↓
改善7 (影響分析) ←── version_refs + dependency graphの組合せ

改善2 (階層化) ←── 独立。他に依存しない
改善5 (遅延詳細化) ←── 独立。他に依存しない
改善6 (Traceability) ←── 独立。他に依存しない
```

**推奨実装順序**:
1. 改善1 (バージョニング) — 全体の基盤
2. 改善6 (Traceability) — 独立かつ効果大
3. 改善3 (フィードバックループ) — 最も根本的な課題の解消
4. 改善4 (原子性) — バージョニング活用
5. 改善2 (階層化) — 要件品質向上
6. 改善5 (遅延詳細化) — ワークフロー拡張
7. 改善7 (影響分析) — 全体を統合

---

## 5. 改修時の注意事項

### アーキテクチャ原則

- **Router + Agent + Verifier パターン**: レビュー系は全てこの3層構成。新しいレビュー観点を追加する場合はAgentを追加し、Verifierの入力を拡張する
- **Context Isolation**: 各Agentは独立コンテキストで動作。Agent間で直接データ共有しない。Verifierが集約する
- **CPF (Compact Pipe-delimited Format)**: Agent出力は必ずCPF。人間可読なMarkdownへの変換はRouterが行う
- **`-y` フラグ**: Auto-approve。sdd-roadmap-run が自動実行時に使う

### 既存テンプレート・ルールとの整合

- `.kiro/settings/rules/` 内のルールファイルは各コマンドから参照される
- ルールを変更する場合、参照している全コマンド/エージェントを確認すること
- テンプレートの変更は既存specとの互換性に注意 (既存specのspec.jsonに新フィールドがない場合のフォールバック)

### 後方互換性

- spec.json に新フィールドを追加する場合、**存在しない場合のデフォルト動作**を全コマンドに定義
- 既存プロジェクトがSDD改修後のフレームワークを使えるよう、マイグレーションパスを考慮
- `version` フィールドがないspec.jsonは暗黙的に `"1.0.0"` として扱う

### authflowプロジェクトの現状

| Spec | Phase | Wave |
|------|-------|------|
| data-models | implementation-complete | 1 |
| logging | tasks-generated (tasks.md有) | 1 |
| auth-flow | requirements-generated | 2 |
| org-management | requirements初期状態 | 3 |
| user-management | requirements初期状態 | 3 |
| admin-ui | requirements初期状態 | 4 |
| app-integration | requirements初期状態 | 4 |

Wave 1がほぼ完了、Wave 2の requirements が生成済みの段階。改修後のフレームワークをこのプロジェクトで検証する場合、auth-flow (Wave 2) のdesign生成から適用可能。

---

## 6. 検証計画

改修後のSDDフレームワークを検証する際のチェックポイント:

1. **バージョニング**: 既存specのrequirements編集時にバージョンがインクリメントされるか
2. **不整合検知**: requirements v1.1 に対して design v1.0 のまま sdd-impl を実行した際にブロックされるか
3. **フィードバックループ**: sdd-review-impl が SPEC-UPDATE-NEEDED を出力し、適切なロールバックが行われるか
4. **Traceability**: sdd-impl が生成するテストに AC マーカーが付与されるか
5. **影響分析**: data-models の requirements 変更時に下流 spec が列挙されるか
6. **後方互換**: version フィールドのない既存 spec.json で全コマンドがエラーなく動作するか
