# SDD Framework Self-Review Report (B23)
**Date**: 2026-03-03T21:01:23+0900 | **Agents**: 4 dispatched, 4 completed

## False Positives Eliminated
(none)

## CRITICAL (0)
(none)

## HIGH (3)

### S-H1: settings.json に Skill(sdd-review-self-ext) 未登録
**Location**: framework/claude/settings.json
**Description**: sdd-review-self-ext SKILL.md が存在するが settings.json の permissions.allow に未登録。
**Evidence**: Agent 2, 3 が独立検出。

### S-H2: review dead-code ルーティングが SKILL.md Execution Reference に未記載
**Location**: framework/claude/skills/sdd-roadmap/SKILL.md:96-105
**Description**: Execution Reference セクションで review dead-code の明示的なルーティング記載が欠落。
**Evidence**: Agent 1。

### S-H3: revise.md Part B Step 8 Cross-Cutting で spec_update_count が aggregate cap に未言及
**Location**: framework/claude/skills/sdd-roadmap/refs/revise.md:258
**Description**: Cross-Cutting Consistency Review の auto-fix ループで spec_update_count が aggregate cap 計算に含まれていない。
**Evidence**: Agent 3。

## MEDIUM (7)

### S-M1: SPEC-UPDATE-NEEDED 処理が run.md/revise.md に重複
**Location**: refs/run.md:189, refs/revise.md (Part B Step 4)
**Agent**: 1

### S-M2: Revise Mode spec 名照合の順序が SKILL.md で不明確
**Location**: framework/claude/skills/sdd-roadmap/SKILL.md:34-35
**Agent**: 1

### S-M3: Consensus mode B{seq} 決定責務が SKILL.md 単体で不明
**Location**: framework/claude/skills/sdd-roadmap/SKILL.md:115-116
**Agent**: 1

### S-M4: engines.yaml テンプレートの NOT overwritten コメントが曖昧
**Location**: framework/claude/sdd/settings/templates/engines.yaml:4
**Agent**: 2

### S-M5: reboot.md Phase 9 "merge to main" vs Phase 10 "DO NOT merge" 矛盾
**Location**: framework/claude/skills/sdd-reboot/refs/reboot.md:270, 301
**Agent**: 3

### S-M6: run.md Island Spec demote 先 wave が未規定
**Location**: framework/claude/skills/sdd-roadmap/refs/run.md:87
**Agent**: 3

### S-M7: sdd-steering Engines Mode が .sdd/ ハードコード
**Location**: framework/claude/skills/sdd-steering/SKILL.md:61-65
**Agent**: 3

## LOW (5)

### S-L1: 1-Spec Wave QG スキップ条件が重複記述
**Agent**: 1

### S-L2: verdicts.md ヘッダーフォーマットが self/self-ext で異なる
**Agent**: 1

### S-L3: tmux 並行 wait-for パターンが tmux-integration.md に未記載
**Agent**: 2

### S-L4: sdd-inspector-e2e wave scope 書式が不明瞭
**Agent**: 2

### S-L5: sdd-review-self-ext Step 3 compliance cache ".cpf or .md" が曖昧
**Agent**: 3

## Platform Compliance

| Item | Status |
|---|---|
| Agent frontmatter | OK (cached) |
| Skills frontmatter | OK (sdd-review-self-ext 新規検証含む) |
| Dispatch patterns | OK (cached) |
| settings.json Skill() | NG (sdd-review-self-ext missing) |
| settings.json Agent() | OK (cached) |

## Overall Assessment

H3, M7, L5。settings.json 未登録 (S-H1) は即修正可能。S-H3 (Cross-Cutting aggregate cap) は運用時にカウンター超過を見逃すリスクあり。review.md / reboot.md 系の finding は既存 backlog の延長。

## Recommended Fix Priority

| Priority | ID | Summary | Target Files |
|---|---|---|---|
| 1 | S-H1 | settings.json に Skill(sdd-review-self-ext) 追加 | settings.json |
| 2 | S-H3 | Cross-Cutting Review に spec_update_count 言及追加 | revise.md |
| 3 | S-H2 | review dead-code ルーティング明記 | SKILL.md (roadmap) |
| 4 | S-M5 | Reboot Phase 9/10 merge 矛盾解消 | reboot.md |
| 5 | S-M4,S-M7 | パス/コメント整合 | engines.yaml, sdd-steering |
