---
name: sdd-steering
description: Set up project-wide context (create, update, delete, custom)
allowed-tools: Bash, Glob, Grep, Read, Write, Edit, Skill
argument-hint: [-y] [custom]
---

# SDD Steering (Unified)

<instructions>

## Core Task

Manage project steering documents. Lead handles directly (no SubAgent dispatch needed) since it requires user interaction.

**Before any steering operation**, read `{{SDD_DIR}}/settings/rules/agent/steering-principles.md` and apply its principles (content granularity, security, quality standards, preservation rules) throughout.

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
5a. **Environment setup** (Python profile selected):
    If `pyproject.toml` exists: read and verify alignment with tech stack decisions (core deps, test tools, linters).
    If `pyproject.toml` does not exist: create it with project metadata from dialogue, core dependencies from tech stack decisions, dev dependency group (test tools + linters + formatters + ALL extras), and extras groups for optional packages (if discussed).
    Run install command from `# Install:` line to create/update virtual environment. If `# Install:` line is empty or not found in tech.md, skip and warn user: "No install command configured in tech.md."
    Principle: dev environment = all dependencies installed. Extras are for end-user selective installation; developers always have everything.
6. **Pitfalls transfer**: If the selected profile has a `## Known Pitfalls` section, scan the project's dependencies (`pyproject.toml`, `package.json`, or equivalent) and transfer only the pitfall entries whose library/topic matches the project's actual dependencies into `tech.md ## Pitfalls`. Omit pitfall groups for libraries/topics not used by the project.
7. **Apply profile suggestions**: If a profile was selected, inform user of recommended Bash permissions for `settings.json` (from profile's Suggested Permissions section)
8. **Initialize User Intent** in `product.md`:
   - Record user's Vision from dialogue
   - Set initial Success Criteria and Anti-Goals
9. Present summary (include which profile was applied, if any)
10. **Publish pipeline offer** (Python profile only):
    If the selected profile is `python`, ask the user if they plan to publish this package to PyPI. If yes, run the following pre-flight checks before invoking `/sdd-publish-setup`:

    a. **Git remote**: `git remote get-url origin` — if no remote, inform user and skip (publish setup requires a GitHub remote)
    b. **Existing CI/CD**: Check if `.github/workflows/publish.yml` (or any `*.yml` with `pypi` or `publish` in the filename/content) already exists. If found, inform user and skip ("Publish workflow already exists")
    c. **PyPI name availability**: Read `[project] name` from `pyproject.toml`. Run `curl -s -o /dev/null -w '%{http_code}' https://pypi.org/pypi/{name}/json` — if HTTP 200, the name is already taken (warn user: "Package name '{name}' already exists on PyPI. You may need to choose a different name or verify you own it"). If HTTP 404, the name is available (good). If no `pyproject.toml` or no name field, skip this check
    d. If all checks pass (or user acknowledges warnings), invoke `/sdd-publish-setup` via Skill tool

    If the user declines PyPI publish, skip entirely.

### If Steering Exists → Update/Reset Mode

1. Build status summary from existing steering files
2. Present options:
   - **Update**: Targeted dialogue-driven changes (what to change: Product/Tech/Structure/Profile/Everything)
   - **Reset**: Delete all and recreate (requires "RESET" confirmation)
3. If "Profile" selected: re-run profile selection flow and update tech.md/structure.md accordingly
4. Execute selected action
5. After update: auto-draft `{{SDD_DIR}}/session/handover.md`

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

1. Auto-draft `{{SDD_DIR}}/session/handover.md`
2. Report summary to user
3. Suggest next action: `/sdd-roadmap design "description"` or `/sdd-roadmap create`

</instructions>

## Error Handling

- **Template missing**: Warn and use inline basic structure
- **Steering directory missing**: Create it automatically
