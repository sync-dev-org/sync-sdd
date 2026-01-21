# Knowledge Index

Development knowledge catalog for review reference and team learning.

## Naming Convention

```
{type}-{category}-{name}.md
```

| Component | Values |
|-----------|--------|
| type | `incident`, `pattern`, `reference` |
| category | `state`, `api`, `async`, `data`, `security`, `integration` |
| name | kebab-case descriptive name |

**Examples**:
- `incident-state-cache-recovery-reset.md`
- `pattern-api-retry-exponential-backoff.md`
- `reference-api-slack-rate-limits.md`

## Filtering

| Purpose | Method |
|---------|--------|
| By type | `Glob: .kiro/knowledge/incident-*.md` |
| By category | `Glob: .kiro/knowledge/*-state-*.md` |
| By keyword | `Grep: "Keywords.*cache"` |
| By phase | `Grep: "Should Detect At.*requirements"` |

---

## Knowledge Types

### incident

Problem patterns discovered during development. Learn from failures.

| File | Category | Keywords | Should Detect At |
|------|----------|----------|------------------|
| [incident-state-cache-recovery-reset.md](./incident-state-cache-recovery-reset.md) | state | cache, dedup, state-transition, TTL, recovery | requirements |

### pattern

Recommended approaches and best practices. Replicate successes.

| File | Category | Keywords | Applicable Phases |
|------|----------|----------|-------------------|
| - | - | - | - |

### reference

Technical summaries and quick-reference materials.

| File | Category | Keywords | Last Verified |
|------|----------|----------|---------------|
| - | - | - | - |

---

## By Category

### state
- [incident-state-cache-recovery-reset.md](./incident-state-cache-recovery-reset.md) — Recovery cache clear oversight

### api
- (none)

### async
- (none)

### data
- (none)

### security
- (none)

### integration
- (none)

---

## By Detection Phase

Quick reference for `sdd-review-*` commands.

### requirements
- [incident-state-cache-recovery-reset.md](./incident-state-cache-recovery-reset.md)

### design
- (none)

### tasks
- (none)

### impl
- (none)
