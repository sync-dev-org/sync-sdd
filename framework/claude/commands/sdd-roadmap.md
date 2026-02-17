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
7. Set `spec.json.roadmap` for each spec: `{"wave": N, "dependencies": ["spec-name", ...]}`
8. Generate roadmap.md with Wave Overview, Dependencies, Execution Flow
9. **Update product.md** User Intent → Spec Rationale section
10. Update `{{SDD_DIR}}/handover/conductor.md`

## Run Mode

Dispatch to Coordinator for pipeline execution:

```
roadmap 実行
Mode: {auto|gate}
Wave: {resume from or "all"}
```

### Full-Auto Mode (default)
- GO/CONDITIONAL → auto-advance to next phase
- NO-GO → auto-fix loop (max 3 retries, including structural changes), then escalate to user
- SPEC-UPDATE-NEEDED → auto-fix from spec level (including structural changes), then escalate
- Wave transitions → automatic

### Gate Mode (`--gate`)
- Pause at each Design Review completion → user approval
- Pause at each Impl Review completion → user approval
- Pause at Wave transitions → user approval
- Structural changes (spec splitting, wave restructuring) → escalate to user

### Pipeline Execution
Each spec progresses through mandatory phases:
```
spec-a: [Architect] → [Design Review] → [Planner] → [Builder ×N] → [Impl Review]
spec-b:   [Architect] → [Design Review] → ...
spec-c:         (waiting on spec-a) → [Architect] → ...
```

Design Review and Impl Review are **mandatory** in roadmap run.

### Wave Quality Gate
After all specs in a wave complete individual pipelines:
1. **Impl Cross-Check** (`--wave N`): Cross-feature consistency review across Wave 1..N
   - GO/CONDITIONAL → proceed to dead-code review
   - NO-GO → auto-fix: responsible Builder(s) fix → re-review (max 3 retries → escalate)
   - SPEC-UPDATE-NEEDED → cascade fix from spec level
2. **Dead Code Review**: Full codebase dead-code review
   - GO → Wave complete, proceed to next wave
   - CONDITIONAL/NO-GO → responsible Builder(s) fix → re-review dead-code (max 3 retries → escalate)

Coordinator manages:
- Dependency tracking between specs
- Cross-spec file ownership analysis to prevent conflicts
- Parallel vs sequential spec scheduling
- Phase-by-phase teammate spawning (Opus for T3, Sonnet for T4)
- Failure propagation: when a spec fails, block all downstream dependents
- Wave Quality Gate execution and auto-fix routing

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
- **Spec failure (retries exhausted)**: Block dependent specs, report cascading impact, present options (fix / skip / abort)

think
