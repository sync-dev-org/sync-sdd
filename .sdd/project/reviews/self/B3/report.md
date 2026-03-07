# SDD Framework Self-Review Report (B3)

**Date**: 2026-02-24
**Version**: v1.0.3+uncommitted (E2E/Visual inspector split)
**Mode**: full
**Agents**: 5 dispatched, 5 completed

---

## False Positives Eliminated

| Finding | Reporting Agent | Elimination Reason |
|---|---|---|
| Wave-Scoped template redundancy across 12 inspectors | Agent 5 (Dead Code) | Intentional: SubAgents have no shared memory. Each agent must carry its own context template. |
| Low-frequency steering-custom templates | Agent 5 (Dead Code) | Not unused: templates are consumed when user runs `/sdd-steering custom`. Low invocation frequency ≠ dead code. |
| CLAUDE.md Commands (6) vs README Commands (7) | Agents 2,3,5 | Intentional design decision (session.md/decisions.md に記録済み): sdd-review-self はフレームワーク開発専用ツールのため CLAUDE.md Commands テーブルから意図的に除外。README は全スキルのリファレンスとして7個を掲載。 |

---

## CRITICAL (0)

なし

---

## HIGH (0)

なし

---

## MEDIUM (2)

### M1: CLAUDE.md Inspector数表記「+2 web」の曖昧さ

**Location**: `framework/claude/CLAUDE.md:26`
**Reporting Agents**: Agent 1 (Flow Integrity)
**Description**: 変更後の表記 `6 design + 6 impl inspectors +2 web (web projects), 4 (dead-code)` は、+2 web が impl review 専用であることを明示していない。review.md の Design Review セクションは 6 inspectors のみを列挙し、Impl Review セクションのみが E2E + Visual を含む。現在の表記だと「design にも web inspector が付く」と誤読される可能性がある。
**Evidence**: review.md Design Review = 6 inspectors, Impl Review = 6 + 2 web. CLAUDE.md の表記はこの区別を伝えていない。

### M2: Web Inspector Server Protocol — dev serverコマンド不在時のハンドリング未定義

**Location**: `framework/claude/skills/sdd-roadmap/refs/review.md:48-61`
**Reporting Agents**: Agent 3 (Consistency)
**Description**: Protocol の Step 1 は「Read dev server command from steering/tech.md Common Commands」とあるが、tech.md に web stack indicator があるがコマンドがない場合の処理が未定義。「If server fails to start: dispatch web inspectors anyway」は起動失敗をカバーするが、コマンド自体が見つからないケースは別。
**Evidence**: Web inspector dispatch の条件は「tech.md に web stack indicators がある」。dev server command の存在は前提だが明示されていない。Leading case は tech.md にフレームワーク名だけ書いて Common Commands セクションが空のケース。

---

## LOW (2)

### L1: revise.md の redundant phase set

**Location**: `framework/claude/skills/sdd-roadmap/refs/revise.md:39,48`
**Reporting Agents**: Agent 3 (Consistency)
**Description**: Step 4 で `phase = design-generated` を設定し、Step 5 の Architect 完了後に再度同じ値を設定。意味的に冗長だが実害なし (defense-in-depth として許容)。

### L2: Auditor failure handling が review.md で明示されていない

**Location**: `framework/claude/skills/sdd-roadmap/refs/review.md`
**Reporting Agents**: Agent 3 (Consistency)
**Description**: Inspector failure には VERDICT:ERROR プロトコルがあるが、Auditor 自体が失敗した場合の回復パスが review.md に明記されていない。CLAUDE.md の汎用 SubAgent Failure Handling でカバーされ、Auditor 自身にも Verdict Output Guarantee があるため実運用リスクは低い。

---

## Claude Code Compliance Status

| Item | Status |
|---|---|
| agents/ YAML frontmatter | PASS (24/24) |
| Skills frontmatter | PASS (7/7) |
| Task tool subagent_type | PASS |
| settings.json keys | PASS |
| install.sh paths | PASS |
| Model selection | PASS |
| Tool permissions | PASS |

---

## Overall Assessment

フレームワーク全体の整合性は高いレベルで維持されている。E2E/Visual inspector 分離の未コミット変更は、Agent 2 の Split Traceability Table が示す通り、旧機能の100%が新ファイルに追跡可能で機能損失なし。

Claude Code 公式仕様への準拠は全項目 PASS。新規エージェント `sdd-inspector-visual` も適切に定義されている。

検出された MEDIUM 2件は documentation clarity の改善で解決可能。

---

## Recommended Fix Priority

| Priority | ID | Summary | Target Files |
|---|---|---|---|
| 1 | M1 | CLAUDE.md Inspector数表記を明確化 (`+2 web` → impl review 限定と明記) | `framework/claude/CLAUDE.md` |
| 2 | M2 | Web Inspector Server Protocol にコマンド不在時の fallback を追加 | `framework/claude/skills/sdd-roadmap/refs/review.md` |
