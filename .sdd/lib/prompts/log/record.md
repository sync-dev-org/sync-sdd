# Record Entry — Single Item Recording Procedure

Record a single decision, issue, or knowledge entry to `.sdd/session/` YAML files.

## Step 1: Parse

Extract from the caller's context:
- **type**: `decision`, `issue`, or `knowledge`
- **content**: summary, detail, severity, source, and (for issues) subtype

If type is not specified, infer from content using the Rerouting rules below.
If content is absent or too vague to form a summary, ask the user.

## Step 2: Reroute

Verify the type matches the content. Apply these rules:

| Content pattern | Correct type | Issue subtype |
|----------------|-------------|---------------|
| Problem / bug / error / failure | `issue` | BUG |
| Feature or capability request | `issue` | FEATURE |
| Improvement or enhancement suggestion | `issue` | ENHANCEMENT |
| Explicit choice or selection between alternatives | `decision` | — |
| Reusable learning, pattern, insight, or workaround | `knowledge` | — |

**Issue subtype defaults:**
- "問題", "バグ", "bug", "error", "failure" → BUG
- "改善", "enhancement", "improvement" → ENHANCEMENT
- "機能", "feature", "capability" → FEATURE

**On mismatch (explicit user invocation only):**
1. Suggest the correct type: "This looks more like an issue (BUG). Record as issue instead?"
2. If user confirms or does not object, use the suggested type.
3. If user insists on the original type, respect their choice.

When called from flush or internal flows, apply rerouting silently without confirmation.

## Step 3: Ensure Target File

Use Glob to check if the target file exists under `.sdd/session/`:
- `decisions.yaml` for decisions
- `issues.yaml` for issues
- `knowledge.yaml` for knowledge

If the file does not exist, Read the template from `.sdd/settings/templates/session/{filename}` and Write it to `.sdd/session/{filename}`.

If `.sdd/session/` directory does not exist, create it first.

## Step 4: Determine Next ID

Read the target file. Scan all `id:` values to find the maximum sequence number.

- Decision IDs: `D{N}` — find highest N, use N+1
- Issue IDs: `I{N}` — find highest N, use N+1
- Knowledge IDs: `K{N}` — find highest N, use N+1
- If the file has no entries or `entries: []`, start at 1

## Step 5: Get Timestamp

Run `date +%Y-%m-%dT%H:%M:%S%z` via Bash. Use the output verbatim. Do NOT use `-u` flag.

## Step 6: Build Entry

### Decision
```yaml
  - id: "D{N}"
    status: "active"
    severity: "{H|M|L}"  # default: M
    summary: "{one-line summary}"
    detail: "{背景・詳細・理由・影響を含む}"
    source: "{user|lead|auditor}"
    created_at: "{timestamp}"
```

### Issue
```yaml
  - id: "I{N}"
    type: "{BUG|FEATURE|ENHANCEMENT}"
    status: "open"
    severity: "{H|M|L}"  # default: H
    summary: "{one-line summary}"
    detail: "{詳細}"
    source: "{source}"
    created_at: "{timestamp}"
```

### Knowledge
```yaml
  - id: "K{N}"
    status: "active"
    severity: "{H|M|L}"  # default: M
    summary: "{one-line summary}"
    detail: "{詳細・影響・推奨を含む}"
    source: "{source}"
    created_at: "{timestamp}"
```

## Step 7: Write Entry

Use the **Edit tool** to append the new entry at the end of the file.
NEVER use Bash echo/printf/cat for file writes.

The entry must be appended after the last line of the file, maintaining proper YAML indentation (2-space indent for list items under `entries:`).

**Empty entries list** (`entries: []`): Replace `entries: []` with `entries:` followed by the new entry.

## Step 8: Confirm

Report:
- ID assigned
- Summary
- File path

**Multiple items**: Process each separately, assigning sequential IDs. Report all in a single summary.
