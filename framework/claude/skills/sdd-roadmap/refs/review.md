# Review Subcommand

Phase execution reference. Canonical source for ALL review types. Assumes Single-Spec Roadmap Ensure already completed by router (except dead-code/cross-check/wave which skip enrollment).

> **Migration note**: Review execution logic is being migrated to `/sdd-review` skill. This file remains the canonical reference until full integration (Phase 2, Session 5). The `/sdd-review` skill can be used standalone for the same functionality.

Triggered by:
- `$ARGUMENTS = "review design|impl {feature}"` — single-spec review
- `$ARGUMENTS = "review design|impl --cross-check"` — cross-check across all specs (no feature name)
- `$ARGUMENTS = "review design|impl --wave N"` — wave-scoped review (no feature name)
- `$ARGUMENTS = "review dead-code"` — dead-code review

## Step 1: Parse Arguments

Parse review type (`design`/`impl`/`dead-code`), feature name, and options (`--cross-check`, `--wave N`).

If first argument after "review" is not one of `design`, `impl`, `dead-code`:
- Error: "Usage: `/sdd-roadmap review design|impl {feature}` or `/sdd-roadmap review design|impl --cross-check` or `/sdd-roadmap review design|impl --wave N` or `/sdd-roadmap review dead-code`"

**1-Spec Roadmap guard**: If option is `--cross-check` or `--wave N` AND `roadmap.md` contains exactly 1 spec: inform user "Single-spec roadmap — cross-check/wave review has no additional value over single-spec review." and abort.

## Step 2: Phase Gate

**Design Review**: Verify `design.md` exists. Verify `phase` is `design-generated` or `implementation-complete`. BLOCK if `spec.yaml.phase` is `blocked`.
**Implementation Review**: Verify `design.md` and `tasks.yaml` exist. Verify `phase` is `implementation-complete`. BLOCK if `blocked`.
**Dead Code Review**: No phase gate (operates on entire codebase). Roadmap must exist (Router blocks if absent — see SKILL.md).

## Design Review

Spawn via review execution flow (below):
- 6 design Inspectors (sonnet): `sdd-inspector-rulebase`, `sdd-inspector-testability`, `sdd-inspector-architecture`, `sdd-inspector-consistency`, `sdd-inspector-best-practices`, `sdd-inspector-holistic`
- Design Auditor (opus): `sdd-auditor-design`

**Cross-check / wave-scoped mode**: Same Inspector set + Auditor. Each Inspector's context includes cross-check scope (all specs or wave-scoped) instead of single feature.

## Impl Review

Spawn via review execution flow (below):
- Standard impl Inspectors (6, sonnet): `sdd-inspector-impl-rulebase`, `sdd-inspector-interface`, `sdd-inspector-test`, `sdd-inspector-quality`, `sdd-inspector-impl-consistency`, `sdd-inspector-impl-holistic`
- **Projects with E2E commands** (steering/tech.md Common Commands contains `# E2E` with non-empty, non-placeholder command): also spawn `sdd-inspector-e2e`
- **Web projects** (steering/tech.md contains web stack indicators: React, Next.js, Vue, Angular, Svelte, Express, Django+templates, Rails, FastAPI+frontend, etc.): also spawn `sdd-inspector-web-e2e` and `sdd-inspector-web-visual` (Lead manages dev server lifecycle — see Web Inspector Server Protocol below)
- Impl Auditor (opus): `sdd-auditor-impl`

**Cross-check / wave-scoped mode**: Same Inspector set + Auditor. Context includes:
- Wave scope: cumulative (Wave N re-inspects ALL code from Waves 1..N)
- Previously resolved issues: read `{{SDD_DIR}}/project/reviews/wave/verdicts.md`, include as PREVIOUSLY_RESOLVED in Inspector context. Inspectors MUST NOT re-flag resolved items. Recurrence = REGRESSION (upgrade severity).

## Dead-Code Review

Spawn via review execution flow (below):
- 4 dead-code Inspectors (sonnet): `sdd-inspector-dead-settings`, `sdd-inspector-dead-code`, `sdd-inspector-dead-specs`, `sdd-inspector-dead-tests`
- Dead-code Auditor (opus): `sdd-auditor-dead-code`

## Web Inspector Server Protocol (Web Projects Only)

When impl review includes web inspectors (`sdd-inspector-web-e2e` and `sdd-inspector-web-visual`), Lead manages the dev server lifecycle.

Apply **Server Lifecycle pattern** from `{{SDD_DIR}}/settings/rules/tmux-integration.md` (tmux mode + background mode 両方を含む):

1. **Server Start** (before Inspector dispatch):
   - Read dev server command from `steering/tech.md` Common Commands (the `Dev:` entry)
   - If no dev server command found: skip server start, dispatch web inspectors without server URL (they will report "Server URL not accessible" and terminate gracefully)
   - Pane title: `sdd-{SID}-devserver-{feature}`
   - Ready pattern: `ready`, `localhost`, `listening on`
   - Port offset for Spec Stagger parallel reviews
   - Record server URL (e.g., `http://localhost:{port}`)

2. **Inspector Dispatch**: Include server URL in spawn context for `sdd-inspector-web-e2e` and `sdd-inspector-web-visual`. Both inspectors use the already-running server — they do NOT start or stop it.

3. **Server Stop** (after all Inspectors complete, before Auditor dispatch): Kill pane per pattern.

### Common Rules

- If server fails to start: dispatch web inspectors anyway (they will report the error in their CPF output and terminate gracefully)
- Read dev server command from `steering/tech.md` Common Commands — do not hardcode commands

## Review Execution Flow

> **Dispatch loop context**: Within `run.md` dispatch loop, this flow is decomposed into dispatch-loop events (see run.md §Review Decomposition). The sequential flow below applies to standalone review invocations.

1. Determine review scope directory:
   - **Per-feature** (design/impl with feature name): `{{SDD_DIR}}/project/specs/{feature}/reviews/`
   - **Project-level** (dead-code): `{{SDD_DIR}}/project/reviews/dead-code/` (standalone). When called from Wave QG (run.md Step 7b): use `{{SDD_DIR}}/project/reviews/wave/` instead.
   - **Project-level** (cross-check via `--cross-check`): `{{SDD_DIR}}/project/reviews/cross-check/`
   - **Project-level** (wave-scoped via `--wave N`): `{{SDD_DIR}}/project/reviews/wave/`
   - **Project-level** (cross-cutting from revise.md): `{{SDD_DIR}}/project/specs/.cross-cutting/{id}/`
2. Determine B{seq}: read `{scope-dir}/verdicts.md`, increment max existing batch number (or start at 1).
3. Create review directory: `{scope-dir}/active/`
3a. **Web projects (impl review only)**: Start dev server per Web Inspector Server Protocol above.
4. Spawn all Inspectors via `Agent(subagent_type=..., run_in_background=true)`. Each context includes:
   - Review output path: `{scope-dir}/active/{inspector-name}.cpf`
   - Feature/scope context
   - **E2E inspector**: no additional context needed (self-loads from steering and design.md)
   - **Web inspectors**: also include server URL
5. Wait for all Inspector agents to complete (poll via `TaskOutput`). Handle failed Inspectors: retry, skip, or proceed with available results.
5a. **Web projects (impl review only)**: Stop dev server per Web Inspector Server Protocol above.
6. Spawn Auditor via `Agent(subagent_type=..., run_in_background=true)`. Context includes:
   - Review directory path (Auditor reads all `.cpf` files)
   - Verdict output path: `{scope-dir}/active/verdict.cpf`
   - Steering Exceptions from `{{SDD_DIR}}/handover/session.md`
   - Builder SelfCheck warnings (if any, from impl phase): items flagged as WARN during Builder self-validation — treat as attention points, not authoritative findings
7. Read `{scope-dir}/active/verdict.cpf`
8. Persist verdict to `{scope-dir}/verdicts.md` (see Router → Verdict Persistence Format)
9. Archive: rename `{scope-dir}/active/` → `{scope-dir}/B{seq}/`

## Standalone Verdict Handling

When review is invoked standalone (not within run/revise pipeline):
1. Display formatted verdict report to user
2. **No auto-fix**: Report verdict and stop. Auto-fix loops are only executed within pipeline orchestration.
3. **Process STEERING entries** (see below)
4. Auto-draft `{{SDD_DIR}}/handover/session.md`

## Steering Feedback Loop Processing

When Auditor verdict contains a `STEERING:` section, process **after** handling the verdict (GO/NO-GO/etc.) but **before** advancing to the next phase.

1. **Parse**: Each `STEERING:` line has format: `{CODIFY|PROPOSE}|{target file}|{decision text}`
2. **Route by level**:

| Level | Action | Blocks pipeline |
|-------|--------|----------------|
| `CODIFY` | Update `steering/{target file}` directly + append to `decisions.md` (STEERING_UPDATE) | No |
| `PROPOSE` | Present to user for approval | Yes (standalone: no pipeline, but still requires user approval before proceeding) |

3. **PROPOSE handling**:
   - On approval → update `steering/{target file}` + append to `decisions.md` (STEERING_UPDATE)
   - On rejection → append to `decisions.md` as STEERING_EXCEPTION (with Reason, Steering-ref), or USER_DECISION if simply rejected

## Inspector Error Handling

If an Inspector CPF file contains `VERDICT:ERROR` (Inspector could not execute): treat as "Inspector unavailable" — no findings from that Inspector. Proceed with remaining Inspectors' results. Note in Auditor context that Inspector {name} was unavailable.

**Exception**: If the ERROR CPF also contains C-level (Critical) findings, pass those findings AND the error context to the Auditor. Critical findings indicate the Inspector detected a fatal problem (e.g., missing spec files) before failing — these must not be silently discarded.

## Verdict Destination by Review Type

All verdict files follow the same pattern: `{scope-dir}/verdicts.md`

- **Single-spec review**: `{{SDD_DIR}}/project/specs/{feature}/reviews/verdicts.md`
- **Dead-code review** (standalone): `{{SDD_DIR}}/project/reviews/dead-code/verdicts.md` (Wave QG context uses `reviews/wave/verdicts.md` with header `[W{wave}-DC-B{seq}]`; see run.md Step 7b)
- **Cross-check review**: `{{SDD_DIR}}/project/reviews/cross-check/verdicts.md`
- **Wave-scoped review**: `{{SDD_DIR}}/project/reviews/wave/verdicts.md`
- **Cross-cutting review**: `{{SDD_DIR}}/project/specs/.cross-cutting/{id}/verdicts.md`
- **Self-review** (framework-internal): `{{SDD_DIR}}/project/reviews/self/verdicts.md`

## Next Steps by Verdict (standalone)

Standalone reviews report results only — no auto-fix. Auto-fix loops are executed within pipeline orchestration (run.md / revise.md).

- Design GO/CONDITIONAL → suggest `/sdd-roadmap impl {feature}`
- Impl GO/CONDITIONAL → feature complete
- NO-GO → report findings to user (auto-fix only within pipeline)
- SPEC-UPDATE-NEEDED → report to user (auto-fix only within pipeline)
