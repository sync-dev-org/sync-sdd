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

## Step 1: Obtain timestamps and git branch

Run a single Bash call to get all values needed upfront:

```
date +%Y-%m-%dT%H:%M:%S%z; date +%Y-%m-%d-%H%M; git branch --show-current
```

Output is 3 lines:
- Line 1 → `ISO_TIMESTAMP` (for Generated field, archive headers, created_at)
- Line 2 → `ARCHIVE_SLUG` (for archive filenames)
- Line 3 → `BRANCH` (for handover header)

Do not call `date` or `git branch` again.

## Step 2: Read current state

Read these files in parallel (use Glob first to check existence for files that may not exist):

| File | Purpose |
|------|---------|
| `.sdd/session/handover.md` | Current handover (auto-draft or previous manual) |
| `.sdd/session/decisions.yaml` | Decision log |
| `.sdd/session/issues.yaml` | Issue tracker |
| `.sdd/session/knowledge.yaml` | Knowledge base |

Also Glob `.sdd/project/specs/*/spec.yaml` and read any that exist to capture pipeline state.

## Step 3: Flush pending session data

Using the files read in Step 2, persist any decisions, issues, or knowledge discussed during the session but not yet written to their files. This prevents data loss at session boundaries.

Scan the conversation history for unrecorded items:
- **Decisions**: user choices or direction changes not yet in `decisions.yaml`
- **Issues**: bug reports or feature requests not yet in `issues.yaml`
- **Knowledge**: operational learnings not yet in `knowledge.yaml`

Cross-reference against Step 2 data — only flush items that are genuinely missing. Use Edit to append at the end of each file's `entries:` list. Use `ISO_TIMESTAMP` for `created_at`.

## Step 4: Consolidate session data

Create all archive directories in one call:

```
mkdir -p .sdd/session/decisions .sdd/session/issues .sdd/session/knowledge .sdd/session/handovers
```

Then process each file. If a file has no entries to archive, skip it entirely (no rewrite, no archive file).

### 4a: decisions.yaml

- **Keep**: `status: active`
- **Archive**: `status: superseded`
- Before archiving, scan active entries for conflicts — if two active decisions address the same topic and one logically supersedes the other, mark the older one `superseded`
- Archive destination: `.sdd/session/decisions/{ARCHIVE_SLUG}.yaml`
- Rewrite `.sdd/session/decisions.yaml` with kept entries only (preserve header comment)

### 4b: issues.yaml

- **Keep**: `status: open` or `status: deferred`
- **Archive**: `status: resolved` or `status: rejected`
- **Knowledge promotion**: before archiving each resolved issue, check if its `resolution` contains a reusable insight (e.g., workaround, root cause pattern, tool usage tip). If so, append a knowledge.yaml entry with the insight. This prevents resolution knowledge from being lost when the issue is archived
- Archive destination: `.sdd/session/issues/{ARCHIVE_SLUG}.yaml`
- Rewrite `.sdd/session/issues.yaml` with kept entries only (preserve header comment)

### 4c: knowledge.yaml

- **Keep**: `status: active`
- **Archive**: `status: superseded`
- **Curation** (before duplicate detection): review active entries for quality and promotion:
  1. **FP detection**: check if any entry is a false positive (incorrect conclusion, outdated, or disproven by later findings). If FP, set `status: superseded` with a note in `detail`
  2. **Rules promotion**: check if any entry describes a Bash security heuristic pattern or workaround. If valid, update `.sdd/settings/rules/lead/bash-security-heuristics.md` with the finding, then set `status: superseded` (knowledge is now codified in rules)
- **Duplicate detection**: if 3+ active entries share substantially similar summaries, flag them as a steering PROPOSE candidate — present to the user in Step 6
- Archive destination: `.sdd/session/knowledge/{ARCHIVE_SLUG}.yaml`
- Rewrite `.sdd/session/knowledge.yaml` with kept entries only (preserve header comment)

### Archive file format

```yaml
# Archived from {source_file} at {ISO_TIMESTAMP}
# Entries: {count}
entries:
  - ...
```

## Step 5: Archive existing handover

If `.sdd/session/handover.md` exists, write its content to `.sdd/session/handovers/{ARCHIVE_SLUG}.md`. The directory was already created in Step 4.

## Step 6: User enrichment

Use the `AskUserQuestion` tool to ask the user:

> 追加したい判断や、次セッションへの引き継ぎ要素はありますか?

Options:
1. **特にない** — proceed with auto-collected data only
2. **議論が必要** — enter detailed enrichment flow (see below)

The user can also provide free text instead of selecting an option. Classify free text into the appropriate handover sections: decisions → Key Decisions, warnings → Warnings, tone → Tone and Nuance, next steps → Resume Instructions.

### Detailed enrichment flow (option 2)

Ask follow-up questions one at a time, skipping any that have obvious answers from session context:

1. **Session Goal**: "このセッションの目標は何でしたか?"
2. **Tone/Nuance**: "次のセッションに伝えたいトーンやニュアンスは?"
3. **Key Decisions**: "追加すべき判断や、既存の判断への補足は?"
4. **Warnings**: "次のリードへの警告事項は?"
5. **Steering Exceptions**: "ステアリングからの意図的な逸脱はありますか?"
6. **Resume Instructions**: "再開時に最初にやるべきことは?"

If duplicate knowledge entries were detected in Step 4c, also present the steering PROPOSE recommendation:
> "以下の知見が 3 回以上出現しています — steering への codify を検討してください: {topics}"

## Step 7: Write new handover

Write `.sdd/session/handover.md` following this structure:

```markdown
# Session Handover
**Generated**: {ISO_TIMESTAMP}
**Branch**: {BRANCH}
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

Key rules:
- **No `**Mode**:` marker** — its absence signals manual polish
- **Key Decisions**: reference decision IDs (e.g., D2, D214) so the next Lead can look up details
- **Tone and Nuance**: intentionally ephemeral — permanent rules belong in knowledge.yaml or CLAUDE.md Behavioral Rules
- **Open Issues**: only include if issues.yaml has open/deferred entries
- **Large entry sets (50+ active)**: summarize by severity (H/M/L counts) rather than listing all

## Step 8: Commit proposal

Use the `AskUserQuestion` tool to present the user with three options:

1. **Commit all changes** — stage and commit everything (session data + any other modified files)
2. **Commit .sdd/session only** — stage and commit only files under `.sdd/session/`
3. **No commit** — end without committing

If the user chooses option 1 or 2, generate a commit message that reflects the session's work. Derive the summary from the Accomplished section.

Format:
```
session: {1-line summary of session accomplishments}

Co-Authored-By: sync-sdd <noreply@sync-sdd>
```

For option 2, stage only `.sdd/session/` files.

## Edge cases

- **Empty session data files**: skip consolidation for that file. Still generate the handover with available information
- **No existing handover.md**: skip Step 5, generate a fresh handover
- **No active specs**: note "No active specifications" in Active Goals
- **User declines enrichment**: generate with auto-collected data only. Still omit Mode marker
