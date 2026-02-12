---
description: Create custom steering documents for specialized project contexts
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, AskUserQuestion
---

# Custom Steering Creation

<background_information>
- **Mission**: Create specialized steering documents beyond core files (product, tech, structure)
- **Key Principle**: Same dialogue-driven approach as core steering initialization
- **Success Criteria**:
  - Custom steering captures specialized patterns
  - Follows same granularity principles as core steering
  - Provides clear value for specific domain
</background_information>

<instructions>

## Execution Flow

### Step 1: Ask for Custom Steering Topic

**Use AskUserQuestion**:
- "What specialized topic do you want to document?"
- Suggest common options:
  - **API standards** - REST/GraphQL conventions, error handling
  - **Testing** - Test organization, mocking, coverage
  - **Security** - Auth patterns, input validation
  - **Database** - Schema design, migrations, query patterns
  - **Error handling** - Error types, logging, retry strategies
  - **Authentication** - Auth flows, permissions, sessions
  - **Deployment** - CI/CD, environments, rollback
  - *(User can also specify custom topic)*

### Step 2: Ask About Codebase Analysis

**Use AskUserQuestion**:
- "Would you like me to analyze your codebase to extract patterns for this topic?"
- Options:
  - **"Yes, analyze codebase"**: Scan code for relevant patterns, use as defaults
  - **"No, I'll describe"**: Pure dialogue, user provides all information

### Step 3A: Codebase Analysis (if selected)

If user chose analysis:

1. **Load template** (if exists):
   - Check `{{KIRO_DIR}}/settings/templates/steering-custom/{topic}.md`

2. **Scan for relevant patterns**:
   - **Glob**: Find files related to the topic
   - **Read**: Examine implementations, configs
   - **Grep**: Search for specific patterns

3. **Extract findings**:
   - Naming conventions
   - Code organization patterns
   - Common approaches used
   - Existing standards (from linter configs, etc.)

4. **Present findings and confirm**:
   - "I found these patterns for [topic]: [list]"
   - "Is this accurate? Anything to add or change?"

### Step 3B: Dialogue-Driven (if no analysis)

If user chose dialogue:

1. **Load template** (if exists) for question structure

2. **Ask topic-specific questions** progressively:

   **For API Standards**:
   - "What API style do you use? (REST, GraphQL, etc.)"
   - "How do you handle errors? (format, codes)"
   - "Any authentication/versioning conventions?"

   **For Testing**:
   - "How are tests organized? (by feature, by type)"
   - "What testing frameworks do you use?"
   - "Any mocking or fixture conventions?"

   **For Security**:
   - "What authentication method do you use?"
   - "How do you handle input validation?"
   - "Any specific security requirements?"

   **For Database**:
   - "What database(s) do you use?"
   - "How do you handle migrations?"
   - "Any query or schema conventions?"

   **For other topics**: Ask 3-5 relevant questions based on domain

3. **Summarize understanding**:
   - "Based on our discussion, here's what I'll document: [summary]"
   - "Anything to adjust?"

### Step 4: Generate Custom Steering

1. **Apply principles** from `{{KIRO_DIR}}/settings/rules/steering-principles.md`:
   - Patterns over exhaustive lists
   - Single domain per file
   - Concrete examples with code
   - 100-200 lines typical

2. **Structure content**:
   ```markdown
   # [Topic] Standards

   ## Overview
   [Brief description of this domain]

   ## Conventions
   [Key patterns and rules]

   ## Examples
   [Code examples showing patterns]

   ## Anti-patterns
   [What to avoid]
   ```

3. **Write file** to `{{KIRO_DIR}}/steering/{topic}.md`

### Step 5: Present Summary

```
## Custom Steering Created

### Generated
- {{KIRO_DIR}}/steering/{topic}.md

### Content Summary
- [Key pattern 1]
- [Key pattern 2]
- [Key pattern 3]

### Source
- [If analyzed]: Based on codebase analysis of [directories/files]
- [If dialogue]: Based on your specifications

### Next Steps
- Review and customize as needed
- This file is now part of project memory

Ready to guide development.
```

</instructions>

## Available Templates

Templates in `{{KIRO_DIR}}/settings/templates/steering-custom/`:

| Template | Use For |
|----------|---------|
| `api-standards.md` | REST/GraphQL conventions |
| `testing.md` | Test organization, mocking |
| `security.md` | Auth patterns, validation |
| `database.md` | Schema, migrations, queries |
| `error-handling.md` | Error types, logging |
| `authentication.md` | Auth flows, permissions |
| `deployment.md` | CI/CD, environments |

Load as starting point when topic matches; customize for project.

## Tool Guidance

### Dialogue
- **AskUserQuestion**: Primary tool for topic selection and information gathering
- Ask 2-3 questions at a time
- Build understanding progressively

### Codebase Analysis (optional)
- **Glob**: Find topic-related files
- **Read**: Load configs, implementations
- **Grep**: Search for specific patterns

### File Operations
- **Read**: Load templates
- **Write**: Create custom steering file

## Steering Principles

From `{{KIRO_DIR}}/settings/rules/steering-principles.md`:

- **Patterns over lists**: Document patterns, not every file/component
- **Single domain**: One topic per file
- **Concrete examples**: Show patterns with code
- **Maintainable size**: 100-200 lines typical
- **Security first**: Never include secrets or sensitive data

## Safety & Fallback

- **No template**: Generate from scratch based on dialogue/analysis
- **Security**: Never include secrets
- **Validation**: Ensure doesn't duplicate core steering content
- **Uncertainty**: Ask user rather than assume

## Notes

- Templates are starting points, customize via dialogue
- Follow same granularity principles as core steering
- All steering files loaded as project memory
- Custom files equally important as core files
- Avoid documenting agent-specific directories (.cursor/, .gemini/, .claude/)
