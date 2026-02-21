---
description: Check progress and analyze downstream impact
allowed-tools: Read, Glob, Grep
argument-hint: [feature-name] [--impact]
---

# SDD Status (Unified)

<instructions>

## Core Task

Display comprehensive status for specifications and optionally analyze downstream impact of changes. Lead handles directly (read-only, no teammate needed).

## Step 1: Parse Arguments

```
$ARGUMENTS = ""                    → Overall roadmap + all specs progress
$ARGUMENTS = "{feature}"           → Individual spec status
$ARGUMENTS = "{feature} --impact"  → Individual spec status + downstream impact analysis
$ARGUMENTS = "--impact {feature}"  → Same as above
```

## Step 2: Load Context

1. Read `{{SDD_DIR}}/project/specs/roadmap.md` (if exists)
2. Scan `{{SDD_DIR}}/project/specs/*/spec.yaml` for all specs

## Step 3: Generate Report

### Overall Progress (always shown)

For each wave in roadmap:
- Wave completion percentage
- Specs in each phase (design-generated / implementation-complete / blocked)
- Blocked specs with `blocked_info` details (blocked_by, reason)

### Individual Spec Status (when feature specified)

- Current phase and version
- Design status (exists, version)
- Tasks status (parse tasks.yaml: total, done, pending, optional)
- Implementation status (files created, test results)
- Version alignment check (design ↔ impl ↔ version_refs)
- **Change history**: Display latest 5 entries from `spec.yaml.changelog` (version, action, timestamp)
- **Review history**: If `verdicts.md` exists, display per batch: B{seq}, review-type, date, runs, verdict/consensus-verdict, tracked open count

### Impact Analysis (when `--impact` flag)

1. Build dependency graph from roadmap (forward and reverse maps)
2. Identify changes in target spec (changelog, version bumps)
3. Classify change stability: BREAKING / INTERFACE / COMPATIBLE / UNKNOWN
4. Trace downstream impact:
   - For each dependent spec: check version alignment, design references
   - Identify specs that need re-review or re-implementation
5. Generate impact report with action recommendations

## Step 4: Display

Format as human-readable markdown report.

</instructions>

## Error Handling

- **No specs found**: "No specs found. Run `/sdd-roadmap design \"description\"` to create."
- **Feature not found**: "Spec '{feature}' not found."
- **No roadmap**: Show individual spec statuses without wave context
