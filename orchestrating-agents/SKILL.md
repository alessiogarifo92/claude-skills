---
name: orchestrating-agents
description: Use when dispatching any subagent or coordinating multi-phase work (research → plan → implement → verify → deploy) — covers picking the model for the task, writing the dispatch brief, and verifying each agent's report before the next phase.
version: 1.3.0
---

# Orchestrating Agents

## Overview

The main session is the **orchestrator**: it owns decisions, verification, git, and the user relationship. Agents execute one scoped job each and report back in a fixed structure; the orchestrator verifies every report **before** building the next phase on it. Delegation transfers work, never accountability.

This skill governs HOW to orchestrate once `direct-execution`'s decision tree says delegation buys something. It does not change WHEN to delegate — direct execution stays the default for linear tasks.

## Workflow phases — who does what, on which model

| Phase | Who | Model |
|---|---|---|
| 1. Brainstorming / design decisions | Main session, with the user (`brainstorming`). Never delegated — decisions need the user. `multi-agent-brainstorm` may gather parallel lenses as phase-2 input, but the call still happens here. | main session |
| 2. Data gathering | `researcher` (external facts, docs, feasibility); `Explore` (locating things in the codebase) | sonnet / haiku |
| 3. Planning | Main session (`writing-plans` only for real multi-step work); user approves the plan | main session |
| 4. Implementation | Direct by default (`test-driven-development` for the test/code order). Delegate one whole scoped piece: `implementer` (feature+tests), `quick-debugger` (localized bug), `refactor-optimizer` (behavior-preserving cleanup); `executing-plans` / `subagent-driven-development` when a written plan drives it | sonnet |
| 5. Verification | `test-runner` for suites/lint (keeps logs out of context); orchestrator re-checks (gate below); manual browser check with the user per global rules | haiku + main session |
| 6. Review | `requesting-code-review` decides whether a pass is warranted; the `code-review` plugin (user-triggered) or main session reads the full diff; `receiving-code-review` governs the feedback that comes back | — |
| 7. Deploy / closing | Main session only: commit, push, merge, release — after tests + manual gate + user confirmation. `github-ops` only for mechanical follow-through once every decision is made | main session + haiku |

## Model policy

- **haiku** — mechanical jobs with a narrow contract: run-and-report (`test-runner`), locate-and-point (`Explore`), convention-following git/GitHub ops (`github-ops`).
- **sonnet** — anything that diagnoses or writes code (`quick-debugger`, `implementer`, `refactor-optimizer`) or synthesizes external facts into a report the orchestrator will rely on (`researcher`). A wrong diagnosis or subtly wrong code costs far more than the model delta.
- **main session (no delegation)** — design decisions, ambiguity resolution, anything destructive or user-facing, all git state changes.

Override per dispatch with the `model` parameter when the task's weight clearly differs from the agent's default (e.g. a truly trivial one-line fix → haiku), and announce model + effort at launch per the global CLAUDE.md rule.

## Dispatch brief — what the agent receives

Goal in one sentence; exact scope boundaries (files/areas in scope, what NOT to touch); the spec or reproduction (decisions already made — an agent never decides for you); the verification commands to run; the reminder that git belongs to the orchestrator.

**Inline every rule the agent must follow — agents cannot load skills.** None of the custom agents in `~/.claude/agents/` carries the `Skill` tool (verified against all seven frontmatters), so an agent can never invoke `product-ownership`, `test-verification`, `laravel-architecture` or any other skill to find out how this project works. Whatever a skill says about the job you're delegating reaches the agent **only** if you paste the relevant constraint into the brief. Skills are an orchestrator-side resource: the main session loads them, extracts what applies, and hands the agent the concrete instruction.

- Delegating Laravel work? The Boost rule lives in `laravel-architecture` — restate it, don't assume.
- Delegating a test run that touches a shared DB? Restate the no-destructive-reset constraint (it's in the global CLAUDE.md, which the brief should still make explicit rather than rely on).
- Delegating an implementation? Restate the test-coverage expectation and any convention the skill would have supplied.

A brief that says "follow our conventions" delegates a lookup the agent has no way to perform. The failure is silent: the agent produces plausible work that quietly ignores a rule, and it surfaces only at your verification gate — or worse, after merge.

**Connecting a connector does not hand it to the agents.** Adding an MCP connector on claude.ai, or a server with `claude mcp add`, makes its tools available to the main session — not to subagents. An agent can use only what its own frontmatter `tools:` lists, and a tool that isn't listed produces no error: the agent doesn't know it exists and falls back in silence to whatever native tool it does have. You get a plausible report produced with the wrong instrument. Update the frontmatter of every agent that should use it in the same move as connecting it — part of adding the connector, not a follow-up.

- **Syntax.** The server-level wildcard `mcp__<Server>__*` works in the frontmatter (`test-runner` carries `mcp__playwright__*`). Spell tools out one by one only where least privilege matters, as `github-ops` does.
- **The server name is load-bearing.** `Context7` (the claude.ai connector) and `context7` (`claude mcp add context7`) are different names. A wildcard that doesn't match the real server name doesn't fail — it matches nothing, silently.
- **The frontmatter is half the change.** If the agent's prompt doesn't say *when* to prefer the new tool, gravity stays with the native tool it already knows. `test-runner` needed an explicit Playwright constraint; `researcher` needed a precedence rule for Context7. Ship both halves or neither.
- **Not every agent should get one.** All four must hold: the agent actually runs that phase (not "it might come up"); without the tool its fallback is materially worse, not merely different; the tool is read-only, or its writes are inside the agent's mandate; the prompt says when to prefer it. An agent failing any one keeps what it has — adding tools "just in case" widens the surface for nothing.

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
