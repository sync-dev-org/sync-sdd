---
description: Analyze downstream impact of spec changes across the dependency graph
allowed-tools: Read, Glob, Grep, AskUserQuestion
argument-hint: <feature-name>
---

# SDD Impact Analysis

<background_information>
- **Mission**: Analyze downstream effects of changes to a feature's spec across the dependency graph
- **Prerequisite**: roadmap.md must exist with dependency information; versioning (spec.json version/changelog) recommended
- **Success Criteria**:
  - Identify all directly and transitively affected specs
  - Classify impact severity using stability tags and version_refs
  - Provide actionable recommendations for each affected spec
</background_information>

<instructions>

## Core Task
Analyze the downstream impact of recent changes to feature **$1**'s specification.

## Execution Steps

### Step 1: Load Context

1. **Read target spec**:
   - `{{KIRO_DIR}}/specs/$1/spec.json` — version, changelog, version_refs, roadmap metadata
   - `{{KIRO_DIR}}/specs/$1/requirements.md` — current requirements with stability tags

2. **Read roadmap**:
   - `{{KIRO_DIR}}/specs/roadmap.md` — dependency graph and wave structure
   - If roadmap.md does not exist: Report "No roadmap found. Impact analysis requires `/sdd-roadmap` to be configured." and stop.

3. **Read all specs**:
   - Glob `{{KIRO_DIR}}/specs/*/spec.json` to load all spec metadata

### Step 2: Build Dependency Graph

1. **Parse roadmap.md** for spec dependencies (from Wave structure and dependency sections)
2. **Build forward dependency map**: spec → depends_on (what this spec needs)
3. **Build reverse dependency map**: spec → depended_on_by (what specs depend on this one)
4. If target spec has no downstream dependents, report: "No downstream specs depend on {feature}." and stop.

### Step 3: Identify Changes

1. **Read spec.json changelog** for recent changes to the target feature
   - If no changelog or version fields: Report "Version tracking not available for {feature}. Run `/sdd-requirements {feature}` to initialize." — proceed with limited analysis.
2. **Identify changed requirements** from changelog entries (especially `affected_requirements` field if present)
3. **Classify change severity** using stability tags from requirements.md:
   - `[constraint]` change → **BREAKING** (all downstream affected, full re-review required)
   - `[contract]` change → **INTERFACE** (design-level downstream affected)
   - `[behavior]` change → **COMPATIBLE** (minimal downstream impact)
   - No stability tags → **UNKNOWN** (cannot determine without manual review)

### Step 4: Trace Impact

For each downstream spec (from reverse dependency map):

1. **Check version alignment**:
   - Read downstream spec's `version_refs` — does its design/tasks reference the target spec's pre-change version?
   - If version_refs show the downstream spec was generated before the target's change: mark as **potentially stale**

2. **Check design references**:
   - Read downstream spec's `design.md` (if exists)
   - Grep for references to the changed feature's components, interfaces, or data models
   - If references found to changed elements: impact confirmed

3. **Classify impact per downstream spec**:
   - **BREAKING**: Downstream spec's design relies on a changed `[constraint]`
   - **INTERFACE**: Downstream spec references changed `[contract]` elements
   - **COMPATIBLE**: Only `[behavior]` changes, downstream unaffected
   - **UNKNOWN**: Cannot determine (no stability tags, no clear references)

4. **Traverse transitively**: If this downstream spec is also a dependency for others, continue tracing with accumulated impact level

### Step 5: Generate Report

Present report in the language specified in spec.json:

```
## Impact Analysis: {feature}

### Change Summary
- Feature: {feature}
- Current version: v{version}
- Changes: {changelog summary}

### Impact Summary

| Spec | Wave | Impact | Stale? | Action Needed |
|------|------|--------|--------|---------------|
| spec-a | 2 | BREAKING | Yes | Re-review requirements, re-generate design and tasks |
| spec-b | 3 | INTERFACE | Yes | Re-generate design |
| spec-c | 3 | COMPATIBLE | No | No action required |
| spec-d | 4 | UNKNOWN | - | Manual review recommended |

### Directly Affected (first-order)
{list with details}

### Transitively Affected (second+ order)
{list with details}

### Recommended Next Steps
1. {ordered action items}
```

</instructions>

## Tool Guidance
- **Read**: All spec files, roadmap, requirements
- **Glob**: Discover all specs
- **Grep**: Search for cross-references in design files
- **AskUserQuestion**: Clarify scope if changelog is ambiguous

## Output Description

Provide impact analysis report in the language specified in spec.json:
1. **Change Summary**: What changed in the target feature
2. **Impact Summary Table**: All affected specs with classification
3. **Detailed Impact**: Per-spec breakdown with specific affected elements
4. **Recommended Actions**: Prioritized list of next steps

**Format**: Structured markdown with tables for quick scanning

## Safety & Fallback

### Error Scenarios

**No roadmap.md**:
- "No roadmap found. Impact analysis requires `/sdd-roadmap` to be configured."
- Stop execution.

**No version/changelog fields**:
- "Version tracking not available for {feature}. Proceeding with limited analysis based on dependency graph only."
- Skip changelog-based analysis, rely on Grep-based reference detection.

**No downstream dependencies**:
- "No downstream specs depend on {feature}. No impact analysis needed."
- Stop execution.

**No stability tags**:
- All impact classifications default to UNKNOWN.
- Recommend: "Add stability tags (`[constraint]`, `[contract]`, `[behavior]`) to requirements for more precise impact analysis."
