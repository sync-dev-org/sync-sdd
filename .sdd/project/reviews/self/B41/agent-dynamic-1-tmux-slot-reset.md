You are a targeted change reviewer for the SDD Framework self-review.

## Mission
Verify tmux-based dispatch lifecycle changes for `/sdd-review` and `/sdd-review-self` are consistent with existing Lead behavior and do not leave stale state when completion signaling differs.

## Change Context
Recent commits and working-tree changes add tmux pane title updates, dispatch completion messages, and idle-reset behavior in review/prep/inspector/auditor paths. These edits span `framework/claude/CLAUDE.md`, `framework/claude/skills/sdd-review.md`, and `framework/claude/skills/sdd-review-self.md`.

## Investigation Focus
1. Check whether every new `tmux select-pane -T ...` title assignment has a matching reset path on all completion branches.
2. Verify that reported messages (`Dispatched ... inspectors` / `Prep dispatched...` / `Auditor dispatched...`) are not emitted before wait/wait-for completion.
3. Confirm SubAgent mode paths exclude tmux title mutations and still return slot state to `idle`.
4. Ensure close/reset steps still clear `agent/engine/channel` consistently after each command path.

## Files to Examine
framework/claude/CLAUDE.md
framework/claude/skills/sdd-review.md
framework/claude/skills/sdd-review-self/SKILL.md

## Output
Write CPF to: .sdd/project/reviews/self/active/agent-dynamic-1-tmux-slot-reset.cpf
SCOPE:agent-dynamic-1-tmux-slot-reset

Follow the CPF format from the shared prompt (shared-prompt.md).

After writing CPF, print to stdout:
EXT_REVIEW_COMPLETE
AGENT:dynamic-1
ISSUES: <number of issues found>
WRITTEN:.sdd/project/reviews/self/active/agent-dynamic-1-tmux-slot-reset.cpf
