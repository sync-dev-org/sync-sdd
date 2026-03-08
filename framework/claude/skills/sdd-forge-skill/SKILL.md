---
name: sdd-forge-skill
description: "Create, rebuild, improve, evaluate, compare, and optimize AI agent skills. Use this skill whenever the user wants to make a skill, create a skill, turn something into a skill, improve a skill, edit a skill, fix a skill, reforge a skill, rebuild a skill from scratch, regenerate a skill, test a skill, run evals, benchmark a skill, compare skill versions, check if a new version is better, optimize a skill description, or improve skill triggering. Covers the full skill lifecycle from idea to polished, tested, well-triggering skill."
---

# Skill Forge

Adapted from [anthropics/skills](https://github.com/anthropics/skills) (Apache 2.0). See LICENSE.txt.

Create, rebuild, improve, evaluate, compare, and optimize AI agent skills through iterative development.

## Modes

| Mode | Purpose | Entry |
|------|---------|-------|
| `create` | Interview user, draft skill, eval, iterate | "make a skill", "create a skill", "turn this into a skill" |
| `reforge` | Rebuild existing skill from scratch via requirements extraction | "reforge skill", "rebuild skill", "regenerate skill" |
| `improve` | Iterate on existing skill with feedback | "improve skill", "edit skill", "fix skill" |
| `eval` | Run test cases, grade, benchmark, review | "test skill", "run evals", "benchmark" |
| `compare` | Blind A/B comparison of two skill versions | "compare versions", "is the new version better?" |
| `optimize-description` | Automated description optimization loop | "optimize description", "improve triggering" |

The core loop, regardless of mode:

- Figure out what the skill should do
- Draft or edit the skill (via SubAgent)
- Run claude-with-access-to-the-skill on test prompts
- Evaluate the outputs with the user (quantitative benchmarks + qualitative review via HTML viewer)
- Iterate until satisfied
- Optionally optimize the description for better triggering

Figure out where the user is in this process and help them progress. Be flexible — if the user says "just vibe with me", skip the formal eval/benchmark loop.

## Communicating with the User

The skill forge is used by people across a wide range of technical familiarity. Pay attention to context cues:

- "evaluation" and "benchmark" are borderline but OK for most users
- "JSON" and "assertion" — look for cues that the user knows what these mean before using them without a brief explanation
- When in doubt, briefly explain a term inline

## Script Execution

All Python scripts are at `${CLAUDE_SKILL_DIR}/scripts/` and `${CLAUDE_SKILL_DIR}/eval-viewer/`. Use `env` prefix with `PYTHONPATH` — bare `PYTHONPATH=... python` triggers Claude Code's environment variable prefix heuristic:

```bash
env PYTHONPATH=${CLAUDE_SKILL_DIR} python -m scripts.<module_name> <args>
```

Example:
```bash
env PYTHONPATH=${CLAUDE_SKILL_DIR} python -m scripts.run_loop --eval-set eval.json --skill-path ./my-skill --model claude-sonnet-4-6 --verbose
```

For non-module scripts (eval-viewer), use the full path:
```bash
env PYTHONPATH=${CLAUDE_SKILL_DIR} python ${CLAUDE_SKILL_DIR}/eval-viewer/generate_review.py <args>
```

---

## Mode: Create

### Step 1: Interview

Gather from the user (extract from conversation history first if context already exists):

1. What should this skill enable Claude to do?
2. When should this skill trigger? (concrete phrases/contexts)
3. What's the expected output format?
4. Should we set up test cases? (suggest based on skill type — objective outputs benefit from evals, subjective ones often don't)

Proactively ask about edge cases, dependencies, and example files. Keep it conversational — don't over-interview.

### Step 2: Dispatch Writer

Spawn a generic `Agent()` with `run_in_background: true`. The prompt should include:

1. **Read instruction**: "Read `${CLAUDE_SKILL_DIR}/references/writer.md` and follow its instructions."
2. **Mode**: `create`
3. **Skill name and path**: where to write the output
4. **Intent summary**: structured from the interview — purpose, trigger contexts, output format, edge cases, dependencies
5. **Project context paths**: `.sdd/session/decisions.yaml`, `.sdd/session/knowledge.yaml` (if they exist)
6. **Skill forge resources path**: `${CLAUDE_SKILL_DIR}` value

### Step 3: Review Draft

Read the writer's output. Check:
- Description has 5-10 keyword phrases and pushy tone
- Body is under 500 lines
- No `AskUserQuestion` in allowed-tools
- Instructions explain the why, not just rules

Present the draft to the user. If they want changes, re-dispatch in improve mode.

### Step 4: Eval (optional)

If the user wants to test, switch to Eval mode. Otherwise iterate on feedback.

---

## Mode: Reforge

Rebuild an existing skill from scratch. The key insight: requirements-only prompts produce higher quality than detailed specifications. Strip away implementation details and let the writer rediscover the best approach.

### Step 1: Backup

Use `mv` (not `cp`) for each file being reforged. Physical removal prevents the writer SubAgent from reading the old version — filesystem constraints are more reliable than prompt constraints.

```
mv {file} {file}.bak{N}
```

Increment N from 1. Check existing `.bak*` files to find the next available number. When multiple files are being reforged, issue all `mv` commands as parallel Bash calls in a single turn.

Reforge scope can include SKILL.md and any reference `.md` files the user specifies — not just SKILL.md alone. Scripts, assets, and other non-target files are excluded.

### Step 2: Extract Requirements

From the backed-up files, extract **what** the skill does, not **how**:

1. **Purpose**: What problem does this skill solve?
2. **Trigger contexts**: When should it activate? What user phrases?
3. **Core capabilities**: Essential things it must do (numbered list)
4. **Output expectations**: What the user expects when the skill completes
5. **Constraints**: Hard limits (line counts, format requirements, security rules)

Do NOT extract implementation details (step procedures, variable names, section headings). The goal is a clean brief that communicates intent without biasing the writer's design.

### Step 3: Scan External Interfaces

Catalog everything the skill touches:

1. **File references**: files the skill reads or writes (scripts, templates, session data)
2. **MCP dependencies**: any MCP servers
3. **Other skill interactions**: cross-skill triggers or references
4. **Tool dependencies**: required tools (Agent, Read, Bash, etc.)
5. **Environment expectations**: variables, CLI tools, runtime requirements

Present the inventory to the user for confirmation.

### Step 4: Dispatch Writer in Create Mode

Send requirements + interfaces only. No old implementation details. Include the explicit instruction: "Generate a completely fresh SKILL.md. Do NOT read the existing skill."

### Step 5: Diff Analysis

Compare old (.bak{N}) and new versions. Report:
- **Improvements**: cleaner structure, better description, removed cruft, fresh design decisions
- **Concerns**: missing capabilities, dropped interfaces, unhandled edge cases
- **Proposals**: suggested adjustments based on Lead's project knowledge

### Step 6: User Decision

- **Accept**: finalize the new version
- **Iterate**: re-reforge with adjusted requirements (new version becomes next .bak{N+1})
- **Improve**: switch to improve mode with the new version as base
- **Revert**: restore from a specific `.bak{N}`

---

## Mode: Improve

### Step 1: Collect Feedback

Read the existing skill. Ask the user what needs to change — specific complaints, eval results showing problems, benchmark regressions.

### Step 2: Dispatch Writer

Spawn `Agent()` with `run_in_background: true`:

1. **Read instruction**: "Read `${CLAUDE_SKILL_DIR}/references/writer.md` and follow its instructions."
2. **Mode**: `improve`
3. **Skill name and path**
4. **Feedback**: structured user complaints, benchmark data
5. **Project context paths** and **Skill forge resources path**

### Step 3: Iterate

How to think about improvements:

1. **Generalize from the feedback.** The user iterates on a few examples because it's fast, but the skill must work across many prompts. Avoid fiddly overfitty changes — try different metaphors or patterns instead.
2. **Keep the prompt lean.** Read the transcripts, not just outputs. If the skill wastes tokens on unproductive work, cut those parts.
3. **Explain the why.** Transmit understanding, not rules. A model that grasps the goal makes better decisions than one following rigid instructions.
4. **Look for repeated work.** If all test cases had the subagent writing the same helper script, bundle it in `scripts/`.

Re-eval if test cases exist. Present results. Keep going until the user is satisfied or feedback is all empty.

---

## Mode: Eval

Run test cases against a skill, grade assertions, aggregate into benchmark statistics, and present results in an HTML viewer for qualitative and quantitative review. This section is one continuous sequence — don't stop partway through.

### Step 1: Test Cases

Check for `evals/evals.json` in the skill directory. If absent, create 2-3 realistic test prompts — the kind of thing a real user would say. Share with the user for review.

Save to `evals/evals.json`. Don't write assertions yet — you'll draft them while runs are in progress.

```json
{
  "skill_name": "example-skill",
  "evals": [
    {
      "id": 1,
      "prompt": "User's task prompt",
      "expected_output": "Description of expected result",
      "files": []
    }
  ]
}
```

See `${CLAUDE_SKILL_DIR}/references/schemas.md` for the full schema.

### Step 2: Spawn All Runs

Put results in `<skill-name>-workspace/` as a sibling to the skill directory. Within the workspace, organize by iteration (`iteration-1/`, `iteration-2/`, etc.) and by test case (`eval-0/`, `eval-1/`, etc.).

Create all workspace directories in one Bash call upfront:
```bash
mkdir -p <workspace>/iteration-N/eval-0/{with_skill,without_skill}/outputs <workspace>/iteration-N/eval-1/{with_skill,without_skill}/outputs
```

For each test case, spawn **two** subagents **in the same turn** — with-skill and baseline. Don't do all with-skill first; launch everything at once so it all finishes around the same time.

**With-skill run**: Same prompt, with the skill loaded, save outputs to `<workspace>/iteration-N/eval-ID/with_skill/outputs/`.

**Baseline run** (depends on context):
- Creating a new skill → no skill at all, save to `without_skill/outputs/`
- Improving → the old version (snapshot to `<workspace>/skill-snapshot/` first), save to `old_skill/outputs/`

Write `eval_metadata.json` for each test case. Give descriptive names, not just "eval-0".

### Step 3: Draft Assertions While Runs Execute

Use the time productively. Draft quantitative assertions for each test case and explain them to the user. Good assertions are objectively verifiable with descriptive names that read clearly in the benchmark viewer.

Don't force assertions onto subjective skills (writing style, design quality) — those are better evaluated qualitatively.

Update `eval_metadata.json` and `evals/evals.json` with assertions once drafted.

### Step 4: Capture Timing Data

When each subagent completes, the task notification includes `total_tokens` and `duration_ms`. Save immediately to `timing.json` in the run directory — this data isn't persisted elsewhere.

```json
{
  "total_tokens": 84852,
  "duration_ms": 23332,
  "total_duration_seconds": 23.3
}
```

### Step 5: Grade, Aggregate, and Launch Viewer

Once all runs complete:

1. **Grade** — dispatch all grader subagents in a single turn (one `Agent()` per run, all with `run_in_background: true`). Each grader follows `${CLAUDE_SKILL_DIR}/references/grader.md` and saves `grading.json` in its run directory. The grading.json expectations array must use fields `text`, `passed`, and `evidence` — the viewer depends on these exact names. Wait for all grader notifications before proceeding.

2. **Aggregate + Analyze + Launch** — after all grading completes, do these in one turn:

   First, aggregate:
   ```bash
   env PYTHONPATH=${CLAUDE_SKILL_DIR} python -m scripts.aggregate_benchmark <workspace>/iteration-N --skill-name <name>
   ```
   Produces `benchmark.json` and `benchmark.md`. Put each with_skill version before its baseline counterpart.

   Then read `benchmark.json`, do an analyst pass (surface patterns the aggregate stats hide — see `${CLAUDE_SKILL_DIR}/references/analyzer.md`), and launch the viewer:
   ```bash
   env PYTHONPATH=${CLAUDE_SKILL_DIR} python ${CLAUDE_SKILL_DIR}/eval-viewer/generate_review.py <workspace>/iteration-N --skill-name "my-skill" --benchmark <workspace>/iteration-N/benchmark.json
   ```
   Run the viewer via `Bash(run_in_background=true)` — do not use `nohup ... &` (triggers `&` and `2>` security heuristics).

   For iteration 2+, pass `--previous-workspace <workspace>/iteration-<N-1>`.

   **Headless environments**: use `--static <output_path>` for a standalone HTML file. Feedback downloads as `feedback.json` when the user clicks "Submit All Reviews".

### What the User Sees

The **Outputs** tab shows one test case at a time: prompt, output files, previous output (iteration 2+), formal grades (if grading ran), and a feedback textbox.

The **Benchmark** tab shows stats: pass rates, timing, token usage for each configuration, with per-eval breakdowns and analyst observations.

Navigation via prev/next buttons or arrow keys. "Submit All Reviews" saves all feedback to `feedback.json`.

### Step 6: Read Feedback and Iterate

Read `feedback.json`. Empty feedback means the user thought it was fine. Focus improvements on test cases with specific complaints.

Kill the viewer when done: `kill $VIEWER_PID` (omit `2>/dev/null` — the `2>` redirect triggers security heuristics; tolerate stderr).

If improvements needed, switch to Improve mode, then rerun evals into `iteration-<N+1>/`.

---

## Mode: Compare

Blind A/B comparison for rigorous version comparison.

### Step 1: Run Evals for Both Versions

Execute the same eval set against both skill versions. Collect transcripts and outputs.

### Step 2: Blind Comparison

For each eval, dispatch a comparator subagent (`Agent()` with `run_in_background: true`). It receives outputs labeled A and B without knowing which version produced which. See `${CLAUDE_SKILL_DIR}/references/comparator.md`.

### Step 3: Post-Hoc Analysis

After blind comparison, dispatch the analyzer with full context (both skills revealed). It explains why the winner won and generates improvement suggestions. See `${CLAUDE_SKILL_DIR}/references/analyzer.md`.

### Step 4: Report

Present: winner, rubric scores, quality assessment, improvement suggestions. Let the user decide next steps.

---

## Mode: Optimize-Description

The description field is the primary mechanism that determines whether Claude invokes a skill. This mode automates optimization for better triggering.

### Step 1: Generate Trigger Eval Queries

Create 20 eval queries — a mix of should-trigger (8-10) and should-not-trigger (8-10). Save as JSON.

Queries must be realistic — concrete, specific, with detail (file paths, context about the user's situation, column names). Use varied lengths, some casual, some formal. Focus on edge cases, not clear-cut examples.

For **should-trigger**: different phrasings of the same intent, cases where the user doesn't name the skill explicitly but clearly needs it, uncommon use cases, competitive cases where this skill should win.

For **should-not-trigger**: near-misses that share keywords but need something different. "Write a fibonacci function" as a negative for a PDF skill is too easy. The negative cases should be genuinely tricky.

### Step 2: Review with User

Present queries via the HTML template:

1. Read `${CLAUDE_SKILL_DIR}/assets/eval_review.html`
2. Replace `__EVAL_DATA_PLACEHOLDER__` with the JSON array, `__SKILL_NAME_PLACEHOLDER__` and `__SKILL_DESCRIPTION_PLACEHOLDER__` with the skill's values
3. Write to temp file and open: `open /tmp/eval_review_<skill-name>.html`
4. User edits queries, toggles should-trigger, adds/removes entries, clicks "Export Eval Set"
5. Check `~/Downloads/` for the exported `eval_set.json`

### Step 3: Run Optimization Loop

```bash
env PYTHONPATH=${CLAUDE_SKILL_DIR} python -m scripts.run_loop --eval-set <path-to-eval-set.json> --skill-path <path-to-skill> --model <model-id-powering-this-session> --max-iterations 5 --verbose
```

Run via `Bash(run_in_background=true)` — this is a long-running process.

Use the model ID from the system prompt so triggering tests match the user's actual experience.

The loop splits queries into 60% train / 40% test, runs each query 3x for reliability, generates improved descriptions, and selects by test score (not train) to avoid overfitting. Up to 5 iterations.

### How Skill Triggering Works

Skills appear in Claude's `available_skills` list with name + description. Claude decides whether to consult a skill based on that. The key: Claude only consults skills for tasks it can't easily handle alone — simple one-step queries may not trigger even if the description matches. Complex, multi-step, or specialized queries reliably trigger when the description matches.

This means eval queries should be substantive enough that Claude would benefit from a skill. Simple queries like "read file X" are poor test cases.

### Step 4: Apply Results

Take `best_description` from the output and update the skill's frontmatter. Show before/after and report scores.

---

## Package and Present

If you have access to the `present_files` tool (check first — skip if not available):

```bash
env PYTHONPATH=${CLAUDE_SKILL_DIR} python -m scripts.package_skill <path/to/skill-folder>
```

Direct the user to the resulting `.skill` file.

## Reference Files

- `${CLAUDE_SKILL_DIR}/references/writer.md` — writer SubAgent instructions (create/improve modes)
- `${CLAUDE_SKILL_DIR}/references/comparator.md` — blind A/B comparator instructions
- `${CLAUDE_SKILL_DIR}/references/analyzer.md` — post-hoc analysis + benchmark analysis instructions
- `${CLAUDE_SKILL_DIR}/references/grader.md` — assertion grading instructions
- `${CLAUDE_SKILL_DIR}/references/schemas.md` — JSON schema definitions for the eval pipeline
- `${CLAUDE_SKILL_DIR}/references/skill-reference.md` — comprehensive skill authoring guide
- `${CLAUDE_SKILL_DIR}/references/skill-reference-sources.md` — reference guide update procedure

## Constraints

- SKILL.md body must be under 500 lines; use references/ for overflow
- Description must be pushy with 5-10 concrete keyword phrases
- Never include `AskUserQuestion` in allowed-tools (auto-approve bug causes empty responses)
- All SubAgent dispatches use `Agent()` with `run_in_background: true`
- Python scripts require `env PYTHONPATH=... python` (not bare `PYTHONPATH=...`) to avoid security heuristic
- Long-running scripts (`run_loop`, viewer) use `Bash(run_in_background=true)` — not `nohup ... &`
- Avoid `2>` stderr redirects — tolerate error output instead
- Adapt communication to user's technical level
- No project-specific IDs (D{seq}, K{seq}) in skill output — use the insight, not the reference
