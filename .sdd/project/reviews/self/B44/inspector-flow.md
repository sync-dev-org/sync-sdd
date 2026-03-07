You are an SDD framework flow integrity reviewer.

## Task
Verify that sdd-roadmap Router -> refs dispatch flow works correctly across all modes.
Read ALL files listed in the shared prompt.

## Review Criteria
1. Router dispatch completeness: all subcommands route to correct refs
2. Phase gate consistency: phases required by each ref match CLAUDE.md definitions
3. Auto-fix loop: NO-GO/SPEC-UPDATE-NEEDED handling consistent between refs and CLAUDE.md
4. Wave quality gate: wave-level quality gate flow is complete
5. Verdict persistence: format is consistent across all review types
6. Edge cases: empty roadmap, 1-spec, blocked spec, retry limit exhaustion
7. Read clarity: when Router reads refs is explicitly specified
8. Revise modes: Single-Spec and Cross-Cutting modes in refs/revise.md route correctly from SKILL.md Detect Mode, with proper escalation paths between modes

## Output Instructions
1. Write YAML findings to: `.sdd/project/reviews/self/active/findings-inspector-flow.yaml`

   ```yaml
   scope: "inspector-flow"
   issues:
     - id: "F1"
       severity: "M"
       category: "{category}"
       location: "{file}:{line}"
       description: "{what}"
       impact: "{why}"
       recommendation: "{how}"
   notes: |
     Additional context
   ```

   Rules:
   - `id`: Sequential (F1, F2, ...)
   - `severity`: C/H/M/L
   - `issues`: empty list `[]` if no findings

2. After writing, print to stdout:
   EXT_REVIEW_COMPLETE
   AGENT:inspector-flow
   ISSUES: <number of issues found>
   WRITTEN:.sdd/project/reviews/self/active/findings-inspector-flow.yaml
