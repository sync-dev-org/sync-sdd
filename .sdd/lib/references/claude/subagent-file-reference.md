# Claude Code Subagent File Reference

**Last Updated**: 2026-03-10
**Sources**: code.claude.com/docs/en/sub-agents, sync-sdd agent definitions (5 agents), hands-on verification (v2.1.72)

Specification reference for subagent files (`.claude/agents/*.md`). Official name: **"Subagent files"** (公式ドキュメントでの呼称). For the Agent tool (dispatch side) specification, see `agent-tool-reference.md`.

## File Format

Location: `.claude/agents/{filename}.md`

YAML frontmatter + Markdown body. The `name` field in frontmatter becomes the `subagent_type` value used for dispatch. The filename is only used for file discovery — it does NOT determine the `subagent_type`. If `name` differs from the filename, the `name` field takes precedence.

```yaml
---
name: my-agent
description: "What this agent does and when to use it."
model: sonnet
tools: Read, Glob, Grep, Write, Edit, Bash
background: true
---

Markdown body = SubAgent's system prompt.
```

Loaded at session startup. Files added during a session are NOT recognized until session restart or `/agents` reload (verified: test definitions placed during session were absent from available agents list until restart).

## Frontmatter Fields

### Required

Both fields are required — omitting either causes the definition to fail to load (verified: file is silently ignored, not listed in available agents).

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Unique identifier. This value becomes the `subagent_type` for dispatch. Does NOT need to match the filename (verified: `name: different-name-from-filename` in `test-name-mismatch.md` works, dispatched via `subagent_type: "different-name-from-filename"`) |
| `description` | string | Purpose and usage conditions. Claude uses this for auto-delegation decisions. The more detailed, the more appropriately tasks are delegated |

### Model / Execution

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `model` | string | `inherit` | `sonnet`, `opus`, `haiku`, `inherit`. Verified: `haiku` → claude-haiku-4-5-20251001. inherit = same model as parent conversation |
| `background` | boolean | `false` | `true` makes asynchronous execution the default. Verified: Agent tool auto-launches in background without explicit `run_in_background` parameter |
| `maxTurns` | integer | none | Maximum number of agentic turns (tool uses). Verified: `maxTurns: 1` stops after 1 tool use |
| `isolation` | string | none | `worktree` runs on a git worktree copy at `.claude/worktrees/agent-{id}`. Auto-cleanup if no changes |

All fields in this section verified via hands-on testing (v2.1.72). See `agent-tool-reference.md` Model Control section for priority order when both definition and dispatch-time `model` are specified.

### Tools / Permissions

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `tools` | string or list | all (inherits all tools) | Comma-separated string (e.g., `Read, Glob, Grep, Bash`) or YAML array format. Both verified working. Tools not listed are denied to the SubAgent |
| `disallowedTools` | string | none | Denylist. Removes from inherited/specified tools |
| `permissionMode` | string | `default` | See below |

**Agent(type) syntax in tools**: For agents running as the main thread via `claude --agent`, you can restrict spawnable SubAgent types like `tools: Agent(worker, researcher), Read, Bash`. `Agent` alone (without parentheses) allows all types. Excluding `Agent` from tools prevents SubAgent spawning. **This restriction applies only to the main thread** — since SubAgents cannot spawn other SubAgents, `Agent(type)` is ineffective in SubAgent definitions.

**Permission Modes:**

| Mode | Behavior |
|------|----------|
| `default` | Normal approval prompts |
| `acceptEdits` | Auto-approves file edits |
| `dontAsk` | Auto-denies approval prompts (allowed tools still work). Verified working |
| `bypassPermissions` | Skips all checks. **Note: If the parent has bypassPermissions, SubAgent cannot override it** |
| `plan` | Read-only mode |

**AskUserQuestion**: In foreground SubAgents, it is passed through to the parent. In background SubAgents, the call fails (SubAgent continues).

### Advanced

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `skills` | list | none | Skills whose full content is injected into the SubAgent's context at startup. Parent's Skills are not inherited |
| `memory` | string | none | Persistent memory scope (see below) |
| `mcpServers` | string/object | none | Server name (references existing config) or inline definition (name: config) |
| `hooks` | object | none | Lifecycle hooks (see below) |

**Known bug with skills (#27736, OPEN)**: In agent definitions via Plugin, the `skills` field does not appear in the Agent tool's description. The Skill content itself is injected, but it is not displayed in the parent session's Tool UI.

**memory scopes:**

| Scope | Location | Purpose |
|-------|----------|---------|
| `user` | `~/.claude/agent-memory/<name>/` | Cross-project learning (recommended default) |
| `project` | `.claude/agent-memory/<name>/` | Project-specific (shareable via VCS) |
| `local` | `.claude/agent-memory-local/<name>/` | Project-specific (not shareable via VCS) |

When memory is enabled: read/write instructions for the memory directory are added to the system prompt, and the first 200 lines of `MEMORY.md` are injected into the context. **Read, Write, Edit tools are automatically enabled** (even if restricted via tools).

**hooks (in SubAgent definitions):**

Hooks that execute only while the SubAgent is active. Supported events:

| Event | Matcher | Purpose |
|-------|---------|---------|
| `PreToolUse` | Tool name | Validation before tool execution |
| `PostToolUse` | Tool name | Post-execution processing (linting, etc.) |
| `Stop` | (none) | On SubAgent completion. Converted to `SubagentStop` at runtime |

**hooks (in settings.json):**

Project-level hooks that react to SubAgent lifecycle events:

| Event | Matcher | Purpose |
|-------|---------|---------|
| `SubagentStart` | Agent type name | On SubAgent start |
| `SubagentStop` | Agent type name | On SubAgent completion |

## Markdown Body (System Prompt)

The Markdown after the frontmatter becomes the SubAgent's system prompt as-is.

Context received by the SubAgent (per official documentation):
1. This system prompt (Markdown body of the agent definition)
2. Basic environment details (working directory)
3. Full content of Skills specified in the `skills` field
4. `memory`'s MEMORY.md (when enabled)

**Not received:**
- Parent's full Claude Code system prompt (including CLAUDE.md)
- Parent's conversation history

> **Note**: The official documentation states "Subagents receive only this system prompt (plus basic environment details), not the full Claude Code system prompt." CLAUDE.md is loaded for Agent Team Teammates, not SubAgents. While actual behavior may differ, the framework design assumes CLAUDE.md is not inherited.

### Design Guidelines

- **Self-contained**: Since the parent's conversation history cannot be referenced, write assuming all necessary information is received via the prompt
- **Minimize output**: Results should be concise. Write large outputs to files and return `WRITTEN:{path}`
- **Align with tool constraints**: Do not instruct use of tools beyond those restricted in the `tools` field

## Discovery Paths (Priority Order)

| Location | Scope | Priority |
|----------|-------|----------|
| `--agents` CLI flag (JSON) | Session-only | 1 (highest) |
| `.claude/agents/` | Project-level (VCS-managed) | 2 |
| `~/.claude/agents/` | User-level (shared across all projects) | 3 |
| Plugin's `agents/` directory | Plugin scope | 4 (lowest) |

When multiple definitions share the same name, the higher priority definition wins. Use the `/agents` command to check override status. Use `claude agents` to list from CLI.

## Relationship with Agent Tool

| Item | Agent Definition File | Agent Tool Parameter |
|------|-------------------|---------------------|
| model | `model: sonnet` (at definition time) | `model: "sonnet"` (at dispatch time) |
| Priority | Agent tool side takes precedence | — |
| tools | Fixed at definition time | Cannot be overridden |
| prompt | system prompt (always applied) | task prompt (varies per invocation) |

When specifying a definition with `subagent_type` at dispatch time, the definition's system prompt and the Agent tool's task prompt are combined.

## Disabling Specific SubAgents

Specific SubAgents (including built-in ones) can be disabled via `permissions.deny` in `settings.json`:

```json
{
  "permissions": {
    "deny": ["Agent(Explore)", "Agent(my-custom-agent)"]
  }
}
```

CLI: `claude --disallowedTools "Agent(Explore)"`

## sync-sdd Agent Definition List

| Name | Model | Tools | Tier | Purpose |
|------|-------|-------|------|---------|
| `sdd-analyst` | opus | Read, Glob, Grep, Write, Edit, WebSearch, WebFetch | T2 | Zero-based redesign |
| `sdd-architect` | opus | Read, Glob, Grep, Write, Edit, WebSearch, WebFetch | T2 | Design generation |
| `sdd-builder` | sonnet | Read, Glob, Grep, Write, Edit, Bash | T3 | TDD implementation |
| `sdd-taskgenerator` | sonnet | Read, Glob, Grep, Write | T3 | Task decomposition |
| `sdd-conventions-scanner` | sonnet | Read, Glob, Grep, Write | T3 | Codebase pattern scanning |

## Hands-on Verification Summary (v2.1.72)

| Test | Definition | Result |
|------|-----------|--------|
| name omitted | `test-no-name.md` | **Load failure** — silently ignored, not in available agents |
| description omitted | `test-no-desc.md` | **Load failure** — silently ignored, not in available agents |
| name + description only | `test-minimal.md` | **Success** — all other fields optional |
| name ≠ filename | `test-name-mismatch.md` (name: `different-name-from-filename`) | **name field is subagent_type**, not filename |
| `model: haiku` | `test-full.md` | **claude-haiku-4-5-20251001** |
| `tools: Read, Glob, Grep` (CSV) | `test-full.md` | **Write denied** — tools restriction works |
| `tools:` YAML array | `test-tools-array.md` | **Write denied** — array format also works |
| `background: true` | `test-full.md` | **Auto background launch** without explicit `run_in_background` |
| `isolation: worktree` | `test-full.md` | **CWD = `.claude/worktrees/agent-{id}`** |
| `maxTurns: 1` | `test-maxturns.md` | **Stopped after 1 tool use** |
| `permissionMode: dontAsk` | `test-full.md` | **Working** — unapproved tools auto-denied |
| Session reload required | All test-* files | **Confirmed** — files added mid-session not recognized until restart |
