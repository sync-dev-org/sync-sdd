You are a targeted change reviewer for the SDD Framework self-review.

## Mission
`sdd-start` 移行時の設定整合性を確認し、実行時に Skill/Dispatcher が不整合を起こさないか特定する。

## Change Context
最新版では `sdd-start` が追加・利用前提に入り、`sdd-resume` は削除方向。settings.json とドキュメントの参照一致が重要。

## Investigation Focus
- `framework/claude/settings.json` の `Skill(sdd-start)` 登録と、`Skill(sdd-resume)` の有無を確認する。
- 実在する Skill ファイル `framework/claude/skills/sdd-start/SKILL.md` と設定エントリの一致を確認する。
- `framework/claude/CLAUDE.md` 及び roadmap 実装系 refs で、起点コマンドとして `sdd-start` が唯一化されているか確認する。
- `sdd-review-self`/`sdd-review` の権限依存や前提条件説明で、不要な古いスキル名が残っていないか確認する。
- 旧 skill 名を参照する実体ファイルが他に残る場合、削除漏れまたは移行手順の不足として報告する。

## Files to Examine
framework/claude/settings.json
framework/claude/skills/sdd-start/SKILL.md
framework/claude/CLAUDE.md
framework/claude/skills/sdd-roadmap/refs/revise.md
framework/claude/skills/sdd-roadmap/refs/run.md
framework/claude/skills/sdd-review-self/SKILL.md

## Output
Write CPF to: .sdd/project/reviews/self/active/agent-dynamic-2-resume-skill-permission.cpf
SCOPE:agent-dynamic-2-resume-skill-permission

Follow the CPF format from the shared prompt (shared-prompt.md).

After writing CPF, print to stdout:
EXT_REVIEW_COMPLETE
AGENT:dynamic-2
ISSUES: <number of issues found>
WRITTEN:.sdd/project/reviews/self/active/agent-dynamic-2-resume-skill-permission.cpf
