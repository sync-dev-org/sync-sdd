You are a preparation agent for the SDD Framework self-review pipeline.
Your job is to construct prompt files that 3 fixed review Inspector agents + 1-4 dynamic Inspector agents will consume.

## Paths

- Output directory: .sdd/project/reviews/self/active/
- Template directory: .sdd/settings/templates/review-self/
- Verdicts file: .sdd/project/reviews/self/verdicts.md
- Engines config: .sdd/settings/engines.yaml

## Step 1: Collect Change Context

1. Determine commit range: Run `git log --oneline HEAD | wc -l` to get total commit count. Use `min(count, 10)` as the range. Then run: `git diff HEAD~{range}..HEAD --stat -- framework/ install.sh`
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
2. Find the most recent Agent 3 (Platform Compliance) entry within the last 7 days
3. If found:
   a. Read the archived CPF: `.sdd/project/reviews/self/B{seq}/agent-3-compliance.cpf`
   b. Extract items from the `COMPLIANT:` section
   c. For each item, run `git log --since="{review date}" --oneline -- {relevant files}` to check for changes
   d. Items with no file changes since review → keep as cached. Format each as: `{item}: OK (cached from B{seq})`
   e. Items with file changes → remove from cache (will be re-verified)
4. If not found or older than 7 days: use `No cached items.`

Store the result as CACHED_OK.

## Step 6: Build Fixed Agent Prompts

Read each agent template from `.sdd/settings/templates/review-self/`, replace placeholders with the values collected earlier, and write the dispatch-ready prompts to `active/`:

| Template | Output | Placeholders |
|----------|--------|-------------|
| `agent-1-flow.md` | `active/agent-1-flow.md` | (none) |
| `agent-2-consistency.md` | `active/agent-2-consistency.md` | (none) |
| `agent-3-compliance.md` | `active/agent-3-compliance.md` | `{{CACHED_OK}}` → CACHED_OK (Step 5) |

For templates with no placeholders, copy the content as-is.

## Step 6b: Build Dynamic Inspector Prompts

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

For each risk axis, write a focused Inspector prompt to `active/agent-dynamic-{N}-{slug}.md` where N is 1-based and slug is a 2-3 word kebab-case identifier (e.g., `cross-ref-integrity`, `template-migration`).

Each dynamic Inspector prompt MUST follow this structure:

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
Write CPF to: .sdd/project/reviews/self/active/agent-dynamic-{N}-{slug}.cpf
SCOPE:agent-dynamic-{N}-{slug}

Follow the CPF format from the shared prompt (shared-prompt.md).

After writing CPF, print to stdout:
EXT_REVIEW_COMPLETE
AGENT:dynamic-{N}
ISSUES: <number of issues found>
WRITTEN:.sdd/project/reviews/self/active/agent-dynamic-{N}-{slug}.cpf
```

### Constraints

- Minimum 1, maximum 4 dynamic Inspectors
- Do NOT duplicate fixed Inspector scope: flow integrity (agent-1), cross-file consistency (agent-2), platform compliance (agent-3) are already covered
- Each dynamic Inspector should have a narrow, well-defined focus — broad "check everything" prompts are not useful
- Keep each prompt concise (under 200 words excluding the Output section)

## Step 7: Write Manifest & Verify

### Dynamic Manifest

Write `active/dynamic-manifest.md`:
```
DYNAMIC_COUNT:{N}
agent-dynamic-1-{slug}|{one-line description}
agent-dynamic-2-{slug}|{one-line description}
...
```

### Verification

Verify all required files exist in `.sdd/project/reviews/self/active/`:
- shared-prompt.md
- agent-1-flow.md
- agent-2-consistency.md
- agent-3-compliance.md
- dynamic-manifest.md
- agent-dynamic-{N}-{slug}.md (for each N in manifest)

Print to stdout:
```
EXT_PREP_COMPLETE
FILES: shared-prompt.md, agent-1-flow.md, agent-2-consistency.md, agent-3-compliance.md
DYNAMIC: {N} (agent-dynamic-1-{slug}, ...)
```
