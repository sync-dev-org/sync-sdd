# Pattern Knowledge Template

---
**Purpose**: Document recommended patterns and best practices discovered through development experience.

**Usage**:
- Record successful approaches that should be replicated.
- Provide guidance for common scenarios.
- Enable proactive pattern application during `sdd-review-*` commands.

**Naming Convention**: `pattern-{category}-{name}.md`
- Categories: `state`, `api`, `async`, `data`, `security`, `integration`
- Example: `pattern-api-retry-exponential-backoff.md`, `pattern-state-cache-invalidation.md`
---

## Metadata

| Field | Value |
|-------|-------|
| Category | {{CATEGORY}} |
| Keywords | {{KEYWORDS}} |
| Applicable Phases | {{APPLICABLE_PHASES}} |

<!--
CATEGORY: state / api / async / data / security / integration
KEYWORDS: Comma-separated search terms
APPLICABLE_PHASES: requirements / design / tasks / impl (comma-separated)
-->

## Pattern Summary

**{{PATTERN_NAME}}**

{{BRIEF_DESCRIPTION}}

## Problem Context

### When to Apply
- {{CONDITION_1}}
- {{CONDITION_2}}

### Symptoms Without This Pattern
- {{SYMPTOM_1}}
- {{SYMPTOM_2}}

## Solution

### Core Principle

{{PRINCIPLE_EXPLANATION}}

### Implementation Approach

```
{{PSEUDOCODE_OR_STRUCTURE}}
```

### Key Points
1. {{KEY_POINT_1}}
2. {{KEY_POINT_2}}
3. {{KEY_POINT_3}}

## Examples

### Good Example
```
{{GOOD_EXAMPLE}}
```

### Anti-Pattern (Avoid)
```
{{BAD_EXAMPLE}}
```

## Application Checklist

- [ ] {{CHECK_ITEM_1}}
- [ ] {{CHECK_ITEM_2}}
- [ ] {{CHECK_ITEM_3}}

## Related Patterns

| Pattern | Relationship |
|---------|--------------|
| {{RELATED_PATTERN_1}} | {{RELATIONSHIP_1}} |
| {{RELATED_PATTERN_2}} | {{RELATIONSHIP_2}} |

## References

- {{REFERENCE_1}}
- {{REFERENCE_2}}
