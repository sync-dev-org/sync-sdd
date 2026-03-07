# SDD Framework Self-Review Report
**Date**: 2026-02-27 | **Agents**: 4 dispatched, 4 completed | **Version**: v1.3.0+b9-fixes

## False Positives Eliminated

| Finding | Agent | Reason |
|---|---|---|
| Inspector count "6" vs "up to 8" | Agent 3 | impl は web projects で +2 (e2e, visual)。異なるカウントが正しい |
| Dead-code escalation detail missing from CLAUDE.md | Agent 3 | CLAUDE.md は summary-level、詳細は run.md に属する設計 |
| Wave QG Dead-Code scope directory dual structure | Agent 3 | standalone (reviews/dead-code/) vs wave QG (reviews/wave/) は意図的分離 |
| init.yaml template missing | Agent 3 | framework/claude/sdd/settings/templates/specs/init.yaml に実在 |
| Wave Context path prefix inconsistency | Agent 3 | specs/.cross-cutting/ は refs 内で一貫した慣習的相対パス |

## CRITICAL (0)

(なし)

## HIGH (0)

(なし)

## MEDIUM (1)

### M1: CLAUDE.md counter reset triggers に blocking protocol fix/skip が未明示 [FIXED]
**Location**: framework/claude/CLAUDE.md:172
**Description**: run.md Step 6 に追加した counter reset が CLAUDE.md の reset triggers リストに反映されていなかった。"user escalation decision" に意味的に包含されるが明示性が不足
**Source**: Agent 1 (Flow, HIGH) + Agent 2 (Changes, MEDIUM) — merged, MEDIUM に統一
**Status**: FIXED — "(including blocking protocol fix/skip)" を追記

## LOW (10)

### L1: review.md Step 1 error message に dead-code の {feature} が残存 [FIXED]
**Location**: framework/claude/skills/sdd-roadmap/refs/review.md:12
**Source**: Agent 2 (Changes)
**Status**: FIXED — dead-code 用の Usage 例を分離

### L2: best-practices agent body に WebSearch/WebFetch 活用指示が未記載 [FIXED]
**Location**: framework/claude/agents/sdd-inspector-best-practices.md:87
**Source**: Agent 2 (Changes)
**Status**: FIXED — Research Depth セクションに WebSearch/WebFetch 活用指示を追記

### L3: Consensus B{seq} 決定責任が Router と review.md 間で曖昧
**Source**: Agent 1 (Flow) + Agent 3 (Consistency) | Pre-existing

### L4: Design Review NO-GO retry exhaustion → Step 6 Blocking Protocol 未参照
**Source**: Agent 1 (Flow) | Pre-existing

### L5: Dead-code review retry counter の格納先・resume 復元が未定義
**Source**: Agent 1 (Flow) | Pre-existing

### L6: Impl Review Inspector リストの表現揺れ (brace expansion vs explicit list)
**Source**: Agent 3 (Consistency) | Pre-existing

### L7: STEERING: CODIFY 説明が Auditor と review.md で微妙に異なる
**Source**: Agent 3 (Consistency) | Pre-existing

### L8: revise.md Part A Step 7 "roadmap run was in progress" 判定が曖昧
**Source**: Agent 1 (Flow) | Pre-existing

### L9: revise.md Part A→Part B 移行時の phase state の曖昧さ
**Source**: Agent 3 (Consistency) | Pre-existing

### L10: run.md "Execute per refs/design.md (Steps 1-3)" 参照が dispatch context でやや不正確
**Source**: Agent 1 (Flow) | Pre-existing

## Platform Compliance

| Item | Status |
|---|---|
| Agent frontmatter (24) | PASS |
| Skill frontmatter (6) | PASS |
| settings.json Skill/Task 整合性 | PASS |
| Task dispatch patterns | PASS |
| Tool availability | PASS |
| run_in_background consistency | PASS |

## Overall Assessment

B9 pre-existing findings (M2, M4, L1-L6) の修正に伴い発見された新規 findings 3件 (M1, L1, L2) を全て即修正。Pre-existing LOW findings 8件は本変更と無関係。プラットフォームコンプライアンスは全 PASS。

## Recommended Fix Priority

| Priority | ID | Summary | Target Files |
|---|---|---|---|
| Done | M1 | CLAUDE.md counter reset triggers 明示化 | CLAUDE.md |
| Done | L1 | review.md error message dead-code 引数修正 | refs/review.md |
| Done | L2 | best-practices WebSearch 活用指示追記 | agents/sdd-inspector-best-practices.md |
| Backlog | L3-L10 | Pre-existing LOW findings | Various |
