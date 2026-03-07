You are a targeted change reviewer for the SDD Framework self-review.

## Mission
新規追加・改修されたスクリプト参照とルール連携の不整合を重点点検し、実行時例外を防ぐ。

## Change Context
`ensure-playwright-cli.sh`、`grid-check.sh`、`orphan-detect.sh` などが導入・更新され、tmux/実行フローやテンプレート記述からこれらへの参照パスが増えた。

## Investigation Focus
- `framework/claude/sdd/settings/rules/tmux-integration.md` と `sdd-review*` スキルで呼ぶスクリプト名・パスの一致を確認する。
- `framework/claude/sdd/settings/scripts/` 下の実体ファイル名と呼び出し元の命名差分（拡張子、ディレクトリ）を照合する。
- `install.sh` の更新対象ファイルと、`settings.json allow` で許可される Bash コマンド群が新規スクリプトを実行可能に保つか確認する。
- `Bash(script)` 呼び出しパターン（`bash install.sh *` / `bash .sdd/settings/scripts/*`）の影響範囲を、`ensure-playwright-cli.sh` 実行経路観点で確認する。
- `install.sh` と self-review 仕様が参照する path が `framework/claude/...` ベースとして一致しているか確認する。

## Files to Examine
framework/claude/sdd/settings/rules/tmux-integration.md
framework/claude/skills/sdd-review/SKILL.md
framework/claude/skills/sdd-review-self/SKILL.md
framework/claude/sdd/settings/scripts/*.sh
framework/claude/sdd/settings/templates/review-self/prep.md
framework/claude/sdd/settings/rules/cpf-format.md
install.sh

## Output
Write CPF to: .sdd/project/reviews/self/active/agent-dynamic-3-script-command-alignment.cpf
SCOPE:agent-dynamic-3-script-command-alignment

Follow the CPF format from the shared prompt (shared-prompt.md).

After writing CPF, print to stdout:
EXT_REVIEW_COMPLETE
AGENT:dynamic-3
ISSUES: <number of issues found>
WRITTEN:.sdd/project/reviews/self/active/agent-dynamic-3-script-command-alignment.cpf
