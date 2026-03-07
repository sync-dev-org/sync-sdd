## Change-Focused Review Report

**対象コミット**: HEAD~5..HEAD (v1.1.2 → v1.2.3)
**主要変更**: sdd-knowledge廃止、sdd-review-self効率化、Cross-Cutting Revision追加、install.sh v1.2.0マイグレーション

---

### Issues Found

- [MEDIUM] README.md のスキル数が7のまま / README.md:53
  `# 7 skills` と記載されているが、sdd-knowledge 削除後の実際のスキル数は 6。
  `framework/claude/skills/` 配下の sdd-* ディレクトリは現在 6 個（sdd-handover, sdd-release, sdd-review-self, sdd-roadmap, sdd-status, sdd-steering）。
  ユーザーが README を見てインストール後に混乱する可能性がある。

- [LOW] インストール済み `.claude/settings.json` に `Skill(sdd-knowledge)` が残存 / .claude/settings.json:9
  これはインストール先ファイルであり framework ソースではないため、次回 `install.sh --force` または手動削除で解消される。
  ただし、このリポ自体が開発リポとして機能しているため、framework settings.json と乖離したまま運用されている点は注意。
  framework/claude/settings.json には正しく `Skill(sdd-knowledge)` が存在しない（削除済み）。

---

### Confirmed OK

**Focus Target 1: sdd-knowledge 廃止**

- `framework/claude/skills/sdd-knowledge/SKILL.md` — 削除済み（ディレクトリごと消滅）
- `framework/claude/sdd/settings/templates/knowledge/` — 削除済み（pattern.md, incident.md, reference.md すべて消滅）
- `framework/claude/CLAUDE.md` — `Knowledge:` パス行削除済み、`Knowledge aggregation` Lead 責務記述削除済み
- `framework/claude/CLAUDE.md` — `## Knowledge Auto-Accumulation` セクションは **意図的に保持**。buffer.md への蓄積プロトコルは継続（sdd-knowledge は削除だが buffer.md 蓄積は維持）
- `framework/claude/agents/sdd-inspector-best-practices.md` — `Knowledge Context` (knowledge/pattern-*.md, knowledge/reference-*.md 参照) セクション削除済み
- `framework/claude/agents/sdd-inspector-holistic.md` — `Knowledge Context` (knowledge/pattern-*.md, knowledge/incident-*.md 参照) セクション削除済み
- `framework/claude/agents/sdd-inspector-impl-holistic.md` — `Knowledge Context` (knowledge/incident-*.md, knowledge/pattern-*.md 参照) セクション削除済み
- `framework/claude/agents/sdd-inspector-quality.md` — `Knowledge Context` (knowledge/incident-*.md 参照) セクション削除済み
- `framework/claude/settings.json` — `Skill(sdd-knowledge)` 削除済み（framework ソース）
- `framework/claude/skills/sdd-roadmap/refs/run.md` — knowledge 関連参照（旧 Step 7c Post-gate での knowledge flush）削除済み
- `framework/claude/skills/sdd-roadmap/refs/impl.md` — buffer.md への knowledge タグ保存プロトコルは **正しく保持**（Step 3 Builder incremental processing）
- `install.sh` — knowledge テンプレートへの参照なし。`--update` 時の `remove_stale ".sdd/settings/templates" ...` により既存インストール済み knowledge テンプレートは自動削除される
- `framework/claude/sdd/settings/templates/handover/buffer.md` — 旧バージョンの `Auto-flush to knowledge/` セクション削除済み（3行削除確認）。`## Knowledge Buffer` セクションは正しく保持
- framework 内のすべての `.md`, `.json`, `.yaml`, `.sh` ファイルに `sdd-knowledge` または `project/knowledge/` パスへのダングリング参照なし（grep 確認済み）

**Focus Target 2: sdd-review-self 効率化**

- `framework/claude/skills/sdd-review-self/SKILL.md` — Sonnet×4 構成に変更済み：
  - Agent 1: Flow Integrity（変更なし）
  - Agent 2: Change-Focused Review（旧 Regression Detection から変更）
  - Agent 3: Consistency & Dead Ends（変更なし）
  - Agent 4: Platform Compliance（旧 Compliance から改善）
  - 旧 Agent 5: Dead Code（削除済み）
- `--quick` モード廃止。`argument-hint:` が空文字列（適切）
- `allowed-tools` から `WebSearch, WebFetch` 削除済み（Agent 4 が自前で WebSearch を行う設計）
- `Task(subagent_type="general-purpose", model="sonnet", run_in_background=true)` — 明示的に sonnet モデル指定されている
- `$FOCUS_TARGETS` パラメータ導入（Lead がフォーカスエリアを指定）
- `$CACHED_OK` による Platform Compliance キャッシュ機構導入（7日以内の前回結果を再利用）
- Consolidation Step がシンプル化：WebSearch/WebFetch なし、decisions.md 確認のみ
- Verdict persistence フォーマットが正しく更新（`{mode}` フィールドが除去）
- CLAUDE.md には `sdd-review-self` コマンド記述なし（意図的：内部ツールとして Commands テーブル外）。settings.json には `Skill(sdd-review-self)` 登録済み（正常）

**Focus Target 3: Cross-Cutting Revision**

- `framework/claude/skills/sdd-roadmap/refs/revise.md` — Part A（Single-Spec）と Part B（Cross-Cutting）の2部構成で完全に実装されている
- `framework/claude/skills/sdd-roadmap/SKILL.md` Step 1 Detect Mode:
  - `"revise {feature} [instructions]"` → Single-Spec Mode（Part A）
  - `"revise [instructions]"` → Cross-Cutting Mode（Part B）
  - revise.md Mode Detection と完全一致
- `framework/claude/CLAUDE.md`:
  - `Cross-Cutting Parallelism` セクションで `revise.md Part B` を正しく参照
  - `REVISION_INITIATED` に `(cross-cutting)` 注記ルール記載
  - `cross-cutting: {summary}` コミットメッセージフォーマット記載
  - `specs/.cross-cutting/{id}/` パス記載（CLAUDE.md Paths セクション）
  - counter reset trigger: `/sdd-roadmap revise` start — revise.md Part A Step 4 と Part B Step 7 で `retry_count/spec_update_count = 0` リセットが実装されている（整合）
- `revise.md` Part B のエスカレーションパス:
  - Part A Step 3 が 2+ specs 影響を検出 → Part B Step 2 へジョイン（明確）
  - Part A Step 6 で downstream オプション (d) Cross-cutting revision 選択時 → Part B Step 2 へジョイン（明確）
- FULL/AUDIT/SKIP 分類、Triage、Tier-based execution、Cross-check review、Post-completion commit すべて実装済み

**Focus Target 4: install.sh**

- v1.2.0 マイグレーションブロック（`.claude/sdd/` → `.sdd/`）正常実装
- `--uninstall` 時の旧パス（`.claude/sdd/`）クリーンアップ追加済み
- `.sdd/.version` 書き込みパス正常（`.claude/sdd/.version` からの移行含む）
- `--update` 時の stale ファイル削除: `.sdd/settings/templates` 配下の knowledge テンプレートは `remove_stale` により自動削除される
- skills stale 削除ループ: `sdd-knowledge` ディレクトリがフレームワークソースに存在しなければ `.claude/skills/sdd-knowledge/` は削除される
- `find .sdd/settings/templates -depth -type d -empty -delete` により空ディレクトリも自動削除
- install.sh ヘッダーコメントのバージョン参照 `v1.2.3` と `VERSION` ファイル内容 `1.2.3` が一致
- 明示的な v1.2.3 マイグレーションブロックなし — これは **設計通り**。skill ディレクトリの stale 削除は汎用ループで処理されるため、個別ブロック不要

**Focus Target 5: settings.json（framework ソース）**

- `Skill(sdd-knowledge)` 削除済み（framework/claude/settings.json）
- `Task(sdd-inspector-visual)` 追加済み（v1.0.4 時点の変更、現在も保持）
- `Task(sdd-inspector-e2e)` 存在確認（以前から存在）
- 現在の framework settings.json の Skill 許可: sdd-roadmap, sdd-steering, sdd-status, sdd-handover, sdd-release, sdd-review-self（6個）— sdd-knowledge 削除後の状態として正常
- Task 許可一覧と `framework/claude/agents/sdd-*.md` ファイル一覧の整合性: 全 Task エントリに対応するエージェント定義ファイルが存在する

**その他の確認事項**

- `framework/claude/CLAUDE.md` Commands テーブル数: 「Commands (5)」と記載、5コマンドがリストされている（sdd-knowledge 削除後の状態として正常）
- Inspector カウント（CLAUDE.md vs review.md）: `6 design, 6 impl +2 web, 4 dead-code` — review.md の実際のエージェントリストと一致
- buffer.md テンプレート: `## Knowledge Buffer` セクションのみ保持、旧 `Auto-flush` セクション削除済み
- impl.md の buffer.md 保存プロトコル（Step 3）: `create from template` 参照は buffer.md テンプレートが存在するため有効
- last_phase_action 命名統一（v1.2.2）: impl.md の参照は `last_phase_action` に統一されている

---

### Overall Assessment

**総合評価**: 軽微な問題あり（運用影響なし）

主要フォーカスターゲット 5 項目すべてにおいて、sdd-knowledge の廃止処理は framework ソース内で完結している。ダングリング参照なし、プロトコル欠損なし。

**検出した問題**:

1. **README.md スキル数誤記（MEDIUM）**: `# 7 skills` → `# 6 skills` への修正が必要。ユーザー向けドキュメントの誤りだが、フレームワーク動作には影響しない。

2. **インストール済み settings.json の乖離（LOW）**: `.claude/settings.json`（インストール先）に `Skill(sdd-knowledge)` が残存。`install.sh --force` または手動削除で解消。framework ソース (`framework/claude/settings.json`) は正しい状態。

sdd-review-self の Sonnet×4 構成と CLAUDE.md の記述に矛盾なし。Cross-Cutting Revision の SKILL.md ルーティングと revise.md の実装が整合している。install.sh のマイグレーションとバージョン更新は正確。
