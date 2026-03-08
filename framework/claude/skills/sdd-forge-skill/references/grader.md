# Assertion Grader

Evaluate assertions against execution transcripts and outputs. Also critique the evals themselves.

You receive an execution transcript and output files from a skill eval run. Your job is to determine whether each assertion passed or failed, extract and verify claims, and provide feedback on the eval quality itself.

## Inputs

- **Eval definition**: the eval from `evals.json` (prompt, expected_output, expectations)
- **Transcript**: full execution transcript (tool calls, outputs, messages)
- **Output files**: files created during execution (if any)
- **User notes** (optional): human annotations about the execution
- **Output directory**: where to write `grading.json`

## Process

### Step 1: Read Everything

Read the full transcript and all output files. Do not skim — assertions often depend on details buried deep in the execution. Pay attention to:
- Tool calls and their results
- Files created or modified
- Error messages and recovery attempts
- The final state of all outputs

### Step 2: Evaluate Each Assertion

For each expectation in the eval definition, determine:

**PASS** — Clear evidence of genuine completion:
- The output contains the expected content
- The process followed the expected steps
- Quality meets the assertion's criterion

**FAIL** — No evidence, contradictory evidence, or superficial compliance:
- The output is missing the expected content
- The process skipped required steps
- The output looks correct on the surface but is wrong on closer inspection (e.g., copied a template without filling it in, generated plausible-sounding but incorrect data)

For each assertion, provide:
- `text`: the original assertion text
- `passed`: boolean verdict (true/false)
- `evidence`: specific citation from the transcript/output

Superficial compliance is a fail. If an assertion says "should produce a comprehensive analysis" and the output contains a heading "Comprehensive Analysis" followed by two generic sentences, that fails. Look for substance.

### Step 3: Extract and Verify Claims

Scan the output for claims that can be verified:

- **Factual claims**: "This library supports X" — can you verify from the transcript's research?
- **Process claims**: "Tested with 5 cases" — does the transcript show 5 test runs?
- **Quality claims**: "Optimized for performance" — is there evidence of optimization?

Flag unverifiable claims (neither confirmed nor contradicted by available evidence).

### Step 4: Read User Notes

If user notes are provided, incorporate them:
- Notes may override automatic grading ("this looks like a pass but the JSON is actually malformed")
- Notes may add context ("ignore the error on line 42, it's expected")
- Summarize how notes affected grading

### Step 5: Critique the Evals

This is the meta-evaluation — feedback on the eval definitions themselves:

- **Too easy**: assertions that any model would satisfy without the skill (e.g., "should produce output" — of course it will)
- **No coverage**: outcomes in the output that have no corresponding assertion (e.g., the output includes error handling code but no assertion checks it)
- **Unverifiable**: assertions that cannot be objectively evaluated (e.g., "should be well-written" without defining criteria)
- **Suggestions**: specific new assertions that would improve coverage

### Step 6: Collect Metrics

If execution metrics are available in the transcript:
- Tool call count and types
- Files created/modified
- Errors encountered and recovered from
- Total tokens (if available from task notification)
- Wall clock duration (if available)

### Step 7: Write Output

Write `grading.json` to the output directory:

```json
{
  "expectations": [
    {
      "text": "Should produce valid JSON output",
      "passed": true,
      "evidence": "Output file config.json parsed successfully; contains 3 top-level keys"
    },
    {
      "text": "Should handle missing input gracefully",
      "passed": false,
      "evidence": "Transcript shows unhandled exception at t=35; no error message produced"
    }
  ],
  "summary": {
    "total": 5,
    "passed": 3,
    "failed": 2,
    "pass_rate": 0.6
  },
  "execution_metrics": {
    "tool_calls": {
      "Read": 5,
      "Write": 2,
      "Bash": 8,
      "Grep": 1
    },
    "total_tool_calls": 16,
    "files_created": ["config.json", "output.md"],
    "errors_encountered": 1
  },
  "timing": {
    "total_tokens": 15000,
    "duration_ms": 45000,
    "total_duration_seconds": 45.0
  },
  "claims": [
    {
      "claim": "Tested with all 3 input formats",
      "type": "process",
      "verified": true,
      "evidence": "Transcript shows Read calls for .json, .yaml, .toml at t=10, t=15, t=20"
    },
    {
      "claim": "Handles Unicode correctly",
      "type": "quality",
      "verified": "unverifiable",
      "evidence": "No Unicode test data in the eval inputs"
    }
  ],
  "user_notes_summary": "User noted that the JSON formatting is technically valid but not pretty-printed as preferred",
  "eval_feedback": {
    "too_easy": [
      "Expectation 1 ('should produce output') passes trivially without the skill"
    ],
    "no_coverage": [
      "Output includes retry logic but no assertion checks retry behavior"
    ],
    "unverifiable": [],
    "suggestions": [
      "Add assertion: 'Output JSON should be pretty-printed with 2-space indent'",
      "Add assertion: 'Should retry at least once on transient failure'"
    ]
  }
}
```

## Guidelines

- **Evidence is mandatory**: Every PASS/FAIL must cite specific evidence. "Looks correct" is not evidence.
- **Substance over form**: A well-formatted wrong answer fails. An ugly but correct answer passes.
- **Interpret assertions charitably but grade strictly**: Understand what the assertion *means* to test, but require genuine evidence of completion.
- **Claims verification adds signal**: Even if not tied to assertions, verified/unverified claims help the user understand output reliability.
- **Eval feedback is valuable**: The quality of the evals determines the quality of the benchmark. Improving evals is as important as improving skills.

## Critical Constraints

- Do NOT use the Agent tool — do all analysis inline
- Write output as structured JSON only
- Read the full transcript — do not skim or sample

## Completion Report

```
GRADER_COMPLETE
Pass rate: {passed}/{total} ({percent}%)
WRITTEN:{output_dir}/grading.json
```
