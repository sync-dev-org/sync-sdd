# Engine Dispatch — Runtime Escalation

Error handling for engine dispatch failures. Read this prompt when an expected output file is missing after a stage completes.

## Failure Detection

After a stage completes, check for the expected output file. If missing, proceed with escalation.

## Step 1: Capture Failure Output

- **tmux mode**: `tmux capture-pane -t {pane_id} -p` — capture the last visible output.
- **background mode**: Read the task output from the completed Bash command.
- **SubAgent mode**: Read the Agent return value.

## Step 2: Classify Failure

Analyze the captured output to determine failure type:

### ENGINE_FAILURE
API-level or infrastructure failures. Indicators:
- HTTP 5xx responses
- Rate limit errors (429, "rate limit", "quota exceeded")
- Connection errors ("connection refused", "ECONNREFUSED", "timeout")
- Authentication errors ("unauthorized", "invalid API key")
- Timeout: agent exceeds the resolved timeout value. For tmux: send `C-c` to terminate before re-dispatch.

### LEVEL_FAILURE
Agent completed but produced unusable output. Indicators:
- Empty output (no content written)
- YAML syntax error in output file
- Output file exists but contains no `issues` section
- Agent produced output in wrong format

### Ambiguous
If the failure type cannot be determined from the captured output, treat as ENGINE_FAILURE (conservative — switching engines is safer than retrying the same one).

## Step 3: Escalate

### ENGINE_FAILURE Escalation
Skip the same engine entirely and jump to the next engine type:
- **codex** → claude L5
- **claude** → L0 (subagents)
- **gemini** → claude L5

### LEVEL_FAILURE Escalation
Advance to the next level within the chain:
- L1 → L2 → L3 → L4 → L5 → L6 → L7 → L0

If the next level uses the same engine that just failed with ENGINE_FAILURE, skip it.

### Timeout Escalation
Treat as ENGINE_FAILURE — escalate to a different engine, not just a higher level in the same engine. Timeouts often indicate systemic API issues.

## Step 4: Re-dispatch

Re-dispatch the failed agent with the escalated engine/model/effort. Follow the same dispatch mode logic from `engine.md` Section 3.

Record the escalated level in `.sdd/session/state.yaml` (sticky for session).

## Step 5: Record Issue

Record the escalation event:
- Read `.sdd/lib/prompts/log/record.md` and follow its instructions
- type: `issue`
- issue type: BUG
- severity: M
- summary: `"Runtime escalation: {agent_name} {failure_type} at {level}"`
- detail: Include the failure classification, captured output summary, and escalation target

## Step 6: Terminal Failure

If L0 (subagents) also fails:
- Mark the agent as "did not complete"
- The consuming pipeline (Auditor, Lead) proceeds with available findings
- Do not retry further — report to user
