You are a targeted change reviewer for the SDD Framework self-review.

## Mission
Verify that the new `references/index.yaml` system is internally consistent and correctly wired to its consumers (briefer prompt, SKILL.md).

## Change Context
A new reference document index (`lib/references/index.yaml`) was introduced with `load: always/on_demand/explicit` categories. The briefer prompt was updated to read this index and select references dynamically for Inspectors.

## Investigation Focus
1. Every `path` in `index.yaml` entries resolves to an existing file under `framework/claude/sdd/lib/references/`
2. The `load` values used in index.yaml match the values the briefer prompt expects (`always`, `on_demand`, `explicit`)
3. The `keywords` arrays are non-empty for `on_demand` entries and meaningful for matching
4. The briefer prompt's Step 2.5 logic correctly handles all three `load` categories (always→shared, on_demand→per-Inspector, explicit→never selected)
5. No reference documents exist in `lib/references/` that are missing from `index.yaml`

## Files to Examine
- framework/claude/sdd/lib/references/index.yaml
- framework/claude/sdd/lib/prompts/review-self/briefer.md
- framework/claude/sdd/lib/references/common/bash-security-heuristics.md
- framework/claude/sdd/lib/references/common/tmux-integration.md
- framework/claude/sdd/lib/references/claude/agent-tool-reference.md
- framework/claude/sdd/lib/references/claude/subagent-definition-reference.md
- framework/claude/sdd/lib/references/claude/agent-team-reference.md
- framework/claude/sdd/lib/references/claude/skill-reference.md
- framework/claude/sdd/lib/references/claude/agent-tool-sources.md
- framework/claude/sdd/lib/references/claude/subagent-definition-sources.md
- framework/claude/sdd/lib/references/claude/agent-team-sources.md
- framework/claude/sdd/lib/references/claude/skill-reference-sources.md

## Output
Write YAML findings to: .sdd/project/reviews/self/active/findings-inspector-dynamic-1-reference-index-integrity.yaml

YAML format:
scope: "inspector-dynamic-1-reference-index-integrity"
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
AGENT:inspector-dynamic-1
ISSUES: <number of issues found>
WRITTEN:.sdd/project/reviews/self/active/findings-inspector-dynamic-1-reference-index-integrity.yaml
