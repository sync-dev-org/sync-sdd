# SDD Framework Self-Review Report
**Date**: 2026-02-27 | **Agents**: 4 dispatched, 4 completed | **Version**: v1.2.5+wave-context

## False Positives Eliminated

| Finding | Agent | Reason |
|---|---|---|
| CLAUDE.md "Commands (5)" vs 実際6スキル | Agent 3 | session.md Key Decisions: "sdd-review-selfはCommands(5)に含めない: framework-internal用途" |

## CRITICAL (0)

(なし)

## HIGH (0)

(なし)

## MEDIUM (4)

### M1: revise.md Cross-Cutting Tier Execution で conventions brief 未伝播 [FIXED]
**Location**: framework/claude/skills/sdd-roadmap/refs/revise.md:212-227
**Description**: Cross-Cutting Revision の Tier Execution に Wave Context Generation ステップがなく、並列 Builder が conventions brief なしで実行される
**Source**: Agent 1 (Flow) + Agent 2 (Changes)
**Status**: FIXED — Step 7 に Wave Context Generation + conventions brief 伝播を追加

### M2: Blocking Protocol `fix` でカウンタリセット未明記
**Location**: framework/claude/skills/sdd-roadmap/refs/run.md:218-223
**Description**: CLAUDE.md は "user escalation decision" でカウンタリセットと定義するが、run.md Step 6 の `fix` オプションにリセット記述がない
**Source**: Agent 1 (Flow)
**Status**: Pre-existing, not fixed this session

### M3: Shared Research テンプレートが未存在 [ADDRESSED]
**Location**: framework/claude/skills/sdd-roadmap/refs/run.md:55
**Description**: Conventions Brief にはテンプレートがあるが Shared Research にはない非対称性
**Source**: Agent 2 (Changes)
**Status**: ADDRESSED — "free-form, no template" と明記。Shared Research は project context により内容が大きく変わるため、固定テンプレートは不適切

### M4: sdd-inspector-best-practices の tools に WebSearch/WebFetch 未宣言
**Location**: framework/claude/agents/sdd-inspector-best-practices.md:6
**Description**: 本文で Research Depth (Autonomous) に言及するが frontmatter tools に WebSearch/WebFetch がない
**Source**: Agent 3 (Consistency)
**Status**: Pre-existing (B8 から継続), not fixed this session

## LOW (6)

### L1: review.md Triggered by 行 dead-code の feature 引数表記
**Location**: framework/claude/skills/sdd-roadmap/refs/review.md:6
**Source**: Agent 1 (Flow) | Pre-existing

### L2: revise.md Step 7 Architect 後 spec.yaml 更新の暗黙委譲
**Location**: framework/claude/skills/sdd-roadmap/refs/revise.md:212-217
**Source**: Agent 1 (Flow) | Pre-existing

### L3: Pilot Stagger "Multi-wave execution plan" 表現紛らわしい [FIXED]
**Location**: framework/claude/skills/sdd-roadmap/refs/impl.md:55
**Source**: Agent 2 (Changes)
**Status**: FIXED — "(refers to tasks.yaml execution waves, not roadmap waves)" を追記

### L4: CPF category 値が Inspector/Auditor 間で標準化されていない
**Source**: Agent 3 (Consistency) | Pre-existing

### L5: install.sh v0.18.0/v0.20.0 マイグレーション往復
**Source**: Agent 3 (Consistency) | Pre-existing

### L6: sdd-handover 空 argument-hint
**Source**: Agent 4 (Compliance, cached) | Pre-existing

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

Wave Context (Conventions Brief + Shared Research + Pilot Stagger) 追加は主要パスで正しく統合されている。新規 findings 3件は全て修正済み。Pre-existing findings 7件は本変更とは無関係。

## Recommended Fix Priority

| Priority | ID | Summary | Target Files |
|---|---|---|---|
| Done | M1 | revise.md conventions brief 伝播 | refs/revise.md |
| Done | M3 | Shared Research テンプレート非対称性解消 | refs/run.md |
| Done | L3 | Pilot Stagger 表現改善 | refs/impl.md |
| Next | M2 | Blocking Protocol カウンタリセット | refs/run.md |
| Next | M4 | best-practices WebSearch tools | agents/sdd-inspector-best-practices.md |
| Backlog | L1-L6 | Pre-existing LOW findings | Various |
