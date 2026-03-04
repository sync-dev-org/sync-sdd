---
description: Unified spec lifecycle (design, implement, review, roadmap management)
allowed-tools: Agent, Bash, Glob, Grep, Read, Write, Edit
argument-hint: design <feature> | impl <feature> [tasks] | review design|impl <feature> [flags] | review dead-code | run [--gate] | revise [feature] [instructions] | create [-y] | update | delete | -y
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
$ARGUMENTS = "review impl {feature}"                → Review Subcommand
$ARGUMENTS = "review dead-code"                      → Review Subcommand
$ARGUMENTS = "review design --cross-check"          → Review Subcommand
$ARGUMENTS = "review impl --cross-check"            → Review Subcommand
$ARGUMENTS = "review design --wave N"               → Review Subcommand
$ARGUMENTS = "review impl --wave N"                 → Review Subcommand

# Management subcommands
$ARGUMENTS = "run"              → Run Mode
$ARGUMENTS = "run --gate"       → Run Mode
$ARGUMENTS = "revise {feature} [instructions]" → Revise Mode (Single-Spec) — first word matches a spec name in specs/
$ARGUMENTS = "revise [instructions]"             → Revise Mode (Cross-Cutting) — first word does not match any spec name
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
   - If spec not found AND subcommand is `design` → **auto-add to roadmap (with Backfill)**:
     1. Create spec directory, initialize spec.yaml from template
     2. **Backfill check**: Analyze if new spec can join an existing wave:
        a. New spec has `dependencies: []` (no dependencies yet at design time)
        b. Find highest incomplete wave where adding a dependency-free spec causes no conflict
        c. If backfill possible: present option — "Add to Wave {N} (with {M} existing specs)" or "New Wave {max+1}"
        d. If `-y` flag or no backfill possible: default to `max(existing waves) + 1`
     3. Set `spec.yaml.roadmap = {wave: chosen_wave, dependencies: []}`
     4. Update `roadmap.md` Wave Overview with new spec entry
     5. Inform user: "Added {feature} to roadmap (Wave {N})."
     6. Proceed to subcommand execution
   - If spec not found AND subcommand is `impl`/`review` → BLOCK: "Spec '{feature}' not found. Use `/sdd-roadmap design \"description\"` to create."
   - If spec exists but `spec.yaml.roadmap` is null → BLOCK: "{feature} exists but is not enrolled in the roadmap. Use `/sdd-roadmap update` to sync."
   - Exception: `review dead-code`, `review design|impl --cross-check`, and `review design|impl --wave N` operate on the whole codebase/wave, not a single spec → skip enrollment check
3. **If no roadmap**:
   - If subcommand is `review dead-code`, `review design|impl --cross-check`, or `review design|impl --wave N` → BLOCK: "No roadmap found. Run `/sdd-roadmap create` first."
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
- **Review** (design, impl, dead-code, --cross-check, --wave) → Read `refs/review.md`
- **Run** → Read `refs/run.md`
- **Revise** → Read `refs/revise.md`
- **Create / Update / Delete** → Read `refs/crud.md`

Then follow the instructions in the loaded file.

---

## Shared Protocols

### Verdict Persistence Format

a. Read existing file (or create with `# Verdicts: {feature}` header)
b. Determine B{seq} (increment max existing, or start at 1)
c. Append batch entry header:
   - Per-feature/standalone: `## [B{seq}] {review-type} | {ISO-8601} | v{version}`
   - Wave QG cross-check: `## [W{wave}-B{seq}] ...` (see run.md Step 7a)
   - Wave QG dead-code: `## [W{wave}-DC-B{seq}] ...` (see run.md Step 7b)
   - Cross-cutting revision: persists to `specs/.cross-cutting/{id}/verdicts.md` (see revise.md Part B Step 8)
d. Append Raw section (Auditor CPF verdict verbatim)
e. Append Disposition (`GO-ACCEPTED`, `CONDITIONAL-TRACKED`, `NO-GO-FIXED`, `SPEC-UPDATE-CASCADED`, `ESCALATED`)
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
