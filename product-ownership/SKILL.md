---
name: product-ownership
description: Use when drafting or creating a GitHub issue/ticket, researching external sources needed to write one, deciding whether something is a bug/research/implementation ticket, starting or finishing implementation work on a ticket, about to push or merge a completed change, or cleaning up branches after a PR merges or a commit supersedes it
version: 1.0.0
---

# Product Ownership

Own the lifecycle of a work item end to end: from a raw problem report to a grounded ticket, through to the branch cleanup once the work has actually shipped. Grounding tickets in the real code/data is expected baseline behavior, not this skill's job — this skill is about the parts that get skipped without a deliberate habit: separating ticket types, confirming before publishing, reusing repo conventions, and closing the loop on branches.

## Ticket types — don't blend them
- **Bug**: root cause identified in code. Deliverable is the fix.
- **Research**: deliverable is a written report (issue comment or `docs/` file), *not* code. Close the research ticket when the report lands and open a **separate** implementation ticket that references it — don't let research quietly turn into unplanned implementation, and don't let an open research ticket sit unresolved once the report is done.
- **Implementation**: references the research/decision it's grounded in instead of re-deriving it.

## Before creating on GitHub
- Draft the full title + body and show it to the user; wait for confirmation before `gh issue create`, unless they've explicitly said to just create it directly.
- Run `gh label list` and reuse what exists instead of inventing new labels.
- Match the repo's existing issue tone/language/section structure if prior issues establish one (check `gh issue list`/`gh issue view` on a couple of examples).

## Work-in-progress label
The moment actual implementation work starts on an issue (not just drafting/grounding it) — add an `in progress` label to it. If the repo doesn't have that label yet (`gh label list`), create it first: `gh label create "in progress" --color fbca04 --description "Actively being worked on"`. Remove the label when the issue closes — GitHub does not strip labels on close automatically, so this is a manual step to do alongside `gh issue close`/the closing comment, not something to leave dangling.

## Manual user check — the gate before any merge or push
Automated tests passing is necessary but NOT sufficient to merge or push. After implementation and tests, and before any `git push`, branch merge, or PR merge:

1. Make the change live and reachable in the browser: dev stack running (`docker compose up -d` in this repo — frontend at http://localhost:3000, API docs at http://localhost:8010/docs) with the change active. Open/curl the relevant page yourself first to confirm the handoff isn't broken.
2. Tell the user exactly what to check manually: which URL/page, what action to perform, and what they should see.
3. Stop and wait for their explicit confirmation that it works. If they report a problem, fix it and repeat this gate from step 1.

If the change has no browser-observable surface (pure tooling, CI config, docs), say so explicitly and tell the user how to verify it instead — the stop-and-wait for their confirmation still applies before merge/push.

| Excuse | Reality |
|--------|---------|
| "All tests pass, so it's safe to push" | Tests are not the gate; the user's manual check is. |
| "It's a trivial/one-line change" | Trivial changes ship broken UIs too. Same gate. |
| "Pushing after tests is pre-authorized" | That pre-authorization operates *after* this gate, never instead of it. |
| "I already verified it in the browser myself" | Your own check prepares the handoff; it doesn't replace the user's. |
| "The user seems away, I'll push and they can review later" | The push can wait. Waiting is the whole point of the gate. |

## Closing when the fix ships
Once the fix is committed and pushed to the default branch (after tests pass **and** the user has confirmed the manual browser check above), close the issue directly — right away, without waiting to be asked. Don't rely on GitHub's auto-close commit-message keywords (`Fixes #N`/`Closes #N`) as the closing mechanism; close it explicitly via `gh issue close <N> --comment "..."`, referencing the commit SHA that shipped it, and remove the `in progress` label as part of that same step.

This is pre-authorized as standard practice for the ticket-implementation workflow described in this skill — it doesn't extend to other GitHub actions (merging PRs, force-pushing, etc.), which still default to asking first.

## When work lands via a different path than expected
If a PR gets superseded (e.g. you push a direct commit instead of merging its branch), close **both** the issue and the PR, and reference what actually shipped it (commit SHA or PR number) in the closing comment — don't leave either dangling as if nothing happened.

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
- Starting work on an issue → is the `in progress` label on it?
- About to `git push` or merge anything → did the user manually confirm in the browser that the change works? If not, stop and ask now.
- Fix pushed to the default branch → did you close the issue right away, without waiting to be asked?
- Closing an issue → was the `in progress` label removed?
- Just merged/superseded a branch → does `git branch -a` show only the default branch, locally and remotely, when you're done?
- Modified a skill → did you bump its frontmatter `version` and add the `CHANGELOG.md` line in the same commit?

## Boundary
This is about grounding and lifecycle hygiene for issues/branches, not about deciding product priority or roadmap — it doesn't replace the user's judgment on what to build next or in what order.
