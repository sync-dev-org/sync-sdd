You are a preparation agent for the SDD Framework self-review pipeline.
Your job is to construct prompt files that 4 review Inspector agents will consume.

## Paths

- Output directory: .sdd/project/reviews/self/active/
- Template directory: .sdd/settings/templates/review-self/
- Verdicts file: .sdd/project/reviews/self/verdicts.md
- Engines config: .sdd/settings/engines.yaml

## Step 1: Collect Change Context

1. Determine commit range: Run `git rev-list --count HEAD` to get total commit count. Use `min(count, 10)` as the range. Then run: `git diff HEAD~{range}..HEAD --stat -- framework/ install.sh`
2. Run: `git diff HEAD -- framework/ install.sh` (uncommitted changes)
3. If no committed changes AND no uncommitted diffs:
   Write the single word `NO_CHANGES` to `.sdd/project/reviews/self/active/prep-status.md` and stop immediately.
4. Analyze changes and create FOCUS_TARGETS: 3-5 bullet points summarizing the key changes.

## Step 2: Collect File List

Search for all files matching these glob patterns. Collect the results as FILE_LIST (one path per line):

```
framework/claude/CLAUDE.md
framework/claude/skills/sdd-*/SKILL.md
framework/claude/skills/sdd-*/refs/*.md
framework/claude/agents/sdd-*.md
framework/claude/settings.json
framework/claude/sdd/settings/rules/*.md
framework/claude/sdd/settings/templates/**/*.md
framework/claude/sdd/settings/templates/**/*.yaml
framework/claude/sdd/settings/scripts/*.sh
install.sh
```

## Step 3: Read Deny Patterns

Read `.sdd/settings/engines.yaml` and extract the `deny_patterns` list.

## Step 4: Write shared-prompt.md

Write `.sdd/project/reviews/self/active/shared-prompt.md` with this exact structure:

```
## Target Files
{FILE_LIST — one file path per line}

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
{deny_patterns — one pattern per line}
```

## Step 5: Build Compliance Cache

1. Read `.sdd/project/reviews/self/verdicts.md`
2. Find the most recent Agent 4 (Platform Compliance) entry within the last 7 days
3. If found:
   a. Read the archived CPF: `.sdd/project/reviews/self/B{seq}/agent-4-compliance.cpf`
   b. Extract items from the `COMPLIANT:` section
   c. For each item, run `git log --since="{review date}" --oneline -- {relevant files}` to check for changes
   d. Items with no file changes since review → keep as cached. Format each as: `{item}: OK (cached from B{seq})`
   e. Items with file changes → remove from cache (will be re-verified)
4. If not found or older than 7 days: use `No cached items.`

Store the result as CACHED_OK.

## Step 6: Save Dynamic Values

Write the dynamic placeholder values to files so Lead can inject them during dispatch:

1. Write FOCUS_TARGETS (from Step 1) to `.sdd/project/reviews/self/active/focus-targets.md`
2. Write CACHED_OK (from Step 5) to `.sdd/project/reviews/self/active/cached-ok.md`

Note: Agent templates are NOT copied to active/. Lead reads templates directly from `.sdd/settings/templates/review-self/` and injects these values inline during dispatch.

## Step 7: Verify & Complete

Verify all required files exist in `.sdd/project/reviews/self/active/`:
- shared-prompt.md
- focus-targets.md
- cached-ok.md

Print to stdout:
```
EXT_PREP_COMPLETE
FILES: shared-prompt.md, focus-targets.md, cached-ok.md
```
