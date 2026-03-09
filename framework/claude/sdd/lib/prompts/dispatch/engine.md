# Engine Dispatch — Normal Path

Shared engine resolution, command construction, and dispatch mode instructions for review pipelines (sdd-review-self, sdd-review). For runtime failure handling (missing output, timeouts, API errors), see `.sdd/lib/prompts/dispatch/escalation.md`.

The calling Skill provides these context values before invoking this prompt:
- **ROLE_NAME**: e.g., `review-self`, `review`
- **STAGES**: list of stages to resolve (e.g., `briefer`, `inspectors`, `auditor`)
- **DEFAULT_TIMEOUT**: hardcoded fallback (e.g., 900)
- **Argument overrides**: per-stage `--{stage}-engine`, `--{stage}-model`, `--{stage}-effort`, `--timeout`

## 1. Engine Resolution

For each stage in STAGES:

1. If argument override provided (`--{stage}-engine`, `--{stage}-model`, `--{stage}-effort`), use those values directly.
2. Otherwise, check `.sdd/session/state.yaml` for sticky escalated level. If present, use it.
3. Otherwise, read `.sdd/settings/engines.yaml` and look up `roles.{ROLE_NAME}.stages.{stage}.start_level` to get the level key (e.g., `L4`). Resolve engine/model/effort from `levels.{level_key}`.
4. Resolve timeout: `--timeout` argument > `roles.{ROLE_NAME}.timeout` from engines.yaml > DEFAULT_TIMEOUT.

### Install Check

For each resolved engine (codex/claude/gemini), run the `install_check` command from `engines.yaml.engines.{engine}.install_check`.

- On success: proceed with resolved level.
- On failure: advance to the next level in the chain (L1→L2→L3→...→L7→L0). If the next level uses the same engine, skip it and continue advancing.
- If all external levels fail: fall back to L0 (subagents). L0 always passes (install_check = `true`).
- Record escalated level in `.sdd/session/state.yaml` under `escalation.{ROLE_NAME}.{stage}` (sticky for session).

## 2. Command Construction

| Engine | Command Pattern |
|--------|----------------|
| codex | `npx -y @openai/codex exec --full-auto --model {model} -c model_reasoning_effort='"{effort}"' -` |
| claude | `env -u CLAUDECODE claude -p - --model {model} --output-format stream-json --verbose --dangerously-skip-permissions` piped to `jq -rjf .sdd/settings/scripts/claude-stream-progress.jq` with `CLAUDE_CODE_EFFORT_LEVEL={effort}` env prefix (use `env` command for prefix) |
| gemini | `npx -y @google/gemini-cli -p --model {model} --yolo` |
| subagents | Map model name: names containing "spark" or "haiku" → `"haiku"`, "opus" → `"opus"`, otherwise → `"sonnet"`. With effort=high: include "ultrathink" keyword in prompt. |

For codex/claude: prompt is delivered via stdin pipe (`cat {prompt_files} | {engine_cmd}`).
For gemini: prompt is passed as the last positional argument (read prompt file content and pass inline).
For subagents: dispatch via Agent tool with `run_in_background: true`.

## 3. Dispatch Modes

Determine dispatch mode from engine type and environment:

### SubAgent Mode (engine = subagents)

Dispatch via Agent tool with `run_in_background: true`. Pass the prompt content and instruct the SubAgent to Read the referenced files itself. Lead does NOT Read the prompt files — instruct SubAgent to `Read {path} and follow its instructions`.

### tmux Mode (external engine + $TMUX set)

Use Pattern B (One-Shot Command) from `.sdd/lib/references/common/tmux-integration.md`.

1. Assign an idle slot from `.sdd/session/state.yaml` grid section.
2. Set pane title: `tmux select-pane -t {pane_id} -T '{agent_label} | {model}'` (best-effort, decoration only).
3. Build engine command per Section 2.
4. Send command: `tmux send-keys -t {pane_id} '{prompt_delivery} | {engine_cmd}; tmux wait-for -S {channel}' Enter`
5. Verify delivery: `pgrep -fl "tmux send-keys"` (exit 1 = normal). If residual process detected: report PID and kill — target pane did not accept the command.
6. Update `state.yaml` slot: status → busy, agent → `"{agent_label}"`, engine → `"{engine}"`, channel → `"{channel}"`.
7. Wait via `Bash(run_in_background=true)`: `tmux wait-for {channel}`
8. On completion: restore pane title `tmux select-pane -t {pane_id} -T 'sdd-{SID}-slot-{N}'` and update `state.yaml` slot back to idle (remove agent/engine/channel fields).

### Background Mode (external engine + no tmux)

Execute via `Bash(run_in_background=true)` with the engine command. No slot management.

### Parallel Dispatch

For dispatching multiple agents in parallel (e.g., Inspectors):

**Staggered dispatch**: Issue multiple `send-keys` with 0.5s sleep stagger in a single batch of `Bash(run_in_background=true)` calls:
```
Bash(run_in_background=true): sleep 0.0; tmux send-keys -t {pane1} '...' Enter
Bash(run_in_background=true): sleep 0.5; tmux send-keys -t {pane2} '...' Enter
Bash(run_in_background=true): sleep 1.0; tmux send-keys -t {pane3} '...' Enter
```

**Hold-and-release**: When all agents must complete before proceeding:
- Command chain per agent: `{prompt_delivery} | {engine_cmd}; tmux wait-for -S {channel}; tmux wait-for {close_channel}`
- `{channel}`: agent-specific completion signal (e.g., `sdd-{SID}-inspector-{name}-B{seq}`)
- `{close_channel}`: shared release signal (e.g., `sdd-{SID}-close-B{seq}`)
- Lead waits for all agent channels, reads results, then sends `tmux wait-for -S {close_channel}` to release all agents simultaneously.

**Slot overflow**: If all 12 slots are busy, fall back to `Bash(run_in_background=true)` for overflow agents.

**Completion detection**: Each `Bash(run_in_background=true)` wait-for completes via task-notification. Do not poll or use TaskOutput.
