# Roadmap Management (Create / Update / Delete)

Interactive operations reference. Lead handles directly.

---

## Create Mode

1. Load steering, rules, templates, existing specs
2. Verify product understanding with user
3. Propose spec candidates from steering analysis
4. Organize into implementation waves — **Parallel-Optimized Wave Scheduling**:
   a. Build dependency graph from spec candidates
   b. **Foundation-First**: Identify foundation specs and place in Wave 1:
      - Model / Schema definitions
      - Error handling infrastructure
      - Shared libraries (helpers, logger, etc. — referenced by multiple specs)
      - Other specs likely referenced by later waves
      - Heuristics: name/description keywords (`model`, `schema`, `shared`, `common`, `core`, `base`, `error`, `logging`, `config`), high dependee count (≥ 2), steering/product.md designation
   c. Topological sort remaining specs → assign wave = dependency level (foundation deps go to Wave 2+)
   d. Maximize parallelism: specs at the same dependency level share a wave
   e. **Parallelism report** — output per-wave summary:
      ```
      Wave 1 (foundation): 3 specs [models, errors, shared-utils] — all parallel
      Wave 2: 2 specs [api, ui] — api serial (depends on models), ui parallel
      Wave 3: 1 spec [integration] — serial (depends on api, ui)
      Critical path: 3 waves
      ```
5. Refine wave organization through dialogue (unless `-y`)
6. Create spec directories with skeleton design.md files
7. Set `spec.yaml.roadmap` for each spec: `{wave: N, dependencies: ["spec-name", ...]}`
8. Generate roadmap.md with Wave Overview, Dependencies, Execution Flow, Parallelism Report
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
4. **Backfill optimization**: When adding new specs or reordering waves, check if specs can be consolidated into fewer waves while respecting dependency constraints. Present parallelism report (same format as Create Mode Step 4e).
5. Auto-draft `{{SDD_DIR}}/handover/session.md`
6. Record changes to `decisions.md` as `DIRECTION_CHANGE`

---

## Delete Mode

1. Require explicit "RESET" confirmation. If not confirmed: abort, no changes.
2. Delete roadmap.md, all spec directories (including `specs/.cross-cutting/`), and project-level reviews directory (`{{SDD_DIR}}/project/reviews/`)
3. Optionally reinitialize via Create mode
