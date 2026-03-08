# shared-prompt.md Structure

The Briefer writes this file to `active/shared-prompt.md`. It is prepended to every Inspector prompt via `cat shared-prompt.md inspector-{name}.md`.

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

## PROHIBITED COMMANDS (MUST NEVER execute)
{deny_patterns — one pattern per line, from engines.yaml}
```
