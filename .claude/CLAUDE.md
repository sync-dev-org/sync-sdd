# AI-DLC and Spec-Driven Development

Kiro-style Spec Driven Development implementation on AI-DLC (AI Development Life Cycle)

## Project Context

### Paths
- Steering: `{{KIRO_DIR}}/steering/`
- Specs: `{{KIRO_DIR}}/specs/`
- Knowledge: `{{KIRO_DIR}}/knowledge/`

### Steering vs Specification vs Knowledge

| Artifact | Scope | Purpose | Portable |
|----------|-------|---------|----------|
| **Steering** | Project-specific | Project-wide rules, context, decisions | No |
| **Specs** | Feature-specific | Requirements, design, tasks for a feature | No |
| **Knowledge** | Cross-project | Reusable insights, patterns, incidents | Yes |

**Steering** (`{{KIRO_DIR}}/steering/`) - Guide AI with project-wide rules and context
**Specs** (`{{KIRO_DIR}}/specs/`) - Formalize development process for individual features
**Knowledge** (`{{KIRO_DIR}}/knowledge/`) - Capture reusable learnings across projects

**When to use which**:
- Project-specific decisions (tech stack, architecture) → Steering
- Feature implementation details → Specs
- Reusable patterns and lessons learned → Knowledge

### Active Specifications
- Check `{{KIRO_DIR}}/specs/` for active specifications
- Use `/sdd-status [feature-name]` to check progress

## Minimal Workflow (Stages)
- Stage 0 (optional): `/sdd-steering`, `/sdd-steering-custom`
- Stage 0.5 (optional): `/sdd-roadmap [-y]` - Generate product-wide specification roadmap and initialize multiple specs as skeletons
- Stage 1 (Specification):
  - `/sdd-requirements "description"` (new spec) or `/sdd-requirements {feature}` (edit existing)
  - `/sdd-review-requirement {feature}` (optional: requirements review)
  - `/sdd-impact-analysis {feature}` (optional: after editing existing requirements with downstream dependencies)
  - `/sdd-analyze-gap {feature}` (optional: for existing codebase)
  - `/sdd-design {feature} [-y]`
  - `/sdd-review-design {feature}` (optional: design review)
  - `/sdd-tasks {feature} [-y]`
- Stage 2 (Implementation): `/sdd-impl {feature} [tasks]`
  - `/sdd-review-impl {feature}` (optional: after implementation)
- Progress check: `/sdd-status {feature}` (use anytime)

## Development Rules
- 3-gate approval workflow: Requirements → Design → Tasks → Implementation
- Human review required at each approval gate; use `-y` only for intentional fast-track
- Keep steering current and verify alignment with `/sdd-status`
- Follow the user's instructions precisely, and within that scope act autonomously: gather the necessary context and complete the requested work end-to-end in this run, asking questions only when essential information is missing or the instructions are critically ambiguous.

### SPEC-Code Atomicity Convention
- SPEC changes (requirements.md, design.md, tasks.md) and corresponding code changes should be kept in the same logical change unit
- When editing requirements triggers downstream changes, guide through the full cascade: requirements → design → tasks → implementation
- Version consistency is enforced: `/sdd-impl` blocks if spec versions are misaligned (version_refs mismatch)
- If `/sdd-review-impl` returns SPEC-UPDATE-NEEDED, fix the spec first — do not re-implement against a defective spec

## Behavioral Rules
- After a compact operation, ALWAYS wait for the user's next instruction. NEVER start any action autonomously after compact.
- Do not continue or resume previously in-progress tasks after compact unless the user explicitly instructs you to do so.

## Compact Pipe-Delimited Format (CPF)

Token-efficient structured text format used for inter-agent communication and tool output.

### Notation Rules

| Element | Format | Example |
|---------|--------|---------|
| Metadata | `KEY:VALUE` (no space) | `VERDICT:CONDITIONAL` |
| Structured row | `field1\|field2\|field3` | `H\|ambiguity\|Req 1\|not quantified` |
| Freeform text | Plain lines (no decoration) | `Domain research suggests...` |
| List identifiers | `+` separated | `rulebase+edge-case` |
| Empty sections | Omit header entirely | _(do not output)_ |
| Severity codes | C/H/M/L | C=Critical, H=High, M=Medium, L=Low |

### Writing CPF

- Section headers (`ISSUES:`, `NOTES:`, etc.) followed by one record per line
- No decoration characters (`- [`, `] `, `: `, ` - `)
- Omit empty sections (do not output the header)
- No spaces in metadata lines (`KEY:VALUE`)

### Parsing CPF

```
1. Line starts with known keyword + `:` → metadata or section start
2. Lines under a section → split by `|` to extract fields
3. Field containing `+` → split as identifier list
4. Section not present → no data of that type (not an error)
```

### Minimal Example

```
VERDICT:GO
SCOPE:my-feature
ISSUES:
M|ambiguity|Req 1.AC1|"quickly" not quantified
NOTES:
No critical issues found
```

## Steering Configuration
- Load entire `{{KIRO_DIR}}/steering/` as project memory
- Default files: `product.md`, `tech.md`, `structure.md`
- Custom files are supported (managed via `/sdd-steering-custom`)
