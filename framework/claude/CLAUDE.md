# AI-DLC and Spec-Driven Development (v{{SDD_VERSION}})

Spec-Driven Development framework for AI-DLC (AI Development Life Cycle)

> **Architecture**: SubAgent mode via `Task` tool with `subagent_type` parameter.
> Lead dispatches work to SubAgents defined in `.claude/agents/`. SubAgents auto-execute and return results.
> SubAgent definitions use YAML frontmatter for model, tools, and description.

## Role Architecture

### 3-Tier Hierarchy

```
Tier 1: Command  ─── Lead ─────────────────────── (Lead, Opus)
Tier 2: Brain    ─── Analyst / Architect / Auditor ─────── (SubAgent, Opus)
Tier 3: Execute  ─── TaskGenerator / Builder / Inspector / ConventionsScanner ─── (SubAgent ×N, Sonnet)
```

| Tier | Role | Responsibility |
|------|------|---------------|
| T1 | **Lead** | User interaction, phase gate checks, dispatch planning, progress tracking, SubAgent orchestration, spec.yaml updates. |
| T2 | **Analyst** | Holistic project analysis, zero-based redesign proposal, steering reform/generation. Produces analysis-report.md + updated steering. |
| T2 | **Architect** | Design generation, research, discovery. Produces design.md + research.md. |
| T2 | **Auditor** | Review synthesis. Merges Inspector findings into verdict (GO/CONDITIONAL/NO-GO; Impl Auditor also: SPEC-UPDATE-NEEDED). Product Intent checks. |
| T3 | **TaskGenerator** | Task decomposition + execution planning. Generates tasks.yaml with detail bullets, parallelism analysis, file ownership, and Builder groupings. |
| T3 | **Builder** | TDD implementation. RED→GREEN→REFACTOR→VERIFY→SELF-CHECK→MARK COMPLETE cycle. Reports SelfCheck quality status and [PATTERN]/[INCIDENT]/[REFERENCE] tags. |
| T3 | **Inspector** | Individual review perspectives. 6 design, 6 impl +2 web (impl only, web projects), 4 dead-code. Outputs CPF findings. |
| T3 | **ConventionsScanner** | Codebase pattern scanning. Generates conventions brief (naming, error handling, schema, imports, testing). Pilot convention supplement. |

### Chain of Command

Lead dispatches T2/T3 SubAgents using `Task` tool with `subagent_type` parameter (e.g., `Task(subagent_type="sdd-architect", prompt="...")`). SubAgents are defined in `.claude/agents/` with YAML frontmatter specifying model, tools, and description.
SubAgents execute their work autonomously and return a structured completion report as their Task result.
Lead reads the Task result and determines next actions.

Review pipelines use **file-based communication**: Inspectors write CPF files to `reviews/active/` directory, Auditor reads them and writes `verdict.cpf`. After verdict is persisted, the directory is renamed to `reviews/B{seq}/` for archival. No inter-agent messaging needed for review data transfer.

All SubAgents MUST keep their Task result output minimal to preserve Lead's context budget (token efficiency). File-heavy outputs (reports, analysis, file lists) → write to file, return `WRITTEN:{path}`. Lead reads files on-demand via targeted Read/Grep. Specifically:
- **Review SubAgents** (Inspector/Auditor): return ONLY `WRITTEN:{path}`. All analysis goes into CPF output files.
- **Builder**: write full report to `builder-report-{group}.md`, return only structured summary (status, counts, report path). See sdd-builder agent definition.
- **Analyst**: write analysis report to `{{SDD_DIR}}/project/reboot/analysis-report.md`, return structured summary (`ANALYST_COMPLETE` + counts + `Files to delete: {count}` + `WRITTEN:{path}`).
- **Architect / TaskGenerator**: current report format is already concise — no file-based output required unless reports grow.

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

Lead dispatches SubAgents via `Task` tool with `run_in_background: true` **always**. No exceptions — even when only one SubAgent is active, foreground dispatch is prohibited. This ensures Lead never blocks the user's terminal during pipeline execution. Lead uses `TaskOutput` to collect results when needed.

**Builder parallel coordination**: As each Builder completes, immediately update tasks.yaml (mark `done`), collect files, store knowledge tags. Final spec.yaml update only after ALL Builders complete.

Operational details (dispatch prompts, review protocol, incremental processing): see sdd-roadmap `refs/run.md`.

### Parallel Execution Model

Roadmap execution maximizes parallelism at multiple levels:

- **Wave Scheduling** (planning): Foundation-First placement, topological-sort-based wave assignment, parallelism report. See sdd-roadmap `refs/crud.md`.
- **Design Fan-Out**: Independent specs within a wave have their Architects dispatched in parallel.
- **Spec Stagger**: Specs within the same wave can be at different pipeline phases simultaneously (e.g., spec-a in Impl while spec-b in Design Review). Lead uses a ready-spec dispatch loop.
- **Design Lookahead**: Next-wave Design starts once current-wave dependencies reach `design-generated`, before current-wave Implementation completes. Impl is gated on Wave QG.
- **Wave Bypass**: Island specs (no dependencies, no dependents) run as independent fast-track pipelines outside the wave structure.
- **Builder parallelism**: Within a spec, multiple Builders execute in parallel per TaskGenerator groupings.
- **Inspector parallelism**: All Inspectors for a review dispatch in parallel; Auditor synthesizes after all complete.
- **Cross-Cutting Parallelism**: Tier-based parallel revision for multi-spec changes. Impact analysis classifies specs (FULL/AUDIT/SKIP), triage eliminates unnecessary work, and execution tiers run in parallel within each tier. See sdd-roadmap `refs/revise.md` Part B.
- **Wave Context**: Shared context artifacts (conventions brief, shared research) generated before Agent dispatch to ensure consistency across parallel Agents. ConventionsScanner generates the conventions brief (codebase pattern scanning stays out of Lead's context); shared research eliminates redundant Architect discovery. Pilot Stagger seeds conventions via ConventionsScanner supplement mode. See sdd-roadmap `refs/run.md` Step 2.5 and `refs/impl.md` Pilot Stagger Protocol.

See sdd-roadmap `refs/run.md` Step 3-4 for dispatch loop details.

### SubAgent Platform Constraints

- **No shared memory**: SubAgents do not share conversation context. All context must be passed via the Task prompt.
- **Result-based communication**: SubAgents return their result as the Task return value. Lead reads this directly in its context window — keep results concise.
- **Framework convention — file-based review**: Inspectors write `.cpf` files to `reviews/active/` directory, Auditor reads them. Completed reviews are archived to `reviews/B{seq}/`. No inter-agent messaging needed for review data transfer.
- **Concurrency**: No framework-imposed SubAgent limit. Platform manages concurrent execution. Consensus mode (`--consensus N`) dispatches N pipelines in parallel.

### SubAgent Failure Handling

File-based output protocol makes SubAgent outputs idempotent. If a SubAgent fails or returns without producing its output file, Lead uses its own judgment to retry, skip, or derive results from available files. Retry dispatches the same Task prompt — the flow is identical to the initial attempt. This applies to all file-writing SubAgents (Inspectors → CPF files, Auditors → verdict.cpf, Builders → builder-report files, ConventionsScanner → conventions-brief, Analyst → analysis-report).

## Project Context

### Paths
- **SDD Root**: `{{SDD_DIR}}` = `.sdd`
- Steering: `{{SDD_DIR}}/project/steering/`
- Specs: `{{SDD_DIR}}/project/specs/` (cross-cutting briefs/verdicts: `specs/.cross-cutting/{id}/`)
- Handover: `{{SDD_DIR}}/handover/`
- Rules: `{{SDD_DIR}}/settings/rules/`
- Templates: `{{SDD_DIR}}/settings/templates/`
- Profiles: `{{SDD_DIR}}/settings/profiles/`
- Agent Profiles: `.claude/agents/`

### Artifacts

| Artifact | Scope | Purpose | Portable |
|----------|-------|---------|----------|
| **Steering** | Project-specific | Project-wide rules, context, decisions | No |
| **Specs** | Feature-specific | Design + architecture + tasks for a feature | No |
| **Verdicts** | Feature/Wave-specific | Review verdicts, consensus findings, issue tracking | No |

- Project-specific decisions (tech stack, architecture) → Steering
- Feature implementation details → Specs

### Active Specifications
- Check `{{SDD_DIR}}/project/specs/` for active specifications
- Use `/sdd-status [feature-name]` to check progress

## Workflow

### Commands (6)

| Command | Description |
|---------|-------------|
| `/sdd-steering` | Set up project context (create/update/delete/custom) |
| `/sdd-roadmap` | Unified spec lifecycle: design, impl, review, run, revise, create, update, delete |
| `/sdd-reboot` | Zero-based project redesign (analysis + design pipeline on feature branch) |
| `/sdd-status` | Check progress + impact analysis |
| `/sdd-handover` | Generate session handover document |
| `/sdd-release` | Create a versioned release (branch, tag, push) |

### Phase-Driven Workflow
- Phases: `initialized` → `design-generated` → `implementation-complete` (also: `blocked`)
- Revision: `implementation-complete` → `design-generated` → (full pipeline) → `implementation-complete`
- All lifecycle operations auto-create a 1-spec roadmap if none exists. Roadmap is always required.

### SPEC-Code Atomicity
- SPEC changes (design.md, tasks.yaml) and code changes belong in the same logical unit
- Editing specs triggers full cascade: design → implementation
- On SPEC-UPDATE-NEEDED verdict: fix the spec first, then re-implement via cascade

### Stages
- Stage 0 (optional): `/sdd-steering`
- Stage 1 (Specification): `/sdd-roadmap design` → `/sdd-roadmap review design` (optional)
- Stage 2 (Implementation): `/sdd-roadmap impl` → `/sdd-roadmap review impl` (optional)
- Multi-feature: `/sdd-roadmap create` → `/sdd-roadmap run`
- Progress check: `/sdd-status` (anytime)

### Auto-Fix Counter Limits

- `retry_count`: max 5 (NO-GO only). `spec_update_count`: max 2 (SPEC-UPDATE-NEEDED only). Aggregate cap: 6.
- **Exception**: Dead-Code Review NO-GO: max 3 retries (dead-code findings are simpler scope; exhaustion → escalate).
- CONDITIONAL = GO (proceed). Counters are NOT reset on intermediate GO/CONDITIONAL.
- Counter reset triggers: wave completion, user escalation decision (including blocking protocol fix/skip), `/sdd-roadmap revise` start, session resume (dead-code counters are in-memory only; see `refs/run.md`).
- Full auto-fix loop, wave quality gate, and blocking protocol details: see sdd-roadmap `refs/run.md`.

### decisions.md Recording

Lead records the following decision types as a standard behavior:
- `USER_DECISION`: when user makes an explicit choice
- `STEERING_UPDATE`: steering modified
- `DIRECTION_CHANGE`: spec split, wave restructure, scope change
- `ESCALATION_RESOLVED`: outcome of an escalation to user
- `REVISION_INITIATED`: user-initiated past-wave spec revision (append `(cross-cutting)` for multi-spec revisions)
- `STEERING_EXCEPTION`: intentional deviation from steering (prevents review false-positives)
- `SESSION_START`/`SESSION_END`: session lifecycle

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
| `buffer.md` | Overwrite (auto) | Knowledge tags from Builder reports |
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

**Exception — `run` pipeline dispatch loop**: Auto-draft only at Wave QG post-gate, user escalation, and pipeline completion. Skip at individual phase completions (Design, Impl, Review per spec). spec.yaml is ground truth for pipeline state; intermediate session.md freshness is unnecessary.

**Manual polish** (`/sdd-handover`):
1. Archive current session.md to `sessions/{date}.md`
2. Enrich via user interaction: Session Goal, Tone/Nuance, Steering Exceptions, Key Decisions refinement, Warnings, Resume Instructions
3. Write without Mode marker (indicates manual polish)

### session.md Format

Template: `{{SDD_DIR}}/settings/templates/handover/session.md`

### decisions.md Format

Append-only structured log. Each entry: `[{ISO-8601}] D{seq}: {DECISION_TYPE} | {summary}` followed by fields: Context, Decision, Reason, Impact, Source, Steering-ref (if STEERING_EXCEPTION).

Decision types: `USER_DECISION` (user choice), `STEERING_UPDATE` (steering modified), `DIRECTION_CHANGE` (scope/wave change), `ESCALATION_RESOLVED` (escalation outcome), `REVISION_INITIATED` (user-initiated past-wave spec revision; append `(cross-cutting)` for multi-spec revisions), `STEERING_EXCEPTION` (intentional deviation — prevents review false-positives), `SESSION_START`/`SESSION_END` (session lifecycle; Reason/Impact optional).

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
| Session start | decisions.md | SESSION_START auto-append |

### Session Resume

On session start (new Claude Code session, conversation compact, or `/sdd-handover` resume):
1. Detect: `{{SDD_DIR}}/handover/session.md` exists?
   - Absent → first session: skip to step 6
   - Present → resume session: proceed
2. Read `{{SDD_DIR}}/handover/session.md` → Direction, Context, Warnings, Steering Exceptions
2a. Read `{{SDD_DIR}}/project/specs/*/reviews/verdicts.md` → active review state per spec (latest batch Tracked)
3. Read latest N entries from `decisions.md` → recent decision history
4. Read `buffer.md` → pending knowledge tags
5. If roadmap active: scan all `spec.yaml` files → build pipeline state dynamically
6. Append `SESSION_START` to `decisions.md`
7. If roadmap pipeline was active (session.md indicates run/revise in progress):
     - Continue pipeline from spec.yaml state. Treat spec.yaml as ground truth.
     - Do NOT manually update spec.yaml to "recover" or "fix" perceived inconsistencies.
     - If spec.yaml state vs actual artifacts seem inconsistent: report to user, do not auto-fix.
   Otherwise: await user instruction.

## Knowledge Auto-Accumulation

- Builder reports learnings with tags: `[PATTERN]`, `[INCIDENT]`, `[REFERENCE]`
- Lead extracts tags from builder-report files via targeted Grep (when Builder summary indicates Tags > 0) and appends to `{{SDD_DIR}}/handover/buffer.md`
- buffer.md persists across sessions via handover. No auto-flush to separate files.

## Pipeline Stop Protocol

When user requests stop during pipeline execution:
1. Lead auto-drafts `session.md` with current direction and progress
2. Report to user: what was completed, what was in progress, how to resume

Resume: `/sdd-roadmap run` scans all `spec.yaml` files to rebuild pipeline state and resumes from interruption point. For 1-spec roadmaps, use the specific subcommand (e.g., `/sdd-roadmap impl {feature}`) to resume from the interrupted phase.

## Behavioral Rules
- **Roadmap Required**: All spec lifecycle operations (design, impl, review) flow through `/sdd-roadmap`. If no roadmap exists, a 1-spec roadmap is auto-created. Always use `/sdd-roadmap {subcommand}`.
- **Change Request Triage**: Before editing any file, check whether it appears in any spec's `implementation.files_created`. If it does, do NOT edit directly — route through the spec's revision workflow (see Artifact Ownership). This applies regardless of how the change was requested (bug report, feature request, quick fix, user instruction).
- After a compact operation: If a roadmap pipeline (run/revise) was in progress, perform Session Resume steps 1-6 to reload context, then continue the pipeline from spec.yaml state (do NOT manually "recover" or patch spec.yaml — treat it as ground truth). If no pipeline was active, wait for the user's next instruction.
- Do not continue or resume non-pipeline tasks after compact unless the user explicitly instructs you to do so.
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
- Commit message format: `Wave {N}: {summary}` (multi-spec) or `{feature}: {summary}` (1-spec roadmap) or `cross-cutting: {summary}` (cross-cutting revision) or `reboot: {summary}` (reboot redesign)

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
