# SDD Framework Self-Review Report
**Date**: 2026-03-03 | **Version**: v1.11.0+sdk-drift | **Agents**: 4 dispatched, 4 completed

## False Positives Eliminated

| Finding | Agent | Reason |
|---|---|---|
| Inspector カウント 6 impl +2 web 不一致 | Agent 3 | 自己訂正: CLAUDE.md, review.md, auditor-impl 全て 6+2=8 で一致 |
| Analyst 出力先パス不整合 | Agent 3 | 自己訂正: CLAUDE.md, reboot.md, sdd-analyst.md 全て一致 |
| Reboot フェーズ番号不整合 | Agent 3 | 自己訂正: SKILL.md と reboot.md で 10 フェーズ完全一致 |
| Commands (7) vs 8 スキル | Agent 3 | 意図的設計: sdd-review-self はフレームワーク内部専用、ユーザー向け 7 コマンドは正確 |
| general-purpose Agent が settings.json に未登録 | Agent 3 | built-in agent type: settings.json の Agent() は custom agent 定義のみ |
| Agent dispatch 時の model パラメータ | Agent 4 | 標準 Agent tool パラメータ: Claude Code 公式仕様で有効 |
| revise Single→Cross-Cutting 昇格が SKILL.md で不可視 | Agent 1 | 意図的設計: SKILL.md は静的判定、動的昇格は revise.md の責務 |
| buffer.md テンプレート vs impl.md フォーマット乖離 | Agent 3 | 意図的設計: テンプレートは概念的、impl.md が実フォーマットを定義 |
| sdd-taskgenerator research.md if exists 条件 | Agent 3 | 自己訂正: 両ファイルとも (if exists) と記述で一致 |

## HIGH (1)

### H1: `Skill(sdd-publish-setup)` が settings.json 未登録 + sdd-steering allowed-tools に Skill 未追加
**Location**: `framework/claude/settings.json`, `framework/claude/skills/sdd-steering/SKILL.md`
**Description**: v1.11.0 で追加された sdd-publish-setup が settings.json の permissions.allow に未登録。また sdd-steering の allowed-tools に `Skill` ツールが含まれていないため、Create Mode Step 10 での `/sdd-publish-setup` 呼び出しが権限不足で失敗する。
**Evidence**: Agent 1 L3, Agent 3 L1, Agent 4 M1+M2 が同一問題を検出。D73 で sdd-publish-setup を追加したが permissions 設定が漏れた。

## MEDIUM (5)

### M1: dead-specs/dead-tests SCOPE フィールド例が不正
**Location**: `framework/claude/agents/sdd-inspector-dead-specs.md:48,60`, `sdd-inspector-dead-tests.md:49,57`
**Description**: フォーマット定義では `SCOPE:dead-code` だが実例では `SCOPE:cross-check`。Auditor は SCOPE を厳密検証しないため実害は小さいが、Inspector 実装の参考にする際に誤りが生じる。
**Evidence**: Agent 3

### M2: sdd-inspector-rulebase の Design Sections チェックに System Flows 欠落
**Location**: `framework/claude/agents/sdd-inspector-rulebase.md:53-62`
**Description**: `design-review.md` では `System Flows section (if applicable)` が含まれるが、inspector-rulebase のチェックリストに欠落。
**Evidence**: Agent 3 (pre-existing)

### M3: Auto-Fix カウンタリセット条件が run.md で不完全
**Location**: `framework/claude/skills/sdd-roadmap/refs/run.md:261`
**Description**: CLAUDE.md では 4 条件（wave completion, user escalation, revise start, session resume）を列挙するが、run.md は wave completion のみ記述。CLAUDE.md が権威的ソースだが、run.md だけ読む Agent にとって情報不足。
**Evidence**: Agent 1

### M4: sdd-architect.md SDK Source Inspection の適用スコープ未明示
**Location**: `framework/claude/agents/sdd-architect.md:65-70`
**Description**: Lead が SDK パスを渡した場合に適用されるのが全 Feature Type 共通か Complex/Extension のみかが不明確。
**Evidence**: Agent 2 (current commit)

### M5: impl.md Step 2.5 のフォールバック意図が未記載
**Location**: `framework/claude/skills/sdd-roadmap/refs/impl.md:37-48`
**Description**: design.md Step 2.5 で既に SDK 追加済みのはずだが、impl.md Step 2.5 で再度 manifest チェックする理由（別セッションで design のみ済ませた場合のフォールバック）が説明されていない。
**Evidence**: Agent 2 (current commit)

## LOW (8)

### L1: Consensus B{seq} 決定の渡し方が SKILL.md に未記載
**Location**: `framework/claude/skills/sdd-roadmap/SKILL.md:115-116`
**Evidence**: Agent 1

### L2: Dead-Code Review verdict 保存先の説明が括弧注記のみで可読性低
**Location**: `framework/claude/skills/sdd-roadmap/refs/review.md:143-144`
**Evidence**: Agent 1

### L3: `--wave N` parse 手順が review.md Step 1 に未記載
**Location**: `framework/claude/skills/sdd-roadmap/refs/review.md:9`
**Evidence**: Agent 1

### L4: revise.md Part B Step 5.5 "Resume from Part A Step 4" が Step 5 であるべき
**Location**: `framework/claude/skills/sdd-roadmap/refs/revise.md:181`
**Evidence**: Agent 1

### L5: run.md vs design.md Dependency Sync 条件文言の差異
**Location**: `framework/claude/skills/sdd-roadmap/refs/run.md:62`, `refs/design.md:24`
**Evidence**: Agent 2 (current commit)

### L6: sdd-steering Step 5a Install コマンド空の場合のフォールバック未定義
**Location**: `framework/claude/skills/sdd-steering/SKILL.md:49-53`
**Evidence**: Agent 2 (current commit)

### L7: sdd-architect.md Steps 5-6 参照が旧フロー名を暗示
**Location**: `framework/claude/agents/sdd-architect.md:68`
**Evidence**: Agent 2 (current commit)

### L8: `--cross-check` 1-Spec guard の表現差異 (skip vs abort)
**Location**: `framework/claude/skills/sdd-roadmap/SKILL.md:72`, `refs/review.md:14`
**Evidence**: Agent 1

## Platform Compliance

| Item | Status |
|---|---|
| Agent frontmatter (26 agents) | PASS (10 full + 16 cached) |
| Skill frontmatter (8 skills) | PASS (7 cached + 1 new: sdd-publish-setup) |
| settings.json Agent() entries (26) | PASS |
| settings.json Skill() entries | **FAIL** — `Skill(sdd-publish-setup)` missing |
| sdd-steering allowed-tools | **FAIL** — `Skill` tool missing |
| SubAgent nesting prohibition | PASS |
| Tool availability | PASS |

## Overall Assessment

CRITICAL 問題なし。HIGH 1 件は v1.11.0 で追加した sdd-publish-setup のパーミッション設定漏れで、今セッションで修正すべき。

MEDIUM 5 件のうち M4, M5 は今コミット (SDK API Drift 対策) のドキュメント明確化、M1-M3 は pre-existing。LOW 8 件は全てドキュメント可読性の改善。

Pre-existing backlog (前回 B18 から繰越): H3 M8 L6 → 今回 H0+M2 (M2, M3) + L2 (L2, L3) が pre-existing。

## Recommended Fix Priority

| Priority | ID | Summary | Target Files |
|---|---|---|---|
| 1 (now) | H1 | settings.json + steering allowed-tools に sdd-publish-setup 追加 | settings.json, sdd-steering/SKILL.md |
| 2 (now) | M4 | SDK Source Inspection スコープ明示 | sdd-architect.md |
| 3 (now) | M5 | impl.md Step 2.5 フォールバック意図追記 | refs/impl.md |
| 4 (backlog) | M1 | dead-specs/dead-tests SCOPE 例修正 | sdd-inspector-dead-specs.md, sdd-inspector-dead-tests.md |
| 5 (backlog) | M2 | inspector-rulebase に System Flows 追加 | sdd-inspector-rulebase.md |
| 6 (backlog) | M3 | run.md カウンタリセット条件補完 | refs/run.md |
| 7 (backlog) | L1-L8 | ドキュメント可読性改善 | 各ファイル |
