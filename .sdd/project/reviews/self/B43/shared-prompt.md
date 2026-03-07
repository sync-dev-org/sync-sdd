## Target Files
install.sh
framework/claude/CLAUDE.md
framework/claude/settings.json
framework/claude/agents/sdd-analyst.md
framework/claude/agents/sdd-architect.md
framework/claude/agents/sdd-builder.md
framework/claude/agents/sdd-conventions-scanner.md
framework/claude/agents/sdd-taskgenerator.md
framework/claude/skills/sdd-handover/SKILL.md
framework/claude/skills/sdd-publish-setup/SKILL.md
framework/claude/skills/sdd-release/SKILL.md
framework/claude/skills/sdd-review/SKILL.md
framework/claude/skills/sdd-review-self/SKILL.md
framework/claude/skills/sdd-reboot/SKILL.md
framework/claude/skills/sdd-roadmap/SKILL.md
framework/claude/skills/sdd-roadmap/refs/crud.md
framework/claude/skills/sdd-roadmap/refs/design.md
framework/claude/skills/sdd-roadmap/refs/impl.md
framework/claude/skills/sdd-roadmap/refs/revise.md
framework/claude/skills/sdd-roadmap/refs/run.md
framework/claude/skills/sdd-start/SKILL.md
framework/claude/skills/sdd-status/SKILL.md
framework/claude/skills/sdd-steering/SKILL.md
framework/claude/sdd/settings/rules/cpf-format.md
framework/claude/sdd/settings/rules/design-discovery-full.md
framework/claude/sdd/settings/rules/design-discovery-light.md
framework/claude/sdd/settings/rules/design-principles.md
framework/claude/sdd/settings/rules/design-review.md
framework/claude/sdd/settings/rules/steering-principles.md
framework/claude/sdd/settings/rules/tasks-generation.md
framework/claude/sdd/settings/rules/tmux-integration.md
framework/claude/sdd/settings/rules/verdict-format.md
framework/claude/sdd/settings/templates/handover/buffer.md
framework/claude/sdd/settings/templates/handover/session.md
framework/claude/sdd/settings/templates/reboot/analysis-report.md
framework/claude/sdd/settings/templates/review/auditor-brief.md
framework/claude/sdd/settings/templates/review/auditor.md
framework/claude/sdd/settings/templates/review/inspector-brief.md
framework/claude/sdd/settings/templates/review/inspector-dead-code.md
framework/claude/sdd/settings/templates/review/inspector-dead-settings.md
framework/claude/sdd/settings/templates/review/inspector-dead-specs.md
framework/claude/sdd/settings/templates/review/inspector-dead-tests.md
framework/claude/sdd/settings/templates/review/inspector-design-architecture.md
framework/claude/sdd/settings/templates/review/inspector-design-best-practices.md
framework/claude/sdd/settings/templates/review/inspector-design-consistency.md
framework/claude/sdd/settings/templates/review/inspector-design-rulebase.md
framework/claude/sdd/settings/templates/review/inspector-design-testability.md
framework/claude/sdd/settings/templates/review/inspector-impl-consistency.md
framework/claude/sdd/settings/templates/review/inspector-impl-e2e.md
framework/claude/sdd/settings/templates/review/inspector-impl-interface.md
framework/claude/sdd/settings/templates/review/inspector-impl-quality.md
framework/claude/sdd/settings/templates/review/inspector-impl-rulebase.md
framework/claude/sdd/settings/templates/review/inspector-impl-test.md
framework/claude/sdd/settings/templates/review/inspector-impl-web-e2e.md
framework/claude/sdd/settings/templates/review/inspector-impl-web-visual.md
framework/claude/sdd/settings/templates/review-self/auditor.md
framework/claude/sdd/settings/templates/review-self/briefer.md
framework/claude/sdd/settings/templates/review-self/inspector-compliance.md
framework/claude/sdd/settings/templates/review-self/inspector-consistency.md
framework/claude/sdd/settings/templates/review-self/inspector-flow.md
framework/claude/sdd/settings/templates/review-self/builder.md
framework/claude/sdd/settings/templates/specs/design.md
framework/claude/sdd/settings/templates/specs/init.yaml
framework/claude/sdd/settings/templates/specs/research.md
framework/claude/sdd/settings/templates/steering/product.md
framework/claude/sdd/settings/templates/steering/structure.md
framework/claude/sdd/settings/templates/steering/tech.md
framework/claude/sdd/settings/templates/steering-custom/api-standards.md
framework/claude/sdd/settings/templates/steering-custom/authentication.md
framework/claude/sdd/settings/templates/steering-custom/database.md
framework/claude/sdd/settings/templates/steering-custom/deployment.md
framework/claude/sdd/settings/templates/steering-custom/error-handling.md
framework/claude/sdd/settings/templates/steering-custom/security.md
framework/claude/sdd/settings/templates/steering-custom/testing.md
framework/claude/sdd/settings/templates/steering-custom/ui.md
framework/claude/sdd/settings/templates/wave-context/conventions-brief.md
framework/claude/sdd/settings/scripts/claude-stream-progress.jq
framework/claude/sdd/settings/scripts/grid-check.sh
framework/claude/sdd/settings/scripts/multiview-grid.sh
framework/claude/sdd/settings/scripts/orphan-detect.sh
framework/claude/sdd/settings/scripts/ensure-playwright-cli.sh

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
mkfs
:(){:|:&};:
