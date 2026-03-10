# Subagent File Reference — Sources and Update Procedure

**Last Updated**: 2026-03-09

This file documents the information sources and research procedure used to create `subagent-file-reference.md`. When the reference guide becomes stale, follow this procedure to update it.

---

## Update Procedure

**Principle**: Official documentation and GitHub Issues are starting points, not ground truth. Docs lag behind implementation, contain inaccuracies, and may describe intended behavior rather than actual behavior. **Every claim in the reference must be verified against the real environment.**

1. Check the "Last Updated" date in `subagent-file-reference.md`. If older than ~1 month, update is recommended.
2. For each source below, visit the URL and check for changes since the last update.
3. Pay special attention to: new frontmatter fields, discovery path changes, permission mode changes, new hooks events, memory behavior changes.
4. Check GitHub Issues for open bugs that affect subagent files.
5. **Run hands-on verification against the real environment** (see Verification Procedures below). This step is mandatory — do not skip it in favor of trusting docs.
6. Update `subagent-file-reference.md` content and its "Last Updated" date. Mark each claim as verified or unverified.
7. Update this file's "Last Verified" dates for each source.
8. Record verification results in the reference's "Hands-on Verification Summary" section.

---

## Primary Sources

### Official Documentation

| Source | URL | Last Verified |
|--------|-----|--------------|
| Sub-agents documentation | https://code.claude.com/docs/en/sub-agents | 2026-03-09 |
| Hooks reference | https://code.claude.com/docs/en/hooks | 2026-03-09 |
| Skills documentation | https://code.claude.com/docs/en/skills | 2026-03-09 |
| MCP servers | https://code.claude.com/docs/en/mcp | 2026-03-09 |
| Settings reference | https://code.claude.com/docs/en/settings | 2026-03-09 |
| Plugins reference | https://code.claude.com/docs/en/plugins-reference | 2026-03-09 |
| Permissions | https://code.claude.com/docs/en/permissions | 2026-03-09 |

Key facts: The "Supported frontmatter fields" table on the sub-agents page is the canonical reference for all fields. The hooks page documents SubagentStart/SubagentStop events. Memory auto-enables Read/Write/Edit tools.

### GitHub Issues (Active Monitoring)

| Issue | Topic | Last Verified |
|-------|-------|--------------|
| #27736 | skills field not rendered in Agent tool description (OPEN) | 2026-03-09 |
| #27749 | Custom branch name for isolation: worktree (OPEN, FEATURE) | 2026-03-09 |
| #32340 | Skills invocation + nested spawning parity (OPEN, FEATURE) | 2026-03-09 |

Search query: `gh search issues --repo anthropics/claude-code "agent definition OR frontmatter OR .claude/agents" --sort updated --limit 20`

### sync-sdd Agent Definitions (Internal)

| File | Last Verified |
|------|--------------|
| framework/claude/agents/sdd-analyst.md | 2026-03-09 |
| framework/claude/agents/sdd-architect.md | 2026-03-09 |
| framework/claude/agents/sdd-builder.md | 2026-03-09 |
| framework/claude/agents/sdd-taskgenerator.md | 2026-03-09 |
| framework/claude/agents/sdd-conventions-scanner.md | 2026-03-09 |

When updating, verify the sync-sdd agent list section matches actual files in framework/claude/agents/.

---

## Research Queries Used

### Official Docs
- WebFetch: https://code.claude.com/docs/en/sub-agents — full spec, frontmatter table
- WebFetch: https://code.claude.com/docs/en/hooks — SubagentStart/SubagentStop events

### GitHub Issues
- `gh search issues --repo anthropics/claude-code "agent definition" --sort updated --limit 20`
- `gh search issues --repo anthropics/claude-code "frontmatter" --sort updated --limit 10`
- `gh search issues --repo anthropics/claude-code "agent skills field" --sort updated --limit 10`

### Key Verification Points

1. **Frontmatter fields table**: New fields may be added. The table on the sub-agents page is canonical
2. **name constraints**: Only "lowercase letters and hyphens" is documented. Additional constraints (no leading/trailing/consecutive hyphens) are inferred — verify if formalized
3. **tools format**: Both CSV string and YAML array work (verified v2.1.72). Check if new formats are added
4. **permissionMode values**: May add new modes. Check for bypassPermissions precedence rules
5. **memory behavior**: Auto-tool enablement and MEMORY.md injection — verify details
6. **hooks**: New events may be added. Check hooks reference page
7. **Discovery paths**: New locations or priority changes
8. **Agent(type) syntax**: Restrictions on which agents can spawn which — this is main-thread only
9. **CLAUDE.md inheritance**: See "Critical Evidence" in `agent-tool-sources.md`. Whether CLAUDE.md is passed to SubAgents requires ongoing verification
10. **name vs filename**: name field is subagent_type, not filename (verified v2.1.72). Check if this behavior changes

---

## Verification Procedures

**Why this section exists**: Official docs stated "Must match the filename" for the `name` field — this was wrong (verified: name field determines subagent_type regardless of filename). Docs also omitted YAML array format for `tools`. Hands-on testing is the only way to confirm actual behavior.

### Frontmatter Required Fields

Create minimal test definitions and attempt to load them:

```
# Test: name only (no description) → should fail to load
# Test: description only (no name) → should fail to load
# Test: both name + description → should load successfully
# Verification: restart session, then Agent(subagent_type: "nonexistent") to list available agents
```

Files that fail to load are silently ignored — they simply don't appear in the available agents list.

### name vs filename Relationship

Create a definition where name differs from filename:

```
# File: .claude/agents/test-name-mismatch.md
# Frontmatter: name: different-name-from-filename
# Restart session
# Agent(subagent_type: "nonexistent") → check which name appears in available list
# Dispatch using the name field value, not the filename
```

### Frontmatter Field Verification

Create test definitions with each optional field and verify behavior:

```
# model: haiku → verify actual model via transcript jsonl (NOT SubAgent self-report)
jq -r 'select(.type == "assistant") | .message.model' ~/.claude/projects/{project}/{session}/subagents/agent-{id}.jsonl

# tools: "Read, Glob, Grep" (CSV) → try using Write, verify denied
# tools: [Read, Glob, Grep] (YAML array) → same test
# background: true → verify Agent tool auto-launches in background
# isolation: worktree → check CWD in SubAgent output
# maxTurns: 1 → verify stops after 1 tool use
# permissionMode: dontAsk → verify unapproved tools auto-denied
```

### Session Reload Behavior

Files added during a session are NOT loaded until session restart (or `/agents`). Always restart the session after creating test definitions before testing them.

---

## Critical Evidence

### Context Received by SubAgents

**Official documentation excerpt** (sub-agents page):
> "Subagents receive **only this system prompt** (plus basic environment details like working directory), **not the full Claude Code system prompt.**"

Here "this system prompt" refers to the Markdown body of the agent definition. CLAUDE.md is part of the "full Claude Code system prompt".

For details, see the "Critical Evidence" section in `agent-tool-sources.md`.

### Hooks Type Restrictions

**Official documentation excerpt** (hooks page, end of "Prompt-based hooks" section):

Events supporting all 4 types (`command`, `http`, `prompt`, `agent`):
> PostToolUse, PostToolUseFailure, PreToolUse, Stop, SubagentStop, **TaskCompleted**, UserPromptSubmit

Events supporting `command` only:
> ConfigChange, Notification, PreCompact, SessionEnd, SessionStart, SubagentStart, **TeammateIdle**, WorktreeCreate, WorktreeRemove

-> The type restriction descriptions for TeammateIdle/TaskCompleted in agent-team-reference.md are based on this evidence.
