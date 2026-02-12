---
description: Initialize steering documents through interactive dialogue
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, AskUserQuestion, Task
---

# Steering Initialization

<background_information>
- **Mission**: Create steering documents for a new project through interactive dialogue
- **Prerequisite**: No existing steering (or called after reset)
- **Success Criteria**:
  - User understands their options before choosing
  - Steering files capture project intent accurately
  - Patterns documented, not exhaustive lists
</background_information>

<instructions>

## Execution Flow

### Step 1: Ask About Codebase Analysis

**Use AskUserQuestion** to ask:
- "Would you like me to analyze your codebase to suggest values?"
- Options:
  - **"Yes, analyze codebase"**: Analyze code structure and use findings as defaults
  - **"No, I'll provide everything"**: Pure dialogue without codebase analysis

### Step 2: Codebase Analysis (if selected)

If user chose analysis:

1. **Scan project structure**:
   - Glob for source files, configs
   - Read README, package.json, pyproject.toml, etc.
   - Grep for patterns (imports, naming conventions)

2. **Extract detected values**:
   - Project name and purpose (from README, package.json)
   - Technology stack (from configs, imports)
   - Architecture pattern (from directory structure)
   - Coding standards (from linter configs, existing code)

3. **Store findings** for use as defaults in dialogue

### Step 3: Interactive Dialogue (6 Questions)

Ask progressively using AskUserQuestion. If codebase was analyzed, present detected values as defaults.

#### Question 1: What is this project?
- "What does your project do in one sentence?"
- If analyzed: "Based on the code, this appears to be [detected]. Is this correct?"
- Capture: Name, purpose, problem it solves

#### Question 2: Who is it for?
- "Who will use this and what will they achieve?"
- Capture: Target users, use cases

#### Question 3: Core Capabilities
- "What are the 3-5 most important things it does?"
- If analyzed: "I detected these main features: [list]. Correct?"
- Capture: 3-5 main features (patterns, not exhaustive list)

#### Question 4: Technology Choices
- "What technologies are you using or planning to use?"
- If analyzed: "Detected stack: [language, framework, libraries]. Accurate?"
- Capture: Language, framework, key libraries

#### Question 5: Architecture Approach
- "How is the code organized? (feature-first, layered, etc.)"
- If analyzed: "The code appears to follow [pattern]. Intended?"
- Capture: Monolith/microservices, organization pattern

#### Question 6: Development Standards
- "Any specific coding standards or practices?"
- If analyzed: "Found conventions: [list]. Correct?"
- Capture: Code style, testing approach

### Step 4: Generate Steering Files

1. **Load templates** from `{{KIRO_DIR}}/settings/templates/steering/`

2. **Generate files**:
   - `{{KIRO_DIR}}/steering/product.md` - Product info from Q1-Q3
   - `{{KIRO_DIR}}/steering/tech.md` - Tech info from Q4, Q6
   - `{{KIRO_DIR}}/steering/structure.md` - Architecture from Q5

3. **Write files** to `{{KIRO_DIR}}/steering/`

### Step 5: Present Summary

```
## Steering Initialized

### Generated Files
- product.md: [product name] - [purpose]
- tech.md: [stack summary]
- structure.md: [pattern summary]

### Key Patterns Captured
- [Pattern 1]
- [Pattern 2]
- [Pattern 3]

### Next Steps
- Review files in {{KIRO_DIR}}/steering/
- Run `/sdd-steering` again to make changes
- Use `/sdd-steering-custom` for specialized topics

Ready to guide development.
```

</instructions>

## Tool Guidance

### Dialogue
- **AskUserQuestion**: Primary tool - drive the 6-question dialogue
- Ask 1-2 questions at a time
- Build understanding progressively

### Codebase Analysis (optional)
- **Glob**: Find source/config files
- **Read**: Load README, package files, configs
- **Grep**: Search for patterns in codebase

### File Operations
- **Read**: Load templates
- **Write**: Create steering files

## Safety & Fallback

- **Never include**: Secrets, credentials, API keys
- **Uncertainty**: Ask user rather than assume
- **Analysis fails**: Proceed with pure dialogue mode

## Principles Reference

Load `{{KIRO_DIR}}/settings/rules/steering-principles.md` for:
- Granularity guidelines
- What to document vs avoid
- Quality standards

## Notes

- Templates are starting points, customize via dialogue
- Focus on patterns and decisions, not exhaustive lists
- User input always takes precedence over analysis
- Avoid documenting agent-specific directories (.cursor/, .gemini/, .claude/)
