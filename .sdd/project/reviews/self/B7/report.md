# SDD Framework Self-Review Report
**Date**: 2026-02-24
**Version**: v1.2.0+compact-fix
**Mode**: full
**Agents**: 5 dispatched, 5 completed

---

## False Positives Eliminated

| Finding | Reporting Agent | Elimination Reason |
|---|---|---|
| Commands (6) vs 7 skills (sdd-review-self missing) | Consistency, Dead Code | Intentional design decision (D2): "sdd-review-selfはCommands(6)に含めない: framework-internal用途" |
| install.sh v0.18.0 migration comment stale | Consistency | Migration comments are historical context for upgrade compatibility. Code works correctly. |
| Revise Cross-Cutting Step 7 phase=design-generated intent ambiguity | Flow | Phase is set as state transition before Architect dispatch, not as gate check. Standard framework pattern. |
| Verdict Disposition semantics only in Router | Flow | Single source of truth is correct design. Other files reference Router. |
| sdd-auditor-dead-code Step 8 vs Step 10 | Consistency | Natural difference due to fewer verification steps in dead-code scope. |
| Builder "no spec.yaml update" in 2 places | Consistency | Intentional redundancy. SubAgent architecture requires each file to be self-contained. |
| install.sh migration code accumulation | Dead Code | Required for backward compatibility. Not actionable until v2.0.0. |
| general-purpose SubAgent not in settings.json | Dead Code | Platform built-in SubAgent type, not a custom agent. No permission entry needed. |
| Task(subagent_type=...) vs agent_type terminology | Compliance | Framework correctly uses `subagent_type` which matches Claude Code Task tool parameter name. |
| 14 Inspector Wave-Scoped Cross-Check duplication | Dead Code | SubAgent architecture constraint — each agent must be self-contained. |
| Inspector Steering Context duplication | Dead Code | Same as above. |
| Dead-code Inspector no wave-1..{N} SCOPE | Consistency | Intentional — dead-code reviews don't have wave-scoped mode. |

---

## CRITICAL (0)

## HIGH (0)

## MEDIUM (0)

## LOW (2)

### L1: design-discovery-full.md 表記不統一残存
**Location**: `framework/claude/sdd/settings/rules/design-discovery-full.md:91`
**Description**: `Components & Interface Contracts` — セクション名は `Components and Interfaces` (design-principles.md:96) に v1.1.1 で統一済みだが、このフリーテキスト参照が未更新。`&` → `and` + `Interface Contracts` → `Interfaces`
**Evidence**: design-principles.md:96 `### Components and Interfaces Authoring`, design-review.md:31 `Has Components and Interfaces section`

### L2: dead-code review の feature パラメータ曖昧性
**Location**: `framework/claude/skills/sdd-roadmap/SKILL.md:4` (argument-hint) vs `SKILL.md:72` (enrollment exception)
**Description**: argument-hint は `review dead-code <feature>` を示すが、Router line 72 は dead-code が enrollment をスキップし全コードベース対象と明記。review.md:20 も "operates on entire codebase" と記述。feature パラメータの扱いが曖昧。
**Evidence**: SKILL.md:4 `dead-code <feature>`, SKILL.md:72 `skip enrollment check`, review.md:20 `No phase gate (operates on entire codebase)`

---

## Claude Code Compliance Status

| Item | Status |
|---|---|
| agents/ YAML frontmatter (24 files) | PASS |
| skills/ SKILL.md (7 files) | PASS |
| settings.json permissions | PASS |
| install.sh paths | PASS |
| Model selection | PASS |
| Tool permissions (minimal) | PASS |

---

## Overall Assessment

フレームワーク v1.2.0 + 未コミット変更（compact 後 pipeline 続行ルール、Builder git 操作禁止）の品質は良好。CRITICAL/HIGH/MEDIUM の指摘はゼロ。LOW 2件は表記統一と argument-hint の軽微な曖昧性のみ。

未コミット変更（Session Resume Step 7 改訂、Behavioral Rules Pipeline 対応化、Builder workspace-wide git 禁止）はいずれも既存フローとの整合性を維持している。

---

## Recommended Fix Priority

| Priority | ID | Summary | Target Files |
|---|---|---|---|
| Low | L1 | "Components & Interface Contracts" → "Components and Interfaces" 表記統一 | framework/claude/sdd/settings/rules/design-discovery-full.md |
| Low | L2 | dead-code review の argument-hint から `<feature>` を除外 or 注釈追加 | framework/claude/skills/sdd-roadmap/SKILL.md |
