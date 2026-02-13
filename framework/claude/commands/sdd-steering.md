---
description: Steering router - initialize, update, or reset steering documents
allowed-tools: Glob, Grep, Read, AskUserQuestion, Skill
argument-hint: "[-y]"
---

# Steering Document Router

<background_information>
- **Mission**: Route to appropriate steering action based on current state
- **This is a router command**: Detects steering state and presents options
- **Subcommands**:
  - `/sdd-steering-create` - Create new steering documents from scratch
  - `/sdd-steering-update` - Update existing steering documents
  - `/sdd-steering-delete` - Reset and reinitialize steering
</background_information>

<instructions>

## Execution Flow

### Step 1: Check Steering State

1. **Check if core steering files exist**:
   - Look for `{{SDD_DIR}}/project/steering/product.md`
   - Look for `{{SDD_DIR}}/project/steering/tech.md`
   - Look for `{{SDD_DIR}}/project/steering/structure.md`

2. **If core files do NOT exist** (any missing):
   - Inform user: "No steering documents found. Initializing..."
   - Execute `/sdd-steering-create` via Skill tool
   - END

3. **If core files EXIST**:
   - Read all steering files to build summary
   - Proceed to Step 2

### Step 2: Build Status Summary

1. **Read each steering file** and extract key points:
   - `product.md`: Product name, purpose, target users
   - `tech.md`: Primary stack, key frameworks
   - `structure.md`: Organization pattern, key directories

2. **List any custom steering files** in the directory

3. **Build summary**:
   ```
   ## Current Steering Status

   ### Product (product.md)
   - Name: [product name]
   - Purpose: [brief purpose]

   ### Technology (tech.md)
   - Stack: [primary technologies]
   - Standards: [key standards]

   ### Structure (structure.md)
   - Pattern: [organization pattern]
   - Key directories: [list]

   ### Custom Files
   - [custom1.md]: [brief description]
   ```

### Step 3: Present Options

**Show status summary first**, then present two options:

```
## Steering Actions

### 1. Update - Modify Existing
Make targeted changes to specific sections.
→ Invokes `/sdd-steering-update`

### 2. Reset - Start Fresh
Delete all steering and reinitialize from scratch.
⚠️ This deletes all steering documents!
```

**Use AskUserQuestion** with options:
- "Update" - Modify existing steering
- "Reset" - Delete and reinitialize

### Step 4: Execute Selected Action

#### If "Update" selected:

Execute `/sdd-steering-update` via Skill tool.

#### If "Reset" selected:

Execute `/sdd-steering-delete` via Skill tool.

</instructions>

## Auto-Approve Mode

**If `-y` flag is provided**:
- Skip option selection
- Automatically select "Update" action
- Pass `-y` to `/sdd-steering-update`

## Tool Guidance

### Skill Invocation

| Action | Command |
|--------|---------|
| Initialize | `/sdd-steering-create` |
| Update | `/sdd-steering-update` |
| Reset | `/sdd-steering-delete` |

### File Operations

- **Read**: Steering files (for status summary)
- **Glob**: Find all files in `{{SDD_DIR}}/project/steering/`

**NEVER modify files directly** - always route to subcommands.

## Output Description

### Status Display

```
## Steering Status

### Summary
| File | Status | Key Content |
|------|--------|-------------|
| product.md | ✅ | [product name] - [purpose] |
| tech.md | ✅ | [stack] |
| structure.md | ✅ | [pattern] |
| custom/*.md | ✅ | [N custom files] |

## Actions
[Update / Reset]
```

**Language**: Follow user's language setting.
