# sync-sdd

Spec-Driven Development framework for [Claude Code](https://docs.anthropic.com/en/docs/claude-code).

Your AI development team — 26 specialized SubAgents orchestrated by a Lead, turning natural language into production code through spec-driven pipelines with multi-agent review.

## Why sync-sdd

**The problem**: AI coding assistants are powerful but chaotic. Without structure, you get inconsistent quality, no traceability, and designs that drift from intent.

**The solution**: sync-sdd brings software engineering discipline to AI-assisted development. Every feature flows through a spec-driven pipeline — design, review, implement, review — with phase gates that prevent skipping steps and multi-agent reviews that catch what a single perspective misses.

### Key capabilities

- **26 SubAgents, 3 tiers** — Analyst redesigns from zero, Architect designs features, Builders implement with TDD, 6+ Inspectors review from different angles, Auditor synthesizes the verdict. Each agent has a focused specialty.
- **Aggressive parallelism** — Specs within a wave execute at different phases simultaneously. Design Fan-Out dispatches multiple Architects in parallel. Design Lookahead starts the next wave's design before the current wave finishes. Island specs bypass wave boundaries entirely.
- **Foundation-First scheduling** — Models, shared libraries, and error handling are automatically prioritized to Wave 1. Dependency-aware topological sorting minimizes wave count and maximizes parallel throughput.
- **Self-correcting reviews** — NO-GO verdicts trigger automatic fix loops (up to 5 retries). SPEC-UPDATE-NEEDED cascades back through the full pipeline. Dead-code review catches orphaned artifacts. Consensus mode runs multiple independent review pipelines for high-confidence findings.
- **Specification traceability** — Every implementation traces back to a design. Phase gates enforce order. Version tracking detects stale implementations. SPEC-Code atomicity keeps design and code in sync.
- **Cross-session continuity** — Session handover and decision logs persist across conversations. Resume any interrupted pipeline from exactly where it stopped.

## Install

```sh
curl -LsSf https://raw.githubusercontent.com/sync-dev-org/sync-sdd/main/install.sh | sh
```

Run from your project root. Requires `curl` and `tar`.

### Options

```sh
# Update framework files (preserves your steering/specs)
curl -LsSf <url>/install.sh | sh -s -- --update

# Install specific version
curl -LsSf <url>/install.sh | sh -s -- --version v1.5.2

# Force overwrite existing files
curl -LsSf <url>/install.sh | sh -s -- --force

# Remove framework files
curl -LsSf <url>/install.sh | sh -s -- --uninstall
```

## What gets installed

```
your-project/
├── .claude/
│   ├── CLAUDE.md                      # Framework instructions (auto-loaded)
│   ├── settings.json                  # Default settings
│   ├── skills/sdd-*/SKILL.md          # 7 skills
│   └── agents/sdd-*.md               # 26 SubAgent definitions
└── .sdd/
    └── settings/                      # Rules, templates, profiles
```

Your project files are never touched by `--update`:

```
.sdd/project/steering/             # Project context and decisions
.sdd/project/specs/                # Feature specifications
.sdd/handover/                     # Session continuity
```

## Architecture

```
Tier 1: Command  ─── Lead ─────────────────────────── (Opus)
Tier 2: Brain    ─── Analyst / Architect / Auditor ─────── (Opus)
Tier 3: Execute  ─── TaskGenerator / Builder / Inspector (Sonnet x N)
```

**Lead** orchestrates everything — user interaction, phase gates, dispatch planning, SubAgent coordination, and state management.

**Analyst** performs holistic project analysis for zero-based redesign. **Architect** generates technical designs with research and discovery. **Auditor** synthesizes multi-Inspector findings into GO / CONDITIONAL / NO-GO / SPEC-UPDATE-NEEDED verdicts.

**TaskGenerator** decomposes designs into parallelizable tasks. **Builder** implements via TDD (RED-GREEN-REFACTOR). **Inspector** provides focused review perspectives — 6 for design, 6+2 for implementation (web projects), 4 for dead-code.

## Parallel execution model

sync-sdd maximizes throughput at every level:

```
Wave 1 ──────────────────────────────────────────────────
  spec-a: [Design] → [Design Review] → [Impl ████████] → [Impl Review]
  spec-b:    [Design] → [Design Review ██] → [Impl ██████████] → ...
  spec-c:       [Design █████] → [Design Review] → [Impl ██████] → ...
  island-x: [Design] → [Review] → [Impl] → [Review] → commit ✓
                                     ↓ (Lookahead)
Wave 2 ──────────────────────────────────────────────────
  spec-d:          [Design ███████] → [Design Review ███] → (wait for W1 QG) → [Impl] → ...
```

| Strategy | What it does |
|----------|-------------|
| **Design Fan-Out** | Independent specs get their Architects dispatched simultaneously |
| **Spec Stagger** | Specs within a wave overlap phases — one in Impl while another in Design Review |
| **Design Lookahead** | Next-wave design starts as soon as dependencies are designed, before current wave implements |
| **Wave Bypass** | Fully independent specs run their own pipeline, skip wave boundaries |
| **Foundation-First** | Models, shared libs, error handling auto-prioritized to Wave 1 |

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
/sdd-roadmap impl feature-name             # Task generation + TDD
/sdd-roadmap review impl feature-name      # Optional: implementation review

# Multi-feature roadmap
/sdd-roadmap create                        # Plan features in waves
/sdd-roadmap run                           # Execute all — parallel by default
```

## Workflow

```
steering → design → review → implement → review
              ↑                              |
              └── SPEC_FEEDBACK (if needed) ─┘
```

**Phase gates** enforce order: you can't implement without a design. Version tracking prevents stale implementations.

**Auto-fix loop**: NO-GO reviews trigger automatic fixes (max 5 retries, dead-code max 3). SPEC-UPDATE-NEEDED cascades through the full pipeline — Architect re-designs, TaskGenerator re-plans, Builder re-implements.

**Multi-agent review**: 6+ Inspectors examine the work from different angles (architecture, consistency, testability, quality, best practices, holistic). An Auditor synthesizes findings into a single verdict. Consensus mode (`--consensus N`) runs N independent pipelines and filters noise through frequency thresholds.

**Knowledge accumulation**: Builders report patterns, incidents, and references via tagged completion reports. Lead collects them into a handover buffer that persists across sessions.

## Commands

| Command | Description |
|---------|-------------|
| `/sdd-steering` | Set up project context (create/update/delete/custom) |
| `/sdd-roadmap` | Unified spec lifecycle: design, impl, review, run, revise, create, update, delete |
| `/sdd-status` | Check progress + impact analysis |
| `/sdd-handover` | Generate session handover document |
| `/sdd-release` | Create a versioned release (branch, tag, push) |
| `/sdd-review-self` | Self-review for framework development |

## License

MIT
