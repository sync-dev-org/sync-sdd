# Claude Code Agent Tool Reference

**Last Updated**: 2026-03-10
**Sources**: code.claude.com/docs/en/sub-agents, code.claude.com/docs/en/model-config, GitHub anthropics/claude-code

Specification reference for spawning SubAgents via the Claude Code Agent tool. For the specification of agent definition files in `.claude/agents/`, see `subagent-file-reference.md`.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `description` | string | Yes | Short task description, 3-5 words |
| `prompt` | string | Yes | Instructions for the SubAgent. The SubAgent receives only this as its task prompt |
| `subagent_type` | string | No | Agent type. Built-in or custom definition name from `.claude/agents/` |
| `run_in_background` | boolean | No | `true` for async execution. Completion is auto-notified via `task-notification` |
| `isolation` | enum | No | `"worktree"` only. Execute on a copy in a git worktree |
| `model` | enum | No | Model alias for the SubAgent. Enum: `sonnet`, `opus`, `haiku` only. Extended aliases like `sonnet[1m]` are not accepted. Restored in v2.1.72 |
| `resume` | string | No | Specify a previous Agent ID to continue the conversation |

**Note on `model` parameter**: Was removed from the tool schema in v2.1.69 (#31311 regression) and restored in v2.1.72. Verified working with short aliases: `sonnet` → claude-sonnet-4-6, `haiku` → claude-haiku-4-5, `opus` → claude-opus-4-6. Takes precedence over agent definition frontmatter when specified.

## Built-in Agent Types

| Type | Model | Tools | Use Case |
|------|-------|-------|----------|
| `general-purpose` | inherit | All | General-purpose task delegation. Default when omitted |
| `Explore` | haiku | Read-only (Write/Edit denied) | Fast codebase exploration. thoroughness level: quick/medium/very thorough |
| `Plan` | inherit | Read-only (Write/Edit denied) | Codebase investigation in plan mode |
| `statusline-setup` | sonnet | (internal) | Status line setup via `/statusline` |
| `claude-code-guide` | haiku | (internal) | Q&A about Claude Code features |

`Bash` is not listed as a valid `subagent_type` (verified via error message listing available agents). It may be an internal mechanism not exposed through the Agent tool.

When `subagent_type` is omitted, `general-purpose` is used.

## Model Control

### Model Aliases

| Alias | Resolves To | Use Case |
|-------|-------------|----------|
| `sonnet` | claude-sonnet-4-6 (latest Sonnet) | Everyday coding |
| `opus` | claude-opus-4-6 (latest Opus) | Complex reasoning |
| `haiku` | claude-haiku-4-5 | Fast, low-cost |
| `default` | Depends on account type (Max/Team Premium=Opus, Pro/Team Standard=Sonnet) | -- |
| `sonnet[1m]` | Sonnet + 1M token context | Long sessions |
| `opusplan` | plan mode=Opus, execution=Sonnet | Hybrid |
| `inherit` | Same model as parent conversation | Default when model is omitted |

Aliases always resolve to the latest version. To pin to a specific version, use the full model name (e.g., `claude-opus-4-6`) or override via environment variables.

**Agent tool `model` parameter restriction**: The dispatch-time `model` parameter accepts only `sonnet`, `opus`, `haiku` (enum). Extended aliases like `sonnet[1m]`, `opusplan`, and full model IDs are not accepted. For extended aliases, use agent definition frontmatter or environment variables.

### Environment Variables

| Variable | Use Case |
|----------|----------|
| `ANTHROPIC_DEFAULT_OPUS_MODEL` | Override the resolution target of the `opus` alias |
| `ANTHROPIC_DEFAULT_SONNET_MODEL` | Override the resolution target of the `sonnet` alias |
| `ANTHROPIC_DEFAULT_HAIKU_MODEL` | Override the resolution target of the `haiku` alias |
| `CLAUDE_CODE_SUBAGENT_MODEL` | Set the model for all SubAgents at once |

In sync-sdd, model specification via environment variables is not used.

### Specifying at Dispatch Time

**Available since v2.1.72.** Use the `model` parameter with short aliases (`sonnet`, `opus`, `haiku`). Verified working: `model: sonnet` → claude-sonnet-4-6, `model: haiku` → claude-haiku-4-5. Was broken in v2.1.69-v2.1.71 (#31311 regression).

### Priority Order (Verified v2.1.72)

| Priority | Method | Status |
|----------|--------|--------|
| 1 (Highest) | `model` parameter at dispatch time | **Working (v2.1.72+).** Verified: `model: sonnet` → claude-sonnet-4-6, `model: haiku` → claude-haiku-4-5 |
| 2 | `model` field in `.claude/agents/` definition | **Working.** Verified: sdd-builder (`model: sonnet`) dispatches to claude-sonnet-4-6 |
| 3 | `CLAUDE_CODE_SUBAGENT_MODEL` environment variable | Documented. Not verified in this environment |
| 4 (Default) | inherit | **Working.** general-purpose inherits parent model (Opus) |

### Known Issues

- **#31311** (OPEN, fixed in v2.1.72): Agent tool `model` parameter silently ignored in v2.1.69-v2.1.71. Parameter restored to tool schema in v2.1.72. Issue not yet closed on GitHub
- **#31027** (OPEN, fixed in v2.1.72): Agent tool schema missing `model` parameter. Regression was a refactor oversight. Issue not yet closed on GitHub
- **#18873** (OPEN, fixed in v2.1.72): `model` parameter returns 404 for short names, validation error for full IDs. Fixed with short alias support (sonnet/opus/haiku). Issue not yet closed on GitHub
- **#5456** (CLOSED, DUPLICATE of #3903): Agent definition's model is ignored, falling back to Sonnet. Reported as of v1.0.72
- **#3903** (CLOSED, NOT_PLANNED): `--model` CLI flag is not inherited by sub-tasks. Reported as of v1.0.53
- **#27736** (OPEN): Bug where the `skills` field from agent definitions is not displayed in the Agent tool description
- **#32340** (OPEN): Feature request for dynamic skill invocation from SubAgents + nested spawning (under duplicate review)

Model control is available via both the `model` parameter at dispatch time and the `model` field in agent definition frontmatter. Both methods work reliably as of v2.1.72.

## Context and Communication

- SubAgents start in a **new context window** -- they do not inherit the parent's conversation history
- **Official documentation**: "Subagents receive only this system prompt (plus basic environment details like working directory), not the full Claude Code system prompt." -- CLAUDE.md is part of the "full Claude Code system prompt" and is **stated to not be passed to SubAgents**
- **Note**: Agent Team Teammates do load CLAUDE.md, but this is different from SubAgents (Agent tool). "CLAUDE.md works normally" is a statement about Teammates
- **Possible divergence from actual behavior**: Research reports suggest "CLAUDE.md is also loaded by SubAgents." Official documentation and actual behavior may differ. The framework design assumes CLAUDE.md is NOT inherited, and passes required context explicitly via the prompt
- Skills specified via the `skills` field have their full text injected (parent Skills are not inherited)
- All task context is passed via the `prompt` parameter
- Communication is one-directional: parent -> SubAgent (prompt), SubAgent -> parent (return value)
- For large outputs, SubAgents write to files and return `WRITTEN:{path}`

## Background Execution

- `run_in_background: true` for async execution
- **Before launch**, Claude Code displays a tool permission pre-approval prompt. After launch, the SubAgent operates only with pre-approved permissions; unapproved operations are automatically denied
- Completion is auto-notified via `task-notification` -- **do not poll with TaskOutput** (#14055 Race Condition)
- If a background SubAgent fails due to insufficient permissions, it can be resumed in the foreground with `resume` to retry via interactive prompts
- AskUserQuestion calls fail, but the SubAgent continues
- `CLAUDE_CODE_DISABLE_BACKGROUND_TASKS=1` can disable the entire background feature
- Ctrl+B can move a running foreground task to the background

## Resume and Transcript

- Use the `resume` parameter with a previous Agent ID to continue the conversation
- On resume, the full conversation history is retained (including tool calls, results, and reasoning)
- Transcript: `~/.claude/projects/{project}/{sessionId}/subagents/agent-{agentId}.jsonl`
- Parent conversation compaction does not affect SubAgent transcripts (separate files)
- `cleanupPeriodDays` (default: 30) for automatic cleanup

## Auto-Compaction

SubAgents support the same auto-compaction as parent conversations. Triggers at approximately 95% capacity. The threshold can be changed with `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE`.

## Limitations

| Limitation | Details |
|------------|---------|
| **Context Isolation** | No parent conversation history. Official: only system prompt + environment info + prompt (CLAUDE.md is stated to not be included) |
| **No Nesting** | SubAgents cannot spawn other SubAgents. Writing `Agent(type)` in tools has no effect in SubAgent definitions |
| **No Tool Override** | Tool lists cannot be changed at dispatch time. Controlled via tools/disallowedTools in agent definitions |
| **AskUserQuestion** | Foreground: passed through to parent. Background: call fails (SubAgent continues) |
| **No Skills Inheritance** | Parent Skills are not inherited. Must be explicitly specified via the `skills` field in agent definitions |
| **No Shared Memory** | Memory is not shared between invocations (except via resume). Persistence is possible via the `memory` field |

## Agent Tool vs Agent Team

| Aspect | Agent Tool (SubAgent) | Agent Team |
|--------|----------------------|------------|
| Platform | Claude Code CLI | Claude Code CLI (experimental, disabled by default) |
| Session | Child context within parent session | Fully independent Claude Code instance |
| Communication | One-directional (prompt -> result) | Bidirectional (message, broadcast) + Shared Task List |
| Parallelism | Multiple SubAgents within 1 session | Multiple independent sessions |
| Nesting | Not supported | Not supported (Teammates cannot create sub-teams) |
| Token Cost | Low (returned as summarized result) | High (approx. 7x in plan mode, generally "significantly more") |
| Usage in sync-sdd | Yes (the only method) | No |

Agent Team is an experimental feature of Claude Code CLI. Not available in Agent SDK (Python/TypeScript) as of 2026-03.
