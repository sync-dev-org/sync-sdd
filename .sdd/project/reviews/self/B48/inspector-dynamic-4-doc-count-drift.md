You are a targeted change reviewer for the SDD Framework self-review.

## Mission
Verify that CLAUDE.md and README.md counts and descriptions remain accurate after the addition of new reference documents and structural changes.

## Change Context
Multiple new reference documents were added (agent-tool-reference, subagent-definition-reference, agent-team-reference, skill-reference, plus sources files). Review-self templates were added/updated. The CLAUDE.md was updated (2 lines changed). Verify all numeric claims still hold.

## Investigation Focus
1. CLAUDE.md command count (12) matches actual skill count in `framework/claude/skills/sdd-*/SKILL.md`
2. CLAUDE.md agent count (5 agents) matches actual agent files in `framework/claude/agents/sdd-*.md`
3. CLAUDE.md review template count (21: 17 inspector + 1 auditor + 1 briefer + 2 brief) matches actual files in `settings/templates/review/`
4. Review-self template counts in `settings/templates/review-self/` are consistent with documentation
5. engines.yaml level chain table in CLAUDE.md matches actual `engines.yaml` content

## Files to Examine
- framework/claude/CLAUDE.md
- framework/claude/sdd/settings/engines.yaml
- framework/claude/skills/sdd-*/SKILL.md (count only)
- framework/claude/agents/sdd-*.md (count only)
- framework/claude/sdd/settings/templates/review/*.md (count only)
- framework/claude/sdd/settings/templates/review-self/*.md (count only)

## Output
Write YAML findings to: .sdd/project/reviews/self/active/findings-inspector-dynamic-4-doc-count-drift.yaml

YAML format:
scope: "inspector-dynamic-4-doc-count-drift"
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

After writing, print to stdout:
EXT_REVIEW_COMPLETE
AGENT:inspector-dynamic-4
ISSUES: <number of issues found>
WRITTEN:.sdd/project/reviews/self/active/findings-inspector-dynamic-4-doc-count-drift.yaml
