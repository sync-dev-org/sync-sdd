---
description: Set up project-wide context (create, update, delete, custom)
allowed-tools: Bash, Glob, Grep, Read, Write, Edit, AskUserQuestion
argument-hint: [-y] [custom]
---

# SDD Steering (Unified)

<instructions>

## Core Task

Manage project steering documents. Lead handles directly (no SubAgent dispatch needed) since it requires user interaction.

**Before any steering operation**, read `{{SDD_DIR}}/settings/rules/steering-principles.md` and apply its principles (content granularity, security, quality standards, preservation rules) throughout.

## Step 1: Detect Mode

```
$ARGUMENTS = "custom"      → Custom steering creation
$ARGUMENTS = "-y"           → Auto-approve update mode
$ARGUMENTS = ""             → Auto-detect (create if missing, update if exists)
```

## Step 2: Check Steering State

1. Check if core steering files exist in `{{SDD_DIR}}/project/steering/`:
   - `product.md`, `tech.md`, `structure.md`
2. Scan for any custom steering files (`*.md` excluding core files)

### If No Steering Exists → Create Mode

Execute full steering creation:
1. Ask about codebase analysis preference
2. If selected: Scan project structure, extract patterns, tech stack
3. **Language profile selection**:
   a. Read available profiles from `{{SDD_DIR}}/settings/profiles/` (exclude `_index.md`)
   b. If codebase analysis detected a language → suggest the matching profile
   c. Present options: available profiles + "None (fully manual)"
   d. Selected profile pre-fills `tech.md` and `structure.md` values (type safety, code quality, testing, naming, imports, commands)
4. 6-question dialogue (profile answers pre-filled where applicable; user can override):
   - Project purpose and domain
   - Target users
   - Key capabilities
   - Technology stack (pre-filled from profile)
   - Architecture approach
   - Development standards (pre-filled from profile)
5. Generate steering files from templates in `{{SDD_DIR}}/settings/templates/steering/`
6. **Apply profile suggestions**: If a profile was selected, inform user of recommended Bash permissions for `settings.json` (from profile's Suggested Permissions section)
7. **Initialize User Intent** in `product.md`:
   - Record user's Vision from dialogue
   - Set initial Success Criteria and Anti-Goals
8. Present summary (include which profile was applied, if any)

### If Steering Exists → Update/Reset Mode

1. Build status summary from existing steering files
2. Present options:
   - **Update**: Targeted dialogue-driven changes (what to change: Product/Tech/Structure/Profile/Everything)
   - **Reset**: Delete all and recreate (requires "RESET" confirmation)
3. If "Profile" selected: re-run profile selection flow and update tech.md/structure.md accordingly
4. Execute selected action
5. After update: auto-draft `{{SDD_DIR}}/handover/session.md`

### Custom Mode (`custom` argument)

1. Ask for custom steering topic (suggest: API standards, testing, security, DB, auth, etc.)
2. Check if a matching template exists in `{{SDD_DIR}}/settings/templates/steering-custom/`:
   - `api-standards.md`, `authentication.md`, `database.md`, `deployment.md`, `error-handling.md`, `security.md`, `testing.md`, `ui.md`
   - If match found: use as base template, pre-fill structure and sections
   - If no match: generate structure from scratch
3. Optional codebase analysis
4. Topic-specific dialogue (template sections guide the conversation)
5. Generate custom steering file: `{{SDD_DIR}}/project/steering/{topic}.md`

## Step 3: Post-Completion

1. Auto-draft `{{SDD_DIR}}/handover/session.md`
2. Report summary to user
3. Suggest next action: `/sdd-roadmap design "description"` or `/sdd-roadmap create`

</instructions>

## Error Handling

- **Template missing**: Warn and use inline basic structure
- **Steering directory missing**: Create it automatically
