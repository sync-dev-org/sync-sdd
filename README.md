# sync-sdd

Spec-Driven Development framework for [Claude Code](https://docs.anthropic.com/en/docs/claude-code).

AI-DLC (AI Development Life Cycle) with 3-tier SubAgent architecture, phase-gated workflow, and specification traceability.

## Install

```sh
curl -LsSf https://raw.githubusercontent.com/sync-dev-org/sync-sdd/main/install.sh | sh
```

Run from your project root. Requires `curl` and `tar`.

### Options

```sh
# Update framework files (preserves your steering/specs/knowledge)
curl -LsSf <url>/install.sh | sh -s -- --update

# Install specific version
curl -LsSf <url>/install.sh | sh -s -- --version v0.22.0

# Force overwrite existing files
curl -LsSf <url>/install.sh | sh -s -- --force

# Remove framework files
curl -LsSf <url>/install.sh | sh -s -- --uninstall
```

## What gets installed

```
your-project/
└── .claude/
    ├── CLAUDE.md                      # Framework instructions (auto-loaded)
    ├── settings.json                  # Default settings
    ├── skills/sdd-*/SKILL.md          # 9 skills
    ├── agents/sdd-*.md               # 23 SubAgent definitions (YAML frontmatter)
    └── sdd/
        └── settings/                  # Framework-managed
            ├── rules/
            ├── templates/
            └── profiles/
```

Your project files (created through the workflow) are never touched by `--update`:

```
.claude/sdd/project/steering/      # Project context and decisions
.claude/sdd/project/specs/         # Feature specifications
.claude/sdd/project/knowledge/     # Reusable learnings
.claude/sdd/handover/              # Session continuity (auto-persisted)
```

Reset all project files: `rm -rf .claude/sdd/project`

## Architecture

```
Tier 1: Command  ─── Lead ─────────────────────── (Lead, Opus)
Tier 2: Brain    ─── Architect / Auditor ────────── (SubAgent, Opus)
Tier 3: Execute  ─── TaskGenerator / Builder / Inspector ─── (SubAgent ×N, Sonnet)
```

Lead handles user interaction, phase gates, dispatch planning, and SubAgent orchestration. All work is delegated via `Task(subagent_type=...)` to agents defined in `.claude/agents/`.

## Quick start

```sh
cd your-project
claude                          # Start Claude Code

# Stage 0: Set up project context (optional)
/sdd-steering

# Stage 1: Specification
/sdd-roadmap design "your feature description"
/sdd-roadmap review design feature-name    # Optional: design review

# Stage 2: Implementation
/sdd-roadmap impl feature-name             # Task generation + TDD implementation
/sdd-roadmap review impl feature-name      # Optional: implementation review

# Multi-feature roadmap
/sdd-roadmap create                        # Plan multiple features in waves
/sdd-roadmap run                           # Execute all features

# Anytime
/sdd-status feature-name
```

## Workflow

```
steering → design → review → implement → review
              ↑                              |
              └── SPEC_FEEDBACK (if needed) ─┘
```

**Phase gates** enforce order: you can't implement without a design.

**Version tracking** prevents stale implementations: if a spec changes, tasks and implementation are re-validated.

**Auto-fix loop**: NO-GO reviews trigger automatic spec/impl fixes (max 3 retries) before escalating to user.

## Commands

| Command | Description |
|---------|-------------|
| `/sdd-steering` | Set up project context (create/update/delete/custom) |
| `/sdd-roadmap` | Unified spec lifecycle: design, impl, review, run, revise, create, update, delete |
| `/sdd-roadmap design` | Generate or edit a technical design |
| `/sdd-roadmap impl` | Task generation + TDD implementation |
| `/sdd-roadmap review` | Multi-agent review (design/impl/dead-code) |
| `/sdd-status` | Check progress + impact analysis |
| `/sdd-handover` | Generate session handover document |
| `/sdd-knowledge` | Manage reusable knowledge entries |
| `/sdd-release` | Create a versioned release (branch, tag, push) |
