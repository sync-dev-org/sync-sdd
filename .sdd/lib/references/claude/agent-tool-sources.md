# Agent Tool Reference — Sources and Update Procedure

**Last Updated**: 2026-03-10

This file documents the information sources and research procedure used to create `agent-tool-reference.md`. When the reference guide becomes stale, follow this procedure to update it.

---

## Update Procedure

**Principle**: Official documentation and GitHub Issues are starting points, not ground truth. Docs lag behind implementation, contain inaccuracies, and may describe intended behavior rather than actual behavior. GitHub Issues may remain OPEN after fixes are shipped. **Every claim in the reference must be verified against the real environment.**

1. Check the "Last Updated" date in `agent-tool-reference.md`. If older than ~1 month, update is recommended.
2. For each source below, visit the URL and check for changes since the last update.
3. Pay special attention to: new parameters, new built-in agent types, model alias changes, new environment variables, breaking changes to nesting/context/background behavior.
4. Check GitHub Issues for open bugs that contradict official docs (docs can lag behind actual behavior). **Do not assume an issue's status reflects reality** — issues may be OPEN after a fix ships, or CLOSED while the bug persists.
5. **Run hands-on verification against the real environment** (see Verification Procedures below). This step is mandatory — do not skip it in favor of trusting docs or issue statuses.
6. Update `agent-tool-reference.md` content and its "Last Updated" date. Mark each claim as verified or unverified.
7. Update this file's "Last Verified" dates for each source.
8. Record verification results in the "Hands-on Verification" sections below.

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

Key facts: The hooks.md PreToolUse section documents Agent tool input fields (prompt, description, subagent_type, model). As of v2.1.72, `model` has been restored to the tool schema (#31311, #31027 fixed). Built-in agent types are listed under "Built-in subagents". Model aliases are on the model-config page.

### GitHub Issues (Active Monitoring)

| Issue | Topic | Status | Last Verified |
|-------|-------|--------|--------------|
| #31311 | Agent tool `model` parameter silently ignored in v2.1.69-v2.1.71 (regression, fixed in v2.1.72) | OPEN | 2026-03-10 |
| #31027 | Agent tool schema missing `model` parameter (fixed in v2.1.72) | OPEN | 2026-03-10 |
| #18873 | `model` parameter returns 404 / blocks cost-optimized workflows (fixed in v2.1.72) | OPEN | 2026-03-10 |
| #5456 | Agent definition model ignored (CLOSED, DUPLICATE of #3903) | CLOSED | 2026-03-09 |
| #3903 | --model not inherited by sub-tasks (CLOSED, NOT_PLANNED) | CLOSED | 2026-03-09 |
| #27736 | skills field not rendered in Agent tool description | OPEN | 2026-03-09 |
| #32340 | Skills invocation + nested spawning feature request | OPEN | 2026-03-09 |

Search queries for new issues:
- `gh search issues --repo anthropics/claude-code "subagent OR agent definition OR agent tool" --sort updated --limit 20`
- `gh search issues --repo anthropics/claude-code "subagent model" --sort updated --limit 10`
- `gh search issues --repo anthropics/claude-code "Agent tool model" --sort updated --limit 10`

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

## Verification Procedures

**Why this section exists**: Official docs contained inaccuracies (e.g., `model` parameter documented but broken for months; `Bash` listed as built-in type but not in runtime list; GitHub Issues OPEN after fixes shipped). Web research and doc reading alone produce unreliable references. Hands-on testing is the only way to confirm actual behavior.

### Agent Tool Parameter Schema Verification

Probe the tool schema by passing invalid values and reading validation errors:

```
# Enumerate enum values — error message reveals accepted values
Agent(model: "invalid") → "Invalid option: expected one of ..."
Agent(isolation: "invalid") → "Invalid input: expected ..."

# Enumerate available agent types
Agent(subagent_type: "nonexistent") → "not found. Available agents: ..."

# Verify string parameters accept arbitrary values (runtime check only)
Agent(resume: "invalid_id") → runtime error, not schema error

# Verify boolean parameters
Agent(run_in_background: true) → success confirms boolean type

# Verify required parameters
Omit description or prompt → schema validation error
```

### Model Verification

SubAgent self-reports are unreliable — the model may report what it reads from frontmatter rather than its actual identity. Verify via transcript:

```
# Check actual API model from transcript jsonl
jq -r 'select(.type == "assistant") | .message.model' ~/.claude/projects/{project}/{session}/subagents/agent-{id}.jsonl
```

### Built-in Agent Types Verification

The error message from an invalid `subagent_type` lists all available agents. Compare against the reference table. Types not in the list should be removed or marked as internal.

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

### Agent Tool `model` Parameter History

**Conclusion (2026-03-10)**: The `model` parameter is working as of v2.1.72. Short aliases (sonnet/opus/haiku) are supported.

**Timeline:**
- **v1.0.53-v1.0.72**: #3903/#5456 report model not inherited by sub-tasks
- **v2.1.12+**: #18873 reports `model` parameter broken (short name → 404, full ID → validation error)
- **v2.1.66**: `model` present in tool schema (documented in #31027 with full schema comparison)
- **v2.1.68**: `model` reported as working briefly (#31311 author)
- **v2.1.69**: `model` removed from tool schema (#31311 regression, #31027)
- **v2.1.71**: Confirmed absent from tool schema (hands-on verification 2026-03-10)
- **v2.1.72**: **Fixed.** `model` restored to tool schema. Short aliases work: `sonnet` → claude-sonnet-4-6, `haiku` → claude-haiku-4-5 (hands-on verification 2026-03-10)
- **hooks.md**: Lists `model` in PreToolUse Agent input table (now consistent with implementation)

**Hands-on verification (2026-03-10, v2.1.71):**
- Tool schema provided to LLM has `additionalProperties: false` with 6 properties: description, prompt, subagent_type, run_in_background, isolation, resume. No `model`.
- Agent definition frontmatter `model` field works: sdd-builder (`model: sonnet`) → API call uses `claude-sonnet-4-6` (verified via SubAgent transcript jsonl)
- Built-in types verified: general-purpose → opus (inherit), Explore → haiku, Plan → opus (inherit), statusline-setup → sonnet, claude-code-guide → haiku

**Hands-on verification (2026-03-10, v2.1.72) — full parameter schema:**
- `model: sonnet` → SubAgent reports claude-sonnet-4-6
- `model: haiku` → SubAgent reports claude-haiku-4-5
- `model: "sonnet[1m]"` → InputValidationError: enum accepts only `sonnet`/`opus`/`haiku`
- `model: "invalid"` → same enum error, confirms 3-value enum
- `isolation: "invalid"` → InputValidationError: expected `"worktree"` (single-value enum)
- `subagent_type: "nonexistent"` → runtime error listing available agents: general-purpose, statusline-setup, Explore, Plan, claude-code-guide + custom definitions. **`Bash` not listed** — removed from reference
- `resume: "invalid_id"` → runtime error "No transcript found" (string type, no schema validation)
- `run_in_background: true` → works (boolean type confirmed)
- `description` and `prompt` → required strings (omission triggers validation error)

**Practical impact**: Both dispatch-time `model` parameter and agent definition frontmatter `model` field are available for model control. Dispatch-time takes precedence.

### Model Priority Is Not Officially Defined

**Conclusion (2026-03-10)**: Updated based on hands-on verification (v2.1.72).

The priority table in agent-tool-reference.md is based on verified behavior:
1. Dispatch-time `model` parameter: **verified working (v2.1.72+)** — `sonnet` → claude-sonnet-4-6, `haiku` → claude-haiku-4-5
2. Agent definition `model` field: **verified working** (sdd-builder → sonnet confirmed via transcript)
3. `CLAUDE_CODE_SUBAGENT_MODEL`: documented but not verified in this environment
4. Default (inherit): **verified working** (general-purpose → parent model confirmed)

Priority 1 vs 2 precedence (dispatch-time overriding definition) is inferred from Claude Code architecture but not explicitly tested with a conflicting configuration.
