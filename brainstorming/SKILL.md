---
name: brainstorming
description: Use when starting new creative work with fuzzy requirements — a new feature, product idea, app, or UI — before any implementation plan or code exists, to surface intent, constraints, and tradeoffs rather than jumping straight to a solution shape
version: 1.0.1
---

# Brainstorming

**Run on:** opus · effort high — framing errors propagate to every later phase.

Before committing to a solution shape, understand the problem shape. This is the requirement-discovery step for genuinely open-ended work.

**Pairs with:** `direct-execution` decides whether this applies at all — skip straight to execution for a linear, single-focus task; escalate here only when requirements are genuinely open. `project-lifecycle` calls this as phase 1 for new-project ideation. `docs-and-specs` writes up the decision once made. `multi-agent-brainstorm` is the parallel-lens version when one perspective isn't enough.

## When this applies
- A new feature, product, app, or UI surface where "what exactly should this do" isn't settled
- Multiple plausible solution shapes exist and picking wrong is expensive to unwind
- NOT for: a scoped bug fix, a one-file change, or anything `direct-execution`'s decision tree already resolves directly

## Loop
1. State the goal in the user's words — the outcome, not the mechanism.
2. Ask only what's decision-relevant: who uses this, what the failure mode is if it's wrong, what existing code/system this touches, what's explicitly out of scope. Skip questions whose answer wouldn't change the approach.
3. Surface 2-3 plausible approaches with the real tradeoff of each — not one default dressed up as a menu.
4. Recommend one, state why, and let the user redirect before any plan or code exists.
5. Hand off: `project-lifecycle` phase 2 (tools/cost) or straight to `docs-and-specs`/implementation once direction is picked.

## Common mistakes
| Mistake | Fix |
|---|---|
| Proposing a full implementation before the goal is confirmed | State the goal back first, wait for confirmation |
| Asking questions whose answer doesn't change the approach | Only ask what's decision-relevant |
| One "recommended" option with no real alternative | Always give the actual tradeoff of at least one other shape |
| Treating this as required for every task | Check `direct-execution` first — most tasks skip this entirely |

## Boundary
This is requirement/intent discovery only. Tool and cost decisions belong to `market-analyst`; architecture soundness belongs to `architecture-review`/`principal-engineering-core`; ticket drafting belongs to `product-ownership`.
