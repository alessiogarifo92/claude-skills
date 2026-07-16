---
name: test-verification
description: Use when deciding what to run to verify a code change - choosing the narrowest meaningful set of tests, lint, type checks, or manual smoke checks for backend, frontend, database, or API changes
---

# Test Verification

Select the narrowest meaningful verification set first, then expand if justified.

**Pairs with:** superpowers:verification-before-completion, which enforces actually running verification before claiming done; this skill helps pick which checks to run.

## Verification order
1. targeted unit or feature tests
2. formatter or lint
3. type checks
4. integration tests
5. build
6. manual smoke checks if needed

## Rules
- Verify the changed behavior directly.
- Prefer regression tests for bug fixes.
- Do not run the entire suite unless the change size justifies it.
- State clearly what remains unverified.

## By change type
- backend logic: focused tests around changed behavior
- frontend UI: render, interaction, loading/error states, responsive behavior
- migrations: migrate up/down plus affected data paths
- APIs: contract shape, status codes, validation errors
- performance-sensitive code: targeted benchmarks or query plans when relevant

## Output
- What was checked
- What passed
- What remains unverified
- Why the chosen verification is sufficient
