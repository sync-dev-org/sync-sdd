---
description: Generate product-wide specification roadmap and initialize multiple specs with research-driven requirements
allowed-tools: Glob, Grep, Read, Write, Edit, AskUserQuestion, Task
argument-hint: [-y]
---

# Create Specification Roadmap

<background_information>
- **Mission**: Generate a product-wide specification roadmap and initialize multiple specs with research-driven requirements documents
- **Success Criteria**:
  - **Product understanding verified with user** (prevent domain misunderstanding)
  - Spec candidates proposed from steering documents
  - **Optional domain research** (if user requests):
    - Phase 4: Targeted research for critical insights (innovative patterns, edge cases, breaking changes)
    - Spec candidates refined based on critical findings (if any)
  - **Individual spec research completed** (always):
    - Phase 5: Targeted research for each spec (innovative patterns, edge cases, breaking changes)
    - ONLY critical findings recorded in research.md (not exhaustive)
  - Comprehensive spec inventory with dependencies mapped
  - Clear implementation waves with parallel execution opportunities
  - **Multiple spec directories created with research-driven requirements.md files**
  - Requirements informed by targeted research (not exhaustive or superficial)
  - Ready for design phase via `/sdd-design`
</background_information>

<instructions>

## Core Philosophy

This is an **exploratory, collaborative task** with **targeted research**. Steering documents provide initial context for spec candidates. Research focuses on critical insights only:
- **Phase 2**: Propose spec candidates from steering documents
- **Phase 4 (optional)**: Targeted domain research if user requests (ONLY critical insights)
- **Phase 5 (always)**: Targeted research for each spec (ONLY critical findings)
- **NOT exhaustive**: Skip obvious patterns and generic best practices
- Share ONLY critical findings with the user
- Use targeted research to create ready-to-implement requirements
- Build the roadmap iteratively through dialogue
- Focus on "discovering together" rather than "outputting answers"

**CRITICAL - Details Before Confirmation**:
- NEVER ask for YES/NO confirmation with only a one-line summary
- ALWAYS output full details as text FIRST, THEN ask for confirmation
- Users need complete information to make informed decisions
- Pattern: [Show detailed findings/proposals] → [AskUserQuestion for approval]

## Auto-Approve Mode

**If `-y` flag is provided**:
- Skip Phase 4 domain research (go directly from candidates to waves)
- Auto-approve spec candidates and wave organization
- Phase 5 individual spec research still executes (always required)
- Create spec directories and requirements without confirmation prompts
- Still provide summary of what was done

## Execution Steps

### Phase 1: Context Load

1. **Read rules and templates**:

   **Rules**:
   - Read `{{KIRO_DIR}}/settings/rules/steering-principles.md` (for understanding steering update criteria)
   - Read `{{KIRO_DIR}}/settings/rules/ears-format.md` (for requirements generation)

   **Steering Templates** (understand what each file should contain):
   - Read `{{KIRO_DIR}}/settings/templates/steering/product.md`
   - Read `{{KIRO_DIR}}/settings/templates/steering/tech.md`
   - Read `{{KIRO_DIR}}/settings/templates/steering/structure.md`

   **Custom Steering Templates** (understand more detailed patterns allowed):
   - Read `{{KIRO_DIR}}/settings/templates/steering-custom/database.md`
   - Read `{{KIRO_DIR}}/settings/templates/steering-custom/api-standards.md`
   - Read `{{KIRO_DIR}}/settings/templates/steering-custom/testing.md`
   - Read `{{KIRO_DIR}}/settings/templates/steering-custom/security.md`
   - (and others if relevant to the domain)

   **Spec Templates** (for skeleton generation in Phase 5):
   - Read `{{KIRO_DIR}}/settings/templates/specs/requirements.md`
   - Read `{{KIRO_DIR}}/settings/templates/specs/research.md`
   - Read `{{KIRO_DIR}}/settings/templates/specs/init.json`

   **Purpose**:
   - Understand what content is appropriate for each steering file
   - Understand how to generate proper skeleton requirements.md and research.md

2. **Read ALL steering documents**:
   - Read entire `{{KIRO_DIR}}/steering/` directory:
     - `product.md` - Product vision, goals, user personas
     - `tech.md` - Technical constraints, standards, patterns
     - `structure.md` - Project structure, conventions
     - All custom steering files

3. **Scan existing specs**:
   - Glob `{{KIRO_DIR}}/specs/*/spec.json` to understand existing features
   - Read each spec's `requirements.md` (if exists) to understand scope
   - Build inventory of existing specs with their phases

### Phase 2: Product Understanding and Spec Candidate Inference

**Purpose**: Verify product understanding and propose spec candidates from steering documents.

**CRITICAL**: Prevent domain misunderstanding. Domain research is optional and user-directed.

1. **Report product understanding**:

   **Output as text and ASK FOR CONFIRMATION**:
   ```
   ## Product Understanding

   Based on steering documents, I understand this product as:

   **Domain**: [具体的なドメイン]
   **Core Purpose**: [プロダクトの核心的目的]
   **Target Users**: [想定ユーザー]
   **Key Technical Areas**: [主要技術領域]
   **Similar Products**: [類似と思われるプロダクト]

   Is this understanding correct? Should I adjust?
   ```

   **Use AskUserQuestion**:
   - Show understanding first as text
   - Then ask: "Is this product understanding correct?"
   - If user corrects, update understanding before proceeding

2. **Generate spec candidate list from steering**:
   - Cross-reference `product.md` Core Capabilities
   - Map `structure.md` modules to potential specs
   - Each candidate should have:
     - Name (kebab-case)
     - Brief description
     - Rationale (why this spec is needed)
     - Source (steering section)

3. **Check for duplicates** with existing specs:
   - Compare against `{{KIRO_DIR}}/specs/*/` inventory
   - Mark overlaps or extensions

4. **Present candidates to user in detail** (unless `-y`):

   **First, output full details as text**:

   **Format rules for visual clarity**:
   - Use **bold headers** with clear separation
   - Group related specs together
   - Use blank line + heavy separator (═══) between groups

   ```
   ## Spec Candidates (from steering)

   ═══════════════════════════════════════════════════════════
   ### Foundation Layer
   ═══════════════════════════════════════════════════════════

   **spec-name-a**
   - Description: Brief description
   - Rationale: Why needed
   - Source: product.md - Core Capabilities

   **spec-name-b**
   - Description: Brief description
   - Rationale: Why needed
   - Source: structure.md - Module X

   ═══════════════════════════════════════════════════════════
   ### Core Features
   ═══════════════════════════════════════════════════════════

   **spec-name-c**
   - Description: Brief description
   - Rationale: Why needed
   - Source: product.md - Feature Y

   ...
   ```

   **Then, inform user about optional research**:
   ```
   These spec candidates are based on steering documents.

   If you want domain research to validate or enrich these candidates:
   - Say "research this" or "conduct domain research"
   - I'll delegate research to a subagent and refine candidates based on findings

   Otherwise, we can proceed directly to wave organization.
   ```

   **Then, ask for confirmation** using AskUserQuestion:
   - Only AFTER showing the full details above
   - Options: "Proceed with these specs", "Conduct domain research first", "Modify candidates"

### Phase 3: Wave Organization

**Purpose**: Organize spec candidates into implementation waves based on dependencies.

1. **Analyze technical dependencies**:
   - Identify which specs depend on others
   - Map data flow and integration points
   - Note shared infrastructure needs

2. **Organize into waves**:
   - **Wave 1 (Foundation)**: Core infrastructure, base utilities, data models
   - **Wave 2 (Core)**: Primary features, main business logic
   - **Wave 3 (Integration)**: Cross-feature integrations, workflows
   - **Wave 4 (Interface)**: UI/API layers, user-facing polish

3. **Identify parallel execution opportunities**:
   - Within each wave, mark specs that can be developed simultaneously
   - Note specs that must be sequential

4. **Present wave organization in detail** (unless `-y`):

   **First, output full details as text**:

   a. **Dependency Graph** (mermaid format):
      ```mermaid
      graph TD
        spec-a --> spec-b
        spec-a --> spec-c
        ...
      ```

   b. **Wave Breakdown**:
      ```
      ## Wave 1 (Foundation)
      - spec-a: [description] (parallel: yes)
      - spec-b: [description] (parallel: yes)

      ## Wave 2 (Core) - depends on Wave 1
      - spec-c: [description] (depends on: spec-a)
      ...
      ```

   **Then, ask for confirmation** using AskUserQuestion:
   - Only AFTER showing the full details above
   - Ask: "Proceed with this wave organization?"

### Phase 4: Optional Domain Research

**Purpose**: Conduct domain research to validate or enrich spec candidates (user-directed only).

**When to execute**: Only when user explicitly requests "research this" or "conduct domain research" during Phase 2.

**If user requests research**:

1. **Delegate domain research to subagent**:

   **Use Task tool with subagent_type="general-purpose"**:

   Pass the following to subagent:
   - Domain, purpose, technical areas (from Phase 2 product understanding)
   - Research requirements (4 categories: Academic, Design Patterns, Technology, Production)
   - Instructions to use WebSearch + WebFetch to read FULL content
   - Output format: structured summary with key findings

   See "Tool Guidance > Subagent Delegation > Phase 4 (Optional Domain Research)" for detailed prompt.

2. **Receive and present research findings**:

   **Output full details as text**:
   - What was researched (specific queries, academic sources)
   - Key discoveries from papers/engineering blogs
   - Established design patterns identified
   - Technology selection rationale
   - How findings inform spec candidates (component breakdown, naming, scope)

3. **Refine spec candidates based on research** (if needed):
   - Adjust candidate names/descriptions based on industry standards
   - Add missing components revealed by research
   - Update rationales with research references

4. **Re-present refined candidates**:
   - Show updated spec candidate list
   - Highlight changes made based on research
   - Ask for confirmation to proceed

**Note**: Research findings will be passed to Phase 5 subagents and recorded in each spec's `research.md`

### Phase 5: Spec Initialization with Individual Research

**Purpose**: Create spec directories with research-driven requirements for all planned specs using parallel subagents.

**Research approach**:
- Phase 4 (optional): Domain research for spec breakdown validation (if user requested)
- Phase 5 (always): Individual spec research for detailed requirements and implementation guidance

1. **Prepare spec list**:
   - Combine existing specs (from Phase 1) with new spec candidates (from Phase 3)
   - For existing specs: Skip directory creation, optionally update metadata
   - For new specs: Create full skeleton via subagents

2. **For each NEW spec candidate**:

   a. **Create directory and spec.json** [Main agent executes]:
      - Create `{{KIRO_DIR}}/specs/[spec-name]/`
      - Generate spec.json with roadmap metadata
      - Set `phase: "requirements-generated"`

   b-e. **Delegate research and file generation to subagent** [Subagent executes]:

   **Use Task tool with subagent_type="general-purpose"** for EACH spec:

   Pass the following to subagent:
   - Spec name, description, wave, dependencies
   - Domain research summary from Phase 4 (if available, otherwise "N/A")
   - Template paths (requirements.md, research.md, ears-format.md)
   - Instructions to:
     1. Conduct individual spec research (WebSearch + WebFetch)
     2. Generate requirements.md with EARS format
     3. Generate research.md with all findings

   See "Tool Guidance > Subagent Delegation > Phase 5" for detailed prompt.

   **IMPORTANT**: Launch all spec subagents **IN PARALLEL** (single message with multiple Task calls) to maximize efficiency.

3. **Wait for all subagents to complete**:
   - Subagents will create requirements.md and research.md in parallel
   - Each subagent has isolated 200K token context
   - WebFetch results stay in subagent contexts

4. **Verify created files**:
   - Check that all specs have requirements.md and research.md
   - Report any errors (missing files, write failures)

5. **Present creation summary** (unless `-y`):
   - Show table of created specs with wave assignments and research quality
   - Ask: "Proceed with spec initialization?"

5. **Generate roadmap.md** (project-wide roadmap file):
   - Write to `{{KIRO_DIR}}/specs/roadmap.md`
   - **NOT in steering** (to avoid context pollution for individual spec implementers)
   - **Plan only, no progress tracking** (progress is dynamically calculated by `/sdd-status`)
   - Content structure:
     ```markdown
     # Specification Roadmap

     Generated: {{TIMESTAMP}}

     ## Wave Overview

     | Wave | Name | Specs |
     |------|------|-------|
     | 1 | Foundation | schemas-core, core-utilities |
     | 2 | Core | feature-a, feature-b |

     ## Dependency Graph

     ```mermaid
     graph TD
       schemas-core --> feature-a
       ...
     ```

     ## Implementation Order

     ### Wave 1 (Foundation)
     - schemas-core (P)
     - core-utilities (P)

     ### Wave 2 (Core) - depends on Wave 1
     - feature-a (depends on: schemas-core)
     ...
     ```
   - This file is read by `/sdd-status` for Wave structure (progress is calculated from spec.json files)

</instructions>

## Tool Guidance

### File Operations
- **Read**: Load all steering, existing specs, and templates before analysis
- **Glob**: Find existing spec directories and config files
- **Write**: Create spec.json, requirements.md, research.md, and roadmap.md for each spec

### Domain Research (WebSearch/WebFetch) - Targeted Research Only

**CRITICAL**:
1. Focus ONLY on critical insights that impact spec breakdown or requirements
2. **DO NOT be exhaustive** - Skip obvious patterns and generic best practices
3. **DO NOT stop at WebSearch summaries** - Use WebFetch to read full content
4. Record ONLY findings with implementation value

**Optional Domain Research (Phase 4)**
- **When**: ONLY when user explicitly requests during Phase 2 ("research this", "conduct domain research")
- **Goal**: Find critical insights that impact spec breakdown
- **What to search for**:
  1. **Innovative patterns**: Specific to this domain, not obvious from steering
  2. **Critical edge cases**: Non-obvious failure modes, scalability bottlenecks, security issues
  3. **Breaking changes**: In related technologies mentioned in steering
- **What NOT to search**:
  - ❌ Generic "best practices" (assume they're already known)
  - ❌ Basic design patterns (CQRS, etc. are assumed knowledge)
  - ❌ Technology comparisons (unless steering is ambiguous)
  - ❌ Tutorial-level content
- **How to handle findings**:
  - Use findings to refine spec candidate proposals (naming, scope, breakdown)
  - Share ONLY critical insights with user in Phase 4 output
  - If no critical findings: Report "No critical findings that significantly impact spec breakdown"

**Individual Spec Research (Phase 5)**
- **When**: For each spec being initialized
- **Goal**: Find critical insights relevant to THIS spec
- **What to search for**:
  1. **Innovative patterns**: Specific to this component type, not obvious from general knowledge
  2. **Critical edge cases**: Non-obvious failure modes, concurrency issues, data corruption risks
  3. **Breaking changes**: In dependency specs or related modules
- **What NOT to search**:
  - ❌ Basic design patterns (assume they're known)
  - ❌ Generic API design (unless something unique to this component)
  - ❌ Technology comparisons (unless unclear from steering)
  - ❌ Tutorial-level content
- **How to handle findings**:
  - Use findings to enrich requirements.md with critical acceptance criteria
  - Record ONLY critical findings in spec's research.md:
    - Innovative patterns with implementation value
    - Critical edge cases to handle
    - Breaking changes affecting this spec
  - If no critical findings: Write "No critical findings beyond steering and standard practices" in research.md

**WebFetch Usage Pattern**:
1. Use WebSearch to find relevant sources (focus on engineering blogs, post-mortems, issue trackers)
2. Identify sources with critical insights (not generic tutorials)
3. **Use WebFetch to read FULL CONTENT** of 2-3 most relevant sources
4. Extract ONLY critical information (innovative patterns, edge cases, breaking changes)
5. Skip generic information that's assumed knowledge

### Dialogue
- **AskUserQuestion**: Use at each phase transition for confirmation
- Keep dialogue natural - present findings, ask for input, iterate

### Subagent Delegation

**Purpose**: Isolate high-token-consumption research tasks to prevent main conversation compaction.

**Benefits**:
- Each subagent has separate 200K token context
- WebFetch results stay isolated in subagent
- Only summaries/files return to main conversation
- Enables parallel execution for multiple specs

#### Phase 4 (Optional): Domain Research Subagent

**When to use**: Only when user explicitly requests domain research during Phase 2

**Subagent type**: `general-purpose`

**Input to subagent**:
```
Conduct targeted domain research for the following product:

**Domain**: [domain from product.md]
**Core Purpose**: [purpose]
**Technical Areas**: [areas]
**User Confirmation**: Product understanding was confirmed

**Research Goal**: Find ONLY critical insights that impact spec breakdown or requirements. Do NOT be exhaustive.

**What to search for** (use WebSearch + WebFetch to read FULL content):

1. **Innovative architectural patterns** specific to this domain:
   - Search: "[domain] architecture patterns papers"
   - Search: "[domain] unique design challenges"
   - WebFetch: Read FULL papers/blogs from domain experts
   - Extract ONLY: Novel or critical patterns not obvious from steering

2. **Critical edge cases or pitfalls**:
   - Search: "[domain] common mistakes" or "lessons learned"
   - Search: "[identified company/OSS] [domain] post-mortem"
   - WebFetch: Read FULL engineering blogs/case studies
   - Extract ONLY: Non-obvious failure modes, scalability bottlenecks, security issues

3. **Breaking changes or evolution** in related technologies:
   - IF steering mentions specific technologies, search: "[technology] breaking changes" or "migration guide"
   - WebFetch: Read FULL changelogs/migration guides
   - Extract ONLY: Breaking changes that affect architecture decisions

**CRITICAL - What NOT to search**:
- ❌ Generic "best practices" (assume they're already known)
- ❌ Basic design patterns (CQRS, etc. are assumed knowledge)
- ❌ Technology comparisons (unless steering is ambiguous)
- ❌ Tutorial-level content

**OUTPUT FORMAT** (return as structured text):

## Domain Research Summary

### Innovative Patterns
[ONLY if found non-obvious patterns]
- Pattern: [Name]
  - Why it matters: [Impact on spec breakdown]
  - Reference: [URL]

### Critical Edge Cases
[ONLY if found non-obvious pitfalls]
- Edge case: [Description]
  - Impact: [How it affects requirements]
  - Reference: [URL]

### Breaking Changes
[ONLY if related technologies have breaking changes]
- Technology: [Name]
  - Breaking change: [Description]
  - Impact: [How it affects architecture]
  - Reference: [URL]

### Implications for Spec Breakdown
[ONLY concrete changes to spec candidates]
- [Specific suggestion based on findings]

**If no critical findings**: Return "No critical findings that significantly impact spec breakdown beyond steering documents."
```

**Output from subagent**: Structured research summary (text) with URLs and key insights

**Main agent receives**: Text summary only (WebFetch results stay in subagent)

#### Phase 5: Individual Spec Research Subagents

**When to use**: For each new spec candidate

**Subagent type**: `general-purpose`

**Parallel execution**: Launch ALL spec subagents in a single message (multiple Task calls)

**Input to subagent** (per spec):
```
Generate research-driven requirements.md and research.md for the following spec:

**Spec Name**: [spec-name]
**Description**: [description from Phase 2]
**Wave**: [wave number]
**Dependencies**: [dependency specs]
**Domain Research Summary**:
[Phase 4のドメインリサーチ結果サマリーを渡す（利用可能な場合）、なければ "N/A"]

**Templates**:
- Requirements template: {{KIRO_DIR}}/settings/templates/specs/requirements.md
- Research template: {{KIRO_DIR}}/settings/templates/specs/research.md
- EARS format rules: {{KIRO_DIR}}/settings/rules/ears-format.md

TASKS:

1. **Conduct targeted individual spec research** (use WebSearch + WebFetch to read FULL content):

   **Research Goal**: Find ONLY critical insights relevant to THIS spec. Do NOT be exhaustive.

   **What to search for**:

   a. **Innovative patterns specific to this component**:
      - Search: "[spec component] innovative patterns" or "lessons learned"
      - WebFetch: Read FULL engineering blogs from component experts
      - Extract ONLY: Novel patterns not obvious from general knowledge

   b. **Critical edge cases for this component**:
      - Search: "[spec component] edge cases" or "gotchas"
      - Search: "[identified OSS] [component] issues" (check GitHub issues)
      - WebFetch: Read FULL issue discussions/post-mortems
      - Extract ONLY: Non-obvious failure modes, concurrency issues, data corruption risks

   c. **Breaking changes in related modules**:
      - IF this spec depends on other specs, search: "[dependency] breaking changes" or "migration"
      - WebFetch: Read FULL changelogs
      - Extract ONLY: Breaking changes that affect this spec's requirements

   **CRITICAL - What NOT to search**:
   - ❌ Basic design patterns (assume they're known)
   - ❌ Generic API design (unless something unique to this component)
   - ❌ Technology comparisons (unless unclear from steering)
   - ❌ Tutorial-level content

2. **Generate requirements.md**:
   - Follow template structure from {{KIRO_DIR}}/settings/templates/specs/requirements.md
   - Use EARS format for acceptance criteria (refer to {{KIRO_DIR}}/settings/rules/ears-format.md)
   - Include concrete requirement areas informed by targeted research findings
   - Write to: {{KIRO_DIR}}/specs/[spec-name]/requirements.md

3. **Generate research.md**:
   - Follow template structure from {{KIRO_DIR}}/settings/templates/specs/research.md
   - Record ONLY critical findings from:
     - Domain research (relevant parts from Phase 4 summary, if available)
     - Individual spec research (step 1 above)
   - Include ONLY:
     - Innovative patterns with implementation value
     - Critical edge cases to handle
     - Breaking changes affecting this spec
   - **If no critical findings**: Write "No critical findings beyond steering and standard practices."
   - Write to: {{KIRO_DIR}}/specs/[spec-name]/research.md

OUTPUT:
- Confirm files created: requirements.md, research.md
- Provide brief summary:
  - Critical findings count (0 if none)
  - Key patterns identified (if any)
  - Edge cases identified (if any)
```

**Output from subagent** (per spec):
- requirements.md file created
- research.md file created
- Brief summary of research quality

**Main agent receives**: File paths + brief summary (WebFetch results stay in subagent)

**Example parallel invocation**:
```
# In a single message, make multiple Task tool calls:
Task(spec-a, subagent_type="general-purpose", prompt="[Phase 5 prompt for spec-a]")
Task(spec-b, subagent_type="general-purpose", prompt="[Phase 5 prompt for spec-b]")
Task(spec-c, subagent_type="general-purpose", prompt="[Phase 5 prompt for spec-c]")
...
```

## Output Description

### Generated Files

For each NEW spec, create the following files in `{{KIRO_DIR}}/specs/[spec-name]/`:

1. **spec.json**: Metadata with roadmap information
   ```json
   {
     "feature_name": "spec-name",
     "created_at": "2024-01-01T00:00:00Z",
     "updated_at": "2024-01-01T00:00:00Z",
     "language": "en",
     "phase": "requirements-generated",
     "approvals": {
       "requirements": { "generated": true, "approved": false },
       "design": { "generated": false, "approved": false },
       "tasks": { "generated": false, "approved": false }
     },
     "ready_for_implementation": false,
     "roadmap": {
       "wave": 1,
       "dependencies": [],
       "parallel": false,
       "description": "Brief description"
     }
   }
   ```

2. **requirements.md**: Research-driven requirements document
   - Introduction with spec context and wave information
   - Concrete requirement areas informed by individual spec research
   - Detailed acceptance criteria in EARS format
   - Enriched by Phase 5 individual spec research (not just skeleton)

3. **research.md**: Comprehensive research findings
   - Phase 4 domain research (relevant parts for this spec, if available)
   - Phase 5 individual spec research (all details)
   - Implementation examples, API patterns, architectural guidance

### Console Output

Provide conversational summary with:
1. Context summary (what was loaded from steering)
2. **Product understanding confirmed with user** (domain, purpose, corrections if any)
3. **Phase 2: Spec candidates identified from steering**
4. **Phase 3: Wave organization**
5. **Phase 4 (if user requested): Domain research delegated to subagent**:
   - Subagent completed targeted research with WebFetch isolation
   - Critical findings: [innovative patterns / edge cases / breaking changes]
   - OR "No critical findings that significantly impact spec breakdown"
   - Spec candidates refined (if critical findings found)
6. **Phase 5: Individual spec research delegated to parallel subagents**:
   - N subagents launched in parallel
   - Each subagent conducted targeted research with WebFetch isolation
   - All requirements.md and research.md files created
7. **Created specs summary table**:
   | Spec Name | Wave | Dependencies | Critical Findings | Status |
   |-----------|------|--------------|-------------------|--------|
   | foundation | 1 | - | 0 critical findings | Created with requirements |
   | feature-a | 2 | foundation | 2 edge cases identified | Created with requirements |
8. **Token efficiency note**: "Targeted research (not exhaustive) was conducted in isolated subagent contexts to prevent main conversation compaction."
9. Next steps guidance: "Requirements are research-backed. Proceed to `/sdd-design [spec-name]`."

**Language**: Use the language the user writes in (auto-detect).

## Dialogue Points

**CRITICAL**: Always output full details as text BEFORE using AskUserQuestion. Users cannot make decisions from one-line summaries.

| Phase | Step 1: Output Details (text) | Step 2: Ask (AskUserQuestion) |
|-------|------------------------------|-------------------------------|
| **Phase 2 start** | Show: Product understanding (domain, purpose, users, tech areas, similar products) | **"Is this product understanding correct?"** |
| **Phase 2 candidates** | Show: full table with name, description, rationale, source for each spec + "Want domain research to validate/enrich?" | "Proceed with these specs" / "Conduct domain research first" / "Modify candidates" |
| **Phase 3** | Show: mermaid dependency graph, wave breakdown with parallel markers | "Proceed with this organization?" |
| **Phase 4 (if requested)** | Show: "Research delegated to subagent. Critical findings: [innovative patterns / edge cases / breaking changes]" (with full details from subagent, or "No critical findings") + refined spec candidates (if any changes) | "Proceed with refined specs?" (or "Proceed as-is" if no changes) |
| **Before Phase 5** | Show: summary table of specs to create | "Create these spec directories with individual research via parallel subagents?" |
| **During Phase 5** | Show: "Launching N parallel subagents for individual spec research..." (progress indicator) | (No confirmation - automated) |
| **After Phase 5** | Show: created specs table with research status and token efficiency note | "Specs initialized with research-driven requirements (via subagents). Proceed to `/sdd-design [spec-name]`" |

## Safety & Fallback

### Error Scenarios

- **No steering files**: Suggest running `/sdd-steering` first
- **Empty product.md**: Cannot determine domain - ask user to describe product
- **WebSearch fails**: Proceed with steering-only analysis, note limitation
- **Template missing**: Use inline fallback structure with warning

### Session Boundaries

- This command creates multiple spec directories with research-driven requirements
- **Phase 2**: Proposes spec candidates from steering documents
- **Phase 4 (optional)**: Domain research via subagent if user requests (WebFetch results isolated)
- **Phase 5 (always)**: Individual spec research via parallel subagents (WebFetch results isolated)
- Creates **research-driven** requirements.md files with concrete acceptance criteria
- Creates research.md files with comprehensive research findings
- **Token efficiency**: Research is conducted in isolated subagent contexts to prevent main conversation compaction
- **No steering updates** (use `/sdd-steering` for that)

### Integration with Other Skills

**Typical flow**:
```
/sdd-roadmap → Create multiple specs with research-driven requirements + research.md
    ↓
/sdd-design [spec-name] → Generate design from requirements and research
    ↓
/sdd-tasks [spec-name] → Generate implementation tasks
    ↓
/sdd-impl [spec-name] → Implement tasks
```

**Key difference from old workflow**:
- **OLD**: /sdd-roadmap → skeleton → /sdd-requirements → refine → design
- **NEW**: /sdd-roadmap (with individual research) → requirements ready → design directly

**After roadmap initialization**:
- Each spec has research-driven requirements.md (not skeleton)
- Each spec has research.md with comprehensive findings
- Requirements are informed by individual spec research
- **Skip** `/sdd-requirements` refinement step (already enriched)
- Proceed directly to `/sdd-design [spec-name]`
- Follow wave order for implementation priority

