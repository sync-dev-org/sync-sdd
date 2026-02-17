# Language Profile: TypeScript

## Core Technologies
- **Language**: TypeScript 5.x
- **Package Manager**: npm / pnpm / bun
- **Runtime**: Node.js 20+

## Development Standards

### Type Safety
Strict mode enabled. No `any` type in interfaces. Explicit return types for public functions.

### Code Quality
ESLint + Prettier, or Biome as unified alternative.

### Testing
Vitest or Jest. Co-located test files preferred.

## Structure Conventions

### Naming
- **Files**: `camelCase.ts` or `kebab-case.ts` (pick one per project)
- **Classes/Types/Interfaces**: `PascalCase`
- **Functions/Variables**: `camelCase`
- **Constants**: `UPPER_SNAKE_CASE` or `PascalCase` for enum-like
- **React Components**: `PascalCase.tsx`

### Import Organization
```typescript
// Node built-ins
import path from 'node:path';

// External packages
import express from 'express';

// Absolute imports (path aliases)
import { User } from '@/models/user';

// Relative imports
import { helper } from './utils';
```

### Module Structure
- ES modules (`import`/`export`)
- Barrel files (`index.ts`) for public API surfaces
- `src/` as source root with path alias `@/`

## Common Commands
```bash
# Dev: npm run dev
# Build: npm run build
# Test: npm test
# Lint: npm run lint
# Format: npm run format
# Type check: npx tsc --noEmit
```

## Suggested Permissions
```
Bash(npm:*)
Bash(npx:*)
Bash(pnpm:*)
Bash(bun:*)
Bash(node:*)
```

## Version Management
`version` field in `package.json`. Managed via `npm version` or CI automation.
