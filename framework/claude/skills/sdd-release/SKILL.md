---
description: Create a versioned release (branch, tag, push)
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, AskUserQuestion
argument-hint: <patch|minor|major|vX.Y.Z> <summary>
---

# SDD Release

<instructions>

## Core Task

Create a versioned release. Automates: version determination → documentation update → metadata update → commit → release branch → tag → push → return to main → push.

Trunk-based development: commit on main first, then create a release branch as a snapshot.

## Input

Arguments: `$ARGUMENTS`
- **$0**: version — bump type (`patch`, `minor`, `major`) or explicit semver (e.g., `v1.2.3`). Required.
- **$1+**: summary — one-line release description. Required.

If arguments are missing, ask the user.

## Step 1: Pre-Flight Checks

1. Verify on `main` branch
2. Verify working tree is clean or has only staged/untracked changes intended for this release
3. Detect ecosystem (see Step 2)
4. Determine current version from ecosystem-specific source
5. Calculate new version:
   - If bump type (`patch`/`minor`/`major`): increment the appropriate segment
   - If explicit version (e.g., `v1.2.3`): use directly
6. Confirm version bump direction makes sense (new > current)

## Step 2: Ecosystem Detection

Detect project ecosystem by checking for configuration files. Use the **first match** in priority order:

### Priority 1: Python (hatch-vcs)

**Detection**: `pyproject.toml` exists AND contains `[tool.hatch.version]` with `source = "vcs"`
- **Current version**: `git describe --tags --abbrev=0` (strip `v` prefix)
- **Metadata update**: SKIP — version is derived from git tags at build time

### Priority 2: Python (standard)

**Detection**: `pyproject.toml` exists (not hatch-vcs)
- **Current version**: `[project] version` field in `pyproject.toml`
- **Metadata update**: Update `pyproject.toml` `[project] version` field

### Priority 3: TypeScript

**Detection**: `package.json` exists
- **Current version**: `version` field in `package.json`
- **Metadata update**: Update `package.json` `version` field. Update lock files if needed.

### Priority 4: Rust

**Detection**: `Cargo.toml` exists
- **Current version**: `[package] version` field in `Cargo.toml`
- **Metadata update**: Update `Cargo.toml` `[package] version` field

### Priority 5: SDD Framework repo

**Detection**: `framework/claude/CLAUDE.md` exists (framework source code, not installed instance)
- **Current version**: `VERSION` file contents
- **Metadata update**: Update `VERSION`, `README.md` version references (`--version vX.Y.Z`), `install.sh` version references

### Priority 6: Other

**Detection**: None of the above matched
- **Current version**: `git describe --tags --abbrev=0` (strip `v` prefix), or ask user
- **Metadata update**: Ask user which files contain version references

## Step 3: Documentation Update

Update documentation files that reference the version:

1. **README.md** — search for old version references and update to new version
2. **CHANGELOG.md** — if exists, add release entry (or remind user to update)
3. **SDD Framework repo only**: verify command/agent counts in `framework/claude/CLAUDE.md`:
   - Count `framework/claude/skills/sdd-*/SKILL.md` files → verify `### Commands (N)` matches
   - Count `framework/claude/agents/sdd-*.md` files → verify agent count in README.md matches
   - If counts changed, update the numbers and tables

## Step 4: Metadata Update

Apply ecosystem-specific metadata updates as determined in Step 2.

### Python (hatch-vcs)

No metadata files to update. Version will be set by the git tag in Step 6.

### Python (standard)

Update `pyproject.toml`:
```
[project]
version = "{new_version}"
```

### TypeScript

Update `package.json` `version` field to `{new_version}`.

If `package-lock.json` exists, run `npm install --package-lock-only` to sync the lock file.

### Rust

Update `Cargo.toml`:
```
[package]
version = "{new_version}"
```

### SDD Framework repo

1. Update `VERSION` file with new version (without `v` prefix)
2. Update `README.md` — replace `--version v{old}` with `--version v{new}`
3. Update `install.sh` — replace `--version v{old}` with `--version v{new}` in header comment

### Other

Apply updates as specified by user in Step 2.

## Step 5: Commit on Main

Stage all changed files (documentation + metadata + any pending changes) and commit:
```
{summary} (v{version})
```

## Step 6: Release Branch + Tag

```sh
git checkout -b release/v{version}
git tag v{version}
```

## Step 7: Push Release

```sh
git push origin release/v{version}
git push origin v{version}
```

## Step 8: Return to Main + Push

```sh
git checkout main
git push origin main
```

## Step 9: Report

Output:
- Ecosystem detected
- Version: old → new
- Release branch: `release/v{version}`
- Tag: `v{version}`
- Commit summary
- Files modified

</instructions>

## Error Handling

- **Not on main**: "Switch to main branch first: `git checkout main`"
- **Dirty working tree**: "Uncommitted changes detected. Commit or stash before releasing."
- **Version not incrementing**: "New version ({new}) must be greater than current ({current})"
- **No ecosystem detected**: Falls through to "Other" — asks user for version source
- **Missing arguments**: Ask user for version bump type and summary
