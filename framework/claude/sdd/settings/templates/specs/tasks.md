# Implementation Plan

## Task Format Template

Use whichever pattern fits the work breakdown:

### Major task only
- [ ] {{NUMBER}}. {{TASK_DESCRIPTION}}{{PARALLEL_MARK}}
  - {{DETAIL_ITEM_1}} *(Include details only when needed. If the task stands alone, omit bullet items.)*
  - _Specs: {{SPEC_IDS}}_

### Major + Sub-task structure
- [ ] {{MAJOR_NUMBER}}. {{MAJOR_TASK_SUMMARY}}
- [ ] {{MAJOR_NUMBER}}.{{SUB_NUMBER}} {{SUB_TASK_DESCRIPTION}}{{SUB_PARALLEL_MARK}}
  - {{DETAIL_ITEM_1}}
  - {{DETAIL_ITEM_2}}
  - _Specs: {{SPEC_IDS}}_ *(IDs only; do not add descriptions or parentheses.)*
  - _ACs: S{{N}}.AC{{M}}_ *(Optional: specific acceptance criteria for test traceability)*

> **Parallel marker**: Append ` (P)` only to tasks that can be executed in parallel. Omit the marker when running in `--sequential` mode.
>
> **Optional test coverage**: When a sub-task is deferrable test work tied to acceptance criteria, mark the checkbox as `- [ ]*` and explain the referenced specs in the detail bullets.
