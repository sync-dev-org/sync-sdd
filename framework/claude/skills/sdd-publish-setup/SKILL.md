---
name: sdd-publish-setup
description: Set up CI/CD publish pipeline (GitHub Actions + Trusted Publisher)
allowed-tools: Bash, Read, Write, Edit, Glob, Grep
---

# SDD Publish Setup

<instructions>

## Core Task

Set up a CI/CD publish pipeline for the project. Creates a GitHub Actions workflow that automatically publishes to a package registry when a version tag is pushed. Designed to complement `/sdd-release` (which creates tags) by adding the automated publish step.

This is a **one-time setup** command per project. If the workflow already exists, offer to regenerate or skip.

## Step 1: Pre-Flight Checks

1. Check if `.github/workflows/publish.yml` already exists
   - If exists: ask user whether to overwrite or abort
2. Verify a GitHub remote is configured: `git remote get-url origin`
   - If no remote: "No GitHub remote found. Set one up first: `git remote add origin <url>`" → abort
3. Extract GitHub owner and repo name from the remote URL
   - HTTPS: `https://github.com/{owner}/{repo}.git` → extract owner, repo
   - SSH: `git@github.com:{owner}/{repo}.git` → extract owner, repo
   - Strip `.git` suffix if present

## Step 2: Ecosystem Detection

Detect the project ecosystem by checking configuration files. Use the **first match** in priority order:

### Priority 1: Python (hatch-vcs)

**Detection**: `pyproject.toml` exists AND contains `[tool.hatch.version]` with `source = "vcs"`
- **Registry**: PyPI (pypi.org)
- **Auth**: OIDC Trusted Publisher (no API token needed)
- **Build tool**: `build` package (`uv run python -m build`)

### Priority 2: Python (standard)

**Detection**: `pyproject.toml` exists (not hatch-vcs)
- **Registry**: PyPI (pypi.org)
- **Auth**: OIDC Trusted Publisher
- **Build tool**: `build` package

### Priority 3: TypeScript

**Detection**: `package.json` exists
- **Registry**: npm (npmjs.com)
- **Auth**: npm provenance (OIDC)
- **Build tool**: npm

### Priority 4: Rust

**Detection**: `Cargo.toml` exists
- **Registry**: crates.io
- **Auth**: API token via GitHub Secrets
- **Build tool**: cargo

### Priority 5: Other

**Detection**: None of the above matched
- Ask the user what registry and build process to use → abort with guidance

Report the detected ecosystem to the user and confirm before proceeding.

## Step 3: Workflow Generation

Create `.github/workflows/publish.yml` based on the detected ecosystem.

### Python (hatch-vcs / standard)

Detect the following from the project:
- **Package manager**: check if `uv.lock` exists → `uv`, otherwise check for `poetry.lock` → `poetry`, fallback to `pip`
- **Lint command**: check if `ruff` is in dev dependencies → `uv run ruff check src/ tests/`, otherwise skip lint step
- **Test command**: check if `pytest` is in dev dependencies → `uv run pytest`, otherwise skip test step
- **src layout**: check if `src/` directory exists (affects build behavior)

Generate the workflow:

```yaml
name: Publish to PyPI

on:
  push:
    tags:
      - "v*"

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - uses: astral-sh/setup-uv@v4
      - run: uv sync
      # lint step (if ruff detected)
      - run: uv run ruff check src/ tests/
      # test step (if pytest detected)
      - run: uv run pytest
      - run: uv run python -m build
      - uses: actions/upload-artifact@v4
        with:
          name: dist
          path: dist/

  publish:
    needs: build
    runs-on: ubuntu-latest
    environment: pypi
    permissions:
      id-token: write
    steps:
      - uses: actions/download-artifact@v4
        with:
          name: dist
          path: dist/
      - uses: pypa/gh-action-pypi-publish@release/v1
```

Adjust the workflow based on detection:
- If package manager is `pip` instead of `uv`: replace `astral-sh/setup-uv` with `actions/setup-python`, replace `uv sync` with `pip install .`, replace `uv run` with direct commands
- If package manager is `poetry`: use `snok/install-poetry`, replace accordingly
- If no ruff: remove the ruff step
- If no pytest: remove the pytest step
- If hatch-vcs: `fetch-depth: 0` is critical (keep it). If standard: `fetch-depth: 0` is harmless (keep it)

### TypeScript

```yaml
name: Publish to npm

on:
  push:
    tags:
      - "v*"

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: "lts/*"
          registry-url: "https://registry.npmjs.org"
      - run: npm ci
      - run: npm test
      - run: npm run build --if-present

  publish:
    needs: build
    runs-on: ubuntu-latest
    permissions:
      contents: read
      id-token: write
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: "lts/*"
          registry-url: "https://registry.npmjs.org"
      - run: npm ci
      - run: npm publish --provenance --access public
        env:
          NODE_AUTH_TOKEN: ${{ secrets.NPM_TOKEN }}
```

### Rust

```yaml
name: Publish to crates.io

on:
  push:
    tags:
      - "v*"

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: dtolnay/rust-toolchain@stable
      - run: cargo test
      - run: cargo build --release

  publish:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: dtolnay/rust-toolchain@stable
      - run: cargo publish
        env:
          CARGO_REGISTRY_TOKEN: ${{ secrets.CARGO_REGISTRY_TOKEN }}
```

## Step 4: Dev Dependencies Update

Check if the build tool is available in dev dependencies and add it if missing.

### Python

Check if `build` is in `[dependency-groups] dev` (pyproject.toml).
- If missing: add `"build"` to the dev dependency list using Edit tool
- Run `uv sync` to install

### TypeScript

No additional dev dependencies needed (npm handles publishing natively).

### Rust

No additional dev dependencies needed (cargo handles publishing natively).

## Step 5: Registry Setup Guide

Display the manual steps the user needs to perform in their browser. These cannot be automated.

### PyPI (Python projects)

Output the following:

```
## PyPI Trusted Publisher Setup

Complete these steps in your browser:

### 1. PyPI — Pending Publisher Registration
   URL: https://pypi.org/manage/account/publishing/

   Enter the following values:
   - PyPI project name: {project_name}
   - Owner: {github_owner}
   - Repository name: {github_repo}
   - Workflow name: publish.yml
   - Environment name: pypi

### 2. GitHub — Environment Creation
   URL: https://github.com/{github_owner}/{github_repo}/settings/environments

   - Click "New environment"
   - Name: pypi
   - (Optional) Add "Required reviewers" for publish approval gate
```

Where `{project_name}` is from `pyproject.toml [project] name`, `{github_owner}` and `{github_repo}` are from Step 1.

### npm (TypeScript projects)

Output the following:

```
## npm Publish Setup

### 1. npm — Access Token
   URL: https://www.npmjs.com/settings/~/tokens

   - Create a new "Automation" token
   - Copy the token value

### 2. GitHub — Repository Secret
   URL: https://github.com/{github_owner}/{github_repo}/settings/secrets/actions

   - Click "New repository secret"
   - Name: NPM_TOKEN
   - Value: (paste the npm token)
```

### crates.io (Rust projects)

Output the following:

```
## crates.io Publish Setup

### 1. crates.io — API Token
   URL: https://crates.io/settings/tokens

   - Create a new token with "publish-update" scope
   - Copy the token value

### 2. GitHub — Repository Secret
   URL: https://github.com/{github_owner}/{github_repo}/settings/secrets/actions

   - Click "New repository secret"
   - Name: CARGO_REGISTRY_TOKEN
   - Value: (paste the crates.io token)
```

## Step 6: Verification Guide

Output verification steps:

```
## Verification

After completing the registry setup above:

1. Commit and push the workflow file:
   git add .github/workflows/publish.yml
   git commit -m "ci: add publish workflow"
   git push origin main

2. Create a test release to verify the pipeline:
   /sdd-release patch "test publish pipeline"

3. Check GitHub Actions:
   https://github.com/{github_owner}/{github_repo}/actions

4. Check the package registry for the published version.

If the publish fails, check the Actions log for error details.
Common issues:
- PyPI: Trusted Publisher not configured → check environment name matches "pypi"
- npm: NPM_TOKEN secret not set → check repository secrets
- crates.io: CARGO_REGISTRY_TOKEN not set → check repository secrets
```

## Step 7: Summary Report

Output:
- Ecosystem detected
- Workflow file created: `.github/workflows/publish.yml`
- Dev dependencies updated (if any)
- Registry: {registry name}
- Auth method: {OIDC / API token}
- Trigger: push tag `v*`
- Pipeline: lint → test → build → publish
- Manual steps remaining: {count} (registry setup)

</instructions>

## Error Handling

- **Workflow already exists**: Ask user — overwrite or abort
- **No GitHub remote**: "No GitHub remote configured. Run `git remote add origin <url>` first."
- **Ecosystem not detected**: "Could not detect project ecosystem. Ensure pyproject.toml, package.json, or Cargo.toml exists."
- **Build dependency add fails**: Warn but continue — user can add manually
- **Directory creation fails**: "Could not create .github/workflows/ directory. Check file system permissions."
