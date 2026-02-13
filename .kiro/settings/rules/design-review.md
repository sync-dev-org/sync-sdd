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

**design.md Specifications Section Check**:
- Has Introduction subsection
- Has numbered Spec headings (Spec 1, Spec 2, ...)
- Each Spec has Goal statement
- Each Spec has Acceptance Criteria (numbered list, natural language)
- ACs are testable and specific (no vague qualifiers)
- Has Non-Goals subsection
- No implementation details in Specifications section (component names, API specs, data structures)

**design.md Design Sections Check** (compare against template):
- Has Overview (Purpose, Users, Impact, Goals, Non-Goals)
- Has Architecture section
- Has Components and Interfaces section
- Has Data Models section (if applicable)
- Has Error Handling section
- Has Testing Strategy section

**Drift Indicators** (🔴 Critical):
- Sections missing from template → Structural drift
- Extra sections not in template → Ad-hoc additions
- Incorrect section nesting → Template violation
- Missing Specifications section entirely → Critical structural gap

#### 0.2 Section Responsibility Separation (WHAT vs HOW)

**Specifications section should contain (WHAT)**:
- ✅ User objectives and goals
- ✅ Acceptance criteria (observable behaviors)
- ✅ Business rules and constraints
- ✅ User-facing error messages
- ❌ NOT: Component names, class names, function signatures
- ❌ NOT: Database schemas, API endpoints
- ❌ NOT: Technology choices, libraries

**Design sections (Overview, Architecture, Components, etc.) should contain (HOW)**:
- ✅ Architecture decisions and rationale
- ✅ Component responsibilities and interfaces
- ✅ Data models and schemas
- ✅ Error handling strategies
- ✅ Technology stack and choices
- ❌ NOT: New acceptance criteria beyond Specifications section
- ❌ NOT: User stories ("As a user, I want...")
- ❌ NOT: Business rules not derived from Specifications section

**Drift Indicators** (🟡 Warning):
- Implementation details leaking into Specifications section → Premature design
- New acceptance criteria appearing in design sections → Scope creep
- Specifications section missing testable criteria → Incomplete specs

#### 0.3 Traceability Check

- Every design component should trace to spec(s) in the Specifications section
- No orphan components (design without spec backing)
- No orphan specs (spec without design coverage)
- Specifications Traceability matrix is accurate (if present)

---

### 1. Specifications Clarity

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

### 2. Specifications Consistency

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

### 1. Specifications Consistency Across Specs

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

## Severity Classification

### Critical (🔴)
Test implementation is **blocked** or **unreliable**:
- Cannot determine expected behavior
- Multiple valid interpretations exist
- Missing essential information
- **SDD Drift**: Major template violation or responsibility leak
- **SDD Drift**: New acceptance criteria in design sections outside Specifications (scope creep)
- **SDD Drift**: Implementation details in Specifications section

### Warning (🟡)
Test implementation is **possible but risky**:
- Reasonable default can be assumed
- Edge case handling unclear
- Potential for misinterpretation
- **SDD Drift**: Minor structural deviation from template
- **SDD Drift**: Orphan component or spec

### CPF Severity Mapping
When outputting in CPF format, map as follows:
- Critical (🔴) → `C` (blocker, unresolvable ambiguity) or `H` (SDD drift, missing info)
- Warning (🟡) → `M` (minor drift, unclear edge case) or `L` (terminology, cosmetic)

---

## Review Guidelines

1. **SDD compliance first**: Check template conformance and responsibility separation before other checks
2. **Be specific**: Quote problematic text, cite exact locations
3. **Be actionable**: Every issue must have a suggested fix (including "move to [file]" for drift)
4. **Prioritize**: SDD drift issues → Critical issues → Warnings
5. **Stay in scope**: Only flag issues that affect testability or SDD compliance
6. **Pull back to SDD**: For drifted content, always recommend the correct location
7. **Assume good intent**: Suggest improvements, don't criticize

