---
description: Unified spec lifecycle (design, implement, review, roadmap management)
allowed-tools: Task, Bash, Glob, Grep, Read, Write, Edit, AskUserQuestion
argument-hint: design <feature> | impl <feature> [tasks] | review design|impl|dead-code <feature> [flags] | run [--gate] [--consensus N] | revise <feature> [instructions] | create [-y] | update | delete | -y
---

# SDD Roadmap (Unified Entry Point)

<instructions>

## Core Task

Unified entry point for all spec lifecycle operations. Roadmap is always required — even single-feature work auto-creates a 1-spec roadmap. Lifecycle subcommands (design, impl, review) ensure a roadmap exists before executing. Management subcommands (create, run, revise, update, delete) handle multi-feature orchestration.

## Step 1: Detect Mode

```
# Lifecycle subcommands (auto-create roadmap if needed)
$ARGUMENTS = "design {feature-or-description}"     → Design Subcommand
$ARGUMENTS = "impl {feature} [task-numbers]"        → Impl Subcommand
$ARGUMENTS = "review design {feature}"              → Review Subcommand
$ARGUMENTS = "review impl {feature} [tasks]"        → Review Subcommand
$ARGUMENTS = "review dead-code [subtype]"           → Review Subcommand
$ARGUMENTS = "review {type} {feature} --consensus N" → Review Subcommand
$ARGUMENTS = "review design --cross-check"          → Review Subcommand
$ARGUMENTS = "review impl --cross-check"            → Review Subcommand
$ARGUMENTS = "review design --wave N"               → Review Subcommand
$ARGUMENTS = "review impl --wave N"                 → Review Subcommand

# Management subcommands
$ARGUMENTS = "run"              → Run Mode
$ARGUMENTS = "run --gate"       → Run Mode
$ARGUMENTS = "run --consensus N" → Run Mode
$ARGUMENTS = "revise {feature} [instructions]" → Revise Mode
$ARGUMENTS = "create" or "create -y" → Create Mode
$ARGUMENTS = "update"           → Update Mode
$ARGUMENTS = "delete"           → Delete Mode
$ARGUMENTS = "-y"               → Auto-detect: run if roadmap exists, create if not
$ARGUMENTS = ""                 → Auto-detect with user choice
```

## Step 2: Auto-Detect (if no explicit mode)

1. Check if `{{SDD_DIR}}/project/specs/roadmap.md` exists
2. If exists: Present options (Run / Update / Reset)
3. If not: Start creation flow

---

## Single-Spec Roadmap Ensure

When a lifecycle subcommand (design, impl, review) is detected:

1. Check if `{{SDD_DIR}}/project/specs/roadmap.md` exists
2. **If roadmap exists**: Verify the target spec is enrolled
   - Read `{{SDD_DIR}}/project/specs/{feature}/spec.yaml`
   - If `spec.yaml.roadmap` is non-null → proceed to subcommand execution
   - If spec not found AND subcommand is `design` → **auto-add to roadmap**:
     1. Create spec directory, initialize spec.yaml from template
     2. Determine next wave number: max(existing waves) + 1
     3. Set `spec.yaml.roadmap = {wave: N+1, dependencies: []}`
     4. Update `roadmap.md` Wave Overview with new spec entry
     5. Inform user: "Added {feature} to roadmap (Wave {N+1})."
     6. Proceed to subcommand execution
   - If spec not found AND subcommand is `impl`/`review` → BLOCK: "Spec '{feature}' not found. Use `/sdd-roadmap design \"description\"` to create."
   - If spec exists but `spec.yaml.roadmap` is null → BLOCK: "{feature} exists but is not enrolled in the roadmap. Use `/sdd-roadmap update` to sync."
   - Exception: `review dead-code` and `review --cross-check` / `review --wave N` operate on the whole codebase/wave, not a single spec → skip enrollment check
3. **If no roadmap**:
   - If subcommand is `review dead-code`, `review --cross-check`, or `review --wave N` → BLOCK: "No roadmap found. Run `/sdd-roadmap create` first."
   - Otherwise, auto-create a 1-spec roadmap:
     a. For `design` with a new description: generate feature name (kebab-case), create spec directory, initialize spec.yaml from `{{SDD_DIR}}/settings/templates/specs/init.yaml`
     b. For `design` with existing spec name: verify spec directory exists (create if not)
     c. For `impl`/`review {feature}`: verify spec exists → BLOCK if not: "Spec '{feature}' not found. Use `/sdd-roadmap design \"description\"` to create."
     d. Create `roadmap.md` with single-wave structure containing the target spec
     e. Set `spec.yaml.roadmap = {wave: 1, dependencies: []}`
     f. Inform user: "Created single-spec roadmap for {feature}."
4. Proceed to the appropriate subcommand section

### 1-Spec Roadmap Optimizations

When `roadmap.md` contains exactly 1 spec:
- **Skip Wave Quality Gate**: Cross-check review is meaningless with 1 spec
- **Skip Cross-Spec File Ownership Analysis**: No overlap possible
- **Skip wave-level dead-code review**: User can still run `/sdd-roadmap review dead-code` manually
- **Commit message format**: `{feature}: {summary}` (not `Wave 1: {summary}`)

---

## Execution Reference

After mode detection and roadmap ensure, Read the reference file for the detected mode:

- **Design** → Read `refs/design.md`
- **Impl** → Read `refs/impl.md`
- **Review** → Read `refs/review.md`
- **Run** → Read `refs/run.md`
- **Revise** → Read `refs/revise.md`
- **Create / Update / Delete** → Read `refs/crud.md`

Then follow the instructions in the loaded file.

---

## Shared Protocols

### Consensus Mode (`--consensus N`)

When `--consensus N` is provided (default threshold: ⌈N×0.6⌉):

1. For each pipeline `p` (1..N): create review directory `specs/{feature}/_review-{p}/`
2. Spawn N sets of Inspectors in parallel. Each Inspector set writes to its own `_review-{p}/` directory
3. For each pipeline: after all Inspector Tasks complete, spawn Auditor with `_review-{p}/` as input and `_review-{p}/verdict.cpf` as output
4. Read all N `verdict.cpf` files. Aggregate VERIFIED sections:
   - Key by `{category}|{location}`, count frequency
   - Confirmed (freq ≥ threshold) → Consensus. Noise (freq < threshold)
5. Consensus verdict: no findings above threshold → GO; any C/H findings ≥ threshold → NO-GO; only M/L findings ≥ threshold → CONDITIONAL
6. Delete all `_review-{p}/` directories
7. Proceed to verdict handling with consensus verdict

N=1 (default): use `specs/{feature}/_review/` (no `-{p}` suffix).

### Verdict Persistence Format

a. Read existing file (or create with `# Verdicts: {feature}` header)
b. Determine B{seq} (increment max existing, or start at 1)
c. Append batch entry: `## [B{seq}] {review-type} | {timestamp} | v{version} | runs:{N} | threshold:{K}/{N}`
d. Append Raw section (Auditor CPF verdicts verbatim)
e. Append Consensus section (findings with freq ≥ threshold) and Noise section
f. Append Disposition (`GO-ACCEPTED`, `CONDITIONAL-TRACKED`, `NO-GO-FIXED`, `SPEC-UPDATE-CASCADED`, `ESCALATED`)
g. For CONDITIONAL: extract M/L issues → append as Tracked section
h. If previous batch exists with Tracked: compare → append `Resolved since B{prev}`

---

## Post-Completion

1. Auto-draft `{{SDD_DIR}}/handover/session.md`
2. Report results to user

</instructions>

## Error Handling

- **No roadmap for run/update/revise**: "No roadmap found. Run `/sdd-roadmap create` first."
- **No steering for create**: Warn and suggest `/sdd-steering` first
- **Spec not in roadmap**: "{feature} is not part of the active roadmap. Use `/sdd-roadmap update` to add it."
- **Spec not found (impl/review)**: "Spec '{feature}' not found. Use `/sdd-roadmap design \"description\"` to create."
- **Missing design.md (impl)**: "Run `/sdd-roadmap design {feature}` first."
- **Wrong phase (impl)**: "Phase is '{phase}'. Run `/sdd-roadmap design {feature}` first."
- **Wrong phase for impl review**: "Phase is '{phase}'. Run `/sdd-roadmap impl {feature}` first."
- **Blocked**: "{feature} is blocked by {blocked_info.blocked_by}."
- **Spec conflicts during run**: Lead handles file ownership resolution (serialize preferred, partition allowed)
- **Spec failure (retries exhausted)**: Block dependent specs via Blocking Protocol, report cascading impact, present options (fix / skip / abort)
- **Artifact verification failure**: Do not update spec.yaml — escalate to user
