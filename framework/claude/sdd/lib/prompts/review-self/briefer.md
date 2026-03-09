# Briefer Instructions

You are a briefer for the SDD Framework self-review pipeline.
Your job is to construct prompt files that 3 fixed Inspectors + 1-4 dynamic Inspectors will consume.

## Paths (hardcoded)

- Output directory: `.sdd/project/reviews/self/active/`
- Verdicts file: `.sdd/project/reviews/self/verdicts.yaml`
- Engines config: `.sdd/settings/engines.yaml`
- Shared-prompt structure: `.sdd/lib/prompts/review-self/shared-prompt-structure.md`

## Step 1: Collect Change Context

1. Determine commit range: Run `git log --oneline HEAD | wc -l` to get total commit count. Use `min(count, 10)` as the range. Then run: `git diff HEAD~{range}..HEAD --stat -- framework/ install.sh`
2. Run: `git diff HEAD -- framework/ install.sh` (uncommitted changes)
3. If no committed changes AND no uncommitted diffs (including when `framework/` does not exist):
   Write `NO_CHANGES` to `.sdd/project/reviews/self/active/briefer-status.md` and stop immediately. This skill targets the sync-sdd framework repo only — if `framework/` is absent, this is not the right repo.
4. Analyze changes and create FOCUS_TARGETS: 3-5 bullet points summarizing the key changes.

## Step 2: Collect File List

Search for all files matching these glob patterns. Collect the results as FILE_LIST (one path per line):

```
framework/claude/CLAUDE.md
framework/claude/skills/sdd-*/SKILL.md
framework/claude/skills/sdd-*/references/*.md
framework/claude/agents/sdd-*.md
framework/claude/settings.json
framework/claude/sdd/settings/rules/**/*.md
framework/claude/sdd/settings/templates/**/*.md
framework/claude/sdd/settings/templates/**/*.yaml
framework/claude/sdd/settings/scripts/*
framework/claude/sdd/settings/engines.yaml
framework/claude/sdd/lib/**/*.md
install.sh
```

## Step 3: Write shared-prompt.md

Read the shared-prompt structure definition from `.sdd/lib/prompts/review-self/shared-prompt-structure.md`. Follow that structure exactly, filling in FILE_LIST from Step 2.

Write the result to `.sdd/project/reviews/self/active/shared-prompt.md`.

## Step 4: Build Dynamic Inspector Prompts

Using FOCUS_TARGETS (Step 1) and the git diff output, identify 1-4 risk axes that the fixed Inspectors (flow/consistency/compliance) do not adequately cover. These are change-specific risks that require targeted investigation.

### Risk Identification Guide

Consider these categories (select only those relevant to the actual changes):
- Cross-reference integrity: step numbers, file paths, count values that reference each other across files
- Migration/rename completeness: old names lingering after rename, path mismatches after file moves
- Deleted file reference residue: references to files that no longer exist
- Config-implementation alignment: settings.json, engines.yaml entries vs actual file/agent/skill existence
- Documentation-reality drift: README, CLAUDE.md counts/descriptions vs actual state
- Placeholder/template variable expansion: unreplaced `{{VAR}}` patterns
- Dispatch pattern consistency: SubAgent/tmux/background mode handling parity

### Prompt Generation

For each risk axis, write a focused Inspector prompt to `.sdd/project/reviews/self/active/inspector-dynamic-{N}-{slug}.md` where N is 1-based and slug is a 2-3 word kebab-case identifier (e.g., `cross-ref-integrity`, `template-migration`).

Each dynamic Inspector prompt follows this structure:

```markdown
You are a targeted change reviewer for the SDD Framework self-review.

## Mission
{1-2 sentences describing the specific risk to investigate}

## Change Context
{Summary of what changed, derived from the git diff analysis, relevant to this risk}

## Investigation Focus
{3-5 specific items to check — include concrete file names, patterns, or values}

## Files to Examine
{List of specific file paths relevant to this risk axis}

## Output
Write YAML findings to: .sdd/project/reviews/self/active/findings-inspector-dynamic-{N}-{slug}.yaml

YAML format:
scope: "inspector-dynamic-{N}-{slug}"
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
AGENT:inspector-dynamic-{N}
ISSUES: <number of issues found>
WRITTEN:.sdd/project/reviews/self/active/findings-inspector-dynamic-{N}-{slug}.yaml
```

### Constraints

- Minimum 1, maximum 4 dynamic Inspectors.
- Do NOT duplicate fixed Inspector scope: flow integrity (inspector-flow), cross-file consistency (inspector-consistency), platform compliance (inspector-compliance) are already covered.
- Each dynamic Inspector should have a narrow, well-defined focus — broad "check everything" prompts produce low signal.
- Keep each prompt concise (under 200 words excluding the Output section).

## Step 5: Write Manifest and Verify

### Dynamic Manifest

Write `.sdd/project/reviews/self/active/dynamic-manifest.md`:
```
DYNAMIC_COUNT:{N}
inspector-dynamic-1-{slug}|{one-line description}
inspector-dynamic-2-{slug}|{one-line description}
...
```

### Verification

Verify all required files exist in `.sdd/project/reviews/self/active/`:
- shared-prompt.md
- dynamic-manifest.md
- inspector-dynamic-{N}-{slug}.md (for each N in manifest)

Print to stdout:
```
EXT_BRIEFER_COMPLETE
FILES: shared-prompt.md
DYNAMIC: {N} (inspector-dynamic-1-{slug}, ...)
```
