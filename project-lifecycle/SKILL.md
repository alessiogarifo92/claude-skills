---
name: project-lifecycle
description: Use when starting a new application or project from scratch, or evaluating one end to end — from initial idea through tool/stack and cost decisions, architecture, breaking the work into tickets, implementation, and deploy — not for a single scoped ticket already in flight
version: 1.2.0
---

# Project Lifecycle

Owns the whole-project arc that sits above a single ticket: an idea becomes a validated stack, a sound architecture, a set of tickets, and eventually a deployed app. `product-ownership` owns each ticket's lifecycle once it exists; this skill decides what tickets should exist and in what order.

**Pairs with:** `brainstorming` (phase 1) or `multi-agent-brainstorm` when the idea spans specialties; `market-analyst` (phase 2); `principal-engineering-core` + `architecture-review` (phase 3); `product-ownership` (phases 4-6, per ticket); `orchestrating-agents` for any parallel work within a phase.

## Phases

| Phase | Skill | Gate before next phase |
|---|---|---|
| 1. Idea | `brainstorming` (or `multi-agent-brainstorm` for multi-specialty ideas) — goal, users, constraints, 2-3 shapes | User picks a direction |
| 2. Tools & cost | `market-analyst` per external tool/API/SaaS/library candidate; state the free-tier and cheapest-viable path explicitly, not just the "best" option | User confirms the stack and its cost profile |
| 3. Architecture | `principal-engineering-core` for operating principles, `architecture-review` for structural shape (plus `database-design` if persistence is involved) | User confirms the shape before any ticket is drafted |
| 4. Tickets | `product-ownership` — one ticket per independently shippable slice, referencing the phase 2/3 decisions instead of re-deriving them | Each ticket drafted and confirmed per `product-ownership`'s own gate |
| 5. Implementation | `product-ownership`'s per-ticket loop (worktree → `writing-plans` if multi-step → direct execution / `test-driven-development` → `test-verification` → `requesting-code-review` → manual gate → `finishing-a-development-branch`) | Same ticket-level gates, unchanged |
| 6. Deploy | Cheapest viable hosting path first (see cost rule); `security-review` before anything becomes publicly reachable (secrets, auth, exposed endpoints); manual verification on the real deploy target, not just locally | User confirms the live deploy |

## Cost rule
Every phase that adds a tool, service, or hosting target restates: what it costs today, what it costs at realistic 10x scale, and whether a free/cheaper path exists that doesn't compromise the actual requirement — per `market-analyst`. Default recommendation is the cheapest option that meets the constraint, not the most capable one available.

## Check
- Idea phase skipped straight to code? Back up — requirements were never confirmed.
- A tool/service adopted without a `market-analyst` verdict? Get one before it lands in a ticket.
- More than one ticket drafted before phase 3's architecture is confirmed? Architecture decisions ripple into every ticket — confirm shape first.
- Tickets don't reference the phase 2/3 decisions? They'll re-derive and drift from what was actually decided.
- Laravel project scaffolded without Laravel Boost? Install it before the first ticket, per CLAUDE.md — tickets written against source files instead of the running app start drifting from phase 3's decisions immediately.
- About to make something publicly reachable without a `security-review` pass over secrets/auth/exposed endpoints? Do it before the deploy, not after the first incident.
- Recurring cost of the deployed stack never restated at deploy time? Phase 2's estimate was for the plan; confirm what's actually being billed now.

## Boundary
This skill sequences *which skill runs when* for a whole project; it doesn't replace any of their internal judgment. A single ticket in an already-running project never needs this — start directly at `product-ownership`.
