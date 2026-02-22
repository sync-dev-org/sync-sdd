# AI-DLC and Spec-Driven Development (v{{SDD_VERSION}})

Spec-Driven Development framework for AI-DLC (AI Development Life Cycle)

> **Architecture**: Agent Teams mode (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` in `settings.json`).
> Agents communicate via spawn/dismiss/SendMessage. Do NOT convert to subagent-only architecture.
> **Note**: Agent Teams is an experimental feature. API changes may require framework updates.
> Internal tool names: `TeammateTool` (spawn/shutdown/cleanup), `SendMessageTool` (direct/broadcast/shutdown_request).

## Role Architecture

### 3-Tier Hierarchy

```
Tier 1: Command  ─── Lead ─────────────────────── (Lead, Opus)
Tier 2: Brain    ─── Architect / Auditor ────────────── (Teammate, Opus)
Tier 3: Execute  ─── TaskGenerator / Builder / Inspector ─── (Teammate ×N, Sonnet)
```

| Tier | Role | Responsibility |
|------|------|---------------|
| T1 | **Lead** | User interaction, phase gate checks, spawn planning, progress tracking, teammate lifecycle management, spec.yaml updates, Knowledge aggregation. |
| T2 | **Architect** | Design generation, research, discovery. Produces design.md + research.md. |
| T2 | **Auditor** | Review synthesis. Merges Inspector findings into verdict (GO/CONDITIONAL/NO-GO/SPEC-UPDATE-NEEDED). Product Intent checks. |
| T3 | **TaskGenerator** | Task decomposition + execution planning. Generates tasks.yaml with detail bullets, parallelism analysis, file ownership, and Builder groupings. |
| T3 | **Builder** | TDD implementation. RED→GREEN→REFACTOR cycle. Reports [PATTERN]/[INCIDENT] tags. |
| T3 | **Inspector** | Individual review perspectives. 6 inspectors spawned in parallel (design/impl), 4 (dead-code). Outputs CPF findings. |

### Chain of Command

Lead spawns T2/T3 teammates using `TeammateTool`. Do NOT use the `Task` tool to spawn teammates — `Task` creates isolated subagents that cannot participate in Agent Teams messaging (`SendMessageTool` will not reach them).
Teammates complete their work and output a structured completion report as their final text.
Lead reads completion output and determines next actions.

Review pipelines use **file-based communication**: Inspectors write CPF files to a `.review/` directory, Auditor reads them and writes `verdict.cpf`. No SendMessage needed for review data transfer.

Review teammates (Inspector/Auditor) MUST suppress text output to prevent context leakage via idle notifications. After writing their output file, they output ONLY `WRITTEN:{path}` and terminate. All analysis is internal.

### State Management

**spec.yaml is owned by Lead.** T2/T3 teammates MUST NOT update spec.yaml directly.
- Teammates produce work artifacts (design.md, tasks.yaml, code) and output completion reports
- Lead validates results, computes metadata updates (phase, version_refs, changelog)
- Lead updates spec.yaml directly

```
User ──→ Lead ──→ T2/T3 Teammates
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
- **Content changes MUST always be routed through the responsible teammate**

### Phase Gate

Before spawning any teammate, Lead MUST verify:
- `spec.yaml.phase` is appropriate for the requested operation
- If `spec.yaml.phase` is `blocked`: BLOCK with "{feature} is blocked by {blocked_info.blocked_by}"
- If `spec.yaml.phase` is unrecognized: BLOCK with "Unknown phase '{phase}'"
- On failure: report error to user (do NOT spawn teammates unnecessarily)

### Teammate Lifecycle

Lead spawns teammates using `TeammateTool`. Each teammate:
1. Receives context in spawn prompt (feature, paths, scope, instructions)
2. Executes its work autonomously
3. Outputs a structured completion report as final text
4. Goes idle automatically (sends idle notification to Lead)

Lead reads the idle notification and:
- Extracts results (artifacts created, test results, knowledge tags, blocker info)
- Updates spec.yaml metadata (phase, version_refs, changelog)
- Auto-drafts session.md, records decisions to decisions.md, updates buffer.md
- Determines next action (spawn next teammate, escalate to user, etc.)
- Requests shutdown of the teammate (teammate approves and terminates)

For review pipelines: Lead spawns Inspectors first (all via `TeammateTool`). Inspectors write CPF findings to `.review/` directory. After all Inspectors complete, Lead spawns Auditor which reads CPF files and writes `verdict.cpf`. Lead reads the verdict file. See sdd-roadmap §File-Based Review Protocol.

**Builder parallel coordination** (incremental processing): When multiple Builders run in parallel, Lead reads each Builder's completion report as it arrives. On each completion: update tasks.yaml (mark completed tasks as `done`), collect files, store knowledge tags. If next-wave tasks are now unblocked, dismiss completed Builder and spawn next-wave Builders immediately. Final spec.yaml update (phase, implementation.files_created) happens only after ALL Builders complete.

### Agent Teams Known Constraints

- **No shared memory**: Teammates do not share conversation context. All context must be passed via spawn prompt or SendMessage payload.
- **Messaging is bidirectional**: Lead ↔ Teammate, Teammate ↔ Teammate all supported via SendMessage. However, the framework's standard communication pattern is: Lead reads teammate's idle notification output (not message-based).
- **Framework convention — file-based review**: Inspectors write `.cpf` files to `.review/` directory, Auditor reads them. No SendMessage needed for review data transfer.
- **Concurrent teammate limit**: 24 (3 pipelines × 7 teammates + headroom). Consensus mode (`--consensus N`) spawns N pipelines in parallel (7×N teammates).

### Teammate Failure Handling

File-based review protocol makes all teammate outputs idempotent (same `.review/` directory, same file paths). If a teammate goes idle without producing its output file, Lead uses its own judgment to retry, skip, or derive results from available files. No special recovery mode — retry is the same flow as the initial attempt.

## Project Context

### Paths
- **SDD Root**: `{{SDD_DIR}}` = `.claude/sdd`
- Steering: `{{SDD_DIR}}/project/steering/`
- Specs: `{{SDD_DIR}}/project/specs/`
- Knowledge: `{{SDD_DIR}}/project/knowledge/`
- Handover: `{{SDD_DIR}}/handover/`
- Rules: `{{SDD_DIR}}/settings/rules/`
- Templates: `{{SDD_DIR}}/settings/templates/`
- Agent Profiles: `{{SDD_DIR}}/settings/agents/`

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

### Commands (9)

| Command | Description |
|---------|-------------|
| `/sdd-steering` | Set up project context (create/update/delete/custom) |
| `/sdd-roadmap` | Unified spec lifecycle: design, impl, review, run, revise, create, update, delete |
| `/sdd-design` | _Redirects to_ `/sdd-roadmap design` |
| `/sdd-impl` | _Redirects to_ `/sdd-roadmap impl` |
| `/sdd-review` | _Redirects to_ `/sdd-roadmap review` |
| `/sdd-status` | Check progress + impact analysis |
| `/sdd-handover` | Generate session handover document |
| `/sdd-knowledge` | Manage reusable knowledge entries |
| `/sdd-release` | Create a versioned release (branch, tag, push) |

### Stages
- Stage 0 (optional): `/sdd-steering`
- Stage 1 (Specification):
  - `/sdd-roadmap design "description"` (new) or `/sdd-roadmap design {feature}` (edit existing)
  - `/sdd-roadmap review design {feature}` (optional)
- Stage 2 (Implementation):
  - `/sdd-roadmap impl {feature} [tasks]`
  - `/sdd-roadmap review impl {feature}` (optional)
- Multi-feature: `/sdd-roadmap create` → `/sdd-roadmap run`
- Progress check: `/sdd-status {feature}` (anytime)

All lifecycle operations auto-create a 1-spec roadmap if none exists. Roadmap is always required.

### Phase-Driven Workflow
- Phases: `initialized` → `design-generated` → `implementation-complete` (also: `blocked`)
  - Revision: `implementation-complete` → `design-generated` → (full pipeline) → `implementation-complete`
- Each phase gate is enforced by the next command
- Keep steering current and verify alignment with `/sdd-status`

### SPEC-Code Atomicity
- SPEC changes (design.md, tasks.yaml) and code changes belong in the same logical unit
- Editing specs triggers full cascade: design → implementation
- On SPEC-UPDATE-NEEDED verdict: fix the spec first, do not re-implement

### Auto-Fix Loop (Review)

CONDITIONAL = GO (proceed; remaining issues are persisted to `specs/{feature}/verdicts.md` Tracked section). Auto-fix triggers on NO-GO or SPEC-UPDATE-NEEDED only:
1. Extract fix instructions from Auditor's verdict
2. Dismiss review teammates
3. Track counters: `retry_count` for NO-GO (max 3), `spec_update_count` for SPEC-UPDATE-NEEDED (max 2, separate)
4. Determine fix scope and spawn fix teammates (all via `TeammateTool`):
   - **NO-GO (design review)** → spawn Architect with fix instructions
   - **NO-GO (impl review)** → spawn Builder(s) with fix instructions
   - **SPEC-UPDATE-NEEDED** → reset `orchestration.last_phase_action = null`, set `phase = design-generated`, then cascade: spawn Architect (with SPEC_FEEDBACK from Auditor) → TaskGenerator → Builder. All tasks fully re-implemented.
   - **Structural changes** → auto-fix in full-auto mode, escalate in `--gate` mode
   - **NO-GO (wave quality gate)** → map findings to file paths → identify responsible Builder(s) from file ownership records → spawn with fix instructions
5. After fix, dismiss fix teammates, then spawn review pipeline (Inspectors + Auditor) again
6. If `retry_count` ≥ 3 or `spec_update_count` ≥ 2 → escalate to user
7. **Aggregate cap**: Total cycles (retry_count + spec_update_count) MUST NOT exceed 4. Escalate to user at aggregate 4.

### Wave Quality Gate (Roadmap)
- After all specs in a wave complete: Impl Cross-Check review (wave-scoped) → Dead Code review
- Issues found → re-spawn responsible Builder(s) from file ownership records → re-review
- Max 3 retries per gate → escalate to user. On escalation, user chooses: proceed to Dead Code review despite issues, or abort wave
- Wave completion condition: all specs in wave are `implementation-complete` or `blocked`
- CONDITIONAL = GO (proceed; remaining issues are persisted to `specs/verdicts-wave.md`)
- Wave scope is cumulative: Wave N quality gate re-inspects ALL code from Waves 1..N
- **NEW issue detection**: Lead reads `specs/verdicts-wave.md` to collect resolved issues from waves 1..{N-1}. Lead includes in Inspector spawn context: "Previously resolved issues: {resolved findings from verdicts-wave.md}". Inspectors MUST NOT re-flag resolved items. If an issue recurs after being marked resolved, flag as REGRESSION (upgrade severity by one level).

### Blocking/Unblocking Protocol

When a spec fails after exhausting retries:
1. Traverse dependency graph → identify all downstream specs
2. For each downstream spec:
   - Save current phase to `blocked_info.blocked_at_phase`
   - Set `phase` = `blocked`
   - Set `blocked_info.blocked_by` = `{failed_spec}`
   - Set `blocked_info.reason` = `upstream_failure`

When user requests unblocking:
- **fix**: Verify upstream spec phase is `implementation-complete` (re-run `/sdd-roadmap review impl` if needed). Only after verification: restore downstream phase from `blocked_at_phase` → clear `blocked_info`
- **skip**: Exclude upstream spec → evaluate if dependencies resolved → restore if possible
- **abort**: Stop pipeline, leave all specs as-is

### Auto-Fix Loop Details

- `retry_count`: incremented only on NO-GO (max 3). CONDITIONAL does NOT count. **Reset to 0 on GO/CONDITIONAL verdict.**
- `spec_update_count`: incremented only on SPEC-UPDATE-NEEDED (max 2). Separate from `retry_count`. **Reset to 0 on GO/CONDITIONAL verdict.**
- Cascade during Architect failure: escalate entire spec to user
- Structural changes (spec split, etc.): escalate to user, record DIRECTION_CHANGE in decisions.md
- Design Review Auto-Fix: after fix, phase remains `design-generated`
- SPEC-UPDATE-NEEDED cascade: Lead resets `orchestration.last_phase_action = null`, sets `phase = design-generated`, passes SPEC_FEEDBACK from Auditor to Architect's spawn prompt. All tasks are fully re-implemented (no differential — Builder overwrites)

### File Ownership (Cross-Spec, Advisory)

File ownership is **advisory**: it guides Builder task assignment and auto-fix routing but is not enforced at the file system level. Builders may read files outside their assigned scope; they SHOULD NOT write to files owned by another spec's Builder unless the task explicitly requires cross-spec integration.

- `buffer.md`: Lead has exclusive write access (no parallel write conflicts)
- Cross-Spec file overlap resolution (Layer 2, Lead responsibility):
  1. After all parallel specs' tasks.yaml are generated, collect file lists from each execution section
  2. Detect overlap: for each file pair (group_A, group_B) where both claim the same file
  3. If A and B are in same wave (parallel candidates): serialize the overlapping specs OR partition file ownership by re-spawning TaskGenerator with file exclusion constraints
  4. If A depends on B (or vice versa): OK (already serialized by dependency)
  5. Record final file ownership assignments for auto-fix routing

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

Auditor verdicts may include a `STEERING:` section with two levels:

| Level | Meaning | Processing | Blocks pipeline |
|-------|---------|-----------|----------------|
| `CODIFY` | Document existing implicit pattern | Lead applies directly + appends to decisions.md | No |
| `PROPOSE` | New constraint affecting future work | Lead presents to user for approval | Yes |

When Auditor verdict contains a `STEERING:` section:
1. Parse `STEERING:` lines: `{CODIFY|PROPOSE}|{target file}|{decision text}`
2. Route by level:
   - **CODIFY** → Update `steering/{target file}` directly + append to `decisions.md` with Reason (STEERING_UPDATE)
   - **PROPOSE** → Present to user for approval
     - On approval → update `steering/{target file}` + append to `decisions.md` (STEERING_UPDATE)
     - On rejection → append to `decisions.md`: STEERING_EXCEPTION with Reason and Steering-ref, or USER_DECISION if simply rejected
3. Process STEERING entries **after** handling the verdict (GO/NO-GO/etc.) but **before** advancing to the next phase

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

```markdown
# Session Handover
**Generated**: {YYYY-MM-DD}
**Branch**: {branch}
**Session Goal**: {confirmed with user}

## Direction
### Immediate Next Action
{specific command or step}

### Active Goals
{progress toward objectives — table or bullet list, independent of roadmap}

### Key Decisions
**Continuing from previous sessions:**
{numbered list — decision + brief rationale, ref decisions.md for details}

**Added this session:**
{same format}

### Warnings
{constraints, risks, caveats for the next Lead}

## Session Context
### Tone and Nuance
{user's temperature, direction nuances — e.g., "experimental, proceed carefully", "user is enthusiastic about this direction"}

### Steering Exceptions
{intentional deviations from steering best practices — reason + decisions.md ref}

## Accomplished
{work completed this session}

### Modified Files
{file list}

## Resume Instructions
{1-3 steps for next session startup}
```

### decisions.md Format

Append-only structured log. Each entry: `[{ISO-8601}] D{seq}: {DECISION_TYPE} | {summary}` followed by fields: Context, Decision, Reason, Impact, Source, Steering-ref (if STEERING_EXCEPTION).

Decision types: `USER_DECISION` (user choice), `STEERING_UPDATE` (steering modified), `DIRECTION_CHANGE` (scope/wave change), `ESCALATION_RESOLVED` (escalation outcome), `STEERING_EXCEPTION` (intentional deviation — prevents review false-positives), `SESSION_START`/`SESSION_END` (session lifecycle; Reason/Impact optional).

### buffer.md Format

```markdown
# Handover Buffer
**Updated**: {timestamp}

## Knowledge Buffer
- [PATTERN] {description} (source: {spec} {role}, task {N})
- [INCIDENT] {description} (source: {spec} {role}, task {N})

## Skill Candidates
- **{name}**: Detected in {specs} ({N} occurrences)
```

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
- Lead collects tagged reports from teammate completion outputs and writes to `buffer.md`
- On wave completion: Lead aggregates, deduplicates, and writes to `{{SDD_DIR}}/project/knowledge/`
- Skill emergence: When buffer.md Knowledge Buffer contains 2+ `[PATTERN]` entries sharing the same category AND description pattern, Lead adds a Skill candidate entry to buffer.md Skill Candidates section. Surfaced to user via `/sdd-knowledge --skills` or at wave completion. Lead does NOT auto-create Skill files without user approval.

## Pipeline Stop Protocol

When user requests stop during pipeline execution:
1. Lead dismisses all active T2/T3 teammates
2. Lead auto-drafts `session.md` with current direction and progress
3. Report to user: what was completed, what was in progress, how to resume

Resume: `/sdd-roadmap run` scans all `spec.yaml` files to rebuild pipeline state and resumes from interruption point. For 1-spec roadmaps, use the specific subcommand (e.g., `/sdd-roadmap impl {feature}`) to resume from the interrupted phase.

## Behavioral Rules
- **Roadmap Required**: All spec lifecycle operations (design, impl, review) flow through `/sdd-roadmap`. If no roadmap exists, a 1-spec roadmap is auto-created. Direct `/sdd-design`, `/sdd-impl`, `/sdd-review` commands redirect to their `/sdd-roadmap` equivalents. Do NOT use individual commands directly — always use `/sdd-roadmap {subcommand}`.
- **Change Request Triage**: Before editing any file, check whether it appears in any spec's `implementation.files_created`. If it does, do NOT edit directly — route through the spec's revision workflow (see §Artifact Ownership). This applies regardless of how the change was requested (bug report, feature request, quick fix, user instruction).
- After a compact operation, ALWAYS wait for the user's next instruction. NEVER start any action autonomously after compact.
- Do not continue or resume previously in-progress tasks after compact unless the user explicitly instructs you to do so.
- Follow the user's instructions precisely, and within that scope act autonomously: gather the necessary context and complete the requested work end-to-end, asking questions only when essential information is missing or critically ambiguous.

## Execution Conventions

- **No comment preamble in Bash commands**: The `command` argument to Bash must begin with the executable. Do not prepend `#` comment lines. Use the Bash tool's `description` parameter for human-readable context.
- **Use steering Common Commands**: When running project tools (test, lint, build, format, run), use the exact command patterns from `steering/tech.md` Common Commands. Do not substitute alternative invocations (e.g., if tech.md says `uv run pytest`, do not use bare `pytest` or `python3 -m pytest`).
- **Inline scripts use project runtime**: For inline scripting (`-c` flags, heredocs), prefix with the project's runtime from `steering/tech.md` (e.g., `uv run python -c "..."` not bare `python -c "..."`).

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
