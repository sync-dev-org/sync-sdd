# Skill Reference — Sources and Update Procedure

**Last Updated**: 2026-03-08

This file documents the information sources and research procedure used to create `skill-authoring.md`. When the reference guide becomes stale, follow this procedure to update it.

---

## Update Procedure

1. Check the "Last Updated" date in `skill-authoring.md`. If older than ~1 month, update is recommended.
2. For each source below, visit the URL and check for changes since the last update.
3. Pay special attention to: new frontmatter fields, discovery path changes, breaking changes, new platform features.
4. Update `skill-authoring.md` content and its "Last Updated" date.
5. Update this file's "Last Verified" dates for each source.

---

## Primary Sources

### agentskills.io (Open Standard)

| Source | URL | Last Verified |
|--------|-----|--------------|
| Specification | https://agentskills.io/specification | 2026-03-08 |
| What Are Skills | https://agentskills.io | 2026-03-08 |
| Integration Guide | https://agentskills.io/integrate-skills | 2026-03-08 |
| GitHub repo | https://github.com/agentskills/agentskills | 2026-03-08 |
| skills-ref validator | https://github.com/agentskills/agentskills/tree/main/skills-ref | 2026-03-08 |

Key facts: Living document (no formal version). Maintained by Anthropic. 30+ platform adopters. Core fields: name, description, license, compatibility, metadata, allowed-tools (experimental).

### Claude Code

| Source | URL | Last Verified |
|--------|-----|--------------|
| Skills documentation | https://code.claude.com/docs/en/skills | 2026-03-08 |
| Best practices | https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices | 2026-03-08 |
| Overview | https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview | 2026-03-08 |
| anthropics/skills repo | https://github.com/anthropics/skills | 2026-03-08 |
| Skill creator blog | https://claude.com/blog/improving-skill-creator-test-measure-and-refine-agent-skills | 2026-03-08 |
| Release notes tracker | https://www.claudeupdates.dev | 2026-03-08 |

Key facts: v2.1.69 (2026-03-05). Discovery: `.claude/skills/` only. Extension fields: disable-model-invocation, user-invocable, context, agent, model, allowed-tools, hooks, argument-hint. `${CLAUDE_SKILL_DIR}` variable added in v2.1.69.

### Codex CLI

| Source | URL | Last Verified |
|--------|-----|--------------|
| Skills documentation | https://developers.openai.com/codex/skills/ | 2026-03-08 |
| AGENTS.md guide | https://developers.openai.com/codex/guides/agents-md | 2026-03-08 |
| CLI reference | https://developers.openai.com/codex/cli/reference/ | 2026-03-08 |
| Multi-agent | https://developers.openai.com/codex/multi-agent/ | 2026-03-08 |
| Config reference | https://developers.openai.com/codex/config-reference/ | 2026-03-08 |
| Prompting guide | https://developers.openai.com/cookbook/examples/gpt-5/codex_prompting_guide/ | 2026-03-08 |
| GitHub repo | https://github.com/openai/codex | 2026-03-08 |
| Changelog | https://developers.openai.com/codex/changelog/ | 2026-03-08 |

Key facts: v0.111.0 (2026-03-05). Discovery: `.agents/skills/` (CWD to root). Extension: agents/openai.yaml sidecar. Explicit ($skill-name) + implicit (description match) invocation. Custom prompts deprecated in favor of skills.

### Gemini CLI

| Source | URL | Last Verified |
|--------|-----|--------------|
| Skills documentation | https://geminicli.com/docs/cli/skills/ | 2026-03-08 |
| GEMINI.md guide | https://geminicli.com/docs/cli/gemini-md/ | 2026-03-08 |
| Subagents | https://geminicli.com/docs/core/subagents/ | 2026-03-08 |
| Extensions | https://geminicli.com/docs/extensions/ | 2026-03-08 |
| Extension reference | https://geminicli.com/docs/extensions/reference/ | 2026-03-08 |
| Custom commands | https://geminicli.com/docs/cli/custom-commands/ | 2026-03-08 |
| Hooks reference | https://geminicli.com/docs/hooks/reference/ | 2026-03-08 |
| Configuration | https://geminicli.com/docs/reference/configuration/ | 2026-03-08 |
| GitHub repo | https://github.com/google-gemini/gemini-cli | 2026-03-08 |
| Latest changelog | https://geminicli.com/docs/changelogs/latest/ | 2026-03-08 |

Key facts: v0.32.1 (2026-03-04). Discovery: `.gemini/skills/` AND `.agents/skills/` (`.agents/` takes precedence). activate_skill tool for explicit activation. Extensions as packaging unit. Subagents experimental (requires enableAgents flag).

### Cross-Platform / Ecosystem

| Source | URL | Last Verified |
|--------|-----|--------------|
| AGENTS.md standard | https://agents.md/ | 2026-03-08 |
| skills.sh (Vercel) | https://skills.sh/ | 2026-03-08 |
| vercel-labs/skills repo | https://github.com/vercel-labs/skills | 2026-03-08 |
| awesome-agent-skills | https://github.com/VoltAgent/awesome-agent-skills | 2026-03-08 |
| Claude Code AGENTS.md issue | https://github.com/anthropics/claude-code/issues/6235 | 2026-03-08 |
| AAIF (Linux Foundation) | https://aaif.io/ | 2026-03-08 |

Key facts: `.agents/skills/` is de facto cross-platform path (Claude Code is the exception). skills.sh has 44k+ skills. AGENTS.md is governed by Linux Foundation AAIF; agentskills.io is still Anthropic-maintained. Claude Code does not support AGENTS.md (3,059 upvotes on feature request).

---

## Research Queries Used

These queries were used during the initial research (2026-03-08). Reuse them for updates.

### agentskills.io / Standard
- "agentskills.io specification 2026"
- "agent skills open standard cross-platform 2026"
- ".agents directory standard 2026"
- "agents directory cross-platform skills"

### Claude Code
- "Claude Code skills 2026 March"
- "Claude Code agent skills update 2026"
- "Claude Code AGENTS.md support 2026"
- "Claude Code skills best practices site:platform.claude.com"

### Codex CLI
- "OpenAI Codex CLI custom instructions 2026"
- "Codex CLI AGENTS.md format"
- "Codex CLI update March 2026"
- "codex-cli changelog 2026"
- "codex-cli github agents"

### Gemini CLI
- "Google Gemini CLI custom instructions 2026"
- "Gemini CLI GEMINI.md configuration"
- "Gemini CLI update March 2026"
- "gemini-cli github agents extensions"

### Cross-Platform
- "write skills that work on Claude Code AND Codex AND Gemini"
- "cross-platform agent skills best practices 2026"
- "agentskills.io portable skills guide"
- "SKILL.md frontmatter cross-platform compatibility"
- "AI coding agent skills best practices 2026"
- "Claude Code vs Codex vs Gemini CLI skills comparison 2026"

### Community
- "Claude Code skills tips site:reddit.com 2026"
- "Claude Code skills site:news.ycombinator.com 2026"
- "Codex CLI custom instructions tips 2026"
- "github cross-platform agent skills repository"
