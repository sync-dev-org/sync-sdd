# Requirement Review Rules for Steering Alignment

## Review Philosophy
- **Perspective**: Ensure requirements faithfully represent steering vision before design begins
- **Question**: "Does this requirement belong here, and is it clear enough to design against?"
- **Goal**: Guarantee steering alignment, internal consistency, and design-readiness
- **Anti-Drift**: Prevent requirements from diverging from project steering

---

## Mode 1: Single Review Checklist

### 0. Steering Alignment (HIGHEST PRIORITY)

**Purpose**: Ensure requirements reflect and support the steering documents.

#### 0.1 Product Vision Alignment (product.md)

Check against steering/product.md:
- Does requirement support stated product goals?
- Does requirement serve identified user personas?
- Does requirement fit within declared product scope?
- Is requirement consistent with product principles?

**Drift Indicators** (🔴 Critical):
- Requirement contradicts product vision
- Requirement serves undeclared user persona
- Requirement outside product scope boundaries
- Requirement violates product principles

#### 0.2 Technical Constraint Alignment (tech.md)

Check against steering/tech.md:
- Does requirement respect declared technical constraints?
- Is requirement achievable within tech stack boundaries?
- Does requirement follow stated technical standards?
- Are non-functional requirements consistent with tech guidelines?

**Drift Indicators** (🔴 Critical):
- Requirement assumes technology not in tech stack
- Requirement violates technical constraints
- Performance expectation conflicts with tech limitations
- Security requirement contradicts tech standards

#### 0.3 Structure Alignment (structure.md)

Check against steering/structure.md:
- Does requirement fit within declared module/domain boundaries?
- Is requirement scope appropriate for project structure?
- Does requirement follow naming/convention guidelines?

**Drift Indicators** (🟡 Warning):
- Requirement spans multiple domains unexpectedly
- Requirement naming inconsistent with conventions

---

### 1. Template Conformance

#### 1.1 Structure Check

**Required Elements**:
- [ ] Introduction section present
- [ ] Requirements section with numbered headings (Requirement 1, 2, 3...)
- [ ] Each requirement has Objective (user story format)
- [ ] Each requirement has Acceptance Criteria section

**Format Compliance**:
- [ ] Objectives use "As a [role], I want [capability], so that [benefit]"
- [ ] Acceptance Criteria use EARS format:
  - When [event], the [system] shall [response]
  - If [trigger], then the [system] shall [response]
  - While [precondition], the [system] shall [response]
  - Where [feature is included], the [system] shall [response]
  - The [system] shall [response]

**Content Boundaries**:
- [ ] No implementation details (component names, class names, APIs)
- [ ] No technology choices (libraries, frameworks, databases)
- [ ] No design decisions (architecture patterns, data structures)

**Drift Indicators** (🔴 Critical):
- Missing required sections
- Non-EARS acceptance criteria
- Implementation details present

---

### 2. Internal Quality

#### 2.1 Ambiguous Language Detection

Flag any occurrence of:
- "適切に" / "appropriately" / "properly"
- "必要に応じて" / "as needed" / "when necessary"
- "など" / "etc." / "and so on"
- "基本的に" / "basically" / "generally"
- "通常は" / "usually" / "normally"
- "できるだけ" / "as much as possible"
- "すぐに" / "quickly" / "fast" (without metric)
- "多くの" / "many" / "few" / "some" (unquantified)
- "簡単に" / "easily" / "simply"
- "柔軟に" / "flexibly"

**What to check**: Every acceptance criterion must have explicit, testable conditions.

#### 2.2 Completeness Check

- Are error/failure scenarios addressed?
- Are boundary conditions specified?
- Are null/empty/default cases defined?
- Are concurrent/race conditions considered (if applicable)?
- Are timeout/retry behaviors specified (if applicable)?

#### 2.3 Contradiction Detection

- Do any acceptance criteria conflict with each other?
- Are there mutually exclusive conditions without priority?
- Does any criterion make another impossible?

#### 2.4 Testability Assessment

For each acceptance criterion:
- Can it be verified with a specific test?
- Is the expected outcome unambiguous?
- Are success/failure conditions binary?

---

## Mode 2: Cross-Check Checklist

### 1. Inter-Requirement Consistency

#### 1.1 Terminology Unification
- Same concept uses same term across all specs
- No conflicting definitions
- Glossary terms used consistently

#### 1.2 Behavioral Consistency
- Same trigger produces consistent response across specs
- Shared entities behave consistently
- No contradictory assumptions about system state

#### 1.3 Dependency Clarity
- Dependencies between requirements explicitly stated
- Dependency direction clear (A requires B)
- No circular dependencies

### 2. Scope/Responsibility Separation

#### 2.1 Non-Overlapping Scope
- Each spec has distinct, clear boundaries
- No duplicate requirements across specs
- Shared concerns explicitly allocated to one spec

#### 2.2 Domain Boundaries
- Requirements respect domain boundaries from structure.md
- Cross-domain concerns explicitly noted
- Integration points clearly defined

#### 2.3 Completeness Assessment
- All steering goals covered by at least one spec
- No gaps between spec scopes
- Edge cases at boundaries addressed

### 3. Steering Coherence (Cross-Spec)

#### 3.1 Collective Vision Support
- All specs together support product vision
- No spec undermines another's steering alignment
- Priorities consistent with steering

#### 3.2 Technical Coherence
- All specs respect same technical constraints
- No spec assumes different tech boundaries
- Non-functional requirements consistent

---

## Output Formats

### Single Review Output

```markdown
# Requirement Review: {feature-name}

## Summary
[2-3 sentence overview: What does this requirement cover? What is its quality status?]

## Steering Alignment

### Product Vision (product.md)
| Aspect | Status | Notes |
|--------|--------|-------|
| Goals alignment | ✅ / ⚠️ / 🔴 | [details] |
| User persona fit | ✅ / ⚠️ / 🔴 | [details] |
| Scope boundaries | ✅ / ⚠️ / 🔴 | [details] |

### Technical Constraints (tech.md)
| Aspect | Status | Notes |
|--------|--------|-------|
| Tech stack fit | ✅ / ⚠️ / 🔴 | [details] |
| Constraints respected | ✅ / ⚠️ / 🔴 | [details] |
| Standards followed | ✅ / ⚠️ / 🔴 | [details] |

### Structure (structure.md)
| Aspect | Status | Notes |
|--------|--------|-------|
| Domain boundaries | ✅ / ⚠️ / 🔴 | [details] |
| Conventions | ✅ / ⚠️ / 🔴 | [details] |

## Template Conformance
| Element | Status | Issues |
|---------|--------|--------|
| Structure | ✅ / 🔴 | [missing sections] |
| User stories | ✅ / 🔴 | [format issues] |
| EARS criteria | ✅ / 🔴 | [format issues] |
| No impl details | ✅ / 🔴 | [violations] |

## Critical Issues (設計フェーズを阻害)

🔴 **Issue 1**: [Concise title]
- **Location**: Requirement X, Acceptance Criteria Y
- **Problem**: [Quote or describe]
- **Impact**: Cannot design/test because [reason]
- **Suggested Fix**: [Specific change]

## Warnings (曖昧さ・改善推奨)

🟡 **Warning 1**: [Concise title]
- **Location**: [section]
- **Problem**: [Description]
- **Risk**: May cause [issue] during design
- **Suggested Fix**: [Recommendation]

## Verdict

**[GO / CONDITIONAL / NO-GO]**

- **GO**: Ready for design phase (`/sdd-design {feature}`)
- **CONDITIONAL**: Can proceed with noted clarifications
- **NO-GO**: Must resolve critical issues first

### Next Steps
[Specific actions based on verdict]
```

### Cross-Check Output

```markdown
# Cross-Requirement Review

## Specs Analyzed
| Spec | Requirements | Steering Alignment | Status |
|------|--------------|-------------------|--------|
| feature-a | ✓ | ✅ Aligned | Reviewed |
| feature-b | ✓ | ⚠️ Partial | Reviewed |
| feature-c | ✓ | ✅ Aligned | Reviewed |

## Cross-Spec Issues

### Terminology Conflicts
🔴 **Conflict 1**: Term "[term]" used inconsistently
- **feature-A**: [definition/usage]
- **feature-B**: [different definition/usage]
- **Resolution**: [standardize on X]

### Behavioral Conflicts
🔴 **Conflict 1**: [feature-A] vs [feature-B]
- **Trigger**: [same trigger]
- **feature-A expects**: [behavior]
- **feature-B expects**: [different behavior]
- **Resolution needed**: [decision required]

### Scope Overlaps
🟡 **Overlap 1**: [title]
- **Specs involved**: [feature-A], [feature-C]
- **Overlapping area**: [what overlaps]
- **Risk**: [duplicate effort, conflicting designs]
- **Resolution**: [allocate to one spec]

### Steering Gaps
🟡 **Gap 1**: [steering goal] not covered
- **From**: product.md / tech.md
- **Current coverage**: [partial/none]
- **Suggested**: Add to [spec] or create new spec

## Scope Assessment

### Well-Separated (明確に分離)
- [feature-X]: [scope summary]
- [feature-Y]: [scope summary]

### Needs Clarification (境界が曖昧)
- [feature-A] vs [feature-B]: [boundary issue]

### Recommended Allocation
| Shared Concern | Assigned To | Rationale |
|---------------|-------------|-----------|
| [concern] | [spec] | [why] |

## Development Readiness

### Independent (並行設計可能)
- [feature-X]
- [feature-Y]

### Sequential (依存関係あり)
1. [feature-A] (no dependencies)
2. [feature-B] (depends on feature-A's interfaces)

### Requires Coordination (設計時に調整必要)
- [feature-P] + [feature-Q]: Share [domain], coordinate on [boundary]

## Summary
[2-3 sentences: Overall requirement quality and recommended approach]
```

---

## Severity Classification

### Critical (🔴)
Design phase is **blocked**:
- Steering violation (requirement contradicts product/tech/structure)
- Ambiguous acceptance criteria (cannot design solution)
- Internal contradiction (requirements conflict)
- Missing template sections
- Implementation details in requirements (responsibility leak)

### Warning (🟡)
Design possible but **risky**:
- Minor steering drift
- Edge case not specified
- Terminology inconsistency
- Boundary condition unclear

### CPF Severity Mapping
When outputting in CPF format, map as follows:
- Critical (🔴) → `C` (steering violation, blocker) or `H` (ambiguity, contradiction)
- Warning (🟡) → `M` (minor drift, unclear edge case) or `L` (terminology, cosmetic)

---

## Review Guidelines

1. **Steering first**: Always verify steering alignment before quality checks
2. **Template compliance**: Check structure before content
3. **Be specific**: Quote problematic text, cite exact locations
4. **Be actionable**: Every issue must have a suggested fix
5. **Prioritize**: Steering issues → Critical → Warnings
6. **Scope discipline**: Flag requirements that belong elsewhere
7. **No premature design**: Flag any implementation details for removal

---

## Deep Review: Steering Update Proposals

When `--deep` flag is used, include steering update proposals to persist discovered knowledge.

### Purpose
Capture domain knowledge, business rules, edge cases, and compliance requirements into steering documents so future reviews don't need to re-search the same information.

### What to Capture

| Knowledge Type | Proposed Location | Examples |
|---------------|-------------------|----------|
| Business rules | product.md | Industry regulations, domain conventions |
| User behavior patterns | product.md | Common user flows, expectations |
| Compliance requirements | tech.md | Legal, security, accessibility standards |
| Domain edge cases | Custom steering | Known failure modes, boundary conditions |
| Terminology | Custom steering | Domain glossary, standard definitions |

### Output Format Addition (--deep only)

```markdown
## Steering Update Proposals

### Existing Steering Updates

#### product.md
```diff
+ ## [Domain] Business Rules
+ - [Rule from research]: [Source]
+ - [User expectation]: [How to address]
```

#### tech.md
```diff
+ ## Compliance Considerations
+ - [Requirement]: [How it affects requirements]
```

### New Custom Steering Proposals

#### Proposed: `steering/{domain}-requirements.md`
**Rationale**: [Why this domain knowledge needs to be persisted]

**Content**:
```markdown
# [Domain] Requirements Knowledge

## Business Rules
- [Rule]: [Source and implications]

## Known Edge Cases
- [Edge case]: [Expected behavior]

## User Behavior Patterns
- [Pattern]: [How to address in requirements]

## Domain Glossary
- [Term]: [Standard definition]
```

### Knowledge Capture Summary
| Knowledge | Source | Location | Priority |
|-----------|--------|----------|----------|
| [Item] | [URL] | [file] | High/Medium/Low |
```
