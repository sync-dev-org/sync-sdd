# Incident: Mid-Wave SPEC Addition Consistency

---
**Purpose**: Capture the challenges of adding a cross-cutting SPEC mid-project when previous wave specs have already been finalized.

**Usage**:
- Check when adding infrastructure/foundation specs after dependent features are designed
- Validate that existing specs don't have conflicting scope declarations
- Ensure automated reviews understand "not yet implemented" vs "missing implementation"
---

## Metadata

| Field | Value |
|-------|-------|
| Discovered Phase | design |
| Should Detect At | specifications |
| Category | integration |
| Keywords | mid-wave, spec-addition, cross-cutting, consistency, scope, non-goals, dependencies |
| Severity | high |

## Problem Summary

**Adding a cross-cutting SPEC after dependent specs are finalized causes hidden inconsistencies**

When a foundational spec (e.g., logging infrastructure) is added mid-project as a later wave, existing specs that should depend on it may already contain contradictory declarations (e.g., "audit logging out of scope for v1"). Automated review tools may also misinterpret "not yet implemented" as "missing implementation" because they lack awareness of the spec's chronological context.

## Concrete Example

### What Was Specified
- Wave 2: auth and user-group specs completed with "監査ログ（v1 スコープ外）" in Non-Goals
- Wave 3: logging spec added to provide SecurityLogger infrastructure
- logging spec assumed auth/user-group would use SecurityLogger

### What Was Missing
- **Consistency check between new spec's assumptions and existing specs' scope declarations**
- **Chronological context awareness in automated reviews**

### What Happened
```
1. logging spec created with "初期統合対象: auth, user-group"
2. Design review flagged "RotatingFileHandler not implemented" as CRITICAL
3. Review couldn't distinguish "will be implemented" from "missing"
4. Manual discovery: auth/user-group declared logging "out of scope"
5. Required retroactive updates to 2 previous wave specs
6. Parameter decisions (is_first_user) required cross-spec analysis
```

Manual intervention required to resolve contradictions and update previous wave specs.

### Why It Was Overlooked
- Roadmap didn't anticipate need for logging spec until Wave 3
- No automated cross-spec consistency check for scope declarations
- Review tools designed for single-spec validation, not cross-spec dependencies
- "Out of scope" in Non-Goals not flagged when new spec assumes integration

## Detection Points by Phase

### specifications
- [ ] When adding infrastructure spec: scan existing specs for contradictory Non-Goals
- [ ] Check if new spec's "integration targets" have declared the feature out of scope
- [ ] Validate that dependency direction matches wave ordering
- [ ] Document which existing specs need updates before proceeding

### design
- [ ] Cross-check new spec's component dependencies against existing spec designs
- [ ] Verify existing specs have dependency declarations for new infrastructure
- [ ] Flag if new spec adds parameters that existing specs don't account for

### tasks
- [ ] Include "update existing spec" tasks when adding cross-cutting infrastructure
- [ ] Ensure task ordering reflects actual implementation sequence

### impl
- [ ] Review tool should distinguish "pre-implementation" from "missing implementation"
- [ ] Verify existing implementations align with updated spec dependencies

## General Checklist

| Check | Action |
|-------|--------|
| Cross-cutting spec added | Scan all existing specs for scope conflicts |
| "Out of scope" found | Determine if scope should change or spec should wait |
| Integration assumed | Verify target specs have matching dependencies |
| Parameters defined | Check if existing designs need parameter updates |
| Review flagged gaps | Confirm whether gap is "not yet" or "missing" |

## Related Patterns

| Pattern | Common Oversight |
|---------|------------------|
| Foundation-last anti-pattern | Building features before infrastructure, requiring retroactive updates |
| Scope declaration drift | Non-Goals becoming stale as project evolves |
| Review context blindness | Automated tools lacking temporal/planning context |
| Cross-spec dependency gaps | Unidirectional dependency declarations (A depends on B, but B doesn't know) |

## Lessons Learned

1. **Cross-cutting infrastructure should be in early waves** - Logging, error handling, and security foundations should precede features that use them
2. **Scope declarations need cross-spec validation** - When adding a spec, automatically check if other specs have conflicting scope statements
3. **Reviews need planning context** - Tools should know which specs are "pre-implementation" to avoid false positives
4. **Bi-directional dependency tracking** - Both provider and consumer specs should declare the relationship
5. **Retroactive spec updates are expensive** - Each previous wave spec touched requires re-review and potential task regeneration
