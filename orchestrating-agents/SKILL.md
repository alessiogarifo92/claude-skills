---
name: orchestrating-agents
description: Use when dispatching any subagent or coordinating multi-phase work (research → plan → implement → verify → deploy) — covers picking the model for the task, writing the dispatch brief, and verifying each agent's report before the next phase.
version: 2.7.0
model: opus
effort: high
---

# Orchestrating Agents

**Run on:** opus · effort high — delegation and verification decisions stay in the main session.

**Pairs with:** `direct-execution` (decides *whether* to delegate; this skill decides *how*), `cross-verification` (blind panels and the critic), `autonomous-workflow` (the stage map that calls the agents), `subagent-driven-development` and `multi-agent-brainstorm` (parallel dispatch shapes).

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
| 4. Implementation | Direct by default (`test-driven-development`). Delegate one whole scoped piece: `implementer` (feature+tests), `quick-debugger` (localized bug), `refactor-optimizer` (behavior-preserving cleanup); independent tickets in parallel via `subagent-driven-development`; `executing-plans` when a written plan drives it | `implementer` opus·high; `quick-debugger` sonnet·high; `refactor-optimizer` sonnet·medium |
| 5. Verification | `test-runner` runs suites/lint (keeps logs out of context); `verifier` re-derives a gating claim blind; orchestrator re-checks (gate below); manual browser check with the user per global rules | haiku·low / sonnet·medium + main session |
| 6. Review | `requesting-code-review` decides; level-gated per `cross-verification` (L1 `reviewer` alone; L2 + the relevant lens; L3 `reviewer` + `security-auditor` + `architect` in parallel and a `critic` reconciling, Mode C); `receiving-code-review` governs the feedback | opus·high |
| 7. Deploy / closing | Main session decides and does all git. `release-auditor` + `security-auditor` + `verifier` gate the deploy (`deploy-readiness`); `github-ops` only for mechanical follow-through once every decision is made | main session + sonnet·high / haiku·low |
| 8. Launch / marketing | `marketing-strategist` drafts 2+ variants, `critic` red-teams (`cross-verification` Mode F); the user approves anything external | opus·medium |

## Model policy

Three tiers, plus effort. The `model:` and `effort:` in each agent's frontmatter encode this; override per dispatch only with a reason.

- **opus** — judgment where a wrong call is expensive and not caught by a test: architecture, review, security, critique, marketing positioning, and the main session's own decisions; and **writing new product code** (`implementer`, a child session implementing a feature or a non-trivial fix), because design quality inside the code (structure, naming, edge cases the spec missed) is exactly what tests do not catch. Effort high (medium for copy).
- **sonnet** — work whose output a deterministic check accepts or rejects, and work that writes no product code: a localized bug with a reproduction (`quick-debugger`), a behavior-preserving refactor under existing tests (`refactor-optimizer`), content a tool verifies (a level stage the solver accepts, a PR brought back to green), playtest and other agents driving the app, research synthesis (`researcher`), docs, re-deriving a claim (`verifier`), release audit (`release-auditor`). The check catches its mistakes, so opus would add cost without a matching gain. Effort high for diagnosis, medium for refactor/research/verify.
- **haiku** — mechanical jobs with a narrow contract: run-and-report (`test-runner`), locate-and-point (`Explore`), convention-following git/GitHub ops (`github-ops`). Effort low.
- **main session (no delegation)** — design decisions, ambiguity resolution, anything destructive or user-facing, all git state changes.

Model choice is the smaller lever: on mix-splash the most expensive work (playtest) already ran on sonnet; context size and the number of parallel sessions moved the cost far more, so opus for code is affordable only with the Token budget below in force. Escalate a sonnet agent to opus (via the `model` parameter) when its task turns out to be a judgment call rather than bounded work — e.g. a `quick-debugger` bug that crosses subsystems, or a failing second attempt. Drop to haiku only for a truly trivial job. Per-skill and per-agent recommendations: `README.md`. Announce model + effort at launch per the global CLAUDE.md rule.

## Token budget

Every request re-reads the whole context, so cost grows with **context size × number of calls**, not with the size of the task. One long session that plays, polls or loops costs far more than the same work split into short ones.

- **Child sessions take the model policy too.** A session opened with `create_session` inherits the caller's model unless `model` is passed, so pass it every time. Opus (`claude-opus-5-5`, or the current opus id) for a session that writes new product code (a mechanic, UI, `src/core` rules, a non-trivial bug) or owns decisions (the manager, design, architecture) — **at most 2 opus code sessions at once**. Sonnet (`claude-sonnet-5-5`, or the current sonnet id) for a session whose output a tool verifies or that writes no product code: a level stage the solver accepts, a PR to green, a playtest turn, research, docs. State the model when announcing the session.
- **Parallel sessions: 2-3, not 5** (of which at most 2 on opus writing code). Each one starts cold (bootstrap, CLAUDE.md, skills listing, repo reads) and they all draw on the same weekly limit. Open the next wave when one closes, and only for tickets whose blockers are merged — a session that waits for a sibling's PR to be aligned is paying to wait.
- **Short contexts, compacted automatically.** The model cannot run `/compact` (it is a user command), so compaction is configuration: `CLAUDE_CODE_AUTO_COMPACT_WINDOW=200000` makes every session and subagent auto-compact near 160K tokens instead of near 800K on the 1M window, where every call costs 5× what it did at the start. The SessionStart hook writes it into `~/.claude/settings.json` (settings `env` reloads live, so it applies to the running session); `settings.json` and `templates/cloud-setup-script.sh` carry it too. Keep the state (done, open, next step) on the ticket so a compaction loses nothing, and hand a long tail of work to a fresh session rather than dragging a big context. Never ask the user to type `/compact`.
- **Agents that loop on a UI or a simulation** (playtest agents, browser drivers): one bounded job per agent (one level pack, one flow), a hard cap on actions, and read a screenshot only when the screen has settled — every image read stays in that agent's context for every later call. Answer what a deterministic tool can answer (a solver, a script, a test) with the tool, and keep LLM agents for what needs a player's eye.
- **Check-ins.** A `send_later` / scheduled check-in re-reads the whole manager context each time it fires. Space them by how fast the awaited thing changes (CI ~15-30 min, a child ticket 1-2 h), and arm none while parked on a user gate — child sessions report back with `send_message` anyway.
- **Archive finished sessions.** When a child session, or any session that completed one or more tickets, is done — final report verified, its PR merged or its ticket closed, nothing left waiting on it — archive it with `archive_session` in the same closing step, so the session list shows only live work. Archiving loses nothing: an archived session stays readable with `get_session` and `list_events` (verified 2026-11-05 on mix-splash, final result text included), and `unarchive_session` reopens it if it must work again. The orchestrator archives its children; a session never archives itself mid-turn — a standalone session tells the user it can be archived. Don't archive a session that still owns an open PR, a pending check-in or an unanswered question.
- **Why:** on mix-splash (29 Oct-4 Nov 2026) one manager on opus opened 20+ opus child sessions in waves of 4-5; two playtest sessions alone cost ~$120 of the ~$330 total at list price (580M cache-read tokens from sonnet playtest agents driving the game by screenshot), each request carried 200-340K tokens of context, and the weekly limit reached its warning in six days.

## Dispatch brief — what the agent receives

Goal in one sentence; exact scope boundaries (files/areas in scope, what NOT to touch); the spec or reproduction (decisions already made — an agent never decides for you); the verification commands to run; the reminder that git belongs to the orchestrator. That reminder is also enforced: every agent but `github-ops` carries a PreToolUse hook (`scripts/agent-guard.sh`) that blocks git and GitHub writes, so a brief asking an agent to commit, push, merge or close an issue fails by design. Edits to agent files take effect in sessions started after them; a running session keeps the definitions it loaded.

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
