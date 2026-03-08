---
name: sdd-log
description: "Record decisions, issues, and knowledge to session YAML files (.sdd/session/). Use this skill whenever the user wants to log, record, track, or remember something. Triggers: /sdd-log, issue, 問題, バグ, bug, 機能, feature, 改善, enhancement, 判断, 決定, decision, 覚えて, remember, knowledge, record, log, track, 登録, 記録. Subcommands: decision, issue, knowledge, resolve, update, flush. Make sure to use this skill for ANY request to record project decisions, report bugs or issues, track feature requests, store knowledge or learnings, resolve issues, or flush unpersisted session data to YAML files."
allowed-tools: Bash Read Edit Write Glob
argument-hint: "decision|issue|knowledge|resolve|update|flush <args>"
---

<instructions>
You are the sdd-log skill. You record session data (decisions, issues, knowledge) to YAML files under `.sdd/session/`.

## Subcommands

| Subcommand | Target File | Purpose |
|------------|-------------|---------|
| `decision` | decisions.yaml | Record an explicit choice or direction |
| `issue` | issues.yaml | Record a bug, feature request, or enhancement |
| `knowledge` | knowledge.yaml | Record a reusable insight or learning |
| `resolve <ID>` | issues.yaml | Mark an issue as resolved |
| `update <ID> <field=value>` | Auto-detect by prefix | Update any entry field |
| `flush` | All three files | Persist unpersisted items from conversation |

## Step 1: Parse Arguments

Extract the subcommand and content from the user's message.

- If a subcommand is explicitly given (e.g., `/sdd-log issue ...`), use it as the initial type.
- If no subcommand is given, infer from content using the rerouting logic in Step 2.
- If content is absent or too vague to form a summary, ask the user for summary and detail.

## Step 2: Internal Rerouting

Before recording, verify the subcommand matches the content. This applies to ALL subcommands, not just flush.

**Rerouting rules:**
- Contains a problem / bug / error / failure description → `issue` (type: BUG)
- Contains a feature or capability request → `issue` (type: FEATURE)
- Contains an improvement or enhancement suggestion → `issue` (type: ENHANCEMENT)
- Contains an explicit choice or selection between alternatives → `decision`
- Contains a reusable learning, pattern, insight, or workaround → `knowledge`

**Type defaults for issue:**
- "問題", "バグ", "bug", "error", "failure" → BUG
- "改善", "enhancement", "improvement" → ENHANCEMENT
- "機能", "feature", "capability" → FEATURE

**When a mismatch is detected (explicit subcommand invocation only):**
1. Suggest the correct type: "This looks more like an issue (BUG). Record as issue instead?"
2. If user confirms or does not object, use the suggested type.
3. If user insists on the original type, respect their choice.

In `flush` mode, apply rerouting silently without confirmation — the goal is
bulk persistence with minimal friction.

## Step 3: Ensure Target File Exists

Use Glob to check if the target file exists under `.sdd/session/`.

- `decisions.yaml` for decisions
- `issues.yaml` for issues
- `knowledge.yaml` for knowledge

If the file does not exist, Read the template from `.sdd/settings/templates/session/{filename}` and Write it to `.sdd/session/{filename}`.

## Step 4: Determine Next ID

Read the target file. Scan all `id:` values to find the maximum sequence number.

- Decision IDs: `D{N}` — scan for highest N, use N+1
- Issue IDs: `I{N}` — scan for highest N, use N+1
- Knowledge IDs: `K{N}` — scan for highest N, use N+1
- If the file has no entries or `entries: []`, start at 1

## Step 5: Get Timestamp

Run `date +%Y-%m-%dT%H:%M:%S%z` via Bash. Use the output verbatim. Do NOT use `-u` flag.

## Step 6: Build Entry

### Decision Entry
```yaml
  - id: "D{N}"
    status: "active"
    severity: "{H|M|L}"  # default: M
    summary: "{one-line summary}"
    detail: "{背景・詳細・理由・影響を含む}"
    source: "{user|lead|auditor}"
    created_at: "{timestamp}"
```

### Issue Entry
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

### Knowledge Entry
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

Use the **Edit tool** to append the new entry at the end of the file. NEVER use Bash echo/printf/cat for file writes.

The entry must be appended after the last line of the file, maintaining proper YAML indentation (2-space indent for list items under `entries:`).

## Step 8: Confirm

Report to the user:
- ID assigned
- Summary
- File path (absolute)

For flush mode, report a summary table of all items written.

---

## Subcommand: `resolve <ID>`

1. Validate the ID starts with `I`. If not, report error: "Only issues (I-prefix) can be resolved."
2. Read `issues.yaml`, find the entry with matching ID.
3. If not found, report error: "Issue {ID} not found."
4. If already resolved, report: "Issue {ID} is already resolved."
5. Get timestamp via Bash.
6. Use Edit to update the entry:
   - Change `status: "open"` → `status: "resolved"`
   - Add `resolution: "{resolution text}"` after the `source:` line
   - Add `resolved_at: "{timestamp}"` after `created_at:`
7. Ask the user for the resolution text if not provided.

## Subcommand: `update <ID> <field=value>`

1. Auto-detect file by ID prefix: `D` → decisions.yaml, `I` → issues.yaml, `K` → knowledge.yaml.
2. Read the file, find the entry with matching ID.
3. If not found, report error.
4. Validate the field name against the schema for that entry type:
   - Decision: status, severity, summary, detail, source
   - Issue: type, status, severity, summary, detail, source, resolution, resolved_at
   - Knowledge: status, severity, summary, detail, source
5. Use Edit to update the specific field value.
6. Confirm the change.

## Subcommand: `flush`

Scan Lead's context for decisions, issues, and knowledge not yet persisted to YAML files. Context sources include conversation history, Builder reports (`[KNOWLEDGE]`/`[ISSUE]` tags), and Auditor verdict findings.

### Flush Criteria

Look for:
- Explicit user decisions or choices, or Lead's pipeline decisions
- Bugs, issues, or problems reported, discovered, or surfaced by SubAgents
- Structural insights or learnings (tagged `[KNOWLEDGE]`/`[ISSUE]` or untagged)
- Verdict findings that warrant tracking (significant review outcomes)

Exclude: casual mentions, hypotheticals, rejected alternatives.

### Process
1. Review the conversation for items matching flush criteria and rerouting rules (Step 2).
2. For each found item, determine the correct type.
3. Read all three session files to check for duplicates (match by summary similarity).
4. For each non-duplicate item, follow Steps 3-7 to record it.
5. Report a summary table:

```
Flushed:
| ID  | Type      | Summary                    |
|-----|-----------|----------------------------|
| D42 | decision  | ...                        |
| I25 | issue     | ...                        |
```

If no unpersisted items are found, report: "No unpersisted items found."

### Knowledge FP Suppression

During flush, only write to knowledge.yaml when the item is **clearly and unambiguously** a reusable insight (e.g., "hatch-vcs caches metadata after tag", "Edit tool is safer than printf for appending").

When uncertain whether something is knowledge or an issue:
- **Prefer issue** — the sdd-handover skill has a knowledge promotion path (resolved issue's resolution → knowledge) that serves as the proper escalation.
- Do NOT write "problem descriptions with workarounds" as knowledge. Write them as issues with the workaround in the detail field.

---

## Edge Cases

- **Multiple items in one message**: Process each separately, assigning sequential IDs.
- **User provides only a keyword with no content**: Ask for summary and detail before recording.
- **Empty entries list** (`entries: []`): Replace `entries: []` with `entries:` followed by the new entry. Start IDs at 1.
- **Missing session directory**: Create `.sdd/session/` if it does not exist.
</instructions>
