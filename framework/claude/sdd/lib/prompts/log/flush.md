# Flush — Bulk Persist Unpersisted Session Data

Scan the current conversation context for decisions, issues, and knowledge not yet persisted to `.sdd/session/` YAML files, then record each item.

## Flush Criteria

**Include:**
- Explicit user decisions or choices, or Lead's pipeline decisions
- Bugs, issues, or problems reported, discovered, or surfaced by SubAgents
- Structural insights or learnings (tagged `[KNOWLEDGE]`/`[ISSUE]` or untagged)
- Verdict findings that warrant tracking (significant review outcomes)

**Exclude:**
- Casual mentions, hypotheticals, rejected alternatives
- Items already recorded (check by summary similarity in Step 3)

## Step 1: Scan Context

Review the conversation for items matching flush criteria. Context sources:
- Conversation history (user messages, Lead responses)
- Builder reports (`[KNOWLEDGE]` / `[ISSUE]` tags)
- Auditor verdict findings

For each found item, determine the correct type using the Rerouting rules below.

## Step 2: Reroute (per item)

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

Apply rerouting silently — flush is bulk persistence with minimal friction.

## Step 3: Dedup Check

Read all three session files:
- `.sdd/session/decisions.yaml`
- `.sdd/session/issues.yaml`
- `.sdd/session/knowledge.yaml`

For each candidate item, check if a similar summary already exists. Skip duplicates.

## Step 4: Knowledge FP Suppression

Only write to knowledge.yaml when the item is **clearly and unambiguously** a reusable insight (e.g., "hatch-vcs caches metadata after tag", "Edit tool is safer than printf for appending").

When uncertain whether something is knowledge or an issue:
- **Prefer issue** — the sdd-handover consolidation has a knowledge promotion path (resolved issue's resolution → knowledge).
- Do NOT write "problem descriptions with workarounds" as knowledge. Write them as issues with the workaround in the detail field.

## Step 5: Record Each Item

For each non-duplicate item, execute the recording procedure below.

### 5a: Ensure Target File

Use Glob to check if the target file exists under `.sdd/session/`:
- `decisions.yaml` for decisions
- `issues.yaml` for issues
- `knowledge.yaml` for knowledge

If the file does not exist, Read the template from `.sdd/settings/templates/session/{filename}` and Write it to `.sdd/session/{filename}`.

If `.sdd/session/` directory does not exist, create it first.

### 5b: Determine Next ID

Read the target file. Scan all `id:` values to find the maximum sequence number.

- Decision IDs: `D{N}` — find highest N, use N+1
- Issue IDs: `I{N}` — find highest N, use N+1
- Knowledge IDs: `K{N}` — find highest N, use N+1
- If the file has no entries or `entries: []`, start at 1

### 5c: Get Timestamp

Run `date +%Y-%m-%dT%H:%M:%S%z` via Bash. Use the output verbatim. Do NOT use `-u` flag.

### 5d: Build Entry

#### Decision
```yaml
  - id: "D{N}"
    status: "active"
    severity: "{H|M|L}"  # default: M
    summary: "{one-line summary}"
    detail: "{背景・詳細・理由・影響を含む}"
    source: "{user|lead|auditor}"
    created_at: "{timestamp}"
```

#### Issue
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

#### Knowledge
```yaml
  - id: "K{N}"
    status: "active"
    severity: "{H|M|L}"  # default: M
    summary: "{one-line summary}"
    detail: "{詳細・影響・推奨を含む}"
    source: "{source}"
    created_at: "{timestamp}"
```

### 5e: Write Entry

Use the **Edit tool** to append the new entry at the end of the file.
NEVER use Bash echo/printf/cat for file writes.

Maintain proper YAML indentation (2-space indent for list items under `entries:`).

**Empty entries list** (`entries: []`): Replace `entries: []` with `entries:` followed by the new entry.

## Step 6: Report

Report a summary table of all items written:

```
Flushed:
| ID  | Type      | Summary                    |
|-----|-----------|----------------------------|
| D42 | decision  | ...                        |
| I25 | issue     | ...                        |
```

If no unpersisted items are found, report: "No unpersisted items found."
