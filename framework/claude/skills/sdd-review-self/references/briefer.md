# Briefer Instructions

You are a briefer for the SDD Framework self-review pipeline.
Your job is to construct prompt files that 3 fixed Inspectors + 1-4 dynamic Inspectors will consume.

## Paths

These paths are provided by Lead at dispatch time:
- Output directory: (provided as ACTIVE_DIR)
- Template directory: (provided as TEMPLATE_DIR — the references/ directory of this skill)
- Verdicts file: (provided as VERDICTS_PATH)
- Engines config: .sdd/settings/engines.yaml

## Step 1: Collect Change Context

1. Determine commit range: Run `git log --oneline HEAD | wc -l` to get total commit count. Use `min(count, 10)` as the range. Then run: `git diff HEAD~{range}..HEAD --stat -- framework/ install.sh`
2. Run: `git diff HEAD -- framework/ install.sh` (uncommitted changes)
3. If no committed changes AND no uncommitted diffs (including when `framework/` does not exist):
   Write `NO_CHANGES` to `{ACTIVE_DIR}/briefer-status.md` and stop immediately. This skill targets the sync-sdd framework repo only — if `framework/` is absent, this is not the right repo.
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
install.sh
```

## Step 3: Read Deny Patterns

Read `.sdd/settings/engines.yaml` and extract the `deny_patterns` list.

## Step 3b: Read Security Heuristics

Read `.sdd/settings/rules/lead/bash-security-heuristics.md` and store the content as HEURISTICS_CONTENT. This document describes Claude Code platform constraints that the framework intentionally works around — Inspectors must not flag these patterns as issues.

## Step 4: Write shared-prompt.md

Read the shared-prompt structure definition from `{TEMPLATE_DIR}/shared-prompt-structure.md`. Follow that structure exactly, filling in FILE_LIST and deny_patterns from the preceding steps.

Write the result to `{ACTIVE_DIR}/shared-prompt.md`.

## Step 5: Build Compliance Cache

1. Read the verdicts file at VERDICTS_PATH.
2. Find the latest batch with `type: "self"` within the last 7 days — use `batches[].seq` and `batches[].date` fields.
3. If found:
   a. Read the archived findings: `{SCOPE_DIR}/B{seq}/findings-inspector-compliance.yaml` (derive SCOPE_DIR from VERDICTS_PATH by removing the filename).
   b. Extract items from the `compliance:` section.
   c. For each item, run `git log --since="{review date}" --oneline -- {relevant files}` to check for changes.
   d. Items with no file changes since review -> keep as cached. Format each as: `{item}: OK (cached from B{seq})`
   e. Items with file changes -> remove from cache (will be re-verified).
4. If not found or older than 7 days: use `No cached items.`

Store the result as CACHED_OK.

## Step 6: Build Fixed Inspector Prompts

Read each fixed Inspector template from `{TEMPLATE_DIR}/`. Replace placeholders with collected values and write dispatch-ready prompts to `{ACTIVE_DIR}/`:

| Template | Output | Placeholders |
|----------|--------|-------------|
| `inspector-flow.md` | `{ACTIVE_DIR}/inspector-flow.md` | (none) |
| `inspector-consistency.md` | `{ACTIVE_DIR}/inspector-consistency.md` | (none) |
| `inspector-compliance.md` | `{ACTIVE_DIR}/inspector-compliance.md` | `{{CACHED_OK}}` -> CACHED_OK value from Step 5 |

For templates with no placeholders, copy the content as-is.

## Step 7: Build Dynamic Inspector Prompts

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

For each risk axis, write a focused Inspector prompt to `{ACTIVE_DIR}/inspector-dynamic-{N}-{slug}.md` where N is 1-based and slug is a 2-3 word kebab-case identifier (e.g., `cross-ref-integrity`, `template-migration`).

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
Write YAML findings to: {ACTIVE_DIR}/findings-inspector-dynamic-{N}-{slug}.yaml

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
WRITTEN:{ACTIVE_DIR}/findings-inspector-dynamic-{N}-{slug}.yaml
```

### Constraints

- Minimum 1, maximum 4 dynamic Inspectors.
- Do NOT duplicate fixed Inspector scope: flow integrity (inspector-flow), cross-file consistency (inspector-consistency), platform compliance (inspector-compliance) are already covered.
- Each dynamic Inspector should have a narrow, well-defined focus — broad "check everything" prompts produce low signal.
- Keep each prompt concise (under 200 words excluding the Output section).

## Step 8: Write Manifest and Verify

### Dynamic Manifest

Write `{ACTIVE_DIR}/dynamic-manifest.md`:
```
DYNAMIC_COUNT:{N}
inspector-dynamic-1-{slug}|{one-line description}
inspector-dynamic-2-{slug}|{one-line description}
...
```

### Verification

Verify all required files exist in `{ACTIVE_DIR}/`:
- shared-prompt.md
- inspector-flow.md
- inspector-consistency.md
- inspector-compliance.md
- dynamic-manifest.md
- inspector-dynamic-{N}-{slug}.md (for each N in manifest)

Print to stdout:
```
EXT_BRIEFER_COMPLETE
FILES: shared-prompt.md, inspector-flow.md, inspector-consistency.md, inspector-compliance.md
DYNAMIC: {N} (inspector-dynamic-1-{slug}, ...)
```
