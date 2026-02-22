# Roadmap Management (Create / Update / Delete)

Interactive operations reference. Lead handles directly.

---

## Create Mode

1. Load steering, rules, templates, existing specs
2. Verify product understanding with user
3. Propose spec candidates from steering analysis
4. Organize into implementation waves (dependency-based)
5. Refine wave organization through dialogue (unless `-y`)
6. Create spec directories with skeleton design.md files
7. Set `spec.yaml.roadmap` for each spec: `{wave: N, dependencies: ["spec-name", ...]}`
8. Generate roadmap.md with Wave Overview, Dependencies, Execution Flow
9. **Update product.md** User Intent → Spec Rationale section
10. Auto-draft `{{SDD_DIR}}/handover/session.md`

---

## Update Mode

### Step 1: Load and Compare
1. Read `roadmap.md` and scan all `spec.yaml` files
2. Build current state map: `{spec: {phase, wave, dependencies, version}}`
3. Compare against roadmap.md declared state

### Step 2: Detect Differences

| Category | Detection |
|----------|-----------|
| **Missing spec** | spec.yaml exists but not in roadmap.md |
| **Orphaned entry** | roadmap.md lists spec but no spec.yaml |
| **Wave mismatch** | spec.yaml.roadmap.wave differs from roadmap.md |
| **Dependency change** | spec.yaml.roadmap.dependencies differ |
| **Phase regression** | spec phase earlier than expected for completed wave |
| **Blocked cascade** | spec is blocked but roadmap shows active |

### Step 3: Impact Analysis
For each difference:
1. Trace dependency graph forward (downstream impact)
2. Check wave ordering integrity (would change violate wave boundaries?)
3. Classify impact: `SAFE` / `WAVE_REORDER` / `SCOPE_CHANGE`

### Step 4: Present Options
- **Apply All**: Apply all safe changes, present risky changes individually
- **Selective**: User picks which changes to apply
- **Abort**: No changes

### Step 5: Execute
1. Update roadmap.md to reflect accepted changes
2. Update affected spec.yaml roadmap fields
3. If wave reordering: re-validate dependency graph (no cycles)
4. Auto-draft `{{SDD_DIR}}/handover/session.md`
5. Record changes to `decisions.md` as `DIRECTION_CHANGE`

---

## Delete Mode

1. Require explicit "RESET" confirmation
2. Delete roadmap.md, all spec directories, and project-level verdict files (`verdicts-wave.md`, `verdicts-dead-code.md`, `verdicts-cross-check.md`)
3. Optionally reinitialize via Create mode
