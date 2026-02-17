# sync-sdd

Spec-Driven Development framework for [Claude Code](https://docs.anthropic.com/en/docs/claude-code).

AI-DLC (AI Development Life Cycle) with 3-tier Agent Team architecture, phase-gated workflow, and specification traceability.

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
curl -LsSf <url>/install.sh | sh -s -- --version v0.5.0

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
    ├── commands/sdd-*.md              # 9 slash commands
    ├── agents/sdd-*.md                # 20 agent definitions
    └── sdd/
        └── settings/                  # Framework-managed
            ├── rules/
            └── templates/
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
Tier 1: Command  ─── Lead ─────────────────────── (Conductor, Opus)
Tier 2: Brain    ─── Architect / Planner / Auditor ── (Teammate, Opus)
Tier 3: Execute  ─── Builder / Inspector ─── (Teammate ×N, Sonnet)
```

Lead handles user interaction, phase gates, spawn planning, and teammate lifecycle management. All work is delegated through the Agent Team hierarchy.

## Quick start

```sh
cd your-project
claude                          # Start Claude Code

# Stage 0: Set up project context (optional)
/sdd-steering

# Stage 1: Specification
/sdd-design "your feature description"
/sdd-review design feature-name    # Optional: design review
/sdd-tasks feature-name

# Stage 2: Implementation
/sdd-impl feature-name
/sdd-review impl feature-name     # Optional: implementation review

# Anytime
/sdd-status feature-name
```

## Workflow

```
steering → design → review → tasks → implement → review
              ↑                                      |
              └──── SPEC_FEEDBACK (if needed) ───────┘
```

**Phase gates** enforce order: you can't generate tasks without a design, can't implement without tasks.

**Version tracking** prevents stale implementations: if a spec changes, tasks and implementation are re-validated.

**Auto-fix loop**: NO-GO reviews trigger automatic spec/impl fixes (max 3 retries) before escalating to user.

## Commands

| Command | Description |
|---------|-------------|
| `/sdd-steering` | Set up project context (create/update/delete/custom) |
| `/sdd-design` | Generate or edit a technical design |
| `/sdd-review` | Multi-agent review (design/impl/dead-code) |
| `/sdd-tasks` | Generate implementation tasks from design |
| `/sdd-impl` | TDD implementation of tasks |
| `/sdd-roadmap` | Multi-feature roadmap (create/run/update/delete) |
| `/sdd-status` | Check progress + impact analysis |
| `/sdd-handover` | Generate session handover document |
| `/sdd-knowledge` | Manage reusable knowledge entries |

## License

MIT
