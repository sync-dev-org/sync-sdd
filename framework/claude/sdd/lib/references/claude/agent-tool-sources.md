# Agent Tool Reference — Sources and Update Procedure

**Last Updated**: 2026-03-09

This file documents the information sources and research procedure used to create `agent-tool-reference.md`. When the reference guide becomes stale, follow this procedure to update it.

---

## Update Procedure

1. Check the "Last Updated" date in `agent-tool-reference.md`. If older than ~1 month, update is recommended.
2. For each source below, visit the URL and check for changes since the last update.
3. Pay special attention to: new parameters, new built-in agent types, model alias changes, new environment variables, breaking changes to nesting/context/background behavior.
4. Check GitHub Issues for open bugs that contradict official docs (docs can lag behind actual behavior).
5. Update `agent-tool-reference.md` content and its "Last Updated" date.
6. Update this file's "Last Verified" dates for each source.

---

## Primary Sources

### Official Documentation

| Source | URL | Last Verified |
|--------|-----|--------------|
| Sub-agents documentation | https://code.claude.com/docs/en/sub-agents | 2026-03-09 |
| Model configuration | https://code.claude.com/docs/en/model-config | 2026-03-09 |
| Costs and token usage | https://code.claude.com/docs/en/costs | 2026-03-09 |
| Settings & env vars | https://code.claude.com/docs/en/settings | 2026-03-09 |
| Agent teams (for comparison) | https://code.claude.com/docs/en/agent-teams | 2026-03-09 |
| Hooks reference | https://code.claude.com/docs/en/hooks | 2026-03-09 |
| CLI reference | https://code.claude.com/docs/en/cli-reference | 2026-03-09 |

Key facts: Agent tool parameters are not directly documented as a parameter table — they are inferred from the built-in tool definition and usage patterns. Built-in agent types are listed under "Built-in subagents". Model aliases are on the model-config page.

### GitHub Issues (Active Monitoring)

| Issue | Topic | Last Verified |
|-------|-------|--------------|
| #5456 | Agent definition model ignored (CLOSED, DUPLICATE) | 2026-03-09 |
| #3903 | --model not inherited by sub-tasks (CLOSED, NOT_PLANNED) | 2026-03-09 |
| #27736 | skills field not rendered in Agent tool description (OPEN) | 2026-03-09 |
| #32340 | Skills invocation + nested spawning feature request (OPEN) | 2026-03-09 |

Search query for new issues: `gh search issues --repo anthropics/claude-code "subagent OR agent definition OR agent tool" --sort updated --limit 20`

### Release Tracking

| Source | URL | Last Verified |
|--------|-----|--------------|
| Claude Code updates | https://www.claudeupdates.dev | 2026-03-09 |
| Documentation index | https://code.claude.com/docs/llms.txt | 2026-03-09 |

---

## Research Queries Used

These queries were used during the initial research (2026-03-09). Reuse them for updates.

### Official Docs
- WebFetch: https://code.claude.com/docs/en/sub-agents — full spec extraction
- WebFetch: https://code.claude.com/docs/en/model-config — model aliases, env vars

### GitHub Issues
- `gh search issues --repo anthropics/claude-code "subagent" --sort updated --limit 20`
- `gh search issues --repo anthropics/claude-code "agent definition model ignored" --sort updated`
- `gh search issues --repo anthropics/claude-code "CLAUDE_CODE_SUBAGENT_MODEL" --sort updated`
- `gh search issues --repo anthropics/claude-code "agent tool parameter" --sort updated`

### Key Verification Points

On each update, verify these specific claims which are most likely to change:

1. **Built-in agent types**: New types may be added. Check "Built-in subagents" section
2. **Model aliases**: New aliases (e.g., `sonnet[1m]`) may be added. Check model-config page
3. **Nesting**: Currently prohibited. Feature request #32340 may change this
4. **Background behavior**: Permission pre-approval model may evolve
5. **CLAUDE_CODE_SUBAGENT_MODEL**: Behavior may change. Check model-config env vars table
6. **Agent Team comparison**: Agent Team is experimental — may become stable or get new capabilities
7. **CLAUDE.md inheritance**: See "Critical Evidence" below

---

## Critical Evidence

### Does SubAgent Context Include CLAUDE.md?

**Conclusion (2026-03-09)**: Based on official documentation, **it does not**.

**Official documentation excerpt** (sub-agents page, "Write subagent files" section):
> "The body becomes the system prompt that guides the subagent's behavior. **Subagents receive only this system prompt (plus basic environment details like working directory), not the full Claude Code system prompt.**"

CLAUDE.md is part of the Claude Code system prompt and is included in the "full Claude Code system prompt".

**Contrast: Agent Team (Teammate)** (agent-teams page, "Context and communication" section):
> "Each teammate has its own context window. When spawned, a teammate loads the same project context as a regular session: **CLAUDE.md, MCP servers, and skills.**"
> "**CLAUDE.md works normally**: teammates read CLAUDE.md files from their working directory."

-> CLAUDE.md loading is explicitly documented **only for Teammates**. It is not documented for SubAgents.

**Research agent misreport**: A research agent on 2026-03-09 reported that "CLAUDE.md is also loaded for SubAgents", but this was an error that confused the Teammate description with SubAgent behavior.

**Possible divergence from actual behavior**: Official documentation and actual behavior may differ (Claude Code is under active development). Verification through hands-on testing is recommended during the next update.

**Impact on framework design**: sync-sdd is designed with the assumption that CLAUDE.md is NOT inherited (necessary context is explicitly passed via the prompt when dispatching SubAgents). As long as this assumption holds, there is no impact.

### Model Priority Is Not Officially Defined

**Conclusion (2026-03-09)**: The priority table in agent-tool-reference.md is estimated.

Official documentation does not contain a table or description explicitly defining model priority. It is inferred from the following information:
- Agent definition `model` field: listed in the frontmatter table, default is `inherit`
- `CLAUDE_CODE_SUBAGENT_MODEL`: documented in the model-config page's environment variables table as "The model to use for subagents"
- `model` parameter at dispatch time: exists as a built-in parameter of the Agent tool (confirmed from actual behavior)
- #3903/#5456: Reports that the agent definition's model is ignored — basis for the recommendation that the dispatch-time parameter is reliable

Verify during the next update whether official documentation has added an explicit priority definition.
