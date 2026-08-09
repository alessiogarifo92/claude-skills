---
name: product-ownership
description: Use when drafting or creating a GitHub issue/ticket, researching external sources needed to write one, deciding whether something is a bug/research/implementation ticket, starting or finishing implementation work on a ticket, about to push or merge a completed change, or cleaning up branches after a PR merges or a commit supersedes it
version: 1.9.0
---

# Product Ownership

Own the lifecycle of a work item end to end: from a raw problem report to a grounded ticket, through to the branch cleanup once the work has actually shipped. Grounding tickets in the real code/data is expected baseline behavior, not this skill's job — this skill is about the parts that get skipped without a deliberate habit: separating ticket types, confirming before publishing, reusing repo conventions, and closing the loop on branches.

## End-to-end workflow and handoffs
This skill is the entry and exit point of the task lifecycle; the custom chain (brainstorming → writing-plans → test-driven-development → requesting/receiving-code-review → finishing-a-development-branch) covers the middle — see `project-lifecycle` for the whole-project version of this table when the work spans multiple tickets, not just one. Who does what, per phase:

| Phase | Process skill | Agent |
|---|---|---|
| 0. Operating principles | `principal-engineering-core` for non-trivial tasks | — |
| 1. Ideation | `brainstorming` (or `multi-agent-brainstorm` when the idea spans UI/UX + architecture + cost at once); `market-analyst` before locking in any external tool/API/SaaS/asset (cost + license due diligence) | `researcher` for external feasibility facts and current pricing/ToS pages; `Explore` to see what already exists in the code |
| 2. Grounding / ticket | this skill (ticket type, draft + user confirmation, existing labels); a ticket that adopts an external dependency cites the `market-analyst` verdict | `researcher` for the ticket's external sources; `Explore` to verify in the code that the problem is where you think |
| 3. Pickup | this skill (`in progress` label, always) → `worktree-manager` **only once code work is about to start** (not for research/drafting) → `writing-plans` for multi-step work | `Explore` to locate the critical files before planning; `github-ops` to create/list the ticket's worktree and branch via the repo's own convention, called at the code-work point, not at pickup |
| 4. Implementation | **Direct execution in the main session by default** (`direct-execution`) + `test-driven-development`, plus the relevant domain skill; `subagent-driven-development`/`executing-plans` only for genuinely independent parallel workstreams or plans spanning sessions; a research ticket delivers a report instead (see Ticket types) | `implementer` / `quick-debugger` / `refactor-optimizer` for one whole scoped piece, per `orchestrating-agents`; `researcher` writes the report on research tickets |
| 5. Verification | `test-verification` picks the checks and enforces evidence before "done" | `test-runner` runs suites/lint/typecheck and reports only the outcome |
| 6. Review | `requesting-code-review` (the discipline of asking before merging) drives the `code-review` plugin for the diff itself; add the `architecture-review` / `security-review` lens when the change touches structure or trust boundaries, the `market-analyst` lens for new external dependencies, and `receiving-code-review` when feedback comes back | reviewer subagent |
| 7. Closing | manual user gate (below) → `finishing-a-development-branch` (merge/PR/rebase options) → this skill: close issue, remove label, branch cleanup, skill version bumps | `github-ops` for the mechanical follow-through once you've decided what to run: merge/push, `gh issue close`/label removal, local+remote branch and worktree cleanup |

Every agent dispatch in any phase follows `orchestrating-agents`: the model matches the task (haiku mechanical, sonnet code/research), the agent reports in the STATUS/CHANGES/EVIDENCE/FINDINGS/OPEN structure, and the orchestrator verifies the report before the next phase starts.

The table stays at phase level on purpose: domain skills are a category ("the relevant domain skill"), not an exhaustive list. Rationale and diagram live in the decision record `docs/reports/2026-07-17-ticket-4-workflow-skills-agents.md` (#4).

**Closing order is fixed.** The manual user gate comes first; only after the user confirms does `finishing-a-development-branch` present its merge/PR options, and only after the work lands do issue closing and cleanup happen. Never let finishing-a-development-branch's menu jump ahead of the gate.

**Anti-friction rules:**
- When multiple user confirmations are foreseeable (ticket draft, manual gate, follow-up ticket), prepare all the material first — report, drafts, closing text — and present the requests at a single stop point, so one reply unblocks the whole queue. The gate's content is unchanged; only the batching is.
- The handoff message at the gate must be self-contained: what to check, where (URL/command), the expected result, and what will happen after confirmation — the user should not need to reconstruct context from the conversation.

## Ticket types — don't blend them
- **Bug**: root cause identified in code. Deliverable is the fix.
- **Research**: deliverable is a written report (issue comment or `docs/` file), *not* code. Close the research ticket when the report lands (remove the `in progress` label as part of that same close, exactly as any other closing path) and open a **separate** implementation ticket that references it — don't let research quietly turn into unplanned implementation, and don't let an open research ticket sit unresolved once the report is done. If the report is just an issue comment (nothing committed), the ticket never needed a worktree in the first place — see `worktree-manager`'s "Research tickets" section.
- **Implementation**: references the research/decision it's grounded in instead of re-deriving it.

## Before creating on GitHub
- Draft the full title + body and show it to the user; wait for confirmation before `gh issue create`, unless they've explicitly said to just create it directly.
- Run `gh label list` and reuse what exists instead of inventing new labels.
- Match the repo's existing issue tone/language/section structure if prior issues establish one (check `gh issue list`/`gh issue view` on a couple of examples).

## Work-in-progress label
Add an `in progress` label the moment a ticket is actually being worked (this includes research/drafting, not just code — see the pickup row in the table above for when a *worktree* also gets created, which is a narrower, later trigger). If the repo doesn't have that label yet (`gh label list`), create it first: `gh label create "in progress" --color fbca04 --description "Actively being worked on"`.

Remove the label the moment the issue closes — GitHub does not strip labels on close automatically, so this is a manual step to do alongside `gh issue close`/the closing comment, never left dangling. This is unconditional: it applies to **every** closing path, not just the shipped-fix flow — a research ticket closed once its report lands, an issue closed as duplicate/wontfix/not-planned, and a superseded ticket (see "When work lands via a different path" below) all remove the label at close time exactly the same way a shipped fix does.

A step that only exists as a phrase in a skill, disconnected from the action that triggers it, gets skipped under load — it happened on issue #34: the worktree was created and work landed without the label ever being applied. Don't rely on remembering to do this as a separate action each time: pickup tooling should apply the label as part of creating the worktree/branch, so labeling and pickup happen atomically. The global `worktree-manager` skill does exactly this — its `start <issue>` labels the issue automatically, and it's the same script across every repo, not something to reimplement per project. Where a repo's pickup instead goes through `github-ops` or something else that doesn't label automatically, treat "did I label it?" as a mandatory checkpoint immediately after `git worktree add`/branch creation, before writing any code — not a step to "get to."

## Manual user check — the gate before any merge or push
Automated tests passing is necessary but NOT sufficient to merge or push. After implementation and tests, and before any `git push`, branch merge, or PR merge:

1. Make the change live and reachable in the browser: dev stack running (`docker compose up -d` in this repo — frontend at http://localhost:3000, API docs at http://localhost:8010/docs) with the change active. Walk the page yourself first with the `playwright` MCP server — navigate, perform the action, read the console — to confirm the handoff isn't broken before you hand it over.
2. Tell the user exactly what to check manually, in the three-part split `test-verification` defines: what you already verified in the browser (so they don't repeat it), what needs their eyes (absolute URL, the action, a falsifiable expected result), and what you could not verify and why.
3. Stop and wait for their explicit confirmation that it works. If they report a problem, fix it and repeat this gate from step 1.

If the change has no browser-observable surface (pure tooling, CI config, docs), say so explicitly and tell the user how to verify it instead — the stop-and-wait for their confirmation still applies before merge/push.

| Excuse | Reality |
|--------|---------|
| "All tests pass, so it's safe to push" | Tests are not the gate; the user's manual check is. |
| "It's a trivial/one-line change" | Trivial changes ship broken UIs too. Same gate. |
| "Pushing after tests is pre-authorized" | That pre-authorization operates *after* this gate, never instead of it. |
| "I already verified it in the browser myself" | Your own check prepares the handoff; it doesn't replace the user's. |
| "Playwright drove the whole flow green, that's stronger than a human click" | Playwright proves it runs. It can't tell you the result is *right* — that judgment is what the gate is for. |
| "The user seems away, I'll push and they can review later" | The push can wait. Waiting is the whole point of the gate. |

## Closing when the fix ships
Once the fix is committed and pushed to the default branch (after tests pass **and** the user has confirmed the manual browser check above), close the issue directly — right away, without waiting to be asked. Don't rely on GitHub's auto-close commit-message keywords (`Fixes #N`/`Closes #N`) as the closing mechanism; close it explicitly via `gh issue close <N> --comment "..."`, referencing the commit SHA that shipped it, and remove the `in progress` label as part of that same step.

This is pre-authorized as standard practice for the ticket-implementation workflow described in this skill — it doesn't extend to other GitHub actions (merging PRs, force-pushing, etc.), which still default to asking first.

## When work lands via a different path than expected
If a PR gets superseded (e.g. you push a direct commit instead of merging its branch), close **both** the issue and the PR, and reference what actually shipped it (commit SHA or PR number) in the closing comment — don't leave either dangling as if nothing happened. Remove the `in progress` label from the issue as part of closing it here too, same as any other close.

## Branch cleanup — after any merge or superseding commit
Once a branch's work has landed on the default branch, delete **both** copies — local and remote. Only the default branch persists long-term. This is standing cleanup, not something to wait to be asked for each time; do it as part of finishing that piece of work, right after confirming the change actually landed.

- Remote: `git push origin --delete <branch>` (or `gh pr merge --delete-branch` at merge time)
- Local: `git branch -d <branch>`; if it's checked out in a worktree, remove the worktree first (`git worktree remove`, unlocking it if needed) before deleting the branch

**Red flag:** if you notice `git branch -a` listing branches other than the default one whose work is already on it, that's stale cleanup you should do now, not just note for later.

## Skill versioning
Every skill in this repo carries a semver `version` in its `SKILL.md` frontmatter. When you modify a skill, bump its version (MAJOR = behavior/approach change, MINOR = new section/rule/capability, PATCH = fixes/clarifications) and add a line to the root `CHANGELOG.md` under today's date — in the same commit as the change.

## Check
- Research ticket done → is there a follow-up implementation ticket, or does one need opening?
- About to run `gh issue create` → did the user see and confirm this exact text?
- Starting work on an issue → is the `in progress` label on it? (Label yes, always — worktree only once code is actually about to be written.)
- About to `git push` or merge anything → did the user manually confirm in the browser that the change works? If not, stop and ask now.
- Fix pushed to the default branch → did you close the issue right away, without waiting to be asked?
- Closing an issue → was the `in progress` label removed?
- Just merged/superseded a branch → does `git branch -a` show only the default branch, locally and remotely, when you're done?
- Modified a skill → did you bump its frontmatter `version` and add the `CHANGELOG.md` line in the same commit?
- Added or renamed a repo skill or agent → is the "End-to-end workflow and handoffs" section still correct? Update it in the same commit.

## Boundary
This is about grounding and lifecycle hygiene for issues/branches, not about deciding product priority or roadmap — it doesn't replace the user's judgment on what to build next or in what order.
