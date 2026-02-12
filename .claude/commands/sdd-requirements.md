---
description: Generate comprehensive requirements for a specification
allowed-tools: Bash, Glob, Grep, LS, Read, Write, Edit, MultiEdit, Update, WebSearch, WebFetch, AskUserQuestion
argument-hint: <feature-name-or-description>
---

# SDD Requirements Generation

<background_information>
- **Mission**: Initialize specifications and generate comprehensive, testable requirements in EARS format
- **Success Criteria**:
  - Create complete requirements document aligned with steering context
  - Follow the project's EARS patterns and constraints for all acceptance criteria
  - Focus on core functionality without implementation details
  - Update metadata to track generation status
</background_information>

<instructions>

## Step 1: Detect Current State

Check `{{KIRO_DIR}}/specs/` for the input **$1**:

```
input = $1
is_existing_feature = {{KIRO_DIR}}/specs/$1/ directory exists
```

**Backward Compatibility**: When reading an existing spec.json, if the `version` field is missing, treat as:
```
version = spec_json.version ?? "1.0.0"
changelog = spec_json.changelog ?? []
version_refs = spec_json.version_refs ?? {
  requirements: version,
  design: approvals.design.generated ? version : null,
  tasks: approvals.tasks.generated ? version : null
}
```
Persist these defaults on next write.

---

## Step 2: Route Based on Input

### Case A: Input is NOT an existing feature name

**Treat $1 as a project description and create new spec:**

1. **Generate Feature Name**:
   - Create a concise, kebab-case feature name from description
   - Check `{{KIRO_DIR}}/specs/` for naming conflicts (append number suffix if needed)
   - If ambiguous, propose 2-3 options via AskUserQuestion and let user select

2. **Create Directory Structure**:
   - Create `{{KIRO_DIR}}/specs/[feature-name]/`

3. **Initialize spec.json**:
   - Read `{{KIRO_DIR}}/settings/templates/specs/init.json`
   - Replace placeholders:
     - `{{FEATURE_NAME}}` → generated feature name
     - `{{TIMESTAMP}}` → current ISO 8601 timestamp
     - `{{LANG_CODE}}` → detect from user input or default to `en`
   - Set `phase: "requirements-generated"` (skip `initialized` phase)
   - Set `approvals.requirements.generated: true`
   - **Version initialization**:
     - Set `version: "1.0.0"`
     - Set `version_refs.requirements: "1.0.0"`
     - Append changelog entry: `{ "version": "1.0.0", "date": "{ISO_DATE}", "phase": "requirements", "summary": "Initial requirements" }`
   - Write to spec directory

4. **Generate Requirements Document**:
   - Load steering context from `{{KIRO_DIR}}/steering/`
   - Read `{{KIRO_DIR}}/settings/rules/ears-format.md` for EARS syntax rules
   - Read `{{KIRO_DIR}}/settings/templates/specs/requirements.md` for document structure
   - Generate complete requirements based on project description
   - Group related functionality into logical requirement areas
   - Apply EARS format to all acceptance criteria
   - Assign stability tags to each AC: `[constraint]` for immutable invariants, `[contract]` for interface agreements, `[behavior]` for changeable behavior (default)
   - Set `## Detail Level: normal` header (or `interface` if user provides a brief/sketch description)
   - Write to `{{KIRO_DIR}}/specs/[feature-name]/requirements.md`

---

### Case B: Input IS an existing feature name

**Present options via AskUserQuestion:**

```
Feature "[feature-name]" already exists. What would you like to do?

A. Regenerate requirements (fresh generation from description)
B. Edit requirements (dialogue-driven modifications)
C. Update description and regenerate
D. View current status (no changes)
E. Deepen detail level (interface → normal → edge-cases)
```

#### Option A: Regenerate Requirements

1. Read existing `{{KIRO_DIR}}/specs/$1/requirements.md` for project description
2. Read steering context and templates
3. Generate fresh requirements (overwrites existing)
4. Update spec.json metadata

#### Option B: Edit Requirements (Dialogue-Driven)

1. Load existing requirements from `{{KIRO_DIR}}/specs/$1/requirements.md`
2. Present current requirements summary
3. Ask: "What would you like to change?"
   - Options: Add requirements / Modify existing / Remove requirements / Refine acceptance criteria / Other
4. Conduct focused dialogue on selected area
5. Apply changes to requirements.md
6. Preserve unchanged sections

#### Option C: Update Description and Regenerate

1. Ask user for new/updated project description via AskUserQuestion
2. Regenerate requirements with new description
3. Update requirements.md with new content

#### Option D: View Current Status

1. Read `{{KIRO_DIR}}/specs/$1/spec.json` and `requirements.md`
2. Display current state summary
3. No file modifications

#### Option E: Deepen Detail Level

1. Read current `## Detail Level:` header from `{{KIRO_DIR}}/specs/$1/requirements.md`
2. Advance to next level: `interface` → `normal` → `edge-cases`
   - If already at `edge-cases`, inform user and suggest Option B for targeted edits instead
3. Preserve all existing ACs, then add new ACs appropriate for the deeper level:
   - `interface` → `normal`: Add happy-path behavior details and standard error handling
   - `normal` → `edge-cases`: Add boundary conditions, race conditions, failure recovery, concurrency scenarios
4. Update the `## Detail Level:` header in requirements.md
5. For each new or modified AC, assign appropriate stability tag: `[constraint]`, `[contract]`, or `[behavior]`
6. Follow version increment logic (Step 3)

---

## Step 3: Update Metadata (for Options A, B, C)

Update `{{KIRO_DIR}}/specs/$1/spec.json`:
- Set `phase: "requirements-generated"`
- Set `approvals.requirements.generated: true`
- Update `updated_at` timestamp

**Version management** (Case B edits only — Case A uses initial "1.0.0" set in Step 2):
- Increment `version` (minor bump: 1.0.0 → 1.1.0 for additions, patch bump: 1.0.0 → 1.0.1 for refinements)
- Update `version_refs.requirements` to the new version
- Append changelog entry: `{ "version": "{NEW_VER}", "date": "{ISO_DATE}", "phase": "requirements", "summary": "{brief description of change}" }`
- **Downstream staleness warning**: If `version_refs.design` or `version_refs.tasks` exist and reference an older version than the new `version_refs.requirements`:
  - Warn: "Design is based on requirements v{design_ref} but requirements are now v{new_ver}. Consider re-running `/sdd-design $1`."
  - Warn: "Tasks are based on requirements v{tasks_ref} but requirements are now v{new_ver}. Consider re-running `/sdd-tasks $1`."
- **Impact analysis suggestion** (if roadmap.md exists and feature has downstream dependencies):
  - If `[constraint]`-tagged ACs were changed: "A [constraint]-level AC was changed. Running `/sdd-impact-analysis $1` is strongly recommended."
  - Otherwise: "This feature has downstream dependencies. Consider running `/sdd-impact-analysis $1` to assess impact."

</instructions>

## Tool Guidance

- **AskUserQuestion**: Primary tool for dialogue flow and option selection
- **Glob**: Check existing spec directories for name uniqueness
- **Read first**: Load all context (spec, steering, rules, templates) before generation
- **Write last**: Update requirements.md only after complete generation
- Use **WebSearch/WebFetch** only if external domain knowledge needed

## Output Description

Provide output in the language specified in spec.json with:

### For New Specification (Case A):

1. **Generated Feature Name**: `feature-name` format with 1-2 sentence rationale
2. **Created Files**: Bullet list with full paths
3. **Requirements Summary**: Brief overview of major requirement areas (3-5 bullets)
4. **Next Steps**: Guide user on how to proceed

### For Existing Specification (Case B):

1. **Action Taken**: What was modified/viewed
2. **Changes Made**: Summary of updates (if any)
3. **Next Steps**: Guide user on how to proceed

**Format Requirements**:
- Use Markdown headings for clarity
- Include file paths in code blocks
- Keep summary concise (under 300 words)

## Important Constraints

- Focus on WHAT, not HOW (no implementation details)
- Requirements must be testable and verifiable
- Choose appropriate subject for EARS statements (system/service name for software)
- Generate initial version first, then iterate with user feedback (no sequential questions upfront)
- Requirement headings in requirements.md MUST include a leading numeric ID only (for example: "Requirement 1", "1.", "2 Feature ..."); do not use alphabetic IDs like "Requirement A".

## Safety & Fallback

### Error Scenarios

- **Ambiguous Feature Name**: Propose 2-3 options via AskUserQuestion and let user select
- **Template Missing**: If template files don't exist, use inline fallback structure with warning
- **Language Undefined**: Default to English (`en`) if language cannot be detected
- **Steering Directory Empty**: Warn user that project context is missing and may affect requirement quality
- **Non-numeric Requirement Headings**: If existing headings do not include a leading numeric ID, normalize them to numeric IDs

### Next Phase: Design Generation

**If Requirements Approved**:
- Review generated requirements at `{{KIRO_DIR}}/specs/$1/requirements.md`
- **Optional Gap Analysis** (for existing codebases):
  - Run `/sdd-analyze-gap $1` to analyze implementation gap with current code
  - Identifies existing components, integration points, and implementation strategy
  - Recommended for brownfield projects; skip for greenfield
- Then `/sdd-design $1 -y` to proceed to design phase

**If Modifications Needed**:
- Re-run `/sdd-requirements $1` to enter edit mode

**Note**: Approval is mandatory before proceeding to design phase.

think
