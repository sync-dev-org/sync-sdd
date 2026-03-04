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
- Current `{{SDD_DIR}}/handover/session.md` (if exists — may be auto-draft or previous manual polish)
- Recent entries from `{{SDD_DIR}}/handover/decisions.md` (if exists)

## Step 2: Collect Session Context (Interactive)

Ask user:
1. "What was accomplished in this session?" (key deliverables)
2. "What should be done next?" (immediate next action)
3. "Any decisions or caveats to note?" (context for next session)
4. "Any tone or nuance to convey?" (e.g., "this approach is experimental", "user is enthusiastic about X direction", "prioritize speed over quality for now")
5. "Any intentional deviations from steering/best practices?" (steering exceptions — prevents repeated review flags in future sessions)

## Step 3: Generate Handover Document

Generate comprehensive session.md following the template at `{{SDD_DIR}}/settings/templates/handover/session.md`:

### Direction (from Lead perspective + user input)
- Immediate Next Action
- Active Goals (from spec progress + user input)
- Key Decisions: carry forward from previous session.md + add new from this session (each with brief rationale, reference decisions.md D{seq} for details)
- Warnings

### Session Context (from user interaction)
- Tone and Nuance
- Steering Exceptions (with decisions.md references)

### Accomplished (from auto-collected data + user input)
- Work summary
- Modified Files

### Resume Instructions
- 1-3 concrete steps for next session startup

Do NOT include a `**Mode**:` marker — absence of marker indicates manual polish.

## Step 3.5: Timestamp

Run `date +%Y-%m-%dT%H:%M:%S%z` once. Reuse this single value for all timestamps in Step 3-4: session.md `Generated`, archive filename (derive `YYYY-MM-DD-HHmm` by extracting and reformatting), and SESSION_END entry. Do NOT call `date` again.

## Step 4: Write Files

1. If `{{SDD_DIR}}/handover/session.md` exists:
   - Copy it to `{{SDD_DIR}}/handover/sessions/{YYYY-MM-DD-HHmm}.md` (archive, e.g. `2026-03-03-1430.md`)
   - If same-timestamp archive already exists, append `-2`, `-3`, etc.
2. Write new session.md to `{{SDD_DIR}}/handover/session.md`
3. Append `SESSION_END` to `{{SDD_DIR}}/handover/decisions.md` (append-only, NEVER overwrite):
   ```
   [{ISO-8601}] D{seq}: SESSION_END | {brief session summary}
   - Context: /sdd-handover executed
   - Decision: Session ended, handover archived
   ```

## Step 5: Post-Completion

Report to user:
- Handover file location
- Archive location (if created)
- Key items captured
- Reminder: next session will auto-load session.md on start

</instructions>

## Relationship to Auto-Draft

| Aspect | Auto-Draft (Automatic) | Manual Polish (/sdd-handover) |
|--------|------------------------|-------------------------------|
| Trigger | Each command completion | User runs command |
| Content | Carry-forward + Next Action/Accomplished | Full user context + tone + steering exceptions |
| Quality | Functional (machine-generated) | High (user-validated) |
| Mode marker | `**Mode**: auto-draft` | No marker |
| Archive | No archive | Archives previous session.md to sessions/ |

## Error Handling

- **No active specs**: Still generate handover with available context
- **No git repo**: Skip git state section
- **No existing session.md**: Generate from scratch (no archive step)
- **No decisions.md**: Create with SESSION_END as first entry
