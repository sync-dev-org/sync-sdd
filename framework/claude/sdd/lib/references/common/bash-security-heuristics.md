# Bash Security Heuristics Guide

Claude Code applies security heuristics to Bash commands **before** checking `settings.json` allow patterns. These heuristics cannot be bypassed by allow-list registration.

> Verified against Claude Code v2.1.72 (2026-03-10). Full test cases: `lib/references/common/bash-security-heuristics-sources.md`

## Three Types of Approval Prompts

| Type | Options | Resolution | Suppressible |
|------|---------|------------|-------------|
| **HEURISTIC** | Yes / No (2択) | Avoid the pattern entirely | No |
| **ALLOW** | Yes / Yes, and don't ask again / No (3択) | Register in `settings.json` | Yes |
| **ALLOW (repeating)** | 3択だが登録済みでも毎回出る | Avoid the pattern or use helper script | No |

## Security Heuristic Patterns (HEURISTIC)

These patterns trigger 2-option approval prompts regardless of `settings.json` configuration.

### Command Substitution

| Pattern | Detection Message | Workaround |
|---------|------------------|------------|
| `$()` command substitution | "Command contains $() command substitution" | Use single quotes: `echo '$(date)'` |
| `` ` ` `` backtick substitution | "Command contains backticks for command substitution" | Use single quotes |
| `${}` parameter substitution | "Command contains ${} parameter substitution" | Use `$VAR` (no braces) or `printenv VAR` |

**Key behaviors:**
- Escaped forms `\$()` and `\${}` are **still detected** — escaping does not help
- Single quotes suppress `$()` and `${}` detection: `echo '$(date)'` → OK
- `$VAR` without braces is always OK regardless of quoting: `echo "$HOME"` → OK

### Process Substitution

| Pattern | Detection Message | Workaround |
|---------|------------------|------------|
| `<()` process substitution | "Command contains process substitution <()" | Use temp files or dedicated tools |

**Key behavior:** Single quotes do **NOT** suppress `<()` detection (unlike `$()`): `echo '<(foo)'` → still HEURISTIC

### Shell Operators

| Pattern | Detection Message | Workaround |
|---------|------------------|------------|
| `()` subshell | "shell operators that require approval for safety" | Avoid subshells |
| `&` background | "shell operators that require approval for safety" | Use `Bash(run_in_background=true)` |
| `<` stdin redirect | "input redirection (<) which could read sensitive files" | Use Read tool or command arguments |
| `&>` both redirect | "output redirection (>) which could write to arbitrary files" | Use `>` and `2>` separately |
| `>&` redirect | "output redirection (>) which could write to arbitrary files" | Same as above |

**Not HEURISTIC (formerly misclassified):**
- `2>` stderr redirect → **NOT a heuristic trigger**. Project-internal `2>/dev/null` is AUTO. Previously misattributed due to external path detection (see External Path Access)
- `>` stdout redirect → AUTO for project-internal paths
- `>>` append redirect → AUTO for project-internal paths
- `1>` explicit fd1 → AUTO
- `2>&1` → AUTO
- Parentheses/ampersand in strings → AUTO: `echo "(test)"`, `echo "test &"` are fine

### Heredoc

| Pattern | Detection Message | Workaround |
|---------|------------------|------------|
| `<<EOF` (unquoted delimiter) | "Command contains newlines that could separate multiple commands" | Use `<<'EOF'` or `<<"EOF"` (quoted delimiter) |

**Key behaviors:**
- Quoted delimiters (`<<'EOF'`, `<<"EOF"`) are **AUTO** — no prompt at all
- Plain newlines without heredoc syntax are also AUTO: multiline `echo` commands work fine
- Previously documented as "allow pattern miss" — this is **incorrect**; quoted heredocs are fully AUTO

### Compound Commands + Quoted Dashes

| Pattern | Detection Message | Workaround |
|---------|------------------|------------|
| `&&` / `;` / `\|\|` + quoted string containing `-` | "Command contains quoted characters in flag names" | Remove quotes from dash strings, or use parallel Bash calls |

**Key behaviors:**
- ALL compound operators trigger this: `&&`, `;`, **and** `||` (previously `||` was documented as safe — this is **incorrect**)
- Both single and double quotes trigger: `echo '-'` and `echo "-"` are both detected
- Unquoted dashes are OK: `date && echo ---` → AUTO
- Single commands are OK: `echo "-"` alone → AUTO

### External Path Access

| Path type | Result | Message |
|-----------|--------|---------|
| Non-existent external path (`/nonexistent`) | HEURISTIC (2択) | (no message, bare prompt) |
| Existing external path (`/tmp`, `/usr/bin/git`) | ALLOW (3択) | "allow reading from ..." |
| Project-internal path (relative or absolute) | AUTO | |

**Key behaviors:**
- This applies to command **arguments**, not redirect targets
- `/dev/null` is special-cased for **redirects only**: `> /dev/null` → AUTO, but `cat /dev/null` → ALLOW
- External path redirect: `> /tmp/file` → ALLOW, `> /dev/null` → AUTO

### `[[ ]]` Test Syntax

| Pattern | Detection Message | Workaround |
|---------|------------------|------------|
| `[[ ... ]]` | "ambiguous syntax with command separators that could be misinterpreted" | Use `test` command instead |

`test -f file && echo exists` → AUTO. `[[ -f file ]] && echo exists` → HEURISTIC.

### Multiple Triggers (Priority)

When multiple HEURISTIC patterns exist in one command, only one message is shown. Observed priority order:

1. Quoted characters in flag names (highest)
2. `$()` command substitution
3. Shell operators / stdin redirect (lowest)

## Allow Pattern Behavior (ALLOW)

### `#{}` Breaks Allow Pattern Matching

`#{}` in tmux format strings causes registered `tmux *` patterns to stop matching. This is **not** `${}` misdetection — the allow pattern matching itself breaks.

```bash
tmux display-message -p 'hello'       # OK — tmux * matches
tmux display-message -p '#{pane_id}'  # NG — tmux * no longer matches
# Fix: use helper script to isolate #{} format strings
```

### awk `$N` — Repeating ALLOW

`$N` field references in awk trigger ALLOW prompts **every time**, even with `Bash(awk *)` registered. The prompt cannot be suppressed.

```bash
awk '{print $2}' file     # NG — repeating prompt (Shell expansion syntax)
awk '{print NR}' file     # OK — no $ reference
cut -d' ' -f2             # OK — alternative
```

### Pipe Commands

Pipes check **each command individually** against the allow list.

```bash
echo "test" | grep test    # OK — both registered
echo "test" | sort         # OK — sort is auto-allowed
```

### Control Structures

`if/then/fi`, `for/do/done`, `while/do/done` → ALLOW (allow pattern is the full command string, not generalizable). Use dedicated tools or helper scripts.

### Environment Variable Prefix

`VAR=value command` → ALLOW (VAR is treated as the command name). Fix: prefix with `env`.

```bash
FOO=bar ls .          # NG — "FOO" is the command name
env FOO=bar ls .      # OK — "env *" matches
```

### Shell Builtins

`eval`, `export`, `source` → ALLOW. Register in `settings.json` if needed. `printf` is AUTO (no registration needed).

## Command-Specific Examples

### git

```bash
# OK
git commit -m "message"
git log --oneline -5
git log --format="%H %s" -3

# NG — $() substitution
git commit -m "$(cat file)"
# Fix: git commit -m "message directly"

# NG — && + quoted dash
git status && echo "---"
# Fix: run as separate Bash calls, or: git status && echo done
```

### tmux

```bash
# OK
tmux select-pane -T 'title'
tmux list-panes              # no -F flag
printenv TMUX_PANE

# NG — #{} breaks allow pattern
tmux display-message -p '#{pane_id}'
tmux list-panes -F '#{pane_id}'
# Fix: use helper script to isolate #{} format strings
```

### Redirects

```bash
# OK — project-internal redirects
echo x > .sdd/file.txt
echo x >> .sdd/file.txt
echo x 1> .sdd/file.txt
echo x 2> .sdd/file.txt       # 2> is fine for project paths!
echo x 2>&1
echo x > /dev/null             # /dev/null is special-cased

# NG — &> and >&
echo x &> file.txt             # HEURISTIC
echo x >& file.txt             # HEURISTIC

# NG — external path redirects
echo x > /tmp/file.txt         # ALLOW (external path)
```

## Recommended settings.json Allow List

Essential commands for SDD framework operation:

```json
"Bash(git *)", "Bash(mkdir *)", "Bash(ls *)", "Bash(mv *)",
"Bash(cp *)", "Bash(wc *)", "Bash(which *)", "Bash(sed *)",
"Bash(cat *)", "Bash(echo *)", "Bash(curl *)", "Bash(diff *)",
"Bash(tmux *)", "Bash(npm *)", "Bash(npx *)", "Bash(date *)",
"Bash(ps *)", "Bash(pgrep *)", "Bash(grep *)", "Bash(lsof *)",
"Bash(sleep *)", "Bash(rm *)", "Bash(printenv *)", "Bash(jq *)",
"Bash(env *)", "Bash(kill *)", "Bash(chmod *)",
"Bash(awk *)", "Bash(tee *)", "Bash(printf *)", "Bash(gh *)", "Bash(uv *)",
"Bash(bash install.sh *)", "Bash(bash .sdd/settings/scripts/*)"
```

## Summary: Decision Tree

```
Is the command blocked?
├── Yes/No only (2 options)?
│   └── HEURISTIC. Must restructure the command. Cannot be suppressed.
├── Yes/Yes, and don't ask again/No (3 options)?
│   ├── Does it keep appearing after registration?
│   │   └── ALLOW (repeating). Use alternative approach or helper script.
│   └── Otherwise
│       └── ALLOW. Register command in settings.json.
└── No prompt at all
    └── AUTO. No action needed.
```

## Maintaining This Guide

When a new pattern is discovered:
1. Record as an issue in `issues.yaml`
2. Add a test case to `bash-security-heuristics-sources.md`
3. Run the test and record the result
4. Update this guide based on verified results
5. Update CLAUDE.md summary if the pattern is common enough
