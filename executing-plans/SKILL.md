---
name: executing-plans
description: Use when executing an already-written multi-step plan, including across separate sessions or context resets, to keep steps in order and confirm each one before moving to the next
version: 1.0.1
---

# Executing Plans

**Run on:** sonnet · effort medium — follows a written plan step by step.

Run an already-written plan sequentially, with a checkpoint after each step — including when execution spans multiple sessions or a context reset, where the plan document is the source of truth, not memory.

**Pairs with:** `writing-plans` produces the plan this skill runs. `subagent-driven-development` is the variant for steps that are genuinely independent instead of sequential. `test-verification` supplies what to check at each step's checkpoint.

## When this applies
- A written plan (from `writing-plans` or `docs-and-specs`) exists and execution is starting or resuming
- Steps are sequential/dependent — if they're independent, prefer `subagent-driven-development` instead
- Work may span multiple sessions/context compactions

## Loop per step
1. Re-read the plan (or the relevant step) before acting — never execute from memory of a plan written several turns or sessions ago.
2. Execute exactly that step, nothing beyond its stated scope.
3. Verify per `test-verification` before marking the step done.
4. Report status against the plan (which step, what changed, what's next) — a checkpoint, not a wall of narration.
5. Proceed to the next step only after the checkpoint is clear.

## Rules
- Never skip ahead to a later step "since it's related" — that's exactly how a confirmed plan drifts from what was agreed.
- If a step reveals the plan was wrong, stop and re-confirm the remaining steps with the user instead of silently improvising a replacement.
- Resuming after a context reset: re-read the plan document in full before continuing — don't reconstruct it from a compacted summary.

## Common mistakes
| Mistake | Fix |
|---|---|
| Running all steps in one pass with no checkpoints | Checkpoint after each step, at the plan's own granularity |
| Resuming from memory instead of re-reading the plan | Always re-read before continuing |
| Silently changing the plan mid-execution | Stop, surface the change, get confirmation |

## Boundary
This runs a plan someone already wrote. `writing-plans` decides its shape; `subagent-driven-development` is the parallel-dispatch variant for the steps within it that are independent.
