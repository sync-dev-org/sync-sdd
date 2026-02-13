---
description: Sync roadmap with current spec states, analyze impact on existing work
allowed-tools: Glob, Grep, Read, Write, Edit, AskUserQuestion
argument-hint: ""
---

# Update Roadmap to Match Spec States

<background_information>
- **Mission**: Synchronize roadmap.md with actual spec states, identify and report rework impact
- **Prerequisite**: roadmap.md must exist
- **Key responsibility**: Protect existing work by analyzing impact before changes
</background_information>

<instructions>

## Execution Flow

### Step 1: Load Current State

1. **Read roadmap.md**:
   - Parse Wave structure
   - Extract spec list with wave assignments
   - Note dependencies

2. **Scan actual specs**:
   - Glob `{{SDD_DIR}}/project/specs/*/`
   - For each spec directory, read:
     - `spec.json` (phase, roadmap metadata)
     - `design.md` (exists? content hash, Specifications section)
     - `tasks.md` (exists? completion status)
   - Note any directories not in roadmap

3. **Read steering documents**:
   - Check if steering has changed since roadmap creation
   - Note any new capabilities or structure changes

### Step 2: Analyze Differences

Build comprehensive diff report:

#### 2.1 Structural Differences

| Type | Description |
|------|-------------|
| **Missing Spec** | In roadmap but no directory exists |
| **Extra Spec** | Directory exists but not in roadmap |
| **Wave Mismatch** | spec.json wave differs from roadmap |
| **Dependency Change** | spec.json dependencies differ from roadmap |
| **Phase Mismatch** | spec.json phase doesn't match expected progress |

#### 2.2 Content Differences

| Type | Description |
|------|-------------|
| **Specifications Changed** | design.md Specifications section modified after tasks generated |
| **Design Changed** | design.md design sections modified after tasks generated |
| **Scope Expansion** | New specs added to existing feature |
| **Scope Reduction** | Specs removed from existing feature |

### Step 3: Impact Analysis

For each difference, analyze downstream impact:

#### 3.1 Wave Reordering Impact

If spec moves to different wave:
- **Upstream**: Does it break dependencies for specs that depended on it?
- **Downstream**: Do its dependencies still come before it?
- **Parallel**: Can it still run parallel with same-wave specs?

#### 3.2 Scope Change Impact

If specifications/design changed:
- **Tasks**: Which tasks are invalidated?
- **Implementation**: Which code needs update?
- **Tests**: Which tests need rewrite?

#### 3.3 Dependency Change Impact

If dependencies added/removed:
- **Build order**: Does implementation order change?
- **Interface**: Do interfaces need update?
- **Integration**: Do integration points change?

### Step 4: Generate Report

```markdown
## Roadmap Sync Analysis

### Summary
- Differences found: [N]
- Specs affected: [list]
- Estimated rework: [none/minor/significant]

---

### Structural Differences

#### Missing Specs (in roadmap, no directory)
| Spec | Wave | Action Needed |
|------|------|---------------|
| spec-x | 2 | Create directory or remove from roadmap |

#### Extra Specs (directory exists, not in roadmap)
| Spec | Current Phase | Action Needed |
|------|---------------|---------------|
| spec-y | design-generated | Add to roadmap or delete directory |

#### Wave Assignment Changes
| Spec | Roadmap Wave | Actual Wave | Impact |
|------|--------------|-------------|--------|
| spec-a | 1 | 2 | Delays spec-b, spec-c |

#### Dependency Changes
| Spec | Roadmap Deps | Actual Deps | Impact |
|------|--------------|-------------|--------|
| spec-b | [spec-a] | [spec-a, spec-x] | Need spec-x first |

---

### Content Differences

#### Specifications Modified After Tasks
| Spec | Implication |
|------|-------------|
| spec-a | Tasks may be outdated, review needed |

#### Design Modified After Tasks
| Spec | Implication |
|------|-------------|
| spec-b | 3 tasks may be invalidated |

---

### Rework Analysis

#### Tasks Potentially Invalidated
| Spec | Task | Reason |
|------|------|--------|
| spec-a | Task 2 | Spec 3 changed |
| spec-a | Task 4 | Dependency interface changed |

#### Implementation Potentially Affected
| Spec | Files | Reason |
|------|-------|--------|
| spec-b | src/notifier.py | Design pattern changed |

---

### Recommended Actions

1. **[Action 1]**: [description]
2. **[Action 2]**: [description]
3. **[Action 3]**: [description]

---

### Update Preview

If you approve, the following changes will be made to roadmap.md:

```diff
- Wave 1: spec-a, spec-b
+ Wave 1: spec-a
+ Wave 2: spec-b, spec-x
```
```

### Step 5: Request User Decision

Present options:

```
## Sync Options

Based on the analysis above:

### Option A: Apply All Changes
- Update roadmap.md to match current spec states
- Mark invalidated tasks for re-review
- You will need to manually address rework items

### Option B: Selective Update
- Choose which changes to apply
- Keep some roadmap assignments even if specs differ

### Option C: Abort
- Make no changes
- Review differences manually first

What would you like to do?
```

### Step 6: Execute Update (if approved)

#### For "Apply All":

1. **Update roadmap.md**:
   - Regenerate Wave Overview table
   - Update Dependency Graph
   - Update Implementation Order sections
   - Preserve Key Research Findings if still relevant
   - Update Quick Reference Commands

2. **Update spec.json files**:
   - Sync roadmap metadata (wave, dependencies, parallel)

3. **Mark affected items**:
   - Add `<!-- NEEDS_REVIEW: reason -->` comments to affected files
   - Update tasks.md with invalidation notes if needed

4. **Generate change report**:
   ```
   ## Sync Complete

   ### Changes Made
   - roadmap.md: Updated wave structure
   - spec-a/spec.json: Wave changed 1→2
   - spec-b/tasks.md: 2 tasks marked for review

   ### Manual Actions Required
   1. Review spec-a design for requirement changes
   2. Re-run /sdd-review-design spec-b
   3. Update spec-c implementation for interface change

   ### Next Steps
   Run `/sdd-roadmap-run` to continue implementation
   ```

#### For "Selective Update":

1. Present each change individually
2. Ask approve/skip for each
3. Apply only approved changes
4. Report what was changed and what was skipped

</instructions>

## Tool Guidance

### File Operations

- **Read**: All specs, roadmap, steering documents
- **Write**: roadmap.md (only after approval)
- **Edit**: spec.json files, add review markers

### Analysis Helpers

**Detect specification changes**:
```
- Compare design.md Specifications section content vs tasks.md generation time
- Parse spec IDs and compare
```

**Detect task invalidation**:
```
- Map tasks to specs/design sections
- If source section changed, task potentially invalid
```

### Dialogue

- Always show full analysis before asking for decision
- For destructive changes, require explicit confirmation
- Provide "abort" option at every decision point

## Safety Measures

### Never Auto-Apply

- All changes require user approval
- Show preview before any file modification

### Preserve Work

- Never delete implementation code
- Never delete completed tasks
- Only mark for review, don't auto-invalidate

### Audit Trail

- Log all changes made
- Include timestamps in roadmap.md update

## Output Description

### Analysis Output

Comprehensive markdown report showing:
1. All differences found
2. Impact analysis for each
3. Recommended actions
4. Preview of changes

### Completion Output

```
## Roadmap Update Complete

Updated: {{TIMESTAMP}}

### Changes Applied
[list of changes]

### Files Modified
- {{SDD_DIR}}/project/specs/roadmap.md
- {{SDD_DIR}}/project/specs/spec-a/spec.json
- {{SDD_DIR}}/project/specs/spec-b/tasks.md (review markers added)

### Next Steps
[recommended actions]
```
