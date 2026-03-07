# Testing Standards

[Purpose: guide what to test, where tests live, and how to structure them]

## Philosophy
- Test behavior, not implementation
- Prefer fast, reliable tests; minimize brittle mocks
- Cover critical paths deeply; breadth over 100% pursuit

## Organization
Options:
- Co-located: source file + test file side by side
- Separate: `/src/...` and `/tests/...`
Pick one as default; allow exceptions with rationale.

Naming:
- Files: `*.test.*` or `*.spec.*`
- Suites: what is under test; Cases: expected behavior

## Testing School (Classical / Detroit)
- Prefer real collaborators over mocks for internal dependencies
- Mock only at external boundaries: DB, network, filesystem, third-party APIs
- Internal classes/functions should be exercised as real instances — catches integration issues early
- Thin passthrough/CRUD layers: integration test is sufficient — skip isolated unit tests

## Test Types
- Unit: single unit, real internal collaborators, mock externals only, very fast
- Integration: multiple units together, mock externals only
- E2E: full flows, minimal mocks, only for critical journeys

## Structure (AAA)
```
test "does X when Y":
  // Arrange — set up preconditions
  input = setup()
  // Act — execute the behavior
  result = act(input)
  // Assert — verify the outcome
  assert result == expected
```

## Mocking & Data
- Mock externals (API/DB); never mock the system under test
- Never mock internal collaborators — use real instances
- Use factories/fixtures; reset state between tests
- Keep test data minimal and intention-revealing

## Anti-Patterns
- **Over-mocking**: mocking internal dependencies makes tests refactor-fragile and hides integration bugs
- **Duplication**: testing the same behavior at unit + integration + E2E levels wastes effort and creates noise on failure
- **Implementation coupling**: asserting on internal method calls/counts rather than observable outcomes (inputs→outputs, state changes)
- **Coverage chasing**: adding tests for trivial getters/setters/passthrough to inflate metrics
- **Green-at-all-costs**: when a test fails, fix the code or requirements — do not add mocks to silence the failure

## Coverage
- Target: [% overall]; higher for critical domains
- Enforce thresholds in CI; exceptions require review rationale

---
_Focus on patterns and decisions. Tool-specific config lives elsewhere._
