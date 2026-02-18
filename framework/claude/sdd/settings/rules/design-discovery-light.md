# Light Discovery Process for Extensions

## Objective
Analyze the gap between requirements and the existing codebase, then determine integration strategy for feature extensions.

## Discovery Steps

### 1. Current State Investigation

**Scan Existing Codebase**:
- Key files/modules and directory layout related to the feature domain
- Reusable components, services, and utilities
- Dominant architecture patterns and constraints

**Extract Conventions**:
- Naming, layering, dependency direction
- Import/export patterns and dependency hotspots
- Testing placement and approach

**Map Integration Surfaces**:
- Data models/schemas relevant to the feature
- API clients, service interfaces, auth mechanisms
- Extension points or interfaces available

### 2. Feasibility Analysis

**From the Specifications, identify technical needs**:
- Data models, APIs/services, UI/components
- Business rules and validation
- Non-functionals: security, performance, scalability

**Identify gaps and constraints**:
- Missing capabilities in current codebase
- Unknowns requiring research (mark as "Research Needed")
- Constraints from existing architecture

### 3. Implementation Approach Decision

Evaluate and select the most appropriate approach:

**Option A: Extend Existing Components**
When the feature fits naturally into existing structure.
- Which files/modules to extend, impact on existing functionality
- Backward compatibility, single responsibility assessment
- Trade-offs: minimal new files, faster development / risk of bloating

**Option B: Create New Components**
When the feature has distinct responsibility or existing components are already complex.
- Rationale for new creation, integration points, responsibility boundaries
- Trade-offs: clean separation, easier testing / more files, careful interface design

**Option C: Hybrid Approach**
When complex features require both extension and new creation.
- Which parts extend, which parts are new, how they interact
- Trade-offs: balanced, allows iteration / more complex planning

Select and document the chosen approach with rationale.

### 4. Dependency & Technology Check

**Verify Compatibility**:
- Version compatibility of new dependencies
- API contracts haven't changed
- No breaking changes in pipeline

**For New Libraries Only**:
- WebSearch for official documentation
- Basic usage patterns and known compatibility issues
- Licensing compatibility
- Record findings in `research.md`

### 5. Risk Assessment

**Complexity & Risk Estimation**:
- Effort: S (1-3 days) | M (3-7 days) | L (1-2 weeks) | XL (2+ weeks)
- Risk: High (unknown tech, complex integrations) | Medium (new patterns with guidance) | Low (extend established patterns)

**Integration Risks**:
- Impact on existing functionality
- Performance implications
- Security considerations
- Testing requirements

## When to Escalate to Full Discovery

Switch to full discovery if you find:
- Significant architectural changes needed
- Complex external service integrations
- Security-sensitive implementations
- Performance-critical components
- Unknown or poorly documented dependencies

## Output Requirements
- Current codebase analysis summary (key patterns, integration surfaces)
- Chosen approach (Extend / Create / Hybrid) with rationale
- Effort (S/M/L/XL) and Risk (High/Medium/Low) with justification
- List of files/components to modify or create
- New dependencies with versions
- Integration risks and mitigations
- Testing focus areas
- Research items to carry forward (if any)
