# SDD Framework Self-Review Report B21
**Date**: 2026-03-03T16:42:03+0900 | **Agents**: 4 dispatched, 4 completed
**Scope**: sdd-inspector-e2e 新設 + inspector-test E2E 分離 + E2E フォーマット正規化

## False Positives Eliminated

| Finding | Agent | Reason |
|---|---|---|
| sdd-inspector-test.md 未コミット | Agent 2 | 作業中のため当然 |
| installed CLAUDE.md differs from framework | Agent 4 | 未コミット変更のため当然 |
| general-purpose model パラメータ | Agent 4 | 公式仕様で有効パラメータ確認済み |

## From Current Changes (2 findings, 1 fixed)

### M1: inspector-e2e design.md プレースホルダーフィルタ不足 — **FIXED**
**Location**: framework/claude/agents/sdd-inspector-e2e.md:40
**Description**: design.md Testing Strategy からバッククォートで囲まれたコマンドを抽出する際、テンプレートのプレースホルダー `[command]` をフィルタしていなかった。steering パースでは同等のフィルタあり。
**Evidence**: Agent 2 — design.md template L278 の `E2E command: \`[command]\`` が誤抽出される
**Fix**: Skip placeholders in brackets 条件を追加済み

### M2: README.md Inspector カウント未更新
**Location**: README.md:79
**Description**: `6+2 for implementation (web projects)` — E2E Inspector (+1 conditional) が反映されていない
**Evidence**: Agent 1 — CLAUDE.md は正しく `6 impl +1 e2e +2 web` だが README が旧記述のまま
**Status**: リリース時に更新（sdd-release Step 3.2 で自動検出される）

## Pre-existing Backlog (9 findings)

### HIGH (2)
- H1: sdd-release Step 3.3 が sdd-review-self を除外せず 8≠7 誤報 (Agent 3)
- H2: dead-code Auditor SCOPE フィールドが Inspector と不一致 (Agent 3)

### MEDIUM (3)
- M3: run.md Step 2 の buffer.md 注記が文脈から逸脱 (Agent 3)
- M4: conventions-brief テンプレート Wave ヘッダー 1-spec 非対応 (Agent 3)
- M5: dead-code Auditor Agent 省略名が非公式 (Agent 3)

### LOW (4)
- L1: revise.md Mode Detection の軽微な重複 (Agent 1)
- L2: review.md dead-code verdicts.md パス 2 箇所重複 (Agent 1)
- L3: Session Resume ステップ番号が非連番 (Agent 3)
- L4: revise.md Part A Step 3 前提条件の視認性 (Agent 3)

## Platform Compliance

| Item | Status |
|---|---|
| sdd-inspector-e2e frontmatter | OK (new, verified) |
| sdd-inspector-test (E2E removed) | OK (verified) |
| sdd-auditor-impl (count 9, list updated) | OK (verified) |
| settings.json (Agent entry added) | OK (verified) |
| CLAUDE.md (inspector count updated) | OK (verified) |
| 17 cached agents/skills | OK (cached from B20) |

## Overall Assessment

今回の変更 (sdd-inspector-e2e 新設 + inspector-test E2E 分離) は整合性が高い。dispatch 条件、auditor リスト、settings.json、CLAUDE.md すべて一貫。

修正済み 1 件: design.md プレースホルダーフィルタ追加。
リリース時対応 1 件: README.md Inspector カウント更新。
Pre-existing backlog: H2 M8 L10 (前回 B20 の H0 M8 L10 から H+2)。
