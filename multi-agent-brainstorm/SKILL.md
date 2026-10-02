---
name: multi-agent-brainstorm
description: Use when a new idea or design question needs input from multiple distinct specialties at once — UI/UX, architecture, cost/tooling, code feasibility — before a direction is picked, to gather independent parallel analysis rather than one agent covering every lens sequentially
version: 1.2.0
---

# Multi-Agent Brainstorm

**Run on:** opus · effort high — orchestrator; lenses per its own table.

Gathers independent, parallel analysis from distinct specialties on the same question — it does not decide. The decision stays with the user in the main session, exactly as `orchestrating-agents` phase 1 requires; this skill only enriches phase 2 (data gathering) with multiple simultaneous lenses instead of one pass.

**Pairs with:** `cross-verification` (the compare protocol, Mode A), `autonomous-workflow` (stage 1), `orchestrating-agents` for the dispatch brief/report contract/verification gate that governs every call here; `brainstorming` for the single-lens version of this; `project-lifecycle` phase 1 can call this instead of a single pass when the idea is big enough to warrant it.

## When this applies
- A new feature/product/app idea genuinely spans specialties that would otherwise be reviewed one at a time, burning separate context passes for each
- NOT for a scoped, single-domain question — dispatch one relevant skill/agent directly instead of paying for parallel lenses nobody asked for

## Dispatch pattern
1. Write ONE shared problem statement (the idea, its constraints, what's out of scope) — every agent gets the same brief, only the lens differs.
2. Dispatch one agent per lens, in parallel (single message, multiple Agent calls — never sequential when independent). Match the agent and model to the lens per `orchestrating-agents`' model policy, and announce each model and effort at launch per the global rule — opus only on the lenses where judgment carries the answer (architecture, positioning), sonnet/haiku on the rest, and mix at least two models so errors do not correlate:
   - **UI/UX lens** — `general-purpose` (sonnet): user flows, friction points, accessibility, what a user would actually see first
   - **Architecture lens** — `architect` (opus, preloads both skills): apply `architecture-review` + `principal-engineering-core` to the proposed shape
   - **Marketing/positioning lens** (when the idea has an audience to win) — `marketing-strategist` (opus·medium): who it is for, what they would pay for, how they would hear about it
   - **Cost/tooling lens** — `researcher` (sonnet): apply `market-analyst` to the candidate stack, with current pricing/ToS pages as sources
   - **Code feasibility lens** — `Explore` (haiku) if extending an existing repo; `researcher` (sonnet) for greenfield build-vs-buy
3. Each agent reports read-only findings in the standard STATUS/CHANGES/EVIDENCE/FINDINGS/OPEN shape — none of them touch code or make the call.
4. **Cross-critique round** — hand all lens reports to a `critic` (opus·high), per `cross-verification` Mode A: it lists agreements, conflicts with evidence, and the strongest argument for the option the lenses liked least. Lenses stay blind to each other until this point.
5. Main session synthesizes: where lenses agree, where they conflict (e.g. the UI/UX lens wants a shape the cost lens flags as expensive), and presents the tradeoff to the user for the actual decision.

## Check
- Did every agent get the identical problem statement, or did the lens drift into a different question?
- Did any agent go past analysis into "I recommend implementing X" as a decision? That's a scope violation — flag it, the user decides.
- Were conflicting lenses surfaced explicitly, not silently averaged into a mushy middle recommendation?
- Is every lens actually load-bearing for this decision? Drop the ones that aren't instead of dispatching every lens by default (cap: 3 panelists per round, per `cross-verification`).

## Boundary
This is parallel analysis-gathering, not a decision mechanism and not an implementation dispatch — `orchestrating-agents`' phases 3 onward still govern planning/implementation once the user picks a direction.
