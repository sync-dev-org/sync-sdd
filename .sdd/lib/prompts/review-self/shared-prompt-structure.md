# shared-prompt.md Structure

The Briefer writes this file to `active/shared-prompt.md`. It is delivered to each Inspector in one of two ways depending on the dispatch mode:
- **tmux/background mode**: prepended via `cat shared-prompt.md inspector-{name}.md | {engine_cmd}`
- **SubAgent mode**: Inspector reads `shared-prompt.md` and its own prompt file as two separate Read operations

## Template

```
## Target Files
{FILE_LIST — one file path per line, collected by Briefer Step 2}

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

Read `.sdd/lib/references/bash-security-heuristics.md` for the full list of known heuristic patterns and their workarounds.

## PROHIBITED COMMANDS (MUST NEVER execute)

Read the `deny_patterns` section from `.sdd/settings/engines.yaml` for the list of prohibited commands.
```
