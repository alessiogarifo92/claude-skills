---
name: orchestrating-agents
description: Use when dispatching any subagent or coordinating multi-phase work (research → plan → implement → verify → deploy) — covers picking the model for the task, writing the dispatch brief, and verifying each agent's report before the next phase.
version: 1.0.0
---

# Orchestrating Agents

## Overview

The main session is the **orchestrator**: it owns decisions, verification, git, and the user relationship. Agents execute one scoped job each and report back in a fixed structure; the orchestrator verifies every report **before** building the next phase on it. Delegation transfers work, never accountability.

This skill governs HOW to orchestrate once `direct-execution`'s decision tree says delegation buys something. It does not change WHEN to delegate — direct execution stays the default for linear tasks.

## Workflow phases — who does what, on which model

| Phase | Who | Model |
|---|---|---|
| 1. Brainstorming / design decisions | Main session, with the user. Never delegated — decisions need the user. | main session |
| 2. Data gathering | `researcher` (external facts, docs, feasibility); `Explore` (locating things in the codebase) | sonnet / haiku |
| 3. Planning | Main session (`writing-plans` only for real multi-step work); user approves the plan | main session |
| 4. Implementation | Direct by default. Delegate one whole scoped piece: `implementer` (feature+tests), `quick-debugger` (localized bug), `refactor-optimizer` (behavior-preserving cleanup) | sonnet |
| 5. Verification | `test-runner` for suites/lint (keeps logs out of context); orchestrator re-checks (gate below); manual browser check with the user per global rules | haiku + main session |
| 6. Review | `/code-review` (user-triggered) or main session reading the full diff | — |
| 7. Deploy / closing | Main session only: commit, push, merge, release — after tests + manual gate + user confirmation. `github-ops` only for mechanical follow-through once every decision is made | main session + haiku |

## Model policy

- **haiku** — mechanical jobs with a narrow contract: run-and-report (`test-runner`), locate-and-point (`Explore`), convention-following git/GitHub ops (`github-ops`).
- **sonnet** — anything that diagnoses or writes code (`quick-debugger`, `implementer`, `refactor-optimizer`) or synthesizes external facts into a report the orchestrator will rely on (`researcher`). A wrong diagnosis or subtly wrong code costs far more than the model delta.
- **main session (no delegation)** — design decisions, ambiguity resolution, anything destructive or user-facing, all git state changes.

Override per dispatch with the `model` parameter when the task's weight clearly differs from the agent's default (e.g. a truly trivial one-line fix → haiku), and announce model + effort at launch per the global CLAUDE.md rule.

## Dispatch brief — what the agent receives

Goal in one sentence; exact scope boundaries (files/areas in scope, what NOT to touch); the spec or reproduction (decisions already made — an agent never decides for you); the verification commands to run; the reminder that git belongs to the orchestrator.

## Report contract — what the agent returns

Every custom agent reports in this structure (their system prompts require it):

- **STATUS**: `done` | `partial` | `blocked` — with the reason if not `done`.
- **CHANGES**: each file touched and what changed (`none` for read-only agents).
- **EVIDENCE**: exact commands run and their outcomes (test counts before/after, repro output, URLs).
- **FINDINGS**: what was learned — root cause, discoveries, anything suspicious left untouched.
- **OPEN**: questions, out-of-scope suggestions, follow-ups.

## Verification gate — before the next phase

An agent's report is a claim, not a fact. Before continuing:

1. **STATUS ≠ done** → resolve the blocker or answer the open question first; never route around a `blocked` report.
2. **Code-changing agents**: run `git status`/`git diff --stat` and skim the diff — does it match CHANGES and the scope you gave? Re-run the narrowest relevant test yourself (or via `test-runner`) — does it match EVIDENCE?
3. **Research/exploration**: spot-check at least one load-bearing claim (open the cited file/line, fetch one key source). If the next phase depends entirely on it, check more.
4. **Verification fails** → send the discrepancy back to the same agent (SendMessage keeps its context) or fix trivially in the main session — but say so. Never silently accept a report that didn't check out, and never start phase N+1 on an unverified phase N.

## Red flags

- Chaining a second agent on top of an unverified report
- Accepting "all tests pass" without a number or without re-running anything
- Letting an agent resolve an ambiguity the user should decide
- An agent report mentioning git commit/push — that's a scope violation to flag, not a convenience
