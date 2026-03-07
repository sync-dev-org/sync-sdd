# Regression Detection Report

**Date**: 2026-02-24
**Mode**: full
**Scope**: framework/claude/ + install.sh
**対象コミット**: dd14ce8 (v1.1.2) まで + 未コミット変更

---

## 検出された問題

### CRITICAL (0)

なし。

### HIGH (0)

なし。

### MEDIUM (2)

#### M1: install.sh kiro マイグレーションが旧パスを使用

**Location**: install.sh:237-262 (migrate_kiro_to_sdd 関数)
**Description**: kiro マイグレーション (v0.4.0未満) が `.claude/sdd/project/` にデータを移動するが、v1.2.0 マイグレーションが後続で `.claude/sdd/` -> `.sdd/` に移動するため、実質的には問題ない。ただし、kiro マイグレーション内の `rm -f .claude/CLAUDE.md` (259行) は、v1.2.0 の CLAUDE.md マーカー管理と競合する可能性がある。

**Impact**: v0.3.x以前からの直接アップグレードにのみ影響。現実的なリスクは低い。
**Evidence**: install.sh のマイグレーション実行順序を確認。v0.4.0 -> v1.2.0 の間に CLAUDE.md は削除・再作成される。マーカーベースの管理 (install_claude_md 関数) がその後実行されるため、最終状態は正しい。

#### M2: CLAUDE.md の Commands (6) と README の 7 コマンドの不一致

**Location**: framework/claude/CLAUDE.md:142 vs README.md:143-153
**Description**: CLAUDE.md は「Commands (6)」として 6 コマンドを列挙（sdd-review-self を除外）。README.md は 7 コマンドを列挙（sdd-review-self を含む）。
**Impact**: sdd-review-self は SKILL.md で「framework-internal use only」と記載されており、CLAUDE.md のユーザー向け命令セットから除外するのは意図的設計と推定される。しかし、カウントの不一致は初見のユーザーに混乱を与える可能性がある。
**Evidence**: sdd-review-self/SKILL.md frontmatter に `description: Self-review for SDD framework development (framework-internal use only)` とあるため、意図的な除外と判断。

### LOW (1)

#### L1: README.md の settings.json に関する install.sh ヘルプテキストの不整合

**Location**: install.sh:88-89
**Description**: install.sh のヘルプテキストに `settings.json` が「Default settings (prompt before overwrite)」と記載されているが、v1.1.2 で `defaultMode: "acceptEdits"` に変更された事実が反映されていない。ヘルプ自体は機能的に問題ないが、デフォルト動作の変更について追加情報があると親切。
**Impact**: cosmetic。

---

## 確認OK項目

### 1. パス変更の一貫性 (.claude/sdd -> .sdd)

未コミット変更で `{{SDD_DIR}}` の定義が `.claude/sdd` から `.sdd` に変更された。以下を確認:

| ファイル | 更新状態 | 備考 |
|---------|---------|------|
| framework/claude/CLAUDE.md | OK | `{{SDD_DIR}}` = `.sdd` に変更済み |
| framework/claude/sdd/settings/rules/steering-principles.md | OK | `.sdd/` に更新済み (2箇所) |
| install.sh (install先) | OK | `.sdd/settings/` に更新済み |
| install.sh (version file) | OK | `.sdd/.version` に更新済み |
| install.sh (usage/help) | OK | `.sdd/` パスに更新済み |
| install.sh (uninstall) | OK | 新旧両方のパスをクリーンアップ |
| install.sh (migration v1.2.0) | OK | `.claude/sdd/` -> `.sdd/` 移行コード追加済み |
| install.sh (stale file removal) | OK | `.sdd/settings/` に更新済み |
| install.sh (.gitignore管理) | OK | `.sdd/` の gitignore エントリ追加ロジック |
| framework/claude/skills/* | OK | すべて `{{SDD_DIR}}` 変数を使用（ハードコードなし） |
| framework/claude/agents/* | OK | すべて `{{SDD_DIR}}` 変数を使用（ハードコードなし） |
| README.md | OK | `.sdd/` パスに更新済み |
| install.sh (旧マイグレーション) | OK | `.claude/sdd/` の参照は全てレガシーマイグレーション文脈のみ |

### 2. Dangling Reference チェック

| 参照元 | 参照先 | 存在確認 |
|--------|--------|---------|
| CLAUDE.md: `see sdd-roadmap refs/run.md` | refs/run.md Step 3-4, auto-fix loop, Wave QG, Blocking Protocol | OK |
| CLAUDE.md: `see sdd-roadmap refs/review.md` (Steering Feedback Loop) | refs/review.md Steering Feedback Loop Processing | OK |
| CLAUDE.md: `{{SDD_DIR}}/settings/rules/cpf-format.md` | framework/claude/sdd/settings/rules/cpf-format.md | OK |
| CLAUDE.md: `{{SDD_DIR}}/settings/templates/handover/session.md` | framework/claude/sdd/settings/templates/handover/session.md | OK |
| CLAUDE.md: `{{SDD_DIR}}/settings/templates/handover/buffer.md` | framework/claude/sdd/settings/templates/handover/buffer.md | OK |
| SKILL.md (roadmap): `refs/design.md` | framework/claude/skills/sdd-roadmap/refs/design.md | OK |
| SKILL.md (roadmap): `refs/impl.md` | framework/claude/skills/sdd-roadmap/refs/impl.md | OK |
| SKILL.md (roadmap): `refs/review.md` | framework/claude/skills/sdd-roadmap/refs/review.md | OK |
| SKILL.md (roadmap): `refs/run.md` | framework/claude/skills/sdd-roadmap/refs/run.md | OK |
| SKILL.md (roadmap): `refs/revise.md` | framework/claude/skills/sdd-roadmap/refs/revise.md | OK |
| SKILL.md (roadmap): `refs/crud.md` | framework/claude/skills/sdd-roadmap/refs/crud.md | OK |
| SKILL.md (roadmap): `init.yaml` テンプレート | framework/claude/sdd/settings/templates/specs/init.yaml | OK |
| sdd-steering SKILL.md: steering テンプレート | framework/claude/sdd/settings/templates/steering/*.md | OK |
| sdd-steering SKILL.md: カスタムテンプレート | framework/claude/sdd/settings/templates/steering-custom/*.md | OK |
| sdd-knowledge SKILL.md: knowledge テンプレート | framework/claude/sdd/settings/templates/knowledge/*.md | OK |
| sdd-architect.md: design-discovery-full.md | framework/claude/sdd/settings/rules/design-discovery-full.md | OK |
| sdd-architect.md: design-discovery-light.md | framework/claude/sdd/settings/rules/design-discovery-light.md | OK |
| sdd-architect.md: design-principles.md | framework/claude/sdd/settings/rules/design-principles.md | OK |
| sdd-taskgenerator.md: tasks-generation.md | framework/claude/sdd/settings/rules/tasks-generation.md | OK |
| sdd-steering SKILL.md: steering-principles.md | framework/claude/sdd/settings/rules/steering-principles.md | OK |
| sdd-steering SKILL.md: profiles/ | framework/claude/sdd/settings/profiles/*.md | OK |
| sdd-auditor-design.md: design-review.md | (直接参照なし — Inspector が使用) | OK |
| refs/review.md: Wave verdicts.md パス | 定義済み | OK |
| refs/revise.md: .cross-cutting/{id}/ | 定義済み | OK |

### 3. プロトコル完全性

| プロトコル | 定義場所 | 処理規則場所 | 完全性 |
|-----------|---------|------------|--------|
| Phase Gate | CLAUDE.md | refs/design.md Step 2, refs/impl.md Step 1, refs/review.md Step 2 | OK |
| SubAgent Lifecycle (background-only) | CLAUDE.md | 全 SubAgent プロファイルに `background: true` | OK (24/24) |
| Builder Self-Check | CLAUDE.md (T3 Builder) | sdd-builder.md Step 2.5 | OK |
| Auto-Fix Counter | CLAUDE.md | refs/run.md Step 4 Phase Handlers | OK |
| Blocking Protocol | CLAUDE.md (参照) | refs/run.md Step 6 | OK |
| Wave Quality Gate | CLAUDE.md (参照) | refs/run.md Step 7 | OK |
| Verdict Persistence | SKILL.md (Router) | refs/review.md Step 8 | OK |
| Consensus Mode | SKILL.md (Router) | SKILL.md Shared Protocols | OK |
| Steering Feedback Loop | CLAUDE.md | refs/review.md | OK |
| File-Based Review | CLAUDE.md | refs/review.md Review Execution Flow | OK |
| Knowledge Auto-Accumulation | CLAUDE.md | sdd-builder.md, refs/impl.md Step 4 | OK |
| Session Resume | CLAUDE.md | CLAUDE.md Session Resume セクション | OK |
| Pipeline Stop Protocol | CLAUDE.md | CLAUDE.md セクション | OK |
| Cross-Cutting Revision | CLAUDE.md, SKILL.md | refs/revise.md Part B | OK |
| Artifact Ownership | CLAUDE.md | CLAUDE.md, refs/revise.md | OK |
| Web Inspector Server Protocol | refs/review.md | refs/review.md | OK |
| Inspector Error Handling (VERDICT:ERROR) | refs/review.md | refs/review.md | OK |
| Verdict Destination Table | refs/review.md | refs/review.md | OK |

### 4. テンプレート整合性

| テンプレート | CLAUDE.md参照 | ファイル存在 | 内容一致 |
|------------|-------------|-----------|---------|
| handover/session.md | OK (session.md Format セクション) | OK | 構造が CLAUDE.md の Auto-Draft/Manual Polish 記述と一致 |
| handover/buffer.md | OK (buffer.md Format セクション) | OK | Knowledge Buffer + Skill Candidates 構造 |
| specs/design.md | (Architect が参照) | OK | Specifications + Design 構造 |
| specs/research.md | (Architect が参照) | OK | Research & Design Decisions 構造 |
| specs/init.yaml | (Router が参照) | OK | spec.yaml 初期値（phase: initialized, orchestration fields） |
| knowledge/{type}.md | (Knowledge skill が参照) | OK (3 types) | pattern, incident, reference |
| steering/*.md | (Steering skill が参照) | OK (3 files) | product, tech, structure |
| steering-custom/*.md | (Steering skill が参照) | OK (8 files) | 各カスタムトピック |
| profiles/*.md | (Steering skill が参照) | OK (3 + index) | python, typescript, rust |

### 5. settings.json 整合性

| 項目 | 状態 |
|------|------|
| 7 Skills のパーミッション | OK: 7 Skill() エントリ |
| 24 Agents のパーミッション | OK: 24 Task() エントリ |
| defaultMode: acceptEdits (v1.1.2) | OK |
| Bash パーミッション | OK: git, mkdir, ls, mv, cp, wc, which, diff, playwright-cli, npm, npx |

### 6. Agent カウント整合性

| ソース | 数 | 一致 |
|--------|---|------|
| framework/claude/agents/sdd-*.md ファイル数 | 24 | -- |
| settings.json Task() エントリ数 | 24 | OK |
| README.md 記載 | 24 | OK |
| CLAUDE.md Inspector 数 (6 design + 6 impl + 2 web + 4 dead-code) | 18 Inspector | OK |
| CLAUDE.md 3-Tier 表 | Architect, Auditor(3), TaskGenerator, Builder, Inspector(18) = 24 | OK |

---

## Split Traceability Table

直近の変更でリファクタリングやスプリットは発生していないが、未コミット変更のパス移動 (.claude/sdd -> .sdd) について追跡表を示す。

### v1.2.0 パス移動 (未コミット)

| 旧コンテンツ | 旧場所 | 新場所 | 移行状態 |
|-------------|-------|--------|---------|
| SDD Root 定義 | CLAUDE.md `.claude/sdd` | CLAUDE.md `.sdd` | OK |
| steering-principles.md 内パス | `.claude/sdd/` | `.sdd/` | OK (2箇所) |
| install先 settings | `.claude/sdd/settings/` | `.sdd/settings/` | OK |
| install先 version | `.claude/sdd/.version` | `.sdd/.version` | OK |
| install ヘルプテキスト | `.claude/sdd/` | `.sdd/` | OK (全箇所) |
| install summary | `.claude/sdd/` | `.sdd/` | OK |
| .gitignore管理 | なし | `.sdd/` エントリ追加 | OK (新機能) |
| uninstall | `.claude/sdd/settings/` のみ | `.sdd/settings/` + `.claude/sdd/settings/` | OK (両方クリーンアップ) |
| バージョン読み込み | `.claude/sdd/.version` | `.sdd/.version` (fallback: `.claude/sdd/.version`) | OK |
| migration v1.2.0 | なし | `.claude/sdd/{dir}` -> `.sdd/{dir}` | OK (新マイグレーション) |
| stale file removal | `.claude/sdd/settings/` | `.sdd/settings/` | OK |
| README.md 構造図 | `.claude/sdd/` | `.sdd/` | OK |
| README.md ユーザーファイルパス | `.claude/sdd/project/` | `.sdd/project/` | OK |

### v1.1.0 Cross-Cutting 追加

| 新コンテンツ | 場所 | 導入状態 |
|-------------|------|---------|
| Cross-Cutting Parallelism | CLAUDE.md Parallel Execution Model | OK |
| revise.md Part B | refs/revise.md | OK (202行追加) |
| REVISION_INITIATED (cross-cutting) | CLAUDE.md decisions.md Recording | OK |
| .cross-cutting/{id}/ | refs/revise.md, refs/review.md, sdd-status SKILL.md | OK |
| design.md cross-cutting brief 参照 | refs/design.md, sdd-architect.md | OK |
| background: true 全エージェント | 24 agents | OK |

### v1.1.1 settings.json 精査

| 変更内容 | 場所 | 状態 |
|---------|------|------|
| 全 Task() パーミッション追加 | settings.json | OK (24 Task エントリ) |
| プロファイル構文修正 | profiles/python.md, typescript.md, rust.md | OK |

### v1.1.2 acceptEdits モード

| 変更内容 | 場所 | 状態 |
|---------|------|------|
| defaultMode: acceptEdits | settings.json | OK |

---

## 総合評価

フレームワークのリグレッションは検出されなかった。未コミット変更（`.claude/sdd` -> `.sdd` パス移動）は以下の点で一貫性が保たれている:

1. **CLAUDE.md**: `{{SDD_DIR}}` 変数定義のみ変更。すべてのスキル・エージェントは変数経由でアクセスするため、連鎖的な変更は不要。
2. **steering-principles.md**: 唯一ハードコードパスを含むルールファイルであり、正しく更新済み。
3. **install.sh**: install先、version管理、ヘルプ、uninstall、stale file removal、.gitignore管理のすべてが更新済み。v1.2.0 マイグレーションコードも追加済み。
4. **README.md**: 構造図とユーザーファイルパスが更新済み。

直近5コミット (v1.0.3 - v1.1.2) で導入された機能はすべて適切にドキュメント化され、参照先が存在し、プロトコル定義は完全である。

**推奨修正優先度**:

| Priority | ID | Summary | Target Files |
|---|---|---|---|
| MEDIUM | M1 | kiro マイグレーションのパス整合性確認（実質的影響なし） | install.sh |
| MEDIUM | M2 | CLAUDE.md Commands (6) vs README 7 コマンドの不一致明確化 | framework/claude/CLAUDE.md or README.md |
| LOW | L1 | install.sh ヘルプの acceptEdits 情報追加 | install.sh |
