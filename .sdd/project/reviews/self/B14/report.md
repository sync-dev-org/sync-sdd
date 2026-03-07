# SDD Framework Self-Review Report
**Date**: 2026-02-27 | **Agents**: 4 dispatched, 4 completed | **Version**: v1.5.1+uncommitted

## False Positives Eliminated

| Finding | Agent | Reason |
|---|---|---|
| Cross-Cutting Revise コミット前ユーザー確認なし | Agent 1 (Flow) | CLAUDE.md Commit Timing: "Wave completion: Lead commits directly" — 標準パイプラインの設計方針 |
| revise.md Part A にコミット指示なし | Agent 3 (Consistency) | CLAUDE.md Commit Timing: "Pipeline completion (1-spec roadmap): After individual pipeline completes, Lead commits" でカバー |
| CLAUDE.md refs/impl.md Pilot Stagger 参照 | Agent 3 (Consistency) | Agent 自身が検証後「問題なし」と確認 |

## CRITICAL (0)

なし

## HIGH (0)

なし (Agent 1 の 2 件を精査の結果 MEDIUM に再分類)

## MEDIUM (4)

### M1: run.md に `.sdd/` ハードコードパスが混在
**Location**: `framework/claude/skills/sdd-roadmap/refs/run.md` 行 38, 54
**Description**: Conventions Brief と Shared Research の出力パスのみ `.sdd/project/specs/.wave-context/` とハードコード。他の全パスは `{{SDD_DIR}}` を使用。`{{SDD_DIR}}` が変更された場合にパスが壊れる。
**Evidence**: 同ファイル内の他のパス（行 35, 37, 234, 245 等）はすべて `{{SDD_DIR}}` 使用

### M2: sdd-review-self の `Task(general-purpose)` が settings.json に未登録
**Location**: `framework/claude/skills/sdd-review-self/SKILL.md`, `framework/claude/settings.json`
**Description**: sdd-review-self は `Task(subagent_type="general-purpose")` を使用するが、settings.json の allow リストに `Task(general-purpose)` がない。ユーザーが毎回手動で承認する必要がある。
**Evidence**: settings.json の Task エントリはすべて `Task(sdd-*)` 形式

### M3: reboot Phase 5 `-y` スキップ時のレポート読み込み明示性不足
**Location**: `framework/claude/skills/sdd-reboot/refs/reboot.md` Phase 5
**Description**: Phase 5 は `-y` で「Skip」されるが、Phase 6c で Lead がレポートを読む必要があることが Phase 5 の skip 説明に明示されていない。Phase 6c に独立した read 指示があるため動作上は問題ないが、Lead が「Phase 5 = レポート読み」と解釈してスキップすると Phase 6c の read も省略するリスク。
**Evidence**: Phase 5: "Skip if `-y`" / Phase 6c: "Read the analysis report to extract proposed spec decomposition"

### M4: reboot Phase 7 EXIT 条件で skip spec の扱いが分離記述
**Location**: `framework/claude/skills/sdd-reboot/refs/reboot.md` Phase 7
**Description**: EXIT 条件本文 "If all specs in wave have design-generated..." と Verdict Handling 補足 "Skip → exclude spec from wave EXIT condition" が分離した記述。Lead が EXIT 本文のみを参照すると、skip された spec を待ち続ける可能性。
**Evidence**: EXIT 条件 (Phase 7 Dispatch Loop step 5) vs Verdict Handling (同 Phase 7 別セクション)

## LOW (8)

### L1: CLAUDE.md Analyst completion report に `Files to delete: {count}` 未記載
**Location**: `framework/claude/CLAUDE.md` (Analyst 記述セクション)
**Description**: 未コミット変更で Analyst の completion report に `Files to delete: {count}` を追加したが、CLAUDE.md の Analyst 出力説明に反映されていない。

### L2: SKILL.md vs revise.md Mode Detection 判定基準不統一 (pre-existing B9 M2)
**Location**: `framework/claude/skills/sdd-roadmap/SKILL.md`, `refs/revise.md`
**Description**: SKILL.md は引数形式のみで Single-Spec/Cross-Cutting を判定。revise.md は「既知のスペック名への照合」を明示。

### L3: Dead-Code Review リトライカウントのセッション再開後リセット (pre-existing)
**Location**: `refs/run.md` Step 7b
**Description**: インメモリのみで永続化されず、セッション再開でリセット。設計上意図的だが不透明。

### L4: review.md dispatch loop コンテキスト注記の配置が曖昧
**Location**: `refs/review.md` Web Inspector Server Protocol 末尾
**Description**: dispatch loop との関係を示す注記が Web Inspector セクション末尾に配置されており、Review Execution Flow セクションとの関連が不明瞭。

### L5: Builder グループ ID 命名規則が暗黙的
**Location**: `refs/impl.md`, `sdd-builder.md`
**Description**: グループ ID の生成規則が TaskGenerator に暗黙的に依存。

### L6: reboot Phase 6d product.md 二重更新リスク
**Location**: `refs/reboot.md` Phase 6d
**Description**: Analyst が Phase 4 で product.md を更新、Lead が Phase 6d で再確認・補完。具体的な重複回避手順がない。

### L7: reboot.md aggregate cap 6 が design review で misleading
**Location**: `refs/reboot.md` Phase 7 Verdict Handling
**Description**: Design Review では SPEC-UPDATE-NEEDED が発生しないため spec_update_count=0 固定。aggregate cap 6 の記述はやや misleading。

### L8: design-review.md と design.md テンプレートのセクション順序微差
**Location**: `sdd/settings/rules/design-review.md`, `sdd/settings/templates/specs/design.md`
**Description**: Specifications Traceability の順序チェックが impl inspector で明示的に行われていない。

## Platform Compliance

| Item | Status |
|---|---|
| sdd-analyst.md (未コミット変更) | PASS (フル検証) |
| sdd-reboot/SKILL.md (未コミット変更) | PASS (フル検証) |
| 他 24 エージェント | OK (cached) |
| 他 6 スキル | OK (cached) |
| settings.json Skill()/Task() 対応 | OK |
| settings.json Bash/defaultMode | OK (cached) |

## Overall Assessment

フレームワーク全体のフローは堅牢。今回の未コミット変更（Phase 9 ユーザー承認ゲート、Phase 10 削除確認、Analyst Deletion Manifest）は正しく実装されている。CRITICAL/HIGH の問題はなし。

主な対応推奨:
1. **M1**: run.md ハードコードパスを `{{SDD_DIR}}` に統一（1分修正）
2. **M2**: settings.json に `Task(general-purpose)` を追加（1分修正）
3. **L1**: CLAUDE.md の Analyst 出力説明に `Files to delete` を追記（1分修正）
4. **M3/M4**: reboot.md の Phase 5 `-y` skip 説明と Phase 7 EXIT 条件の文言明確化

Pre-existing backlog (L2, L3): 設計上意図的または影響軽微のため即時修正不要。

## Recommended Fix Priority

| Priority | ID | Summary | Target Files |
|---|---|---|---|
| 1 | M1 | `.sdd/` ハードコードを `{{SDD_DIR}}` に統一 | refs/run.md |
| 2 | M2 | `Task(general-purpose)` を settings.json に追加 | settings.json |
| 3 | L1 | CLAUDE.md Analyst 出力に `Files to delete` 追記 | CLAUDE.md |
| 4 | M3 | Phase 5 `-y` skip にレポート読み込み注記追加 | refs/reboot.md |
| 5 | M4 | Phase 7 EXIT 条件に skip spec 除外を inline 化 | refs/reboot.md |
