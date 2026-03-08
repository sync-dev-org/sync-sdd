---
name: sdd-review-self
description: "Framework self-review for sync-sdd development repo. Runs automated code quality review using external engines (Codex CLI, Claude Code headless, Gemini CLI) or SubAgents against framework/ directory. Use this skill for self-review, framework review, review-self, quality check on framework files, code review of SDD framework, verify framework consistency, check framework compliance, audit framework changes, run self-review pipeline."
argument-hint: "[--briefer-engine E] [--inspector-engine E] [--auditor-engine E] [--builder-engine E] [--briefer-model M] [--inspector-model M] [--auditor-model M] [--builder-model M] [--briefer-effort low|medium|high] [--inspector-effort low|medium|high] [--auditor-effort low|medium|high] [--builder-effort low|medium|high]"
allowed-tools: Read Write Edit Glob Grep Bash Agent Skill
---

# sdd-review-self

Self-review pipeline for the sync-sdd framework development repository. Dispatches external engines or SubAgents to review `framework/` for flow integrity, cross-file consistency, and platform compliance.

## Gate Check

1. Verify `framework/` directory exists. If absent, report "This skill targets the sync-sdd framework repo only. framework/ not found." and stop.

## Step 1: Parse Arguments

Parse `$ARGUMENTS` for per-stage overrides. Each stage (briefer, inspectors, auditor, builder) accepts `--{stage}-engine`, `--{stage}-model`, `--{stage}-effort`. Unspecified stages use the level chain from engines.yaml.

## Step 2: Resolve Engine Levels

Read `.sdd/settings/engines.yaml`. For each stage (briefer, inspectors, auditor, builder):
1. If argument override provided, use that engine/model/effort directly.
2. Otherwise, check `session/state.yaml` for sticky escalated level. If present, use it.
3. Otherwise, use `roles.review-self.stages.{stage}.start_level` to look up engine/model/effort from `levels`.

For each resolved engine (codex/claude/gemini), run `install_check` from engines.yaml. On failure, escalate to the next level in the chain. If all external levels fail, fall back to L0 (subagents). Record escalated level in `session/state.yaml` (sticky for session).

## Step 3: Prepare Scope Directory

```
SCOPE_DIR = .sdd/project/reviews/self
ACTIVE = $SCOPE_DIR/active/
```

If `active/` exists and contains files, remove all files in it (stale from interrupted run). Create `active/` if it does not exist.

Determine `B_SEQ`: read `$SCOPE_DIR/verdicts.yaml`. If it exists, next seq = max(batches[].seq) + 1. Otherwise, seq = 1.

## Step 4: Dispatch Briefer

Read `${CLAUDE_SKILL_DIR}/references/briefer.md` for the full Briefer instructions.

Build the Briefer prompt by prepending the scope paths:
```
Output directory: {ACTIVE}
Template directory: ${CLAUDE_SKILL_DIR}/references/
Verdicts file: {SCOPE_DIR}/verdicts.yaml
```

Dispatch the Briefer using the resolved engine for the `briefer` stage.

### Dispatch Modes (applies to all stages)

Determine dispatch mode from engine type and environment:

**SubAgent mode** (engine = subagents): Dispatch via Agent tool with `run_in_background: true`. Pass the prompt content and instruct the SubAgent to Read the referenced files itself.

**tmux mode** (external engine + $TMUX set): Use Pattern B (One-Shot Command) from tmux-integration.md.
- Assign an idle slot from `session/state.yaml` grid section.
- Build engine command (see Engine Command Construction below).
- `tmux send-keys -t {pane_id} '{prompt_delivery} | {engine_cmd}; tmux wait-for -S {channel}' Enter`
- Update state.yaml slot: status -> busy, agent -> "briefer", engine -> "{engine}", channel -> "{channel}".
- Wait via `Bash(run_in_background=true)`: `tmux wait-for {channel}`
- On completion: update state.yaml slot back to idle.

**Background mode** (external engine + no tmux): `Bash(run_in_background=true)` with the engine command. No slot management.

### Engine Command Construction

| Engine | Command Pattern |
|--------|----------------|
| codex | `npx -y @openai/codex exec --full-auto -m {model} -c model_reasoning_effort='"{effort}"' -q` |
| claude | `env -u CLAUDECODE claude -p - --model {model} --output-format stream-json --verbose --dangerously-skip-permissions` piped to `jq -rjf .sdd/settings/scripts/claude-stream-progress.jq` with `CLAUDE_CODE_EFFORT_LEVEL={effort}` env prefix |
| gemini | `npx -y @google/gemini-cli -p --model {model} --yolo` |

For codex/claude: prompt is delivered via stdin pipe (`cat {prompt_file} | {engine_cmd}`).
For gemini: prompt is passed as the last positional argument (read prompt file content and pass inline).
For subagents with effort=high: include "ultrathink" keyword in prompt.

### Briefer Completion

After Briefer completes, verify `active/briefer-status.md` does not contain `NO_CHANGES`. If it does, report "No framework changes detected. Nothing to review." and stop.

Verify `active/shared-prompt.md` exists. Read `active/dynamic-manifest.md` to learn the count and names of dynamic Inspectors.

## Step 5: Dispatch Inspectors (Parallel)

Dispatch all Inspectors in parallel: 3 fixed (flow, consistency, compliance) + N dynamic (from manifest).

Each Inspector receives: `cat {ACTIVE}/shared-prompt.md {ACTIVE}/inspector-{name}.md`

For tmux mode, use staggered parallel dispatch (0.5s intervals) + hold-and-release pattern:
- Channel per Inspector: `sdd-{SID}-inspector-{name}-B{B_SEQ}`
- Close channel (shared): `sdd-{SID}-close-B{B_SEQ}`
- Command chain: `{prompt_delivery} | {engine_cmd}; tmux wait-for -S {channel}; tmux wait-for {close_channel}`
- Assign slots from state.yaml. If slots insufficient, overflow Inspectors use background mode.
- Issue all send-keys + wait-for via single batch of `Bash(run_in_background=true)` calls with sleep stagger.
- Wait for all Inspector channels (task-notification per background wait).

For SubAgent mode: dispatch all via Agent tool with `run_in_background: true`. Each Inspector reads shared-prompt.md and its own inspector prompt file.

For background mode: dispatch all via `Bash(run_in_background=true)`.

### Runtime Escalation (applies to all stages)

After a stage completes, check for the expected output file. If missing:
1. Capture failure output (tmux: capture-pane; background: task output).
2. Classify failure:
   - **ENGINE_FAILURE**: API 5xx, rate limit (429), connection error, timeout. Skip same engine, jump to next engine type (codex -> claude L5, claude -> L0).
   - **LEVEL_FAILURE**: empty output, YAML syntax error, agent produced no findings file. Advance to next level in chain.
   - Ambiguous -> treat as ENGINE_FAILURE (conservative).
3. Re-dispatch the failed Inspector with the escalated engine.
4. Record escalation via `/sdd-log issue` (type: BUG, summary: "Runtime escalation: {inspector} {failure_type} at {level}").
5. If L0 also fails -> mark Inspector as "did not complete". Auditor proceeds with available findings.

### Inspector Completion

After all Inspectors complete (or fail), verify findings files exist in `active/`:
- `findings-inspector-flow.yaml`
- `findings-inspector-consistency.yaml`
- `findings-inspector-compliance.yaml`
- `findings-inspector-dynamic-{N}-{slug}.yaml` (per manifest)

For tmux mode: release all slots by sending the close channel signal (`tmux wait-for -S {close_channel}`), then update all slot statuses to idle in state.yaml.

## Step 6: Dispatch Auditor

Read `${CLAUDE_SKILL_DIR}/references/auditor.md` for the full Auditor instructions.

Build the Auditor prompt listing the available findings files and the decisions.yaml path.

Dispatch using the resolved engine for the `auditor` stage. Same dispatch mode logic as Step 4.

### Auditor Completion

Verify `active/verdict-auditor.yaml` exists. Apply runtime escalation if missing.

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
- `approved` -> will be fixed by Builder
- `rejected` -> move to `fp_eliminated` (user-confirmed FP)
- `deferred` -> add to `tracked`, record via `/sdd-log issue` (type: ENHANCEMENT, status: deferred)

Update `verdict.yaml` with `user_decision` for each item.

For **A items**: auto-approved (present for visibility, proceed to Builder without waiting).

## Step 8: Dispatch Builder

Collect all items with `user_decision: approved` (A items auto-approved + user-approved B items). If none, skip to Step 9.

Read `${CLAUDE_SKILL_DIR}/references/builder.md`. Build the Builder prompt by expanding placeholders:
- `{{DENY_PATTERNS}}`: from engines.yaml
- `{{FINDINGS}}`: YAML list of approved items (id, location, detail, recommendation)
- `{{TEST_CMD}}`: empty (framework has no test suite)
- `{{OUTPUT_PATH}}`: `active/builder-report.yaml`

Dispatch using the resolved engine for the `builder` stage. Same dispatch mode logic.

### Builder Completion

Read `active/builder-report.yaml`. For each item:
- `result: fixed` -> set `resolution: fixed` in verdict.yaml
- `result: skipped` -> set `resolution: deferred` in verdict.yaml, record reason

Update verdict.yaml with resolution fields.

## Step 9: Verdict Persistence

### Update verdicts.yaml

Append a new batch entry to `$SCOPE_DIR/verdicts.yaml` following verdict-format.md Section 4:

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
    builder: "{actual model used, or omit if no Builder}"
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
mv $SCOPE_DIR/active $SCOPE_DIR/B{B_SEQ}
```

### Deferred Items

For any items with `user_decision: deferred`, record each via `/sdd-log issue` if not already recorded in Step 7.

### Auto-Draft Handover

Invoke `/sdd-log flush` then auto-draft `handover.md`:
1. Read current handover.md
2. Carry forward: Key Decisions, Warnings, Session Context
3. Update Immediate Next Action
4. Append self-review completion to Accomplished
5. Write with `**Mode**: auto-draft`

Report completion to user with summary: verdict, disposition, counts, batch number.
