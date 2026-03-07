# Regression Detection Report

**Date**: 2026-02-24
**Reviewer**: Agent 2 (Regression Detection)
**Scope**: framework/claude/ + install.sh
**対象コミット**: v0.22.0 (c0549d7) -> v0.23.0 (3e653be) -> v0.23.1 (4d35d77) -> v1.0.0 (0d5bea5) + uncommitted changes

---

## Issues Found

### [MEDIUM] M1: SelfCheck WARN → Auditor「attention points」の伝達パスが未定義

**Location**: `framework/claude/skills/sdd-roadmap/refs/impl.md:54`
**Description**: impl.md は `WARN({items}) → log items. Pass as attention points to Auditor when dispatching impl review` と指示しているが、review.md の Auditor dispatch (Step 6) および sdd-auditor-impl.md の Input Handling には「attention points」を受け取る仕組みが定義されていない。

**影響**: Lead が impl review を dispatch する際、SelfCheck WARN 情報を Auditor コンテキストに含める方法が不明。Auditor 側も受け取り方を知らない。結果として SelfCheck WARN が事実上無視される可能性がある。

**Evidence**:
- `impl.md:54`: `WARN({items}) → log items. Pass as attention points to Auditor when dispatching impl review`
- `review.md` Step 6 (Spawn Auditor): コンテキストには review directory path, verdict output path, Steering Exceptions のみ記載。attention points の言及なし
- `sdd-auditor-impl.md` Input Handling: review directory path, verdict output path のみ。attention points の言及なし
- `run.md` Impl Review completion handler: attention points の言及なし

**推奨修正**:
1. review.md Step 6 に「If Builder SelfCheck WARN items exist, include in Auditor context as `SELFCHECK_WARN:` section」を追加
2. sdd-auditor-impl.md の Input Handling に SELFCHECK_WARN の受け取りと処理を追加
3. または run.md の Impl Review completion handler に SelfCheck WARN の Auditor 連携手順を明記

---

## Confirmed OK

- [OK] ダングリング参照: CLAUDE.md の全「see X for details」参照が有効
  - `refs/run.md` → dispatch prompts, review protocol, incremental processing: Step 4 Phase Handlers に存在
  - `refs/run.md` → auto-fix loop (Step 5), wave quality gate (Step 7), blocking protocol (Step 6): 全て存在
  - `refs/review.md` → Steering Feedback Loop: 「Steering Feedback Loop Processing」セクションに存在
  - `refs/run.md Step 3-4` → Step 3: Schedule Specs, Step 4: Parallel Dispatch Loop に存在
  - `refs/crud.md` → Wave Scheduling: Foundation-First + parallelism report に存在
  - `{{SDD_DIR}}/settings/rules/cpf-format.md` → 存在し、完全な CPF 仕様を含む

- [OK] テンプレート整合性:
  - `{{SDD_DIR}}/settings/templates/handover/session.md` → 存在、CLAUDE.md の session.md Format 記述と一致
  - `{{SDD_DIR}}/settings/templates/handover/buffer.md` → 存在、Knowledge Buffer + Skill Candidates 構造一致
  - `{{SDD_DIR}}/settings/templates/specs/design.md` → 存在、Architect が参照する構造と一致
  - `{{SDD_DIR}}/settings/templates/specs/research.md` → 存在、Architect が参照する構造と一致
  - `{{SDD_DIR}}/settings/templates/specs/init.yaml` → 存在、Router の Single-Spec Roadmap Ensure が参照

- [OK] v0.23.0 Review directory リファクタリング: `_review` → `reviews/active/` + `reviews/B{seq}/` アーカイブ
  - 旧パス `_review`, `_review-wave-{N}/`, `_review-wave-{N}-dc/` の参照が完全に除去済み
  - 新パス `reviews/active/`, `reviews/B{seq}/` が review.md, run.md, CLAUDE.md で一貫

- [OK] v0.23.0 Verdict path リファクタリング:
  - 旧: `specs/verdicts-wave.md`, `specs/verdicts-dead-code.md`, `specs/verdicts-cross-check.md`
  - 新: `{{SDD_DIR}}/project/reviews/{wave,dead-code,cross-check}/verdicts.md`
  - 全ファイルで新パスに統一済み。旧パスの残留なし

- [OK] v0.23.1 修正:
  - Auditor verdict scope 修正: `GO/CONDITIONAL/NO-GO/SPEC-UPDATE-NEEDED` → Design Auditor は `GO/CONDITIONAL/NO-GO`、Impl Auditor のみ `SPEC-UPDATE-NEEDED`
  - Knowledge flush パス: impl.md に 1-spec/multi-spec 分岐追加済み
  - Profiles パス: CLAUDE.md に追加済み
  - Decision types: `STEERING_UPDATE`, `STEERING_EXCEPTION`, `SESSION_END` 追加済み
  - 参照修正: `§Counter Reset` → `§Auto-Fix Counter Limits`

- [OK] v1.0.0 Parallel Execution Model:
  - CLAUDE.md に Parallel Execution Model セクション追加
  - run.md に Island Spec Detection (Wave Bypass), Dispatch Loop, Readiness Rules, Design Lookahead, Phase Handlers 追加
  - crud.md に Foundation-First, Parallelism Report, Backfill 追加
  - Router SKILL.md に Backfill check 追加
  - `Concurrent SubAgent limit: 24` → `No framework-imposed SubAgent limit` に変更 (制限撤廃)

- [OK] Uncommitted changes (SelfCheck):
  - sdd-builder.md: Step 5 SELF-CHECK 追加、Step 6 MARK COMPLETE 更新、Completion Report に SelfCheck フィールド追加
  - impl.md: Builder incremental processing に SelfCheck 処理追加
  - 旧 Step 5 の AC verification が SELF-CHECK item 1 に移動済み (内容保持確認済み)

- [OK] Uncommitted changes (Steering Integration):
  - sdd-taskgenerator.md: Step 2 に steering context 適用指示追加
  - tasks-generation.md: Avoid ルール緩和 + Steering Integration セクション追加
  - 相互参照が正確 (`see tasks-generation.md Steering Integration`)

- [OK] プロトコル完全性:
  - Phase Gate: CLAUDE.md に定義、design.md/impl.md/review.md で個別チェック実装
  - Auto-Fix Counter: CLAUDE.md に定義、run.md に実装 (retry_count, spec_update_count, aggregate cap)
  - Blocking Protocol: run.md Step 6 に完全な処理ルール
  - Wave Quality Gate: run.md Step 7 に完全な処理ルール
  - Consensus Mode: Router SKILL.md に定義、review.md/run.md で参照
  - Verdict Persistence: Router SKILL.md に定義、review.md Step 8 で参照
  - Steering Feedback Loop: CLAUDE.md に概要、review.md に完全な処理ルール
  - Builder parallel coordination: CLAUDE.md に概要、impl.md に詳細
  - Knowledge Auto-Accumulation: CLAUDE.md に概要、impl.md/run.md に実装
  - Session Resume: CLAUDE.md に7ステップ定義
  - Pipeline Stop Protocol: CLAUDE.md に定義

- [OK] Agent 数の整合性: 23 agents (1 architect, 3 auditors, 18 inspectors, 1 builder, 1 taskgenerator - E2E inspector は web projects のみ)

- [OK] Skill 数の整合性: CLAUDE.md Commands (6) と実 SKILL.md 数 (7: sdd-steering, sdd-roadmap, sdd-status, sdd-handover, sdd-knowledge, sdd-release, sdd-review-self)。sdd-review-self はフレームワーク内部用であり Commands テーブルに含めないのは意図的

- [OK] install.sh:
  - バージョン参照: `--version v1.0.0` (最新)
  - `/sdd-impl` → `/sdd-roadmap impl` 修正済み (v1.0.0 diff 確認)
  - agents install パス: `$SRC/framework/claude/agents` → `.claude/agents` (正しい)
  - stale file removal: agents の `sdd-*.md` パターンで正しくスコープ

---

## Split Traceability Table

v0.22.0 → v1.0.0 の主要リファクタリングにおけるコンテンツ移動追跡:

| 元の内容 | 元の場所 | 移動先 | 状態 |
|----------|---------|--------|------|
| Review directory `_review/` pattern | review.md (v0.22.0) | review.md `reviews/active/` + `reviews/B{seq}/` | OK - 完全移行 |
| Verdict path `specs/verdicts-wave.md` | review.md (v0.22.0) | `{{SDD_DIR}}/project/reviews/wave/verdicts.md` | OK - 完全移行 |
| Verdict path `specs/verdicts-dead-code.md` | review.md (v0.22.0) | `{{SDD_DIR}}/project/reviews/dead-code/verdicts.md` | OK - 完全移行 |
| Verdict path `specs/verdicts-cross-check.md` | review.md (v0.22.0) | `{{SDD_DIR}}/project/reviews/cross-check/verdicts.md` | OK - 完全移行 |
| Verdict path `specs/{feature}/verdicts.md` | review.md (v0.22.0) | `{{SDD_DIR}}/project/specs/{feature}/reviews/verdicts.md` | OK - 完全移行 |
| Previously-resolved ref `specs/verdicts-wave.md` | review.md (v0.22.0) | `{{SDD_DIR}}/project/reviews/wave/verdicts.md` | OK - 完全移行 |
| Review dir cleanup: "Delete review directory" | review.md (v0.22.0) Step 7 | review.md Step 9: "Archive: rename active/ → B{seq}/" | OK - 意図的変更 (削除→アーカイブ) |
| SubAgent limit "24 (3 pipelines x 7)" | CLAUDE.md (v0.23.1) | "No framework-imposed SubAgent limit" | OK - 意図的変更 (制限撤廃) |
| run.md Step 3 pipeline state diagram | run.md (v0.23.1) | run.md Step 3 Island Detection + Step 4 Dispatch Loop | OK - 簡易図→詳細スケジューラ |
| run.md Step 4 sequential pipeline | run.md (v0.23.1) | run.md Step 4 Parallel Dispatch Loop + Readiness Rules | OK - 直列→並列モデル |
| run.md Design/Impl Phase headers | run.md (v0.23.1) | run.md Phase Handlers (Design/Design Review/Impl/Impl Review completion) | OK - 名前変更 |
| crud.md Step 4 wave organization | crud.md (v0.23.1) | crud.md Step 4 Parallel-Optimized Wave Scheduling | OK - 拡張 |
| Builder Step 5 "MARK COMPLETE: Verify ACs" | sdd-builder.md (HEAD~) | Step 5 SELF-CHECK item 1 (AC coverage) + Step 6 MARK COMPLETE | OK - AC verification 保持 |
| tasks-generation Avoid "File paths and directory structure" | tasks-generation.md (HEAD~) | "Inventing file paths -- use structure.md Directory Patterns" | OK - 意図的緩和 |
| Decision types: `SESSION_START` only | CLAUDE.md (v0.22.0) | `SESSION_START`/`SESSION_END` pair | OK - SESSION_END 追加 |
| Decision types: missing STEERING_UPDATE | CLAUDE.md (v0.22.0) | `STEERING_UPDATE` added | OK - 追加 |

---

## Overall Assessment

フレームワークのリファクタリング(v0.23.0 review redesign, v0.23.1 fixes, v1.0.0 parallel execution model, uncommitted SelfCheck/Steering Integration)において、コンテンツの移行は高い精度で行われている。

**ダングリング参照**: なし。全ての「see X for details」参照が有効なコンテンツを指している。

**Split losses**: 検出されず。旧コンテンツは全て新しい場所に移行済み。

**プロトコル完全性**: 全プロトコルが少なくとも1ファイルで完全な処理ルールを持つ。

**テンプレート整合性**: CLAUDE.md が参照する全テンプレートが存在し、内容が一致。

**唯一の問題点**: SelfCheck WARN → Auditor 連携のパス定義が不完全 (M1)。impl.md に指示があるが、受け取り側 (review.md, sdd-auditor-impl.md) に対応する定義がない。これは uncommitted changes で新規追加された機能であり、既存機能のリグレッションではなく新機能の定義不足。ただし、このまま commit すると impl.md の指示と review.md/auditor の実装にギャップが生じるため、MEDIUM として報告。
