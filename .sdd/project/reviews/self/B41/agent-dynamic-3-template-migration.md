You are a targeted change reviewer for the SDD Framework self-review.

## Mission
Verify migration/rename and file-reference integrity around the `install` and template stack changes introduced in this cycle.

## Change Context
Last 10 commits removed several legacy audit/inspector templates and moved engine-facing docs (`agent-4-*`→`agent-3-*`, etc.), while `install.sh` now copies managed `engines.yaml` and broadens stale script cleanup to `*`.

## Investigation Focus
1. Check for lingering references to removed/renamed agent-template filenames in `CLAUDE.md`, `settings.json`, and active review dispatch docs.
2. Confirm install/stale-cleanup changes do not remove required `.yaml/.md` script assets outside `sdd/settings/scripts`.
3. Ensure `engines.yaml` copy is not duplicated/conflicting with existing `.sdd/settings/engines.yaml` behavior during update/force modes.
4. Verify references to `templates/review-self/agent-4-*` are eliminated and no dispatch call points at deleted paths.

## Files to Examine
framework/claude/CLAUDE.md
framework/claude/settings.json
framework/claude/sdd/settings/templates/review-self/
framework/claude/skills/sdd-review-self/SKILL.md
framework/claude/skills/sdd-roadmap/SKILL.md
framework/claude/skills/sdd-review/SKILL.md
install.sh

## Output
Write CPF to: .sdd/project/reviews/self/active/agent-dynamic-3-template-migration.cpf
SCOPE:agent-dynamic-3-template-migration

Follow the CPF format from the shared prompt (shared-prompt.md).

After writing CPF, print to stdout:
EXT_REVIEW_COMPLETE
AGENT:dynamic-3
ISSUES: <number of issues found>
WRITTEN:.sdd/project/reviews/self/active/agent-dynamic-3-template-migration.cpf
