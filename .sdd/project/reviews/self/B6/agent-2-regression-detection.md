## Regression Detection Report

**Date**: 2026-02-24
**Scope**: v1.0.3 (f91949a) ~ v1.1.2 (dd14ce8) + uncommitted `.sdd` migration changes
**Reviewer**: Agent 2 (Regression Detection)

---

### Issues Found

#### [MEDIUM] M1: kiro migration は `.claude/sdd/` をターゲットにしているが、v1.2.0 migration が正しくチェインする
- **File**: `install.sh:237-263` (kiro migration) → `install.sh:386-406` (v1.2.0 migration)
- **Status**: 実際にはチェイン正常。kiro → `.claude/sdd/` (v0.4.0) → `.sdd/` (v1.2.0) の順序で実行される。
- **注意点**: ただし kiro migration 内で `mkdir -p .claude/sdd/project` を明示的に作成しているため、v1.2.0 migration の `mv ".claude/sdd/$dir" ".sdd/$dir"` と整合する。問題なし。

#### [LOW] L1: CLAUDE.md `Commands (6)` と実際の Skills 数 (7) の不一致
- **File**: `framework/claude/CLAUDE.md:142`
- **説明**: CLAUDE.md は `### Commands (6)` として 6 コマンドをリスト。実際の `framework/claude/skills/sdd-*/SKILL.md` は 7 ファイル。7 つ目は `sdd-review-self` (description: "framework-internal use only")。
- **判定**: `sdd-review-self` はユーザー向けコマンドではなくフレームワーク内部ツール。Commands テーブルはユーザー向けを意図しているため、整合性としては問題ない。ただし README.md では `7 skills` と記載されており、ユーザーが混乱する可能性がある。
- **推奨**: 低優先度。CLAUDE.md の `Commands (6)` の隣に注釈を追加するか、README.md 側で「6 user commands + 1 internal skill」と明確化するとよい。

---

### Confirmed OK

#### 1. `.claude/sdd/` → `.sdd/` パス移行の完全性

| ファイル | 旧パス `.claude/sdd/` | 新パス `.sdd/` | 状態 |
|---------|----------------------|---------------|------|
| `framework/claude/CLAUDE.md` (SDD Root) | `.claude/sdd` | `.sdd` | OK (uncommitted) |
| `framework/claude/sdd/settings/rules/steering-principles.md` L25 | `.claude/sdd/` | `.sdd/` | OK (uncommitted) |
| `framework/claude/sdd/settings/rules/steering-principles.md` L80 | `.claude/sdd/project/specs/` etc | `.sdd/project/specs/` etc | OK (uncommitted) |
| `install.sh` (全箇所) | `.claude/sdd/` | `.sdd/` | OK (uncommitted) |
| `README.md` (構造図・パス) | `.claude/sdd/` | `.sdd/` | OK (uncommitted) |
| `.gitignore` | N/A | `.sdd/` 追加 | OK (uncommitted) |
| Skills/Agents/Rules 内 | `{{SDD_DIR}}` 経由 | 変更不要 | OK |

全ファイルで `{{SDD_DIR}}` 変数経由のパス参照を使用しており、CLAUDE.md の `{{SDD_DIR}}` = `.sdd` 変更 1 箇所で全パスが正しく解決される。Skills、Agents、Rules 内にハードコードされた `.claude/sdd/` パスは存在しない。

#### 2. settings.json 権限の完全性 (v1.1.1)

| 対象 | settings.json 内 | 実ファイル | 一致 |
|------|-----------------|-----------|------|
| Skills (7) | `Skill(sdd-roadmap)` 等 7 エントリ | 7 SKILL.md | OK |
| Agents (24) | `Task(sdd-architect)` 等 24 エントリ | 24 agent .md | OK |
| `defaultMode: acceptEdits` | 設定済み (v1.1.2) | N/A | OK |

settings.json の Skill/Task エントリと実ファイルが完全一致。

#### 3. agent `background: true` フラグ (v1.0.3)

全 24 agent 定義に `background: true` が設定されていることを確認。v1.0.3 で foreground exception を除去した変更が全エージェントに反映済み。

#### 4. Cross-cutting revision (v1.1.0) の完全性

- `refs/revise.md` に Part A (Single-Spec) と Part B (Cross-Cutting) の両方が完全に定義
- CLAUDE.md `### Parallel Execution Model` に Cross-Cutting Parallelism が追加済み
- `sdd-status/SKILL.md` に Cross-Cutting Revisions セクションが追加済み
- SKILL.md Router の Mode Detection に `revise [instructions]` (Cross-Cutting) が追加済み
- `refs/design.md` Step 3 に cross-cutting brief パスのハンドリングが追加済み
- `refs/review.md` Verdict Destination に Cross-cutting review 行が追加済み
- CLAUDE.md `decisions.md Recording` に `REVISION_INITIATED` + `(cross-cutting)` 注記が追加済み

#### 5. dangling reference チェック

| 参照元 (CLAUDE.md) | 参照先 | 内容一致 |
|-------------------|--------|---------|
| "see sdd-roadmap `refs/run.md`" (L82) | `refs/run.md` Step 3-4 dispatch loop | OK |
| "See sdd-roadmap `refs/crud.md`" (L88) | `refs/crud.md` Create Mode Step 4 | OK |
| "See sdd-roadmap `refs/revise.md` Part B" (L95) | `refs/revise.md` Part B Step 6-7 | OK |
| "see sdd-roadmap `refs/run.md` Step 3-4" (L97) | `refs/run.md` Step 3-4 | OK |
| "see sdd-roadmap `refs/run.md`" (L176) | `refs/run.md` Step 5-7 | OK |
| "see sdd-roadmap `refs/review.md`" (L206) | `refs/review.md` Steering Feedback Loop | OK |
| "`{{SDD_DIR}}/settings/rules/cpf-format.md`" (L332) | `rules/cpf-format.md` | OK |
| "`{{SDD_DIR}}/settings/templates/handover/session.md`" (L240) | `templates/handover/session.md` | OK |
| "`{{SDD_DIR}}/settings/templates/handover/buffer.md`" (L250) | `templates/handover/buffer.md` | OK |
| "`{{SDD_DIR}}/settings/templates/specs/init.yaml`" (SKILL.md L76) | `templates/specs/init.yaml` | OK |

全参照先にコンテンツが存在し、内容が一致。

#### 6. テンプレート整合性

| テンプレート | CLAUDE.md 参照 | 実ファイル | セクション一致 |
|------------|---------------|-----------|--------------|
| `handover/session.md` | session.md Format セクション | 存在・Direction/Session Context/Accomplished/Resume 構造 | OK |
| `handover/buffer.md` | buffer.md Format セクション | 存在・Knowledge Buffer + Skill Candidates 構造 | OK |
| `specs/design.md` | Architect Step 1 | 存在・Specifications/Overview/Architecture 以降の構造 | OK |
| `specs/research.md` | Architect Step 1 | 存在・Summary/Research Log/Architecture 以降の構造 | OK |
| `specs/init.yaml` | Router L76 | 存在・全フィールド定義 | OK |
| `steering/product.md` | Product Intent セクション | 存在・User Intent/Vision/Success Criteria/Anti-Goals | OK |
| `steering/tech.md` | Steering Configuration | 存在 | OK |
| `steering/structure.md` | Steering Configuration | 存在 | OK |

#### 7. プロトコル完全性

| プロトコル | 定義場所 | 処理ルール場所 | 完全性 |
|----------|---------|--------------|--------|
| Phase Gate | CLAUDE.md L68-74 | design.md Step 2, impl.md Step 1, review.md Step 2 | OK |
| Auto-Fix Counter | CLAUDE.md L170-176 | run.md Step 4 Phase Handlers, run.md Step 7 | OK |
| Blocking Protocol | CLAUDE.md (概要) | run.md Step 6 | OK |
| Verdict Persistence | SKILL.md (Router) | review.md Step 8-9 | OK |
| Consensus Mode | SKILL.md (Router) | review.md (参照) | OK |
| Steering Feedback Loop | CLAUDE.md L204-206 | review.md Steering Feedback Loop Processing | OK |
| Knowledge Auto-Accumulation | CLAUDE.md L279-284 | impl.md Step 3, run.md Step 7c Post-gate | OK |
| Builder Self-Check | CLAUDE.md L25 | builder.md Step 2.5, impl.md Step 3 | OK |
| SubAgent Background Dispatch | CLAUDE.md L78 | 全 agent `background: true` | OK |
| Cross-Cutting Revision | CLAUDE.md L95 | revise.md Part B Steps 1-9 | OK |
| Session Resume | CLAUDE.md L265-277 | (Lead direct) | OK |
| Pipeline Stop Protocol | CLAUDE.md L286-292 | (Lead direct) | OK |
| SPEC-Code Atomicity | CLAUDE.md L158-161 | run.md Phase Handlers | OK |
| Web Inspector Server Protocol | review.md L47-63 | review.md Step 3a, 5a | OK |
| File-based review communication | CLAUDE.md L34-36, L103 | review.md Step 3-9 | OK |

#### 8. Split Traceability (リファクタリング追跡)

v0.23.0 (fe54f2e) の CLAUDE.md スリム化 + sdd-roadmap Progressive Disclosure 分割以降の追跡:

| 元コンテンツ (CLAUDE.md) | 分割先 | 状態 |
|------------------------|--------|------|
| Design dispatch details | refs/design.md | 完全移行済み |
| Impl dispatch details | refs/impl.md | 完全移行済み |
| Review protocol details | refs/review.md | 完全移行済み |
| Run orchestration details | refs/run.md | 完全移行済み |
| Create/Update/Delete details | refs/crud.md | 完全移行済み |
| Revise details | refs/revise.md | 完全移行済み (v1.1.0 で Part B 追加) |
| Consensus Mode protocol | SKILL.md Router Shared Protocols | 完全 |
| Verdict Persistence Format | SKILL.md Router Shared Protocols | 完全 |
| Counter limits (概要) | CLAUDE.md に残留 | OK (refs に詳細) |
| Parallel Execution Model | CLAUDE.md に残留 (概要) | OK (refs に詳細) |

CLAUDE.md は概要・方針を保持し、refs に詳細を委譲するパターンが一貫している。Split loss は検出されなかった。

#### 9. v1.2.0 migration (uncommitted) の install.sh 整合性

- v1.2.0 migration ブロックが正しい位置 (v0.20.0 migration の後) に挿入
- `settings`, `project`, `handover` の 3 ディレクトリを移行
- `.version` ファイルも移行
- 既存 `.sdd/` ディレクトリとの衝突チェックあり
- uninstall にも新旧両方のパスの cleanup 処理を追加
- stale file removal も `.sdd/settings/` パスに更新済み
- `.gitignore` への `.sdd/` 自動追加ロジック追加済み
- summary 出力も `.sdd/` に更新済み

---

### Overall Assessment

**判定: 問題なし (MEDIUM 0件, LOW 1件)**

直近 5 コミット (v1.0.3 ~ v1.1.2) および uncommitted の `.sdd/` パス移行変更について、包括的なリグレッション検査を実施した。

**主要な検証結果:**

1. **パス移行 (`.claude/sdd/` → `.sdd/`)**: CLAUDE.md の `{{SDD_DIR}}` 定義変更 1 箇所で全パスが正しく解決される設計。Skills/Agents/Rules 内にハードコードパスは存在せず、クリーンな移行。install.sh の migration block も正しくチェインされている。

2. **settings.json 権限精査 (v1.1.1)**: 全 7 Skills と全 24 Agents が settings.json に正確にリストされている。`defaultMode: acceptEdits` も正しく追加。

3. **Cross-cutting revision (v1.1.0)**: revise.md Part B に完全な処理フローが定義。CLAUDE.md、SKILL.md Router、refs/design.md、refs/review.md、sdd-status の全箇所に適切な参照が追加。

4. **Background-only dispatch (v1.0.3)**: 全 24 agent 定義に `background: true` が設定済み。

5. **dangling reference**: 全参照先のコンテンツ存在を確認。Split loss なし。

6. **プロトコル完全性**: 15 プロトコルすべてに完全な処理ルールが存在。

フレームワークは健全な状態にあり、リグレッションは検出されなかった。
