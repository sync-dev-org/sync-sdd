---
name: sdd-review-self
description: "Framework self-review for sync-sdd development repo. Runs automated code quality review using external engines (Codex CLI, Claude Code headless, Gemini CLI) or SubAgents against framework/ directory. Use this skill for self-review, framework review, review-self, quality check on framework files, code review of SDD framework, verify framework consistency, check framework compliance, audit framework changes, run self-review pipeline."
argument-hint: "[--inspector-engine E] [--auditor-engine E] [--inspector-model M] [--auditor-model M] [--inspector-effort low|medium|high] [--auditor-effort low|medium|high] [--timeout N]"
allowed-tools: Read Write Edit Glob Grep Bash Agent
---

# sdd-review-self

Self-review pipeline for the sync-sdd framework development repository. Dispatches external engines or SubAgents to review `framework/` for flow integrity, cross-file consistency, and platform compliance. Lead acts as supervisor — it does not read Inspector findings directly (context preservation) but reviews the Auditor's synthesized verdict, applying FP judgment and severity corrections that require session context (D121).

## Gate Check

1. Verify `framework/` directory exists. If absent, report "This skill targets the sync-sdd framework repo only. framework/ not found." and stop.

## Step 1: Parse Arguments

Parse `$ARGUMENTS` for per-stage overrides. Each stage (inspectors, auditor) accepts `--{stage}-engine`, `--{stage}-model`, `--{stage}-effort`. Also parse `--timeout <seconds>`. Unspecified stages use the level chain from engines.yaml. Note: Briefer is a fixed SubAgent (Step 4) and does not accept engine overrides.

## Step 2: Resolve Engine Levels

Read `.sdd/lib/prompts/dispatch/engine.md` and follow Section 1 (Engine Resolution) with:
- ROLE_NAME = `review-self`
- STAGES = `inspectors`, `auditor`
- DEFAULT_TIMEOUT = 900
- Argument overrides from Step 1

## Step 3: Prepare Scope Directory

```
SCOPE_DIR = .sdd/project/reviews/self
ACTIVE = .sdd/project/reviews/self/active/
```

If `active/` exists and contains files, remove all files in it (stale from interrupted run). Create `active/` if it does not exist.

Determine `B_SEQ`: read `{SCOPE_DIR}/verdicts.yaml`. If it exists, next seq = max(seq values) + 1. Otherwise, seq = 1.

## Step 4: Dispatch Briefer

The Briefer is dispatched as a **SubAgent** (not an external engine). Lead does NOT read the Briefer prompt — the SubAgent reads it itself.

Dispatch via Agent tool with `run_in_background: true`:
- model: sonnet
- Prompt: `Read .sdd/lib/prompts/review-self/briefer.md and follow its instructions exactly. Write all output files to .sdd/project/reviews/self/active/.`

### Briefer Completion

After Briefer completes, verify `.sdd/project/reviews/self/active/briefer-status.md` does not contain `NO_CHANGES`. If it does, report "No framework changes detected. Nothing to review." and stop.

Verify `active/shared-prompt.md` exists. Read `active/dynamic-manifest.md` to learn the count and names of dynamic Inspectors.

## Step 5: Dispatch Inspectors (Parallel)

Dispatch all Inspectors in parallel: 3 fixed (flow, consistency, compliance) + N dynamic (from manifest).

Each Inspector receives its prompt via stdin pipe:
- Fixed: `cat .sdd/project/reviews/self/active/shared-prompt.md .sdd/lib/prompts/review-self/inspector-{name}.md`
- Dynamic: `cat .sdd/project/reviews/self/active/shared-prompt.md .sdd/project/reviews/self/active/inspector-dynamic-{N}-{slug}.md`

Follow `.sdd/lib/prompts/dispatch/engine.md` Section 3 (Dispatch Modes) for the resolved inspector engine.

For tmux mode, use staggered parallel dispatch (0.5s intervals) + hold-and-release pattern:
- Channel per Inspector: `sdd-{SID}-inspector-{name}-B{B_SEQ}`
- Close channel (shared): `sdd-{SID}-close-B{B_SEQ}`
- Command chain: `cat {prompt_files} | {engine_cmd}; tmux wait-for -S {channel}; tmux wait-for {close_channel}`
- Assign slots from state.yaml. If slots insufficient, overflow Inspectors use background mode.
- Issue all send-keys + wait-for via single batch of `Bash(run_in_background=true)` calls with sleep stagger.
- After all Inspector wait-for channels have signaled completion (confirmed via task-notification): proceed to Inspector Completion.

For SubAgent mode: dispatch all via Agent tool with `run_in_background: true`. Each Inspector reads shared-prompt.md and its own inspector prompt file.

For background mode: dispatch all via `Bash(run_in_background=true)`.

### Runtime Escalation

If any Inspector fails to produce its expected output file, read `.sdd/lib/prompts/dispatch/escalation.md` and follow its instructions to classify the failure, escalate, and re-dispatch.

### Inspector Completion

After all Inspectors complete (or fail), verify findings files exist in `active/`:
- `findings-inspector-flow.yaml`
- `findings-inspector-consistency.yaml`
- `findings-inspector-compliance.yaml`
- `findings-inspector-dynamic-{N}-{slug}.yaml` (per manifest)

For tmux mode: release all slots by sending the close channel signal (`tmux wait-for -S {close_channel}`), then update all slot statuses to idle in state.yaml.

## Step 6: Dispatch Auditor

Lead does NOT read the Auditor template.

Build a prompt header listing the available findings file paths and the `.sdd/session/decisions.yaml` path. Write to `active/auditor-header.md`.

Dispatch the Auditor using the resolved engine for the `auditor` stage, following `.sdd/lib/prompts/dispatch/engine.md` Section 3:
- **SubAgent mode**: Pass the header content inline + instruct it to `Read .sdd/lib/prompts/review-self/auditor.md and follow its instructions`.
- **tmux/background mode**: `cat .sdd/project/reviews/self/active/auditor-header.md .sdd/lib/prompts/review-self/auditor.md | {engine_cmd}`

### Auditor Completion

Verify `active/verdict-auditor.yaml` exists. If missing, read `.sdd/lib/prompts/dispatch/escalation.md` and follow its instructions.

## Step 7: Lead Supervision

Read `active/verdict-auditor.yaml`. Do NOT read individual Inspector findings files -- the Auditor has already synthesized them.

### Second-Pass FP/Defer Judgment

Cross-reference each Auditor finding against:
- `decisions.yaml`: intentional decisions that explain the finding.
- Previous `verdicts.yaml` tracked items: already known and tracked.

For each finding, determine:
- **FP**: finding is explained by a decision or is a known tracked item. Add to `lead_overrides` with action: "eliminate".
- **Severity reclassify**: finding severity is too high given context. Add to `lead_overrides` with action: "reclassify". Lead may only downgrade severity.
- **Accept**: finding is valid. Keep as-is.

### A/B Classification Verification

Review the Auditor's A/B classification for each confirmed finding:
- **A (auto-fix)**: the fix is unambiguous. Naming typo, missing permission entry, stale count.
- **B (decision-required)**: design-level change, wide impact, multiple valid approaches.

Adjust classification if the Auditor miscategorized.

### Write verdict.yaml

Write `active/verdict.yaml` following the schema in `.sdd/settings/rules/agent/verdict-format.md` Section 3. Include:
- `verdict`: GO / CONDITIONAL / NO-GO
- `counts`: severity counts (updated after Lead overrides)
- `issues`: confirmed findings with `classification` field (A or B)
- `lead_overrides`: all FP eliminations and reclassifications with rationale
- `disposition`: see verdict-format.md Disposition Codes

### Present to User

Present the full verdict to the user with ALL fields expanded. Do not compress into summary tables.

For **B items**: include `impact`, `options` (if applicable), and `recommendation` for each.

User approves, rejects, or defers each item:
- `approved` -> will be fixed by Lead in Step 8
- `rejected` -> move to `fp_eliminated` (user-confirmed FP)
- `deferred` -> add to `tracked`, record as issue (Read `.sdd/lib/prompts/log/record.md`, type=issue, issue type=ENHANCEMENT, status=deferred)

Update `verdict.yaml` with `user_decision` for each item.

For **A items**: auto-approved (present for visibility, proceed to Lead Fix).

## Step 8: Lead Fix

Collect all items with `user_decision: approved` (A + B approved). If none, skip to Step 9.

Lead directly applies fixes to the codebase:
1. For each approved item, read the target file and apply the fix per the recommendation. Set `resolution: fixed` in verdict.yaml.
2. After all fixes, verify with `git diff` and report: `Fixed {N}/{total} items. Files modified: {list}`
3. Items that cannot be fixed (insufficient context, wide impact): set `resolution: deferred` in verdict.yaml and report reason.

## Step 9: Verdict Persistence

### Update verdicts.yaml

Append a new batch entry to `.sdd/project/reviews/self/verdicts.yaml` following verdict-format.md Section 4:

```yaml
- seq: {B_SEQ}
  type: "self"
  scope: "framework"
  date: "{ISO-8601 timestamp via date command}"
  version: "{contents of .sdd/.version}"
  engines:
    briefer: "{actual model used}"
    inspectors: "{actual model used}"
    auditor: "{actual model used}"
    builder: "lead"
  agents:
    fixed: 3
    dynamic: {N from manifest}
    total: {3 + N}
  counts: {from verdict.yaml}
  verdict: "{from verdict.yaml}"
  disposition: "{from verdict.yaml}"
  tracked: {from verdict.yaml, if any}
  resolved: {from verdict.yaml, if any}
```

### Archive

Rename `active/` to `B{B_SEQ}/`:
```
mv .sdd/project/reviews/self/active .sdd/project/reviews/self/B{B_SEQ}
```

### Deferred Items

For any items with `user_decision: deferred`, record each as an issue if not already recorded in Step 7:
- Read `.sdd/lib/prompts/log/record.md` and follow its instructions
- type: issue, issue type: ENHANCEMENT, status: deferred

### Auto-Draft Handover

Read `.sdd/lib/prompts/log/flush.md` and follow its instructions, then auto-draft `handover.md`:
1. Read current handover.md
2. Carry forward: Key Decisions, Warnings, Session Context
3. Update Immediate Next Action
4. Append self-review completion to Accomplished
5. Write with `**Mode**: auto-draft`

Report completion to user with summary: verdict, disposition, counts, batch number.
