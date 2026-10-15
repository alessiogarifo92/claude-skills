---
name: project-lifecycle
description: Use when starting a new application or project from scratch, or evaluating one end to end — from initial idea through tool/stack and cost decisions, architecture, breaking the work into tickets, implementation, and deploy — with the user steering each phase (when unattended, `autonomous-workflow` conducts it) — not for a single scoped ticket already in flight
version: 1.13.0
model: opus
effort: high
---

# Project Lifecycle

**Run on:** opus · effort high — phase gates and decisions.

Owns the whole-project arc that sits above a single ticket: an idea becomes a validated stack, a sound architecture, a set of tickets, and eventually a deployed app. `product-ownership` owns each ticket's lifecycle once it exists; this skill decides what tickets should exist and in what order.

**Pairs with:** `brainstorming` (phase 1) or `multi-agent-brainstorm` when the idea spans specialties; `market-analyst` (phase 2); `principal-engineering-core` + `architecture-review` (phase 3); `design`, plus the external `impeccable` / `taste` / `emil-design-eng` and `brand-strategist` (phase 3.5); `product-ownership` (phases 4-6, per ticket); `orchestrating-agents` for any parallel work within a phase; `autonomous-workflow` to run the whole table unattended (it owns the gates' autonomy rules); `cross-verification` for the phase 1/2/3/3.5/6 panels; `deploy-readiness` (phase 6); `product-marketing-strategist` + `brand-strategist` (phase 7).

## Phases

| Phase | Skill | Gate before next phase |
|---|---|---|
| 1. Idea | `brainstorming` (or `multi-agent-brainstorm` for multi-specialty ideas, with its cross-critique round) — goal, users, constraints, 2-3 shapes | User picks a direction |
| 2. Tools & cost | `market-analyst` per external tool/API/SaaS/library candidate; state the free-tier and cheapest-viable path explicitly, not just the "best" option | User confirms the stack and its cost profile |
| 3. Architecture | `principal-engineering-core` for operating principles, `architecture-review` for structural shape (plus `database-design` if persistence is involved); `architect` agents with different lenses (override one to `model: sonnet`) + a `critic` (`cross-verification` Mode A) when the architecture is a real risk; a small, no-spend project gets one `architect` + `critic` | User confirms the shape before any ticket is drafted |
| 3.5. Design UI/UX (only if the project has a user-facing UI) | Propose it explicitly here, don't wait to be asked — see "Phase 3.5 in detail" below for the five steps it runs; the global CLAUDE.md rule "Never skip a Design UI/UX phase before development" states the failure mode this prevents | User picks **one** named direction out of several (or explicitly defers the phase, e.g. "ship default styling for now") before any UI-bearing ticket is drafted |
| R. Repo & CI (not a numbered phase: after phase 1, before phase 4) | the repo is created at the **end of phase 1** (confirmed in the phase-1 gate), with bootstrap `CLAUDE.md` and `docs/decisions.md`; CI and the manual-gate preview mechanism are set up before the first implementation ticket (`autonomous-workflow` stages 1.5 and 4.5) | User confirms repo creation; provider accounts are the user's |
| 4. Tickets | `ticket-interrogation` first on any slice whose requirements are still fuzzy (it produces the ticket body), then `product-ownership` — one ticket per independently shippable slice, referencing the phase 2/3/3.5 decisions instead of re-deriving them; the whole batch gets its own milestone (e.g. "MVP") per `product-ownership`'s milestone convention, instead of only naming the range in ticket text | Each ticket drafted and confirmed per `product-ownership`'s own gate |
| 5. Implementation | `product-ownership`'s per-ticket loop (worktree → `writing-plans` if multi-step → direct execution / `test-driven-development` → `test-verification` → `requesting-code-review` → manual gate → `finishing-a-development-branch`) | Same ticket-level gates, unchanged |
| 6. Deploy | `deploy-readiness` — cheapest viable hosting path first (see cost rule); `security-review` before anything becomes publicly reachable (secrets, auth, exposed endpoints); `release-auditor` + `security-auditor` + `verifier` panel; smoke test on the real deploy target, not just locally | User confirms go/no-go, then the live deploy |
| 7. Launch (only if a public launch was asked for) | `product-marketing-strategist` (+ `brand-strategist`): positioning, landing copy, launch channels; `marketing-strategist` agent drafts 2+ variants, `critic` red-teams them (`cross-verification` Mode F) | User approves everything before it is published or sent |

## Target platforms are a phase 1-2 decision
Which platforms the app runs on (web, installable PWA, native/Expo, store-distributed) is settled in the phase-1 brief and costed in phase 2, not discovered at deploy:
- **Installable PWA:** Android **and** iOS are both targets by default, without waiting for the user to say so. The iOS limits (no install prompt, storage separate from Safari, web push only once installed on the Home Screen) go into the phase-1/2 brief, because they can decide PWA vs a wrapped/native app — e.g. when push notifications are core. Every PWA-related ticket names both platforms in its acceptance criteria; the checks are in `test-verification`'s "Installable web apps (PWA)" section.
- **Native / store apps:** phase 2 states the recurring costs up front per the cost rule — Apple Developer Program (yearly), Google Play (one-off), the cloud build service quota, macOS CI minutes, an optional device cloud — and which devices the user owns for the real-device pass. The build and store path is `deploy-readiness` 2c; where the UI flows run in CI is decided in ticket 0 (`autonomous-workflow` stage 4.5).

## When the project's GitHub repo is created
Whenever this skill creates the project's repository (or picks up a project whose repo it just created), turn on **Automatically delete head branches** in the same step, before the first ticket branch exists:

```bash
gh repo edit <owner>/<repo> --delete-branch-on-merge
```

- **Commit the skills SessionStart hook in the first commit too**: copy `templates/session-start-hook.sh` to `.claude/session-start-hook.sh` and register it in `.claude/settings.json` (the JSON is in the script's header). Every later session, local or remote, then starts by fast-forwarding the skills clone, re-running `install.sh`, and printing the skills commit, whether it is behind, the repo's visibility (private = finite Actions minutes) and the entry skills. It is the deterministic half of the bootstrap: it does not depend on the session remembering to check.
- **Record the repo's visibility** (`gh api repos/<owner>/<repo> --jq .private`) in the project `CLAUDE.md` "Repo visibility" line; `test-verification` uses it to decide how to treat a CI job that never starts.
- **Commit the project `CLAUDE.md` in the first commit**, built from `templates/project-CLAUDE-bootstrap.md` (the attach-the-skills-repo section plus the "Run / preview" field). A project created without it runs every later remote session with none of these rules.
- GitHub has no account- or org-wide default for it, and template repos copy files, not settings: it must be set per repo, at creation, or it silently stays off.
- In a remote session without `gh` (the GitHub MCP server has no repo-settings tool), hand the user the one-click path instead — *Settings → General → Pull Requests → Automatically delete head branches* — and don't consider repo setup done until they confirm it.
- It only deletes the head branch of a PR that is **merged**. Branches merged without a PR (fast-forward pushes) and PRs closed unmerged (superseded) still need `finishing-a-development-branch` / `worktree-manager` cleanup.
- **Why:** on tisane-match the setting was off, so after the MVP PR merged, its head branch and four other merged ticket branches stayed on GitHub — and the remote session could not delete them (its git proxy refuses branch deletion), leaving the cleanup to the user by hand.

## Phase 3.5 in detail — producing options the user can actually choose between

The gate is a *choice*, and a choice needs more than one candidate. One take, or a design described in prose, forces the user to accept or reject blind — that is the phase failing, not the phase running.

### Step 1 — Ground it before designing anything
Read what already exists first: the project's own plan (`strategia-progetto.md` or equivalent), any reference site, brand, or palette signal the user already gave, the phase-3 architecture, and the actual screens the phase-4 tickets will cover. Write those screens down by name — every direction in step 3 is drawn on the same 2-3 of them, or they are not comparable.

### Step 2 — Pick where the aesthetic direction comes from
| Situation | Source of the direction |
|---|---|
| The user handed over a reference site ("make it feel like X") | `taste` (external, `senlindesign/taste-skill`) on that URL → `{domain}.md` + `{domain}.json`, concrete tokens plus Trigger→Decision→Reason→Evidence trade-offs, becomes the brief. Needs Playwright MCP installed at **user** scope (`claude mcp add playwright -s user -- npx -y @playwright/mcp@latest --isolated`), never in a committed `.mcp.json` — see the global CLAUDE.md rule on `.mcp.json` in remote sessions. |
| Greenfield: no reference, no established brand | `impeccable` (external, `pbakaus/impeccable`; it extends Anthropic's `frontend-design` and replaces it here) → `/impeccable init` writes `PRODUCT.md`: seed it from the phase 1-3 decisions in `docs/decisions.md` instead of re-interviewing the user, then `/impeccable shape` per surface. It picks a *mode* per surface (Persuade for landing/pricing, Operate for app UI, Read for docs), which keeps an app shell from being styled like a landing page. Each direction still ends as palette (4-6 named hex), 2+ typeface roles, a layout concept, one signature element. |
| Existing product whose design system or brand is already decided | Its tokens are the constraint and `brand-strategist` owns them. Run `/impeccable document` to write the incumbent system into `DESIGN.md` first; impeccable's own rule "the brief wins, refinement preserves" keeps it inside those tokens. Explore *within* them — layout, density, hierarchy — not around them. (Plain `frontend-design` stays skipped here: its "take one real aesthetic risk" fights "one visual language per product".) |
| No real user-facing UI (internal tool, CLI, API-only) | Defer the phase explicitly and say so, per the gate. |

### Step 3 — Put at least three comparable directions on one canvas
Use `design` (`/design`) — not prose, not frontend code. One canvas; each direction drawn on **the same** 2-3 screens from step 1; each carrying a name the user can point at.

- Distinct means a different thesis, not a recolor: type pairing, layout density, and the hierarchy of the primary screen should each differ. If two directions survive swapping their palettes, they are one direction.
- Label each direction on the canvas with its own tokens (palette hex, type roles, spacing scale), so picking a direction also picks what the tickets inherit.
- Give each direction its motion tokens too (2-3 durations, the easing curves, what animates and what never does), from `emil-design-eng`'s decision framework: frequency first (a command palette opened 100 times a day gets no animation), UI motion under 300 ms, custom ease-out curves rather than CSS defaults, nothing scales in from 0. Motion left undecided here gets improvised per ticket and drifts.
- Say which one you'd ship and why, in one line. A recommendation is not a substitute for options, but options with no point of view are a shrug.

### Step 4 — Escalate to a clickable prototype when the screens carry state
Static artboards cannot show what a screen *does*. Prototype when there are empty/loading/error states, multi-step flows, expand-on-tap, or filters; skip it for essentially static pages.

| Route | When to take it |
|---|---|
| An HTML Artifact built here | Fastest path to something tappable on a phone. It is an approximation, not the real component library — judge the flow and the information hierarchy, never pixel fidelity. |
| A Claude Design prototype (claude.ai/design) | When the directions need real interaction, or the user wants to drive the iteration visually rather than through the terminal. Fill in `design-brief-template.md` (next to this file) and hand that over. |
| The running app | The only route that proves fidelity — and it belongs to phase 5, per `test-verification`. Never hold a phase-3.5 choice hostage to it. |

### Step 5 — The gate, and what gets written down
The user names one direction. Then record it where phase 4 can reach it — the project's own docs or memory, not this conversation: palette, type scale, spacing, motion tokens, component library, the canvas link, and the prototype link if one exists. With `impeccable` in use, that record is the project's root `DESIGN.md` (next to `PRODUCT.md`): every later `/impeccable` command and `test-verification`'s design pass read it automatically. Phase-4 tickets reference that record instead of re-deriving it, exactly as they do for phases 2 and 3.

### If none of the directions land
Don't iterate blind in the terminal, and don't restart from an empty canvas. Hand a written brief to Claude Design and iterate visually there, then bring the chosen result back into phase 4. `design-brief-template.md` is that brief.

Where the project already has a component library, push it first: `/design-sync` (the `DesignSync` tool) syncs a local library into a Claude Design **design-system** project one component at a time, so what gets prototyped there starts on-brand instead of generic — and the result comes back without a hand re-implementation.

## Cost rule
Every phase that adds a tool, service, or hosting target restates: what it costs today, what it costs at realistic 10x scale, and whether a free/cheaper path exists that doesn't compromise the actual requirement — per `market-analyst`. Default recommendation is the cheapest option that meets the constraint, not the most capable one available.

## Check
- A deploy without `deploy-readiness` (pinned SHA, rollback, smoke test on the live target)? Back up.
- Launch copy published before the deploy was verified, or without the user's approval? Stop — launch is the last phase.
- Idea phase skipped straight to code? Back up — requirements were never confirmed.
- Phase 3.5 produced exactly one direction, or a description in prose instead of visuals? That's not a choice — back up and give the user something to compare.
- Two "directions" that differ only in palette? One direction wearing two coats. Redo one of them with a different layout and type thesis.
- A flow with real states (empty, loading, error, multi-step) signed off from static artboards alone? Prototype it before drafting its tickets — step 4.
- Directions without motion tokens, or a picked direction with no `DESIGN.md`? Phase-5 tickets will each invent their own easing and durations.
- Direction picked but never written into the project's docs/memory? Phase 4 will re-derive it and drift, the same way tickets drift from phase 2/3 decisions.
- Project has any user-facing screen and phase 3.5 was never proposed? Back up before drafting UI-bearing tickets — this was the exact gap that let subsplit's tickets #3/#4/#6/#8/#9 get drafted with zero design direction, caught only because the user asked, not because this skill flagged it.
- A tool/service adopted without a `market-analyst` verdict? Get one before it lands in a ticket.
- More than one ticket drafted before phase 3's architecture is confirmed? Architecture decisions ripple into every ticket — confirm shape first.
- Tickets don't reference the phase 2/3 decisions? They'll re-derive and drift from what was actually decided.
- Repo created without the skills SessionStart hook (`.claude/session-start-hook.sh` + `.claude/settings.json`) or without its visibility recorded in `CLAUDE.md`? Add both now: without the hook, a stale skills clone goes unnoticed.
- Repo created without `--delete-branch-on-merge`? Turn it on now, before merged branches start piling up — see "When the project's GitHub repo is created".
- Laravel project scaffolded without Laravel Boost? Install it before the first ticket, per `laravel-architecture`'s "Ground the design in the running app" — tickets written against source files instead of the running app start drifting from phase 3's decisions immediately.
- About to make something publicly reachable without a `security-review` pass over secrets/auth/exposed endpoints? Do it before the deploy, not after the first incident.
- Recurring cost of the deployed stack never restated at deploy time? Phase 2's estimate was for the plan; confirm what's actually being billed now.

## Boundary
This skill sequences *which skill runs when* for a whole project; it doesn't replace any of their internal judgment. A single ticket in an already-running project never needs this — start directly at `product-ownership`.
