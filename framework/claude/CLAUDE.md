# AI-DLC and Spec-Driven Development (v{{SDD_VERSION}})

Spec-Driven Development framework for AI-DLC (AI Development Life Cycle)

## Role Architecture

### 3-Tier Hierarchy

```
Tier 1: Command  ─── Lead ─────────────────────── (Conductor, Opus)
Tier 2: Brain    ─── Architect / Planner / Auditor ── (Teammate, Opus)
Tier 3: Execute  ─── Builder / Inspector ─── (Teammate ×N, Sonnet)
```

| Tier | Role | Responsibility |
|------|------|---------------|
| T1 | **Lead** | User interaction, phase gate checks, spawn planning, parallelism analysis, file ownership assignment, progress tracking, teammate lifecycle management, spec.json updates, Knowledge aggregation. |
| T2 | **Architect** | Design generation, research, discovery. Produces design.md + research.md. |
| T2 | **Planner** | Task decomposition. Generates tasks.md from design.md with parallelism analysis. |
| T2 | **Auditor** | Review synthesis. Merges Inspector findings into verdict (GO/CONDITIONAL/NO-GO/SPEC-UPDATE-NEEDED). Product Intent checks. |
| T3 | **Builder** | TDD implementation. RED→GREEN→REFACTOR cycle. Reports [PATTERN]/[INCIDENT] tags. |
| T3 | **Inspector** | Individual review perspectives. 5 inspectors spawned in parallel. Outputs CPF findings. |

### Chain of Command

Lead spawns T2/T3 teammates directly with context.
Teammates complete their work and output a structured completion report as their final text.
Lead reads completion output and determines next actions.

Exception: Inspector → Auditor communication uses SendMessage (peer communication within a review pipeline).

### State Management

**spec.json is owned by Lead.** T2/T3 teammates MUST NOT update spec.json directly.
- Teammates produce work artifacts (design.md, tasks.md, code) and output completion reports
- Lead validates results, computes metadata updates (phase, version_refs, changelog)
- Lead updates spec.json directly

```
User ──→ Lead ──→ T2/T3 Teammates
              ◄──
```

### Phase Gate

Before spawning any teammate, Lead MUST verify:
- `spec.json.phase` is appropriate for the requested operation
- `version_refs` consistency between design/tasks/implementation
- On failure: report error to user (do NOT spawn teammates unnecessarily)

### Teammate Lifecycle

Lead spawns teammates directly. Each teammate:
1. Receives context in spawn prompt (feature, paths, scope, instructions)
2. Executes its work autonomously
3. Outputs a structured completion report as final text
4. Terminates immediately after reporting

Lead reads the completion output and:
- Extracts results (artifacts created, test results, knowledge tags, blocker info)
- Updates spec.json metadata (phase, version_refs, changelog)
- Updates handover state
- Determines next action (spawn next teammate, escalate to user, etc.)
- Dismisses the teammate

For review pipelines: Lead spawns Inspectors + Auditor together. Inspectors SendMessage to Auditor (peer communication). Auditor outputs verdict as completion text to Lead.

## Project Context

### Paths
- **SDD Root**: `{{SDD_DIR}}` = `.claude/sdd`
- Steering: `{{SDD_DIR}}/project/steering/`
- Specs: `{{SDD_DIR}}/project/specs/`
- Knowledge: `{{SDD_DIR}}/project/knowledge/`
- Handover: `{{SDD_DIR}}/handover/`
- Rules: `{{SDD_DIR}}/settings/rules/`
- Templates: `{{SDD_DIR}}/settings/templates/`

### Artifacts

| Artifact | Scope | Purpose | Portable |
|----------|-------|---------|----------|
| **Steering** | Project-specific | Project-wide rules, context, decisions | No |
| **Specs** | Feature-specific | Design + architecture + tasks for a feature | No |
| **Knowledge** | Cross-project | Reusable insights, patterns, incidents | Yes |

- Project-specific decisions (tech stack, architecture) → Steering
- Feature implementation details → Specs
- Reusable patterns and lessons learned → Knowledge

### Active Specifications
- Check `{{SDD_DIR}}/project/specs/` for active specifications
- Use `/sdd-status [feature-name]` to check progress

## Workflow

### Commands (9)

| Command | Description |
|---------|-------------|
| `/sdd-steering` | Set up project context (create/update/delete/custom) |
| `/sdd-design` | Generate or edit a technical design |
| `/sdd-review` | Multi-agent review (design/impl/dead-code) |
| `/sdd-tasks` | Generate implementation tasks from design |
| `/sdd-impl` | TDD implementation of tasks |
| `/sdd-roadmap` | Multi-feature roadmap (create/run/update/delete) |
| `/sdd-status` | Check progress + impact analysis |
| `/sdd-handover` | Generate session handover document |
| `/sdd-knowledge` | Manage reusable knowledge entries |

### Stages
- Stage 0 (optional): `/sdd-steering`
- Stage 0.5 (optional): `/sdd-roadmap` — Multi-feature roadmap planning
- Stage 1 (Specification):
  - `/sdd-design "description"` (new) or `/sdd-design {feature}` (edit existing)
  - `/sdd-review design {feature}` (optional)
  - `/sdd-tasks {feature}`
- Stage 2 (Implementation):
  - `/sdd-impl {feature} [tasks]`
  - `/sdd-review impl {feature}` (optional)
- Progress check: `/sdd-status {feature}` (anytime)

### Phase-Driven Workflow
- Phases: `design-generated` → `tasks-generated` → `implementation-complete`
- Each phase gate is enforced by the next command
- Keep steering current and verify alignment with `/sdd-status`

### SPEC-Code Atomicity
- SPEC changes (design.md, tasks.md) and code changes belong in the same logical unit
- Editing specs triggers full cascade: design → tasks → implementation
- Version consistency enforced: `/sdd-impl` blocks on version_refs mismatch
- On SPEC-UPDATE-NEEDED verdict: fix the spec first, do not re-implement

### Auto-Fix Loop (Review)

When Auditor returns NO-GO or SPEC-UPDATE-NEEDED:
1. Extract fix instructions from Auditor's verdict
2. Dismiss review teammates
3. Track retry count (max 3)
4. Determine fix scope and spawn fix teammates:
   - **NO-GO (design review)** → spawn Architect with fix instructions
   - **NO-GO (impl review)** → spawn Builder(s) with fix instructions
   - **SPEC-UPDATE-NEEDED** → cascade: Architect → Planner → Builder
   - **Structural changes** → auto-fix in full-auto mode, escalate in `--gate` mode
   - **NO-GO (wave quality gate)** → map findings to file paths → identify responsible Builder(s) from file ownership records → spawn with fix instructions
5. After fix, dismiss fix teammates, then spawn review pipeline (Inspectors + Auditor) again
6. If 3 retries exhausted → escalate to user

### Wave Quality Gate (Roadmap)
- After all specs in a wave complete: Impl Cross-Check review (wave-scoped) → Dead Code review
- Issues found → re-spawn responsible Builder(s) from file ownership records → re-review
- Max 3 retries per gate → escalate to user

## Product Intent

Lead MUST update `steering/product.md` User Intent section whenever:
- User expresses requirements or vision → update Vision, Success Criteria, Anti-Goals
- Roadmap is created → update Spec Rationale
- Design is started → detail Success Criteria
- User makes a decision → append to Decision Log
- Direction changes → update Vision/Criteria
- Review-driven steering update → Auditor proposes `CODIFY` or `PROPOSE` via verdict (see Steering Feedback Loop)

Auditor references User Intent during every review for:
1. **Alignment check**: spec/impl matches Vision and Success Criteria
2. **Over-engineering check**: design/impl does not violate Anti-Goals
3. **Spec structure check**: Spec Rationale matches actual spec decomposition

### Steering Feedback Loop

Auditor verdicts may include a `STEERING:` section with two levels:

| Level | Meaning | Processing | Blocks pipeline |
|-------|---------|-----------|----------------|
| `CODIFY` | Document existing implicit pattern | Lead applies directly + appends to log.md | No |
| `PROPOSE` | New constraint affecting future work | Lead presents to user for approval | Yes |

When Auditor verdict contains a `STEERING:` section:
1. Parse `STEERING:` lines: `{CODIFY|PROPOSE}|{target file}|{decision text}`
2. Route by level:
   - **CODIFY** → Update `steering/{target file}` directly + append to `log.md`: `STEERING_UPDATE (CODIFY, source: {review type} {feature})`
   - **PROPOSE** → Present to user for approval
     - On approval → update `steering/{target file}` + log as `STEERING_UPDATE (PROPOSE, approved)`
     - On rejection → append to `log.md`: `USER_DECISION: Rejected steering proposal: "{decision text}"`
3. Process STEERING entries **after** handling the verdict (GO/NO-GO/etc.) but **before** advancing to the next phase

## Incremental Persistence (Handover)

State is persisted incrementally to `{{SDD_DIR}}/handover/` — NOT triggered by compact.

| Event | File | Content |
|-------|------|---------|
| Phase transition | conductor.md | Next Action, Active Goals, Pipeline State |
| User decision | conductor.md | Key Decisions |
| Decision/direction change | log.md | Timestamped event (append) |
| Steering update applied | log.md | Source and rationale (append) |
| Teammate completion | conductor.md | Pipeline State, Active Teammates |
| Teammate spawn | conductor.md | Active Teammates |
| Knowledge report | conductor.md | Knowledge Buffer |
| Wave completion | conductor.md | Pipeline State reset, Knowledge flush |

conductor.md is a **latest snapshot** (overwrite). log.md is **append-only** (never overwrite).

### conductor.md Format

```markdown
# Lead Handover
**Updated**: {timestamp}

## Direction
- Next Action: {command form}
- Active Goals: {current objectives}
- Key Decisions: {decisions made this session}

## Pipeline State
| Spec | Phase | Last Action | Next Action | Blocked By |
|------|-------|-------------|-------------|------------|

## Active Teammates
{list of currently spawned teammates and their tasks}

## Knowledge Buffer
{[PATTERN]/[INCIDENT]/[REFERENCE] reports not yet written to knowledge/}
```

### Decision Log (`log.md`)

Append-only record of decisions, direction changes, and steering updates. Provides traceability that snapshots cannot.

Format:
```
[{ISO-8601}] {EVENT_TYPE}: {description}
```

Event types:
- `USER_DECISION` — User made a choice (e.g., skip spec, change approach)
- `STEERING_UPDATE` — Steering file modified (source: which review, CODIFY or PROPOSE)
- `DIRECTION_CHANGE` — Spec split, wave restructure, scope change
- `ESCALATION_RESOLVED` — Outcome of an escalation to user

### Session Resume
On session start (new or post-compact):
1. If `{{SDD_DIR}}/handover/conductor.md` exists → read it
2. Restore pipeline state from the handover snapshot
3. Determine next actions from Pipeline State and pending work
4. Spawn necessary teammates directly and continue orchestration

## Knowledge Auto-Accumulation

- Builder/Inspector report learnings with tags: `[PATTERN]`, `[INCIDENT]`, `[REFERENCE]`
- Lead collects tagged reports from teammate completion outputs
- On wave completion: Lead aggregates, deduplicates, and writes to `{{SDD_DIR}}/project/knowledge/`
- Skill emergence: when 2+ specs share the same pattern, Lead proposes Skill candidates to user for approval

## Pipeline Stop Protocol

When user requests stop during pipeline execution:
1. Lead dismisses all active T2/T3 teammates
2. Lead saves current pipeline state to `{{SDD_DIR}}/handover/conductor.md`
3. Report to user: what was completed, what was in progress, how to resume

Resume: `/sdd-roadmap run` reads handover state and resumes from interruption point.

## Behavioral Rules
- After a compact operation, ALWAYS wait for the user's next instruction. NEVER start any action autonomously after compact.
- Do not continue or resume previously in-progress tasks after compact unless the user explicitly instructs you to do so.
- Follow the user's instructions precisely, and within that scope act autonomously: gather the necessary context and complete the requested work end-to-end, asking questions only when essential information is missing or critically ambiguous.

## Git Workflow

Trunk-based development. main is always HEAD.

### Branch Strategy
- All work happens on main by default
- Feature/topic branches are optional; always merge back to main and delete the branch
- main MUST remain the latest state at all times
- Never leave stale branches; merged branches are deleted immediately

### Commit Timing
- **Wave completion**: After Wave Quality Gate passes, Lead commits directly
- **Standalone command completion**: After `/sdd-impl` or `/sdd-review` completes outside roadmap, Lead commits
- Commit scope: all spec artifacts + implementation changes from the completed work
- Commit message format: `Wave {N}: {summary}` (roadmap) or `{feature}: {summary}` (standalone)

### Release Flow
After a logical milestone (roadmap completion, significant feature set):
1. Create release branch from main (e.g., `release/v{version}`)
2. Update version (hatch-vcs for Python projects, or project-appropriate method)
3. Tag the release
4. Push release branch
5. main continues to advance; release branch is a snapshot, not merged back

## Compact Pipe-Delimited Format (CPF)

Token-efficient structured text format used for inter-agent communication.

### Notation Rules

| Element | Format | Example |
|---------|--------|---------|
| Metadata | `KEY:VALUE` (no space) | `VERDICT:CONDITIONAL` |
| Structured row | `field1\|field2\|field3` | `H\|ambiguity\|Spec 1\|not quantified` |
| Freeform text | Plain lines (no decoration) | `Domain research suggests...` |
| List identifiers | `+` separated | `rulebase+consistency` |
| Empty sections | Omit header entirely | _(do not output)_ |
| Severity codes | C/H/M/L | C=Critical, H=High, M=Medium, L=Low |

### Writing CPF

- Section headers (`ISSUES:`, `NOTES:`, etc.) followed by one record per line
- No decoration characters (`- [`, `] `, `: `, ` - `)
- Omit empty sections (do not output the header)
- No spaces in metadata lines (`KEY:VALUE`)

### Parsing CPF

```
1. Line starts with known keyword + `:` → metadata or section start
2. Lines under a section → split by `|` to extract fields
3. Field containing `+` → split as identifier list
4. Section not present → no data of that type (not an error)
```

### Minimal Example

```
VERDICT:GO
SCOPE:my-feature
ISSUES:
M|ambiguity|Spec 1.AC1|"quickly" not quantified
NOTES:
No critical issues found
```

## Steering Configuration
- Load entire `{{SDD_DIR}}/project/steering/` as project memory
- Default files: `product.md`, `tech.md`, `structure.md`
- Custom files are supported (managed via `/sdd-steering`)
