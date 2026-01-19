# Spec Review Rules for Test Implementer Clarity

## Review Philosophy
- **Perspective**: Test implementer who must write unambiguous tests
- **Question**: "Can I implement tests without guessing?"
- **Goal**: Ensure specs are precise enough for deterministic test implementation
- **Anti-Drift**: Prevent specs from deviating from SDD templates and responsibility boundaries

---

## Mode 1: Single Review Checklist

### 0. SDD Compliance (HIGHEST PRIORITY - Anti-Drift)

**Purpose**: Detect and correct spec drift caused by ad-hoc changes outside SDD workflow.

#### 0.1 Template Conformance

**requirements.md Structure Check**:
- Has Introduction section
- Has Requirements section with numbered requirement headings (1, 2, 3...)
- Each requirement has Objective (user story format)
- Each requirement has Acceptance Criteria (EARS format: When/If/While/Where/The system shall)
- No implementation details (component names, API specs, data structures)

**design.md Structure Check** (compare against template):
- Has Overview (Purpose, Users, Impact, Goals, Non-Goals)
- Has Architecture section
- Has Components and Interfaces section
- Has Data Models section (if applicable)
- Has Error Handling section
- Has Testing Strategy section
- No user stories or acceptance criteria

**Drift Indicators** (🔴 Critical):
- Sections missing from template → Structural drift
- Extra sections not in template → Ad-hoc additions
- Incorrect section nesting → Template violation

#### 0.2 Responsibility Separation (WHAT vs HOW)

**requirements.md should contain (WHAT)**:
- ✅ User objectives and goals
- ✅ Acceptance criteria (observable behaviors)
- ✅ Business rules and constraints
- ✅ User-facing error messages
- ❌ NOT: Component names, class names, function signatures
- ❌ NOT: Database schemas, API endpoints
- ❌ NOT: Technology choices, libraries

**design.md should contain (HOW)**:
- ✅ Architecture decisions and rationale
- ✅ Component responsibilities and interfaces
- ✅ Data models and schemas
- ✅ Error handling strategies
- ✅ Technology stack and choices
- ❌ NOT: New acceptance criteria
- ❌ NOT: User stories ("As a user, I want...")
- ❌ NOT: Business rules not derived from requirements.md

**Drift Indicators** (🔴 Critical):
- Implementation details in requirements.md → Premature design
- New acceptance criteria in design.md → Scope creep
- User stories in design.md → Responsibility leak

#### 0.3 Traceability Check

- Every design component should trace to requirement(s)
- No orphan components (design without requirement backing)
- No orphan requirements (requirement without design coverage)
- Requirements Traceability matrix is accurate (if present)

---

### 1. Requirements Clarity

#### 1.1 Ambiguous Language Detection
Flag any occurrence of:
- "適切に" / "appropriately"
- "必要に応じて" / "as needed"
- "など" / "etc."
- "基本的に" / "basically"
- "通常は" / "usually"
- "できるだけ" / "as much as possible"
- Unquantified terms: "fast", "many", "few", "large", "small"

**What to check**: Every behavior must have explicit conditions and outcomes.

#### 1.2 Numeric/Condition Specificity
- Are timeouts, limits, and thresholds defined with exact values?
- Are boundary conditions explicit (≤ vs <, inclusive vs exclusive)?
- Are valid input ranges specified?

#### 1.3 Edge Cases
- Are null/empty/undefined cases addressed?
- Are error scenarios enumerated?
- Are concurrent access scenarios considered (if applicable)?

### 2. Requirements Consistency

#### 2.1 Internal Contradictions
- Do any requirements conflict with each other?
- Are priorities clear when requirements compete?
- Is the "source of truth" defined for each behavior?

### 3. Design Verifiability

#### 3.1 Component Responsibilities
- Is each component's responsibility clearly bounded?
- Are handoff points between components explicit?
- Can each component be tested in isolation?

#### 3.2 Interface Contracts
- Are all inputs defined with types and constraints?
- Are all outputs defined with types and possible values?
- Are all error cases enumerated with expected behavior?

#### 3.3 State Transitions (if applicable)
- Are all states enumerated?
- Are all valid transitions defined?
- Are invalid transitions explicitly rejected?

### 4. Test Observability

#### 4.1 Deterministic Outcomes
- Does each input combination produce exactly one expected output?
- Are side effects observable and verifiable?
- Can success/failure be unambiguously determined?

#### 4.2 Mockability
- Can external dependencies be mocked?
- Are dependency interfaces clearly defined?
- Is time/randomness controllable for testing?

---

## Mode 2: Cross-Check Checklist

### 1. Requirements Consistency Across Specs

#### 1.1 Terminology Unification
- Is the same term used consistently across specs?
- Are there conflicting definitions for the same concept?
- Is there a glossary or are terms defined in context?

#### 1.2 Conflicting Expectations
- Do different specs expect different behaviors from the same component?
- Are there contradictory assumptions about shared resources?

#### 1.3 Dependency Clarity
- Are inter-spec dependencies explicitly stated?
- Is the dependency direction clear (A depends on B, not circular)?

### 2. Design Compatibility Across Specs

#### 2.1 Shared Resource Access
- Do specs agree on how shared resources are accessed?
- Are locking/synchronization requirements consistent?
- Are data formats compatible?

#### 2.2 API Compatibility
- Do provider and consumer specs agree on API contracts?
- Are version/compatibility requirements specified?

#### 2.3 Data Model Consistency
- Are entity definitions consistent across specs?
- Are there conflicting field types or constraints?

### 3. Parallel Development Feasibility

#### 3.1 Independence Assessment
- Can each spec be implemented without waiting for others?
- Are mock interfaces sufficient for independent testing?

#### 3.2 Circular Dependency Detection
- Is the dependency graph acyclic?
- If cycles exist, can they be broken with interfaces?

#### 3.3 Shared Component Ownership
- Is it clear who owns shared components?
- Are modification rights and responsibilities defined?

---

## Output Formats

### Single Review Output

```markdown
# Spec Review: {feature-name}

## Summary
[2-3 sentence overview: What does this spec cover? What is its testability status?]

## SDD Compliance Check

### Template Conformance
| Document | Status | Issues |
|----------|--------|--------|
| requirements.md | ✅ Compliant / ⚠️ Minor drift / 🔴 Major drift | [details] |
| design.md | ✅ Compliant / ⚠️ Minor drift / 🔴 Major drift | [details] |

### Responsibility Separation
| Issue | Location | Content | Should Be In |
|-------|----------|---------|--------------|
| [type] | [file:section] | [problematic content] | [correct file] |

### Traceability
- Orphan requirements: [list or "None"]
- Orphan components: [list or "None"]

## Critical Issues (テスト実装を阻害)
[Issues that make test implementation impossible or unreliable]

🔴 **Issue 1**: [Concise title]
- **Location**: requirements.md Section X / design.md Component Y
- **Problem**: [Quote or describe the problematic content]
- **Test Impact**: Test implementer cannot determine [what exactly]
- **Suggested Fix**: [Specific, actionable change]

🔴 **Issue 2**: ...

## Warnings (曖昧さ・改善推奨)
[Issues that cause ambiguity but have reasonable defaults]

🟡 **Warning 1**: [Concise title]
- **Location**: [file and section]
- **Problem**: [Description]
- **Risk**: May lead to [potential issue]
- **Suggested Fix**: [Recommendation]

🟡 **Warning 2**: ...

## Verdict

**[GO / CONDITIONAL / NO-GO]**

- **GO**: Test implementation can proceed without blockers
- **CONDITIONAL**: Can proceed, but [specific items] should be clarified during implementation
- **NO-GO**: Must resolve [critical issues] before test implementation

### Next Steps
[What the user should do based on the verdict]
```

### Cross-Check Output

```markdown
# Cross-Spec Review

## Specs Analyzed
| Spec | Requirements | Design | Status |
|------|--------------|--------|--------|
| feature-a | ✓ | ✓ | Reviewed |
| feature-b | ✓ | - | Requirements only |
| feature-c | ✓ | ✓ | Reviewed |

## Cross-Spec Issues

### Requirement Conflicts
[Contradictions between specs' requirements]

🔴 **Conflict 1**: [feature-A] vs [feature-B]
- **Content**: [What contradicts]
- **feature-A says**: [Quote]
- **feature-B says**: [Quote]
- **Resolution needed**: [Who needs to decide/what needs to change]

### Design Incompatibilities
[Technical conflicts between designs]

🔴 **Incompatibility 1**: [feature-X] vs [feature-Y]
- **Component**: [Shared component name]
- **Conflict**: [How they differ]
- **Risk**: [What breaks if not resolved]

### Scope Overlaps
[Areas where specs may interfere]

🟡 **Overlap 1**: [title]
- **Specs involved**: [feature-A], [feature-C]
- **Shared area**: [What overlaps]
- **Parallel development risk**: [Merge conflicts, integration issues, etc.]

## Parallel Development Assessment

### Independent (並行開発可能)
Specs that can be developed simultaneously without coordination:
- [feature-X]
- [feature-Y]

### Sequential (依存関係あり)
Specs with dependencies that require ordering:
1. [feature-A] (no dependencies)
2. [feature-B] (depends on feature-A)
3. [feature-C] (depends on feature-B)

### Requires Coordination (同時作業に注意)
Specs that can be developed in parallel but need communication:
- [feature-P] + [feature-Q]: Share [component], coordinate on [interface]

## Summary
[2-3 sentences: Overall consistency status and recommended development approach]
```

---

## Severity Classification

### Critical (🔴)
Test implementation is **blocked** or **unreliable**:
- Cannot determine expected behavior
- Multiple valid interpretations exist
- Missing essential information
- **SDD Drift**: Major template violation or responsibility leak
- **SDD Drift**: New requirements added in design.md (scope creep)
- **SDD Drift**: Implementation details in requirements.md

### Warning (🟡)
Test implementation is **possible but risky**:
- Reasonable default can be assumed
- Edge case handling unclear
- Potential for misinterpretation
- **SDD Drift**: Minor structural deviation from template
- **SDD Drift**: Orphan component or requirement

---

## Review Guidelines

1. **SDD compliance first**: Check template conformance and responsibility separation before other checks
2. **Be specific**: Quote problematic text, cite exact locations
3. **Be actionable**: Every issue must have a suggested fix (including "move to [file]" for drift)
4. **Prioritize**: SDD drift issues → Critical issues → Warnings
5. **Stay in scope**: Only flag issues that affect testability or SDD compliance
6. **Pull back to SDD**: For drifted content, always recommend the correct location
7. **Assume good intent**: Suggest improvements, don't criticize

---

## Deep Review: Steering Update Proposals

When `--deep` flag is used, include steering update proposals to persist discovered knowledge.

### Purpose
Capture best practices, API updates, edge cases, and implementation gotchas into steering documents so future reviews don't need to re-search the same information.

### What to Capture

| Knowledge Type | Proposed Location | Examples |
|---------------|-------------------|----------|
| Latest API patterns | tech.md | New API versions, deprecations, migration paths |
| Technical constraints | tech.md | Rate limits, quotas, compatibility issues |
| Implementation gotchas | Custom steering | Common bugs, workarounds, edge cases |
| Design patterns | Custom steering | Proven patterns for the domain |
| Security considerations | Custom steering | Vulnerabilities, best practices |

### Output Format Addition (--deep only)

```markdown
## Steering Update Proposals

### Existing Steering Updates

#### tech.md
```diff
+ ## [Technology] Considerations
+ - [Latest API change]: [Impact and how to handle]
+ - [Known limitation]: [Workaround]
```

### New Custom Steering Proposals

#### Proposed: `steering/{domain}-patterns.md`
**Rationale**: [Why this knowledge needs to be persisted]

**Content**:
```markdown
# [Domain] Patterns and Best Practices

## Latest API Considerations
- [Finding 1]
- [Finding 2]

## Known Edge Cases
- [Edge case]: [How to handle]

## Implementation Gotchas
- [Gotcha]: [How to avoid]
```

### Knowledge Capture Summary
| Knowledge | Source | Location | Priority |
|-----------|--------|----------|----------|
| [Item] | [URL] | [file] | High/Medium/Low |
```
