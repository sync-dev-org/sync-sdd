---
description: Generate session handover document
allowed-tools: Bash, Glob, Grep, Read, Write, Edit, AskUserQuestion, SendMessage
argument-hint:
---

# SDD Handover (Unified)

<instructions>

## Core Task

Generate high-quality session handover document. Conductor handles directly (requires user interaction for context gathering).

This is the **manual, high-quality** version of handover. It complements the **automatic incremental persistence** that Lead maintains in `{{SDD_DIR}}/handover/`.

## Step 1: Auto-Collect Project State

Gather in parallel:
- Git state (branch, recent commits, uncommitted changes)
- Roadmap/spec progress (read all spec.json files)
- Test results (if test commands available)
- Steering changes (recent modifications)
- Current `{{SDD_DIR}}/handover/conductor.md` (if exists)

## Step 2: Collect Session Context (Interactive)

Ask user:
1. "What was accomplished in this session?" (key deliverables)
2. "What should be done next?" (immediate next action)
3. "Any decisions or caveats to note?" (context for next session)

## Step 3: Generate Handover Document

Generate comprehensive markdown combining:

### Direction Layer (from Conductor perspective)
- Immediate Next Action (command form)
- Active Goals
- Key Decisions made this session
- Caveats and warnings

### State Layer (from auto-collected data)
- Pipeline State: reference `{{SDD_DIR}}/handover/conductor.md` Pipeline State section
- Test status
- Git state

### Context Layer (from user interaction)
- Session accomplishments
- User-provided context and nuances

## Step 4: Write Files

1. Write handover to `{{SDD_DIR}}/handover/conductor.md` (overwrites incremental version)
2. Append session decisions to `{{SDD_DIR}}/handover/log.md` (append-only, NEVER overwrite)

## Step 5: Post-Completion

Report to user:
- Handover file location
- Key items captured
- Reminder: next session will auto-load handover on start

</instructions>

## Relationship to Incremental Persistence

| Aspect | Incremental (Automatic) | Manual (/sdd-handover) |
|--------|------------------------|----------------------|
| Trigger | Every phase transition / teammate completion | User runs command |
| Content | State snapshot only | State + user context + direction |
| Quality | Minimal (machine-generated) | High (user-validated) |
| Location | Same `{{SDD_DIR}}/handover/` directory | Overwrites conductor.md, appends to log.md |

## Error Handling

- **No active specs**: Still generate handover with available context
- **No git repo**: Skip git state section
