---
name: requesting-code-review
description: Use before merging or completing any non-trivial feature or fix, to decide whether a review pass is warranted and request one, rather than moving straight from tests passing to merge (a change touching a trust boundary also gets `security-review`)
version: 1.2.2
model: opus
effort: high
---

# Requesting Code Review

**Run on:** opus · effort high — orchestrates the review panel; panelists are opus.

Tests passing is necessary, not sufficient. Before merge, explicitly decide whether this change warrants a review pass — this is the trigger discipline, not the review mechanism itself.

**Pairs with:** `cross-verification` (the panel), the `reviewer` / `security-auditor` / `architect` / `critic` agents run the review once requested; the `code-review` plugin is the user-triggered alternative. `architecture-review`, `security-review`, `market-analyst` are the domain lenses to add when relevant. `receiving-code-review` governs what happens with the feedback that comes back.

## When this applies
- Any change beyond a trivial, self-contained fix, before merge — new feature, non-trivial bugfix, anything touching shared or critical code
- NOT required for a tiny, obviously-scoped fix `direct-execution` already covers — though a domain lens can still apply if the file touches structure or trust boundaries

## Rule
Default to requesting review for anything non-trivial. If skipping, say so and why — never skip silently just because tests are green.

## Trigger
Weight the review by the `cross-verification` ladder: L1 `reviewer` alone (opus·high, correctness); L2 `reviewer` plus the one relevant lens (`security-auditor` when a trust boundary is touched, `architect` when structure moves); L3 (auth/payments/PII, data migration, public API, architecture) the full panel in parallel (Mode C) and a `critic` to dedupe and rank. Give each the brief below — agents cannot see this conversation.

Give every reviewer (or, if the user asks for the `code-review` plugin instead, the plugin; or the main session reading the full diff) this brief:
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
This decides *whether and when* to request review. Running it is the review panel (`reviewer` and domain-lens agents), or the `code-review` plugin on request; processing what comes back is `receiving-code-review`.
