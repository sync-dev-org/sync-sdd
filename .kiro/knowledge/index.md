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
| By phase | `Grep: "Should Detect At.*specifications"` |

---

## Knowledge Types

### incident

Problem patterns discovered during development. Learn from failures.

| File | Category | Keywords | Should Detect At |
|------|----------|----------|------------------|
| [incident-state-cache-recovery-reset.md](./incident-state-cache-recovery-reset.md) | state | cache, dedup, state-transition, TTL, recovery | specifications |
| [incident-integration-dry-misapplication-dedup.md](./incident-integration-dry-misapplication-dedup.md) | integration | DRY, 重複排除, deduplication, 仕様統合, コンテキスト分離 | specifications |
| [incident-integration-mid-wave-spec-addition.md](./incident-integration-mid-wave-spec-addition.md) | integration | mid-wave, spec-addition, cross-cutting, consistency, scope, non-goals | specifications |

### pattern

Recommended approaches and best practices. Replicate successes.

| File | Category | Keywords | Applicable Phases |
|------|----------|----------|-------------------|
| [pattern-data-sqlmodel-self-referential-relationship.md](./pattern-data-sqlmodel-self-referential-relationship.md) | data | SQLModel, SQLAlchemy, self-referential, relationship, type annotation, Optional, parent-child, hierarchy | design, impl |

### reference

Technical summaries and quick-reference materials.

| File | Category | Keywords | Last Verified |
|------|----------|----------|---------------|
| [reference-data-cm-production-budget-structure.md](./reference-data-cm-production-budget-structure.md) | data | budget, 予算, 費目, 原価, CM制作, 映像制作 | 2025-05-01 |
| [reference-integration-creative-project-domain-patterns.md](./reference-integration-creative-project-domain-patterns.md) | integration | htmx, auth, OAuth, logging, project, customer, Kanban, 商流 | 2025-05-01 |

---

## By Category

### state
- [incident-state-cache-recovery-reset.md](./incident-state-cache-recovery-reset.md) — Recovery cache clear oversight

### api
- (none)

### async
- (none)

### data
- [pattern-data-sqlmodel-self-referential-relationship.md](./pattern-data-sqlmodel-self-referential-relationship.md) — SQLModel 自己参照リレーションシップの型アノテーション制約
- [reference-data-cm-production-budget-structure.md](./reference-data-cm-production-budget-structure.md) — CM制作の実行予算構成・費目分類

### security
- (none)

### integration
- [incident-integration-dry-misapplication-dedup.md](./incident-integration-dry-misapplication-dedup.md) — DRY原則の誤適用による重複排除仕様の統合
- [incident-integration-mid-wave-spec-addition.md](./incident-integration-mid-wave-spec-addition.md) — 途中Wave追加SPECと既存SPECの整合性問題
- [reference-integration-creative-project-domain-patterns.md](./reference-integration-creative-project-domain-patterns.md) — クリエイティブ案件管理のドメインパターン集

---

## By Detection Phase

Quick reference for `sdd-review-*` commands.

### specifications
- [incident-state-cache-recovery-reset.md](./incident-state-cache-recovery-reset.md)
- [incident-integration-dry-misapplication-dedup.md](./incident-integration-dry-misapplication-dedup.md)
- [incident-integration-mid-wave-spec-addition.md](./incident-integration-mid-wave-spec-addition.md)

### design
- [pattern-data-sqlmodel-self-referential-relationship.md](./pattern-data-sqlmodel-self-referential-relationship.md)

### tasks
- (none)

### impl
- [pattern-data-sqlmodel-self-referential-relationship.md](./pattern-data-sqlmodel-self-referential-relationship.md)
