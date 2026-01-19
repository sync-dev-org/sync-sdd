---
description: Strict requirements review for steering alignment and clarity
allowed-tools: Read, Glob, Grep, WebSearch, WebFetch
argument-hint: [feature-name] [--deep]
---

# SDD Requirements Review for Steering Alignment

<background_information>
- **Mission**: Review requirements for steering alignment, internal consistency, and clarity
- **Two Modes** (each with optional --deep):
  - **Single Review** (`/sdd-review-requirement {feature}`): Review one spec's requirements
  - **Cross-Check** (`/sdd-review-requirement`): Consistency check across all requirements
- **--deep flag**: Enables WebSearch/WebFetch for best practices research
- **Primary Goals**:
  - Ensure requirements align with steering documents (product.md, tech.md, structure.md)
  - Detect contradictions and ambiguities within requirements
  - Verify template conformance
- **Critical Focus: Steering Alignment**:
  - Requirements must reflect steering vision and constraints
  - Detect drift from project goals and technical boundaries
- **Success Criteria**:
  - Requirements traceable to steering context
  - No internal contradictions or ambiguities
  - Template conformance verified
  - Clear GO/CONDITIONAL/NO-GO verdict
</background_information>

<instructions>
## Core Task
Strict requirements review focusing on steering alignment and internal quality.

## Mode Detection
- **If `$ARGUMENTS` contains feature name**: Execute Single Review Mode
- **If `$ARGUMENTS` is empty or only `--deep`**: Execute Cross-Check Mode
- **If `$ARGUMENTS` contains `--deep`**: Enable best practices research (WebSearch/WebFetch)

## Flag Parsing
```
$ARGUMENTS = "{feature} --deep" → Single Review + Deep
$ARGUMENTS = "{feature}"        → Single Review
$ARGUMENTS = "--deep"           → Cross-Check + Deep
$ARGUMENTS = ""                 → Cross-Check
```

---

## Mode 1: Single Review

### Execution Steps

1. **Load Context**:
   - Read `{{KIRO_DIR}}/specs/{feature}/spec.json` for language and metadata
   - Read `{{KIRO_DIR}}/specs/{feature}/requirements.md`

2. **Load Steering Context** (CRITICAL):
   - Read entire `{{KIRO_DIR}}/steering/` directory:
     - `product.md` - Product vision, goals, user personas
     - `tech.md` - Technical constraints, standards, patterns
     - `structure.md` - Project structure, conventions
     - Any custom steering files

3. **Load Templates and Rules**:
   - Read `{{KIRO_DIR}}/settings/templates/specs/requirements.md` (template)
   - Read `{{KIRO_DIR}}/settings/rules/requirement-review.md`

4. **Execute Review** (three perspectives):

   **A. Steering Alignment Check** (HIGHEST PRIORITY):
   - Do requirements support product goals from product.md?
   - Do requirements respect technical constraints from tech.md?
   - Do requirements follow conventions from structure.md?
   - Flag: Requirements contradicting steering vision
   - Flag: Requirements outside declared scope
   - Flag: Requirements violating technical boundaries

   **B. Template Conformance Check**:
   - Has Introduction section
   - Has numbered Requirement sections (1, 2, 3...)
   - Each requirement has Objective (user story format)
   - Each requirement has Acceptance Criteria (EARS format)
   - No implementation details (component names, API specs)

   **C. Internal Quality Check**:
   - Ambiguous language detection
   - Contradictions between requirements
   - Completeness (edge cases, error scenarios)
   - Testability (can acceptance criteria be verified?)

5. **Provide Verdict**:
   - **GO**: Requirements ready for design phase
   - **CONDITIONAL**: Minor issues, can proceed with clarifications
   - **NO-GO**: Critical issues must be resolved first

---

## Mode 2: Cross-Check

### Execution Steps

1. **Discover All Specs**:
   - Glob `{{KIRO_DIR}}/specs/*/spec.json` to find all specs
   - Read all `requirements.md` files

2. **Load Steering Context**:
   - Read entire `{{KIRO_DIR}}/steering/` directory

3. **Load Rules**:
   - Read `{{KIRO_DIR}}/settings/rules/requirement-review.md`

4. **Execute Cross-Check**:

   **A. Inter-Requirement Consistency**:
   - Terminology unification across specs
   - No conflicting expectations for same behavior
   - Dependency clarity between specs

   **B. Scope/Responsibility Separation**:
   - Each spec has clear, non-overlapping scope
   - No duplicate requirements across specs
   - Shared concerns properly allocated

   **C. Steering Coherence**:
   - All requirements collectively support steering vision
   - No spec contradicts another's steering alignment
   - Technical constraints respected across all specs

   **D. Template Conformance**:
   - All requirements.md follow template structure

5. **Assess Development Readiness**:
   - Independent specs (can design in parallel)
   - Sequential dependencies
   - Specs requiring coordination

---

## --deep Flag: Best Practices Research

### Purpose
Enhance review quality through requirements engineering best practices research.

**Key Goal**: Capture discovered knowledge into steering documents so future reviews don't need to re-search.

### Additional Steps (when --deep is enabled)

1. **Execute Base Review** (Single Review or Cross-Check)

2. **Best Practices Research**:
   - **WebSearch**: Search for industry best practices related to:
     - Requirements writing standards (IEEE, INCOSE)
     - Domain-specific requirement patterns
     - Common requirement anti-patterns
     - Latest domain knowledge and industry trends
     - Known edge cases and failure modes
   - **WebFetch**: Retrieve detailed information from:
     - Requirements engineering guidelines
     - Industry standards documentation
     - Case studies on requirement quality

3. **Enhanced Analysis**:
   - Compare requirements against industry standards
   - Identify improvement opportunities
   - Flag potential issues from research insights

4. **Steering Update Proposal** (CRITICAL for --deep):
   - Identify domain knowledge that should be persisted for future reviews
   - Propose updates to existing steering files (product.md, tech.md, structure.md)
   - Propose new custom steering files for domain-specific knowledge
   - Focus on: Business rules, edge cases, compliance requirements, user behavior patterns

5. **Provide Enhanced Verdict**:
   - Base verdict
   - **Best Practices Alignment**: How well do requirements follow standards?
   - **Improvement Opportunities**: Specific suggestions from research
   - **Steering Proposals**: Recommended steering updates

### Deep Review Output Additions
```markdown
## Best Practices Research

### Standards Consulted
- [Standard 1]: [Key findings]
- [Standard 2]: [Key findings]

### Alignment Assessment
✅ **Aligned**: [Practices the requirements follow well]
⚠️ **Consider**: [Practices worth adopting]
❌ **Divergent**: [Areas where requirements deviate from best practices]

### Recommended Improvements
1. [Improvement based on research]
2. [Improvement based on research]

## Steering Update Proposals

### Purpose
Persist discovered domain knowledge so future reviews don't need to re-search.

### Existing Steering Updates
Proposed changes to existing steering files:

#### product.md
```markdown
## [Section to add/update]
[Content based on research - user behavior patterns, business rules, etc.]
```

#### tech.md
```markdown
## [Section to add/update]
[Content based on research - technical constraints, compliance requirements, etc.]
```

### New Custom Steering Proposals
Recommended new steering files for domain-specific knowledge:

#### Proposed: `steering/{domain}-requirements.md`
**Rationale**: [Why this knowledge should be captured]
```markdown
# [Domain] Requirements Knowledge

## Business Rules
- [Rule discovered from research]
- [Compliance requirement]

## Known Edge Cases
- [Edge case 1]: [Expected behavior]
- [Edge case 2]: [Expected behavior]

## User Behavior Patterns
- [Pattern]: [How to address in requirements]

## Common Pitfalls
- [Pitfall]: [How to avoid]
```

### Knowledge Capture Summary
| Knowledge Type | Source | Proposed Location | Priority |
|---------------|--------|-------------------|----------|
| [Business rule] | [URL] | product.md | High |
| [Edge case] | [URL] | {domain}-requirements.md | Medium |
| [Compliance req] | [URL] | tech.md | High |
```

---

## Important Constraints

### Steering Alignment (Primary Focus)
- **Vision alignment**: Requirements must support product goals
- **Technical boundaries**: Requirements must respect tech constraints
- **Scope discipline**: Requirements must stay within declared scope
- **Traceability**: Every requirement should connect to steering context

### Template Conformance (Anti-Drift)
- **Structure**: Must follow requirements.md template
- **Format**: User stories + EARS acceptance criteria
- **No HOW**: No implementation details in requirements

### Quality Standards
- **No ambiguity**: Every requirement must be testable
- **No contradictions**: Requirements must be internally consistent
- **Completeness**: Edge cases and errors addressed
- **--deep only**: WebSearch/WebFetch ONLY when --deep flag is present
</instructions>

## Tool Guidance
- **Read**: Load specs, steering documents, templates, and rules
- **Glob**: Discover all specs for cross-check mode
- **Grep**: Search for terminology usage and pattern detection
- **WebSearch** (--deep only): Research requirements engineering best practices
- **WebFetch** (--deep only): Retrieve detailed standards and guidelines

## Output Description
Follow the output format defined in `{{KIRO_DIR}}/settings/rules/requirement-review.md`:
- Single Review: Summary → Steering Alignment → Template Conformance → Issues → Verdict
- Cross-Check: Specs Analyzed → Cross-Spec Issues → Scope Assessment → Development Readiness
- With --deep: Add Best Practices Research + Enhanced Verdict to either mode

## Safety & Fallback

### Error Scenarios
- **Missing Spec**: If spec directory doesn't exist, stop with message: "Spec '{feature}' not found. Run `/sdd-requirements \"description\"` to create it."
- **No Specs Found** (Cross-Check): If no specs exist, stop with message: "No specs found in `{{KIRO_DIR}}/specs/`. Create specs first."
- **Missing Steering**: Warn that steering context is missing, review quality will be limited
- **Missing Requirements**: If requirements.md doesn't exist, skip spec with warning

### Next Steps

**After Single Review**:
- If GO: Proceed with `/sdd-design {feature}` to create design
- If CONDITIONAL: Address minor issues, optionally re-review
- If NO-GO: Fix critical issues and run `/sdd-review-requirement {feature}` again

**After Cross-Check**:
- Address any cross-requirement conflicts
- Ensure scope separation before parallel design work
- Use dependency information to sequence design phase
