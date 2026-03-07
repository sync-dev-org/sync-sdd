You are a targeted change reviewer for the SDD Framework self-review.

## Mission
`review-self` 改修で削除・移動されたファイルへの参照が、実行時に到達不能になっていないかを確認する。

## Change Context
直近のリネーム/整理差分で複数テンプレート・agent 定義が削除・移動されており、残存する参照は CI 実行・CLI 参照・手順のどこかで失敗しうる。

## Investigation Focus
1. `framework/claude/settings.json` と `framework/claude/CLAUDE.md` の `Agent()` 呼び出し候補に、消えたファイル名や旧テンプレート名が紐付いていないか確認する。
2. `framework/claude/sdd/settings/templates/review-self/*` の変更履歴に対し、削除済み参照（`agent-*.md` など）が残っていないか検査する。
3. `framework/claude/agents/sdd-*.md` で存在しない skill/agent を指す `skills` / `agent` 名の文字列がないかを確認する。
4. `sdd-review-self` と `sdd-review` skill の中間成果物手順で、旧ファイル群 (`active/agent-*`, `prep-status`, `agent-dynamic-*`) の使用を前提にしないか確認する。

## Files to Examine
framework/claude/settings.json
framework/claude/CLAUDE.md
framework/claude/sdd/settings/templates/review-self/
framework/claude/agents/*.md
framework/claude/skills/sdd-review-self/SKILL.md
framework/claude/skills/sdd-review/SKILL.md
.sdd/project/reviews/self/B41/dynamic-manifest.md

## Output
Write CPF to: .sdd/project/reviews/self/active/inspector-dynamic-3-deleted-ref-residue.cpf
SCOPE:inspector-dynamic-3-deleted-ref-residue

Follow the CPF format from the shared prompt (shared-prompt.md).

After writing CPF, print to stdout:
EXT_REVIEW_COMPLETE
AGENT:inspector-dynamic-3
ISSUES: <number of issues found>
WRITTEN:.sdd/project/reviews/self/active/inspector-dynamic-3-deleted-ref-residue.cpf
