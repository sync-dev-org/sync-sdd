# Review Output Format (YAML)

Unified YAML schema for all review pipeline outputs. Replaces CPF format for inter-agent communication.

## File Naming

| Stage | Filename | Producer | Consumer |
|-------|----------|----------|----------|
| Inspector | `findings-inspector-{name}.yaml` | Inspector | Auditor |
| Auditor | `verdict-auditor.yaml` | Auditor | Lead |
| Lead Final | `verdict.yaml` | Lead | Persistence |
| Index | `verdicts.yaml` | Lead | Lead (session resume, status) |

`{name}` = template filename stem without category prefix (e.g., `inspector-impl-test.md` → `findings-inspector-impl-test.yaml`).

Dynamic Inspectors: `findings-inspector-dynamic-{N}-{slug}.yaml`

## 1. Inspector Findings (`findings-inspector-{name}.yaml`)

```yaml
scope: "{inspector-name}"       # e.g., "inspector-impl-test"
issues:
  - id: "F1"                    # Sequential within file: F1, F2, ...
    severity: "H"               # C/H/M/L
    category: "{category}"      # Inspector-specific (e.g., "test-coverage", "dead-export")
    location: "{file}:{line}"   # File path and line number (or descriptive location)
    description: "{what}"       # What is wrong
    impact: "{why}"             # Why it matters
    recommendation: "{how}"     # How to fix
notes: |                        # Optional — freeform observations
  Additional context here
```

### Optional Sections

Inspectors MAY include additional typed sections when relevant:

```yaml
compliance:                     # Compliance Inspector only
  - target: "{spec-item}"
    status: "OK"                # OK/NG/UNCERTAIN
    citation: "{evidence}"
xrefs:                          # Consistency Inspector only
  - source: "{file}"
    target: "{file}"
    status: "OK"                # OK/MISSING_PATH_PREFIX/MISSING_RELATIVE_TARGET/UNDEFINED_REFERENCE
```

### Rules

- `issues` is a list; empty list `[]` if no findings
- `id` is unique within the file, not globally
- `category` is not a global enum — each Inspector defines relevant categories
- `severity` uses standard codes: C (Critical), H (High), M (Medium), L (Low)

## 2. Auditor Verdict (`verdict-auditor.yaml`)

Auditor reads all `findings-inspector-*.yaml` from `active/`, synthesizes, and writes:

```yaml
verdict: "CONDITIONAL"          # GO/CONDITIONAL/NO-GO/SPEC-UPDATE-NEEDED
scope: "{feature-or-scope}"
review_type: "{type}"           # design/impl/dead-code/self
counts:
  C: 0
  H: 1
  M: 3
  L: 2
  FP: 4                         # False positives eliminated
files:                          # Affected files (union from all Inspectors)
  - "path/to/file1"
  - "path/to/file2"
issues:                         # Merged, deduplicated, severity-reassessed findings
  - id: "A1"                   # Auditor-assigned: A1, A2, ...
    source: "inspector-impl-test"  # Origin Inspector (or "inspector-x+inspector-y" if merged)
    severity: "H"
    category: "{category}"
    location: "{file}:{line}"
    description: "{what}"
    impact: "{why}"
    recommendation: "{how}"
fp_eliminated:                  # Optional — FP items with rationale
  - source_id: "F3"
    source: "inspector-impl-quality"
    reason: "{why this is FP}"
notes: |                        # Summary, deconflicting analysis
  Overall assessment text
spec_feedback: |                # Optional — only for SPEC-UPDATE-NEEDED
  What needs to change in the spec
steering:                       # Optional — CODIFY/PROPOSE entries
  - action: "CODIFY"           # CODIFY (Lead applies) or PROPOSE (user approval needed)
    file: "steering/tech.md"
    decision: "{what to add/change}"
```

### Rules

- `verdict` is required; determines pipeline flow
- `issues` contains only confirmed findings (FPs removed)
- `fp_eliminated` enables Lead to audit FP reasoning
- `steering` is optional; omit entirely if no steering feedback (e.g., self-review per D188 #13)

## 3. Lead Final Verdict (`verdict.yaml`)

Lead reads `verdict-auditor.yaml`, applies oversight, and writes `verdict.yaml`:

```yaml
verdict: "CONDITIONAL"
scope: "{feature-or-scope}"
review_type: "{type}"
counts:
  C: 0
  H: 0                         # Updated after Lead overrides
  M: 3
  L: 2
  FP: 5                        # Updated (Auditor FP + Lead FP)
files:
  - "path/to/file1"
issues:                         # Final confirmed issues (after Lead review)
  - id: "A1"
    source: "inspector-impl-test"
    severity: "M"              # May be reclassified by Lead
    category: "{category}"
    location: "{file}:{line}"
    description: "{what}"
    impact: "{why}"
    recommendation: "{how}"
    classification: "A"        # A (auto-fix) / B (decision-required)
    user_decision: "approved"  # approved/rejected/deferred (set after user response)
    resolution: "fixed"        # fixed/deferred/rejected (set after Builder completes)
    resolution_note: "..."     # Optional — what was done or why deferred
lead_overrides:                 # Optional — what Lead changed from Auditor draft
  - id: "A2"
    action: "eliminate"         # reclassify/eliminate/accept
    rationale: "{why}"
  - id: "A1"
    action: "reclassify"
    original_severity: "H"
    new_severity: "M"
    rationale: "{why}"
disposition: "CONDITIONAL-TRACKED"  # See Disposition Codes below
notes: |
  Lead's final assessment
spec_feedback: |                # Carried from Auditor if applicable
  ...
steering:                       # Carried from Auditor, processed by Lead
  - action: "CODIFY"
    file: "steering/tech.md"
    decision: "{what}"
tracked:                        # Optional — for CONDITIONAL disposition
  - id: "A1"
    severity: "M"
    description: "{summary}"
resolved:                       # Optional — items resolved from previous batch
  - id: "A3"
    from_batch: 2               # B{seq} where it was tracked
    resolution: "{how resolved}"
```

### Disposition Codes

| Code | Meaning |
|------|---------|
| `GO-ACCEPTED` | No actionable issues |
| `CONDITIONAL-TRACKED` | M/L issues tracked for follow-up |
| `NO-GO-FIXED` | Issues fixed by Builder |
| `SPEC-UPDATE-CASCADED` | Spec updated, cascade triggered |
| `ESCALATED` | Escalated to user |

### Per-Item Lifecycle

```
Lead classifies (A/B) → User approves/rejects/defers → Builder fixes approved items
```

| Field | Set by | When |
|-------|--------|------|
| `classification` | Lead | After Lead supervision (A/B) |
| `user_decision` | Lead (from user input) | After user presentation |
| `resolution` | Lead (from Builder result) | After Builder completes |

- `classification`: `A` = auto-fixable (clear fix, no judgment needed), `B` = decision-required (design-level, wide impact, multiple options)
- `user_decision`: `approved` (fix it), `rejected` (not a real issue), `deferred` (track for later)
- `resolution`: `fixed` (Builder successfully fixed), `deferred` (tracked for future batch), `rejected` (user rejected)
- Items with `user_decision: rejected` are moved to `fp_eliminated` (user-confirmed FP)
- Items with `user_decision: deferred` are added to `tracked`
- Only `user_decision: approved` items are sent to Builder

### Lead Override Rules

- Lead MAY reclassify severity (with rationale)
- Lead MAY eliminate additional FPs (with rationale)
- Lead MUST NOT add new issues not found by Inspectors
- Lead MUST NOT upgrade severity (only downgrade or eliminate)
- All overrides recorded in `lead_overrides` for audit trail

## 4. Verdict Index (`verdicts.yaml`)

Replaces `verdicts.md`. One per review scope directory.

### Locations

| Scope | Path |
|-------|------|
| Per-feature | `{{SDD_DIR}}/project/specs/{feature}/reviews/verdicts.yaml` |
| Wave cross-check | `{{SDD_DIR}}/project/reviews/wave-{N}/verdicts.yaml` |
| Cross-cutting | `{{SDD_DIR}}/project/specs/.cross-cutting/{id}/verdicts.yaml` |
| Self-review | `{{SDD_DIR}}/project/reviews/self/verdicts.yaml` |

### Schema

```yaml
batches:
  - seq: 1                     # Batch number (monotonic)
    type: "impl"               # design/impl/dead-code/self/cross-check/cross-cutting
    scope: "{feature}"         # Feature name or scope identifier
    date: "2026-03-07T10:30:45+0900"  # ISO-8601, local timezone
    version: "2.5.0"           # From .sdd/.version
    engines:
      briefer: "gpt-5.3-codex-spark"
      inspectors: "gpt-5.3-codex"
      auditor: "claude-sonnet-4-6"
      builder: "claude-sonnet-4-6"  # Optional — omit if no Builder fixes
    agents:
      fixed: 5
      conditional: 0           # Optional, default 0
      dynamic: 2               # Optional, default 0
      total: 7
    counts:
      C: 0
      H: 1
      M: 3
      L: 2
      FP: 4
    verdict: "CONDITIONAL"
    disposition: "CONDITIONAL-TRACKED"
    tracked:                    # Optional — carried from verdict.yaml
      - id: "A1"
        severity: "M"
        description: "{summary}"
    resolved:                   # Optional — carried from verdict.yaml
      - id: "A3"
        from_batch: 1
  - seq: 2
    # ... next batch
```

### Wave-Specific Fields

For wave cross-check and dead-code batches, add `wave` field:

```yaml
  - seq: 1
    type: "cross-check"        # or "dead-code"
    scope: "wave-2"
    wave: 2                    # Wave number
    # ... rest of fields
```

### Rules

- `batches` is an ordered list, newest last
- `seq` is monotonically increasing per file
- Lead appends new batch entry after persisting `verdict.yaml`
- `tracked` and `resolved` are only present when applicable
- `engines` reflects actual engines used (may differ from engines.yaml defaults if overridden)

## Migration Notes

### CPF → YAML

| Before | After |
|--------|-------|
| `*.cpf` | `findings-inspector-{name}.yaml` |
| `verdict.cpf` | `verdict-auditor.yaml` → `verdict.yaml` |
| `report.md` + `verdict-data.md` (self-review) | `verdict-auditor.yaml` → `verdict.yaml` |
| `verdicts.md` | `verdicts.yaml` |

### Data Flow

```
Inspector → findings-inspector-{name}.yaml (in active/)
         ↓
Auditor reads all findings-inspector-*.yaml
         ↓
Auditor → verdict-auditor.yaml (in active/)
         ↓
Lead reads verdict-auditor.yaml, applies oversight (FP + A/B classification)
         ↓
Lead → verdict.yaml (in active/) [classification set, user_decision/resolution pending]
         ↓
Lead presents to user (A items + B items)
         ↓
User approves/rejects/defers each item
         ↓
Lead updates verdict.yaml [user_decision set]
         ↓
Lead dispatches Builder with approved items
         ↓
Builder fixes → Lead verifies → Lead updates verdict.yaml [resolution set]
         ↓
Lead appends to verdicts.yaml
         ↓
Lead renames active/ → B{seq}/
```
