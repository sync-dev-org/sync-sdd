## Target Files
framework/claude/CLAUDE.md
framework/claude/skills/sdd-publish-setup/SKILL.md
framework/claude/skills/sdd-forge-skill/SKILL.md
framework/claude/skills/sdd-log/SKILL.md
framework/claude/skills/sdd-status/SKILL.md
framework/claude/skills/sdd-start/SKILL.md
framework/claude/skills/sdd-steering/SKILL.md
framework/claude/skills/sdd-reboot/SKILL.md
framework/claude/skills/sdd-release/SKILL.md
framework/claude/skills/sdd-roadmap/SKILL.md
framework/claude/skills/sdd-review/SKILL.md
framework/claude/skills/sdd-handover/SKILL.md
framework/claude/skills/sdd-review-self/SKILL.md
framework/claude/skills/sdd-forge-skill/references/skill-reference.md
framework/claude/skills/sdd-forge-skill/references/skill-reference-sources.md
framework/claude/skills/sdd-forge-skill/references/comparator.md
framework/claude/skills/sdd-forge-skill/references/analyzer.md
framework/claude/skills/sdd-forge-skill/references/grader.md
framework/claude/skills/sdd-forge-skill/references/schemas.md
framework/claude/skills/sdd-forge-skill/references/writer.md
framework/claude/skills/sdd-review-self/references/inspector-flow.md
framework/claude/skills/sdd-review-self/references/inspector-consistency.md
framework/claude/skills/sdd-review-self/references/inspector-compliance.md
framework/claude/skills/sdd-review-self/references/auditor.md
framework/claude/skills/sdd-review-self/references/shared-prompt-structure.md
framework/claude/skills/sdd-review-self/references/briefer.md
framework/claude/agents/sdd-analyst.md
framework/claude/agents/sdd-builder.md
framework/claude/agents/sdd-conventions-scanner.md
framework/claude/agents/sdd-taskgenerator.md
framework/claude/agents/sdd-architect.md
framework/claude/settings.json
framework/claude/sdd/settings/rules/agent/tasks-generation.md
framework/claude/sdd/settings/rules/agent/steering-principles.md
framework/claude/sdd/settings/rules/agent/design-principles.md
framework/claude/sdd/settings/rules/agent/design-discovery-full.md
framework/claude/sdd/settings/rules/agent/design-discovery-light.md
framework/claude/sdd/settings/rules/agent/design-review.md
framework/claude/sdd/settings/rules/lead/tmux-integration.md
framework/claude/sdd/settings/rules/agent/verdict-format.md
framework/claude/sdd/settings/rules/lead/bash-security-heuristics.md
framework/claude/sdd/settings/templates/specs/research.md
framework/claude/sdd/settings/templates/steering-custom/api-standards.md
framework/claude/sdd/settings/templates/steering-custom/deployment.md
framework/claude/sdd/settings/templates/steering-custom/database.md
framework/claude/sdd/settings/templates/steering/structure.md
framework/claude/sdd/settings/templates/steering-custom/authentication.md
framework/claude/sdd/settings/templates/steering-custom/security.md
framework/claude/sdd/settings/templates/steering-custom/error-handling.md
framework/claude/sdd/settings/templates/steering/product.md
framework/claude/sdd/settings/templates/steering-custom/testing.md
framework/claude/sdd/settings/templates/reboot/analysis-report.md
framework/claude/sdd/settings/templates/steering/tech.md
framework/claude/sdd/settings/templates/specs/design.md
framework/claude/sdd/settings/templates/steering-custom/ui.md
framework/claude/sdd/settings/templates/review-self/builder.md
framework/claude/sdd/settings/templates/review/auditor.md
framework/claude/sdd/settings/templates/review/inspector-impl-e2e.md
framework/claude/sdd/settings/templates/review/inspector-design-best-practices.md
framework/claude/sdd/settings/templates/review/inspector-impl-test.md
framework/claude/sdd/settings/templates/review/inspector-impl-quality.md
framework/claude/sdd/settings/templates/review/inspector-impl-consistency.md
framework/claude/sdd/settings/templates/review/inspector-design-architecture.md
framework/claude/sdd/settings/templates/review/inspector-design-consistency.md
framework/claude/sdd/settings/templates/review/inspector-impl-web-e2e.md
framework/claude/sdd/settings/templates/review/inspector-impl-interface.md
framework/claude/sdd/settings/templates/review/inspector-impl-rulebase.md
framework/claude/sdd/settings/templates/review/inspector-dead-code.md
framework/claude/sdd/settings/templates/review/inspector-dead-settings.md
framework/claude/sdd/settings/templates/review/inspector-dead-specs.md
framework/claude/sdd/settings/templates/review/inspector-dead-tests.md
framework/claude/sdd/settings/templates/review/briefer.md
framework/claude/sdd/settings/templates/review/inspector-impl-web-visual.md
framework/claude/sdd/settings/templates/review/auditor-brief.md
framework/claude/sdd/settings/templates/review/inspector-brief.md
framework/claude/sdd/settings/templates/review-self/inspector-flow.md
framework/claude/sdd/settings/templates/review-self/inspector-consistency.md
framework/claude/sdd/settings/templates/review-self/inspector-compliance.md
framework/claude/sdd/settings/templates/review-self/briefer.md
framework/claude/sdd/settings/templates/wave-context/conventions-brief.md
framework/claude/sdd/settings/templates/review-self/auditor.md
framework/claude/sdd/settings/templates/review/inspector-design-rulebase.md
framework/claude/sdd/settings/templates/review/inspector-design-testability.md
framework/claude/sdd/settings/templates/session/handover.md
framework/claude/sdd/settings/templates/specs/init.yaml
framework/claude/sdd/settings/templates/session/decisions.yaml
framework/claude/sdd/settings/templates/session/knowledge.yaml
framework/claude/sdd/settings/templates/session/issues.yaml
framework/claude/sdd/settings/scripts/claude-stream-progress.jq
framework/claude/sdd/settings/scripts/grid-check.sh
framework/claude/sdd/settings/scripts/ensure-playwright-cli.sh
framework/claude/sdd/settings/scripts/orphan-detect.sh
framework/claude/sdd/settings/scripts/multiview-grid.sh
framework/claude/sdd/settings/scripts/orphan-kill.sh
framework/claude/sdd/settings/scripts/window-id.sh
install.sh

## YAML Output Format
Write findings in YAML format:
```yaml
scope: "{inspector-name}"
issues:
  - id: "F1"
    severity: "H"
    category: "{category}"
    location: "{file}:{line}"
    summary: "{one-line summary}"
    detail: "{what}"
    impact: "{why}"
    recommendation: "{how}"
notes: |
  Additional context
```
- Severity codes: C=Critical, H=High, M=Medium, L=Low
- Report ALL severity levels including LOW. A review with zero LOW findings is suspicious — verify you haven't self-filtered.
- `issues`: empty list `[]` if no findings

Report findings in Japanese.

## Claude Code Bash Security Heuristics

The SDD framework intentionally uses Bash patterns that work around Claude Code's security heuristic detection. These are NOT bugs — do NOT flag them as issues.

# Bash Security Heuristics Guide

Claude Code applies security heuristics to Bash commands **before** checking `settings.json` allow patterns. These heuristics cannot be bypassed by allow-list registration.

## Two Types of Approval Prompts

| Type | Message | Option 2 | Resolution |
|------|---------|----------|------------|
| **Security heuristic** | "...requires approval for safety" or specific detection message | No (only Yes/No) | Avoid the pattern entirely |
| **Allow pattern miss** | "This command requires approval" | "Yes, and don't ask again for: ..." | Register in `settings.json` |

## Security Heuristic Patterns (Unavoidable)

These patterns trigger approval prompts regardless of `settings.json` configuration.

### Shell Expansion / Substitution

| Pattern | Detection Message | Example |
|---------|------------------|---------|
| `$()` command substitution | "Command contains $() command substitution" | `echo "$(date)"` |
| `${}` parameter substitution | "Command contains ${} parameter substitution" | `echo "${HOME}"` |
| `#{}` in strings | Misdetected as `${}` | `tmux display-message -p '#{pane_id}'` |
| `<()` process substitution | "Command contains process substitution <()" | `diff <(echo a) <(echo b)` |

**OK alternatives:**
- `$VAR` without braces: `echo "$HOME"` — OK
- `printenv VAR`: `printenv HOME` — OK
- Backticks: `` echo `date` `` — OK
- Helper scripts: isolate `#{}` tmux formats into `.sh` scripts

### Shell Operators

| Pattern | Detection Message | Example |
|---------|------------------|---------|
| `()` subshell | "shell operators that require approval for safety" | `(echo hello)` |
| `&` background | "shell operators that require approval for safety" | `sleep 0 &` |
| `<` stdin redirect | "shell operators that require approval for safety" | `xargs echo < /dev/null` |
| `2>` stderr redirect | "shell operators that require approval for safety" | `ls /bad 2>/dev/null` |
| `<<EOF` heredoc (unquoted) | "shell operators that require approval for safety" | `cat <<EOF ... EOF` |

**OK alternatives:**
- `>` stdout redirect (project-internal): `echo x > .sdd/file.txt` — OK
- `>>` append redirect (project-internal): `echo x >> .sdd/file.txt` — OK
- Background: use `Bash(run_in_background=true)` parameter instead of `&`
- Heredoc: avoid entirely; use Write tool or `echo "content"` instead
- stderr: omit `2>/dev/null`, tolerate error output

### Compound Commands + Quoted Dashes

| Pattern | Detection Message | Example |
|---------|------------------|---------|
| `&&` or `;` + quoted string containing `-` | "Command contains quoted characters in flag names" | `date; echo "---"` |

The heuristic detects dash characters inside quoted strings in multi-command contexts, interpreting them as potential flag injection.

**OK alternatives:**
- Remove quotes: `date; echo ---` — OK
- Remove dash from string: `date && echo "done"` — OK
- Single command: `echo "-"` alone — OK
- Use `||` instead (not affected): `false || echo "---"` — OK
- Run as parallel Bash tool calls instead of chaining

### awk with Field References

| Pattern | Detection Message | Example |
|---------|------------------|---------|
| `$N` inside awk | Triggers approval (file access prompt) | `awk '{print $2}'` |

Even inside single quotes, `$N` patterns in awk trigger detection. This occurs even when `awk` is in the allow list.

**OK alternatives:**
- awk without `$`: `awk '{print NR}'` — OK
- Use `cut -d' ' -f2` instead of `awk '{print $2}'`
- Use Grep tool for content extraction

## Allow Pattern Behavior

### Pipe Commands

Pipes (`|`) check **each command individually** against the allow list, not just the first command. Both the source and destination commands must be registered.

```
echo "test" | grep test    # OK — both echo and grep in allow list
echo "test" | awk '{...}'  # NG — awk not in allow list (until registered)
```

**Common pipe destinations to register:** `awk`, `tee`, `printf`, `gh`, `base64`, `xargs`

### Heredoc

Heredoc syntax (`<<'EOF'`) breaks allow pattern matching even for registered commands. `cat` is in the allow list, but `cat <<'EOF' ... EOF` triggers an approval prompt for `cat:*`.

**Workaround:** Avoid heredoc. Use Write tool or direct string arguments.

### Control Structures

`if/then/fi`, `for/do/done`, `while/do/done`, `[[ ]]` — all trigger approval prompts because the compound command structure doesn't match simple `command *` allow patterns.

**Workaround:** Avoid shell control structures. Use dedicated tools (Glob, Grep, Read) or helper scripts.

### Environment Variable Prefix

`VAR=value command args` syntax causes the allow pattern to match `VAR` as the command name, not `command`.

```
PYTHONPATH=path uv run ...    # NG — matches "PYTHONPATH", not "uv"
env PYTHONPATH=path uv run ... # OK — matches "env *"
```

**Workaround:** Prefix with `env` to route through `Bash(env *)` allow pattern.

### Other Unregistered Commands

`eval`, `export`, `source`, `printf` — trigger approval unless registered. Register in `settings.json` if needed.

## PROHIBITED COMMANDS (MUST NEVER execute)
rm -rf /
rm -rf ~
rm -rf .
rm -rf *
git push --force
git push -f
git reset --hard
shutdown
reboot
> /dev/
mkfs
dd if=
:(){:|:&};:
