# SDD Framework Self-Review Report (External Engine)
**Date**: 2026-03-03T20:50:42+0900 | **Engine**: codex [default] | **Agents**: 4 dispatched, 4 completed

## False Positives Eliminated

| Finding | Agent | Reason |
|---|---|---|
| (none) | — | — |

## CRITICAL (0)

(none)

## HIGH (4)

### H1: settings.json に Skill(sdd-review-self-ext) が未登録
**Location**: framework/claude/settings.json
**Description**: sdd-review-self-ext の SKILL.md は存在するが、settings.json の permissions.allow に Skill(sdd-review-self-ext) がない。インストール後にスキル実行がブロックされる。
**Evidence**: Agent 2, 3, 4 が独立に検出。settings.json の Skill() 一覧と実在 skill の不一致。

### H2: Router が feature-less --cross-check/--wave を受理するが review.md の入力仕様と不整合
**Location**: framework/claude/skills/sdd-roadmap/refs/review.md:5
**Description**: Router は review design --cross-check, review impl --wave N を受理するが、review.md は review design|impl {feature} / review dead-code のみを起点としており、feature 省略モードの分岐仕様が ref 内に欠落。
**Evidence**: Agent 1, 3 が独立に検出。SKILL.md:21-28 vs review.md:5-14。

### H3: Consensus Mode の scope-dir が spec-level 固定で project-level scope と矛盾
**Location**: framework/claude/skills/sdd-roadmap/SKILL.md:116
**Description**: Consensus Mode が specs/{feature}/reviews/ を固定使用しているが、dead-code/cross-check/wave は project/reviews/ を使うため scope 矛盾。
**Evidence**: Agent 1。SKILL.md:116 vs refs/review.md:75-97。

### H4: sdd-review-self-ext の Review Scope が engines.yaml テンプレートを含んでいない
**Location**: framework/claude/skills/sdd-review-self-ext/SKILL.md:52
**Description**: Review Scope の Glob パターンが *.md のみで、新設された engines.yaml テンプレートがレビュー対象外。4 Agent が engines.yaml の整合性を検証できない。
**Evidence**: Agent 2。Glob パターン: `templates/**/*.md` は `templates/engines.yaml` にマッチしない。

## MEDIUM (5)

### M1: Cross-check の履歴参照先が review.md 内で不一致
**Location**: framework/claude/skills/sdd-roadmap/refs/review.md:38
**Description**: Cross-check と wave-scoped を同一扱いで PREVIOUSLY_RESOLVED を project/reviews/wave/verdicts.md から読む指示だが、standalone cross-check は project/reviews/cross-check/verdicts.md に永続化される定義と食い違い。
**Evidence**: Agent 1。

### M2: Cross-cutting review の scope-dir が review execution flow で未定義
**Location**: framework/claude/skills/sdd-roadmap/refs/review.md:75,137
**Description**: Cross-cutting verdict パスは specs/.cross-cutting/{id}/verdicts.md として文書化されているが、review execution flow に cross-cutting scope directory のルートが未定義。
**Evidence**: Agent 1, 3。refs/revise.md:255-256 と review.md:137 が要求する cross-cutting review の実行スコープが ref 内で未定義。

### M3: Standalone review の auto-fix 記述が矛盾
**Location**: framework/claude/skills/sdd-roadmap/refs/review.md:103
**Description**: Standalone review handling では「No auto-fix」と明記しつつ、Next Steps では「SPEC-UPDATE-NEEDED → Auto-fix from spec level」と記載。CLAUDE.md の「auto-fix は pipeline orchestration 側で扱う」前提と不整合。
**Evidence**: Agent 1。

### M4: Reboot Phase 7 の skip 分岐と Completion Condition が矛盾
**Location**: framework/claude/skills/sdd-reboot/refs/reboot.md:194
**Description**: Phase 7 は design-review exhaustion 時に skip を許可し、skipped specs を EXIT 条件から除外するが、Completion Condition は全 specs に design-generated + GO/CONDITIONAL を要求。矛盾。
**Evidence**: Agent 3。reboot.md:159-180 vs :192-194。

### M5: Agent frontmatter の background: true は Claude Code 公式仕様外
**Location**: framework/claude/agents/sdd-*.md
**Description**: 全 agent 定義の background: true は Claude Code 公式 frontmatter フィールド外。無視される可能性が高い。公式フィールド: name, description, tools, disallowedTools, model, permissionMode, skills, hooks。
**Evidence**: Agent 4。web search による公式仕様照合。

## Platform Compliance

| Item | Status |
|---|---|
| Agent models & tools | OK |
| Skill frontmatter format | OK |
| Dispatch subagent_type | OK |
| settings.json Skill() permissions | NG (sdd-review-self-ext missing) |
| Agent frontmatter fields | NG (background: true unsupported) |

## Overall Assessment

4 Agent 全てが正常に完了し、CPF 出力プロトコルに準拠した結果を生成しました。sdd-review-self-ext スキルの基本フローは正常に機能しています。

主なリスク:
1. **settings.json 未登録** (H1) — インストール先で即座にブロックされる実運用問題
2. **review.md の入力仕様不備** (H2, H3) — cross-check/wave/cross-cutting モードの運用に影響（既存 backlog の可能性）
3. **engines.yaml がレビュー対象外** (H4) — self-review-ext 自体の品質保証の穴

## Recommended Fix Priority

| Priority | ID | Summary | Target Files |
|---|---|---|---|
| 1 | H1 | settings.json に Skill(sdd-review-self-ext) 追加 | framework/claude/settings.json |
| 2 | H4 | Review Scope に engines.yaml パターン追加 | framework/claude/skills/sdd-review-self-ext/SKILL.md |
| 3 | M5 | Agent frontmatter から background: true を削除 | framework/claude/agents/sdd-*.md (全27ファイル) |
| 4 | H2,H3,M1-M3 | review.md の cross-check/wave/cross-cutting 仕様整備 | framework/claude/skills/sdd-roadmap/refs/review.md, SKILL.md |
| 5 | M4 | Reboot Phase 7 skip + Completion Condition 整合 | framework/claude/skills/sdd-reboot/refs/reboot.md |
