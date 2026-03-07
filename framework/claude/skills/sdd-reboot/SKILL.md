---
description: Reboot project design from zero (analysis, steering reform, new roadmap + specs on feature branch)
allowed-tools: Agent, Bash, Glob, Grep, Read, Write, Edit
argument-hint: [name] [-y]
---

# SDD Reboot

<instructions>

## Core Task

Zero-based redesign of a project. Analyzes the codebase holistically, proposes new steering + spec decomposition + wave structure, runs the design pipeline (with auto-review), and presents results for user approval. All work happens on a `reboot/{name}` branch. Never auto-merges.

## Step 1: Parse Arguments

```
$ARGUMENTS = ""                    → Interactive mode (branch: reboot/{YYYY-MM-DD})
$ARGUMENTS = "{name}"              → Named branch (branch: reboot/{name})
$ARGUMENTS = "-y"                  → Auto-approve analysis (branch: reboot/{YYYY-MM-DD})
$ARGUMENTS = "{name} -y"           → Named branch + auto-approve
```

Extract:
- `branch_name`: from first non-flag argument, or today's date
- `auto_approve`: true if `-y` present
- `user_instructions`: any remaining text after name and flags

## Step 2: Execute

Read and follow `refs/reboot.md` for the complete 10-phase execution:

1. **Pre-Flight**: Clean tree, main branch, codebase check, input state detection
2. **Branch Setup**: Create `reboot/{branch_name}`
3. **Setup**: Create output directory (ConventionsScanner is NOT dispatched — zero-based redesign)
4. **Deep Analysis**: Dispatch Analyst (zero-based, no old specs, no conventions brief)
5. **User Review**: Select architecture alternative, approve/modify/abort (skip if `-y`)
6. **Roadmap Regeneration**: Archive old specs → delete → create new specs + roadmap
7. **Design Pipeline**: Architect + Design Review per wave (design-only, no impl)
8. **Regression Check**: Compare old vs new capabilities (if old specs existed)
9. **Final Report & User Decision**: Present report, user chooses Accept/Iterate/Reject
10. **Post-Completion**: Commit on branch (only if accepted). Never auto-merges.

## Error Handling

| Error | Response |
|-------|----------|
| Dirty working tree | BLOCK: "Uncommitted changes. Commit or stash first." |
| Not on main | BLOCK: "Switch to main: `git checkout main`" |
| No source code | BLOCK: "No source code found. Nothing to reboot." |
| Existing reboot branch | Ask: Resume / Delete & restart / Abort |
| Analyst failure | Retry once. Second failure → delete branch, return to main, report error |
| Design Review exhaustion | Escalate to user: fix / skip / abort |
| User chooses Iterate (Phase 9) | Skill terminates. User edits on branch. Re-run `/sdd-reboot` to resume |
| User aborts at Phase 5 | Return to main, delete branch, record decision in decisions.yaml |

</instructions>
