# Global rules (all projects)

## Orchestration: direct execution by default
These instructions take precedence over any skill's process (including superpowers plugin skills).

- A linear, single-focus task (one bug, one feature, one file, dependent steps A→B→C) is executed **directly in the main session**: read, edit, test, done. No subagent orchestration, no splitting into numbered task lists, no per-task subagent dispatch.
- Subagent orchestration is reserved for genuinely independent parallel work (e.g. three unrelated modules at once) or when isolation is explicitly needed. If the steps depend on each other, they are not parallel — execute them directly.
- Process skills (brainstorming, writing-plans, subagent-driven-development) apply to work that needs design decisions or true parallelism — not to a scoped fix or a scoped feature. When in doubt, start executing directly; escalate to planning only if real complexity emerges.
- The `direct-execution` skill (global) documents this decision tree; the specialized agents in `~/.claude/agents/` (quick-debugger, implementer, refactor-optimizer, test-runner, researcher, Explore, github-ops) are for delegating a single scoped job, never for multiplying one job into many.
- When delegation IS warranted, the `orchestrating-agents` skill (global) governs how: which model per task type (haiku for mechanical run/locate/report jobs, sonnet for anything that diagnoses or writes code or synthesizes research, main session for decisions and all git), the dispatch brief, and the report contract (STATUS/CHANGES/EVIDENCE/FINDINGS/OPEN).
- **Verification gate**: every agent report is a claim, not a fact. Before starting the next phase or dispatching the next agent, the main session verifies the report — check the diff against CHANGES, re-run the narrowest test against EVIDENCE, spot-check a load-bearing research claim. Never build phase N+1 on an unverified phase N; never route around a `blocked` status.

## Never skip a Design UI/UX phase before development
When a project's own plan defines a distinct Design UI/UX phase (mockups, palette, typography, component design, or an approved reference site to match) ahead of a development/build phase, do not start writing theme/frontend/UI code until that design phase has a concrete deliverable — a mockup, a style guide, or an explicit reference to build against.

- Before executing build/implementation tickets, check whether the project's own plan places a design phase earlier in the sequence. If it does and no design deliverable exists yet, stop and flag the gap to the user before proceeding with more build tickets — don't silently keep executing tasks that assume a design outcome that hasn't happened.
- **Why:** on DamianoGuideSite, a technical build plan correctly marked visual design "out of scope" for its own narrow scope, mirroring the project's broader phase plan (a Design UI phase listed before the Sviluppo/build phase in `strategia-progetto.md`) — but the build phase started without that design phase ever producing a deliverable. Several build tickets shipped working code against an unstyled default theme with no design direction, which only surfaced when the user compared the live result to a reference site they had in mind and it looked nothing like it. The rework cost is the same whether it's caught on ticket 1 or ticket 7 — catching it earlier is strictly better.
- **How to apply:** if the user hands over a reference site, mockup, or style direction mid-build (i.e., after the gap is discovered), treat it as the missing Design UI-phase deliverable: capture it in project memory, and if the project tracks work as tickets/phases, offer to open the design phase as its own ticket rather than absorbing style changes ad hoc into unrelated build tickets.

## Commands handed to the user
Any command the user is asked to run must use absolute paths, or explicitly state the directory (`cd /path && ...`) and the environment (host shell vs a specific Docker container) to run it in. Never hand over a bare relative path.

## Announce agent model/effort
Every time the Agent tool is used (any subagent_type — built-in or custom), state in visible text which model it runs on (its frontmatter `model:` field, or the `model` override passed to the call) and its effort/reasoning level if one applies (e.g. a `low`/`medium`/`high` review effort). Announce this at launch time, not only after the result comes back — a one-line note is enough (e.g. "Lancio `github-ops` (modello haiku).").

## Sudo and installing missing tools
Ask the user for the OK before any `sudo` or tool installation. Once the OK is given, try running the command yourself; hand it to the user for manual execution only when it genuinely cannot be run (needs an interactive password/tty, sandbox denial, missing permissions) — and say that's the reason.

## Manual verification: real data, standard ports, one environment at a time
When a ticket needs a manual browser/functional check before merge/push, verify it against the project's real, full dataset on its standard ports — never spin up an ad-hoc scratch environment (throwaway DB seeded with a handful of fixture records, alternate ports) to avoid disturbing a running stack.
- Do the implementation work in the ticket's isolated worktree (per "One git worktree per ticket" below), but never `git checkout` the ticket branch inside the primary checkout itself, even temporarily, to run it.
- To point the already-running stack at the worktree's code instead: swap only the code-serving layer (e.g. bind-mount paths, `docker compose` service source, symlink) over to the worktree while reusing the same database/volume/network/service the primary checkout normally uses, so real data stays intact and the app stays reachable on its usual host/port. Leave that swap in place through your own Playwright walkthrough **and** through the user's manual check that follows it — swap back to the primary checkout only once the user confirms the check is done (see "Restore the stack to main when a ticket closes" below), never right after your own walkthrough. Finishing the Playwright pass is not "the check is done" — the user's confirmation is.
- If two tickets are in progress at once, don't run two parallel environments — verify one, get confirmation, then swap the same environment over to the other ticket and verify that one. Same port, same real data, one at a time.

## Manual verification: walk it in the browser first, then hand the user a checklist
Before asking for the manual check, walk the flow yourself against that running stack with the `playwright` MCP server — navigate, perform the action, read the accessibility snapshot and the console. Never hand over a check you haven't opened; a broken page discovered by the user is a wasted round trip.

This never replaces the user's check, it prepares it. The handoff is always three explicit parts (`test-verification` holds the detail):
1. what was already verified in the browser, one line each, so it isn't repeated;
2. what needs the user's eyes — absolute URL with host and port, the exact action, and an expected result concrete enough to be contradicted ("the row reads 3 articoli — €45,00", not "the totals look right");
3. what could not be verified and why.

Playwright proves the page loads, the action fires and nothing errored. Whether the result is *right* — visually, editorially, in the data — is the user's judgment, and that is the whole point of the gate.

The environment must still be pointed at the ticket's code at the moment this handoff is given. Restoring the stack to the primary checkout is a separate, later step (see "Restore the stack to main when a ticket closes" below) — never do it between finishing your own walkthrough and handing off the checklist. A checklist handed off against an environment already reverted to `main` sends the user to look at the wrong code, and they will have to tell you to redo the swap before they can even start.

## Manual verification: mock data when the real dataset can't cover the case
If the real dataset doesn't contain a case the user needs to see with their own eyes (a specific edge case, empty state, boundary condition, error state), don't skip the check, don't fake having verified it, and don't just describe what "should" happen — insert temporary mock/seed data into the running environment so the scenario is actually reproducible and clickable for the user's manual check.
- Make clear to the user that what they're looking at is temporary mock data inserted for this check, not real catalog data.
- Only delete the mock data after the user has given explicit approval of the check — deleting data is a hard-to-reverse action, so it follows the same confirm-first default as any other destructive operation, it doesn't get a standing exception just because the data is fake.
- Clean it up promptly once approved, so it doesn't linger and get mistaken for real data in later tests.

## Laravel Boost is standard equipment in every Laravel project
Every Laravel project gets Laravel Boost — one just scaffolded, or an existing one being touched for the first time. It's the difference between reasoning about the app from its source files and interrogating the app that is actually running: registered routes, real schema, installed package versions, logs, tinker, plus documentation matched to those versions instead of the most common answer on the internet.

- **Check, then install.** On the first substantive work in a Laravel repo, check whether `laravel/boost` is in `composer.json`. If it isn't: `composer require laravel/boost --dev`, then `php artisan boost:install`. It's a dev dependency and never ships to production.
- **Announce it, keep it separate.** Adding a dependency to someone's repo is a change in its own right — say you're doing it, and give it its own commit rather than folding it silently into a ticket's diff.
- **`boost:install` is interactive** — it asks which agents and features to set up. If it can't be driven from here, hand it to the user to run with the `!` prefix instead of guessing at undocumented `--no-interaction` behavior. Claude Code registration is normally automatic; the documented fallback is `claude mcp add -s local -t stdio laravel-boost php artisan boost:mcp`.
- **It generates a project-root `CLAUDE.md`.** Boost writes guideline files (`CLAUDE.md`, `AGENTS.md`, …) and regenerates them on every later `boost:install`/`boost:update`. If the project already has its own `CLAUDE.md`, read and preserve it first — losing a project's own instructions to a regenerated file is a real regression. This is the project root file, not `~/.claude/CLAUDE.md`.
- **What's committed differs by file.** `.mcp.json`, the generated guideline files, and `boost.json` are regenerated on demand and may be gitignored. `.ai/rules/` is the opposite — it's the team's shared project rules and belongs in version control.
- **Record project rules through the tool, never by hand.** Use Boost's `record-rule` MCP tool: it files the rule under the right glob and regenerates `.ai/rules/index.md`, which is how agents discover it. A rule file written by hand stays invisible until that index is next rebuilt.
- **Existing codebase:** after installing, offer the `infer-conventions` skill to bootstrap `.ai/rules` from what the code already does. It presents each convention with its evidence for approval before writing anything — don't let it record unreviewed.
- **Keep it from drifting:** add `@php artisan boost:update --ansi` to the project's Composer `post-update-cmd` scripts, so guidelines and skills track the installed package versions instead of aging in place.

## One git worktree per ticket
Create the worktree only when code in the repo is actually about to be written or modified — not as a reflexive first step on every ticket, and not for tickets that never touch the repo (a research ticket whose deliverable is an issue comment, for example). When that moment arrives, never work directly on the default branch of the primary checkout — use an isolated worktree, via the global `worktree-manager` skill (`~/.claude/skills/worktree-manager/scripts/worktree.sh`). This is the same convention and the same script in every project — present and future — not something to reinvent or copy per-repo:

- `worktree.sh start <issue> [slug]` creates + locks `.claude/worktrees/<slug>` on branch `worktree-<issue>-<slug>` (ensuring that directory is git-ignored) and applies the `in progress` label to the issue. Call it right before the first file gets touched, not at ticket pickup — research/investigation work (reading code, drafting a report, grounding a ticket) doesn't need it.
- A ticket that stays research-only (report lands as an issue comment, no repo commit) still gets picked up and marked in progress, just without a worktree — label it directly: `gh issue edit <n> --add-label "in progress"`. If the research later produces a `docs/` file that gets committed, that commit is code work — create the worktree at that point, not before.
- Two sessions must never write to the same branch. A locked worktree belongs to another session — do not touch it; unlocking is the owner's explicit handoff step.
- After the branch merges: `worktree.sh cleanup` unlocks/removes the merged worktree and branch, and clears orphaned worktree directories; the remote branch still needs `git push origin --delete` separately.
- If a repo genuinely can't use the script (no `gh` auth, unusual branch layout), fall back to the convention manually — same naming, same lock discipline — but that's the exception, not the default.

## Remove the "in progress" label when a ticket closes
GitHub does not strip labels on close automatically. Whenever a ticket/issue closes — for any reason and by any path (fix shipped, research report delivered, closed as duplicate/wontfix/not-planned, superseded by a different commit or PR) — remove the `in progress` label as part of that same closing action, not as a follow-up to remember later: `gh issue close <n> --comment "..."` paired with `gh issue edit <n> --remove-label "in progress"` (or the single combined call if the `gh` version supports it). This applies uniformly regardless of ticket type; don't treat it as specific to the bug/implementation workflow.

## Restore the stack to main when a ticket closes
If the running stack was swapped to serve this ticket's worktree for manual verification (per "Manual verification: real data, standard ports, one environment at a time" above), swap the code-serving layer back to the primary checkout on its default branch (typically `main`) as part of the same closing action — never leave it pointed at a just-closed ticket's worktree. Do this before running `worktree.sh cleanup`: cleanup removes the worktree directory/branch, and a stack still pointed at it will break instead of falling back to anything. Applies regardless of why the ticket closed (merged, superseded, wontfix).
