---
description: Generate product-wide specification roadmap and initialize multiple specs with skeleton design documents
allowed-tools: Glob, Grep, Read, Write, Edit, AskUserQuestion, Task
argument-hint: [-y]
---

# Create Specification Roadmap

<background_information>
- **Mission**: Generate a product-wide specification roadmap and initialize multiple specs with skeleton design documents
- **Success Criteria**:
  - **Product understanding verified with user** (prevent domain misunderstanding)
  - Spec candidates proposed from steering documents
  - **Wave organization refined through dialogue** (Phase 4):
    - User feedback incorporated into wave structure
    - Research conducted only when needed to answer specific questions
  - Comprehensive spec inventory with dependencies mapped
  - Clear implementation waves with parallel execution opportunities
  - **Multiple spec directories created with skeleton design.md files**
  - Ready for design refinement via `/sdd-design`
</background_information>

<instructions>

## Core Philosophy

This is an **exploratory, collaborative task**. Build the roadmap through dialogue with the user:
- **Phase 2**: Propose spec candidates from steering documents
- **Phase 3**: Propose initial wave organization
- **Phase 4**: Refine wave organization through dialogue (research as needed, not by default)
- **Phase 5**: Create spec directories with skeleton design documents
- Focus on "discovering together" rather than "outputting answers"

**CRITICAL - Details Before Confirmation**:
- NEVER ask for YES/NO confirmation with only a one-line summary
- ALWAYS output full details as text FIRST, THEN ask for confirmation
- Users need complete information to make informed decisions
- Pattern: [Show detailed findings/proposals] → [AskUserQuestion for approval]

## Auto-Approve Mode

**If `-y` flag is provided**:
- Skip Phase 4 dialogue (use initial wave organization as-is)
- Auto-approve spec candidates and wave organization
- Create spec directories and skeleton design documents without confirmation prompts
- Still provide summary of what was done

## Execution Steps

### Phase 1: Context Load

1. **Read rules and templates**:

   **Rules**:
   - Read `{{SDD_DIR}}/settings/rules/steering-principles.md` (for understanding steering update criteria)

   **Steering Templates** (understand what each file should contain):
   - Read `{{SDD_DIR}}/settings/templates/steering/product.md`
   - Read `{{SDD_DIR}}/settings/templates/steering/tech.md`
   - Read `{{SDD_DIR}}/settings/templates/steering/structure.md`

   **Custom Steering Templates** (understand more detailed patterns allowed):
   - Read `{{SDD_DIR}}/settings/templates/steering-custom/database.md`
   - Read `{{SDD_DIR}}/settings/templates/steering-custom/api-standards.md`
   - Read `{{SDD_DIR}}/settings/templates/steering-custom/testing.md`
   - Read `{{SDD_DIR}}/settings/templates/steering-custom/security.md`
   - (and others if relevant to the domain)

   **Spec Templates** (for skeleton generation in Phase 5):
   - Read `{{SDD_DIR}}/settings/templates/specs/design.md`
   - Read `{{SDD_DIR}}/settings/templates/specs/research.md`
   - Read `{{SDD_DIR}}/settings/templates/specs/init.json`

   **Purpose**:
   - Understand what content is appropriate for each steering file
   - Understand how to generate proper skeleton design.md and research.md

2. **Read ALL steering documents**:
   - Read entire `{{SDD_DIR}}/project/steering/` directory:
     - `product.md` - Product vision, goals, user personas
     - `tech.md` - Technical constraints, standards, patterns
     - `structure.md` - Project structure, conventions
     - All custom steering files

3. **Scan existing specs**:
   - Glob `{{SDD_DIR}}/project/specs/*/spec.json` to understand existing features
   - Read each spec's `design.md` (if exists) to understand scope
   - Build inventory of existing specs with their phases

### Phase 2: Product Understanding and Spec Candidate Inference

**Purpose**: Verify product understanding and propose spec candidates from steering documents.

**CRITICAL**: Prevent domain misunderstanding. Domain research is optional and user-directed.

1. **Report product understanding**:

   **Output as text and ASK FOR CONFIRMATION**:
   ```
   ## Product Understanding

   Based on steering documents, I understand this product as:

   **Domain**: [specific domain]
   **Core Purpose**: [core purpose of the product]
   **Target Users**: [target users]
   **Key Technical Areas**: [key technical areas]
   **Similar Products**: [similar products]

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
   - Compare against `{{SDD_DIR}}/project/specs/*/` inventory
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

### Phase 4: Wave Refinement (Dialogue-Based)

**Purpose**: Refine wave organization through dialogue with user. Collect context as needed to make informed adjustments.

**This phase is a conversation**, not an automated research step:

1. **Present initial wave organization** (from Phase 3) and invite feedback:
   - "Does this wave organization make sense?"
   - "Are there any specs that should be in a different wave?"
   - "Are there missing specs or unnecessary ones?"

2. **Respond to user questions and concerns**:
   - If user asks about technical feasibility → explain reasoning
   - If user questions dependencies → clarify or adjust
   - If user wants to know about a specific technology → **optionally conduct targeted research**

3. **Conduct research only when needed** (as part of dialogue):

   **When to research**:
   - User asks: "What about X?" and you need external info to answer
   - User is uncertain about a technology choice
   - Dependency or compatibility questions arise

   **How to research**:
   - Use Task tool with `subagent_type="general-purpose"`
   - Focus on the specific question raised
   - Share findings with user and discuss implications

4. **Iteratively adjust wave organization**:
   - Move specs between waves based on discussion
   - Split or merge specs if user identifies issues
   - Update dependencies as understanding improves

5. **Confirm final wave organization**:
   - Show updated dependency graph and wave breakdown
   - Ask: "Ready to proceed with this organization?"

**Key principle**: This phase is about **understanding user intent** and **building shared context**, not automated research. Research is a tool within the dialogue, not the goal.

### Phase 5: Spec Initialization

**Purpose**: Create spec directories with skeleton design documents for all planned specs.

1. **Prepare spec list**:
   - Combine existing specs (from Phase 1) with new spec candidates (from Phase 3)
   - For existing specs: Skip directory creation, optionally update metadata
   - For new specs: Create directories

2. **For each NEW spec candidate, create directory and spec.json**:
   - Create `{{SDD_DIR}}/project/specs/[spec-name]/`
   - Generate spec.json with roadmap metadata
   - Set `phase: "initialized"`

3. **Generate skeleton design.md for each spec** (new specs only):
   - Read template: design.md
   - **Overwrite guard**: If `design.md` already exists AND spec phase is NOT `initialized`, SKIP skeleton generation for that spec (preserve existing refined design)
   - If `design.md` exists AND spec phase IS `initialized`: overwrite with new skeleton (previous skeleton was never refined)
   - If `design.md` does not exist: generate skeleton
   - Generate design.md skeleton with Specifications section based on steering documents
   - Include spec description, wave info, and dependencies
   - **Design will be refined via `/sdd-design` command**

4. **Present creation summary** (unless `-y`):
   - Show table of created specs with skeleton design documents
   - Ask: "Proceed with spec initialization?"

8. **Generate roadmap.md** (project-wide roadmap file):
   - Write to `{{SDD_DIR}}/project/specs/roadmap.md`
   - **NOT in steering** (to avoid context pollution for individual spec implementers)
   - **Plan only, no progress tracking** (progress is dynamically calculated by `/sdd-status`)
   - **Format Contract**: The following sections are **required** and parsed by `/sdd-roadmap-run` and `/sdd-status`:
     - `## Wave Overview` table: columns must include Wave number, Name, Specs list
     - `## Implementation Order` with `### Wave N (Name)` subsections: each must contain a table with Spec, Dependencies columns
     - Each spec's `spec.json` must have `roadmap.wave` and `roadmap.dependencies` fields set
     - Other sections (Dependency Graph, Wave Execution Flow, Quick Reference) are informational and not parsed
   - Content structure:
     ```markdown
     # Specification Roadmap

     Generated: {{TIMESTAMP}}

     ## Overview

     [Product description and roadmap summary - language follows user settings]

     ## Wave Overview

     | Wave | Name | Specs | Description |
     |------|------|-------|-------------|
     | 1 | Foundation | schemas-core, core-utilities | [description] |
     | 2 | Core | feature-a, feature-b | [description] |

     ## Dependency Graph

     ```mermaid
     graph TD
       schemas-core --> feature-a
       ...
     ```

     ## Implementation Order

     ### Wave 1 (Foundation)

     | Spec | Description | Parallel | Dependencies |
     |------|-------------|----------|--------------|
     | schemas-core | ... | Yes | - |

     **Key Research Findings**:
     - [Critical findings from research]

     ---

     ### Wave 2 (Core) - depends on Wave 1
     ...

     ---

     ## Parallel Execution Opportunities

     - **Wave N**: [specs that can be developed in parallel]

     ---

     ## Wave Execution Flow

     Each Wave follows these 7 steps.

     ```
     ┌─────────────────────────────────────────────────────────────────┐
     │                    Wave N Development Flow                       │
     ├─────────────────────────────────────────────────────────────────┤
     │                                                                 │
     │  1. Identify specs in Wave                                      │
     │     └─→ Check spec.json roadmap.wave                            │
     │                                                                 │
     │  2. Design existence check                                      │
     │     ├─→ Not exists: Run /sdd-design {spec}                     │
     │     └─→ Exists: Continue                                        │
     │                                                                 │
     │  3. Design Review (subagent parallel)                           │
     │     ├─→ 3.1 Individual: /sdd-review-design {spec}              │
     │     │       ├─→ GO: Continue                                    │
     │     │       ├─→ CONDITIONAL (minor): Auto-fix and continue     │
     │     │       └─→ NO-GO / Decision needed: Report to user        │
     │     └─→ 3.2 Cross-check: Wave alignment & interface consistency│
     │                                                                 │
     │  4. User Confirmation [REQUIRED]                                │
     │     └─→ Present spec positioning & responsibility to user      │
     │                                                                 │
     │  5. Task Generation                                             │
     │     └─→ Run /sdd-tasks {spec} -y for each spec in Wave         │
     │                                                                 │
     │  6. Implementation (subagent parallel)                          │
     │     └─→ Run /sdd-impl {spec} considering parallelism           │
     │                                                                 │
     │  7. Implementation Review & Completion Report                   │
     │     ├─→ 7.1 Individual: /sdd-review-impl {spec}                │
     │     ├─→ 7.2 Cross-check                                         │
     │     └─→ Wave N Complete → Wave N+1                              │
     │                                                                 │
     └─────────────────────────────────────────────────────────────────┘
     ```

     ### Step 1: Identify specs in Wave
     1. Read `{{SDD_DIR}}/project/specs/*/spec.json`
     2. List specs where `roadmap.wave == N`
     3. Build dependency graph from `roadmap.dependencies`

     ### Step 2: Design existence check
     - Not exists: Generate with `/sdd-design {spec}` (referencing roadmap info)
     - Exists: Skip (already generated by sdd-roadmap)

     ### Step 3: Design Review (subagent parallel)
     **Individual Review**: GO / CONDITIONAL / NO-GO
     **Cross-check**: Wave alignment, interface consistency, dependency validity

     ### Step 4: User Confirmation [REQUIRED]
     After completing design review for all specs in Wave, present:
     - Positioning in overall architecture (dependent Waves, downstream Waves)
     - Responsibility allocation for each spec (primary responsibility, inputs, outputs)
     - Cross-check results

     ### Step 5: Task Generation
     Run `/sdd-tasks {spec} -y` for each spec in Wave

     ### Step 6: Implementation (subagent parallel)
     Group specs for parallel execution based on dependencies

     ### Step 7: Implementation Review & Completion Report
     **Individual Review + Cross-check** → Wave completion report

     ---

     ## Quick Reference Commands

     ### Wave 1: [Wave Name]
     ```bash
     # Step 2: Design (if not exists)
     /sdd-design [spec-name]

     # Step 3: Design Review (subagent)
     # → Task tool: /sdd-review-design [spec-name]

     # Step 4: User Confirmation
     # → Present responsibility allocation & positioning to user

     # Step 5: Tasks
     /sdd-tasks [spec-name] -y

     # Step 6: Implementation (subagent)
     # → Task tool: /sdd-impl [spec-name]

     # Step 7: Implementation Review (subagent)
     # → Task tool: /sdd-review-impl [spec-name]
     ```

     ### Wave 2: [Wave Name] (parallel execution possible)
     [Same pattern with multiple specs, explicitly showing parallel execution]

     ---

     ## Error Handling

     ### Design Review NO-GO
     1. Present review results to user
     2. Request user decision on fix approach
     3. After fix, re-run /sdd-review-design

     ### Implementation Errors
     1. Log error details
     2. Continue other parallel tasks
     3. After all tasks complete, report error summary to user

     ### Implementation Review Issues
     | Severity | Action |
     |----------|--------|
     | Critical | Must fix, report to user |
     | Warning | Auto-fix if possible, otherwise report |
     | Info | Log and proceed to next Wave |

     ---

     ## Notes

     - **Context Management**: Each subagent runs in isolated context
     - **Parallel Execution Limit**: Adjust based on system resources (recommended: 2-3 parallel)
     - **Checkpoints**: Recommend git commit after each Step completion
     - **Rollback**: Use git revert if issues occur
     ```
   - This file is read by `/sdd-status` for Wave structure (progress is calculated from spec.json files)
   - **Quick Reference Commands section is dynamically generated with actual spec names for each Wave**
   - **Section headers (Wave Execution Flow, Quick Reference Commands, Error Handling, Notes) remain in English regardless of output language**

</instructions>

## Tool Guidance

### File Operations
- **Read**: Load all steering, existing specs, and templates before analysis
- **Glob**: Find existing spec directories and config files
- **Write**: Create spec.json, design.md (skeleton), and roadmap.md for each spec

### Dialogue
- **AskUserQuestion**: Use at each phase transition for confirmation
- Keep dialogue natural - present findings, ask for input, iterate
- **Phase 4 is primarily dialogue**, not automated research

### Research Delegation (Phase 4 only, as needed)

**Research is a tool within Phase 4 dialogue**, not the primary activity.

**When to delegate research**:
- User asks a question you cannot answer from steering documents
- User is uncertain about a technology choice and needs external info
- Dependency or compatibility questions arise during wave refinement

**How to delegate**:
- Use Task tool with `subagent_type="general-purpose"`
- Focus prompt on the **specific question** raised by user
- Results return in CPF format (FINDINGS/SOURCES/CAVEATS sections)
- Share findings with user and discuss implications together

**Research philosophy**:
- Answer the user's specific question, not general domain exploration
- Keep research focused and minimal
- Share findings transparently and let user decide implications

**Example research prompt** (when needed):
```
Research: [specific question from user]

Context:
- Product domain: [domain]
- User's question: [exact question]
- Why we need this: [what decision depends on this info]

Focus on answering the specific question above.
Depth: low
Language: [ja|en based on conversation context]
```

**After receiving report**:
1. Share relevant findings with user
2. Discuss implications together
3. Adjust wave organization based on shared understanding

## Output Description

### Generated Files

For each NEW spec, create the following files in `{{SDD_DIR}}/project/specs/[spec-name]/`:

1. **spec.json**: Metadata with roadmap information
   ```json
   {
     "feature_name": "spec-name",
     "created_at": "2024-01-01T00:00:00Z",
     "updated_at": "2024-01-01T00:00:00Z",
     "language": "en",
     "version": "1.0.0",
     "changelog": [],
     "version_refs": {
       "design": null,
       "tasks": null
     },
     "phase": "initialized",
     "implementation": {
       "files_created": []
     },
     "roadmap": {
       "wave": 1,
       "dependencies": [],
       "parallel": false,
       "description": "Brief description"
     }
   }
   ```

2. **design.md**: Skeleton design document
   - Introduction with spec context and wave information
   - Placeholder Specifications section based on steering documents
   - **To be refined via `/sdd-design` command**

### Console Output

Provide conversational summary with:
1. Context summary (what was loaded from steering)
2. **Product understanding confirmed with user** (domain, purpose, corrections if any)
3. **Phase 2: Spec candidates identified from steering**
4. **Phase 3: Wave organization**
5. **Phase 4 (if user requested): Domain research delegated to general-purpose subagent**:
   - Critical findings: [innovative patterns / edge cases / breaking changes]
   - OR "No critical findings that significantly impact spec breakdown"
   - Spec candidates refined based on findings (if any)
6. **Phase 5: Spec initialization**:
   - Created spec directories with skeleton design documents
7. **Created specs summary table**:
   | Spec Name | Wave | Dependencies | Status |
   |-----------|------|--------------|--------|
   | foundation | 1 | - | Skeleton created |
   | feature-a | 2 | foundation | Skeleton created |
8. Next steps guidance: "Skeleton design documents created. Run `/sdd-design [spec-name]` to refine each spec, then `/sdd-tasks [spec-name]` to generate tasks."

**Language**: Use the language the user writes in (auto-detect).

## Dialogue Points

**CRITICAL**: Always output full details as text BEFORE using AskUserQuestion. Users cannot make decisions from one-line summaries.

| Phase | Step 1: Output Details (text) | Step 2: Ask (AskUserQuestion) |
|-------|------------------------------|-------------------------------|
| **Phase 2 start** | Show: Product understanding (domain, purpose, users, tech areas, similar products) | **"Is this product understanding correct?"** |
| **Phase 2 candidates** | Show: full table with name, description, rationale, source for each spec | "Proceed with these specs?" / "Modify candidates" |
| **Phase 3** | Show: mermaid dependency graph, wave breakdown with parallel markers | "Does this wave organization make sense? Any adjustments needed?" |
| **Phase 4** | Dialogue: respond to user feedback, adjust waves, research if needed | (Iterative dialogue until user confirms) |
| **Before Phase 5** | Show: final wave organization and summary table of specs to create | "Create these spec directories with skeleton design documents?" |
| **After Phase 5** | Show: created specs table | "Specs initialized. Run `/sdd-design [spec-name]` to refine each spec." |

## Safety & Fallback

### Error Scenarios

- **No steering files**: Suggest running `/sdd-steering` first
- **Empty product.md**: Cannot determine domain - ask user to describe product
- **WebSearch fails**: Proceed with dialogue, note limitation
- **Template missing**: Use inline fallback structure with warning

### Session Boundaries

- This command creates multiple spec directories with skeleton design documents
- **Phase 2**: Proposes spec candidates from steering documents
- **Phase 3**: Proposes initial wave organization
- **Phase 4**: Refines wave organization through dialogue (research only when needed)
- **Phase 5**: Creates spec directories with skeleton design documents
- Creates **skeleton** design.md files to be refined via `/sdd-design`
- **No steering updates** (use `/sdd-steering` for that)

### Integration with Other Skills

**Typical flow**:
```
/sdd-roadmap → Create multiple specs with skeleton design documents
    ↓
/sdd-design [spec-name] → Refine design (optional)
    ↓
/sdd-tasks [spec-name] → Generate implementation tasks
    ↓
/sdd-impl [spec-name] → Implement tasks
```

**After roadmap initialization**:
- Each spec has skeleton design.md
- Use `/sdd-design [spec-name]` to refine design if needed
- Proceed to `/sdd-tasks [spec-name]` when design is ready
- Follow wave order for implementation priority

