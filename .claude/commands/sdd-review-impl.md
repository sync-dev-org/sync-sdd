---
description: Validate implementation against requirements, design, and tasks
allowed-tools: Bash, Glob, Grep, Read, LS
argument-hint: [feature-name] [task-numbers] | --cross-check
---

# SDD Implementation Review

<background_information>
- **Mission**: Verify that implementation aligns with approved requirements, design, and tasks
- **Two Modes**:
  - **Single Review** (`/sdd-review-impl {feature}`): Validate one feature's implementation
  - **Cross-Check** (`/sdd-review-impl` or `/sdd-review-impl --cross-check`): Consistency check across all implemented features
- **Success Criteria**:
  - All specified tasks marked as completed
  - Tests exist and pass for implemented functionality
  - Requirements traceability confirmed (EARS requirements covered)
  - Design structure reflected in implementation
  - No regressions in existing functionality
  - (Cross-Check) Consistent interfaces, types, and patterns across features
</background_information>

<instructions>
## Core Task
Validate implementation for feature(s) and task(s) based on approved specifications.

## Critical Review Principles

**DO NOT TRUST**:
- Mocked tests passing (mocks can hide interface mismatches)
- Design documents alone (implementation may have drifted)
- Test coverage numbers (tests may not verify actual contracts)

**MUST VERIFY BY READING ACTUAL SOURCE CODE**:
1. Read the ACTUAL implementation of each interface (not just design.md)
2. Read the ACTUAL call sites (not just what design.md says should happen)
3. Compare signatures character-by-character
4. Verify argument counts, types, and order match EXACTLY

**Common Failure Modes to Catch**:
- Function called with wrong number of arguments
- Function called with arguments in wrong order
- Return type mismatch between caller expectation and actual return
- Missing error handling for exceptions the callee can raise

## Mode Detection
- **If `$ARGUMENTS` contains feature name**: Execute Single Review Mode
- **If `$ARGUMENTS` is empty or `--cross-check`**: Execute Cross-Check Mode

## Flag Parsing
```
$ARGUMENTS = "{feature} {tasks}" → Single Review (specific tasks)
$ARGUMENTS = "{feature}"         → Single Review (all completed tasks)
$ARGUMENTS = "--cross-check"     → Cross-Check
$ARGUMENTS = ""                  → Cross-Check (auto-detect from history or scan)
```

**Note**: `--cross-check` is optional and equivalent to empty arguments. Use `--cross-check` for explicit documentation in procedures (e.g., flow.md).

---

## Mode 1: Single Review

### 1. Detect Validation Target

**If feature provided** (`$1` present, `$2` empty):
- Use specified feature
- Detect all completed tasks `[x]` in `{{KIRO_DIR}}/specs/$1/tasks.md`

**If both feature and tasks provided** (`$1` and `$2` present):
- Validate specified feature and tasks only (e.g., `user-auth 1.1,1.2`)

### 2. Load Context

For each detected feature:
- Read `{{KIRO_DIR}}/specs/<feature>/spec.json` for metadata
- Read `{{KIRO_DIR}}/specs/<feature>/requirements.md` for requirements
- Read `{{KIRO_DIR}}/specs/<feature>/design.md` for design structure
- Read `{{KIRO_DIR}}/specs/<feature>/tasks.md` for task list
- **Load ALL steering context**: Read entire `{{KIRO_DIR}}/steering/` directory including:
  - Default files: `structure.md`, `tech.md`, `product.md`
  - All custom steering files (regardless of mode settings)

### 2.5. Load Dependency Implementations (CRITICAL)

**Before validating, read the ACTUAL source code of all dependencies**:

1. From design.md, extract all "Outbound" dependencies
2. For EACH dependency, locate and READ the actual source file
3. Extract the real function/method signatures from source code
4. Store these for comparison during validation

Example:
```
design.md says: Outbound: create_app(), set_notifier()
→ Read: src/soseki_alive/api/__init__.py
→ Extract actual signatures:
  - def create_app() -> FastAPI
  - def set_notifier(notifier: SlackNotifier) -> None
```

**This step prevents the failure mode where implementation calls a function
with the wrong signature because the reviewer only checked design.md,
not the actual dependency implementation.**

### 3. Execute Validation

For each task, verify:

#### Task Completion Check
- Checkbox is `[x]` in tasks.md
- If not completed, flag as "Task not marked complete"

#### Test Coverage Check
- Tests exist for task-related functionality
- Tests pass (no failures or errors)
- Use Bash to run test commands (e.g., `npm test`, `pytest`)
- If tests fail or don't exist, flag as "Test coverage issue"

#### Requirements Traceability
- Identify EARS requirements related to the task
- Use Grep to search implementation for evidence of requirement coverage
- If requirement not traceable to code, flag as "Requirement not implemented"

#### Design Alignment (CRITICAL)

**A. Interface Signature Verification**:
1. Extract ALL function/method signatures from design.md code blocks
2. For EACH signature, read the actual implementation file
3. Compare parameter names, types, and order EXACTLY
4. Flag ANY mismatch as "Critical: Interface signature mismatch"

Example check:
```
Design: def set_notifier(notifier: SlackNotifier) -> None
Implementation: def set_notifier(app: FastAPI, notifier: SlackNotifier) -> None
→ CRITICAL: Parameter count mismatch (design: 1, impl: 2)
```

**B. Call Site Verification**:
1. Use Grep to find ALL call sites for each interface defined in design
2. Verify arguments at call site match the ACTUAL implementation signature
3. Flag mismatches as "Critical: Call site does not match implementation"

Example check:
```
Design shows: set_notifier(notifier)
Call site uses: set_notifier(api_app, notifier)
→ CRITICAL: Call site arguments don't match design
```

**C. Dependency Import Verification**:
1. For each "Outbound" dependency in design.md, verify import exists
2. Verify imported function/class signatures match design expectations
3. Flag missing imports as "Critical: Missing dependency import"

**D. File Structure Verification**:
- Use Grep/LS to confirm file structure matches design
- Verify key components and modules exist at expected paths
- If misalignment found, flag as "Warning: Design deviation"

**IMPORTANT**: Do NOT rely on mocked tests passing. Read and compare ACTUAL source code against design specifications.

#### Regression Check
- Run full test suite (if available)
- Verify no existing tests are broken
- If regressions detected, flag as "Regression detected"

### 4. Generate Report

Provide summary in the language specified in spec.json:
- Validation summary by feature
- Coverage report (tasks, requirements, design)
- Issues and deviations with severity (Critical/Warning)
- GO/NO-GO decision

---

## Mode 2: Cross-Check

### Execution Steps

1. **Discover Implemented Features**:
   - Parse conversation history for `/sdd-impl <feature>` commands
   - If no history found, scan `{{KIRO_DIR}}/specs/` for features with:
     - `spec.json` containing `"implementation": {"completed": true}` OR
     - `tasks.md` with completed tasks `[x]`
   - Report detected implementations (e.g., "Detected: config-management, shared-logger")

2. **Load All Implementation Context**:
   - For each implemented feature, read:
     - `{{KIRO_DIR}}/specs/<feature>/design.md` for interface definitions
     - Implementation source files (from `spec.json` implementation.files_created)
   - **Load ALL steering context**: Read entire `{{KIRO_DIR}}/steering/` directory

3. **Execute Cross-Check**:

   #### A. Interface Consistency Check
   - Verify shared modules are imported and used consistently
   - Check function signatures match across call sites
   - Flag: Inconsistent import patterns (e.g., `from config import get_settings` vs `import config`)
   - Flag: Different calling conventions for same function

   #### B. Type Consistency Check
   - Verify same data structures use consistent types across features
   - Check return types match expected input types at integration points
   - Flag: Type mismatches at boundaries (e.g., `str` vs `HttpUrl`)
   - Flag: Inconsistent Optional/None handling

   #### C. Error Handling Consistency Check
   - Verify custom exceptions (ConfigError, etc.) are used consistently
   - Check error propagation patterns match across features
   - Flag: Inconsistent exception types for similar errors
   - Flag: Swallowed exceptions that should propagate

   #### D. Dependency Implementation Check
   - Verify design.md dependencies are actually imported
   - Check integration points defined in design are implemented
   - Flag: Missing imports for declared dependencies
   - Flag: Undeclared dependencies that are used

   #### E. Pattern Consistency Check
   - Verify coding patterns match across features (naming, structure)
   - Check logging patterns are consistent (log levels, message format)
   - Flag: Inconsistent naming conventions
   - Flag: Different patterns for similar operations

4. **Run Integration Test Suite**:
   - If integration tests exist, run them
   - Verify cross-feature interactions work correctly
   - Flag any integration test failures

5. **Generate Cross-Check Report**:

```markdown
## Cross-Check Report

### Features Analyzed
| Feature | Status | Files | Tests |
|---------|--------|-------|-------|
| config-management | ✅ Implemented | 2 | 39 |
| shared-logger | ✅ Implemented | 1 | 34 |

### Cross-Spec Issues

#### Critical Issues
| ID | Type | Features Affected | Description |
|----|------|-------------------|-------------|
| C1 | Interface Mismatch | feature-a, feature-b | ... |

#### Warnings
| ID | Type | Features Affected | Description |
|----|------|-------------------|-------------|
| W1 | Pattern Inconsistency | feature-a, feature-b | ... |

### Integration Assessment
- **Interface Compatibility**: GO / NO-GO
- **Type Safety**: GO / NO-GO
- **Error Handling**: GO / NO-GO
- **Overall**: GO / CONDITIONAL / NO-GO
```

## Important Constraints

### Single Review
- **Conversation-aware**: Prioritize conversation history for auto-detection
- **Non-blocking warnings**: Design deviations are warnings unless critical
- **Test-first focus**: Test coverage is mandatory for GO decision
- **Traceability required**: All requirements must be traceable to implementation

### Cross-Check
- **Implementation required**: Only check features with completed implementations
- **Integration focus**: Prioritize cross-feature compatibility over internal details
- **Pattern enforcement**: Flag inconsistencies even if individually correct
- **Actionable feedback**: Every issue must specify which features need coordination
</instructions>

## Tool Guidance
- **Conversation parsing**: Extract `/sdd-impl` patterns from history
- **Read context**: Load all specs and steering before validation
- **Bash for tests**: Execute test commands to verify pass status
- **Grep for traceability**: Search codebase for requirement evidence
- **LS/Glob for structure**: Verify file structure matches design

## Output Description

Provide output in the language specified in spec.json with:

1. **Detected Target**: Features and tasks being validated (if auto-detected)
2. **Validation Summary**: Brief overview per feature (pass/fail counts)
3. **Issues**: List of validation failures with severity and location
4. **Coverage Report**: Requirements/design/task coverage percentages
5. **Decision**: GO (ready for next phase) / NO-GO (needs fixes)

**Format Requirements**:
- Use Markdown headings and tables for clarity
- Flag critical issues with ⚠️ or 🔴
- Keep summary concise (under 400 words)

## Safety & Fallback

### Error Scenarios

**Single Review**:
- **No Implementation Found**: If no `/sdd-impl` in history and no `[x]` tasks, report "No implementations detected"
- **Test Command Unknown**: If test framework unclear, warn and skip test validation (manual verification required)
- **Missing Spec Files**: If spec.json/requirements.md/design.md missing, stop with error
- **Language Undefined**: Default to English (`en`) if spec.json doesn't specify language

**Cross-Check**:
- **No Implementations Found**: If no completed implementations, report "No implementations to cross-check. Run `/sdd-impl` first."
- **Single Implementation**: If only one feature implemented, report "Cross-check requires 2+ implementations. Use `/sdd-review-impl {feature}` for single review."
- **Missing Source Files**: If implementation files not found, warn and skip that feature

### Next Steps Guidance

**After Single Review**:

**If GO Decision**:
- Implementation validated and ready
- Proceed to deployment or next feature

**If NO-GO Decision**:
- Address critical issues listed
- Re-run `/sdd-impl <feature> [tasks]` for fixes
- Re-review with `/sdd-review-impl [feature] [tasks]`

**After Cross-Check**:

**If GO Decision**:
- All implementations are compatible
- Safe to proceed with integration or next wave

**If CONDITIONAL Decision**:
- Minor inconsistencies detected
- Can proceed but should address warnings before production

**If NO-GO Decision**:
- Critical compatibility issues found
- Fix issues in affected features before integration
- Re-run `/sdd-review-impl --cross-check` after fixes

**Note**: Cross-check is recommended after completing a wave of implementations to ensure compatibility before proceeding to dependent features.
