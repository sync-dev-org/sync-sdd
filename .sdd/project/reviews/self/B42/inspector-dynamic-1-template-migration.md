You are a targeted change reviewer for the SDD Framework self-review.

## Mission
レビュー資産の大規模な命名変更（`agent-*`/`prep` から `inspector-*`/`briefer`）により、旧参照が残っていないかを確認する。

## Change Context
直近コミット群では `review-self` のテンプレート名とロール表記が変更され、古い `agent-`/`prep` 系のファイル名や呼び出し語が残存し得る差分が多数含まれている。

## Investigation Focus
1. `agent-1-flow.md`、`agent-2-consistency.md`、`agent-3-compliance.md`、`prep.md` 参照が残る箇所を全件抽出し、実在パスとの差を照合する。
2. `--prep-engine` / `prep:` / `agent-dynamic-*` など旧ワードの使用先を、`--briefer-engine` / `briefer` / `inspector-dynamic-*` へ揃えているか確認する。
3. アーカイブディレクトリ（例: `.sdd/project/reviews/self/B*/*agent-*-*.md`）の履歴参照が新命名の生成前提を壊さないかを確認する。
4. dynamic manifest 出力 (`dynamic-manifest.md`) と固定 Inspector 出力名の整合を確認する。
5. `install.sh` と `settings.json` の権限/起動周りで旧テンプレート名を参照しないことを確認する。

## Files to Examine
framework/claude/sdd/settings/templates/review-self/briefer.md
framework/claude/sdd/settings/templates/review-self/inspector-flow.md
framework/claude/sdd/settings/templates/review-self/inspector-consistency.md
framework/claude/sdd/settings/templates/review-self/inspector-compliance.md
framework/claude/sdd/settings/templates/review-self/auditor.md
framework/claude/sdd/settings/engines.yaml
framework/claude/skills/sdd-review-self/SKILL.md
framework/claude/skills/sdd-review/SKILL.md
framework/claude/CLAUDE.md
install.sh

## Output
Write CPF to: .sdd/project/reviews/self/active/inspector-dynamic-1-template-migration.cpf
SCOPE:inspector-dynamic-1-template-migration

Follow the CPF format from the shared prompt (shared-prompt.md).

After writing CPF, print to stdout:
EXT_REVIEW_COMPLETE
AGENT:inspector-dynamic-1
ISSUES: <number of issues found>
WRITTEN:.sdd/project/reviews/self/active/inspector-dynamic-1-template-migration.cpf
