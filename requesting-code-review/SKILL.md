---
name: requesting-code-review
description: Use before merging or completing any non-trivial feature or fix, to decide whether a review pass is warranted and request one, rather than moving straight from tests passing to merge
version: 1.0.0
---

# Requesting Code Review

Tests passing is necessary, not sufficient. Before merge, explicitly decide whether this change warrants a review pass — this is the trigger discipline, not the review mechanism itself.

**Pairs with:** the `code-review` plugin runs the review once requested. `architecture-review`, `security-review`, `market-analyst` are the domain lenses to add when relevant. `receiving-code-review` governs what happens with the feedback that comes back.

## When this applies
- Any change beyond a trivial, self-contained fix, before merge — new feature, non-trivial bugfix, anything touching shared or critical code
- NOT required for a tiny, obviously-scoped fix `direct-execution` already covers — though a domain lens can still apply if the file touches structure or trust boundaries

## Rule
Default to requesting review for anything non-trivial. If skipping, say so and why — never skip silently just because tests are green.

## Trigger
Invoke the `code-review` plugin (or read the full diff in the main session if unavailable) with:
- the diff or PR reference
- which lens matters most: general correctness, `architecture-review` (structure/boundaries), `security-review` (trust boundaries/input), `market-analyst` (new external dependency)
- what NOT to re-litigate (decisions already confirmed with the user)

## Red flags
| Excuse | Reality |
|--------|---------|
| "Tests pass, that's the real review" | Tests check behavior, not shape, security, or maintainability |
| "It's a small PR, skip review" | Judge by blast radius, not line count — small PRs touch shared code too |
| "I'll request review after merging" | Review before merge is the point; after is just a postmortem |

## Boundary
This decides *whether and when* to request review. Running it is the `code-review` plugin or a domain lens; processing what comes back is `receiving-code-review`.
