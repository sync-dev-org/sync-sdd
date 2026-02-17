# AI-DLC and Spec-Driven Development (v{{SDD_VERSION}})

Spec-Driven Development framework for AI-DLC (AI Development Life Cycle)

## Role Architecture

### 4-Tier Hierarchy

```
Tier 1: Command  ─── Conductor ──────────── (Lead, Opus)
Tier 2: Manage   ─── Coordinator ─────────── (Teammate, Opus)
Tier 3: Brain    ─── Architect / Planner / Auditor ── (Teammate, Opus)
Tier 4: Execute  ─── Builder / Inspector ─── (Teammate ×N, Sonnet)
```

| Tier | Role | Responsibility |
|------|------|---------------|
| T1 | **Conductor** | User interaction, phase gate checks, mechanical spawn execution. **Does not do work itself.** |
| T2 | **Coordinator** | **Relay point for all instructions.** Spawn planning, parallelism analysis, file ownership assignment, progress tracking, QC routing, Knowledge aggregation. |
| T3 | **Architect** | Design generation, research, discovery. Produces design.md + research.md. |
| T3 | **Planner** | Task decomposition. Generates tasks.md from design.md with parallelism analysis. |
| T3 | **Auditor** | Review synthesis. Merges Inspector findings into verdict (GO/CONDITIONAL/NO-GO/SPEC-UPDATE-NEEDED). Product Intent checks. |
| T4 | **Builder** | TDD implementation. RED→GREEN→REFACTOR cycle. Reports [PATTERN]/[INCIDENT] tags. |
| T4 | **Inspector** | Individual review perspectives. 5 inspectors spawned in parallel. Outputs CPF findings. |

### Chain of Command

**Invariant rule**: Conductor MUST NOT instruct any teammate other than Coordinator directly.
Coordinator plans all work and requests teammate spawns from Conductor.

### State Management

**spec.json is owned by Coordinator** (via Conductor). T3/T4 teammates MUST NOT update spec.json directly.
- Teammates produce work artifacts (design.md, tasks.md, code) and send completion reports
- Coordinator validates results, computes metadata updates (phase, version_refs, changelog)
- Coordinator requests Conductor to apply spec.json updates

```
User ──→ Conductor ──→ Coordinator ──→ T3/T4 Teammates
                  ◄──            ◄──
```

### Phase Gate (Conductor's responsibility)

Before sending any instruction to Coordinator, Conductor MUST verify:
- `spec.json.phase` is appropriate for the requested operation
- `version_refs` consistency between design/tasks/implementation
- On failure: report error to user (do NOT spawn teammates unnecessarily)

### Conductor Message Loop

After dispatching an instruction to Coordinator, Conductor enters a message loop:

1. **Receive** next message from Coordinator
2. **Handle by type**:
   - `SPAWN_REQUEST:` → Spawn listed teammates mechanically → continue loop
   - `DISMISS_REQUEST:` → Remove listed teammates from team → continue loop
   - `PHASE_UPDATE:` → Update spec.json as instructed → continue loop
   - `ESCALATION:` → Present issue to user, relay decision to Coordinator → continue loop
   - `DIRECT_ACTION:` → Execute requested action directly → continue loop
   - `PIPELINE_COMPLETE` → Dismiss Coordinator → exit loop → proceed to Post-Completion
3. **Repeat** until `PIPELINE_COMPLETE` received

All command dispatchers use this loop after dispatching to Coordinator.

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
- On NO-GO verdict: Auditor sends fix instructions → Coordinator re-spawns Architect/Builder → re-review
- Maximum 3 retries before escalating to user
- On SPEC-UPDATE-NEEDED: fix from spec level (Architect → Planner → Builder → re-review)
- Structural changes (spec splitting, wave restructuring): auto-fix in full-auto mode, escalate in `--gate` mode

### Wave Quality Gate (Roadmap)
- After all specs in a wave complete: Impl Cross-Check review (wave-scoped) → Dead Code review
- Issues found → re-spawn responsible Builder(s) from file ownership records → re-review
- Max 3 retries per gate → escalate to user

## Product Intent

Conductor MUST update `steering/product.md` User Intent section whenever:
- User expresses requirements or vision → update Vision, Success Criteria, Anti-Goals
- Roadmap is created → update Spec Rationale
- Design is started → detail Success Criteria
- User makes a decision → append to Decision Log
- Direction changes → update Vision/Criteria

Auditor references User Intent during every review for:
1. **Alignment check**: spec/impl matches Vision and Success Criteria
2. **Over-engineering check**: design/impl does not violate Anti-Goals
3. **Spec structure check**: Spec Rationale matches actual spec decomposition

## Incremental Persistence (Handover)

State is persisted incrementally to `{{SDD_DIR}}/handover/` — NOT triggered by compact.

| Event | Writer | File | Content |
|-------|--------|------|---------|
| Phase transition | Conductor | conductor.md | Next Action, Active Goals |
| User decision | Conductor | conductor.md | Key Decisions |
| Teammate completion | Coordinator | coordinator.md | Pipeline State, Active Teammates |
| Teammate spawn | Coordinator | coordinator.md | Active Teammates |
| Knowledge report | Coordinator | coordinator.md | Knowledge Buffer |
| Wave completion | Coordinator | coordinator.md | Pipeline State reset, Knowledge flush |

Each role overwrites its handover file as a **latest snapshot** (not append).

### Session Resume
On session start (new or post-compact):
1. If `{{SDD_DIR}}/handover/conductor.md` exists → read it
2. Spawn Coordinator
3. Coordinator reads `{{SDD_DIR}}/handover/coordinator.md`
4. Coordinator restores pipeline state and requests necessary teammate spawns
5. Resume from interruption point

## Knowledge Auto-Accumulation

- Builder/Inspector report learnings with tags: `[PATTERN]`, `[INCIDENT]`, `[REFERENCE]`
- Coordinator collects tagged reports from all teammates
- On wave completion: Coordinator aggregates, deduplicates, and writes to `{{SDD_DIR}}/project/knowledge/`
- Skill emergence: when 2+ specs share the same pattern, Coordinator proposes Skill candidates to Conductor → user approval

## Pipeline Stop Protocol

When user requests stop during pipeline execution:
1. Conductor sends stop signal to Coordinator
2. Coordinator saves current pipeline state to `{{SDD_DIR}}/handover/coordinator.md`
3. Coordinator sends `DISMISS_REQUEST` for all active T3/T4 teammates
4. Conductor dismisses listed teammates
5. Conductor dismisses Coordinator
6. Conductor updates `{{SDD_DIR}}/handover/conductor.md` with interruption point
7. Report to user: what was completed, what was in progress, how to resume

Resume: `/sdd-roadmap run` reads handover state and resumes from interruption point.

## Behavioral Rules
- After a compact operation, ALWAYS wait for the user's next instruction. NEVER start any action autonomously after compact.
- Do not continue or resume previously in-progress tasks after compact unless the user explicitly instructs you to do so.
- Follow the user's instructions precisely, and within that scope act autonomously: gather the necessary context and complete the requested work end-to-end, asking questions only when essential information is missing or critically ambiguous.

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
