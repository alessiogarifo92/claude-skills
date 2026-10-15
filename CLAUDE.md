# Global rules (all projects)

This file is loaded in every conversation, so it holds only rules that apply whatever the task, plus the triggers that make the right skill load. Detail belongs in the skill that owns the phase; each section below names it.

## Where a new rule/lesson goes: skill → CLAUDE.md → project memory
CLAUDE.md costs context in every conversation in every project; a skill's body costs it only when the skill is invoked (its name and one-line description sit in every conversation otherwise); project memory is scoped to one project and one working-directory path (a worktree has its own memory silo, separate from its repo's primary checkout).

When something worth remembering comes up mid-task, place it in the first of these that fits:
1. **A phase/domain skill**, if the rule is universal but only relevant during a specific kind of work (a ticket phase, a stack, a workflow step) — `product-ownership`, `worktree-manager`, `test-verification`, `finishing-a-development-branch`, a language/framework skill, etc.
2. **This file**, only if the rule is universal *and* applies regardless of the task (a safety rule, a platform quirk, a cross-cutting habit, a trigger that must load a skill) — rare.
3. **Project memory**, for one project's own facts, infrastructure, or the user's project-specific preferences.

**Why:** rules learned on subsplit tickets first landed in project memory, were then promoted wholesale here, and only on review turned out to belong in the skills that govern those phases. On 2026-10-15 this file was cut from ~25 KB to its cross-cutting core for the same reason; the moved detail lives in the skills named below.

## Every project's CLAUDE.md must bootstrap this skills repo
Skills and these rules live in the repo `alessiogarifo92/claude-skills`, loaded from `~/.claude/` on a local machine. A **remote session** (Claude Code on the web, a cloud container, a GitHub Action) starts with only the project repo cloned, so none of this reaches it unless the project's own `CLAUDE.md` — the only thing a remote session loads by itself — carries the bootstrap section from `templates/project-CLAUDE-bootstrap.md`: attach this repo (`add_repo`, clone, `register_repo_root`), run `bash <clone>/scripts/install.sh`, Read `<clone>/<skill>/SKILL.md` directly if a named skill is still missing, and say so in visible text if the attach fails rather than proceeding rule-less. Whenever a project's `CLAUDE.md` is created or edited — new project (`project-lifecycle`) or an existing one picked up for a ticket — check that section is there and add it if missing.

- **Stale is as bad as missing.** An existing clone proves nothing: the bootstrap fetches and fast-forwards it, and each project commits the `templates/session-start-hook.sh` SessionStart hook, which does it at every session start and prints the skills commit, whether it is behind, and the repo's visibility. A "BEHIND" line means update before any work.
- **The hook is added, not asked about.** When this repo is attached alongside a project lacking `.claude/session-start-hook.sh` + its `.claude/settings.json` entry, add both (copy the template; the JSON is in its header) and commit them on the session's working branch as the first change. A multi-repo session relies on the environment's setup script (`templates/cloud-setup-script.sh`, set once by the user) to register the hook at user level.
- **Why:** on subsplit #24 a remote session implemented a whole ticket with no skills reachable — no `## Test info` comment, and a project `CLAUDE.md` that re-derived conventions the skills already owned.

## A project's committed `.mcp.json` must not break remote sessions
A repo-level `.mcp.json` loads in every session, but a remote session has no Docker daemon, none of the user's env vars, and its own GitHub MCP server. Three silent failures follow — the tools never appear:
- **Name collision.** A server named like a managed one — `github` above all — shadows it, and *neither* loads. Prefix repo-level servers: `github-local`, not `github`.
- **Unavailable transport.** A `command: docker` stdio server cannot start in a cloud container and hangs in "connecting". Prefer a hosted HTTP endpoint; keep Docker servers for what is genuinely local-only.
- **Unset token variable.** `"${SOME_TOKEN:-}"` resolves to an empty string, so the server starts unauthenticated. Document which variables `.mcp.json` needs.

**When an expected `mcp__*` tool is missing,** read the project's `.mcp.json`, then check `docker version` and the referenced env vars, before concluding the connector is down. (**Why:** on ps-plus-catalog a Docker-based server named `github` left the first cloud session with no GitHub tools at all, and it read as a permission problem.)

## GitHub from a remote session: REST, not GraphQL
In a remote session `gh issue/pr/repo/label ...` go through GraphQL and fail with `HTTP 403: GitHub GraphQL is not available`. Use the GitHub MCP tools, or `gh api` REST (`gh api "repos/{owner}/{repo}/issues?labels=in%20progress"`, `gh api -X POST "repos/{owner}/{repo}/issues/<n>/labels" -f "labels[]=in progress"`, `gh api repos/{owner}/{repo} --jq .private`). Repo-settings writes are refused by the proxy: hand them to the user as a UI step. A 403 naming GraphQL is this, never a permission problem. `product-ownership`'s "Without `gh`" table maps every operation.

## Orchestration: direct execution by default
These instructions take precedence over any skill's process (including superpowers plugin skills).

- A linear, single-focus task (one bug, one feature, one file, dependent steps A→B→C) is executed **directly in the main session**: read, edit, test, done. No subagent orchestration, no numbered task split, no per-task dispatch. `direct-execution` holds the decision tree.
- Subagents are for genuinely independent parallel work or explicit isolation, one scoped job per agent (the agents in `~/.claude/agents/`), never to multiply one job into many — the exception is a `cross-verification` panel on a high-stakes question. Process skills (brainstorming, writing-plans, subagent-driven-development) are for work that needs design decisions or true parallelism; when in doubt, start executing directly.
- When delegation IS warranted, `orchestrating-agents` governs it: model per task type (haiku mechanical, sonnet code/research/verification, opus for the judgment agents), the dispatch brief, the STATUS/CHANGES/EVIDENCE/FINDINGS/OPEN report. Git and GitHub writes stay in the main session; every agent except `github-ops` carries a PreToolUse hook (`scripts/agent-guard.sh`) that blocks them.
- **End-to-end or unattended runs** go through `autonomous-workflow` (a brand-new project still enters through `project-lifecycle` first). Autonomy removes small questions, never the hard gates: user decisions, spend, publishing, push/merge before the manual check, deploy, destructive operations.
- **High-stakes decisions and results** (architecture, security, data migration, deploy, public copy) go through `cross-verification`: blind parallel agents, a critic, decision on evidence. Linear low-stakes work never does.
- **Verification gate**: every agent report is a claim. Before the next phase or dispatch, check the diff against CHANGES, re-run the narrowest test against EVIDENCE, spot-check a load-bearing research claim. Never build phase N+1 on an unverified phase N; never route around a `blocked` status.

## Always enter through `project-lifecycle` for a new application/project
A request to build a new app/project from scratch, or to evaluate one end to end (not one ticket in a running project), invokes `project-lifecycle` as the very first action — before tickets, architecture or code. If the user jumps to "make ticket X" on a project whose idea/stack/architecture/design phases were never confirmed, flag the gap and offer to backfill that phase first. Map "roles" the user asks for (product owner, architecture, cost, frontend, backend, QA, marketing, deploy) to that skill's phases and skills, not to new agents.
- **Why:** each phase gate — the design gate included — only fires if the skill that owns it was loaded; on a prior project tickets went straight from idea to code and no gate ever had a chance.

## Never skip a Design UI/UX phase before development
No theme/frontend/UI code until the project's design phase has a concrete deliverable (mockup, style guide, or an explicit reference to build against); if build tickets are about to run without one, stop and flag it. The deliverable is grounded in the project's own docs and references, and is visual with **more than one** direction to compare — `design` (`/design`), or the `Artifact` quickstart with intent `design` when that skill is absent — never prose or a single take. Detail, steps and the DamianoGuideSite precedent: `project-lifecycle` phase 3.5 and "Design gap found mid-build".

## Commands handed to the user
Any command the user is asked to run must use absolute paths, or explicitly state the directory (`cd /path && ...`) and the environment (host shell vs a specific Docker container) to run it in. Never hand over a bare relative path.

## Announce agent model/effort
Every time the Agent tool is used (any subagent_type — built-in or custom), state in visible text which model it runs on (its frontmatter `model:` field, or the `model` override passed to the call) and its effort/reasoning level if one applies. Announce this at launch time, not only after the result comes back — a one-line note is enough (e.g. "Lancio `github-ops` (modello haiku).").

## Sudo and installing missing tools
Ask the user for the OK before any `sudo` or tool installation. Once the OK is given, try running the command yourself; hand it to the user for manual execution only when it genuinely cannot be run (needs an interactive password/tty, sandbox denial, missing permissions) — and say that's the reason.

## Every implementation ticket ships with unit tests, not just a Playwright/manual pass
Every implementation ticket — feature, bug fix, or behavior-changing refactor — ships unit tests for the changed logic, error paths and edge cases included, in addition to the browser/manual checks, and wired into the pipeline's coverage report where one exists. Detail: `test-verification`, "Unit layer: mandatory on every implementation ticket".

## Never wipe shared DB data while another ticket is in progress
Destructive operations on a shared database — resetting/seeding fixtures, `migrate:fresh`, wiping tables, deleting mock data inserted for a manual check — run only when no *other* ticket carries the `in progress` label (`gh issue list --label "in progress"`; remote: the REST call above), excluding your own. This binds automated runs (`test-runner`, CI-style suites) exactly as much as the manual-verification stack.
- If another ticket is in progress, wait, or use something non-destructive: data scoped to your ticket, a transaction that rolls back, or a separate schema/database for automated tests.
- **Why:** one agent's fixture reset can corrupt another agent's test mid-flight on the same DB, even though neither touched the other's code.

## One git worktree per ticket
When code for a ticket is about to be written — not at pickup, not for research whose deliverable is an issue comment — work in an isolated worktree via `worktree-manager` (`~/.claude/skills/worktree-manager/scripts/worktree.sh start <issue> [slug]`), never on the default branch of the primary checkout. Same script and convention in every project. Two sessions never write to the same branch; a locked worktree belongs to another session. Detail (research tickets, ports, cleanup, manual fallback): `worktree-manager`.

## Remove the "in progress" label when a ticket closes
Whenever a ticket closes — by any path: shipped, research delivered, duplicate/wontfix, superseded — remove its `in progress` label in that same action (GitHub does not do it). Commands, remote included: `product-ownership`, "Work-in-progress label".

## Restore the stack to main when a ticket closes
If the running stack (containers, bind mount, or a directly-run dev server such as `expo start`) was swapped to serve a ticket's worktree for manual verification, point it back at the primary checkout on the default branch as part of closing the ticket, whatever the reason it closed — and before `worktree.sh cleanup`, which deletes the path the stack would still be serving. Detail: `worktree-manager` lifecycle step 3.

## Invoke `product-ownership` itself at ticket pickup, not only `worktree-manager`
At the pickup point of any ticket, invoke the `product-ownership` skill itself — skill instructions only enter context when that skill is invoked, and calling one narrow skill doesn't pull in a broader one it references. Treat "did I invoke `product-ownership` yet" as a pickup checkpoint, like the `in progress` label.
- **Why:** on subsplit #32 only `worktree-manager` was invoked, so `product-ownership`'s `## Test info` convention never entered context and the manual-verification handoff was improvised in chat.
