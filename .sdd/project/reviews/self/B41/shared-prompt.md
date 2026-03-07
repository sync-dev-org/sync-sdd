## Target Files
framework/claude/CLAUDE.md
framework/claude/agents/sdd-analyst.md
framework/claude/agents/sdd-architect.md
framework/claude/agents/sdd-builder.md
framework/claude/agents/sdd-conventions-scanner.md
framework/claude/agents/sdd-taskgenerator.md
framework/claude/sdd/settings/rules/cpf-format.md
framework/claude/sdd/settings/rules/design-discovery-full.md
framework/claude/sdd/settings/rules/design-discovery-light.md
framework/claude/sdd/settings/rules/design-principles.md
framework/claude/sdd/settings/rules/design-review.md
framework/claude/sdd/settings/rules/steering-principles.md
framework/claude/sdd/settings/rules/tasks-generation.md
framework/claude/sdd/settings/rules/tmux-integration.md
framework/claude/sdd/settings/scripts/claude-stream-progress.jq
framework/claude/sdd/settings/scripts/ensure-playwright-cli.sh
framework/claude/sdd/settings/scripts/grid-check.sh
framework/claude/sdd/settings/scripts/multiview-grid.sh
framework/claude/sdd/settings/scripts/orphan-detect.sh
framework/claude/sdd/settings/templates/handover/buffer.md
framework/claude/sdd/settings/templates/handover/session.md
framework/claude/sdd/settings/templates/reboot/analysis-report.md
framework/claude/sdd/settings/templates/review-self/agent-1-flow.md
framework/claude/sdd/settings/templates/review-self/agent-2-consistency.md
framework/claude/sdd/settings/templates/review-self/agent-3-compliance.md
framework/claude/sdd/settings/templates/review-self/auditor.md
framework/claude/sdd/settings/templates/review-self/prep.md
framework/claude/sdd/settings/templates/review/auditor-preamble.md
framework/claude/sdd/settings/templates/review/auditor.md
framework/claude/sdd/settings/templates/review/context-preamble.md
framework/claude/sdd/settings/templates/review/dead-code.md
framework/claude/sdd/settings/templates/review/dead-settings.md
framework/claude/sdd/settings/templates/review/dead-specs.md
framework/claude/sdd/settings/templates/review/dead-tests.md
framework/claude/sdd/settings/templates/review/design-architecture.md
framework/claude/sdd/settings/templates/review/design-best-practices.md
framework/claude/sdd/settings/templates/review/design-consistency.md
framework/claude/sdd/settings/templates/review/design-rulebase.md
framework/claude/sdd/settings/templates/review/design-testability.md
framework/claude/sdd/settings/templates/review/impl-consistency.md
framework/claude/sdd/settings/templates/review/impl-e2e.md
framework/claude/sdd/settings/templates/review/impl-interface.md
framework/claude/sdd/settings/templates/review/impl-quality.md
framework/claude/sdd/settings/templates/review/impl-rulebase.md
framework/claude/sdd/settings/templates/review/impl-test.md
framework/claude/sdd/settings/templates/review/impl-web-e2e.md
framework/claude/sdd/settings/templates/review/impl-web-visual.md
framework/claude/sdd/settings/templates/review/prep.md
framework/claude/sdd/settings/templates/specs/design.md
framework/claude/sdd/settings/templates/specs/init.yaml
framework/claude/sdd/settings/templates/specs/research.md
framework/claude/sdd/settings/templates/steering-custom/api-standards.md
framework/claude/sdd/settings/templates/steering-custom/authentication.md
framework/claude/sdd/settings/templates/steering-custom/database.md
framework/claude/sdd/settings/templates/steering-custom/deployment.md
framework/claude/sdd/settings/templates/steering-custom/error-handling.md
framework/claude/sdd/settings/templates/steering-custom/security.md
framework/claude/sdd/settings/templates/steering-custom/testing.md
framework/claude/sdd/settings/templates/steering-custom/ui.md
framework/claude/sdd/settings/templates/steering/product.md
framework/claude/sdd/settings/templates/steering/structure.md
framework/claude/sdd/settings/templates/steering/tech.md
framework/claude/sdd/settings/templates/wave-context/conventions-brief.md
framework/claude/settings.json
framework/claude/skills/sdd-handover/SKILL.md
framework/claude/skills/sdd-publish-setup/SKILL.md
framework/claude/skills/sdd-reboot/SKILL.md
framework/claude/skills/sdd-reboot/refs/reboot.md
framework/claude/skills/sdd-release/SKILL.md
framework/claude/skills/sdd-review-self/SKILL.md
framework/claude/skills/sdd-review/SKILL.md
framework/claude/skills/sdd-roadmap/SKILL.md
framework/claude/skills/sdd-roadmap/refs/crud.md
framework/claude/skills/sdd-roadmap/refs/design.md
framework/claude/skills/sdd-roadmap/refs/impl.md
framework/claude/skills/sdd-roadmap/refs/revise.md
framework/claude/skills/sdd-roadmap/refs/run.md
framework/claude/skills/sdd-start/SKILL.md
framework/claude/skills/sdd-status/SKILL.md
framework/claude/skills/sdd-steering/SKILL.md
install.sh

## CPF Format
Write findings in CPF (Compact Pipe-Delimited Format):
- Metadata lines: KEY:VALUE (no space around colon)
- Section header: ISSUES: followed by one record per line
- Issue format: SEVERITY|category|location|description
- Severity codes: C=Critical, H=High, M=Medium, L=Low
- Report ALL severity levels including LOW. A review with zero LOW findings is suspicious — verify you haven't self-filtered.
- Omit empty sections

Report findings in Japanese.

## PROHIBITED COMMANDS (MUST NEVER execute)
rm -rf /
rm -rf ~
rm -rf .
rm -rf *
git push --force
git push -f
git reset --hard
shutdown
reboot
> /dev/
dd if=
:(){:|:&};:
