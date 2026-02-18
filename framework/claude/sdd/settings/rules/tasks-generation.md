# Task Generation Rules

## Core Principles

### 1. Natural Language Descriptions
Focus on capabilities and outcomes, not code structure.

**Describe**:
- What functionality to achieve
- Business logic and behavior
- Features and capabilities
- Domain language and concepts
- Data relationships and workflows

**Avoid**:
- File paths and directory structure
- Function/method names and signatures
- Type definitions and interfaces
- Class names and API contracts
- Specific data structures

**Rationale**: Implementation details (files, methods, types) are defined in design.md. Tasks describe the functional work to be done.

### 2. Task Integration & Progression

**Every task must**:
- Build on previous outputs (no orphaned code)
- Connect to the overall system (no hanging features)
- Progress incrementally (no big jumps in complexity)
- Validate core functionality early in sequence
- Respect architecture boundaries defined in design.md (Architecture Pattern & Boundary Map)
- Honor interface contracts documented in design.md
- Use major task summaries sparingly—omit detail bullets if the work is fully captured by child tasks.

**End with integration tasks** to wire everything together.

### 3. Flexible Task Sizing

**Guidelines**:
- **Major tasks**: As many sub-tasks as logically needed (group by cohesion)
- **Sub-tasks**: 1-3 hours each, 3-10 details per sub-task
- Balance between too granular and too broad

**Don't force arbitrary numbers** - let logical grouping determine structure.

### 4. Specifications Mapping

**Each sub-task must include**:
- `specs:` field listing **only numeric spec IDs** as a YAML list. Never append descriptive text, parentheses, translations, or free-form labels.
- For cross-cutting specs, list every relevant spec ID. All specs MUST have numeric IDs in design.md's Specifications section. If an ID is missing, stop and correct the Specifications section before generating tasks.
- When task references specific acceptance criteria, optionally add `acs:` field (e.g., `[S1.AC1, S1.AC2]`) to enable direct traceability from task → AC → test via the `AC: {feature}.S{N}.AC{M}` test marker convention.

### 5. Code-Only Focus

**Include ONLY**:
- Coding tasks (implementation)
- Testing tasks (unit, integration, E2E)
- Technical setup tasks (infrastructure, configuration)

**Exclude**:
- Deployment tasks
- Documentation tasks
- User testing
- Marketing/business activities

### Optional Test Coverage Tasks

- When the design already guarantees functional coverage and rapid MVP delivery is prioritized, mark purely test-oriented follow-up work (e.g., baseline rendering/unit tests) as **optional** using `optional: true`.
- Only apply the optional marker when the sub-task directly references acceptance criteria from design.md's Specifications section in its detail bullets.
- Never mark implementation work or integration-critical verification as optional—reserve `optional: true` for auxiliary/deferrable test coverage that can be revisited post-MVP.

## Task Hierarchy Rules

### Maximum 2 Levels
- **Level 1**: Major tasks (id: "1", "2", "3"...)
- **Level 2**: Sub-tasks (id: "1.1", "1.2", "2.1", "2.2"...)
- **No deeper nesting** (no "1.1.1")
- If a major task would contain only a single actionable item, collapse the structure and promote the sub-task to the major level (e.g., replace "1.1" with "1").
- When a major task exists purely as a container, keep the summary concise and avoid duplicating detailed bullets—reserve specifics for its sub-tasks.

### Sequential Numbering
- Major tasks MUST increment: 1, 2, 3, 4, 5...
- Sub-tasks reset per major task: 1.1, 1.2, then 2.1, 2.2...
- Never repeat major task numbers

### Parallel Analysis (default)
- Assume parallel analysis is enabled unless explicitly disabled (e.g. `--sequential` flag).
- Mark a task as parallel-capable only when **all** conditions hold:
  1. No data dependency on other pending tasks
  2. No shared file or resource contention
  3. No prerequisite review/approval from another task
  4. Environment/setup work needed by this task is already satisfied or covered within the task itself
- Validate that identified parallel tasks operate within separate boundaries defined in the Architecture Pattern & Boundary Map.
- Confirm API/event contracts from design.md do not overlap in ways that cause conflicts.
- Set `p: true` on each parallel-capable task:
  - Apply to both major tasks and sub-tasks when appropriate.
  - Skip marking container-only major tasks (those without their own actionable detail bullets) — evaluate at sub-task level instead.
- If sequential mode is requested, omit `p: true` entirely.
- Group parallel tasks logically (same parent when possible) and highlight any ordering caveats in detail bullets.
- Explicitly call out dependencies that prevent parallel execution even when tasks look similar.
- **Quality check** before marking `p: true`: verify no merge/deployment conflicts, capture shared state expectations in detail bullets, confirm task can be tested independently. If any check fails, do not mark `p: true`.

### YAML Output Format

Output tasks.yaml with this structure:

```yaml
tasks:
  - id: "1"
    summary: Major task description
    status: pending       # pending | done
    subtasks:
      - id: "1.1"
        p: true           # parallel capable
        summary: Sub-task description
        details:
          - Detail item 1
          - Detail item 2
        specs: [1.1, 1.2]
        acs: [S1.AC1, S1.AC2]   # optional, for test traceability
        status: pending
        depends: []
      - id: "1.2"
        summary: Another sub-task
        details:
          - Detail item
        specs: [1.3]
        status: pending
        depends: ["1.1"]

execution:
  - wave: 1
    groups:
      - id: A
        tasks: ["1.1", "1.2"]
        files: [src/auth/handler.py, src/auth/models.py]
      - id: B
        tasks: ["2.1"]
        files: [src/api/routes.py]
  - wave: 2
    groups:
      - id: C
        tasks: ["3.1"]
        files: [src/core/middleware.py]
        depends: [A]
```

Field reference:
- `status`: `pending` (not started) or `done` (completed)
- `p`: `true` if task can execute in parallel (omit or `false` if sequential)
- `specs`: list of numeric spec IDs from design.md (mandatory)
- `acs`: list of acceptance criteria IDs (optional, for test traceability)
- `depends`: list of task IDs this task depends on
- `optional`: `true` for deferrable test coverage tasks (omit otherwise)

### Execution Plan Generation

The `execution` section maps tasks to Builder work packages:

- **File ownership**: Read design.md Components section to determine which files each task touches
- **Group formation**: Group parallel tasks into Builder work packages with **no file overlap** between groups
- **Wave structure**: Organize groups into execution waves based on dependency chains
- **Group dependencies**: Use `depends` at group level to express cross-group ordering

## Specifications Coverage

**Mandatory Check**:
- ALL specs from design.md's Specifications section MUST be covered
- Cross-reference every spec ID with task mappings
- If gaps found: Return to design phase
- No spec should be left without corresponding tasks

Use `N.M`-style numeric spec IDs where `N` is the top-level Spec number from design.md's Specifications section (for example, Spec 1 → 1.1, 1.2; Spec 2 → 2.1, 2.2), and `M` is a local index within that spec group.

Document any intentionally deferred specs with rationale.
