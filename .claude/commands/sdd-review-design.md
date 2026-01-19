---
description: Strict spec review for test implementer clarity
allowed-tools: Read, Glob, Grep, WebSearch, WebFetch
argument-hint: [feature-name] [--deep]
---

# SDD Design Review for Test Implementer Clarity

<background_information>
- **Mission**: Review specs from a test implementer's perspective to ensure clarity, testability, and SDD compliance
- **Two Modes** (each with optional --deep):
  - **Single Review** (`/sdd-review-design {feature}`): Deep review of one spec
  - **Cross-Check** (`/sdd-review-design`): Consistency check across all specs
- **--deep flag**: Enables WebSearch/WebFetch for best practices research
- **Critical Focus: Prevent Spec Drift**:
  - Ensure specs remain compliant with SDD templates
  - Detect ad-hoc changes made outside SDD workflow
  - Pull drifted specs back into SDD compliance
- **Success Criteria**:
  - Test implementers can work without ambiguity
  - Specs follow SDD templates (no structural drift)
  - Clear separation: requirements.md = WHAT, design.md = HOW
  - Clear GO/CONDITIONAL/NO-GO verdict
  - Actionable feedback for improvements
</background_information>

<instructions>
## Core Task
Strict spec review from test implementer perspective.

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
   - Read `{{KIRO_DIR}}/specs/{feature}/design.md` (if exists)

2. **Load Templates and Rules**:
   - Read `{{KIRO_DIR}}/settings/templates/specs/requirements.md` (template)
   - Read `{{KIRO_DIR}}/settings/templates/specs/design.md` (template)
   - Read `{{KIRO_DIR}}/settings/rules/design-review.md`

3. **Execute Review** (three perspectives):

   **A. SDD Compliance Check** (HIGHEST PRIORITY):
   - Compare actual spec structure against templates
   - Flag missing required sections
   - Flag extra sections not in template
   - Detect requirements.md content leaked into design.md (and vice versa)

   **B. Responsibility Separation Check**:
   - requirements.md should contain WHAT (objectives, acceptance criteria)
   - design.md should contain HOW (architecture, components, interfaces)
   - Flag: Implementation details in requirements.md
   - Flag: New acceptance criteria in design.md
   - Flag: User stories or business rules in design.md

   **C. Test Implementer Clarity Check**:
   - Apply Single Review Checklist from design-review.md
   - Evaluate from test implementer perspective
   - Focus on: "Would I know exactly what to test?"

4. **Provide Verdict**:
   - **GO**: Test implementation can proceed
   - **CONDITIONAL**: Minor clarifications needed, can proceed with caution
   - **NO-GO**: Critical ambiguities must be resolved first

---

## Mode 2: Cross-Check

### Execution Steps

1. **Discover All Specs**:
   - Glob `{{KIRO_DIR}}/specs/*/spec.json` to find all specs
   - For each spec, check if `design.md` exists

2. **Load Review Rules**:
   - Read `{{KIRO_DIR}}/settings/rules/design-review.md`

3. **Execute Cross-Check**:
   - Apply Cross-Check Checklist from design-review.md
   - Compare requirements across specs
   - Compare designs across specs (where available)
   - Identify overlaps, conflicts, and dependencies

4. **Assess Parallel Development**:
   - Identify independent specs (can develop in parallel)
   - Identify sequential dependencies
   - Identify specs requiring coordination

---

## --deep Flag: Best Practices Research

### Purpose
Enhance review quality through thorough best practices research. Applies to both Single Review and Cross-Check modes.

**Key Goal**: Capture discovered knowledge into steering documents so future reviews don't need to re-search.

### Additional Steps (when --deep is enabled)

1. **Execute Base Review** (Single Review or Cross-Check)

2. **Best Practices Research**:
   - **WebSearch**: Search for industry best practices related to:
     - Key technologies/patterns mentioned in design.md
     - Similar problem domains and proven solutions
     - Common pitfalls and anti-patterns to avoid
     - Latest API changes, deprecations, migration guides
     - Known edge cases and gotchas
   - **WebFetch**: Retrieve detailed information from:
     - Official documentation
     - Authoritative technical resources
     - Case studies and reference implementations

3. **Enhanced Analysis**:
   - Compare design decisions against discovered best practices
   - Identify opportunities for improvement based on industry standards
   - Flag potential issues not covered in standard checklist

4. **Steering Update Proposal** (CRITICAL for --deep):
   - Identify knowledge that should be persisted for future reviews
   - Propose updates to existing steering files (tech.md, product.md, structure.md)
   - Propose new custom steering files for domain-specific knowledge
   - Focus on: Latest APIs, edge cases, implementation gotchas, best practices

5. **Provide Enhanced Verdict**:
   - Base verdict (GO/CONDITIONAL/NO-GO for Single Review, or Summary for Cross-Check)
   - **Best Practices Alignment**: How well do the design(s) follow industry standards?
   - **Improvement Opportunities**: Specific suggestions from research
   - **Steering Proposals**: Recommended steering updates

### Deep Review Output Additions
```markdown
## Best Practices Research

### Technologies Researched
- [Technology 1]: [Key findings]
- [Technology 2]: [Key findings]

### Alignment Assessment
✅ **Aligned**: [Practices the design follows well]
⚠️ **Consider**: [Practices worth adopting]
❌ **Divergent**: [Areas where design contradicts best practices]

### Recommended Improvements
1. [Improvement based on research]
2. [Improvement based on research]

## Steering Update Proposals

### Purpose
Persist discovered knowledge so future reviews don't need to re-search.

### Existing Steering Updates
Proposed changes to existing steering files:

#### tech.md
```markdown
## [Section to add/update]
[Content based on research - latest API patterns, constraints, etc.]
```

#### product.md / structure.md
[If applicable]

### New Custom Steering Proposals
Recommended new steering files for domain-specific knowledge:

#### Proposed: `steering/{domain}-patterns.md`
**Rationale**: [Why this knowledge should be captured]
```markdown
# [Domain] Patterns and Best Practices

## Latest API Considerations
- [API change discovered]
- [Deprecation warning]

## Known Edge Cases
- [Edge case 1]: [How to handle]
- [Edge case 2]: [How to handle]

## Implementation Gotchas
- [Gotcha 1]: [What to avoid and why]

## Recommended Patterns
- [Pattern]: [When and how to use]
```

### Knowledge Capture Summary
| Knowledge Type | Source | Proposed Location | Priority |
|---------------|--------|-------------------|----------|
| [API update] | [URL] | tech.md | High |
| [Edge case] | [URL] | {domain}-patterns.md | Medium |
| [Best practice] | [URL] | {domain}-patterns.md | Medium |
```

---

## Important Constraints

### SDD Compliance (Anti-Drift)
- **Template conformance**: Specs MUST follow SDD template structure
- **Responsibility separation**: requirements.md = WHAT, design.md = HOW
- **No ad-hoc additions**: Flag content that bypasses SDD workflow
- **Pull back to SDD**: Recommend moving misplaced content to correct location

### Review Quality
- **Test implementer perspective**: Always ask "Can I write unambiguous tests?"
- **Specific, not vague**: Flag any imprecise language
- **Actionable feedback**: Every issue must have a clear fix
- **Severity classification**: Distinguish critical vs. warning issues
- **--deep only**: WebSearch/WebFetch are ONLY allowed when --deep flag is present
</instructions>

## Tool Guidance
- **Read**: Load specs, requirements, designs, and rules
- **Glob**: Discover all specs for cross-check mode
- **Grep**: Search for terminology usage across specs
- **WebSearch** (--deep only): Research best practices and industry standards
- **WebFetch** (--deep only): Retrieve detailed documentation and resources

## Output Description
Follow the output format defined in `{{KIRO_DIR}}/settings/rules/design-review.md`:
- Single Review: Summary → Critical Issues → Warnings → Verdict
- Cross-Check: Specs Analyzed → Cross-Spec Issues → Parallel Development Assessment
- With --deep: Add Best Practices Research + Enhanced Verdict to either mode

## Safety & Fallback

### Error Scenarios
- **Missing Spec**: If spec directory doesn't exist, stop with message: "Spec '{feature}' not found. Run `/sdd-requirements \"description\"` to create it."
- **No Specs Found** (Cross-Check): If no specs exist, stop with message: "No specs found in `{{KIRO_DIR}}/specs/`. Create specs first."
- **Missing Requirements**: If requirements.md doesn't exist, skip spec with warning

### Next Steps

**After Single/Deep Review**:
- If GO: Proceed with `/sdd-impl {feature}` or test implementation
- If CONDITIONAL: Address minor issues, optionally re-review
- If NO-GO: Fix critical issues and run `/sdd-review-design {feature}` again

**After Cross-Check**:
- Address any cross-spec conflicts before parallel development
- Use dependency information to sequence implementation
