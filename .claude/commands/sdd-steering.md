---
description: Initialize steering documents through interactive dialogue
allowed-tools: Bash, Read, Write, Edit, MultiEdit, Glob, Grep, LS, AskUserQuestion
---

# Steering Interactive Initialization

<background_information>
**Role**: Guide users through steering initialization via interactive dialogue.

**Mission**:
- Provide intuitive, conversational setup experience
- Help users articulate their project vision clearly
- Generate or update steering through dialogue
- Never leave users stuck - always offer clear paths forward

**Success Criteria**:
- User understands their options before choosing
- Steering files capture project intent accurately
- Patterns documented, not exhaustive lists
- User feels confident in generated output
</background_information>

<instructions>

## Step 1: Detect Current State

Check `{{KIRO_DIR}}/steering/` for existing files:

```
steering_exists = core files present (product.md, tech.md, structure.md)
```

---

## Step 2: Present Options

**Ask user to choose using AskUserQuestion tool**:

### Option A: Steering Only (Ignore Codebase)
- Focus purely on steering files and user dialogue
- No codebase analysis
- **If steering exists**: Edit mode - dialogue-driven updates
- **If steering empty**: Full initialization dialogue

### Option B: With Codebase Analysis
- Analyze existing code structure
- Use analysis to inform/validate steering
- Full confirmation of all items with code-derived suggestions

Present both options clearly with descriptions.

---

## Step 3A: Steering Only Flow

### Case 1: No Existing Steering → Full Initialization

Ask ALL items progressively (use AskUserQuestion):

1. **What is this project?**
   - Name, purpose, problem it solves
   - "What does your project do in one sentence?"

2. **Who is it for?**
   - Target users, use cases
   - "Who will use this and what will they achieve?"

3. **Core Capabilities**
   - 3-5 main features (patterns, not exhaustive list)
   - "What are the 3-5 most important things it does?"

4. **Technology Choices**
   - Language, framework, key libraries
   - "What technologies are you using or planning to use?"

5. **Architecture Approach**
   - Monolith, microservices, serverless, etc.
   - "How is the code organized? (feature-first, layered, etc.)"

6. **Development Standards**
   - Code style, testing approach
   - "Any specific coding standards or practices?"

Then generate steering using templates.

### Case 2: Existing Steering → Edit Mode

**Edit mode is dialogue-driven and flexible.**

Since steering already exists with all sections filled, do NOT require re-answering all questions.

1. **Load existing steering**
   - Read all files in `{{KIRO_DIR}}/steering/`
   - Understand current state

2. **Present current summary**
   ```
   Current steering summary:
   - Product: [brief from product.md]
   - Tech: [brief from tech.md]
   - Structure: [brief from structure.md]
   - Custom: [list any custom files]
   ```

3. **Ask what to change** (use AskUserQuestion)
   - "What would you like to update or change?"
   - Options: Product info / Tech stack / Project structure / Everything / Other
   - User can specify freely

4. **Dialogue-driven updates**
   - Focus ONLY on areas user wants to change
   - Ask clarifying questions as needed
   - No forced re-confirmation of unchanged sections
   - Example: If user says "update tech stack", only discuss tech-related changes

5. **Apply changes**
   - Update only affected files
   - Preserve unchanged sections
   - Maintain user customizations

---

## Step 3B: With Codebase Analysis Flow

### 3B.1 Codebase Analysis

Analyze project structure (JIT):

```
- glob: Find source files, configs
- read: README, package.json, pyproject.toml, etc.
- grep: Extract patterns (imports, naming, etc.)
```

### 3B.2 Full Confirmation Dialogue

Even with codebase analysis, confirm ALL core items with user (use AskUserQuestion).
Analysis provides defaults/suggestions; user confirms or overrides.

1. **What is this project?**
   - Present detected purpose: "Based on the code, this appears to be [detected]. Is this correct?"
   - "What problem does it solve? Who is it for?"
   - Confirm or let user clarify

2. **Who is it for?**
   - "Who are the target users? What will they achieve?"
   - Code may not reveal this - always ask

3. **Core Capabilities**
   - "I detected these main features: [list]. Are these the 3-5 core capabilities?"
   - "Anything to add or remove from this list?"

4. **Technology Choices**
   - "Detected stack: [language, framework, libraries]. Is this accurate?"
   - "Any key libraries I missed or should highlight?"

5. **Architecture Approach**
   - "The code appears to follow [detected pattern]. Is this the intended organization?"
   - "Feature-first, layered, domain-driven, etc.?"

6. **Development Standards**
   - "I found these conventions: [detected standards]. Are these correct?"
   - "Any additional coding standards or practices to document?"

### 3B.3 Refinement Dialogue (Codebase-Specific)

After confirming core items, ask additional codebase-specific questions:

7. **Pattern Validation**
   - "I noticed [specific pattern]. Is this intentional? Should it be documented as a standard?"
   - "Are there patterns in the code that should NOT be followed going forward?"

8. **Future Direction**
   - "Are there any patterns you'd like to change?"
   - "Anything the current code doesn't reflect that should become standard?"

9. **Gaps and Concerns**
   - "I couldn't determine [aspect]. Can you clarify?"
   - Present analysis findings, ask for corrections
   - "Is there anything about the project I should know that isn't in the code?"

### 3B.4 Generate/Update Steering

1. Load templates from `{{KIRO_DIR}}/settings/templates/steering/`
2. Merge analysis + ALL user confirmations/overrides
3. If existing steering: preserve custom sections, update confirmed changes
4. Apply steering principles (patterns, not lists)
5. Write to `{{KIRO_DIR}}/steering/`

---

## Step 4: Review and Confirm

Present generated/updated steering summary:

### For New/Full Generation:
```
## Steering Generated

### Files:
- product.md: [summary]
- tech.md: [summary]
- structure.md: [summary]

### Key Patterns Captured:
- [list 3-5 main patterns]

Would you like to review or adjust anything?
```

### For Edit Mode:
```
## Steering Updated

### Changes Made:
- [file]: [what changed]
- [file]: [what changed]

### Preserved:
- [unchanged sections/files]

Would you like to make any additional changes?
```

Offer to:
- Show full file contents
- Make additional adjustments
- Add custom steering (suggest `/sdd-steering-custom`)

</instructions>

## Tool Guidance

- **AskUserQuestion**: Primary tool - drive dialogue
- **Glob**: Find source/config files for analysis (Option B only)
- **Read**: Load templates, existing steering, code samples
- **Grep**: Search for patterns in codebase (Option B only)
- **Write/Edit**: Create or update steering files

**Dialogue Strategy**:
- Full init/codebase: Ask 1-2 questions at a time, build progressively
- Edit mode: Start with "what to change?", then focus on those areas only

## Output Description

Conversational throughout, final summary when complete:

### New Steering:
```
## Steering Initialized

### Generated:
- product.md: [Brief description]
- tech.md: [Key stack/standards]
- structure.md: [Organization pattern]

### Captured Patterns:
- [Pattern 1]
- [Pattern 2]
- [Pattern 3]

### Next Steps:
- Review generated files in {{KIRO_DIR}}/steering/
- Run this command again to edit
- Consider `/sdd-steering-custom` for specialized topics

Ready to guide development.
```

### Edit Mode:
```
## Steering Updated

### Changes:
- tech.md: Updated framework version
- structure.md: Added new directory pattern

### Unchanged:
- product.md (no changes requested)

Ready to guide development.
```

## Examples

### Example 1: New Project (Steering Only)
**State**: No existing steering
**User chooses**: Option A (Steering Only)
**Flow**: Full 6-question dialogue → Generate all files
**Output**: Complete steering from scratch

### Example 2: Edit Existing (Steering Only)
**State**: Steering exists
**User chooses**: Option A (Steering Only)
**Flow**: Show summary → "What to change?" → User: "Tech stack" → Discuss tech only → Update tech.md
**Output**: Only tech.md updated, others preserved

### Example 3: From Codebase
**State**: Any (new or existing)
**User chooses**: Option B (With Codebase)
**Flow**: Analyze code → Confirm all 6 items with detected values → Refinement questions → Generate/update
**Output**: Steering aligned with actual codebase + user intent

### Example 4: Quick Edit
**State**: Steering exists
**User chooses**: Option A
**Flow**: "What to change?" → "Just add that we use Docker" → Update tech.md deployment section
**Output**: Minimal targeted update

## Safety & Fallback

- **Never include**: Secrets, credentials, API keys
- **Edit mode safety**: Always show what will change before applying
- **Uncertainty**: Ask user rather than assume
- **Preservation**: In edit mode, preserve everything not explicitly changed

## Principles Reference

Load `{{KIRO_DIR}}/settings/rules/steering-principles.md` for:
- Granularity guidelines
- What to document vs avoid
- Quality standards
- Security rules

## Notes

- Templates are starting points, customize via dialogue
- Focus on patterns and decisions, not exhaustive lists
- All `{{KIRO_DIR}}/steering/*.md` loaded as project memory
- User input always takes precedence over analysis
- Edit mode: respect user's time - only discuss what they want to change
- Codebase analysis provides suggestions; user confirms everything
- Avoid documenting agent-specific directories (.cursor/, .gemini/, .claude/)
- Light references to {{KIRO_DIR}}/specs/ and {{KIRO_DIR}}/steering/ acceptable
