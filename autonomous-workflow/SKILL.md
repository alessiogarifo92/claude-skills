---
name: autonomous-workflow
description: Use when the user hands over an end-to-end goal (an app idea, a whole feature set, "take it from here", "vai in autonomia") or asks you to run the workflow unattended — conducts every stage from idea through marketing and deploy by routing to the right skill, agent, model and cross-verification level, and says exactly where it may proceed alone and where it must stop
version: 1.2.0
model: opus
effort: high
---

# Autonomous Workflow

**Run on:** opus · effort high — the conductor is the main session; each stage names its own model.

The conductor. It does not replace any skill's judgment: it sequences them, keeps the state, decides what can run in parallel, and enforces which gates are hard. Nothing important is skipped because nobody was asked, and nothing is asked that could be decided alone.

**Pairs with:** `project-lifecycle` (new project: it owns the phase gates and is entered first), `product-ownership` (per ticket), `orchestrating-agents` (model policy, brief, report contract, verification gate), `cross-verification` (the compare-and-verify panels), `direct-execution` (linear work stays direct), `deploy-readiness`, `handling-sudo-and-missing-tools`.

## When this applies
- A new application/project, an epic, or a backlog the user wants moved forward with minimal hand-holding
- The user says to work autonomously / unattended
- NOT for one scoped ticket (`product-ownership` directly) or a quick question

For a brand-new project, invoke `project-lifecycle` first (its gates and Phase 3.5 text must be in context); this skill then conducts the phases it defines.

## Step 0 — Preflight (every session, before stage 1)
1. Bootstrap present? In a remote session, `alessiogarifo92/claude-skills` must be attached (`add_repo`, clone, `register_repo_root`); if it failed, say so in visible text.
2. Project `CLAUDE.md` has the bootstrap section (global rule) — add it if missing.
3. Tools actually available: `gh` or the GitHub MCP, Playwright, Context7, Docker; a missing `mcp__*` tool means read `.mcp.json` and check env before concluding anything. Ask before any sudo/install (`handling-sudo-and-missing-tools`).
4. Open work: `gh issue list --label "in progress"` and `git worktree list` — never touch another session's locked worktree.
5. Write the stage list as tasks (`TaskCreate`/`TodoWrite` if available, else a state section in the project docs or the epic issue) so progress survives context compaction.

## Stage map
`A` = may proceed alone · `G` = hard gate, stop and prepare one self-contained decision brief · Level = `cross-verification` stakes level.

| # | Stage | Owner skill | Agents (model · effort) | Panel | Autonomy |
|---|---|---|---|---|---|
| 1 | Idea | `brainstorming` / `multi-agent-brainstorm` | at most 3 load-bearing lenses out of `architect` (opus·high), `researcher` (sonnet·med), UI/UX `general-purpose` (pass `model: "sonnet"`), `marketing-strategist` (opus·med, only if there is an audience to win) → `critic` (opus·high). Clarifying questions are batched into the single gate brief | Mode A, L3 | **G**: user picks the direction |
| 2 | Tools & cost | `market-analyst` | `researcher` ×N parallel (sonnet·med); free/cheapest path stated | Mode A if >2 candidates | **G**: stack + cost confirmed |
| 3 | Architecture | `principal-engineering-core`, `architecture-review`, `database-design`, `api-design` | `architect` (opus·high) + a second `architect` dispatched with `model: "sonnet"` and a different lens, then `critic` | Mode A, L3 | **G**: shape confirmed |
| 3.5 | Design UI/UX (if any UI) | `project-lifecycle` phase 3.5, `design` | ≥3 directions on one canvas; `critic` reviews comparability | Mode A | **G**: user picks one direction |
| 4 | Tickets | `ticket-interrogation` first for any slice whose decisions are still open (interview → attack → ticket body, in the main session), then `product-ownership` to publish | `researcher`/`Explore` to ground; milestone + dependencies wired | — | **G**: user confirms the batch once (batched stop point) |
| 4.5 | Repo & CI bootstrap | `project-lifecycle` (repo settings incl. delete-branch-on-merge), `test-verification`; also pick the **preview mechanism** for the manual gate (per-PR preview deploy on a free tier via `market-analyst`, or none) and write it, with the run command and URLs, into the project `CLAUDE.md` "Preview" field | direct; CI runs `python`/`npm`/project test + coverage per the stack | — | **A** (repo creation itself is a user-confirmed action) |
| 5 | Implementation | `worktree-manager` → `writing-plans` (multi-step) → `test-driven-development` + stack skill (`laravel-architecture`, `go-backend`, `python-backend`, `vue-frontend`; `sql-performance` for slow queries, `refactoring-strategy` before a structural change) | direct by default; `implementer` (sonnet·high), `quick-debugger` (sonnet·high), `refactor-optimizer` (sonnet·med); independent tickets in parallel worktrees via `subagent-driven-development` | L1; L2-3 for risky logic | **A** |
| 6 | Verification | `test-verification` | `test-runner` (haiku·low) runs and is the single narrowest re-run at L1; `verifier` (sonnet·med) only at L2+ or for a claim that gates the next phase | Mode B on gating claims | **A**; unit tests for changed logic are mandatory |
| 7 | Review | `requesting-code-review` → `receiving-code-review` | level-gated: L1 `reviewer` alone (or the `code-review` plugin); L2 `reviewer` + the one relevant lens; L3 full Mode C with `critic` | Mode C only at L3 | **A** to fix findings, then at most one re-review by `reviewer` on the changed hunks; **G** if a finding contradicts a user decision |
| 8 | Manual gate & merge | `product-ownership` manual check, `finishing-a-development-branch` | `github-ops` (haiku·low) only for mechanics after decisions | — | **G**: user confirms before push/merge (carve-out only per `product-ownership`) |
| 9 | Deploy | `deploy-readiness`, `security-review` | `release-auditor`, `security-auditor`, `verifier`, `critic` | Mode D, L3 | **G**: go/no-go, spend, DNS |
| 10 | Launch / marketing | `product-marketing-strategist`, `brand-strategist` | `marketing-strategist` ×2 variants, `critic` | Mode F | **G**: nothing is published or sent without the user |
| 11 | Close | `product-ownership` closing, `worktree-manager cleanup` | `github-ops` | — | **A** after the gates above |

Parallelism: independent work inside a stage (research per tool, tickets with no blocker per `gh issue list ... blockedBy`, panelists) goes out in **one message with several `Agent` calls**. Dependent steps stay sequential and direct.

## Global limits
- At most **4 agents running concurrently**, across all panels and implementers; queue the rest.
- Panel caps from `cross-verification` apply per panel; at most one panel per stage per decision.
- Review → fix → re-review: one re-review, then escalate to the user with the evidence.
- Parallel implementers: the main session runs `worktree.sh start <issue> <slug>` per ticket (always pass the slug in a remote session without `gh`) and puts the absolute worktree path in each brief; agents never share a checkout. `isolation: worktree` is for `cross-verification` Mode E only.
- Parallel tickets must not share a database that tests reset: give each worktree its own test DB/schema, or run those suites one at a time (global DB rule).

## Autonomy rules
- **Proceed alone** on anything reversible, in scope, and already decided: reading, researching, drafting, implementing on a branch, tests, review, fixes to findings, cleanup after a landed merge.
- **Always stop** (hard gates, even when told to be autonomous): the user's own decisions (idea direction, stack, architecture, design direction), spending money, publishing/sending anything external, push or merge before the manual gate, deploy/DNS/secrets rotation, destructive operations (force-push, `migrate:fresh`, deleting data or branches not yet merged), and anything the user has said they want to approve.
- **Autopilot** ("go on your own"): the user grants it once. It lets you chain stages A→A without asking, and replaces many small questions with **one decision brief per gate** — options, recommendation, what happens next — never with a silent default. It does not unlock a hard gate.
- **Unreachable user**: do not block the whole project. Park the gated item with its brief complete (ticket comment / task), continue every independent item that needs no decision, and say what is waiting at the end.
- **Ambiguity**: look it up in code, docs or the confirmed decisions first; ask only what you cannot derive, with a recommendation attached.

## Loop per stage
1. Re-read confirmed decisions (project docs/memory); never re-derive them.
2. Run the stage with its owner skill; delegate per `orchestrating-agents` (inline every rule in the brief, announce model + effort).
3. Apply the verification gate to every agent report; run the panel when the level says so.
4. Record outcome and decisions (ticket comment or project docs); update tasks.
5. Gate or proceed per the table.

## Failure handling
- Test/CI fails: root-cause per `debugging-workflow`, fix, re-run; never skip, disable or loosen a test to get green.
- Same fix fails twice: stop guessing — dispatch `quick-debugger` or a blind `verifier` for a second view; third failure → report to the user with evidence.
- Agent `blocked` or off-scope (git commits, extra files): treat as a violation, discard or review the diff, re-dispatch with a tighter brief.
- Context getting long: write state (stage, decisions, open gates, next action) into tasks and the ticket before it compacts.
- Remote session: there is no `~/.claude` and often no `gh`. Run `scripts/install.sh` from the attached clone first; if agents are not picked up in the running session, dispatch `general-purpose` with an explicit `model` and paste the agent file's body into the brief. Use the GitHub MCP equivalents (`issue_write`, `sub_issue_write`, `list_issues`, `merge_pull_request`) where `gh` is missing, and hand repo-settings steps to the user. The browser manual gate needs a reachable preview URL; without one, park it as "needs local check" on the ticket with the exact commands. External design skills (`design`, `taste`, `frontend-design`) may be absent: use the Artifact quickstart for design, and give the `critic` exported screenshots or tokens, not a canvas link.
- Remote session without a tool you need: `read_documentation` for the setup, tell the user the exact setting; do not improvise around a missing connector.

## Red flags
| Thought | Reality |
|---|---|
| "Autonomous means no questions" | It means fewer, better-prepared ones; hard gates remain |
| "I'll draft all tickets and start coding" | Gate 1-3.5 first; tickets drafted on undecided assumptions get redone |
| "A panel for every step" | Level ladder in `cross-verification`; most work is Level 0-1 |
| "The agent said it's done" | Report is a claim; run the gate |
| "I'll publish the post, it's only a draft" | Publishing is external; the user decides |

## Boundary
Conducts and gates; the substance of every stage belongs to its owner skill, and the user owns every decision listed under "Always stop".
