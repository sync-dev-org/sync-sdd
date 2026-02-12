---
description: Detect dead code, unused settings, and orphaned specs
allowed-tools: Bash, Glob, Grep, Read, Write, Task
argument-hint: [--full] | [--settings] | [--code] | [--specs] | [--tests]
---

# SDD Dead Code Review

<background_information>
- **Mission**: Thoroughly detect dead code, unused settings, orphaned specs, and stale test code
- **Philosophy**:
  - Do NOT follow a checklist mechanically - conduct **autonomous, multi-angle investigation**
  - Create **throwaway Python scripts** for analysis when needed
  - Report anything suspicious - let humans make the final judgment
</background_information>

<instructions>

## Execution Strategy

**CRITICAL**: Launch 4 Explore agents **in parallel**, instructing each to conduct **thorough autonomous exploration**.

For each agent:
- Do NOT provide detailed checklists (inhibits autonomy)
- Provide only the goal and expected thoroughness level
- Encourage Python script creation for analysis
- Let agents discover project structure themselves

---

## Mode Detection

```
$ARGUMENTS = "--full" or ""  → 4 agents in parallel (Settings, Code, Specs, Tests)
$ARGUMENTS = "--settings"    → Settings only
$ARGUMENTS = "--code"        → Code only
$ARGUMENTS = "--specs"       → Specs only
$ARGUMENTS = "--tests"       → Tests only
```

---

## Agent Prompts

### Agent 1: Settings Audit

```
Thoroughly investigate the project's configuration management to detect "dead config".

Goal:
- Find config fields that are defined but never actually consumed
- Verify settings are properly passed from definition to final consumption point

Investigation approach (decide yourself):
1. First discover the project structure (find config files yourself)
2. Identify config classes/modules and extract all fields
3. For each field, thoroughly trace usage through the codebase
4. Create Python scripts for AST analysis or dependency tracing if needed
5. Verify the path "config → intermediate layer → final consumer" is not broken

Expected thoroughness:
- Go beyond simple grep - trace actual code flow
- Pay special attention to parameters with default values (missing passthrough still works)
- Report anything suspicious

Output: Usage status for each field, with detailed explanation for any issues found
```

### Agent 2: Dead Code Detection

```
Thoroughly investigate the project's source code to detect unused code.

Goal:
- Find functions/methods/classes that are defined but never called
- Identify code used only in tests, not in production
- Find code left for "future use" that is actually dead

Investigation approach (decide yourself):
1. First discover the project structure (find source directories yourself)
2. Enumerate all public symbols (functions, classes, methods)
3. Thoroughly search for call sites of each symbol
4. Create Python scripts for AST analysis or call graph generation if needed
5. Compare __all__ exports with actual usage

Expected thoroughness:
- Go beyond simple grep - trace actual call relationships
- Pay special attention to class methods (may be used internally but never called externally)
- Check usage via properties and decorators
- Report anything suspicious

Output: List of unused or suspicious symbols with detailed analysis
```

### Agent 3: Spec Alignment

```
Thoroughly investigate alignment between project specifications and implementation.

Goal:
- Find features specified but not implemented
- Find features implemented but not in specs
- Find specs that have drifted from implementation

Investigation approach (decide yourself):
1. First discover the project structure (find spec directories yourself)
2. Read each spec and understand expected implementation
3. Identify corresponding implementation files and compare with actual code
4. Cross-reference task completion status with actual implementation state
5. Create scripts for automated comparison if needed

Expected thoroughness:
- Compare interface definitions in specs with actual signatures
- Compare dependency diagrams in specs with actual import relationships
- Detect partial or incomplete implementations
- Report anything suspicious

Output: Alignment status for each spec, with detailed explanation for any drift
```

### Agent 4: Test Code Audit

```
Thoroughly investigate the project's test code to detect orphaned test code.

Goal:
- Find fixtures that are defined but never used
- Find tests that test non-existent functionality
- Find tests depending on outdated interfaces

Investigation approach (decide yourself):
1. First discover the project structure (find test directories yourself)
2. Enumerate all fixture definitions and trace their usage
3. Compare test imports with actual source symbols
4. Create Python scripts for fixture dependency analysis if needed
5. Detect unused imports as well

Expected thoroughness:
- Include conftest.py fixtures in the analysis
- Detect duplicate fixtures at class vs module level
- Trace indirect usage (via other fixtures)
- Report anything suspicious

Output: List of orphaned test code with detailed analysis
```

---

## Report Aggregation

Aggregate results from 4 agents into a unified report:

```markdown
# Dead Code Review Report

Generated: {timestamp}
Project: {project_name}

## Executive Summary

| Category | Issues | Critical | Warnings |
|----------|--------|----------|----------|
| Settings | ? | ? | ? |
| Code | ? | ? | ? |
| Specs | ? | ? | ? |
| Tests | ? | ? | ? |

## Verdict
- GO / CONDITIONAL / NO-GO

## Detailed Findings

[Detailed results per category]

## Recommended Actions

[Prioritized action list]
```

</instructions>

## Important Notes

- **Portability**: Do NOT hardcode project-specific paths. Agents discover structure themselves.
- **Thoroughness**: Provide goals, not checklists. Encourage autonomous exploration.
- **Tool usage**: Actively encourage Python script creation for analysis.
- **Report suspicious items**: Include uncertain findings - let humans decide.
