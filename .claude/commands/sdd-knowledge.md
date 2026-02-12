---
description: Create knowledge entries from development experiences
allowed-tools: Bash, Glob, Grep, Read, Write, Edit, AskUserQuestion
argument-hint: [type] [description]
---

# SDD Knowledge Capture

<background_information>
- **Mission**: Capture development knowledge (incidents, patterns, references) for future review
- **Success Criteria**:
  - Create well-structured knowledge entry following template
  - Update index.md with new entry
  - Enable context-aware retrieval during `sdd-review-*` commands
</background_information>

<instructions>

## Step 1: Determine Knowledge Type

### If $1 is provided (type specified):
- Validate type is one of: `incident`, `pattern`, `reference`
- If $2 is provided, use as initial description

### If no arguments:
- Use AskUserQuestion to select type:

```
What type of knowledge are you capturing?

A. incident - Problem pattern discovered (learn from failure)
B. pattern - Recommended approach (replicate success)
C. reference - Technical summary (quick lookup)
```

## Step 2: Gather Context via Dialogue

### For incident:
Ask sequentially:
1. "What problem occurred? (brief description)"
2. "What was the root cause?"
3. "At which phase should this have been detected? (requirements/design/tasks/impl)"
4. "What category does this belong to? (state/api/async/data/security/integration)"

### For pattern:
Ask sequentially:
1. "What pattern are you documenting? (brief description)"
2. "When should this pattern be applied?"
3. "Which phases is this applicable to? (requirements/design/tasks/impl)"
4. "What category does this belong to? (state/api/async/data/security/integration)"

### For reference:
Ask sequentially:
1. "What are you documenting? (brief description)"
2. "What is the primary source URL?"
3. "What category does this belong to? (state/api/async/data/security/integration)"

## Step 3: Generate File Name

```
{type}-{category}-{kebab-case-name}.md
```

- Generate kebab-case name from description
- Check for conflicts in `{{KIRO_DIR}}/knowledge/`
- If conflict exists, append numeric suffix

## Step 4: Load Template and Generate Content

1. Read template: `{{KIRO_DIR}}/settings/templates/knowledge/{type}.md`
2. Present template structure to user
3. Use dialogue to fill in key sections:
   - For incident: Focus on "What Happened", "Why Overlooked", "Detection Points"
   - For pattern: Focus on "Solution", "Key Points", "Application Checklist"
   - For reference: Focus on "Quick Reference", "Common Gotchas"
4. Generate complete knowledge file

## Step 5: Write Files

1. Write knowledge file to `{{KIRO_DIR}}/knowledge/{generated-filename}`
2. Update `{{KIRO_DIR}}/knowledge/index.md`:
   - Add entry to appropriate type section
   - Add entry to category section
   - Add entry to phase section (if applicable)

</instructions>

## Tool Guidance

- **AskUserQuestion**: Primary tool for gathering knowledge details
- **Glob**: Check for filename conflicts
- **Read**: Load templates and existing index
- **Write/Edit**: Create knowledge file and update index

## Output Description

Provide output in the user's language:

1. **Created File**: Full path to new knowledge file
2. **Summary**: Brief overview of captured knowledge
3. **Index Updated**: Confirmation of index.md update
4. **Next Steps**: How to use this knowledge in reviews

**Format**: Concise (under 200 words)

## Important Constraints

- Knowledge must be project-independent (portable to other projects)
- Focus on reusable insights, not project-specific details
- Include detection points for each relevant SDD phase
- Keep entries focused and actionable

## Safety & Fallback

### Error Scenarios

- **Invalid Type**: Show available types and re-prompt
- **Template Missing**: Use inline basic structure with warning
- **Index Missing**: Create new index.md from scratch

### Integration with Reviews

After creating knowledge:
- `sdd-review-design` can filter by `Should Detect At: design` or by category matching current spec
- `sdd-review-impl` can filter by `incident-*` for common pitfalls

think
