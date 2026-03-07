# Dead Code & Unused References レビューレポート

## 概要

フレームワーク全体（CLAUDE.md, 7 Skills, 6 refs, 24 agents, settings.json, 7 rules, 18 templates, install.sh）を対象に、未参照リソース・冗長コンテンツ・到達不能パス・削除概念の残骸・陳腐化コメントを検出した。

---

## 1. エージェント参照マトリクス

### 1.1 エージェント定義 vs ディスパッチ参照

| エージェント | agents/定義 | settings.json | review.md参照 | SKILL.md/refs参照 | CLAUDE.md参照 |
|---|---|---|---|---|---|
| sdd-architect | YES | YES | - | design.md, run.md | YES (例示) |
| sdd-builder | YES | YES | - | impl.md | - |
| sdd-taskgenerator | YES | YES | - | impl.md | - |
| sdd-auditor-design | YES | YES | review.md | - | - |
| sdd-auditor-impl | YES | YES | review.md | - | - |
| sdd-auditor-dead-code | YES | YES | review.md | - | - |
| sdd-inspector-rulebase | YES | YES | review.md | - | - |
| sdd-inspector-testability | YES | YES | review.md | - | - |
| sdd-inspector-architecture | YES | YES | review.md | - | - |
| sdd-inspector-consistency | YES | YES | review.md | - | - |
| sdd-inspector-best-practices | YES | YES | review.md | - | - |
| sdd-inspector-holistic | YES | YES | review.md | - | - |
| sdd-inspector-impl-rulebase | YES | YES | review.md | - | - |
| sdd-inspector-interface | YES | YES | review.md | - | - |
| sdd-inspector-test | YES | YES | review.md | - | - |
| sdd-inspector-quality | YES | YES | review.md | - | - |
| sdd-inspector-impl-consistency | YES | YES | review.md | - | - |
| sdd-inspector-impl-holistic | YES | YES | review.md | - | - |
| sdd-inspector-e2e | YES | YES | review.md | - | - |
| sdd-inspector-visual | YES | YES | review.md | - | - |
| sdd-inspector-dead-code | YES | YES | review.md | - | - |
| sdd-inspector-dead-settings | YES | YES | review.md | - | - |
| sdd-inspector-dead-specs | YES | YES | review.md | - | - |
| sdd-inspector-dead-tests | YES | YES | review.md | - | - |

**結果**: 全24エージェントが定義・権限設定・ディスパッチ参照のすべてで整合。未参照エージェントなし。

---

## 2. テンプレート/ルール参照マトリクス

### 2.1 ルールファイル

| ルールファイル | 参照元 |
|---|---|
| `cpf-format.md` | CLAUDE.md (l.336) |
| `design-principles.md` | sdd-architect.md (l.30) |
| `design-discovery-full.md` | sdd-architect.md (l.48) |
| `design-discovery-light.md` | sdd-architect.md (l.56) |
| `design-review.md` | sdd-inspector-rulebase.md (l.39, l.123), sdd-inspector-testability.md (l.43) |
| `steering-principles.md` | sdd-steering/SKILL.md (l.15) |
| `tasks-generation.md` | sdd-taskgenerator.md (l.32) |

**結果**: 全7ルールファイルが参照されている。未参照ルールなし。

### 2.2 テンプレートファイル

| テンプレート | 参照元 |
|---|---|
| `specs/design.md` | sdd-architect.md (l.29), sdd-inspector-rulebase.md (l.38, l.122) |
| `specs/research.md` | sdd-architect.md (l.31) |
| `specs/init.yaml` | sdd-roadmap/SKILL.md (l.76) |
| `steering/product.md` | sdd-steering/SKILL.md (l.48, implicit) |
| `steering/tech.md` | sdd-steering/SKILL.md (l.48, implicit) |
| `steering/structure.md` | sdd-steering/SKILL.md (l.48, implicit) |
| `steering-custom/api-standards.md` | sdd-steering/SKILL.md (l.68-69) |
| `steering-custom/authentication.md` | sdd-steering/SKILL.md (l.68-69) |
| `steering-custom/database.md` | sdd-steering/SKILL.md (l.68-69) |
| `steering-custom/deployment.md` | sdd-steering/SKILL.md (l.68-69) |
| `steering-custom/error-handling.md` | sdd-steering/SKILL.md (l.68-69) |
| `steering-custom/security.md` | sdd-steering/SKILL.md (l.68-69) |
| `steering-custom/testing.md` | sdd-steering/SKILL.md (l.68-69) |
| `steering-custom/ui.md` | sdd-steering/SKILL.md (l.68-69), sdd-inspector-visual.md |
| `handover/session.md` | CLAUDE.md (l.240), sdd-handover/SKILL.md (l.36) |
| `handover/buffer.md` | CLAUDE.md (l.250) |
| `knowledge/pattern.md` | sdd-knowledge/SKILL.md (l.43, implicit) |
| `knowledge/incident.md` | sdd-knowledge/SKILL.md (l.43, implicit) |
| `knowledge/reference.md` | sdd-knowledge/SKILL.md (l.43, implicit) |

**結果**: 全テンプレートが参照されている。未参照テンプレートなし。

### 2.3 プロファイルファイル

| プロファイル | 参照元 |
|---|---|
| `_index.md` | sdd-steering/SKILL.md (l.37, 除外対象として) |
| `python.md` | sdd-steering/SKILL.md (l.37, 動的検出) |
| `typescript.md` | sdd-steering/SKILL.md (l.37, 動的検出) |
| `rust.md` | sdd-steering/SKILL.md (l.37, 動的検出) |

**結果**: 全プロファイルが参照パターンに含まれる。未参照なし。

---

## 3. スキル参照の整合性

### 3.1 CLAUDE.md Commands テーブル vs 実在スキル

| CLAUDE.md Commands | SKILL.md存在 | settings.json権限 |
|---|---|---|
| `/sdd-steering` | YES | YES |
| `/sdd-roadmap` | YES | YES |
| `/sdd-status` | YES | YES |
| `/sdd-handover` | YES | YES |
| `/sdd-knowledge` | YES | YES |
| `/sdd-release` | YES | YES |
| (未掲載) `/sdd-review-self` | YES | YES |

### 発見事項

- [MEDIUM] **`sdd-review-self` が CLAUDE.md Commands テーブルに未掲載**
  - 場所: `framework/claude/CLAUDE.md` l.142-151
  - 状況: `sdd-review-self` は SKILL.md が存在し、settings.json に権限設定もあるが、CLAUDE.md の `### Commands (6)` テーブルに記載されていない。「6」の数字も実際の7と不一致。
  - 判定: **意図的である可能性が高い**。`sdd-review-self` はフレームワーク開発専用ツール（description: "framework-internal use only"）であり、エンドユーザー向けのコマンド一覧から除外するのは合理的。しかし、数字の不一致は混乱を招く可能性がある。
  - 推奨: Commands テーブルの下にフレームワーク開発用コマンドとして注記を追加するか、数字を「6 (+1 framework-internal)」のように明示する。

---

## 4. 冗長コンテンツの検出

### 4.1 Inspector Wave-Scoped Cross-Check Mode の大規模重複

- [LOW] **14 Inspector ファイルに Wave-Scoped Cross-Check Mode セクションがほぼ同一内容で存在**
  - 該当ファイル: 全14 Inspector（design 6 + impl 6 + web 2）
  - 内容: 「Resolve Wave Scope → Load Steering Context → Load Roadmap Context → Load Wave-Scoped Specs → Execute Wave-Scoped Cross-Check」の5ステップがほぼ同じ文言で繰り返されている
  - 理由: SubAgent はコンテキストを共有しないため、各エージェントに独立した手順が必要。これは SubAgent アーキテクチャの制約上、避けられない重複。
  - 判定: **False Positive（設計上必要）**。共通ファイルとして外出しすると SubAgent が追加ファイルを読む必要が生じ、トークン効率が低下する。

### 4.2 Inspector Load Context セクションの重複パターン

- [LOW] **Steering Context 読み込み指示が全 Inspector で重複**
  - 内容: `Read entire {{SDD_DIR}}/project/steering/ directory` が全 Inspector に含まれる
  - 判定: **False Positive（同上理由）**。

---

## 5. 到達不能コードパス

### 5.1 検出なし

全フェーズ遷移パスを検証:
- `initialized` → `design-generated` → `implementation-complete`: 正常パス確認
- `blocked` 状態のゲートチェック: 全サブコマンド（design, impl, review）で確認
- `implementation-complete` → `design-generated` (revision): revise.md Part A Step 4 で確認
- NO-GO → auto-fix → re-review ループ: run.md Phase Handlers で確認
- SPEC-UPDATE-NEEDED → cascade: run.md Impl Review completion で確認
- 1-Spec Roadmap Optimizations のスキップ条件: 正常にバイパス

---

## 6. 削除・リネーム概念の残骸

### 6.1 直近の変更コンテキスト

**v1.2.0 (最新コミット)**: `.claude/sdd/` → `.sdd/` への移行
- フレームワークファイル内のパス参照: `{{SDD_DIR}}` テンプレート変数を使用しているため影響なし
- install.sh: v1.2.0 マイグレーションコード確認済み

**未コミット変更**: Session Resume Step 7 改訂、Behavioral Rules 改訂、Builder git 制約追加
- 旧概念の残骸なし

### 6.2 install.sh のレガシーマイグレーションコード

- [LOW] **install.sh に6世代分のマイグレーションコードが累積**
  - v0.4.0: `.kiro/` → `.claude/sdd/` マイグレーション
  - v0.7.0: `sdd-coordinator.md` 削除、`coordinator.md` → `conductor.md` リネーム
  - v0.9.0: `conductor.md` → `session.md`、`log.md` → `decisions.md`
  - v0.10.0: `spec.json` → `spec.yaml`、`sdd-planner.md` 削除
  - v0.15.0: `commands/` → `skills/` 移行
  - v0.18.0: `agents/` → `sdd/settings/agents/`
  - v0.20.0: `sdd/settings/agents/` → `agents/` (戻し)
  - v1.2.0: `.claude/sdd/` → `.sdd/`
  - 判定: マイグレーションコードはユーザーのアップグレード体験に直結するため、**削除不可**。ただし v0.4.0-v0.7.0 のコードは実用上ほぼ不要（そこまで古いバージョンからのアップグレードは稀）。
  - 推奨: メジャーバージョンの区切り（例: v2.0.0）で古いマイグレーションパスの整理を検討。現時点では問題なし。

### 6.3 旧概念の残骸チェック

| 旧概念 | 検索結果 |
|---|---|
| `coordinator` (v0.7.0 で削除) | フレームワークファイル内: なし。install.sh: マイグレーションコード内のみ (正常) |
| `conductor` (v0.9.0 で改名) | フレームワークファイル内: なし。install.sh: マイグレーションコード内のみ (正常) |
| `Agent Teams` (v0.20.0 で廃止) | フレームワークファイル内: なし。install.sh: コメント1箇所 (正常) |
| `sdd-planner` (v0.10.0 で削除) | フレームワークファイル内: なし。install.sh: マイグレーションコード内のみ (正常) |
| `spec.json` (v0.10.0 で廃止) | フレームワークファイル内: なし。install.sh: マイグレーションコード内のみ (正常) |
| `tasks.md` (v0.10.0 で廃止) | フレームワークファイル内: なし。install.sh: マイグレーションコード内のみ (正常) |
| `commands/sdd-*` (v0.15.0 で廃止) | フレームワークファイル内: なし。install.sh: マイグレーション+レガシークリーンアップ (正常) |

**結果**: 全旧概念の残骸はマイグレーションコード内にのみ存在。フレームワーク本体には残骸なし。

---

## 7. 陳腐化コメント・空セクション

### 7.1 TODO/FIXME/HACK

- フレームワークファイル内に実質的な TODO/FIXME/HACK なし
- `sdd-review-self/SKILL.md` と `sdd-builder.md` 内の言及は検出対象の説明文としてのものであり、実際の未完了項目ではない

### 7.2 空セクション

- 検出なし。全ファイルのセクションに内容が存在。

---

## 8. 追加発見事項

### 8.1 review.md Verdict Destination の網羅性

- [LOW] review.md (l.122-129) に「Verdict Destination by Review Type」が列挙されている。Self-review のエントリ (`{{SDD_DIR}}/project/reviews/self/verdicts.md`) が含まれているが、これは `sdd-review-self` スキルが review.md の通常フローではなく独自のフローを使うため、参照情報としてのみ意味がある。整合性上は問題なし。

### 8.2 sdd-review-self の `general-purpose` SubAgent 使用

- [LOW] `sdd-review-self/SKILL.md` (l.65) で `Task(subagent_type="general-purpose")` を使用している。これは Claude Code の汎用 SubAgent 機能で、`agents/` に定義が不要。settings.json に `Task(general-purpose)` の権限設定がないが、これは `defaultMode: "acceptEdits"` でカバーされるか、プラットフォームのビルトイン動作として許可されている可能性がある。
- 判定: 動作に問題がなければ問題なし。ただし、他のすべてのエージェントが settings.json に明示的に権限設定されている中で `general-purpose` だけが未設定なのは一貫性の面で気になる点。

---

## 総合評価

| 重要度 | 件数 | 概要 |
|---|---|---|
| CRITICAL | 0 | - |
| HIGH | 0 | - |
| MEDIUM | 1 | `sdd-review-self` の CLAUDE.md Commands テーブル未掲載 (意図的な可能性高) |
| LOW | 4 | Inspector Wave-Scoped 重複 (設計上必要), Steering Context 重複 (同上), install.sh マイグレーション累積, `general-purpose` 権限未設定 |

**総評**: フレームワークは非常にクリーンな状態にある。24エージェント・7スキル・7ルール・19テンプレートの全リソースが参照チェーンで接続されており、未参照のデッドリソースは検出されなかった。settings.json の権限設定もファイル数と完全一致。旧概念の残骸もマイグレーションコード（install.sh）内に限定され、フレームワーク本体には一切残っていない。唯一の MEDIUM 発見は `sdd-review-self` の Commands テーブル未掲載だが、これはフレームワーク開発専用ツールとしての意図的除外である可能性が高い。
