---
name: product-ownership
description: Use when drafting or creating a GitHub issue/ticket, researching external sources needed to write one, deciding whether something is a bug/research/implementation ticket, starting or finishing implementation work on a ticket, about to push or merge a completed change, or cleaning up branches after a PR merges or a commit supersedes it
version: 1.17.0
---

# Product Ownership

**Run on:** sonnet · effort medium — ticket hygiene and lifecycle; opus when drafting a ticket from a vague problem.

Own the lifecycle of a work item end to end: from a raw problem report to a grounded ticket, through to the branch cleanup once the work has actually shipped. Grounding tickets in the real code/data is expected baseline behavior, not this skill's job — this skill is about the parts that get skipped without a deliberate habit: separating ticket types, confirming before publishing, reusing repo conventions, and closing the loop on branches.

## End-to-end workflow and handoffs
`autonomous-workflow` conducts this table end to end when the user wants the work run unattended. This skill is the entry and exit point of the task lifecycle; the custom chain (brainstorming → writing-plans → test-driven-development → requesting/receiving-code-review → finishing-a-development-branch) covers the middle — see `project-lifecycle` for the whole-project version of this table when the work spans multiple tickets, not just one. Who does what, per phase:

| Phase | Process skill | Agent |
|---|---|---|
| 0. Operating principles | `principal-engineering-core` for non-trivial tasks | — |
| 1. Ideation | `brainstorming` (or `multi-agent-brainstorm` when the idea spans UI/UX + architecture + cost at once); `market-analyst` before locking in any external tool/API/SaaS/asset (cost + license due diligence) | `researcher` for external feasibility facts and current pricing/ToS pages; `Explore` to see what already exists in the code |
| 2. Grounding / ticket | this skill (ticket type, draft + user confirmation, existing labels); a ticket that adopts an external dependency cites the `market-analyst` verdict | `researcher` for the ticket's external sources; `Explore` to verify in the code that the problem is where you think |
| 3. Pickup | this skill (`in progress` label, always) → `worktree-manager` **only once code work is about to start** (not for research/drafting) → `writing-plans` for multi-step work | `Explore` to locate the critical files before planning; `github-ops` to create/list the ticket's worktree and branch via the repo's own convention, called at the code-work point, not at pickup |
| 4. Implementation | **Direct execution in the main session by default** (`direct-execution`) + `test-driven-development`, plus the relevant domain skill; `subagent-driven-development`/`executing-plans` only for genuinely independent parallel workstreams or plans spanning sessions; a research ticket delivers a report instead (see Ticket types) | `implementer` / `quick-debugger` / `refactor-optimizer` for one whole scoped piece, per `orchestrating-agents`; `researcher` writes the report on research tickets |
| 5. Verification | `test-verification` picks the checks and enforces evidence before "done" | `test-runner` runs suites/lint/typecheck and reports only the outcome; `verifier` re-derives a gating claim blind |
| 6. Review | `requesting-code-review` (the discipline of asking before merging) runs the review panel for the diff (the `code-review` plugin if the user prefers it); add the `architecture-review` / `security-review` lens when the change touches structure or trust boundaries, the `market-analyst` lens for new external dependencies, and `receiving-code-review` when feedback comes back | `reviewer` + `security-auditor` + `architect` in parallel, `critic` to reconcile (`cross-verification` Mode C) |
| 7. Closing | manual user gate (below) → `finishing-a-development-branch` (merge/PR/rebase options) → this skill: close issue, remove label, branch cleanup, skill version bumps | `deploy-readiness` when the merge deploys; `github-ops` for the mechanical follow-through once you've decided what to run: merge/push, `gh issue close`/label removal, local+remote branch and worktree cleanup |

Every agent dispatch in any phase follows `orchestrating-agents`: the model matches the task (haiku mechanical, sonnet code/research/verification, opus for the judgment agents `architect`, `reviewer`, `security-auditor`, `critic`, `marketing-strategist`), the agent reports in the STATUS/CHANGES/EVIDENCE/FINDINGS/OPEN structure, and the orchestrator verifies the report before the next phase starts.

The table stays at phase level on purpose: domain skills are a category ("the relevant domain skill"), not an exhaustive list. Rationale and diagram live in the decision record `docs/reports/2026-07-17-ticket-4-workflow-skills-agents.md` (#4).

**Closing order is fixed.** The manual user gate comes first; only once that gate has cleared — by the user's confirmation, or through its carve-out — does `finishing-a-development-branch` present its merge/PR options, and only after the work lands do issue closing and cleanup happen. Never let finishing-a-development-branch's menu jump ahead of the gate.

**Anti-friction rules:**
- When multiple user confirmations are foreseeable (ticket draft, manual gate, follow-up ticket), prepare all the material first — report, drafts, closing text — and present the requests at a single stop point, so one reply unblocks the whole queue. The gate's content is unchanged; only the batching is.
- The handoff message at the gate must be self-contained: what to check, where (URL/command), the expected result, and what will happen after confirmation — the user should not need to reconstruct context from the conversation.

## Ticket types — don't blend them
- **Bug**: root cause identified in code. Deliverable is the fix.
- **Research**: deliverable is a written report (issue comment or `docs/` file), *not* code. Close the research ticket when the report lands (remove the `in progress` label as part of that same close, exactly as any other closing path) and open a **separate** implementation ticket that references it — don't let research quietly turn into unplanned implementation, and don't let an open research ticket sit unresolved once the report is done. If the report is just an issue comment (nothing committed), the ticket never needed a worktree in the first place — see `worktree-manager`'s "Research tickets" section.
- **Implementation**: references the research/decision it's grounded in instead of re-deriving it.
- **Spike**: a time-boxed technical exploration or prototype to reduce uncertainty *before* committing to an implementation approach — "will this library actually work for X", "can we make this integration talk to that API". Unlike research, the deliverable can be throwaway code (a branch/worktree that's never meant to merge), not a written report; unlike implementation, nothing here ships. Close it with a short comment on what was learned and, if it points to a real approach, open a **separate** implementation ticket that references it — same non-blending rule as research.

## Labels — bug outranks feature, spike is exploration not delivery
Reuse the repo's existing GitHub labels for ticket type instead of inventing new ones per project: `bug` for bug tickets, `feature` for feature/implementation tickets, `question` for research tickets, `spike` for spikes (create it once per repo if missing: `gh label create "spike" --color 1d76db --description "Time-boxed technical exploration/prototype to reduce uncertainty"`). `in progress` (see below) stacks on top of whichever type label applies — it is not itself a type.

Deliberately `feature`, never GitHub's default `enhancement` — the user dislikes that name. If a repo still carries the stock `enhancement` label, **rename** it (`gh label edit enhancement --name feature`) rather than creating a `feature` duplicate alongside it: renaming preserves every existing issue association, creating a duplicate silently splits the backlog across two labels.

When choosing what to pick up next and priorities aren't otherwise specified by the user, an open `bug` outranks an open `feature`: a broken existing behavior costs more the longer it sits than a not-yet-built feature does. This is a default, not an override of explicit user direction — if the user names what to work on next, that stands regardless of label.

## Before creating on GitHub
- Draft the full title + body and show it to the user; wait for confirmation before `gh issue create`, unless they've explicitly said to just create it directly.
- Run `gh label list` and reuse what exists instead of inventing new labels.
- Match the repo's existing issue tone/language/section structure if prior issues establish one (check `gh issue list`/`gh issue view` on a couple of examples).
- Check whether the new ticket depends on, blocks, or belongs under an existing one — wire the relationship in with the flags below *before* showing the draft to the user, not as a follow-up once work starts.
- If the ticket originates from an unchecked todo item on a Notion page, check that item off (`- [ ]` → `- [x]`) on the source page as part of creating the ticket, appending a short reference to the ticket created from it (e.g. `— ticket subsplit#24`) — do this proactively, without waiting to be asked. If one todo spawns multiple tickets, list every resulting ticket number on the same checked line rather than splitting the bullet. Without this, Notion drifts out of sync with GitHub as the source of truth for "what's already been turned into a ticket" (missed on 6 tickets created from a subsplit planning page before this became standard). Applies in any project that uses Notion for planning.

## Ticket relationships — dependencies and epics
GitHub has native issue-relationship fields — `blockedBy`/`blocking` (sequential dependencies) and `parent`/`subIssues` (epics) — exposed by `gh issue create`/`gh issue edit` as real flags, not just body text. Use these instead of ad-hoc conventions (a "Blocked by #N" sentence buried in the body, a hand-written epic checklist): they render as badges/progress bars in the GitHub UI, stay in sync automatically, and are queryable with `--json`. Confirm your `gh` version still has them (`gh issue create --help` / `gh issue edit --help`) before falling back to a body-text convention on an older CLI or host that lacks the feature.

**Dependencies (ticket B can't start until ticket A is done):**
- At creation: `gh issue create --blocked-by <A>` or `--blocking <B>`.
- On an existing issue: `gh issue edit <B> --add-blocked-by <A>` / `--remove-blocked-by <A>` (symmetric `--add-blocking`/`--remove-blocking` from the other side).

**Epics (one tracking issue grouping several sub-issues):**
- Create the epic as a normal issue; add an `epic` label for easy filtering (create it once if the repo doesn't have it: `gh label create "epic" --color 5319e7 --description "Tracking issue grouping several sub-issues"`).
- Create each sub-issue against it — `gh issue create --parent <epic>` — or link an existing issue with `gh issue edit <child> --parent <epic>` (or from the epic side: `gh issue edit <epic> --add-sub-issue <child>`). Don't hand-write a `- [ ] #N` checklist for this: the native sub-issue link already gives the epic a progress bar that updates itself as children close.

**Finding what's blocked vs. what can run in parallel:**
- Per ticket: `gh issue view <N> --json blockedBy,blocking,parent,subIssues,subIssuesSummary`.
- Across the open backlog, list every issue that has at least one *still-open* blocker (truly blocked right now, not just historically linked to something already closed). `blockedBy`/`blocking` come back as `{nodes: [...], totalCount: N}`, not a flat array — verified against `gh` 2.96.0 on 2026-08-16:
  ```
  gh issue list --state open --json number,title,blockedBy \
    --jq '.[] | select([.blockedBy.nodes[]? | select(.state=="OPEN")] | length > 0)
              | "#\(.number) \(.title) — blocked by " + ([.blockedBy.nodes[]? | select(.state=="OPEN") | "#\(.number)"] | join(", "))'
  ```
  Re-check the shape on a future `gh` version before trusting this blind (`gh issue list --json blockedBy --jq '.[0]'` on one issue with a known relationship) — GitHub's dependency feature is recent and the JSON shape could still change.
- Every open ticket that doesn't show up in that list has no live blocker — those are the ones safe to hand out for parallel work (parallel worktrees/sessions, or just parallel priority) at the same time.

## Milestones — grouping tickets by phase or goal
When a batch of tickets is drafted for a defined phase or goal (a `project-lifecycle` phase-4 ticket batch — e.g. "MVP" for the initial slice, or a later named batch like "v2"/"Deploy"), create a GitHub milestone for it and assign every ticket in the batch to it, instead of only cross-referencing "ticket #X-#Y" as free text in a ticket body — free text drifts as the backlog grows and isn't queryable (this is exactly what happened on subsplit: `#12` says "derogabile a dopo l'MVP, ticket #2-#11", something only discoverable by reading that one ticket's body, not by asking GitHub).

`gh` has no dedicated `milestone` subcommand — go through the REST API:
- Create once, if it doesn't already exist (`gh api repos/<owner>/<repo>/milestones --jq '.[].title'` to check first): `gh api repos/<owner>/<repo>/milestones -f title="MVP" -f state="open" -f description="..."`.
- Assign at creation: `gh issue create --milestone "MVP" ...`; on an existing issue: `gh issue edit <N> --milestone "MVP"`.
- `gh issue create/edit --milestone <title>` only resolves the title against **open** milestones — if a milestone was created already `closed` (e.g. one covering a phase whose tickets are all done, like "Setup"), assignment fails with `'<title>' not found` even though the milestone exists. Reopen it first (`gh api -X PATCH repos/<owner>/<repo>/milestones/<number> -f state="open"`), assign the issues, then close it again the same way — confirmed hitting this on subsplit's "Setup"/"Design UI/UX" milestones.

Milestones and the dependency/epic relationships above are orthogonal, not substitutes: a milestone answers "does this ticket belong to this goal", `blockedBy`/`blocking` answers "can this ticket start yet". Don't create a milestone for a phase/goal that's already 100% closed — no forward value, same administrative-churn trap as retroactively wiring epics onto finished work (see above). Only create one for a phase/goal that still has open tickets, or that's about to receive its first one.

## Work-in-progress label
Add an `in progress` label the moment a ticket is actually being worked (this includes research/drafting, not just code — see the pickup row in the table above for when a *worktree* also gets created, which is a narrower, later trigger). If the repo doesn't have that label yet (`gh label list`), create it first: `gh label create "in progress" --color fbca04 --description "Actively being worked on"`.

Remove the label the moment the issue closes — GitHub does not strip labels on close automatically, so this is a manual step to do alongside `gh issue close`/the closing comment, never left dangling. This is unconditional: it applies to **every** closing path, not just the shipped-fix flow — a research ticket closed once its report lands, an issue closed as duplicate/wontfix/not-planned, and a superseded ticket (see "When work lands via a different path" below) all remove the label at close time exactly the same way a shipped fix does.

A step that only exists as a phrase in a skill, disconnected from the action that triggers it, gets skipped under load — it happened on issue #34: the worktree was created and work landed without the label ever being applied. Don't rely on remembering to do this as a separate action each time: pickup tooling should apply the label as part of creating the worktree/branch, so labeling and pickup happen atomically. The global `worktree-manager` skill does exactly this — its `start <issue>` labels the issue automatically, and it's the same script across every repo, not something to reimplement per project. Where a repo's pickup instead goes through `github-ops` or something else that doesn't label automatically, treat "did I label it?" as a mandatory checkpoint immediately after `git worktree add`/branch creation, before writing any code — not a step to "get to."

## Manual user check — the gate before any merge or push
Automated tests passing is necessary but NOT sufficient to merge or push. After implementation and tests, and before any `git push`, branch merge, or PR merge:

1. Make the change live and reachable in the browser: the project's dev stack running (its documented run command and URLs — project `CLAUDE.md`, the `run` skill, or project memory; never assume another project's ports) with the change active. Walk the page yourself first with the `playwright` MCP server — navigate, perform the action, read the console — to confirm the handoff isn't broken before you hand it over.
2. Tell the user exactly what to check manually, in the three-part split `test-verification` defines: what you already verified in the browser (so they don't repeat it), what needs their eyes (absolute URL, the action, a falsifiable expected result), and what you could not verify and why.
3. Stop and wait for their explicit confirmation that it works. If they report a problem, fix it and repeat this gate from step 1.

If the change has no browser-observable surface, say so explicitly and tell the user how to verify it instead. Whether the stop-and-wait still applies depends on two conditions, and both must hold to skip it:

1. **The change cannot be verified before it lands.** Not "verifying is inconvenient" — genuinely impossible. The canonical case is this skills repo itself: a skill or agent edit only takes effect once it's merged and pulled into `~/.claude/`, so there is nothing for the user to check beforehand.
2. **Landing is cheap to undo.** A revert commit with no residue — no data migration, no external side effect, nothing already consumed downstream.

When both hold and the user has asked for the merge, proceed without waiting. The wait is not dropped, it is converted: the "how to verify" becomes mandatory and goes **in writing on the ticket** (the closing comment), not just in chat, so it survives the session and is there when the user next pulls.

When either condition fails, the stop-and-wait applies before merge/push exactly as it does for a browser change. CI config, database migrations, deploy scripts and infrastructure-as-code all have no browser surface and all stay inside the gate — a CI config is in fact verifiable *on the PR branch*, which is better evidence than a human's confirmation, so verify it there rather than skipping.

### Recording the check: "Test info" section on the ticket
The walkthrough in step 1 gets written into the ticket itself, not just described in chat — otherwise the evidence disappears once the session ends.

1. While walking the flow with the `playwright` MCP server, capture a screenshot (`browser_take_screenshot`) for each step. For a long or repetitive walkthrough (e.g. ten similar form fields), a screenshot per fundamental step is enough — the starting state, the action's result, and any edge case checked — but never skip the step that's the actual point of the ticket.
2. Commit the screenshots on the ticket's branch under `docs/test-evidence/<issue>-<slug>/NN-description.png` (numbered to match the steps), in the same commit as the change or a follow-up commit before the handoff. `gh` has no scriptable way to upload an image directly into an issue comment (that's the web UI's own attachment flow, not a public API) — a committed file with a stable URL is the reliable substitute.
3. Post a `## Test info` comment on the issue (`gh issue comment <n> --body-file -`) with the numbered steps, each followed by its screenshot referenced via `https://raw.githubusercontent.com/<owner>/<repo>/<commit-sha>/docs/test-evidence/.../NN-description.png` so it renders inline — use the **commit SHA**, not the branch name, since the ticket branch gets deleted after merge (per "Branch cleanup" below) while the commit stays reachable through `main`'s history.
   - **Private-repo gotcha:** `raw.githubusercontent.com` image embeds silently fail to render in issue comments on a **private** repo — the endpoint needs a token the viewer's browser session doesn't send, so the markdown image tag just shows broken with no error at write time. Check `gh repo view --json isPrivate` first; if private, use plain `https://github.com/<owner>/<repo>/blob/<sha>/<path>` markdown *links* instead of `![]()` embeds (they respect the viewer's github.com session and open the file's blob page, which does render the image — just not inline). Confirmed on subsplit issue #9: 4 raw.githubusercontent.com links posted, none displayed; fixed via `gh issue comment --edit-last` to blob links.
   - **Never let a real/working credential land in a committed screenshot** — if a step needs to show a password in cleartext (e.g. a visibility-toggle demo), use an obviously-fake placeholder value, not an actual test account's password; real credentials are chat-only (see the global "always surface test credentials" rule). A screenshot that only needs to prove an outcome (e.g. a post-login screen) carries no such risk since the credential isn't on screen at that point.
4. **Before posting (or right after, but before handoff): confirm the commit the links point to actually exists on GitHub, and that each screenshot resolves.** A commit that only exists in the local worktree — not yet pushed — makes every link in the comment 404, silently: `git commit` succeeding says nothing about `git push` having happened, and the two are easy to conflate. Push the ticket branch (not `main` — a topic-branch push is not the merge/push the manual gate below guards) if it isn't already up to date on the remote, then check each screenshot resolves with `gh api repos/<owner>/<repo>/contents/<path-to-screenshot>?ref=<commit-sha> --jq '.name'` (authenticated, works on a private repo) rather than a bare `curl` on the blob URL — an unauthenticated `curl` 404s on a private repo's blob page regardless of whether the file exists, so it can't tell you anything. Do this for every screenshot referenced, not just the first one.
5. Do this before the manual handoff (step 2 above): the ticket should already show what was checked when the user opens it, not just a chat message that scrolls away. Treat "did I post the Test info comment yet, and do its links actually resolve" as a checklist item before every handoff — it's easy to substitute a verbal chat summary for the recorded version and feel like the gate was satisfied when it wasn't (confirmed missed entirely on subsplit #32, where only `worktree-manager` had been invoked at pickup and this section was never loaded into context — see global CLAUDE.md's "Invoke product-ownership itself at ticket pickup"; confirmed again on #37, where the comment was posted with a correct-looking commit SHA that had never been pushed, so every link 404'd until the user reported it).

| Excuse | Reality |
|--------|---------|
| "All tests pass, so it's safe to push" | Tests are not the gate; the user's manual check is. |
| "It's a trivial/one-line change" | Trivial changes ship broken UIs too. Same gate. |
| "Pushing after tests is pre-authorized" | That pre-authorization operates *after* this gate, never instead of it. |
| "I already verified it in the browser myself" | Your own check prepares the handoff; it doesn't replace the user's. |
| "Playwright drove the whole flow green, that's stronger than a human click" | Playwright proves it runs. It can't tell you the result is *right* — that judgment is what the gate is for. |
| "The user seems away, I'll push and they can review later" | The push can wait. Waiting is the whole point of the gate. |
| "It's not visible in a browser, so the gate doesn't apply" | Wrong axis. The carve-out is "the user cannot verify it before it lands **and** it is cheap to revert" — not "there's nothing to look at". CI config, migrations, deploy scripts and IaC have no browser surface and stay inside the gate. |

## Closing when the fix ships
Once the fix is committed and pushed to the default branch (after tests pass **and** the manual gate above has cleared), close the issue directly — right away, without waiting to be asked. Don't rely on GitHub's auto-close commit-message keywords (`Fixes #N`/`Closes #N`) as the closing mechanism; close it explicitly via `gh issue close <N> --comment "..."`, referencing the commit SHA that shipped it, and remove the `in progress` label as part of that same step.

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
- Drafting a ticket that depends on/blocks another, or belongs under an epic → did you wire `--blocked-by`/`--blocking`/`--parent` before showing the draft, not after?
- Drafting a batch of tickets for a phase/goal (MVP or otherwise) → does a milestone exist for it, and is each ticket in the batch assigned to it?
- Starting work on an issue → is the `in progress` label on it? (Label yes, always — worktree only once code is actually about to be written.)
- About to `git push` or merge anything → did the user manually confirm in the browser that the change works? If not, stop and ask now.
- Did a browser walkthrough for the manual check → is it recorded in a `## Test info` comment (numbered steps + screenshots, blob links if the repo is private) before handing off to the user, not just described in chat?
- Ticket created from a Notion todo → was the source checkbox checked off with a reference to the new ticket?
- Fix pushed to the default branch → did you close the issue right away, without waiting to be asked?
- Closing an issue → was the `in progress` label removed?
- Just merged/superseded a branch → does `git branch -a` show only the default branch, locally and remotely, when you're done?
- Modified a skill → did you bump its frontmatter `version` and add the `CHANGELOG.md` line in the same commit?
- Added or renamed a repo skill or agent → is the "End-to-end workflow and handoffs" section still correct? Update it in the same commit.

## Boundary
This is about grounding and lifecycle hygiene for issues/branches, not about deciding product priority or roadmap — it doesn't replace the user's judgment on what to build next or in what order.
