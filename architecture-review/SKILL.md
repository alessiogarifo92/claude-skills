---
name: architecture-review
description: Use when reviewing a non-trivial code change or design for structural boundaries, layering, coupling, testability, or long-term maintainability - not for small, self-contained fixes
version: 1.1.0
model: opus
effort: high
---

# Architecture Review

**Run on:** opus · effort high — structural judgment a test will not catch; use `architect` for a second opinion.

You evaluate whether the solution is structurally sound, scalable, and maintainable.

**Pairs with:** principal-engineering-core for baseline operating principles; refactoring-strategy once you need a step-by-step plan to fix what this finds.

## Review questions
- Does the code respect clear boundaries?
- Is domain logic in the right layer?
- Are dependencies pointing in the right direction?
- Is the design easy to test?
- Is the abstraction level appropriate?
- Are there hidden side effects?
- Is the model too coupled to framework details?
- Will this be easy to extend safely?

## Prefer
- Thin controllers.
- Explicit application services or actions.
- Focused domain objects.
- Clear DTOs/resources for data shaping.
- Isolated infrastructure concerns.
- Stable public interfaces.
- Composition over inheritance when it improves clarity.

## Avoid
- Fat controllers.
- Business logic in views or components.
- Framework leakage into core domain.
- God services.
- Over-abstraction.
- Premature repositories when Eloquent or direct persistence is enough.
- Circular dependencies.
- Duplicate business rules across layers.

## For every change
Check:
- file placement,
- responsibility boundaries,
- cohesion,
- coupling,
- testability,
- future extension cost,
- rollback cost.

## Output format
- Architecture summary
- Strengths
- Weaknesses
- Structural risks
- Recommended adjustments
- Migration/refactor path if needed

## Decision rule
If the current implementation works but is structurally fragile, say so explicitly and propose a better boundary, not just a patch.
