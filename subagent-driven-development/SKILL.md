---
name: subagent-driven-development
description: Use when executing a written plan whose steps are genuinely independent, dispatching one subagent per independent task in the current session instead of running them sequentially
version: 1.2.0
model: opus
effort: medium
---

# Subagent-Driven Development

**Run on:** opus · effort medium — orchestrator; implementers are sonnet.

Once `writing-plans` has flagged which steps of a plan are genuinely independent, dispatch them in parallel within the current session instead of running them one by one — then verify every report before treating that phase as done.

**Pairs with:** `autonomous-workflow` (stage 5), `cross-verification`, `orchestrating-agents` supplies the model policy, dispatch brief, report contract, and verification gate this skill runs on. `direct-execution`'s decision tree is what should have flagged parallel dispatch as worth it in the first place. `executing-plans` is the sequential counterpart for dependent steps.

## When this applies
- A plan has 2+ steps genuinely independent of each other — no shared state, no sequential dependency
- NOT for dependent steps (`executing-plans` instead) and not for a single scoped job (`direct-execution` handles that with one agent, not a fleet)

## Pattern
1. From the plan, re-confirm which steps are truly independent — "listed separately" is not the same as "independent."
2. For code-writing steps the orchestrator first runs `worktree.sh start <issue> <slug>` per ticket and puts the absolute worktree path in that agent's brief — agents never share a checkout. Then dispatch one agent per independent step in a single batch, per `orchestrating-agents`: model matched to task, full dispatch brief, no shared scope between agents.
3. Each agent reports in the STATUS/CHANGES/EVIDENCE/FINDINGS/OPEN contract.
4. Apply the verification gate to every report individually before considering that plan phase done.
5. For any report that gates the next phase, add a blind `verifier` (`cross-verification` Mode B) instead of re-reading the author's reasoning.
6. Reconcile only in the main session — agents never read or touch each other's output.

## Common mistakes
| Mistake | Fix |
|---|---|
| Dispatching a step that secretly depends on another's output | Re-verify independence before batching; run it sequentially via `executing-plans` if unsure |
| Treating all N reports as done because most came back clean | Every report gets the verification gate individually |
| One subagent per file instead of per independent task | Group by task/decision, not by file touched |

## Boundary
This is the parallel-dispatch execution mode for an already-written plan. Picking the model and writing the dispatch brief is `orchestrating-agents`' job; deciding steps are independent happens when the plan is written (`writing-plans`) or re-confirmed here.
