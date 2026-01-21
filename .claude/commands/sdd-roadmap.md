---
description: Roadmap router - initialize, run, update, or reset the specification roadmap
allowed-tools: Glob, Grep, Read, Write, Edit, AskUserQuestion, Task, Skill, Bash
argument-hint: "[-y]"
---

# Specification Roadmap Router

<background_information>
- **Mission**: Route to appropriate roadmap action based on current state
- **This is a router command**: Detects roadmap state and presents options
- **Subcommands**:
  - `/sdd-roadmap-init` - Create new roadmap from steering
  - `/sdd-roadmap-run` - Execute Wave-based implementation
  - `/sdd-roadmap-update` - Sync roadmap with spec states
</background_information>

<instructions>

## Execution Flow

### Step 1: Check Roadmap State

1. **Check if roadmap.md exists**:
   - Look for `{{KIRO_DIR}}/specs/roadmap.md`

2. **If roadmap.md does NOT exist**:
   - Inform user: "No roadmap found. Initializing new roadmap..."
   - Execute `/sdd-roadmap-init` via Skill tool
   - END

3. **If roadmap.md EXISTS**:
   - Read roadmap.md to understand current wave structure
   - Scan all `{{KIRO_DIR}}/specs/*/spec.json` to get current spec states
   - Proceed to Step 2

### Step 2: Build Status Summary

1. **For each spec in roadmap**, check:
   - Does spec directory exist?
   - What is current phase?
   - Tasks completion status (if tasks.md exists)

2. **Build status summary**:
   ```
   ## Current Roadmap Status

   ### Wave 1 (Foundation)
   | Spec | Phase | Tasks | Status |
   |------|-------|-------|--------|
   | config-management | tasks-generated | 3/5 | In progress |

   ### Wave 2 (Core)
   | Spec | Phase | Tasks | Status |
   |------|-------|-------|--------|
   | slack-notifier | design-generated | - | Ready for tasks |
   | health-checker | requirements-pending | - | Not started |
   ```

### Step 3: Present Options

**Show status summary first**, then present three options:

```
## Roadmap Actions

### 1. Run - Execute Implementation
Resume/start implementation following the roadmap.
→ Invokes `/sdd-roadmap-run`

### 2. Update - Sync with Specs
Analyze differences between roadmap and specs, update roadmap.
→ Invokes `/sdd-roadmap-update`

### 3. Reset - Start Fresh
Discard roadmap and all specs, reinitialize from steering.
⚠️ This deletes all spec work!
```

**Use AskUserQuestion** with options:
- "Run" - Execute implementation
- "Update" - Sync roadmap with specs
- "Reset" - Discard and reinitialize

### Step 4: Execute Selected Action

#### If "Run" selected:

Execute `/sdd-roadmap-run` via Skill tool.

#### If "Update" selected:

Execute `/sdd-roadmap-update` via Skill tool.

#### If "Reset" selected:

**Handle reset inline** (simple operation):

1. **Confirm deletion**:
   ```
   ## Reset Confirmation

   This will DELETE:
   - {{KIRO_DIR}}/specs/roadmap.md
   - All spec directories: {{KIRO_DIR}}/specs/*/

   Steering documents in {{KIRO_DIR}}/steering/ will be PRESERVED.

   Type "RESET" to confirm.
   ```

2. **If confirmed** (user types "RESET"):
   - Delete `{{KIRO_DIR}}/specs/roadmap.md`
   - Delete all directories in `{{KIRO_DIR}}/specs/*/` (but not specs/ itself)
   - Execute `/sdd-roadmap-init` via Skill tool

3. **If not confirmed**: Return to options

</instructions>

## Auto-Approve Mode

**If `-y` flag is provided**:
- Skip option selection
- Automatically select "Run" action
- Pass `-y` to `/sdd-roadmap-run`

## Tool Guidance

### Skill Invocation

| Action | Command |
|--------|---------|
| Initialize | `/sdd-roadmap-init` |
| Run | `/sdd-roadmap-run` |
| Update | `/sdd-roadmap-update` |

### File Operations

- **Read**: roadmap.md, spec.json files (for status)
- **Glob**: Find spec directories
- **Bash**: Delete files for Reset action only

### Reset Deletion

Use Bash for deletion:
```bash
rm {{KIRO_DIR}}/specs/roadmap.md
rm -rf {{KIRO_DIR}}/specs/*/
```

**NEVER delete**:
- `{{KIRO_DIR}}/steering/`
- `{{KIRO_DIR}}/settings/`

## Output Description

### Status Display

```
## Roadmap Status

Generated: 2026-01-20
Specs: 6 | Waves: 4

### Progress
| Wave | Name | Progress | Status |
|------|------|----------|--------|
| 1 | Foundation | 1/1 | ✅ Complete |
| 2 | Core | 1/2 | 🔄 In Progress |
| 3 | Integration | 0/2 | ⏳ Pending |
| 4 | Application | 0/1 | ⏳ Pending |

### Current Position
Wave 2, spec: health-checker
Phase: design-generated
Next: /sdd-tasks

## Actions
[Run / Update / Reset]
```

**Language**: Follow user's language setting.
