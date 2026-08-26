---
name: writing-skills
description: Use when creating a new skill, editing an existing one, or renaming/consolidating skills in this repo, to decide whether it's warranted and verify it actually works before treating it as done
version: 1.2.0
---

# Writing Skills

Author skills that match this repo's own conventions, and verify each one works before calling it done — scaled to what the skill actually is, not a fixed ritual.

**Pairs with:** `product-ownership`'s "Skill versioning" section for the version-bump + CHANGELOG rule that applies to every skill touched, new or edited.

## When to create a skill
- The technique/pattern isn't obvious and would be reused across projects or sessions
- NOT for: a one-off solution, a project-local convention (put it in that repo's own instructions file instead), or anything better enforced by a script/lint than by judgment

## Format — match the repo's existing skills
- Frontmatter: `name` (letters/numbers/hyphens only), `description` starting with "Use when..." stating only *triggers* — never summarize the skill's own process, or agents will follow the summary instead of reading the content — and a semver `version`
- Body: short overview, a `**Pairs with:**` line cross-referencing related skills by name, a `When this applies` / `NOT for` split, the core technique as steps/table/rules, a `Common mistakes` or red-flags table, and a `Boundary` line stating what this skill does NOT own

## Test before treating it as done — scaled to skill type
| Skill type | Example | How to verify |
|---|---|---|
| Discipline (enforces a rule under pressure) | `test-driven-development`, evidence rules in `test-verification` | Run one pressure scenario via a subagent (time pressure, sunk cost, "obviously fine") — confirm it holds under the temptation to skip |
| Technique/recipe (how-to steps) | `debugging-workflow`, `finishing-a-development-branch` | Apply it to one realistic scenario yourself or via an agent; check the output has the right shape |
| Orchestration (sequences other skills) | `project-lifecycle`, `multi-agent-brainstorm` | Check every cross-reference resolves to a real skill; walk through one scenario end-to-end |

## Rules
- Before editing an existing skill, `git fetch origin` and check the local branch isn't behind `origin/main` — a cloud/remote session may have already merged the same fix (often better-worded) while the local checkout sat stale. Editing on a stale base risks redoing work that already landed, and the two versions conflict on push instead of one superseding the other. Confirmed on `worktree-manager`: a dev-server-ports correction was made locally against a 3-days-stale `main`, only to find `origin/main` already had a more complete fix for the same rule, merged via a cloud session's PR — the local edit had to be discarded and reconciled by resetting to `origin/main`.
- Bump the skill's `version` (MAJOR = behavior change, MINOR = new section/rule, PATCH = fix/clarification) and add a `CHANGELOG.md` line for every skill touched, not just new ones — per `product-ownership`'s versioning rule.
- Renaming a skill means fixing every cross-reference to its old name repo-wide (`grep -rl old-name`), not just the file itself.
- Adding or renaming a skill means re-checking the three routing tables that sequence skills — `product-ownership`'s "End-to-end workflow and handoffs", `orchestrating-agents`' workflow phases, and `project-lifecycle`'s phases — in the same commit. A new skill nothing routes to is invisible.
- Cross-references go both ways: if skill A names B as its next/previous step, B should name A back. One-way links leave the entry point unable to send anyone onward.
- Don't skip verification because "it's just a reference" or "a simple addition" — an untested skill's gaps cost more to find later than to test now.

## Boundary
This governs authoring and testing skills in this repo. It doesn't decide which skill applies to a given task — that's each skill's own description doing its job at discovery time.
