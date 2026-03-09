# SubAgent Definition Reference — Sources and Update Procedure

**Last Updated**: 2026-03-09

This file documents the information sources and research procedure used to create `subagent-definition-reference.md`. When the reference guide becomes stale, follow this procedure to update it.

---

## Update Procedure

1. Check the "Last Updated" date in `subagent-definition-reference.md`. If older than ~1 month, update is recommended.
2. For each source below, visit the URL and check for changes since the last update.
3. Pay special attention to: new frontmatter fields, discovery path changes, permission mode changes, new hooks events, memory behavior changes.
4. Check GitHub Issues for open bugs that affect agent definitions.
5. Update `subagent-definition-reference.md` content and its "Last Updated" date.
6. Update this file's "Last Verified" dates for each source.

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
3. **tools format**: Comma-separated in frontmatter, array in CLI JSON. Verify if space-separated is also supported
4. **permissionMode values**: May add new modes. Check for bypassPermissions precedence rules
5. **memory behavior**: Auto-tool enablement and MEMORY.md injection — verify details
6. **hooks**: New events may be added. Check hooks reference page
7. **Discovery paths**: New locations or priority changes
8. **Agent(type) syntax**: Restrictions on which agents can spawn which — this is main-thread only
9. **CLAUDE.md 継承**: `agent-tool-sources.md` の「要注意エビデンス」参照。SubAgent に CLAUDE.md が渡されるか否かは要継続検証

---

## 要注意エビデンス

### SubAgent が受け取るコンテキスト

**公式ドキュメント原文** (sub-agents ページ):
> "Subagents receive **only this system prompt** (plus basic environment details like working directory), **not the full Claude Code system prompt.**"

この "this system prompt" は agent 定義の Markdown body を指す。CLAUDE.md は "full Claude Code system prompt" の一部。

詳細は `agent-tool-sources.md` の「要注意エビデンス」セクション参照。

### hooks のタイプ制限

**公式ドキュメント原文** (hooks ページ, "Prompt-based hooks" セクション末尾):

全4タイプ (`command`, `http`, `prompt`, `agent`) をサポートするイベント:
> PostToolUse, PostToolUseFailure, PreToolUse, Stop, SubagentStop, **TaskCompleted**, UserPromptSubmit

`command` のみサポートするイベント:
> ConfigChange, Notification, PreCompact, SessionEnd, SessionStart, SubagentStart, **TeammateIdle**, WorktreeCreate, WorktreeRemove

→ agent-team-reference.md の TeammateIdle/TaskCompleted のタイプ制限記述はこのエビデンスに基づく。
