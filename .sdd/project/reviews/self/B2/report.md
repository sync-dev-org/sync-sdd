# SDD Framework Self-Review Report
**Date**: 2026-02-24
**Mode**: full
**Agents**: 5 dispatched, 5 completed

---

## False Positives Eliminated

| Finding | Reporting Agent | Elimination Reason |
|---|---|---|
| Commands (6) vs 実際の skill 数 (7) | Agent 3 L2, Agent 5 L1 | 意図的設計決定: decisions.md D2 で sdd-review-self を framework-internal として除外を記録済み |
| Design Auditor が SPEC-UPDATE-NEEDED を出せない | Agent 1 M2 | 設計意図: CLAUDE.md L23 で明示的に "Impl Auditor also: SPEC-UPDATE-NEEDED" — Design Auditor は GO/CONDITIONAL/NO-GO のみが仕様 |
| Wave-Scoped Cross-Check ボイラープレート重複 (13 Inspector) | Agent 5 L2 | 設計制約: SubAgent は self-contained が必須。ルール抽出は可能だが現状は意図的冗長 |
| sdd-review-self が general-purpose subagent 使用 | Agent 5 L3 | 正常: general-purpose は Claude Code ビルトインの SubAgent タイプ |
| SelfCheck FAIL-RETRY-2 の spec.yaml 更新タイミング | Agent 1 M1 | M1 に統合: spec.yaml 更新は「ALL Builders complete」後 (impl.md L60) で明確。問題の本質は M1 の SelfCheck プロトコル矛盾 |

---

## HIGH (1)

### H1: CLAUDE.md Builder 記述が SELF-CHECK を未反映
**Location**: `framework/claude/CLAUDE.md:25`
**Reporters**: Agent 3 (primary), Agent 5 (secondary)
**Description**: CLAUDE.md Role Architecture テーブルの Builder 行が「TDD implementation. RED→GREEN→REFACTOR cycle.」のまま。実際の sdd-builder.md は 6ステップ (RED→GREEN→REFACTOR→VERIFY→SELF-CHECK→MARK COMPLETE) に拡張済み。SelfCheck フィールドも完了レポートに追加されたが CLAUDE.md に言及なし。
**Evidence**: CLAUDE.md L25 vs sdd-builder.md L35-68
**Impact**: Lead が Builder の出力形式を正しく解釈できないリスク。refs/impl.md に処理ロジックがあるため実運用への影響は限定的だが、CLAUDE.md がハイレベル仕様として不完全。

---

## MEDIUM (2)

### M1: SelfCheck プロトコル内部矛盾 (FAIL-RETRY vs 自動 WARN ダウングレード)
**Location**: `framework/claude/agents/sdd-builder.md:64` vs `framework/claude/agents/sdd-builder.md:117` + `framework/claude/skills/sdd-roadmap/refs/impl.md:55`
**Reporters**: Agent 3 M1 (FAIL-RETRY-1 未定義), Agent 1 M1 (タイミング曖昧性) — 統合
**Description**: 矛盾する 2 つの指示が共存:
- sdd-builder.md L64: 「After 2 failures, downgrade to WARN and continue.」 → Builder が自律的に WARN に変換
- 完了レポート形式 (L117): `SelfCheck: {PASS | WARN({items}) | FAIL-RETRY-{N}({items})}` → FAIL-RETRY を Lead に報告
- impl.md L55: `FAIL-RETRY-2({items}) → Lead judgment` → Lead が判断

Builder が FAIL を WARN にダウングレードするなら、FAIL-RETRY-{N} は完了レポートに出現しない。impl.md の FAIL-RETRY-2 処理は dead code になる。
**Fix**: 「downgrade to WARN」を削除し、FAIL-RETRY-{N} を Lead に報告する設計に統一。

### M2: SelfCheck WARN → Auditor 伝達パス未定義
**Location**: `framework/claude/skills/sdd-roadmap/refs/impl.md:54`
**Reporter**: Agent 2 M1
**Description**: impl.md が「WARN({items}) → log items. Pass as attention points to Auditor when dispatching impl review」と指示しているが、受け取り側の review.md (Step 6: Spawn Auditor) および sdd-auditor-impl.md の Input に「attention points」受信機構が未定義。
**Evidence**: review.md L60-63 の Auditor dispatch には attention points のフィールドなし。
**Fix**: review.md の Auditor dispatch context にオプショナルな Builder SelfCheck attention points を追加。

---

## LOW (3)

### L1: Dead Code Review パス使い分けの曖昧性
**Location**: `framework/claude/skills/sdd-roadmap/refs/review.md:49-53` / `refs/run.md`
**Reporters**: Agent 1 L1, Agent 3 L1
**Description**: Wave QG 内の dead-code review は wave パスに書き込むが、standalone dead-code review は dead-code パスに書く。この使い分けが review.md 側で明文化されていない。

### L2: review dead-code の phase gate スキップが CLAUDE.md に未記載
**Location**: `framework/claude/skills/sdd-roadmap/refs/review.md:20` / `framework/claude/CLAUDE.md`
**Reporter**: Agent 1 L2
**Description**: review.md で dead-code review は phase gate をスキップする設計だが、CLAUDE.md の Phase Gate セクションに例外として記載されていない。

### L3: TaskGenerator 失敗時のエラーハンドリング未明示
**Location**: `framework/claude/skills/sdd-roadmap/refs/impl.md:32`
**Reporter**: Agent 3 L3
**Description**: tasks.yaml 生成失敗時のリトライ/エスカレーション処理が明示されていない。SubAgent Failure Handling の汎用ルール (Lead 判断) で対応可能だが、明示的な指示がない。

---

## Claude Code Compliance Status

| Item | Status |
|---|---|
| agents/ YAML frontmatter | PASS (23/23) |
| skills/ frontmatter | PASS (7/7) |
| settings.json | PASS |
| install.sh paths | PASS |
| Model selection | PASS |
| Tool permissions | PASS |

---

## Overall Assessment

フレームワーク全体の品質は高い。CC準拠は完全。H1 と M1 は今回追加した SELF-CHECK 機能に起因する新規 issue であり、既存機能のリグレッションはゼロ。

---

## Recommended Fix Priority

| Priority | ID | Summary | Target Files |
|---|---|---|---|
| 1 | H1 | CLAUDE.md Builder 記述に SELF-CHECK 反映 | `framework/claude/CLAUDE.md` |
| 2 | M1 | SelfCheck プロトコル統一 (FAIL-RETRY を Lead 報告に一本化) | `framework/claude/agents/sdd-builder.md` |
| 3 | M2 | Auditor attention points 受信機構追加 | `framework/claude/skills/sdd-roadmap/refs/review.md` |
