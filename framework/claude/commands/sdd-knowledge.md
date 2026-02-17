---
description: Manage reusable knowledge entries and review auto-accumulated knowledge
allowed-tools: Bash, Glob, Grep, Read, Write, Edit, AskUserQuestion
argument-hint: [type] [description] | [--review] | [--skills]
---

# SDD Knowledge (Unified)

<instructions>

## Core Task

Manage knowledge entries: manual capture, auto-accumulated review, and Skill emergence. Conductor handles directly.

## Step 1: Detect Mode

```
$ARGUMENTS = ""                    → Manual capture (interactive type selection)
$ARGUMENTS = "{type} {description}" → Manual capture (type + description provided)
$ARGUMENTS = "--review"            → Review auto-accumulated knowledge buffer
$ARGUMENTS = "--skills"            → Review and manage Skill emergence candidates
```

## Manual Capture Mode

### Determine Knowledge Type

If type provided, validate: `incident`, `pattern`, `reference`
If not provided, ask user to select.

### Gather Context via Dialogue

**For incident**: What happened? Root cause? Detection phase? Category?
**For pattern**: What pattern? When to apply? Applicable phases? Category?
**For reference**: What to document? Source URL? Category?

Categories: `state`, `api`, `async`, `data`, `security`, `integration`

### Generate and Write

1. Generate filename: `{type}-{category}-{kebab-case-name}.md`
2. Check for conflicts in `{{SDD_DIR}}/project/knowledge/`
3. Load template: `{{SDD_DIR}}/settings/templates/knowledge/{type}.md`
4. Generate content via dialogue
5. Write knowledge file
6. Update `{{SDD_DIR}}/project/knowledge/index.md`

## Auto-Accumulated Review Mode (`--review`)

Review knowledge collected automatically by Lead from Builder/Inspector reports.

1. Read `{{SDD_DIR}}/handover/conductor.md` → Knowledge Buffer section
2. If buffer is empty: "No auto-accumulated knowledge to review."
3. Present each buffered entry to user:
   - Show tag (`[PATTERN]`/`[INCIDENT]`/`[REFERENCE]`), source, content
   - Options: **Accept** (write to knowledge/), **Edit** (modify before writing), **Discard**
4. Write accepted entries using templates
5. Update index.md
6. Clear processed entries from Knowledge Buffer

## Skill Emergence Mode (`--skills`)

Review Skill candidates detected by Lead.

1. Read Skill candidates from `{{SDD_DIR}}/handover/conductor.md`
2. If none: "No Skill candidates detected yet."
3. Present each candidate:
   - Pattern description
   - Specs where detected (2+ required)
   - Proposed Skill name and purpose
   - Options: **Approve** (generate Skill file), **Modify** (edit before generating), **Reject**
4. For approved Skills:
   - Generate command file in `.claude/commands/{skill-name}.md`
   - Report to user: Skill created, available via `/{skill-name}`

## Post-Completion

1. Report summary:
   - Created/reviewed entries count
   - Index updated confirmation
   - Skills created (if any)
2. Suggest: knowledge is used during `/sdd-review` for context-aware checks

</instructions>

## Error Handling

- **Invalid type**: Show available types and re-prompt
- **Template missing**: Use inline basic structure with warning
- **Index missing**: Create new index.md from scratch
- **Empty knowledge buffer**: Inform user, suggest manual capture

## Integration with Reviews

After creating knowledge:
- `/sdd-review design` can filter by detection phase or category
- `/sdd-review impl` can filter by `incident-*` for common pitfalls

think
