---
description: Reset roadmap and all specs (delete and reinitialize)
allowed-tools: Bash, Read, Glob, AskUserQuestion, Skill
---

# Roadmap Reset

<background_information>
- **Mission**: Delete roadmap and all spec directories, then reinitialize from steering
- **Use case**: When roadmap is fundamentally wrong or project direction changed significantly
- **Safety**: Requires explicit confirmation before deletion
</background_information>

<instructions>

## Execution Flow

### Step 1: List Files to Delete

1. **Scan specs directory**:
   - Read `{{SDD_DIR}}/project/specs/roadmap.md`
   - Glob `{{SDD_DIR}}/project/specs/*/` for spec directories

2. **Build deletion list**:
   ```
   ## Reset Confirmation

   This will DELETE:

   ### Roadmap
   - {{SDD_DIR}}/project/specs/roadmap.md

   ### Spec Directories ([N] specs)
   - {{SDD_DIR}}/project/specs/[spec-1]/
   - {{SDD_DIR}}/project/specs/[spec-2]/
   - ...

   ### Preserved
   - {{SDD_DIR}}/project/steering/ (all steering documents)
   - {{SDD_DIR}}/settings/ (templates and rules)

   ⚠️ This action cannot be undone (use git to recover if needed).

   Type "RESET" to confirm.
   ```

### Step 2: Confirm Deletion

**Use AskUserQuestion**:
- Require user to type "RESET" exactly
- Any other input aborts the operation

### Step 3: Execute Deletion

If confirmed:

1. **Delete roadmap**:
   ```bash
   rm {{SDD_DIR}}/project/specs/roadmap.md
   ```

2. **Delete all spec directories**:
   ```bash
   rm -rf {{SDD_DIR}}/project/specs/*/
   ```

3. **Preserve**:
   - `{{SDD_DIR}}/project/specs/` directory itself
   - `{{SDD_DIR}}/project/steering/`
   - `{{SDD_DIR}}/settings/`

### Step 4: Reinitialize

After successful deletion:

1. **Report deletion**:
   ```
   ## Roadmap Reset Complete

   Deleted:
   - roadmap.md
   - [N] spec directories

   Starting reinitialization...
   ```

2. **Execute `/sdd-roadmap-create`** via Skill tool

</instructions>

## Tool Guidance

### File Operations
- **Glob**: Find all spec directories
- **Read**: Check roadmap existence
- **Bash**: Delete files and directories (only after confirmation)

### Skill Invocation
- After deletion, invoke `/sdd-roadmap-create` for reinitialization

### Deletion Commands

```bash
rm {{SDD_DIR}}/project/specs/roadmap.md
rm -rf {{SDD_DIR}}/project/specs/*/
```

**NEVER delete**:
- `{{SDD_DIR}}/project/steering/` (steering documents)
- `{{SDD_DIR}}/settings/` (templates and rules)
- The specs directory itself

## Safety Measures

- **Explicit confirmation**: User must type "RESET" exactly
- **Show full list**: User sees exactly what will be deleted
- **Preserve steering**: Steering documents are never touched
- **Git recovery hint**: Remind user they can recover via git if needed

## Output Description

### Confirmation Prompt
```
## Reset Confirmation

Files to delete:
- roadmap.md
- [N] spec directories

Type "RESET" to confirm, or anything else to cancel.
```

### After Reset
```
## Roadmap Reset Complete

Deleted: roadmap.md + [N] specs
Preserved: steering/, settings/

Starting fresh initialization...
```

Then `/sdd-roadmap-create` takes over.
