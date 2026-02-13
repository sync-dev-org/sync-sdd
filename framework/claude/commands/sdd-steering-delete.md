---
description: Reset steering documents (delete and reinitialize)
allowed-tools: Bash, Read, Glob, AskUserQuestion, Skill
---

# Steering Reset

<background_information>
- **Mission**: Delete existing steering and reinitialize from scratch
- **Use case**: When steering is fundamentally wrong or project direction changed significantly
- **Safety**: Requires explicit confirmation before deletion
</background_information>

<instructions>

## Execution Flow

### Step 1: List Files to Delete

1. **Scan steering directory**:
   - Glob `{{SDD_DIR}}/project/steering/*.md`

2. **Categorize files**:
   - Core files: `product.md`, `tech.md`, `structure.md`
   - Custom files: Any other `.md` files

3. **Present deletion list**:
   ```
   ## Reset Confirmation

   This will DELETE the following steering files:

   ### Core Files
   - {{SDD_DIR}}/project/steering/product.md
   - {{SDD_DIR}}/project/steering/tech.md
   - {{SDD_DIR}}/project/steering/structure.md

   ### Custom Files
   - {{SDD_DIR}}/project/steering/[custom1].md
   - {{SDD_DIR}}/project/steering/[custom2].md

   ⚠️ This action cannot be undone (use git to recover if needed).

   Type "RESET" to confirm.
   ```

### Step 2: Confirm Deletion

**Use AskUserQuestion**:
- Require user to type "RESET" exactly
- Any other input aborts the operation

### Step 3: Execute Deletion

If confirmed:

1. **Delete all steering files**:
   ```bash
   rm {{SDD_DIR}}/project/steering/*.md
   ```

2. **Preserve directory structure**:
   - Keep `{{SDD_DIR}}/project/steering/` directory
   - Only delete `.md` files

### Step 4: Reinitialize

After successful deletion:

1. **Report deletion**:
   ```
   ## Steering Deleted

   Removed [N] files from {{SDD_DIR}}/project/steering/

   Starting reinitialization...
   ```

2. **Execute `/sdd-steering-create`** via Skill tool

</instructions>

## Tool Guidance

### File Operations
- **Glob**: Find all steering files
- **Bash**: Delete files (only after confirmation)

### Skill Invocation
- After deletion, invoke `/sdd-steering-create` for reinitialization

### Deletion Commands

```bash
rm {{SDD_DIR}}/project/steering/*.md
```

**NEVER delete**:
- `{{SDD_DIR}}/settings/` (templates and rules)
- `{{SDD_DIR}}/project/specs/` (specifications)
- The steering directory itself

## Safety Measures

- **Explicit confirmation**: User must type "RESET" exactly
- **Show full file list**: User sees exactly what will be deleted
- **Preserve directory**: Only delete files, not the steering directory
- **Git recovery hint**: Remind user they can recover via git if needed

## Output Description

### Confirmation Prompt
```
## Reset Confirmation

Files to delete: [N]
[file list]

Type "RESET" to confirm, or anything else to cancel.
```

### After Reset
```
## Steering Reset Complete

Deleted: [N] files
Starting fresh initialization...
```

Then `/sdd-steering-create` takes over.
