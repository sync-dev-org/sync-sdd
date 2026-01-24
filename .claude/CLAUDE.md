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

## Development Guidelines
{{DEV_GUIDELINES}}

## Minimal Workflow
- Phase 0 (optional): `/sdd-steering`, `/sdd-steering-custom`
- Phase 0.5 (optional): `/sdd-roadmap [-y]` - Generate product-wide specification roadmap and initialize multiple specs as skeletons
- Phase 1 (Specification):
  - `/sdd-requirements "description"` (new spec) or `/sdd-requirements {feature}` (edit existing)
  - `/sdd-analyze-gap {feature}` (optional: for existing codebase)
  - `/sdd-design {feature} [-y]`
  - `/sdd-review-design {feature}` (optional: design review)
  - `/sdd-tasks {feature} [-y]`
- Phase 2 (Implementation): `/sdd-impl {feature} [tasks]`
  - `/sdd-review-impl {feature}` (optional: after implementation)
- Progress check: `/sdd-status {feature}` (use anytime)

## Development Rules
- 3-phase approval workflow: Requirements → Design → Tasks → Implementation
- Human review required each phase; use `-y` only for intentional fast-track
- Keep steering current and verify alignment with `/sdd-status`
- Follow the user's instructions precisely, and within that scope act autonomously: gather the necessary context and complete the requested work end-to-end in this run, asking questions only when essential information is missing or the instructions are critically ambiguous.

## Behavioral Rules
- After a compact operation, ALWAYS wait for the user's next instruction. NEVER start any action autonomously after compact.
- Do not continue or resume previously in-progress tasks after compact unless the user explicitly instructs you to do so.

## Steering Configuration
- Load entire `{{KIRO_DIR}}/steering/` as project memory
- Default files: `product.md`, `tech.md`, `structure.md`
- Custom files are supported (managed via `/sdd-steering-custom`)
