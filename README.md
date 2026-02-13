# sync-sdd

Spec-Driven Development framework for [Claude Code](https://docs.anthropic.com/en/docs/claude-code).

AI-DLC (AI Development Life Cycle) with phase-gated workflow, multi-agent review, and specification traceability.

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
curl -LsSf <url>/install.sh | sh -s -- --version v0.3.0

# Force overwrite existing files
curl -LsSf <url>/install.sh | sh -s -- --force

# Remove framework files
curl -LsSf <url>/install.sh | sh -s -- --uninstall
```

## What gets installed

```
your-project/
├── .claude/
│   ├── CLAUDE.md              # Framework instructions (auto-loaded by Claude Code)
│   ├── settings.json          # Default settings
│   ├── commands/sdd-*.md      # 21 slash commands
│   └── agents/sdd-*.md        # 13 review agents
└── .kiro/
    └── settings/
        ├── rules/             # Development rules
        └── templates/         # Spec/steering/knowledge templates
```

Your project files (created by you through the workflow) are never touched by `--update`:

```
.kiro/steering/      # Project context and decisions
.kiro/specs/         # Feature specifications
.kiro/knowledge/     # Reusable learnings
.claude/handover.md  # Session continuity
```

## Quick start

```sh
cd your-project
claude                          # Start Claude Code

# Stage 0: Set up project context (optional)
/sdd-steering

# Stage 1: Specification
/sdd-design "your feature description"
/sdd-review-design feature-name     # Optional: design review
/sdd-tasks feature-name

# Stage 2: Implementation
/sdd-impl feature-name
/sdd-review-impl feature-name       # Optional: implementation review

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

## Commands

| Command | Description |
|---------|-------------|
| `/sdd-steering` | Set up project-wide context (product, tech, structure) |
| `/sdd-steering-custom` | Add domain-specific steering (auth, API, DB, etc.) |
| `/sdd-design` | Generate or edit a technical design from description |
| `/sdd-review-design` | Multi-agent design quality review |
| `/sdd-tasks` | Generate implementation tasks from design |
| `/sdd-impl` | TDD implementation of tasks |
| `/sdd-review-impl` | Multi-agent implementation review |
| `/sdd-review-dead-code` | Detect unused code |
| `/sdd-status` | Check progress of a feature |
| `/sdd-analyze-gap` | Gap analysis for existing codebase |
| `/sdd-impact-analysis` | Analyze downstream impact of spec changes |
| `/sdd-knowledge` | Manage reusable knowledge entries |
| `/sdd-roadmap` | Multi-feature roadmap planning and execution |
| `/sdd-handover` | Generate session handover document |

## License

MIT
