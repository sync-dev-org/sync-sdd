# Review Subcommand

> **Migrated**: Review execution is now handled by `/sdd-review` skill. This file is retained as a reference for review types and verdict destinations.

## Routing

Standalone review invocations (`/sdd-roadmap review design|impl {feature}`) delegate to `/sdd-review`:

```
/sdd-review design {feature}
/sdd-review impl {feature}
/sdd-review dead-code
/sdd-review design --cross-check
/sdd-review impl --cross-check
/sdd-review design --wave N
/sdd-review impl --wave N
```

Pipeline context (dispatch loop, auto-fix loops, Wave QG) is handled by `refs/run.md` which references sdd-review steps directly.

## Review Types

### Design Review
- 6 design Inspectors: `sdd-inspector-rulebase`, `sdd-inspector-testability`, `sdd-inspector-architecture`, `sdd-inspector-consistency`, `sdd-inspector-best-practices`, `sdd-inspector-holistic`
- Auditor: `sdd-auditor-design`
- Cross-check / wave-scoped: same Inspector set, wave-scoped context

### Impl Review
- 6 base Inspectors: `sdd-inspector-impl-rulebase`, `sdd-inspector-interface`, `sdd-inspector-test`, `sdd-inspector-quality`, `sdd-inspector-impl-consistency`, `sdd-inspector-impl-holistic`
- Conditional: `sdd-inspector-e2e` (E2E configured), `sdd-inspector-web-e2e` + `sdd-inspector-web-visual` (web projects)
- Auditor: `sdd-auditor-impl`
- Cross-check / wave-scoped: cumulative scope, previously-resolved tracking

### Dead-Code Review
- 4 Inspectors: `sdd-inspector-dead-settings`, `sdd-inspector-dead-code`, `sdd-inspector-dead-specs`, `sdd-inspector-dead-tests`
- Auditor: `sdd-auditor-dead-code`

## Verdict Destinations

- **Single-spec review**: `{{SDD_DIR}}/project/specs/{feature}/reviews/verdicts.md`
- **Dead-code review** (standalone): `{{SDD_DIR}}/project/reviews/dead-code/verdicts.md`
- **Cross-check review**: `{{SDD_DIR}}/project/reviews/cross-check/verdicts.md`
- **Wave-scoped review**: `{{SDD_DIR}}/project/reviews/wave/verdicts.md`
- **Cross-cutting review**: `{{SDD_DIR}}/project/specs/.cross-cutting/{id}/verdicts.md`

## Steering Feedback Loop

When Auditor verdict contains `STEERING:` entries, process after handling the verdict but before advancing:

| Level | Action | Blocks pipeline |
|-------|--------|----------------|
| `CODIFY` | Update `steering/{target file}` directly + `decisions.md` STEERING_UPDATE | No |
| `PROPOSE` | Present to user for approval | Yes |

## Web Inspector Server Protocol

See `/sdd-review` SKILL.md Step 5a for dev server lifecycle management.
