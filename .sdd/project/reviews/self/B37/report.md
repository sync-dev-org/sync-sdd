# SDD Framework Self-Review Report
**Date**: 2026-03-05T03:16:29+0900
**Agents**: 4 dispatched, 4 completed

## False Positives Eliminated

| Finding | Agent | Reason |
|---|---|---|
| M\|agent-frontmatter\|sdd-*.md — `background: true` 未認定フィールド疑い | Agent-4 | D96 (USER_DECISION): 公式サポートフィールドと確認済み。保持 |
| UNCERTAIN\|agent-tool-params — `Agent(model=..., run_in_background=true)` 入力スキーマ未確認 | Agent-4 | 現セッションの Agent ツール定義に `model`/`run_in_background` は明示的な省略可能パラメータとして存在。D10 (USER_DECISION) でも background dispatch 採用を決定済み |

---

## A) 自明な修正 (8件) — OK で全件修正します

| ID | Sev | Location | Summary | Fix |
|---|---|---|---|---|
| A-1 | H | `framework/claude/skills/sdd-roadmap/SKILL.md:70` | Router の単一 Spec enrollment 例外に `review impl --cross-check` と `review design --wave N` が欠落。誤って `specs/{feature}/spec.yaml` 読み取り経路へ進入する | 例外リストに両コマンドを追加 |
| A-2 | M | `framework/claude/skills/sdd-roadmap/SKILL.md:72` | no-roadmap 時の BLOCK 対象にも `review impl --cross-check` と `review design --wave N` が未列挙 (A-1 と対称) | BLOCK 対象リストに両コマンドを追加 |
| A-3 | H | `framework/claude/skills/sdd-roadmap/refs/run.md:182` | `refs/design.md`/`refs/review.md`/`refs/impl.md` を refs 配下から相対参照しており `refs/refs/*.md` となり到達不能 | `sdd-roadmap/refs/design.md` 等、スキルルートからの明示パスに修正 |
| A-4 | M | `framework/claude/skills/sdd-roadmap/refs/revise.md:71` | A-3 と同じ参照記法上の曖昧さ（実行位置依存の解決） | A-3 と同様にスキルルートからの明示パスに修正 |
| A-5 | M | `framework/claude/skills/sdd-reboot/refs/reboot.md:172` | 120行は「sdd-roadmap の refs/run.md」と明示する一方、172行は `refs/run.md` のみで参照先が不定 | 172行を「sdd-roadmap の refs/run.md」と明示 |
| A-6 | M | `framework/claude/sdd/settings/templates/review-self/prep.md:13` | `git rev-list --count HEAD` は CLAUDE.md の Bash ヒューリスティクス回避規約（`--count` 回避）と矛盾し、自己矛盾が生じる | `git log --oneline` 等の代替コマンドに置換 |
| A-7 | L | `framework/claude/skills/sdd-review-self/SKILL.md:107,293` | Prep/Auditor の SubAgent fallback 手順番号が `1→3→4`（293行も同様）で欠番あり | `1→2→3` に修正 |
| A-8 | L | `framework/claude/skills/sdd-roadmap/SKILL.md:44` | Auto-detect 選択肢が `Run / Update / Reset` だが、Detect Mode 定義は `delete`。`Reset` が `delete` にマップされることが未明示 | Router コメントに `Reset = delete` の対応を明記 |

---

## B) ユーザー判断が必要 (4件)

### B-1: Impl Auditor の verdict 式に High 1〜3 件の分岐が欠落

**Location**: `framework/claude/agents/sdd-auditor-impl.md:220-230`

**Description**:
最終判定式は「`>3 High → CONDITIONAL`」の次が「`only Medium/Low AND tests pass → GO`」となっており、High が 1〜3 件の場合が未定義。この範囲に落ちた findings は `GO` にフォールスルーする可能性がある。

```
ELSE IF >3 High issues:
    Verdict = CONDITIONAL        ← >3 のみ定義
ELSE IF only Medium/Low issues AND tests pass:
    Verdict = GO                 ← 1-3 High も "only Medium/Low" を満たさないが分岐なし
```

**Impact**: High 1〜3 件の指摘が `GO` と判定されうる。品質ゲートが意図より緩い。

**Recommendation**: 分岐を `any High → CONDITIONAL` に統一する — `>3 High` と `1-3 High` で異なる扱いにする設計意図がないなら統一が最もシンプル。D104 でデザイン Auditor は「High → NO-GO」に変更済み。同様に Impl Auditor を `any High → CONDITIONAL` に揃えるか、それとも件数で閾値を設けるか確認が必要。

---

### B-2: Design-only reboot が実行不能な Blocking Protocol を流用

**Location**: `framework/claude/skills/sdd-reboot/refs/reboot.md:180`

**Description**:
Design-only reboot のフローが `run.md Step6 Blocking Protocol` を流用しているが、同プロトコルは `implementation-complete` フェーズ前提の `fix` 分岐を含む。Design-only reboot はそのフェーズに到達しないため、`fix` 分岐が実行不能となる。

**Impact**: Design-only reboot で SPEC-UPDATE-NEEDED が発生した際、`fix` 分岐に誤進入してプロトコルが破綻する可能性。

**Recommendation**: Design-only reboot 向けに Blocking Protocol の適用範囲を限定する記述を追加（`fix` 分岐除外の注記）、または Design-only 専用のシンプルなサブセットを定義する — 流用元の前提条件不整合であり、実装上は注記追加のみで済む可能性が高い。

---

### B-3: Wave QG cross-check の SPEC-UPDATE-NEEDED に上限カウンター規約が未記載

**Location**: `framework/claude/skills/sdd-roadmap/refs/run.md:249`

**Description**:
Wave QG cross-check の `SPEC-UPDATE-NEEDED` 分岐に、CLAUDE.md の上限規約（`spec_update_count` max2 / aggregate cap6）到達時のエスカレーション手順が明記されていない。`NO-GO` 分岐には上限記述があるため、同一ループ内で終端条件が非対称。

**Impact**: SPEC-UPDATE-NEEDED が連続した場合、理論上は無限ループになりうる（実際は aggregate cap が効くが、文書として明確でない）。

**Recommendation**: NO-GO 分岐と対称に `spec_update_count max2 / aggregate cap6 到達 → エスカレーション` の規約を追記する — ルール自体は CLAUDE.md に存在するため、参照追記で解決できる。

---

### B-4: Revise Detect Mode に明示オーバーライドがなく先頭語衝突時に誤ルートの余地

**Location**: `framework/claude/skills/sdd-roadmap/SKILL.md:32`

**Description**:
`revise` の Single/Cross-Cutting 判定が「先頭語がいずれかの spec 名に一致するか否か」のみに依存。spec 名が他 spec 名の接頭語になっているケース（例: `auth` と `auth-admin`）で意図しない Single-Spec ルートへ進入する可能性がある。`--cross-cutting` 等の明示オーバーライドが存在しない。

**Impact**: spec 名が衝突しやすいプロジェクトでユーザー意図と異なるモードで実行される可能性。現時点では発生事例なし。

**Recommendation**: `--cross-cutting` フラグを追加してユーザーが明示指定できるようにするか、現状の「先頭語マッチ失敗 → Cross-Cutting」ロジックで十分とみなして defer する — 自動判定の誤ルートリスクは低く、発生したら気づきやすいため defer でも許容範囲。

---

## Platform Compliance

| Item | Status | Source |
|---|---|---|
| agent frontmatter required fields | OK | Agent-4 verified |
| agent frontmatter model aliases | OK | Agent-4 verified |
| skills frontmatter description/allowed-tools/argument-hint | OK | Agent-4 verified |
| built-in general-purpose subagent | OK | Agent-4 verified |
| settings permission rule format | OK | Agent-4 verified |
| settings agent/skill entries match files | OK | Agent-4 verified |
| `background: true` frontmatter field | OK (FP) | D96 — 公式サポートフィールド確認済み |
| `Agent(model=..., run_in_background=true)` パラメータ | OK (FP) | Agent ツール定義で明示的に listed; D10 で設計決定済み |
