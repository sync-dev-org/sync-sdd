# Review Context

Review type: {{REVIEW_TYPE}}
Feature: {{FEATURE}}
Scope: {{SCOPE}}
Output: {{OUTPUT_PATH}}
SDD_DIR: .sdd

## Self-Resolved Context

Read the following files and extract the relevant sections. If a file does not exist, skip it silently.

- **Steering Exceptions**: Read `.sdd/session/handover.md`, extract the `### Steering Exceptions` section content. Apply these as review exemptions.
- **Previously Resolved Issues**: Read `{{VERDICTS_PATH}}` (if provided below), extract issues marked as resolved in the latest batch. Do NOT re-flag resolved items — only flag if regression (severity escalation).
- **SelfCheck Warnings** (impl review only): Read the spec's `tasks.yaml`, look for tasks with `selfcheck: WARN`. Treat as attention points, not authoritative findings.

Verdicts path: {{VERDICTS_PATH}}

{{WEB_SERVER_URL}}

## PROHIBITED COMMANDS (MUST NEVER execute)

{{DENY_PATTERNS}}
