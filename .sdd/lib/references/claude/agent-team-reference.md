# Claude Code Agent Team Reference

**Last Updated**: 2026-03-09
**Status**: Experimental (disabled by default)
**Sources**: code.claude.com/docs/en/agent-teams, code.claude.com/docs/en/costs

An experimental feature that coordinates multiple independent Claude Code sessions as a team. Fundamentally different architecture from the Agent tool (SubAgent).

For SubAgent (Agent tool) specifications, see `agent-tool-reference.md`. For agent definitions, see `subagent-definition-reference.md`.

## Activation

Disabled by default. Enable via environment variable or settings.json:

```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

## Architecture

| Component | Role |
|-----------|------|
| **Team lead** | The Claude Code session that creates the team, assigns tasks, and integrates results |
| **Teammates** | Separate Claude Code instances with independent context windows |
| **Task list** | A shared task list with dependency tracking. Teammates autonomously claim tasks |
| **Mailbox** | Inter-agent messaging infrastructure |

### Fundamental Differences from SubAgent

| Aspect | Agent tool (SubAgent) | Agent Team |
|--------|----------------------|------------|
| **Session** | Child context within parent session | Fully independent Claude Code instance |
| **Communication** | Unidirectional (parent→child: prompt, child→parent: result) | **Bidirectional** (Lead↔Teammate, Teammate↔Teammate) |
| **Coordination** | Parent manages all work | Autonomous claim via Shared Task List |
| **Context** | system prompt + environment info + prompt (officially: CLAUDE.md is NOT included) | Own complete Claude Code session (loads CLAUDE.md, MCP servers, Skills) |
| **Nesting** | SubAgent cannot spawn SubAgents | Teammate cannot create sub-teams |
| **Token cost** | Low (result summarization) | **High** — approximately 7x in plan mode, generally "significantly more" |
| **Use case** | Bounded tasks with clear focus | Complex parallel work requiring discussion and coordination |

## Team Creation

Request in natural language. Claude proposes team composition → user approves → spawn executes:

```
Create an agent team to explore this CLI design from different angles:
- one teammate on UX
- one on technical architecture
- one playing devil's advocate
```

Number of teammates and models can also be specified:
```
Create a team with 4 teammates to refactor these modules in parallel.
Use Sonnet for each teammate.
```

**Recommended team size**: 3-5 teammates. Approximately 5-6 tasks/teammate as a guideline.

## Display Modes

| Mode | Description | Requirements |
|------|-------------|--------------|
| **In-process** | Runs all Teammates within the main terminal. Switch with Shift+Down | Any terminal |
| **Split panes** | Dedicated pane per Teammate. Click to interact directly | tmux or iTerm2 (`it2` CLI) |

Default is `"auto"` (split panes when inside tmux).

Configuration:
- settings.json: `"teammateMode": "in-process"` / `"tmux"` / `"auto"`
- CLI flag: `claude --teammate-mode in-process`

`"tmux"` enables split-pane mode and auto-detects tmux and iTerm2.

## Communication

### Message Types

| Type | Recipient | Purpose |
|------|-----------|---------|
| `message` | A single specific Teammate | Task instructions, questions, feedback |
| `broadcast` | All Teammates | General notifications (use sparingly as cost scales with team size) |

Message delivery is automatic (no polling required). Teammates are automatically notified when idle.

### Direct Interaction

- **In-process**: Shift+Down to cycle between Teammates. Enter to join a session, Escape to interrupt. Ctrl+T to display the task list
- **Split panes**: Click on a pane to interact directly

### Plan Approval

Plan approval can be required from Teammates:
```
Spawn an architect teammate to refactor the auth module.
Require plan approval before they make any changes.
```

Teammate submits a plan → Lead autonomously approves/rejects → on rejection, resubmits with feedback. Lead's decision criteria can be guided via prompt.

## Task Coordination

- Lead decomposes tasks and registers them in the Shared Task List
- Teammates autonomously claim unblocked tasks
- Task completion automatically unblocks dependent tasks
- File locking prevents race conditions on simultaneous claims
- Task states: pending → in progress → completed

## Hooks

| Event | Description | Effect of exit code 2 |
|-------|-------------|----------------------|
| `TeammateIdle` | Just before a Teammate becomes idle | Forces it to continue working |
| `TaskCompleted` | Just before a task is marked complete | Blocks completion and sends feedback (stderr) |

Both hooks also support JSON output: `{"continue": false, "stopReason": "..."}` to fully stop a Teammate.

`TeammateIdle` supports `type: "command"` only. `TaskCompleted` supports all 4 types (`command`, `http`, `prompt`, `agent`).

## Permissions

- All Teammates inherit the Lead's permission mode at spawn time
- Individual Teammate modes can be changed after spawn (but per-teammate specification at spawn time is not possible)
- If the Lead uses `--dangerously-skip-permissions`, all Teammates do as well

## State Storage

| Location | Contents |
|----------|----------|
| `~/.claude/teams/{team-name}/config.json` | Member array (name, agent ID, agent type) |
| `~/.claude/tasks/{team-name}/` | Task definitions and status |

Teammates can read config.json to discover other members.

## Context

What each Teammate receives:
- CLAUDE.md (project's)
- MCP servers
- Skills
- Spawn prompt from Lead

Lead's conversation history is **NOT carried over**.

## Appropriate Use Cases

- **Research & Review**: Multiple Teammates investigate from different perspectives simultaneously, sharing and challenging findings
- **New module development**: Teammates divide components (assuming no file conflicts)
- **Debugging**: Test multiple hypotheses in parallel — converge on root cause through adversarial debate
- **Cross-layer coordination**: Separate Teammates handle Frontend / Backend / Tests

## Cases to Avoid

- Sequential tasks (a single session is more efficient)
- Editing the same files (coordination overhead exceeds benefits)
- Tasks with many dependencies (coordination becomes complex)
- Routine work (token cost is not justified)

## Known Limitations

| Limitation | Details |
|------------|---------|
| **No session restoration** | In-process Teammates are not restored by `/resume` or `/rewind`. Lead may send messages to non-existent Teammates → instruct it to spawn new Teammates |
| **Task status lag** | Teammates may fail to mark tasks as complete, causing dependent tasks to remain blocked |
| **Shutdown delay** | Teammates shut down after completing the current request/tool call |
| **1 team per session** | Lead can manage only 1 team at a time. Cleanup is required before creating a new team |
| **No nested teams** | Teammates cannot create sub-teams |
| **Fixed Lead** | The session that created the team remains Lead for its lifetime (non-transferable) |
| **Split panes constraints** | Not supported in VS Code integrated terminal, Windows Terminal, or Ghostty |

### Known Issues (GitHub)

- **#32276** (OPEN): shutdown_request wakes idle Teammates, which then attempt to message already-terminated peers
- **#27556** (OPEN): TaskUpdate metadata from background agents is not persisted to disk
- **#32357** (OPEN): Feature request for Teammate adoption with custom agent definitions

## Relationship with Agent SDK

Agent Team is a **Claude Code CLI-exclusive feature**. It is not exposed as a programmable API in the Agent SDK (Python/TypeScript) (as of 2026-03).

| Feature | Claude Code CLI | Agent SDK |
|---------|----------------|-----------|
| Agent Team | Yes (experimental) | No |
| SubAgent (Agent tool) | Yes | Yes (`query()`) |
| Custom agent definitions | Yes (`.claude/agents/`) | Yes (config) |
| Hooks | Yes | Yes |
| MCP servers | Yes | Yes |

## Position within sync-sdd

sync-sdd does **NOT use** Agent Team. Reasons:

1. Experimental and disabled by default — cannot guarantee operation in user environments
2. High token cost (approximately 7x in plan mode) — too expensive as framework default behavior
3. Equivalent parallelism already achieved with Agent tool (SubAgent) + tmux grid
4. sync-sdd SubAgents are loosely coupled via file-based communication — Agent Team's bidirectional messaging is unnecessary

However, if Agent Team becomes stable and an SDK API is released, it could potentially be applied to use cases such as parallel Inspector execution in the review pipeline.
