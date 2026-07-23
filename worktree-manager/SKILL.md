---
name: worktree-manager
description: Use when actual code work (not research/drafting) is about to start on a GitHub issue in any repo, when checking which worktrees/sessions are active, or after a branch merges — creates/lists/cleans per-ticket git worktrees so parallel Claude Code sessions never write to the same branch. Same convention across every project.
version: 1.1.0
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

1. **Pickup**: reading the issue, grounding it, drafting a plan or a research report — none of that needs `start`. Call `start <issue>` only at the point the first file is actually about to be edited, then work only inside the printed path.
2. **During**: `list` shows what other sessions hold, across whichever repo you're standing in. If `start` says the slug or branch already exists, another session owns that ticket — coordinate with the user instead of forcing a second worktree.
3. **After merge to the default branch**: `git worktree unlock .claude/worktrees/<slug>`, then run `cleanup`. It removes your (now unlocked, merged) worktree and branch, plus any orphan directories and leftover merged `worktree-*` branches. This is the worktree-side half of the branch-cleanup rule in the product-ownership skill — the remote branch still needs `git push origin --delete`. `cleanup` only touches worktrees/branches, not the GitHub issue itself — closing the issue and stripping its `in progress` label (`gh issue close`/`gh issue edit --remove-label`) is a separate step, done regardless of whether the ticket ever got a worktree at all.

## Research tickets: no worktree, label it directly

A ticket whose deliverable is a report posted as an issue comment (no repo commit) never needs `start` — creating a worktree "just because a ticket was picked up" is exactly the false trigger this skill avoids. Mark it in progress without a worktree:

```bash
gh issue edit <issue> --add-label "in progress"
```

If the research later turns into (or produces) something that gets committed — a `docs/` file, a code change — that's the point code work begins, and `start` applies from there, same as any other ticket.

## Safety model

- `cleanup` never touches a **locked** worktree, even if its branch looks merged — a fresh branch with no commits of its own also counts as "merged", and yanking it would destroy another session's workspace. Unlocking is the explicit handoff step.
- Unmerged branches are never deleted (`git branch -d`, never `-D`); dirty worktrees are skipped with a warning.
- `--dry-run` prints what would happen without changing anything.

## Per-repo requirements

The script assumes:
- `main` as the default branch (hardcoded `DEFAULT_BRANCH` in the script — if a repo uses something else, pass that repo's branch name isn't currently parameterized; flag it if this comes up so the script can read it from `git symbolic-ref`/`gh repo view` instead of assuming).
- `gh` authenticated against the repo in question (for slug derivation and labeling).
- A committed `.gitignore` the script can append `.claude/worktrees/` to (it does this automatically on first `start` in a repo and prints a reminder to commit it).
