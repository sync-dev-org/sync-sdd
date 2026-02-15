---
description: Multi-feature roadmap (create, run, update, delete)
allowed-tools: Bash, Glob, Grep, Read, Write, Edit, AskUserQuestion, SendMessage, WebSearch, WebFetch
argument-hint: [run [--gate]] | [-y] | [create [-y]] | [update] | [delete]
---

# SDD Roadmap (Unified)

<instructions>

## Core Task

Manage product-wide specification roadmap. Create/update/delete are handled by Conductor directly. Run dispatches to Coordinator for pipeline execution.

## Step 1: Detect Mode

```
$ARGUMENTS = "run"              → Execute roadmap (full-auto mode)
$ARGUMENTS = "run --gate"       → Execute roadmap (gate mode)
$ARGUMENTS = "create" or "create -y" → Create roadmap
$ARGUMENTS = "update"           → Sync roadmap with current spec states
$ARGUMENTS = "delete"           → Delete roadmap and all specs
$ARGUMENTS = "-y"               → Auto-detect: run if roadmap exists, create if not
$ARGUMENTS = ""                 → Auto-detect with user choice
```

## Step 2: Auto-Detect (if no explicit mode)

1. Check if `{{SDD_DIR}}/project/specs/roadmap.md` exists
2. If exists: Present options (Run / Update / Reset)
3. If not: Start creation flow

---

## Create Mode

Conductor handles directly (user-interactive):

1. Load steering, rules, templates, existing specs
2. Verify product understanding with user
3. Propose spec candidates from steering analysis
4. Organize into implementation waves (dependency-based)
5. Refine wave organization through dialogue (unless `-y`)
6. Create spec directories with skeleton design.md files
7. Generate roadmap.md with Wave Overview, Dependencies, Execution Flow
8. **Update product.md** User Intent → Spec Rationale section
9. Update `{{SDD_DIR}}/handover/conductor.md`

## Run Mode

Dispatch to Coordinator for pipeline execution:

```
roadmap 実行
Mode: {auto|gate}
Wave: {resume from or "all"}
```

### Full-Auto Mode (default)
- GO/CONDITIONAL → auto-advance to next phase
- NO-GO → auto-fix loop (max 3 retries), then escalate to user
- SPEC-UPDATE-NEEDED → auto-fix from spec level, then escalate
- Wave transitions → automatic

### Gate Mode (`--gate`)
- Pause at each Design Review completion → user approval
- Pause at each Impl Review completion → user approval
- Pause at Wave transitions → user approval

### Pipeline Execution
Each spec progresses independently through phases:
```
spec-a: [Architect] → [Review] → [Planner] → [Builder ×N] → [Impl Review]
spec-b:   [Architect] → [Review] → ...
spec-c:         (waiting on spec-a) → [Architect] → ...
```

Coordinator manages:
- Dependency tracking between specs
- File ownership analysis to prevent conflicts
- Parallel vs sequential spec scheduling
- Phase-by-phase teammate spawning (Opus for T3, Sonnet for T4)

Follow Coordinator's spawn requests mechanically.

## Update Mode

Conductor handles directly:
1. Load roadmap and scan all spec states
2. Detect structural differences (missing specs, wave mismatches, dependency changes)
3. Impact analysis (wave reordering, scope changes)
4. Present update options (Apply All / Selective / Abort)
5. Execute updates with preview

## Delete Mode

Conductor handles directly:
1. Require explicit "RESET" confirmation
2. Delete roadmap.md and all spec directories
3. Optionally reinitialize via Create mode

## Post-Completion

1. Update `{{SDD_DIR}}/handover/conductor.md`
2. Report results to user

</instructions>

## Error Handling

- **No roadmap for run/update**: "No roadmap found. Run `/sdd-roadmap create` first."
- **No steering for create**: Warn and suggest `/sdd-steering` first
- **Spec conflicts during run**: Coordinator handles file ownership resolution

think
