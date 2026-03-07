---
name: sdd-handover
description: >-
  Generates a polished session handover document for seamless cross-session
  continuity. Consolidates decisions, issues, and knowledge, archives stale
  entries, and produces a structured handover.md through user dialogue. Use
  this skill whenever the user says "handover", "ハンドオーバー", "セッション終了",
  "session end", "引き継ぎ書いて", "/sdd-handover", or mentions ending or wrapping
  up a session. Also triggers on combined requests like "リリースしてハンドオーバー".
  This is the manual-polish mode — richer than auto-draft because it
  consolidates session data, archives stale entries, and incorporates user
  dialogue for tone, nuance, and resume instructions.
allowed-tools: Read Write Edit Glob Grep Bash
---

# sdd-handover

Generate a polished session handover document at session end. The goal is to
produce a handover.md that enables the next session's Lead to resume work
without friction — capturing direction, decisions, warnings, tone, and
concrete resume steps.

This is the "manual polish" mode. It differs from auto-draft in three ways:
(1) it consolidates and archives stale session data, (2) it enriches the
document through user dialogue, and (3) it omits the `**Mode**: auto-draft`
marker so the next Lead knows this was a deliberate handover.

## Process

### Step 1: Obtain Timestamps and Branch

Run a single Bash call to get all values needed upfront:

```
date +%Y-%m-%dT%H:%M:%S%z; date +%Y-%m-%d-%H%M; git branch --show-current
```

Output is 3 lines:
- Line 1 → `ISO_TS` (for Generated field, archive headers, created_at)
- Line 2 → `ARCHIVE_SLUG` (for archive filenames)
- Line 3 → `BRANCH` (for handover header)

Do not call `date` or `git branch` again after this step.

### Step 2: Read Current Session Data

Read these files in parallel (use Glob first to check existence for files that may not exist):

- `.sdd/session/handover.md`
- `.sdd/session/decisions.yaml`
- `.sdd/session/issues.yaml`
- `.sdd/session/knowledge.yaml`

Also Glob `.sdd/project/specs/*/spec.yaml` and read any that exist to capture pipeline state.

### Step 3: Flush Pending Session Data

Using the files read in Step 2, scan the conversation history for decisions,
issues, and knowledge discussed during this session but not yet persisted.

For each unpersisted item:
1. Determine the next available ID from the file read in Step 2 (e.g., if the
   last entry is D215, the next is D216)
2. Append the entry to the appropriate file using Edit (insert at end)
3. Use ISO_TS from Step 1

This flush ensures nothing is lost before consolidation rewrites the files.

### Step 4: Consolidate Session Data

This is the core maintenance step. First, create all archive directories in one call:

```
mkdir -p .sdd/session/decisions .sdd/session/issues .sdd/session/knowledge .sdd/session/handovers
```

Then process each file in order. Do not create empty archive files — if nothing qualifies for archival, skip that substep.

#### 4a: decisions.yaml

1. Identify entries with `status: superseded`
2. Check for conflicting active decisions on the same topic — if found, ask
   the user which to keep and mark the other superseded
3. If any superseded entries exist, write them to
   `.sdd/session/decisions/{ARCHIVE_SLUG}.yaml` with this format:
   ```yaml
   # Archived from decisions.yaml at {ISO_TS}
   # Entries: {count}
   entries:
     - ...
   ```
4. Rewrite `.sdd/session/decisions.yaml` containing only `status: active`
   entries

#### 4b: issues.yaml

1. Identify entries with `status: resolved` or `status: rejected`
2. **Knowledge promotion**: For each resolved issue, examine its `resolution`
   field. If the resolution contains a reusable structural insight (a pattern,
   a workaround, a root cause that could recur), create a new knowledge.yaml
   entry. Use judgment — operational fixes ("typo in line 42") are not worth
   promoting; structural insights ("hatch-vcs caches metadata after tag") are
3. Archive resolved/rejected entries to
   `.sdd/session/issues/{ARCHIVE_SLUG}.yaml` (same header format as decisions)
4. Rewrite `.sdd/session/issues.yaml` containing only `status: open` and
   `status: deferred` entries

#### 4c: knowledge.yaml

1. **False positive detection**: Review entries and mark any that turned out
   to be incorrect or no longer applicable as `status: superseded`
2. **Rules promotion**: If an entry describes a Bash security heuristic
   pattern not yet documented in
   `.sdd/settings/rules/lead/bash-security-heuristics.md`, append it to that
   rules file
3. **Duplicate detection**: Look for 3+ entries with similar summaries. If
   found, note them for potential steering codification — mention this to
   the user in the enrichment dialogue (Step 6)
4. Archive superseded entries to
   `.sdd/session/knowledge/{ARCHIVE_SLUG}.yaml` (same header format as decisions)
5. Rewrite `.sdd/session/knowledge.yaml` containing only `status: active`
   entries

For large entry sets (50+ active entries in any file), summarize by severity
counts (e.g., "decisions: 12H / 18M / 5L") rather than listing every entry
during user dialogue.

### Step 5: Archive Existing Handover

If `.sdd/session/handover.md` exists:
1. Create the `handovers/` directory if it does not exist
2. Copy the current handover to `.sdd/session/handovers/{ARCHIVE_SLUG}.md`

If no handover.md exists, skip this step. The enrichment dialogue still runs
— the user may want to set session context even for a first handover.

### Step 6: User Enrichment Dialogue

Present a summary of what was accomplished this session and the consolidation
results (how many entries archived, any knowledge promoted, any duplicates
detected for steering codification).

Then ask the user a single compound question covering all enrichment areas:

> Before I write the handover, anything to add or adjust?
> - **Key decisions** to highlight or clarify?
> - **Warnings** for the next session?
> - **Tone/Nuance** (e.g., "experimental mode", "user wants conservative approach")?
> - **Steering exceptions** (intentional deviations from best practices)?
> - **Resume instructions** (specific steps beyond what I'll infer from pipeline state)?
>
> Say "nothing" or "なし" to proceed with defaults.

Accept both quick dismissals and detailed responses. If the user provides
enrichment, incorporate it into the appropriate sections.

Tone and Nuance is intentionally ephemeral — it captures the user's current
working style and session-specific preferences. Permanent behavioral rules
belong in knowledge.yaml or CLAUDE.md, not in the handover's Tone/Nuance
section.

### Step 7: Generate handover.md

Write `.sdd/session/handover.md` using this structure (template reference:
`.sdd/settings/templates/session/handover.md`):

```markdown
# Session Handover
**Generated**: {ISO_TS}
**Branch**: {branch}
**Session Goal**: {from user enrichment, or inferred from session work}

## Direction
### Immediate Next Action
{specific command or step the next Lead should execute first}

### Active Goals
{progress toward objectives — what is in flight, what is blocked, what is next}

### Key Decisions
**Continuing from previous sessions:**
{carry forward from previous handover — numbered, with decision IDs like D2, D214}

**Added this session:**
{new decisions — numbered, with decision IDs}

### Warnings
{constraints, risks, caveats — from user enrichment and Lead observations}

## Session Context
### Tone and Nuance
{from user enrichment — ephemeral session-specific preferences}

### Steering Exceptions
{intentional deviations — reference decisions.yaml IDs}

## Accomplished
### Work Summary (this session)
{work completed this session — concrete, specific}

### Previous Sessions (carry forward)
{summary of prior session work — carried forward from previous handover}

### Modified Files
{key files changed this session — helps next Lead understand scope}

## Open Issues
{table of open/deferred issues from issues.yaml: ID | Severity | Summary}
{only include if issues.yaml has open/deferred entries}

## Resume Instructions
{1-3 steps for next session startup — always include /sdd-start as first step}
```

Reference decision IDs in Key Decisions so the next Lead can look up full
details in decisions.yaml. Keep the document concise but complete — the next
Lead should be able to resume without reading the full conversation history.

Do NOT include `**Mode**: auto-draft` — its absence signals manual polish.

### Step 8: Commit Proposal

Present the user with three choices:

1. **Commit all changes** — all modified files in the working tree
2. **Commit .sdd/session/ only** — only session data files
3. **No commit** — leave changes as-is

If the user chooses option 1 or 2, generate an appropriate commit message
using a heredoc:

```
session: {one-line summary of session work}

Co-Authored-By: sync-sdd <noreply@sync-sdd>
```

Stage only the relevant files (specific paths, not `git add -A`) and commit.

## Edge Cases

- **No existing handover.md**: Skip archival (Step 5). Enrichment dialogue
  and generation proceed normally
- **Empty or missing session files**: Skip their consolidation substeps.
  Proceed with the remaining flow
- **Combined requests** (e.g., "リリースしてハンドオーバー"): This skill handles
  only the handover portion. Other operations (release, etc.) should complete
  first, with handover running after
- **No spec.yaml files found**: Active Goals and Resume Instructions should
  reflect non-pipeline work (framework development, ad-hoc tasks, etc.)
- **Nothing to archive**: Report "No stale entries found" and move on — do
  not create empty archive files
- **Archive directories missing**: Create them on first use
  (`handovers/`, `decisions/`, `issues/`, `knowledge/`)
