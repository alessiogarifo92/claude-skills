---
name: finishing-a-development-branch
description: Use when implementation is complete, all tests pass, and a decision is needed on how to integrate the work — merge, PR, rebase, or direct push — before product-ownership's closing steps run
version: 1.1.1
---

# Finishing a Development Branch

**Run on:** sonnet · effort low — integration choice is mechanical once the gate has cleared; `github-ops` (haiku) runs the commands.

Decide how completed work actually lands on the default branch. This sits between the manual user gate (`product-ownership`) and the mechanical closing steps (issue close, label removal, branch cleanup — also `product-ownership`).

**Pairs with:** `deploy-readiness` (when the merge deploys), `product-ownership`'s manual user gate must clear before any of this runs; its closing section runs after, regardless of which option is picked here.

## When this applies
- Implementation done, tests green, `product-ownership`'s manual user gate already cleared
- NOT before that gate clears — integration mechanics are moot if the change hasn't been confirmed working

## Options to weigh
| Option | When it fits |
|---|---|
| Direct push to default branch | Small repo/solo work, no PR review culture, trivial or already-reviewed change |
| PR + squash merge | Standard collaborative flow, wants one clean commit on the default branch |
| PR + merge commit | Wants to preserve the branch's individual commit history |
| PR + rebase | Wants linear history without a merge commit, branch already clean |

## Rules
- Check `git log` for the pattern this repo already uses before picking a mode — follow existing convention unless told otherwise.
- Never force-push or rewrite already-pushed shared history to fit a chosen mode.
- Whichever mode is chosen, `product-ownership`'s closing steps (issue close, label removal, branch cleanup) still run after — this skill only decides the integration mechanism.

## `gh pr merge` is hard-blocked by the auto-mode classifier — hand it to the user
`gh pr merge` (and any attempt to edit `.claude/settings.json` / `.claude/settings.local.json` to grant standing permissions) is blocked by the Claude Code auto-mode classifier as a self-escalation guard — this holds even when the user has just explicitly said "you're authorized to merge/do X from now on" earlier in the same conversation. In-conversation verbal authorization is not accepted; the permission has to come through a channel outside Claude's own write access.

- **Why:** confirmed twice in a row on one ticket — `gh pr merge --merge --delete-branch` was denied, and then writing the exact settings.json rule the tool's own error message suggested was *also* denied. Retrying the same action a different way does not work around this; it's a hard technical control, not a policy to reason around.
- **How to apply:** the moment `gh pr merge` (or a similarly consequential git/GitHub action) gets classifier-blocked, don't retry it and don't try to edit permissions to unblock it — immediately tell the user to run the exact command themselves with the `! <command>` prefix (runs as their own action, not Claude's). If that local run then hits its own errors (e.g. `git` refusing a checkout because the base branch is already checked out in another worktree — the primary checkout), that's just a local sync side-effect; check `gh pr view <n> --json state,mergeCommit` — the remote merge via GitHub's API usually already succeeded even when the local git step failed, and `--delete-branch` may need a manual follow-up (`git push origin --delete <branch>`) if it didn't complete. For standing future authorization, point the user at `/permissions` or `/config`, or tell them to edit `.claude/settings.local.json` themselves — Claude cannot write that file's permission-granting content even on direct request.

## Check
- Does `git log` show a dominant pattern (merge commits vs. squash vs. rebase)? Follow it.
- Is the manual user gate actually cleared? If not, stop — that gate comes first, always.

## Boundary
This decides *how* completed work lands on the default branch. Whether it's safe to land at all is `product-ownership`'s manual gate; what happens after landing is also `product-ownership`.
