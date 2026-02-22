# Review Subcommand

Phase execution reference. Canonical source for ALL review types. Assumes Single-Spec Roadmap Ensure already completed by router (except dead-code/cross-check/wave which skip enrollment).

Triggered by: `$ARGUMENTS = "review design|impl|dead-code {feature} [options]"`

## Step 1: Parse Arguments

Parse review type (`design`/`impl`/`dead-code`), feature name, and options (`--consensus N`, `--cross-check`, `--wave N`).

If first argument after "review" is not one of `design`, `impl`, `dead-code`:
- Error: "Usage: `/sdd-roadmap review design|impl|dead-code {feature}`"

**1-Spec Roadmap guard**: If review type is `--cross-check` or `--wave N` AND `roadmap.md` contains exactly 1 spec: inform user "Single-spec roadmap — cross-check/wave review has no additional value over single-spec review." and abort.

## Step 2: Phase Gate

**Design Review**: Verify `design.md` exists. BLOCK if `spec.yaml.phase` is `blocked`.
**Implementation Review**: Verify `design.md` and `tasks.yaml` exist. Verify `phase` is `implementation-complete`. BLOCK if `blocked`.
**Dead Code Review**: No phase gate (operates on entire codebase).

## Design Review

Spawn via review execution flow (below):
- 6 design Inspectors (sonnet): `sdd-inspector-{rulebase,testability,architecture,consistency,best-practices,holistic}`
- Design Auditor (opus): `sdd-auditor-design`

**Cross-check / wave-scoped mode**: Same Inspector set + Auditor. Each Inspector's context includes cross-check scope (all specs or wave-scoped) instead of single feature.

## Impl Review

Spawn via review execution flow (below):
- Standard impl Inspectors (6, sonnet): `sdd-inspector-{impl-rulebase,interface,test,quality,impl-consistency,impl-holistic}`
- **Web projects** (steering/tech.md contains web stack indicators: React, Next.js, Vue, Angular, Svelte, Express, Django+templates, Rails, FastAPI+frontend, etc.): also spawn `sdd-inspector-e2e`
- Impl Auditor (opus): `sdd-auditor-impl`

**Cross-check / wave-scoped mode**: Same Inspector set + Auditor. Context includes:
- Wave scope: cumulative (Wave N re-inspects ALL code from Waves 1..N)
- Previously resolved issues: read `specs/verdicts-wave.md`, include as PREVIOUSLY_RESOLVED in Inspector context. Inspectors MUST NOT re-flag resolved items. Recurrence = REGRESSION (upgrade severity).

## Dead-Code Review

Spawn via review execution flow (below):
- 4 dead-code Inspectors (sonnet): `sdd-inspector-{dead-settings,dead-code,dead-specs,dead-tests}`
- Dead-code Auditor (opus): `sdd-auditor-dead-code`

## Review Execution Flow

1. Create review directory: `{{SDD_DIR}}/project/specs/{feature}/_review/` (or `_review-wave-{N}/` for wave QG, `_review-wave-{N}-dc/` for dead-code)
2. Spawn all Inspectors via `Task(subagent_type=...)`. Each context includes:
   - Review output path: `{_review-dir}/{inspector-name}.cpf`
   - Feature/scope context
3. Wait for all Inspector Tasks to complete. Handle failed Inspectors: retry, skip, or proceed with available results.
4. Spawn Auditor via `Task(subagent_type=...)`. Context includes:
   - Review directory path (Auditor reads all `.cpf` files)
   - Verdict output path: `{_review-dir}/verdict.cpf`
   - Steering Exceptions from `{{SDD_DIR}}/handover/session.md`
5. Read `{_review-dir}/verdict.cpf`
6. Persist verdict (see Router → Verdict Persistence Format)
7. Delete review directory

If `--consensus N`, apply Consensus Mode protocol (see Router).

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
| `PROPOSE` | Present to user for approval | Yes |

3. **PROPOSE handling**:
   - On approval → update `steering/{target file}` + append to `decisions.md` (STEERING_UPDATE)
   - On rejection → append to `decisions.md` as STEERING_EXCEPTION (with Reason, Steering-ref), or USER_DECISION if simply rejected

## Inspector Error Handling

If an Inspector CPF file contains `VERDICT:ERROR` (Inspector could not execute): treat as "Inspector unavailable" — no findings from that Inspector. Proceed with remaining Inspectors' results. Note in Auditor context that Inspector {name} was unavailable.

## Verdict Destination by Review Type

- **Single-spec review**: `{{SDD_DIR}}/project/specs/{feature}/verdicts.md`
- **Dead-code review**: `{{SDD_DIR}}/project/specs/verdicts-dead-code.md`
- **Cross-check review**: `{{SDD_DIR}}/project/specs/verdicts-cross-check.md`
- **Wave-scoped review**: `{{SDD_DIR}}/project/specs/verdicts-wave.md`

## Next Steps by Verdict

- Design GO/CONDITIONAL → `/sdd-roadmap impl {feature}`
- Impl GO/CONDITIONAL → Feature complete
- NO-GO → Auto-fix or manual fix
- SPEC-UPDATE-NEEDED → Auto-fix from spec level
