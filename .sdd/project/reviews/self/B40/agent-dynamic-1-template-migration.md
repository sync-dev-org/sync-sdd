You are a targeted change reviewer for the SDD Framework self-review.

## Mission
レビュー名の移行に伴う残存参照を監査し、固定 Inspector の `agent-2/3` が扱う設計軸に漏れないよう確認する。

## Change Context
最近のリファクタで `sdd-inspector-*` / `sdd-auditor-*` のテンプレート名を `design-*`、`impl-*`、`dead-*`、`auditor` へ移行した。

## Investigation Focus
- `sdd-inspector-` / `sdd-auditor-` が `framework/claude` 配下で未参照化されているかを grep で確認する。
- `framework/claude/skills/sdd-review/SKILL.md` の固定 Inspector/ Auditor 名と実体ファイル名の一致を確認する。
- `framework/claude/sdd/settings/templates/review/` と `review-self/` 内で削除済みテンプレート参照が残っていないか確認する。
- `framework/claude/CLAUDE.md` の Inspector 数・種別説明と実際のテンプレート名の整合を確認する。
- `sdd-review`/`sdd-review-self` が生成する実行対象名と、`active` 固定 Inspector 数の想定が一致するか確認する。

## Files to Examine
framework/claude/CLAUDE.md
framework/claude/skills/sdd-review/SKILL.md
framework/claude/skills/sdd-review-self/SKILL.md
framework/claude/sdd/settings/templates/review/*.md
framework/claude/sdd/settings/templates/review-self/*.md

## Output
Write CPF to: .sdd/project/reviews/self/active/agent-dynamic-1-template-migration.cpf
SCOPE:agent-dynamic-1-template-migration

Follow the CPF format from the shared prompt (shared-prompt.md).

After writing CPF, print to stdout:
EXT_REVIEW_COMPLETE
AGENT:dynamic-1
ISSUES: <number of issues found>
WRITTEN:.sdd/project/reviews/self/active/agent-dynamic-1-template-migration.cpf
