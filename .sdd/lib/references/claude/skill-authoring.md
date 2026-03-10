# Agent Skills Reference Guide

**Last Updated**: 2026-03-08
**Spec Basis**: agentskills.io (living document, no formal version)
**Sources**: See `skill-authoring-sources.md` for full source list and update procedure.

This guide covers the Agent Skills specification, platform-specific implementations, cross-platform compatibility, and best practices for skill authoring. It is the primary reference for the Skill Writer SubAgent.

---

## 1. Agent Skills Standard Specification

The Agent Skills format was created by Anthropic (December 2025) and released as an open standard at [agentskills.io](https://agentskills.io/specification). Adopted by 30+ platforms including Claude Code, Codex CLI, Gemini CLI, Cursor, VS Code/Copilot, Windsurf, and others.

### 1.1 Directory Structure

```
skill-name/
├── SKILL.md          # Required — YAML frontmatter + Markdown body
├── scripts/          # Optional — executable code for deterministic tasks
├── references/       # Optional — docs loaded into context as needed
└── assets/           # Optional — templates, images, data files
```

### 1.2 SKILL.md Format

```yaml
---
name: skill-name
description: What the skill does and when to use it.
---

Markdown instructions (the skill body).
```

### 1.3 Frontmatter Fields (agentskills.io Standard)

| Field | Required | Constraints |
|-------|----------|-------------|
| `name` | Yes | Max 64 chars. Lowercase letters, numbers, hyphens only. Must match parent directory name. No leading/trailing/consecutive hyphens. |
| `description` | Yes | Max 1024 chars. Non-empty. What it does + when to use it. No XML tags. |
| `license` | No | License name or reference to bundled file. |
| `compatibility` | No | Max 500 chars. Environment requirements. |
| `metadata` | No | Arbitrary key-value map (string to string). |
| `allowed-tools` | No | Space-delimited list of pre-approved tools. **Experimental.** |

These are the ONLY fields defined by the open standard. Everything else is a platform extension.

### 1.4 Progressive Disclosure (3 Levels)

| Level | What loads | When | Budget |
|-------|-----------|------|--------|
| **Metadata** | `name` + `description` | Always (at startup) | ~100 tokens |
| **Instructions** | Full SKILL.md body | On skill activation | <5000 tokens recommended |
| **Resources** | `scripts/`, `references/`, `assets/` | On demand (explicit read) | Unlimited |

Keep SKILL.md under 500 lines. Use references/ for overflow. Keep file references one level deep — avoid nested reference chains. For reference files >100 lines, include a table of contents at the top.

---

## 2. Platform-Specific Implementations

### 2.1 Claude Code

**Version context**: v2.1.69 (2026-03-05)

#### Discovery Paths

| Scope | Path |
|-------|------|
| Enterprise | Managed settings |
| Personal | `~/.claude/skills/<name>/SKILL.md` |
| Project | `.claude/skills/<name>/SKILL.md` |
| Plugin | `<plugin>/skills/<name>/SKILL.md` (namespaced as `plugin-name:skill-name`) |

Claude Code does **NOT** scan `.agents/skills/`. Only `.claude/skills/` paths.

Nested `.claude/skills/` directories in subdirectories are auto-discovered (monorepo support). Skills from `--add-dir` directories are also loaded.

#### Extension Frontmatter Fields

| Field | Description |
|-------|-------------|
| `disable-model-invocation` | `true` prevents Claude from auto-loading. Default: `false`. |
| `user-invocable` | `false` hides from `/` menu. Default: `true`. |
| `allowed-tools` | Pre-approved tools (space-delimited). Never include `AskUserQuestion`. |
| `model` | Override model when skill is active. |
| `context` | `fork` runs in isolated subagent context. |
| `agent` | Subagent type when `context: fork` (e.g., `Explore`, `Plan`, custom from `.claude/agents/`). |
| `argument-hint` | Hint shown during autocomplete (e.g., `[issue-number]`). |
| `hooks` | Hooks scoped to skill lifecycle. |

#### Invocation

| Configuration | User can invoke | Claude can invoke |
|--------------|----------------|-------------------|
| Default | Yes (slash command) | Yes (description match) |
| `disable-model-invocation: true` | Yes | No |
| `user-invocable: false` | No | Yes |

#### Variables

- `$ARGUMENTS` / `$ARGUMENTS[N]` / `$N` — user-provided arguments
- `${CLAUDE_SKILL_DIR}` — path to skill's own directory (v2.1.69+, portable)
- `${CLAUDE_SESSION_ID}` — current session ID
- `` !`command` `` — dynamic shell output injection (preprocessing)

#### Key Behaviors

- Description character budget scales at 2% of context window (fallback: 16,000 chars).
- Legacy `.claude/commands/<name>.md` files still work; skills take precedence on name conflict.
- Unknown frontmatter fields are silently ignored.
- "ultrathink" keyword anywhere in skill content enables extended thinking.

### 2.2 Codex CLI

**Version context**: v0.111.0 (2026-03-05), default model gpt-5.4

#### Discovery Paths (precedence order)

| Scope | Path |
|-------|------|
| Folder-specific | `$CWD/.agents/skills/` |
| Parent | `$CWD/../.agents/skills/` (walks up) |
| Repo root | `$REPO_ROOT/.agents/skills/` |
| User | `~/.codex/skills/`, `~/.agents/skills/` |
| Admin | `/etc/codex/skills/` |
| System | Bundled skills |

#### Invocation

- **Explicit**: `/skills` command or `$skill-name` mention
- **Implicit**: Auto-activates based on prompt-description matching. Controlled via `agents/openai.yaml` with `policy.allow_implicit_invocation: true|false`.

#### Extension: agents/openai.yaml Sidecar

Optional metadata file alongside SKILL.md:

```yaml
interface:
  display_name: "User-facing name"
  short_description: "Brief description"
  icon_small: "./assets/small-logo.svg"
  brand_color: "#3B82F6"
  default_prompt: "Surrounding context"
policy:
  allow_implicit_invocation: true
dependencies:
  tools:
    - type: "mcp"
      value: "toolName"
      description: "Tool description"
```

#### Relationship with AGENTS.md

AGENTS.md provides project-wide instructions (concatenated root-to-CWD). Skills provide modular, task-specific capabilities. AGENTS.md is governed by the Agentic AI Foundation (Linux Foundation); skills by the agentskills.io spec. Custom prompts are deprecated in favor of skills.

### 2.3 Gemini CLI

**Version context**: v0.32.1 (2026-03-04)

#### Discovery Paths

| Scope | Path | Notes |
|-------|------|-------|
| Workspace | `.agents/skills/` | Takes precedence |
| Workspace | `.gemini/skills/` | Fallback |
| User | `~/.agents/skills/` | Takes precedence |
| User | `~/.gemini/skills/` | Fallback |
| Extension | Bundled within installed extensions | Via `gemini-extension.json` |

#### Activation

Skills are activated via the `activate_skill` tool when a task matches the description. User consent is prompted before activation. Management commands: `/skills list`, `/skills enable/disable <name>`, `/skills link <path>`, `/skills reload`.

#### Subagents (Experimental)

Defined in `.gemini/agents/*.md` with YAML frontmatter (`name`, `description`, `kind`, `tools`, `model`, `temperature`, `max_turns`, `timeout_mins`). Requires `"experimental": { "enableAgents": true }` in settings.json.

#### Relationship with GEMINI.md

GEMINI.md provides persistent workspace-wide context (hierarchical, supports `@file.md` imports). Skills provide on-demand, task-specific expertise. Separate concepts.

#### Extensions Packaging

Gemini CLI bundles skills, agents, commands, MCP servers, hooks, themes, and policies into a single installable extension (`gemini-extension.json` manifest). Skills within extensions are auto-discovered.

---

## 3. Writing Cross-Platform Compatible Skills

### 3.1 The Portability Principle

The SKILL.md format is fully portable. The body content (Markdown instructions) works identically everywhere. The differences are in discovery paths and platform-specific frontmatter extensions.

### 3.2 Portable Frontmatter

Stick to the universal core for maximum compatibility:

```yaml
---
name: my-skill
description: Does X when Y. Use when the user asks about Z or needs to W.
---
```

Add platform-specific fields as needed — **all platforms silently ignore unknown frontmatter fields**. This means you can safely include Claude Code-specific fields like `context: fork` or `disable-model-invocation: true` in a skill that also runs on Codex/Gemini; they will simply be ignored.

### 3.3 Discovery Path Differences

| Platform | Primary project path | Scans `.agents/skills/`? |
|----------|---------------------|--------------------------|
| Claude Code | `.claude/skills/` | No |
| Codex CLI | `.agents/skills/` | Yes (primary) |
| Gemini CLI | `.gemini/skills/` | Yes (takes precedence) |
| Cursor | `.cursor/skills/` | Yes |
| VS Code/Copilot | `.github/skills/` | Yes |

**For maximum reach**: `.agents/skills/` covers Codex, Gemini, Cursor, and Copilot. Claude Code requires `.claude/skills/`. Options:
- Symlink between directories
- Use `npx skills` (skills.sh by Vercel) which auto-detects and installs to correct paths
- Maintain both directories in a project

### 3.4 Tool Name Abstraction

Do NOT reference platform-specific tool names if you want portability. Each platform maps natural-language instructions to its own tools.

| Instead of | Write |
|-----------|-------|
| "Use the Read tool to examine the file" | "Read the file at path/to/file" |
| "Use Bash to run the tests" | "Run the test suite" |
| "Use Glob to find matching files" | "Find all files matching the pattern `**/*.ts`" |

The skill body is natural language processed by the LLM — not a programmatic API. Trust the model to choose the right tool.

### 3.5 Additional Portability Rules

- **Forward slashes only** in all file paths. Windows backslashes break on Unix.
- **Scripts in Python or Bash** for maximum portability. Document dependencies explicitly.
- **Use `metadata` for platform hints** without polluting standard fields:
  ```yaml
  metadata:
    author: my-org
    version: "1.0"
  ```
- **Avoid time-sensitive information** in skill body (e.g., specific API versions that will change).
- **Use `${CLAUDE_SKILL_DIR}`** (Claude Code v2.1.69+) for self-referencing paths. Other platforms may have equivalents.

### 3.6 Distribution

- **skills.sh** (Vercel, launched 2026-01-20): `npx skills add <package>`. 44k+ skills. Auto-detects installed agents and routes to correct directories.
- **Plugin marketplace** (Claude Code): `plugin install <name>@<org>`.
- **Git-based** (Gemini CLI): `gemini extensions install <github-url>`.
- **Manual**: Copy skill directory to the platform-specific path.

---

## 4. Description Best Practices

The description field is the **single most important factor** in skill effectiveness. It determines whether the skill gets activated.

### 4.1 Core Rules

1. **Third person**: "Processes PDF files and generates reports" — not "I can help you process PDFs."
2. **What + When**: Include both what the skill does AND when to use it.
3. **Be pushy**: Models tend to undertrigger skills. Combat this: "Make sure to use this skill whenever the user mentions dashboards, data visualization, internal metrics, or wants to display any kind of data, even if they don't explicitly ask for a 'dashboard.'"
4. **5-10 concrete keyword phrases**: Better than 30 generic words. Include specific user phrases.
5. **Max 1024 characters**: Hard limit from the spec.
6. **No XML tags**: Prohibited by the spec.
7. **No reserved words**: "anthropic", "claude" are reserved (Claude Code specific).

### 4.2 Good vs Bad Descriptions

**Bad**: "Helps with documents" (too vague, no trigger context)

**Bad**: "I can format your spreadsheet data" (first person, vague)

**Good**: "Processes Excel spreadsheets (.xlsx, .xls) to add formulas, create charts, format cells, and generate pivot tables. Use this skill whenever the user mentions spreadsheets, Excel, CSV data analysis, profit margins, column calculations, or needs to transform tabular data, even if they don't explicitly say 'spreadsheet'."

### 4.3 Evaluation-Driven Optimization

1. Run Claude without the skill. Document where it fails or produces suboptimal results.
2. Create 3+ eval scenarios testing those gaps.
3. Write the skill. Run with-skill AND baseline tests.
4. Iterate: compare results, refine description and body.
5. For triggering accuracy: create 20 eval queries (10 should-trigger, 10 should-not-trigger). Focus on near-misses for negative cases — not obviously irrelevant queries.

---

## 5. SKILL.md Body Writing Guide

### 5.1 Core Principles

- **Concise is key**: Context window is a shared resource. Only add context the model doesn't already have.
- **Explain the why**: Models have good theory of mind. "Validate input before processing because the upstream API returns opaque 500 errors on malformed data" beats "ALWAYS validate input."
- **Appropriate freedom**: High freedom (text guidance) for context-dependent tasks. Low freedom (exact scripts) for fragile/critical operations.
- **Test with all target models**: Haiku needs more guidance; Opus needs less.

### 5.2 Structure Patterns

**Progressive disclosure**:
```
SKILL.md (high-level workflow, <500 lines)
├── references/detailed-guide.md (deep dive on specific topic)
├── references/api-docs.md (API reference)
└── scripts/validate.py (deterministic validation)
```

**Domain organization**:
```
SKILL.md (workflow + selection logic)
├── references/aws.md
├── references/gcp.md
└── references/azure.md
```
Claude reads only the relevant reference file based on context.

### 5.3 Instruction Patterns

**Imperative steps**:
```markdown
## Process
1. Read the input file
2. Validate the schema against references/schema.json
3. Transform the data...
```

**Template pattern**:
```markdown
## Output Format
Use this exact template:
# [Title]
## Summary
## Key Findings
## Recommendations
```

**Example pairs**:
```markdown
## Commit Message Format
Input: Added user authentication with JWT tokens
Output: feat(auth): implement JWT-based authentication
```

**Feedback loop**:
```markdown
## Validation Loop
1. Run the validator script
2. If errors found, fix them
3. Re-run validator
4. Repeat until clean
```

### 5.4 Anti-Patterns

- **Over-constraining**: Excessive MUST/NEVER/ALWAYS. Explain reasoning instead.
- **Voodoo constants**: Undocumented magic numbers or thresholds.
- **Deeply nested references**: Keep one level deep from SKILL.md.
- **Too many options**: Provide a default with an escape hatch.
- **Platform-specific tool names in body**: Use natural language instead (see 3.4).
- **Time-sensitive information**: Specific API versions, model names that will change.

---

## 6. Quick Reference: Portability Matrix

### 6.1 SKILL.md Support

| Feature | Standard | Claude Code | Codex | Gemini | Cursor | Copilot |
|---------|----------|-------------|-------|--------|--------|---------|
| SKILL.md format | agentskills.io | Yes | Yes | Yes | Yes | Yes |
| `name` field | Required | Optional* | Required | Required | Required | Required |
| `description` field | Required | Recommended* | Required | Required | Required | Required |
| `allowed-tools` | Experimental | Yes | Via sidecar | Ignored | Ignored | Ignored |
| Unknown fields | Ignore | Ignore | Ignore | Ignore | Ignore | Ignore |

*Claude Code falls back to directory name / first paragraph if omitted.

### 6.2 Discovery Paths

| Path | Claude Code | Codex | Gemini | Cursor | Copilot |
|------|-------------|-------|--------|--------|---------|
| `.claude/skills/` | Yes | No | No | No | Yes |
| `.agents/skills/` | **No** | Yes | Yes | Yes | Yes |
| `.gemini/skills/` | No | No | Yes | No | No |
| `.cursor/skills/` | No | No | No | Yes | No |
| `.github/skills/` | No | No | No | No | Yes |

### 6.3 Custom Instructions Files

| File | Claude Code | Codex | Gemini |
|------|-------------|-------|--------|
| `CLAUDE.md` | Yes (primary) | No | No |
| `AGENTS.md` | **No** | Yes (primary) | Yes (configurable) |
| `GEMINI.md` | No | No | Yes (primary) |

### 6.4 Platform Extension Fields (Claude Code)

| Field | Purpose | Other platforms |
|-------|---------|----------------|
| `disable-model-invocation` | Prevent auto-loading | VS Code/Copilot supports; others ignore |
| `user-invocable` | Hide from slash menu | VS Code/Copilot supports; others ignore |
| `context: fork` | Run in subagent | Ignored |
| `agent` | Subagent type | Ignored |
| `model` | Override model | Ignored |
| `argument-hint` | Autocomplete hint | VS Code/Copilot supports; others ignore |
| `hooks` | Lifecycle hooks | Ignored |

### 6.5 Agent/Subagent Definitions

| Aspect | Claude Code | Codex | Gemini |
|--------|-------------|-------|--------|
| Location | `.claude/agents/*.md` | `config.toml [agents]` | `.gemini/agents/*.md` |
| Format | YAML frontmatter + Markdown | TOML config | YAML frontmatter + Markdown |
| Status | Stable | Stable | Experimental |
| Dispatch | `Agent` tool | Built-in spawning | Auto-delegation |
| Parallel | Unlimited | `max_threads` (default 6) | `max_turns` per agent |
