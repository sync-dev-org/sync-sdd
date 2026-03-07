# Full Discovery Process for Technical Design

## Objective
Conduct comprehensive research and analysis to ensure the technical design is based on complete, accurate, and up-to-date information.

## Discovery Steps

### 1. Specifications Analysis
**Map Specifications to Technical Needs**
- Extract all functional specifications from the Specifications section of design.md
- Identify non-functional requirements (performance, security, scalability)
- Determine technical constraints and dependencies
- List core technical challenges

### 2. Existing Implementation Analysis
**Understand Current System** (if modifying/extending):
- Analyze codebase structure and architecture patterns
- Map reusable components, services, utilities
- Identify domain boundaries and data flows
- Document integration points and dependencies
- Determine approach: extend vs refactor vs wrap

### 3. External Dependencies Source Inspection
**For Each External SDK/Library** (if Lead provided installed SDK source paths):
- Read installed SDK source code via Read/Glob to extract ground truth:
  - Function signatures and parameter types
  - Class hierarchies and inheritance
  - Type annotations and return types
  - Async/sync behavior (coroutine vs generator vs sync)
- Record verified signatures in `research.md`:
  `"Verified from installed {package} v{version} source"`
- If SDK is NOT installed (no source paths provided):
  note as `"unverifiable — from WebSearch"` and proceed to Step 5

### 4. Design Draft
**Form Initial Architecture** based on source understanding + existing code:
- Identify integration patterns and error handling approaches
- Map data flow between components and external dependencies
- Draft component boundaries and interfaces
- This draft will be validated and enriched in Step 5

### 5. Technology Research + Validation (WebSearch/WebFetch)
**Validate design draft against community knowledge**:
- **Use WebSearch** to find:
  - Recommended usage patterns for the external SDKs/libraries
  - Known pitfalls, common mistakes, and solutions
  - Latest architectural patterns for similar problems
  - Industry best practices for the technology stack
  - Recent updates, breaking changes, or migration guides

- **Use WebFetch** to analyze:
  - Official documentation for frameworks/libraries
  - API references and usage examples
  - Performance benchmarks and comparisons

- **Assess design draft**: confirmed / better alternative found / novel approach
- **Gather non-source information**: rate limits, authentication methods,
  operational constraints, future breaking changes, licensing

### 6. Design Refinement
**Incorporate web findings into design**:
- Update design draft with best practices discovered in Step 5
- Resolve any conflicts between source inspection and web findings
  (see Source vs WebSearch Priority below)
- Document decisions and rejected alternatives in `research.md`

### 7. Architecture Pattern & Boundary Analysis
**Evaluate Architectural Options**:
- Compare relevant patterns (MVC, Clean, Hexagonal, Event-driven)
- Assess fit with existing architecture and steering principles
- Identify domain boundaries and ownership seams required to avoid team conflicts
- Consider scalability implications and operational concerns
- Evaluate maintainability and team expertise
- Document preferred pattern and rejected alternatives in `research.md`

### 8. Risk Assessment
**Identify Technical Risks**:
- Performance bottlenecks and scaling limits
- Security vulnerabilities and attack vectors
- Integration complexity and coupling
- Technical debt creation vs resolution
- Knowledge gaps and training needs

## Research Guidelines

### Source vs WebSearch Priority
- **API contracts** (signatures, types, async behavior): installed SDK source is authoritative
- **Usage patterns** (best practices, recommended approaches): WebSearch is authoritative
- **Operational constraints** (rate limits, auth, quotas): WebSearch is authoritative
- If conflict: document both in research.md. Source wins for contracts, web wins for practice.

### When to Search
**Always search for**:
- Recommended usage patterns and best practices for external SDKs
- Security best practices for authentication/authorization
- Performance optimization techniques for identified bottlenecks
- Latest versions and migration paths for dependencies

**Search if uncertain about**:
- Architectural patterns for specific use cases
- Industry standards for data formats/protocols
- Compliance requirements (GDPR, HIPAA, etc.)
- Scalability approaches for expected load

### Search Strategy
1. Start with official sources (documentation, GitHub)
2. Check recent blog posts and articles (last 6 months)
3. Review Stack Overflow for common issues
4. Investigate similar open-source implementations

## Output Requirements
Capture all findings that impact design decisions in `research.md` using the shared template:
- Key insights affecting architecture, technology alignment, and contracts
- Constraints discovered during research
- Recommended approaches and selected architecture pattern with rationale
- Rejected alternatives and trade-offs (documented in the Design Decisions section)
- Updated domain boundaries that inform Components and Interfaces
- Risks and mitigation strategies
- Gaps requiring further investigation during implementation
