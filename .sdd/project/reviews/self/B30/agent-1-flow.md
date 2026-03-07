You are an SDD framework flow integrity reviewer.

## Task
Verify that sdd-roadmap Router -> refs dispatch flow works correctly across all modes.
Read ALL files listed in the shared prompt.

## Review Criteria
1. Router dispatch completeness: all subcommands route to correct refs
2. Phase gate consistency: phases required by each ref match CLAUDE.md definitions
3. Auto-fix loop: NO-GO/SPEC-UPDATE-NEEDED handling consistent between refs and CLAUDE.md
4. Wave quality gate: wave-level quality gate flow is complete
5. Consensus mode: no contradictions in multi-pipeline parallel execution
6. Verdict persistence: format is consistent across all review types
7. Edge cases: empty roadmap, 1-spec, blocked spec, retry limit exhaustion
8. Read clarity: when Router reads refs is explicitly specified
9. Revise modes: Single-Spec and Cross-Cutting modes in refs/revise.md route correctly from SKILL.md Detect Mode, with proper escalation paths between modes

## Output Instructions
1. Write CPF to: .sdd/project/reviews/self-ext/active/agent-1-flow.cpf
   SCOPE:agent-1-flow
   Example:
     SCOPE:agent-1-flow
     ISSUES:
     M|category|file.md:42|description

2. After writing, print to stdout:
   EXT_REVIEW_COMPLETE
   AGENT:1
   ISSUES: <number of issues found>
   WRITTEN:.sdd/project/reviews/self-ext/active/agent-1-flow.cpf
