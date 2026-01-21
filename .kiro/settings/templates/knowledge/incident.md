# Incident Knowledge Template

---
**Purpose**: Capture problem patterns discovered during development for future review reference.

**Usage**:
- Record issues found during implementation that should have been caught earlier.
- Document detection points for each SDD phase (requirements, design, tasks, impl).
- Enable context-aware knowledge retrieval during `sdd-review-*` commands.

**Naming Convention**: `{category}-{pattern-name}.md`
- Categories: `state`, `api`, `async`, `data`, `security`, `integration`
- Example: `state-cache-recovery-reset.md`, `api-retry-backoff.md`
---

## Metadata

| Field | Value |
|-------|-------|
| Discovered Phase | {{DISCOVERED_PHASE}} |
| Should Detect At | {{SHOULD_DETECT_PHASE}} |
| Category | {{CATEGORY}} |
| Keywords | {{KEYWORDS}} |
| Severity | {{SEVERITY}} |

<!--
DISCOVERED_PHASE: requirements / design / tasks / impl
SHOULD_DETECT_PHASE: requirements / design / tasks / impl
CATEGORY: state / api / async / data / security / integration
KEYWORDS: Comma-separated search terms
SEVERITY: high / medium / low
-->

## Problem Summary

**{{ONE_LINE_SUMMARY}}**

{{BACKGROUND_EXPLANATION}}

## Concrete Example

### What Was Specified
- {{SPECIFIED_ITEM_1}}
- {{SPECIFIED_ITEM_2}}

### What Was Missing
- **{{MISSING_SPECIFICATION}}**

### What Happened
```
{{INCIDENT_SEQUENCE}}
```

{{USER_IMPACT_DESCRIPTION}}

### Why It Was Overlooked
- {{REASON_1}}
- {{REASON_2}}
- {{REASON_3}}

## Detection Points by Phase

### requirements
<!-- Most effective detection timing for specification-level issues -->
- [ ] {{CHECK_ITEM_1}}
- [ ] {{CHECK_ITEM_2}}

### design
- [ ] {{CHECK_ITEM_1}}
- [ ] {{CHECK_ITEM_2}}

### tasks
- [ ] {{CHECK_ITEM_1}}
- [ ] {{CHECK_ITEM_2}}

### impl
- [ ] {{CHECK_ITEM_1}}
- [ ] {{CHECK_ITEM_2}}

## General Checklist

<!-- Reusable checklist applicable to similar patterns -->

| {{COLUMN_1}} | {{COLUMN_2}} |
|--------------|--------------|
| {{ITEM_1}} | {{DETAIL_1}} |
| {{ITEM_2}} | {{DETAIL_2}} |

## Related Patterns

<!-- Similar issues that may occur in other contexts -->

| Pattern | Common Oversight |
|---------|------------------|
| {{PATTERN_1}} | {{OVERSIGHT_1}} |
| {{PATTERN_2}} | {{OVERSIGHT_2}} |

## Lessons Learned

1. **{{LESSON_1}}**
2. **{{LESSON_2}}**
3. **{{LESSON_3}}**
