---
name: sdd-log
description: Records decisions, issues, and knowledge to session YAML files. Make sure to use this skill whenever the user mentions "issue", "問題", "decision", "判断", "決定", "knowledge", "覚えて", "remember", "記録", "登録", or wants to log, track, or record something, even if they don't explicitly say "/sdd-log".
allowed-tools: Bash, Read, Edit, Write, Glob
argument-hint: decision|issue|knowledge|resolve|update <args>
---

# SDD Log

<instructions>

## Core Task

Record session data (decisions, issues, knowledge) to the corresponding YAML files under `{{SDD_DIR}}/session/`. This skill provides explicit, reliable recording — complementing the NL trigger mechanism in CLAUDE.md Behavioral Rules.

## Step 1: Parse Arguments

Parse the first argument as subcommand:

| Subcommand | Target File | Operation |
|-----------|-------------|-----------|
| `decision` | `decisions.yaml` | Append new entry |
| `issue` | `issues.yaml` | Append new entry |
| `knowledge` | `knowledge.yaml` | Append new entry |
| `resolve <ID>` | `issues.yaml` | Update issue status to `resolved` |
| `update <ID> <field=value ...>` | Auto-detect by ID prefix | Update specified fields |

If no subcommand is provided, ask the user which type to record.

## Step 2: Initialize File (if needed)

Check if target file exists with Glob. If not found:
1. Read the corresponding template from `{{SDD_DIR}}/settings/templates/session/{filename}`
2. Write template to `{{SDD_DIR}}/session/{filename}` using Write tool

## Step 3: Read Current File

Read the target file to:
- Determine the next ID (scan all `id:` values, extract max number, increment by 1)
- For `resolve`/`update`: locate the target entry by ID

## Step 4: Get Timestamp

Run `date +%Y-%m-%dT%H:%M:%S%z` via Bash to get the current timestamp. Use the result verbatim.

## Step 5: Build Entry

### For `decision` (new)

Extract from user's message or remaining arguments:
- `summary`: one-line summary (required)
- `detail`: background, rationale, impact (required — ask if not inferrable)
- `severity`: H/M/L (default: M unless user indicates otherwise)
- `source`: "user" (if user-initiated), "lead" (if Lead-initiated), "auditor" (if from review)

```yaml
  - id: "D{N}"
    status: "active"
    severity: "{H|M|L}"
    summary: "{one-line}"
    detail: "{背景・詳細・理由・影響を含む}"
    source: "{user|lead|auditor}"
    created_at: "{timestamp}"
```

### For `issue` (new)

Extract from user's message or remaining arguments:
- `summary`: one-line summary (required)
- `detail`: details (required — ask if not inferrable)
- `type`: BUG / FEATURE / ENHANCEMENT (default: BUG for "問題"/"バグ", ENHANCEMENT for "改善", FEATURE for "機能")
- `severity`: H/M/L (default: H)
- `source`: origin description

```yaml
  - id: "I{N}"
    type: "{BUG|FEATURE|ENHANCEMENT}"
    status: "open"
    severity: "{H|M|L}"
    summary: "{one-line}"
    detail: "{詳細}"
    source: "{出所}"
    created_at: "{timestamp}"
```

### For `knowledge` (new)

Extract from user's message or remaining arguments:
- `summary`: one-line summary (required)
- `detail`: details, impact, recommendations (required — ask if not inferrable)
- `severity`: H/M/L (default: M)
- `source`: origin description

```yaml
  - id: "K{N}"
    status: "active"
    severity: "{H|M|L}"
    summary: "{one-line}"
    detail: "{詳細・影響・推奨を含む}"
    source: "{出所}"
    created_at: "{timestamp}"
```

### For `resolve <ID>`

- Validate ID starts with "I" (only issues can be resolved)
- Find the entry in issues.yaml
- Update `status: "resolved"`
- Add `resolution:` field (from user's message or remaining arguments — ask if not provided)
- Add `resolved_at:` field (timestamp from Step 4)

### For `update <ID> <field=value ...>`

- Auto-detect target file by ID prefix: D → decisions.yaml, I → issues.yaml, K → knowledge.yaml
- Find the entry by ID
- Update specified fields (e.g., `status=superseded`, `severity=H`, `type=BUG`)
- Validate field names against the schema for that entry type

## Step 6: Write Entry

- **New entries**: Use Edit tool to append the new YAML entry at the end of the file (after the last line)
- **Updates** (`resolve`/`update`): Use Edit tool to modify the specific fields in-place
- NEVER use Bash echo/printf/cat for file writes

## Step 7: Confirm

Report to user:
- What was recorded (ID, summary)
- File path
- For `resolve`: show the resolved entry

</instructions>
