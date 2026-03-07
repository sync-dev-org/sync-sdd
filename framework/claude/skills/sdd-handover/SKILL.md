---
description: Generate session handover document
allowed-tools: Bash, Glob, Grep, Read, Write, Edit
---

# SDD Handover

<instructions>

## Core Task

Generate high-quality session handover document through user interaction. This is the **manual polish** version — it enriches the auto-draft with user context, tone, and nuance that cannot be captured automatically.

## Step 1: Auto-Collect Project State

Gather in parallel:
- Git state (branch, recent commits, uncommitted changes)
- Roadmap/spec progress (read all spec.yaml files)
- Test results (if test commands available)
- Steering changes (recent modifications)
- Current `{{SDD_DIR}}/session/handover.md` (if exists — may be auto-draft or previous manual polish)
- Recent entries from `{{SDD_DIR}}/session/decisions.yaml` (if exists)

## Step 1b: Uncommitted Changes Check

If Step 1 detected uncommitted changes (untracked files or modifications):
- Report the list of uncommitted files to the user
- Use `AskUserQuestion` to ask: "未コミットの変更があります。コミットしてからハンドオーバーしますか？"
  - Options: "コミットする (推奨)" / "コミットせずに続行"
- If user chooses to commit: create a commit following the project's git workflow conventions, then proceed
- If user chooses to skip: proceed without committing

## Step 2: Collect Session Context (Interactive)

Use `AskUserQuestion` tool to ask user:
1. "What was accomplished in this session?" (key deliverables)
2. "What should be done next?" (immediate next action)
3. "Any decisions or caveats to note?" (context for next session)
4. "Any tone or nuance to convey?" (e.g., "this approach is experimental", "user is enthusiastic about X direction", "prioritize speed over quality for now")
5. "Any intentional deviations from steering/best practices?" (steering exceptions — prevents repeated review flags in future sessions)

## Step 3: Generate Handover Document

Generate comprehensive handover.md following the template at `{{SDD_DIR}}/settings/templates/session/handover.md`:

### Direction (from Lead perspective + user input)
- Immediate Next Action
- Active Goals (from spec progress + user input)
- Key Decisions: carry forward from previous handover.md + add new from this session (each with brief rationale, reference decisions.yaml D{seq} for details)
- Warnings

### Session Context (from user interaction)
- Tone and Nuance
- Steering Exceptions (with decisions.yaml references)

### Accomplished (from auto-collected data + user input)
- Work summary
- Modified Files

### Resume Instructions
- 1-3 concrete steps for next session startup

Do NOT include a `**Mode**:` marker — absence of marker indicates manual polish.

## Step 4: Timestamp

Run `date +%Y-%m-%dT%H:%M:%S%z` once. Reuse this single value for all timestamps in Steps 3, 4b, and 5: handover.md `Generated`, archive filename (derive `YYYY-MM-DD-HHmm` by extracting and reformatting), SESSION_END entry, and archive filename. Do NOT call `date` again.

## Step 4b: Flush and Consolidate

### Flush

Write any pending decisions to `decisions.yaml` and knowledge to `knowledge.yaml` that were noted during the session but not yet persisted. This ensures all session data is captured before consolidation.

### Consolidate decisions.yaml

1. Read all entries from `decisions.yaml`
2. **Superseded exclusion**: Remove entries that have a `superseded_by` field (they are replaced by the referenced entry)
3. **SESSION pair condensation**: Keep only the latest `SESSION_START`/`SESSION_END` pair. Remove all older SESSION_START and SESSION_END entries
4. **Archive pruned entries**: If any entries were removed, write them to `{{SDD_DIR}}/session/decisions/{YYYY-MM-DD-HHmm}.yaml` (use timestamp from Step 4) with the same schema (`entries: [...]`)
5. **Rewrite decisions.yaml**: Write the header comment + remaining entries (this is the one exception to append-only — consolidation is a controlled rewrite)

### Consolidate knowledge.yaml

1. Read all entries from `knowledge.yaml`
2. **Duplicate detection**: Group entries by `type` × `summary` similarity (same type AND semantically similar summary). If any group has ≥3 entries:
   - Report the duplicate groups to the user
   - For each group, propose a steering entry: `STEERING: PROPOSE — consolidate {count} repeated {type} findings into steering rule: "{summary}"`
   - Use `AskUserQuestion` to ask: "以下の knowledge パターンを steering に昇格しますか？" with options per group: "Approve (steering に追加)" / "Skip (そのまま維持)"
   - For approved groups: append the rule to the appropriate steering file, mark the knowledge entries with `superseded_by: "steering:{file}#{section}"`
3. **Superseded exclusion**: Remove entries that have a `superseded_by` field
4. **Rewrite knowledge.yaml**: Write the header comment + remaining entries

## Step 5: Write Files

1. If `{{SDD_DIR}}/session/handover.md` exists:
   - Copy it to `{{SDD_DIR}}/session/handovers/{YYYY-MM-DD-HHmm}.md` (archive, e.g. `2026-03-03-1430.md`)
   - If same-timestamp archive already exists, append `-2`, `-3`, etc.
2. Write new handover.md to `{{SDD_DIR}}/session/handover.md`
3. Append `SESSION_END` entry to `{{SDD_DIR}}/session/decisions.yaml` `entries` list (append-only, NEVER overwrite):
   ```yaml
   - id: "D{seq}"
     type: "SESSION_END"
     summary: "{brief session summary}"
     context: "/sdd-handover executed"
     detail: "Session ended, handover archived"
     created_at: "{ISO-8601}"
   ```

## Step 6: Post-Completion

Report to user:
- Handover file location
- Archive location (if created)
- Key items captured
- Reminder: next session will auto-load handover.md on start

</instructions>

## Relationship to Auto-Draft

| Aspect | Auto-Draft (Automatic) | Manual Polish (/sdd-handover) |
|--------|------------------------|-------------------------------|
| Trigger | Each command completion | User runs command |
| Content | Carry-forward + Next Action/Accomplished | Full user context + tone + steering exceptions |
| Quality | Functional (machine-generated) | High (user-validated) |
| Mode marker | `**Mode**: auto-draft` | No marker |
| Archive | No archive | Archives previous handover.md to handovers/ |

## Error Handling

- **No active specs**: Still generate handover with available context
- **No git repo**: Skip git state section
- **No existing handover.md**: Generate from scratch (no archive step)
- **No decisions.yaml**: Create with SESSION_END as first entry
