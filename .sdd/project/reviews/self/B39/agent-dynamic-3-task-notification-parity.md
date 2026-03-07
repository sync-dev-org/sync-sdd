You are a targeted change reviewer for the SDD Framework self-review.

## Mission
`TaskOutput` から `task-notification` への移行と、`/sdd-review`/`sdd-review-self` の分岐内での待機チャネル設計が、完了検知と同時実行解放で一貫しているかを確認する。

## Change Context
CLAUDE、tmux ルール、`sdd-review-self`、`sdd-roadmap` の実行フローで待機手段とチャンネル名が更新された。旧実装のイベント待ち方残存は、同期待ちやレース条件の再発を招く。

## Investigation Focus
- `framework/claude/CLAUDE.md` の `task-notification` 記載と固定チャンネル命名規則（`sdd-{SID}-...-B{seq}`）を確認する。
- `framework/claude/sdd/settings/rules/tmux-integration.md` の `Assign/Wait/Close` と実行手順で、send-keys / wait-for の順序が一致するか確認する。
- `framework/claude/skills/sdd-review-self/SKILL.md` の Inspector/Auditor dispatch で fixed/dynamic チャネル名衝突がないか確認する。
- `framework/claude/skills/sdd-roadmap/SKILL.md` と `framework/claude/skills/sdd-roadmap/refs/run.md` の dispatch-loop 記載が `task-notification` 前提として整合しているか確認する。
- 旧 `TaskOutput` 呼び出し（`block=false` 等）への参照残存がないか確認する。

## Files to Examine
framework/claude/CLAUDE.md
framework/claude/sdd/settings/rules/tmux-integration.md
framework/claude/skills/sdd-review-self/SKILL.md
framework/claude/skills/sdd-roadmap/refs/run.md
framework/claude/skills/sdd-roadmap/SKILL.md

## Output
Write CPF to: .sdd/project/reviews/self/active/agent-dynamic-3-task-notification-parity.cpf
SCOPE:agent-dynamic-3-task-notification-parity

Follow the CPF format from the shared prompt (shared-prompt.md).

After writing CPF, print to stdout:
EXT_REVIEW_COMPLETE
AGENT:dynamic-3
ISSUES: <number of issues found>
WRITTEN:.sdd/project/reviews/self/active/agent-dynamic-3-task-notification-parity.cpf
