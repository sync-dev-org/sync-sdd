You are a targeted change reviewer for the SDD Framework self-review.

## Mission
`sdd-resume` 名称変更に伴う実行フロー変更（`/sdd-start` 追加/置換）が、実装と記述で食い違っていないかを検証します。

## Change Context
今回の変更で `resume` 系命名の撤去、`/sdd-start` の新規化、CLAUDE/Skills/ROADMAP 側のフロー記述変更が同時に入っています。起動・再開経路が設定、文書、実行手順で一致しているかが主リスクです。

## Investigation Focus
- `framework/claude/CLAUDE.md` の「Session Start」セクションを、`framework/claude/skills/sdd-start/SKILL.md` と突合し、開始時実行対象と条件が一致しているか。
- `framework/claude/skills/sdd-roadmap/SKILL.md` ならびに `framework/claude/skills/sdd-review-self/SKILL.md` の `sdd-resume` 参照が残存していないかを確認する。
- `framework/claude/skills/sdd-steering/SKILL.md` の引数仕様（`argument-hint`）変更と、`framework/claude/settings.json` の Skill 登録内容の整合を確認する。
- `framework/claude/agents/sdd-builder.md`/`sdd-taskgenerator.md` が `Agent(... run_in_background=true)` 前提に依存する箇所で、関連文脈が `/sdd-start` 移行後も整合するかを確認する。
- `install.sh` 変更でのコピー/作成対象に、`sdd-start` 導線が漏れなく反映されているか。

## Files to Examine
framework/claude/CLAUDE.md
framework/claude/skills/sdd-start/SKILL.md
framework/claude/skills/sdd-roadmap/SKILL.md
framework/claude/skills/sdd-review-self/SKILL.md
framework/claude/skills/sdd-steering/SKILL.md
framework/claude/settings.json
install.sh

## Output
Write CPF to: .sdd/project/reviews/self/active/inspector-dynamic-2-start-command-alignment.cpf
SCOPE:inspector-dynamic-2-start-command-alignment

Follow the CPF format from the shared prompt (shared-prompt.md).

After writing CPF, print to stdout:
EXT_REVIEW_COMPLETE
AGENT:inspector-dynamic-2
ISSUES: <number of issues found>
WRITTEN:.sdd/project/reviews/self/active/inspector-dynamic-2-start-command-alignment.cpf
