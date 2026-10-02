---
name: orchestrating-agents
description: Use when dispatching any subagent or coordinating multi-phase work (research → plan → implement → verify → deploy) — covers picking the model for the task, writing the dispatch brief, and verifying each agent's report before the next phase.
version: 2.3.0
model: opus
effort: high
---

# Orchestrating Agents

**Run on:** opus · effort high — delegation and verification decisions stay in the main session.

## Overview

The main session is the **orchestrator**: it owns decisions, verification, git, and the user relationship. Agents execute one scoped job each and report back in a fixed structure; the orchestrator verifies every report **before** building the next phase on it. Delegation transfers work, never accountability.

This skill governs HOW to orchestrate once `direct-execution`'s decision tree says delegation buys something. It does not change WHEN to delegate — direct execution stays the default for linear tasks.

## Workflow phases — who does what, on which model

`autonomous-workflow` holds the full stage map with gates; this table is the delegation view.

| Phase | Who | Model · effort |
|---|---|---|
| 1. Brainstorming / design decisions | Main session, with the user (`brainstorming`; `ticket-interrogation` when a decided direction still has open decisions and must become a ticket). The call is never delegated — decisions need the user, and `ticket-interrogation` needs AskUserQuestion, which no agent has. For high-stakes questions, `cross-verification` Mode A gathers blind parallel proposals (`architect`, `researcher`, `marketing-strategist`, UI/UX `general-purpose`) and a `critic` compares them — the user still decides | main session · `architect`/`critic` opus·high, others sonnet |
| 2. Data gathering | `researcher` (external facts, docs, feasibility); `Explore` (locating things in the codebase) | sonnet·medium / haiku·low |
| 3. Planning | Main session (`writing-plans` only for real multi-step work); `architect` as second opinion on L3 designs; user approves the plan | main session · opus·high |
| 4. Implementation | Direct by default (`test-driven-development`). Delegate one whole scoped piece: `implementer` (feature+tests), `quick-debugger` (localized bug), `refactor-optimizer` (behavior-preserving cleanup); independent tickets in parallel via `subagent-driven-development`; `executing-plans` when a written plan drives it | sonnet·high (refactor medium) |
| 5. Verification | `test-runner` runs suites/lint (keeps logs out of context); `verifier` re-derives a gating claim blind; orchestrator re-checks (gate below); manual browser check with the user per global rules | haiku·low / sonnet·medium + main session |
| 6. Review | `requesting-code-review` decides; level-gated per `cross-verification` (L1 `reviewer` alone; L2 + the relevant lens; L3 `reviewer` + `security-auditor` + `architect` in parallel and a `critic` reconciling, Mode C); `receiving-code-review` governs the feedback | opus·high |
| 7. Deploy / closing | Main session decides and does all git. `release-auditor` + `security-auditor` + `verifier` gate the deploy (`deploy-readiness`); `github-ops` only for mechanical follow-through once every decision is made | main session + sonnet·high / haiku·low |
| 8. Launch / marketing | `marketing-strategist` drafts 2+ variants, `critic` red-teams (`cross-verification` Mode F); the user approves anything external | opus·medium |

## Model policy

Three tiers, plus effort. The `model:` and `effort:` in each agent's frontmatter encode this; override per dispatch only with a reason.

- **opus** — judgment where a wrong call is expensive and not caught by a test: architecture, review, security, critique, marketing positioning, and the main session's own decisions. Effort high (medium for copy).
- **sonnet** — anything that diagnoses or writes code (`quick-debugger`, `implementer`, `refactor-optimizer`), synthesizes research (`researcher`), re-derives a claim (`verifier`) or audits a release (`release-auditor`). Tests and the verification gate catch its mistakes; opus would add cost without a matching gain on bounded work. Effort high for diagnosis/new code, medium for refactor/research/verify.
- **haiku** — mechanical jobs with a narrow contract: run-and-report (`test-runner`), locate-and-point (`Explore`), convention-following git/GitHub ops (`github-ops`). Effort low.
- **main session (no delegation)** — design decisions, ambiguity resolution, anything destructive or user-facing, all git state changes.

Escalate a sonnet agent to opus (via the `model` parameter) when its task turns out to be a judgment call rather than bounded work — e.g. a `quick-debugger` bug that crosses subsystems, or a failing second attempt. Drop to haiku only for a truly trivial job. Per-skill and per-agent recommendations: `README.md`. Announce model + effort at launch per the global CLAUDE.md rule.

## Dispatch brief — what the agent receives

Goal in one sentence; exact scope boundaries (files/areas in scope, what NOT to touch); the spec or reproduction (decisions already made — an agent never decides for you); the verification commands to run; the reminder that git belongs to the orchestrator.

**Skills reach an agent only through its frontmatter or the brief.** A subagent does not inherit the main session's loaded skills. Two supported routes exist (verified against the Claude Code subagent docs):

- **`skills:` in the agent's frontmatter** preloads the full skill text at startup. Use it for the skills that apply to *every* run of that agent (`implementer` → `test-driven-development`, `test-verification`; `security-auditor` → `security-review`; `architect` → `architecture-review`). Keep the list short: each preloaded skill costs context on every dispatch.
- **The `Skill` tool** in the agent's `tools:` lets it load an unlisted skill on demand. The brief says which one ("load `laravel-architecture` before writing"). Mechanical agents (`test-runner`, `Explore`, `github-ops`) do not carry it.

Everything else — project conventions, user rules from the global CLAUDE.md, constraints from a skill the agent was not given — reaches the agent **only** if the brief states it. Examples:

- Delegating Laravel work? Name `laravel-architecture` in the brief (the Boost rule lives there) or restate the rule.
- Delegating a test run that touches a shared DB? Restate the no-destructive-reset constraint.
- Delegating an implementation? Restate the test-coverage expectation (unit tests for changed logic, error paths included).

A brief that says "follow our conventions" delegates a lookup the agent may not be able to perform. The failure is silent: plausible work that ignores a rule, surfacing only at your verification gate — or after merge.

**Connecting a connector does not hand it to the agents.** Adding an MCP connector on claude.ai, or a server with `claude mcp add`, makes its tools available to the main session — not to subagents. An agent can use only what its own frontmatter `tools:` lists, and a tool that isn't listed produces no error: the agent doesn't know it exists and falls back in silence to whatever native tool it does have. You get a plausible report produced with the wrong instrument. Update the frontmatter of every agent that should use it in the same move as connecting it — part of adding the connector, not a follow-up.

- **Syntax.** The server-level wildcard `mcp__<Server>__*` works in the frontmatter (`test-runner` carries `mcp__playwright__*`). Spell tools out one by one only where least privilege matters, as `github-ops` does.
- **Prefixed servers need their own entries.** A project server named `github-local` (global rule: repo-level servers must not shadow the built-in `github`) exposes `mcp__github-local__*`; `github-ops` and `release-auditor` list both prefixes, so the same agent works in a cloud session and on a machine with the local server.
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

## Parallel dispatch and comparison

Independent agents go out in **one message with several `Agent` calls**; use `run_in_background` when the main session has other work. When the question is high-stakes, run them blind and compare with a `critic` — the protocol, levels and caps are in `cross-verification`. Panelists get the same problem statement and the minimum context; they never see each other's output in round 1.

## Red flags

- Chaining a second agent on top of an unverified report
- Accepting "all tests pass" without a number or without re-running anything
- Letting an agent resolve an ambiguity the user should decide
- Asking several agents the same question and averaging the answers — compare on evidence (`cross-verification`)
- An agent report mentioning git commit/push — that's a scope violation to flag, not a convenience
