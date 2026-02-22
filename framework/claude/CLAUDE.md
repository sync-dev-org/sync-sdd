# AI-DLC and Spec-Driven Development (v{{SDD_VERSION}})

Spec-Driven Development framework for AI-DLC (AI Development Life Cycle)

> **Architecture**: SubAgent mode via `Task` tool with `subagent_type` parameter.
> Lead dispatches work to SubAgents defined in `.claude/agents/`. SubAgents auto-execute and return results.
> SubAgent definitions use YAML frontmatter for model, tools, and description.

## Role Architecture

### 3-Tier Hierarchy

```
Tier 1: Command  ─── Lead ─────────────────────── (Lead, Opus)
Tier 2: Brain    ─── Architect / Auditor ────────────── (SubAgent, Opus)
Tier 3: Execute  ─── TaskGenerator / Builder / Inspector ─── (SubAgent ×N, Sonnet)
```

| Tier | Role | Responsibility |
|------|------|---------------|
| T1 | **Lead** | User interaction, phase gate checks, dispatch planning, progress tracking, SubAgent orchestration, spec.yaml updates, Knowledge aggregation. |
| T2 | **Architect** | Design generation, research, discovery. Produces design.md + research.md. |
| T2 | **Auditor** | Review synthesis. Merges Inspector findings into verdict (GO/CONDITIONAL/NO-GO/SPEC-UPDATE-NEEDED). Product Intent checks. |
| T3 | **TaskGenerator** | Task decomposition + execution planning. Generates tasks.yaml with detail bullets, parallelism analysis, file ownership, and Builder groupings. |
| T3 | **Builder** | TDD implementation. RED→GREEN→REFACTOR cycle. Reports [PATTERN]/[INCIDENT] tags. |
| T3 | **Inspector** | Individual review perspectives. 6 design + 6 impl inspectors +1 E2E (web projects), 4 (dead-code). Outputs CPF findings. |

### Chain of Command

Lead dispatches T2/T3 SubAgents using `Task` tool with `subagent_type` parameter (e.g., `Task(subagent_type="sdd-architect", prompt="...")`). SubAgents are defined in `.claude/agents/` with YAML frontmatter specifying model, tools, and description.
SubAgents execute their work autonomously and return a structured completion report as their Task result.
Lead reads the Task result and determines next actions.

Review pipelines use **file-based communication**: Inspectors write CPF files to a `_review/` directory, Auditor reads them and writes `verdict.cpf`. No inter-agent messaging needed for review data transfer.

Review SubAgents (Inspector/Auditor) MUST keep their Task result output minimal to preserve Lead's context budget (token efficiency). After writing their output file, they return ONLY `WRITTEN:{path}` as their final text. All detailed analysis goes into the CPF output file.

### State Management

**spec.yaml is owned by Lead.** T2/T3 SubAgents MUST NOT update spec.yaml directly.
- SubAgents produce work artifacts (design.md, tasks.yaml, code) and return completion reports
- Lead validates results, computes metadata updates (phase, version_refs, changelog)
- Lead updates spec.yaml directly

```
User ──→ Lead ──→ T2/T3 SubAgents
              ◄──
```

### Artifact Ownership

Lead's operations on spec artifacts are restricted to the following:

| Artifact | Lead's Permitted Operations | Owner (Creation/Content Changes) |
|----------|----------------------------|----------------------------------|
| `design.md` | Read-only | Architect |
| `research.md` | Read-only | Architect |
| `tasks.yaml` | Task status updates (`done` marking) only | TaskGenerator (creation/structural changes) |
| Implementation code (`implementation.files_created` の全ファイル) | Read-only | Builder |

**Prohibited**: Lead MUST NOT rewrite design.md content, modify tasks.yaml task definitions, or directly edit any file listed in a spec's `implementation.files_created`.

When the user requests changes (bug fix, enhancement, edit) to any spec-managed file:
- Use `/sdd-roadmap revise {feature}` for completed specs
- Use `/sdd-roadmap design {feature}` for specs not yet implemented
- **Content changes MUST always be routed through the responsible SubAgent**

### Phase Gate

Before dispatching any SubAgent, Lead MUST verify:
- `spec.yaml.phase` is appropriate for the requested operation
- If `spec.yaml.phase` is `blocked`: BLOCK with "{feature} is blocked by {blocked_info.blocked_by}"
- If `spec.yaml.phase` is unrecognized: BLOCK with "Unknown phase '{phase}'"
- On failure: report error to user (do NOT dispatch SubAgents unnecessarily)

### SubAgent Lifecycle

Lead dispatches SubAgents via `Task` tool. SubAgents execute autonomously and return a completion report. Lead reads the result, updates spec.yaml metadata, auto-drafts session.md, and determines next action.

**Builder parallel coordination**: As each Builder completes, immediately update tasks.yaml (mark `done`), collect files, store knowledge tags. Final spec.yaml update only after ALL Builders complete.

Operational details (dispatch prompts, review protocol, incremental processing): see sdd-roadmap `refs/run.md`.

### SubAgent Platform Constraints

- **No shared memory**: SubAgents do not share conversation context. All context must be passed via the Task prompt.
- **Result-based communication**: SubAgents return their result as the Task return value. Lead reads this directly in its context window — keep results concise.
- **Framework convention — file-based review**: Inspectors write `.cpf` files to `_review/` directory, Auditor reads them. No inter-agent messaging needed for review data transfer.
- **Concurrent SubAgent limit**: 24 (3 pipelines x 7 SubAgents + headroom). Consensus mode (`--consensus N`) dispatches N pipelines in parallel (7xN SubAgents).

### SubAgent Failure Handling

File-based review protocol makes all SubAgent outputs idempotent (same `_review/` directory, same file paths). If a SubAgent fails or returns without producing its output file, Lead uses its own judgment to retry, skip, or derive results from available files. Retry dispatches the same Task prompt — the flow is identical to the initial attempt.

## Project Context

### Paths
- **SDD Root**: `{{SDD_DIR}}` = `.claude/sdd`
- Steering: `{{SDD_DIR}}/project/steering/`
- Specs: `{{SDD_DIR}}/project/specs/`
- Knowledge: `{{SDD_DIR}}/project/knowledge/`
- Handover: `{{SDD_DIR}}/handover/`
- Rules: `{{SDD_DIR}}/settings/rules/`
- Templates: `{{SDD_DIR}}/settings/templates/`
- Agent Profiles: `.claude/agents/`

### Artifacts

| Artifact | Scope | Purpose | Portable |
|----------|-------|---------|----------|
| **Steering** | Project-specific | Project-wide rules, context, decisions | No |
| **Specs** | Feature-specific | Design + architecture + tasks for a feature | No |
| **Verdicts** | Feature/Wave-specific | Review verdicts, consensus findings, issue tracking | No |
| **Knowledge** | Cross-project | Reusable insights, patterns, incidents | Yes |

- Project-specific decisions (tech stack, architecture) → Steering
- Feature implementation details → Specs
- Reusable patterns and lessons learned → Knowledge

### Active Specifications
- Check `{{SDD_DIR}}/project/specs/` for active specifications
- Use `/sdd-status [feature-name]` to check progress

## Workflow

### Commands (6)

| Command | Description |
|---------|-------------|
| `/sdd-steering` | Set up project context (create/update/delete/custom) |
| `/sdd-roadmap` | Unified spec lifecycle: design, impl, review, run, revise, create, update, delete |
| `/sdd-status` | Check progress + impact analysis |
| `/sdd-handover` | Generate session handover document |
| `/sdd-knowledge` | Manage reusable knowledge entries |
| `/sdd-release` | Create a versioned release (branch, tag, push) |

### Phase-Driven Workflow
- Phases: `initialized` → `design-generated` → `implementation-complete` (also: `blocked`)
- Revision: `implementation-complete` → `design-generated` → (full pipeline) → `implementation-complete`
- All lifecycle operations auto-create a 1-spec roadmap if none exists. Roadmap is always required.

### SPEC-Code Atomicity
- SPEC changes (design.md, tasks.yaml) and code changes belong in the same logical unit
- Editing specs triggers full cascade: design → implementation
- On SPEC-UPDATE-NEEDED verdict: fix the spec first, then re-implement via cascade

### Auto-Fix Counter Limits

- `retry_count`: max 5 (NO-GO only). `spec_update_count`: max 2 (SPEC-UPDATE-NEEDED only). Aggregate cap: 6.
- CONDITIONAL = GO (proceed). Counters are NOT reset on intermediate GO/CONDITIONAL.
- Counter reset triggers: wave completion, user escalation decision, `/sdd-roadmap revise` start.
- Full auto-fix loop, wave quality gate, and blocking protocol details: see sdd-roadmap `refs/run.md`.

### decisions.md Recording

Lead records the following decision types as a standard behavior:
- `USER_DECISION`: when user makes an explicit choice
- `DIRECTION_CHANGE`: spec split, wave restructure, scope change
- `ESCALATION_RESOLVED`: outcome of an escalation to user
- `REVISION_INITIATED`: user-initiated past-wave spec revision
- `SESSION_START`: auto-append on session resume

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

Auditor verdicts may include `STEERING:` entries: `CODIFY` (Lead applies directly) or `PROPOSE` (Lead presents to user for approval). Process **after** handling the verdict but **before** advancing to the next phase. Full processing rules: see sdd-roadmap `refs/review.md`.

## Handover (Session Persistence)

Session context is persisted to `{{SDD_DIR}}/handover/` for cross-session continuity.

| File | Behavior | Purpose |
|------|----------|---------|
| `session.md` | Auto-draft + manual polish (overwrite) | Lead/User dialogue context: direction, decisions, warnings, nuance |
| `decisions.md` | Append-only (never overwrite) | Decisions with rationale, steering updates, steering exceptions |
| `buffer.md` | Overwrite (auto) | Knowledge Buffer + Skill candidates (temporary data) |
| `sessions/` | Archive | Dated copies of session.md created by `/sdd-handover` |

Pipeline state is NOT stored in handover — `spec.yaml` is the single source of truth for phase/status. Use `/sdd-status` or scan all `spec.yaml` files to reconstruct pipeline state.

### session.md (Auto-Draft + Manual Polish)

session.md is written in two modes:

**Auto-draft** (after each command completion):
1. Read current session.md (if exists)
2. Carry forward: Key Decisions, Warnings, Session Context (Tone/Nuance, Steering Exceptions)
3. Update: Immediate Next Action based on current state
4. Append: latest work to Accomplished section
5. Mark with `**Mode**: auto-draft`
6. Overwrite session.md

**Manual polish** (`/sdd-handover`):
1. Archive current session.md to `sessions/{date}.md`
2. Enrich via user interaction: Session Goal, Tone/Nuance, Steering Exceptions, Key Decisions refinement, Warnings, Resume Instructions
3. Write without Mode marker (indicates manual polish)

### session.md Format

Template: `{{SDD_DIR}}/settings/templates/handover/session.md`

### decisions.md Format

Append-only structured log. Each entry: `[{ISO-8601}] D{seq}: {DECISION_TYPE} | {summary}` followed by fields: Context, Decision, Reason, Impact, Source, Steering-ref (if STEERING_EXCEPTION).

Decision types: `USER_DECISION` (user choice), `STEERING_UPDATE` (steering modified), `DIRECTION_CHANGE` (scope/wave change), `ESCALATION_RESOLVED` (escalation outcome), `STEERING_EXCEPTION` (intentional deviation — prevents review false-positives), `SESSION_START`/`SESSION_END` (session lifecycle; Reason/Impact optional).

### buffer.md Format

Template: `{{SDD_DIR}}/settings/templates/handover/buffer.md`

### Write Triggers

| Trigger | File | Notes |
|---------|------|-------|
| Command completion (design/impl/review/roadmap/steering) | session.md auto-draft | Carry forward + update Next Action/Accomplished |
| `/sdd-handover` | session.md manual polish, decisions.md SESSION_END, sessions/ archive | Manual |
| User decision | decisions.md | Auto-append with Reason |
| STEERING change | decisions.md | Auto-append with Reason |
| Direction change | decisions.md | Auto-append with Reason |
| Knowledge tag received | buffer.md | Auto-overwrite |
| Wave completion (knowledge flush) | buffer.md | Clear after flush to knowledge/ |
| Session start | decisions.md | SESSION_START auto-append |

### Session Resume

On session start (new Claude Code session, conversation compact, or `/sdd-handover` resume):
1. Detect: `{{SDD_DIR}}/handover/session.md` exists?
   - Absent → first session: skip to step 6
   - Present → resume session: proceed
2. Read `{{SDD_DIR}}/handover/session.md` → Direction, Context, Warnings, Steering Exceptions
2a. Read `{{SDD_DIR}}/project/specs/*/verdicts.md` → active review state per spec (latest batch Tracked)
3. Read latest N entries from `decisions.md` → recent decision history
4. Read `buffer.md` → pending Knowledge/Skill candidates
5. If roadmap active: scan all `spec.yaml` files → build pipeline state dynamically
6. Append `SESSION_START` to `decisions.md`
7. Resume from session.md Immediate Next Action (or await user instruction if first session)

## Knowledge Auto-Accumulation

- Builder/Inspector report learnings with tags: `[PATTERN]`, `[INCIDENT]`, `[REFERENCE]`
- Lead collects tagged reports from SubAgent Task results and writes to `buffer.md`
- On wave completion: Lead aggregates, deduplicates, and writes to `{{SDD_DIR}}/project/knowledge/`
- Skill emergence: When buffer.md Knowledge Buffer contains 2+ `[PATTERN]` entries sharing the same category AND description pattern, Lead adds a Skill candidate entry to buffer.md Skill Candidates section. Surfaced to user via `/sdd-knowledge --skills` or at wave completion. Lead does NOT auto-create Skill files without user approval.

## Pipeline Stop Protocol

When user requests stop during pipeline execution:
1. Lead auto-drafts `session.md` with current direction and progress
2. Report to user: what was completed, what was in progress, how to resume

Resume: `/sdd-roadmap run` scans all `spec.yaml` files to rebuild pipeline state and resumes from interruption point. For 1-spec roadmaps, use the specific subcommand (e.g., `/sdd-roadmap impl {feature}`) to resume from the interrupted phase.

## Behavioral Rules
- **Roadmap Required**: All spec lifecycle operations (design, impl, review) flow through `/sdd-roadmap`. If no roadmap exists, a 1-spec roadmap is auto-created. Always use `/sdd-roadmap {subcommand}`.
- **Change Request Triage**: Before editing any file, check whether it appears in any spec's `implementation.files_created`. If it does, do NOT edit directly — route through the spec's revision workflow (see Artifact Ownership). This applies regardless of how the change was requested (bug report, feature request, quick fix, user instruction).
- After a compact operation, ALWAYS wait for the user's next instruction. NEVER start any action autonomously after compact.
- Do not continue or resume previously in-progress tasks after compact unless the user explicitly instructs you to do so.
- Follow the user's instructions precisely, and within that scope act autonomously: gather the necessary context and complete the requested work end-to-end, asking questions only when essential information is missing or critically ambiguous.

## Execution Conventions

- **No comment preamble in Bash commands**: The `command` argument to Bash must begin with the executable. Do not prepend `#` comment lines. Use the Bash tool's `description` parameter for human-readable context.
- **Use steering Common Commands**: When running project tools (test, lint, build, format, run), use the exact command patterns from `steering/tech.md` Common Commands. Do not substitute alternative invocations (e.g., if tech.md says `uv run pytest`, do not use bare `pytest` or `python3 -m pytest`).
- **Inline scripts use project runtime**: For inline scripting (`-c` flags, heredocs), prefix with the project's runtime from `steering/tech.md` (e.g., `uv run python -c "..."` not bare `python -c "..."`).
- **Playwright**: The SDD framework uses `@playwright/cli` (npm package, command: `playwright-cli`) for browser automation (E2E Inspector, etc.). Do NOT install Python Playwright for framework purposes — neither via `pip install playwright`, `uv add playwright`, nor any other Python package manager. If the project itself lists Python Playwright as an existing dependency, treat it as a project-specific dependency entirely separate from the SDD framework tooling. If `playwright-cli` is not available, install it: `npm install -g @playwright/cli@latest && playwright-cli install`.

## Git Workflow

Trunk-based development. main is always HEAD.

### Branch Strategy
- All work happens on main by default
- Feature/topic branches are optional; always merge back to main and delete the branch
- main MUST remain the latest state at all times
- Never leave stale branches; merged branches are deleted immediately

### Commit Timing
- **Wave completion (multi-spec roadmap)**: After Wave Quality Gate passes, Lead commits directly
- **Pipeline completion (1-spec roadmap)**: After individual pipeline completes, Lead commits
- Commit scope: all spec artifacts + implementation changes from the completed work
- Commit message format: `Wave {N}: {summary}` (multi-spec) or `{feature}: {summary}` (1-spec roadmap)

### Release Flow
After a logical milestone (roadmap completion, significant feature set):
Use `/sdd-release <patch|minor|major> <summary>` to automate the release process.
Ecosystem auto-detection: Python (hatch-vcs / standard), TypeScript, Rust, SDD Framework, Other.
main continues to advance; release branch is a snapshot, not merged back.

## Compact Pipe-Delimited Format (CPF)

Token-efficient structured text format for inter-agent communication. Full specification: `{{SDD_DIR}}/settings/rules/cpf-format.md`

## Steering Configuration
- Load entire `{{SDD_DIR}}/project/steering/` as project memory
- Default files: `product.md`, `tech.md`, `structure.md`
- Custom files are supported (managed via `/sdd-steering`)
