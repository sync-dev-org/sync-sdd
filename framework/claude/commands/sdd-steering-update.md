---
description: Update existing steering documents through targeted dialogue
allowed-tools: Read, Write, Edit, Glob, Grep, AskUserQuestion
argument-hint: "[-y]"
---

# Steering Update

<background_information>
- **Mission**: Update existing steering documents through targeted, dialogue-driven changes
- **Prerequisite**: Steering files must exist
- **Key Principle**: Only change what user wants - preserve everything else
- **Success Criteria**:
  - User's time respected - no forced re-confirmation of unchanged sections
  - Changes applied precisely to requested areas
  - Unchanged sections preserved exactly
</background_information>

<instructions>

## Execution Flow

### Step 1: Load Existing Steering

1. **Read all steering files**:
   - `{{SDD_DIR}}/project/steering/product.md`
   - `{{SDD_DIR}}/project/steering/tech.md`
   - `{{SDD_DIR}}/project/steering/structure.md`
   - Any custom files in `{{SDD_DIR}}/project/steering/`

2. **Build current state summary**:
   ```
   ## Current Steering Summary

   ### Product (product.md)
   - Name: [name]
   - Purpose: [purpose]
   - Target Users: [users]

   ### Technology (tech.md)
   - Stack: [technologies]
   - Standards: [key standards]

   ### Structure (structure.md)
   - Pattern: [organization]
   - Key Directories: [list]

   ### Custom Files
   - [file.md]: [brief content]
   ```

### Step 2: Ask What to Change

**Use AskUserQuestion**:
- "What would you like to update or change?"
- Options:
  - **Product info** - Name, purpose, target users
  - **Tech stack** - Languages, frameworks, libraries
  - **Project structure** - Organization, directories
  - **Everything** - Full review of all sections
  - *(User can also type custom response)*

### Step 3: Optional Codebase Analysis

If changes involve technical aspects (tech stack, structure):

**Offer analysis option**:
- "Would you like me to analyze the codebase to suggest updates?"
- Options:
  - **"Yes, analyze"** - Scan code for changes since steering was created
  - **"No, I'll describe"** - User provides all information

If analysis selected:
1. Scan codebase for current state
2. Compare against steering documents
3. Highlight discrepancies as suggestions

### Step 4: Dialogue-Driven Updates

Based on user's selection, focus dialogue ONLY on those areas:

#### If "Product info" selected:
- "What about the product needs updating?"
- Allow free-form description or specific questions
- Example: "We've pivoted to target enterprise users"

#### If "Tech stack" selected:
- "What technology changes need to be reflected?"
- If analyzed: "I detected [changes]. Should these be documented?"
- Example: "We switched from REST to GraphQL"

#### If "Project structure" selected:
- "How has the project organization changed?"
- If analyzed: "New directories found: [list]. Document these?"
- Example: "We added a /services directory"

#### If "Everything" selected:
- Walk through each file briefly
- Ask if changes needed for each section
- Skip sections user confirms are correct

### Step 5: Apply Changes

1. **Edit only affected files**:
   - Use Edit tool for targeted changes
   - Preserve unchanged sections exactly

2. **Show preview before applying** (unless `-y`):
   ```
   ## Proposed Changes

   ### tech.md
   - Line 15: "REST API" → "GraphQL API"
   - Line 23: Added "Apollo Server" to frameworks

   Apply these changes?
   ```

3. **Apply changes** after confirmation

### Step 6: Present Summary

```
## Steering Updated

### Changes Made
- tech.md: Updated API approach (REST → GraphQL)
- tech.md: Added Apollo Server to frameworks

### Preserved
- product.md (no changes requested)
- structure.md (no changes requested)

### Next Steps
- Review changes in {{SDD_DIR}}/project/steering/
- Use `/sdd-steering-custom` for specialized topics

Ready to guide development.
```

</instructions>

## Auto-Approve Mode

**If `-y` flag is provided**:
- Skip change preview confirmation
- Apply changes directly after dialogue
- Still require user to specify what to change

## Tool Guidance

### Dialogue
- **AskUserQuestion**: Drive focused dialogue on areas user wants to change
- Never force re-confirmation of unchanged sections

### File Operations
- **Read**: Load existing steering files
- **Edit**: Apply targeted changes (preserve unchanged content)
- **Glob**: Find all steering files

### Codebase Analysis (optional)
- **Grep**: Search for patterns
- **Read**: Load config files for comparison

## Safety Measures

- **Preview changes** before applying (unless `-y`)
- **Preserve unchanged sections** exactly
- **Never delete** custom steering files without explicit request
- **Backup approach**: If major changes, suggest `/sdd-steering-delete` instead

## Notes

- Edit mode respects user's time - only discuss what they want to change
- Changes are incremental, not full regeneration
- User customizations are always preserved
- Focus on patterns and decisions, not exhaustive lists
