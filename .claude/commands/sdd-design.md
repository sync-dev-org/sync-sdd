---
description: Create comprehensive technical design for a specification
allowed-tools: Bash, Glob, Grep, LS, Read, Write, Edit, MultiEdit, WebSearch, WebFetch
argument-hint: <feature-name-or-"description">
---

# SDD Technical Design Generator

<background_information>
- **Mission**: Generate comprehensive design document including specifications (WHAT) and architectural design (HOW) in a single document
- **Success Criteria**:
  - All specifications defined with testable acceptance criteria
  - Specifications mapped to technical components with clear interfaces
  - Appropriate architecture discovery and research completed
  - Design aligns with steering context and existing patterns
  - Visual diagrams included for complex architectures
</background_information>

<instructions>
## Core Task
Generate design document for feature **$1** including specifications and technical design.

## Input Mode Detection

Determine mode from $1:
- **New Spec**: $1 is a quoted description string (e.g., `"ユーザー認証機能"`) → Create new spec from scratch
- **Existing Spec**: $1 is an existing feature name (e.g., `auth-flow`) → Edit/regenerate existing design

## Execution Steps

### Step 0: Initialize Spec (New Spec mode only)

If $1 is a description (not an existing feature directory):

1. **Generate feature name**: Convert description to kebab-case feature name
2. **Create spec directory**: `{{KIRO_DIR}}/specs/{feature-name}/`
3. **Initialize spec.json** from `{{KIRO_DIR}}/settings/templates/specs/init.json`:
   - Set `feature_name`, `created_at`, `updated_at`
   - Detect language from steering context or default to user's language
   - Set `phase: "initialized"`
4. **Inform user**: Report the generated feature name
5. **Continue to Step 1** with the generated feature name as $1

### Step 1: Load Context

**Read all necessary context**:
- `{{KIRO_DIR}}/specs/$1/spec.json`, `design.md` (if exists)
- **Entire `{{KIRO_DIR}}/steering/` directory** for complete project memory
- `{{KIRO_DIR}}/settings/templates/specs/design.md` for document structure
- `{{KIRO_DIR}}/settings/rules/design-principles.md` for design principles
- `{{KIRO_DIR}}/settings/templates/specs/research.md` for discovery log structure

**Version consistency check** (skip if `version_refs` not present):
- Read `version` and `version_refs` from spec.json (default: `version ?? "1.0.0"`, `version_refs ?? {}`)
- If existing design.md has a Specifications section, note it for merge mode

### Step 2: Discovery & Analysis

**Critical: This phase ensures design is based on complete, accurate information.**

1. **Classify Feature Type**:
   - **New Feature** (greenfield) → Full discovery required
   - **Extension** (existing system) → Integration-focused discovery
   - **Simple Addition** (CRUD/UI) → Minimal or no discovery
   - **Complex Integration** → Comprehensive analysis required

2. **Execute Appropriate Discovery Process**:

   **For Complex/New Features**:
   - Read and execute `{{KIRO_DIR}}/settings/rules/design-discovery-full.md`
   - Conduct thorough research using WebSearch/WebFetch:
     - Latest architectural patterns and best practices
     - External dependency verification (APIs, libraries, versions, compatibility)
     - Official documentation, migration guides, known issues
     - Performance benchmarks and security considerations

   **For Extensions**:
   - Read and execute `{{KIRO_DIR}}/settings/rules/design-discovery-light.md`
   - Focus on integration points, existing patterns, compatibility
   - Use Grep to analyze existing codebase patterns

   **For Simple Additions**:
   - Skip formal discovery, quick pattern check only

3. **Retain Discovery Findings for Step 3**:
- External API contracts and constraints
- Technology decisions with rationale
- Existing patterns to follow or extend
- Integration points and dependencies
- Identified risks and mitigation strategies
- Potential architecture patterns and boundary options (note details in `research.md`)
- Parallelization considerations for future tasks (capture dependencies in `research.md`)

4. **Persist Findings to Research Log**:
- Create or update `{{KIRO_DIR}}/specs/$1/research.md` using the shared template
- Summarize discovery scope and key findings (Summary section)
- Record investigations in Research Log topics with sources and implications
- Document architecture pattern evaluation, design decisions, and risks using the template sections
- Use the language specified in spec.json when writing or updating `research.md`

### Step 3: Generate Design Document

1. **Load Design Template and Rules**:
- Read `{{KIRO_DIR}}/settings/templates/specs/design.md` for structure
- Read `{{KIRO_DIR}}/settings/rules/design-principles.md` for principles

2. **Generate Design Document**:
- **Follow specs/design.md template structure strictly**
- **Specifications section**: Define numbered specs with goals and testable acceptance criteria in natural language. **Do NOT include internal implementation identifiers** (function names, variable names, class names, method signatures, database column names). Describe observable behavior and outcomes only. External-facing technical requirements (e.g., "REST API", "WebSocket", "CLI command") are acceptable.
- **Architecture and Components sections**: Translate specifications into technical design
- **Integrate all discovery findings**: Use researched information throughout
- If existing design.md found in Step 1, use it as reference context (merge mode)
- Apply design rules: Type Safety, Visual Communication, Formal Tone
- Use language specified in spec.json
- Ensure Specifications Traceability maps spec IDs to components

3. **Update Metadata** in spec.json:
- Set `phase: "design-generated"`
- Update `updated_at` timestamp
- **Version tracking** (initialize defaults if fields missing):
  - **Version bump** (on re-edit only): If `version_refs.design` already has a non-null value (i.e., design was previously generated), increment the spec `version` minor number (e.g., `"1.0.0"` → `"1.1.0"`, `"1.3.0"` → `"1.4.0"`). On first design generation, keep the initial version as-is.
  - Set `version_refs.design` to the (possibly bumped) spec `version`
  - Set `version_refs.tasks` to `null` (invalidate stale task reference)
  - Append changelog entry: `{ "version": "{CURRENT_VER}", "date": "{ISO_DATE}", "phase": "design", "summary": "Design generated" }`

## Critical Constraints
 - **Type Safety**:
   - Enforce strong typing aligned with the project's technology stack.
   - For statically typed languages, define explicit types/interfaces and avoid unsafe casts.
   - For TypeScript, never use `any`; prefer precise types and generics.
   - For dynamically typed languages, provide type hints/annotations where available (e.g., Python type hints) and validate inputs at boundaries.
   - Document public interfaces and contracts clearly to ensure cross-component type safety.
- **Latest Information**: Use WebSearch/WebFetch for external dependencies and best practices
- **Steering Alignment**: Respect existing architecture patterns from steering context
- **Template Adherence**: Follow specs/design.md template structure strictly
- **Design Focus**: Architecture and interfaces ONLY, no implementation code
- **Spec Traceability IDs**: Use numeric spec IDs only (e.g. "1.1", "1.2", "3.1") as defined in the Specifications section. Do not invent new IDs or use alphabetic labels.
</instructions>

## Tool Guidance
- **Read first**: Load all context before taking action (specs, steering, templates, rules)
- **Research when uncertain**: Use WebSearch/WebFetch for external dependencies, APIs, and latest best practices
- **Analyze existing code**: Use Grep to find patterns and integration points in codebase
- **Write last**: Generate design.md only after all research and analysis complete

## Output Description

**Command execution output** (separate from design.md content):

Provide brief summary in the language specified in spec.json:

1. **Status**: Confirm design document generated at `{{KIRO_DIR}}/specs/$1/design.md`
2. **Discovery Type**: Which discovery process was executed (full/light/minimal)
3. **Key Findings**: 2-3 critical insights from `research.md` that shaped the design
4. **Next Action**: Next step guidance (see Safety & Fallback)
5. **Research Log**: Confirm `research.md` updated with latest decisions

**Format**: Concise Markdown (under 200 words) - this is the command output, NOT the design document itself

**Note**: The actual design document follows `{{KIRO_DIR}}/settings/templates/specs/design.md` structure.

## Safety & Fallback

### Error Scenarios

**Missing Spec (Existing Spec mode)**:
- **Stop Execution**: Spec directory must exist
- **User Message**: "No spec found at `{{KIRO_DIR}}/specs/$1/`"
- **Suggested Action**: "Run `/sdd-design \"description\"` to create a new specification"

**Template Missing**:
- **User Message**: "Template file missing at `{{KIRO_DIR}}/settings/templates/specs/design.md`"
- **Suggested Action**: "Check repository setup or restore template file"
- **Fallback**: Use inline basic structure with warning

**Steering Context Missing**:
- **Warning**: "Steering directory empty or missing - design may not align with project standards"
- **Proceed**: Continue with generation but note limitation in output

**Discovery Complexity Unclear**:
- **Default**: Use full discovery process (`{{KIRO_DIR}}/settings/rules/design-discovery-full.md`)
- **Rationale**: Better to over-research than miss critical context

**Invalid Spec IDs**:
- **Stop Execution**: If Specifications section uses non-numeric headings (e.g., "Spec A"), stop and fix before continuing.

### Next Phase: Task Generation

- Review generated design at `{{KIRO_DIR}}/specs/$1/design.md`
- **Optional**: Run `/sdd-review-design $1` for quality review
- Then `/sdd-tasks $1` to generate implementation tasks

**If Modifications Needed**:
- Provide feedback and re-run `/sdd-design $1`
- Existing design used as reference (merge mode)

think hard
