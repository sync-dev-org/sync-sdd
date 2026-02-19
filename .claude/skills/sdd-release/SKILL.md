---
description: Create a versioned release (branch, tag, push)
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, AskUserQuestion
argument-hint: "<version> <summary>"
---

# SDD Release

## Core Task

Create a versioned release of the sync-sdd framework. Automates: version bump → documentation update → commit → release branch → tag → push → return to main → push.

## Input

Arguments: `$ARGUMENTS`
- **$0**: version — semver string (e.g., `v0.15.0`). Required.
- **$1+**: summary — one-line release description. Required.

If arguments are missing, ask the user.

## Step 1: Pre-Flight Checks

1. Verify on `main` branch
2. Verify working tree is clean or has only staged/untracked changes intended for this release
3. Read current `VERSION` file
4. Confirm version bump direction makes sense (new > current)

## Step 2: Version Bump

Update version references in these files:
1. **`VERSION`** — replace contents with new version (without `v` prefix)
2. **`README.md`** — update `--version vX.Y.Z` references
3. **`install.sh`** — update `--version vX.Y.Z` in header comment

## Step 3: Documentation Update

Update `framework/claude/CLAUDE.md`:
- If command count in `### Commands (N)` changed, update the number
- If new commands were added, add to the Commands table

Update `README.md`:
- If command count or command list changed, update the Commands table
- If agent count changed, update the agent definitions count

## Step 4: Commit on Main

Stage all changed files (version files + documentation + any framework changes) and commit:
```
{summary} (v{version})
```

## Step 5: Release Branch + Tag

```sh
git checkout -b release/v{version}
git tag v{version}
```

## Step 6: Push Release

```sh
git push origin release/v{version}
git push origin v{version}
```

## Step 7: Return to Main + Push

```sh
git checkout main
git push origin main
```

## Step 8: Report

Output:
- Version: old → new
- Release branch: `release/v{version}`
- Tag: `v{version}`
- Commit summary
- Files modified
