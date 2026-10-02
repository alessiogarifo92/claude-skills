---
name: direct-execution
description: Use when a task is linear and single-focus (one bug, one feature, one file, dependent steps) and you are tempted to orchestrate it — split it into a task list, dispatch subagents per step, or enter a planning workflow — instead of just doing it.
version: 1.4.0
---

# Direct Execution

**Run on:** main · effort medium — a decision rule applied in the current session, any model.

**Pairs with:** `autonomous-workflow` (end-to-end conductor), `cross-verification` (parallel compare for high stakes), `orchestrating-agents` governs HOW to delegate once this skill's tree says delegation buys something. The escalation targets below (`brainstorming`, `ticket-interrogation`, `writing-plans`, `executing-plans`, `subagent-driven-development`) all defer to this tree first — they are what "escalate" means, not alternatives to it.

## Overview

A linear task executed directly costs one focused pass. The same task pushed through orchestration costs a plan, N subagent dispatches, N context reloads, and review glue — with no quality gain, because the steps were never independent. Core principle: **match the process weight to the task shape, and the default weight is zero.**

## Decision

```
Are there ≥2 substantial pieces that do NOT depend on each other?
├─ NO  → execute directly in this session. No task list, no subagents.
└─ YES → does isolation or parallelism actually buy something here?
    ├─ NO  → still execute directly, just in sequence.
    └─ YES → dispatch one agent per independent piece (see below).
```

Steps that depend on each other (fix → test → verify) are ONE task, not three.

## Executing directly

1. Read what you need. Ask if the goal is unclear — don't guess.
2. Make the change.
3. Verify: run the relevant tests/linter; all must pass.
4. Report the outcome. Git actions (commit/push/merge) follow the user's standing rules — never as a side effect.

## Delegating one scoped job

When a single piece of work is well-scoped but you want it off the main context, use one specialized agent for the whole piece — never one agent per step:

- `quick-debugger` (sonnet) — localized bug, clear symptom
- `implementer` (sonnet) — one decided feature/change + its tests
- `refactor-optimizer` (sonnet) — behavior-preserving cleanup of tested code
- `test-runner` (haiku) — run a suite, report outcome only
- `researcher` (sonnet) — external facts/docs; `Explore` (haiku) — locate things in the codebase
- `github-ops` (haiku) — mechanical git/GitHub follow-through, decisions already made
- `reviewer`, `security-auditor`, `architect`, `critic` (opus, read-only) — independent judgment on a diff, a trust boundary, a design, a proposal; `verifier` (sonnet) — independent re-run of a claim; `marketing-strategist` (opus), `release-auditor` (sonnet) — copy and release readiness

Every dispatch follows the `orchestrating-agents` skill: model per task, dispatch brief, structured report (STATUS/CHANGES/EVIDENCE/FINDINGS/OPEN), and the orchestrator's verification gate before any next phase.

## Escalating to planning

Escalate only when the task genuinely needs decisions: architecture choices, unclear requirements, cross-module redesign, or multiple truly independent workstreams. Escalate when complexity *emerges* — not preemptively "to be safe". Where it goes, in order:

- unclear *what* to build → `brainstorming` (or `multi-agent-brainstorm` when the idea spans UI/UX + architecture + cost at once)
- direction picked, but its decisions are still open → `ticket-interrogation` (interview, then attack, then a ticket body)
- intent confirmed, many dependent steps → `writing-plans`, then `executing-plans` to run it
- genuinely independent workstreams → `subagent-driven-development`, per `orchestrating-agents`
- whole project, not one task → `project-lifecycle`; the user wants it run end to end or unattended → `autonomous-workflow`
- the work is linear but the **stakes are high** (architecture, security, data migration, deploy, public copy) → stay direct for the work itself and add `cross-verification` for the check — more agents on the *verification*, not on the steps

## Red flags — you are about to over-orchestrate

- "I'll split this into N numbered tasks" (for dependent steps)
- "I'll dispatch a subagent for each step to be thorough"
- "The skill/process says to orchestrate, so I must" (user instructions outrank skills)
- "More agents = more confidence" (more agents = more overhead, same code)
- "It might have hidden complexity, better plan first" (start; escalate only if it appears)

## Common mistakes

| Mistake | Fix |
|---|---|
| 9-task plan for one scoped fix | One direct pass: read → edit → test |
| Subagent per file touched | One agent (or direct) for the whole change |
| Planning phase for a rename/typo/test addition | Just do it |
| Review agent between dependent steps | Verify at the end, once |
