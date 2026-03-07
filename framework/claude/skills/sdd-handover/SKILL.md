---
name: sdd-handover
description: |
  Generate a polished session handover document for cross-session continuity.
  Archives the current handover, consolidates session data (prunes superseded
  decisions, archives resolved issues, detects duplicate knowledge), enriches
  the handover through user dialogue, and optionally commits the result.

  Use this skill when the user says: "ハンドオーバー", "handover", "/sdd-handover",
  "セッション終了", "本セッションを終了", "session end", "引き継ぎ書いて".
  Also triggers on combined requests like "リリースしてハンドオーバー".
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
---

# sdd-handover

Generate a session handover document that captures project state, direction, decisions, and human context so the next session's Lead can resume without friction.

This is the **manual polish** mode — richer than auto-draft because it consolidates session data, archives stale entries, and incorporates user dialogue. The output has no `**Mode**:` marker, which distinguishes it from auto-draft documents.

## Why manual polish matters

Auto-draft captures mechanical state (what happened, what's next). Manual polish captures *human* context — the user's priorities, tone, warnings that don't fit neatly into YAML fields, and the reasoning behind decisions. A next-session Lead reading a polished handover understands not just *what* to do but *why* and *how* the user wants it done.

## Step 1: Obtain timestamp

Run `date` commands to get timestamps for the entire skill execution. Reuse these values everywhere — no additional `date` calls later.

```
date +%Y-%m-%dT%H:%M:%S%z    → ISO_TIMESTAMP  (for Generated field, archive headers)
date +%Y-%m-%d-%H%M          → ARCHIVE_SLUG   (for archive filenames)
```

## Step 2: Flush pending session data

Before consolidation, persist any decisions, issues, or knowledge discussed during the session but not yet written to their files. This prevents data loss at session boundaries.

### How to identify pending items

Scan the conversation history for these signals:
- **Decisions**: user choices, direction changes, or "判断"/"decision" keywords that were discussed but not followed by a Write/Edit to `decisions.yaml`
- **Issues**: bug reports, feature requests, or "問題"/"ISSUE" keywords not yet appended to `issues.yaml`
- **Knowledge**: insights from Builder reports, review findings, or operational learnings not yet in `knowledge.yaml`

Cross-reference: Read the current `decisions.yaml`, `issues.yaml`, and `knowledge.yaml` to check what is already recorded. Only flush items that are genuinely missing.

Use Edit to insert at the end of each file's `entries:` list. Use ISO_TIMESTAMP for `created_at`.

## Step 3: Read current state

Read these files in parallel:

| File | Purpose |
|------|---------|
| `.sdd/session/handover.md` | Current handover (may be auto-draft or previous manual) |
| `.sdd/session/decisions.yaml` | Decision log |
| `.sdd/session/issues.yaml` | Issue tracker |
| `.sdd/session/knowledge.yaml` | Knowledge base |
| `.sdd/settings/templates/session/handover.md` | Template for output structure |

Also scan for active specs — Glob `.sdd/project/specs/*/spec.yaml` and read any that exist to capture pipeline state for the handover.

## Step 4: Consolidate session data

Consolidation prunes stale entries from session data files. For each file, separate entries into **keep** and **archive** sets, then rewrite the active file and write the archived entries to a dated file.

### 4a: decisions.yaml

- **Keep**: `status: active`
- **Archive**: `status: superseded`
- Before archiving, scan active entries for conflicts — if two active decisions address the same topic and one logically supersedes the other, mark the older one `superseded`
- Archive destination: `.sdd/session/decisions/{ARCHIVE_SLUG}.yaml`
- Rewrite `.sdd/session/decisions.yaml` with kept entries only

### 4b: issues.yaml

- **Keep**: `status: open` or `status: deferred`
- **Archive**: `status: resolved` or `status: rejected`
- Archive destination: `.sdd/session/issues/{ARCHIVE_SLUG}.yaml`
- Rewrite `.sdd/session/issues.yaml` with kept entries only

### 4c: knowledge.yaml

- **Keep**: `status: active`
- **Archive**: `status: superseded`
- **Duplicate detection**: if 3+ active entries share substantially similar summaries (same topic/pattern), flag them as a steering PROPOSE candidate. Present this to the user in Step 5 — repeated knowledge often indicates a pattern worth codifying in steering
- Archive destination: `.sdd/session/knowledge/{ARCHIVE_SLUG}.yaml`
- Rewrite `.sdd/session/knowledge.yaml` with kept entries only

### Archive file format

```yaml
# Archived from {source_file} at {ISO_TIMESTAMP}
# Entries: {count}
entries:
  - ...
```

If no entries need archiving for a given file, skip creating that archive file. Create the archive directory if it does not exist.

## Step 5: User enrichment

Ask the user a single question to determine the level of enrichment:

> 追加したい判断や、次セッションへの引き継ぎ要素はありますか?

Present options:
1. **特にない** — proceed with auto-collected data only
2. **議論が必要** — enter detailed enrichment flow (see below)

The user can also provide free text instead of selecting an option. Classify free text into the appropriate handover sections: if it describes a decision, add to Key Decisions; if it's a warning or caveat, add to Warnings; if it's about tone or approach, add to Tone and Nuance; if it's about next steps, add to Resume Instructions.

### Detailed enrichment flow (option 2)

Ask follow-up questions one at a time, skipping any that have obvious answers from session context:

1. **Session Goal**: "このセッションの目標は何でしたか?" (if not already clear from handover history)
2. **Tone/Nuance**: "次のセッションに伝えたいトーンやニュアンスは?" (e.g., "experimental", "conservative", user mood)
3. **Key Decisions**: "追加すべき判断や、既存の判断への補足は?"
4. **Warnings**: "次のリードへの警告事項は?"
5. **Steering Exceptions**: "ステアリングからの意図的な逸脱はありますか?"
6. **Resume Instructions**: "再開時に最初にやるべきことは?"

If duplicate knowledge entries were detected in Step 4c, also present the steering PROPOSE recommendation:
> "以下の知見が 3 回以上出現しています — steering への codify を検討してください: {topics}"

## Step 6: Archive existing handover

If `.sdd/session/handover.md` exists, copy its content to `.sdd/session/handovers/{ARCHIVE_SLUG}.md`. Create the `handovers/` directory if needed.

If no handover exists yet, skip this step.

## Step 7: Write new handover

Write `.sdd/session/handover.md` following this structure:

```markdown
# Session Handover
**Generated**: {ISO_TIMESTAMP}
**Branch**: {from git branch --show-current}
**Session Goal**: {from user enrichment or inferred from session}

## Direction
### Immediate Next Action
{specific command or step for resumption}

### Active Goals
{progress toward objectives — table or bullet list}

### Key Decisions
**Continuing from previous sessions:**
{numbered list with decision ID refs, e.g. "D2: 本リポはspec/steering不使用"}

**Added this session:**
{same format for new decisions}

### Warnings
{constraints, risks, caveats for the next Lead}

## Session Context
### Tone and Nuance
{user's temperature, direction nuances — ephemeral, may not persist beyond one handover}

### Steering Exceptions
{intentional deviations with decisions.yaml refs}

## Accomplished
{work completed this session, with Previous Sessions subsection carrying forward history}

## Open Issues
{table of open/deferred issues: ID | Severity | Summary}

## Resume Instructions
{1-3 concrete steps for next session startup}
```

Key formatting rules:
- **No `**Mode**:` marker** — its absence signals manual polish
- **Generated**: ISO_TIMESTAMP from Step 1
- **Branch**: obtain from `git branch --show-current`
- **Key Decisions**: reference decision IDs (e.g., D2, D214) so the next Lead can look up details
- **Tone and Nuance**: these are intentionally ephemeral — they carry across one handover but do not need to persist indefinitely. Permanent behavioral rules belong in knowledge.yaml or CLAUDE.md Behavioral Rules
- **Open Issues**: only include if issues.yaml has open/deferred entries
- **Large entry sets (50+ active)**: summarize by severity (H/M/L counts) rather than listing all. Full data remains in YAML files

## Step 8: Commit proposal

Present the user with three options:

1. **Commit all changes** — stage and commit everything (session data + any other modified files)
2. **Commit .sdd/session only** — stage and commit only files under `.sdd/session/`
3. **No commit** — end without committing

If the user chooses option 1 or 2, generate a commit message that reflects the session's work. Derive the summary from the Accomplished section — the message should tell a future reader what was done, not just that a handover occurred.

Format:
```
session: {1-line summary of session accomplishments}

Co-Authored-By: sync-sdd <noreply@sync-sdd>
```

Example: `session: sdd-review tmux migration + verdict-format.md unified schema`

For option 2, stage only `.sdd/session/` files.

## Edge cases

- **Empty session data files**: if a file has no entries or does not exist, skip its consolidation. Still generate the handover with available information
- **No existing handover.md**: skip the archive step (Step 6) and generate a fresh handover
- **No active specs**: note "No active specifications" in the Active Goals section
- **User declines enrichment**: generate the handover using only auto-collected data. Still omit the Mode marker to distinguish from auto-draft
