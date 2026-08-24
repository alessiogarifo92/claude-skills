---
name: worktree-manager
description: Use when actual code work (not research/drafting) is about to start on a GitHub issue in any repo, when checking which worktrees/sessions are active, or after a branch merges — creates/lists/cleans per-ticket git worktrees so parallel Claude Code sessions never write to the same branch. Same convention across every project.
version: 1.5.1
---

Every Claude Code session that's about to write or modify code for a ticket gets its own worktree and branch. Never commit ticket work directly on the default branch in the primary checkout, and never reuse another session's worktree.

`start` is a code-work trigger, not a ticket-pickup trigger. Don't call it the moment you pick up an issue — call it right before the first file edit. Research/investigation tickets (report lands as an issue comment, nothing committed) never need a worktree at all; see "Research tickets" below.

This is a **global** skill: the naming convention, branch/path scheme, and label handling are identical across every project — only the stack/language inside each repo differs, and the underlying script doesn't need to know that. Don't create a per-project copy of this script or its docs; if a repo needs something this doesn't cover, extend this skill, not a project-local fork.

## Commands (work from anywhere inside any repo, including from a linked worktree)

```bash
~/.claude/skills/worktree-manager/scripts/worktree.sh start <issue> [slug]   # create + lock .claude/worktrees/<slug> on branch worktree-<issue>-<slug>, label the issue "in progress"
~/.claude/skills/worktree-manager/scripts/worktree.sh list                   # active worktrees, their issue, lock state, plus ORPHAN dirs
~/.claude/skills/worktree-manager/scripts/worktree.sh cleanup [--dry-run]    # remove orphan dirs + merged unlocked worktrees/branches
```

`start` prints the worktree path — `cd` there and do all work inside it. When the slug is omitted it is derived from the issue title via `gh` (which resolves the current repo from `git remote`, so no per-project config is needed). The worktree is locked with reason `issue #<n>`, which is how `list` (and other sessions) see who owns what.

`start` also applies the `in progress` label to the issue itself (creating the label first if the repo doesn't have it yet). This closes a gap where labeling was a separate manual step that got skipped under load (see `product-ownership`'s "Work-in-progress label" section) — it's now atomic with pickup instead of something to remember. If `gh` fails to label (auth/network hiccup), `start` prints a warning but still hands you the worktree — check the warning and label the issue manually if you see one.

## Lifecycle

1. **Pickup**: reading the issue, grounding it, drafting a plan or a research report — none of that needs `start`. Before picking "the next ticket," run `ListAgents` to check for other active peer Claude Code sessions on the same machine/repo, and message any `busy` one to ask what it's on — don't trust a locked worktree + "in progress" label alone as proof a ticket is either live or abandoned. On subsplit ticket #8, a locked worktree with fresh uncommitted WIP looked like leftover state from an interrupted session; it was actually another live agent working on it in real time, only caught by asking. Call `start <issue>` only at the point the first file is actually about to be edited, then work only inside the printed path.
2. **During**: `list` shows what other sessions hold, across whichever repo you're standing in. If `start` says the slug or branch already exists, another session owns that ticket — coordinate with the user instead of forcing a second worktree. Worktrees isolate *code*, not the shared services behind it: before any destructive DB reset/seed, check no other ticket carries `in progress` first (global CLAUDE.md, "Never wipe shared DB data while another ticket is in progress") — same `ListAgents`-first discipline as above, applied to a specific shared resource instead of a ticket.
   - **Dev server ports are the same kind of shared, machine-wide resource** — not scoped by git worktree either. Each project documents its own ports in project memory, as a **pool of interchangeable ports, one per concurrent session** — not one port per surface. A session claims *one* free port from the pool and serves everything that ticket's manual check needs on it: the same dev server instance answers both the browser (`http://localhost:<port>`) and the mobile/Expo Go client over LAN (`http://<lan-ip>:<port>`), so web and native never need a port each. Example: subsplit's pool is 8081 and 8082 — agent A takes 8081 for both its surfaces, agent B takes 8082 for both of its, instead of one agent alone occupying 8081 for native/Expo-LAN plus 8082 for web and leaving nothing for the second agent. Before starting a dev server, check `ss -tln` (plus `ListAgents` for parallel sessions) and claim a port the pool says is free. Taking the pool's second port because the first is busy is normal and not a deviation; going *outside* the documented pool needs a real, confirmed conflict — never pre-emptively "to be safe."
     - This does not loosen `test-verification`'s "real data, standard ports, one environment at a time": every port in the pool *is* a standard, documented port, not an ad-hoc scratch environment, and the shared backend/DB behind them stays governed by that rule (and by the "don't wipe shared DB data" rule above). The pool splits the *front* of the stack across parallel sessions; it does not license two sessions to fight over the data behind it.
   - **Before freeing a port a peer session asks for, check for a free alternative first — don't default to capitulating.** A peer's request is real and should be taken seriously, but it is not automatically higher priority than your own user's still-pending task on that same port. Check `ss -tln` for another free port (e.g. the project's other standard port) and offer that; only actually tear down your own server if no reasonable alternative exists or your own user's task isn't currently pending on it. Confirmed on subsplit: a peer asked for port 8081 while the user's own manual-verification handoff on that exact port was still open and unconfirmed, and a free alternative port existed the whole time — the port was freed anyway without checking either, interrupting the user's own pending task for no reason.
3. **After merge to the default branch**: if a running stack was swapped to serve this worktree for manual verification, swap the code-serving layer back to the primary checkout on the default branch **before** running `cleanup` (global CLAUDE.md, "Restore the stack to main when a ticket closes") — `cleanup` prints a reminder when it removes a worktree, but it can't do the swap itself since the mechanism (bind mount, `docker compose` source, symlink, or restarting a directly-run dev server like Expo Go's `expo start` from the right directory) differs per project. Then: `git worktree unlock .claude/worktrees/<slug>`, then run `cleanup`. It removes your (now unlocked, merged) worktree and branch, plus any orphan directories and leftover merged `worktree-*` branches. This is the worktree-side half of the branch-cleanup rule in the product-ownership skill — the remote branch still needs `git push origin --delete`. `cleanup` only touches worktrees/branches, not the GitHub issue itself — closing the issue and stripping its `in progress` label (`gh issue close`/`gh issue edit --remove-label`) is a separate step, done regardless of whether the ticket ever got a worktree at all.

## Research tickets: no worktree, label it directly

A ticket whose deliverable is a report posted as an issue comment (no repo commit) never needs `start` — creating a worktree "just because a ticket was picked up" is exactly the false trigger this skill avoids. Mark it in progress without a worktree:

```bash
gh issue edit <issue> --add-label "in progress"
```

If the research later turns into (or produces) something that gets committed — a `docs/` file, a code change — that's the point code work begins, and `start` applies from there, same as any other ticket.

## Safety model

- `cleanup` never touches a **locked** worktree, even if its branch looks merged — a fresh branch with no commits of its own also counts as "merged", and yanking it would destroy another session's workspace. Unlocking is the explicit handoff step.
- A branch only counts as "merged" if it's a literal git ancestor of `main`, **or** `gh` reports a merged PR with that branch as head — the second check exists because a squash or rebase merge (GitHub's default for this project's repos) produces a brand-new commit on `main`, so the original branch is never an ancestor even though its content is fully there. Without this fallback, `cleanup` silently does nothing on every squash-merged ticket — it reports no error, so the gap is easy to miss (this happened for real on DamianoGuideSite ticket #7: `cleanup` claimed success while the worktree and branch were still sitting there, locked, until it was noticed and fixed by hand).
- Deletion still favors the safe path: `git branch -d` (never `-D`) whenever the branch is a real ancestor. Only when it isn't — and a merged GitHub PR independently confirmed the merge — does `cleanup` force-delete with `-D`; a bare local heuristic never triggers `-D` on its own.
- Unmerged branches (no ancestor relationship and no merged PR found) are never deleted; dirty worktrees are skipped with a warning.
- `--dry-run` prints what would happen without changing anything.

## Per-repo requirements

The script assumes:
- `main` as the default branch (hardcoded `DEFAULT_BRANCH` in the script — if a repo uses something else, pass that repo's branch name isn't currently parameterized; flag it if this comes up so the script can read it from `git symbolic-ref`/`gh repo view` instead of assuming).
- `gh` authenticated against the repo in question (for slug derivation and labeling).
- A committed `.gitignore` the script can append `.claude/worktrees/` to (it does this automatically on first `start` in a repo and prints a reminder to commit it).
