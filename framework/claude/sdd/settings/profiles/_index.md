# Language Profiles

Language profiles provide language-specific defaults for steering files during `/sdd-steering` creation.

## How Profiles Work

1. During `/sdd-steering` create, Lead presents available profiles
2. User selects a profile (or "None" for fully manual setup)
3. Profile values pre-fill `tech.md` and `structure.md` templates
4. User can customize any pre-filled value during the dialogue

Profiles are **starting points**, not constraints. All values can be overridden.

The selected profile's identifier (e.g., `python`, `typescript`, `rust`) is stored in `spec.json.language` for each feature specification.

## Profile Format

Each profile is a markdown file with the following sections:

### Core Technologies
- **Language**: Name and minimum version
- **Package Manager**: Primary package manager
- **Runtime**: Execution environment (if applicable)

### Development Standards
- **Type Safety**: Type checking approach and tools
- **Code Quality**: Linter and formatter
- **Testing**: Test framework and conventions

### Structure Conventions
- **Naming**: File, class, function, constant naming patterns
- **Import Organization**: Import ordering conventions
- **Module Structure**: How code is organized into modules

### Common Commands
```bash
# Dev: [command]
# Build: [command]
# Test: [command]
# Lint: [command]
# Format: [command]
```

### Suggested Permissions
Bash permissions to add to `.claude/settings.json` for this language.

### Version Management
How project versions are managed (if language has conventions).

## Creating Custom Profiles

Copy an existing profile and modify it. Profile files are plain markdown — no special syntax required.

Framework-specific profiles (e.g., Django, Next.js) can extend a base language profile by referencing it and adding framework-specific sections.
