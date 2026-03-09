## Target Files
framework/claude/skills/sdd-review-self/SKILL.md
framework/claude/sdd/lib/prompts/dispatch/engine.md
framework/claude/sdd/lib/prompts/dispatch/escalation.md
framework/claude/sdd/lib/prompts/review-self/briefer.md
framework/claude/sdd/lib/prompts/review-self/shared-prompt-structure.md
framework/claude/sdd/lib/prompts/review-self/inspector-flow.md
framework/claude/sdd/lib/prompts/review-self/inspector-consistency.md
framework/claude/sdd/lib/prompts/review-self/inspector-compliance.md
framework/claude/sdd/lib/prompts/review-self/auditor.md
framework/claude/sdd/lib/references/bash-security-heuristics.md
framework/claude/sdd/lib/references/skill-reference.md
framework/claude/sdd/settings/engines.yaml
framework/claude/sdd/settings/templates/review-self/briefer.md
framework/claude/sdd/settings/templates/review-self/inspector-flow.md
framework/claude/sdd/settings/templates/review-self/inspector-consistency.md
framework/claude/sdd/settings/templates/review-self/inspector-compliance.md
framework/claude/sdd/settings/templates/review-self/auditor.md
framework/claude/sdd/settings/templates/review-self/builder.md
framework/claude/CLAUDE.md
install.sh

## YAML Output Format
Write findings in YAML format:
```yaml
scope: "{inspector-name}"
issues:
  - id: "F1"
    severity: "H"
    category: "{category}"
    location: "{file}:{line}"
    summary: "{one-line summary}"
    detail: "{what}"
    impact: "{why}"
    recommendation: "{how}"
notes: |
  Additional context
```
- Severity codes: C=Critical, H=High, M=Medium, L=Low
- Report ALL severity levels including LOW. A review with zero LOW findings is suspicious — verify you haven't self-filtered.
- `issues`: empty list `[]` if no findings

Report findings in Japanese.

## Claude Code Bash Security Heuristics

The SDD framework intentionally uses Bash patterns that work around Claude Code's security heuristic detection. These are NOT bugs — do NOT flag them as issues.

Read `.sdd/lib/references/bash-security-heuristics.md` for the full list of known heuristic patterns and their workarounds.

## PROHIBITED COMMANDS (MUST NEVER execute)

Read the `deny_patterns` section from `.sdd/settings/engines.yaml` for the list of prohibited commands.
