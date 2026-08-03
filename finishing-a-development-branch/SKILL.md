---
name: finishing-a-development-branch
description: Use when implementation is complete, all tests pass, and a decision is needed on how to integrate the work — merge, PR, rebase, or direct push — before product-ownership's closing steps run
version: 1.0.0
---

# Finishing a Development Branch

Decide how completed work actually lands on the default branch. This sits between the manual user gate (`product-ownership`) and the mechanical closing steps (issue close, label removal, branch cleanup — also `product-ownership`).

**Pairs with:** `product-ownership`'s manual user gate must clear before any of this runs; its closing section runs after, regardless of which option is picked here.

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

## Check
- Does `git log` show a dominant pattern (merge commits vs. squash vs. rebase)? Follow it.
- Is the manual user gate actually cleared? If not, stop — that gate comes first, always.

## Boundary
This decides *how* completed work lands on the default branch. Whether it's safe to land at all is `product-ownership`'s manual gate; what happens after landing is also `product-ownership`.
