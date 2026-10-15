---
name: writing-skills
description: Use when creating a new skill, editing an existing one, or renaming/consolidating skills in this repo, to decide whether it's warranted and verify it actually works before treating it as done
version: 1.6.0
model: opus
effort: medium
---

# Writing Skills

**Run on:** opus · effort medium — authoring conventions and verification.

Author skills that match this repo's own conventions, and verify each one works before calling it done — scaled to what the skill actually is, not a fixed ritual.

**Pairs with:** `product-ownership`'s "Skill versioning" section for the version-bump + CHANGELOG rule that applies to every skill touched, new or edited.

## When to create a skill
- The technique/pattern isn't obvious and would be reused across projects or sessions
- NOT for: a one-off solution, a project-local convention (put it in that repo's own instructions file instead), or anything better enforced by a script/lint than by judgment

## Format — match the repo's existing skills
- Frontmatter: `name` (letters/numbers/hyphens only), `description` starting with "Use when..." stating only *triggers* — never summarize the skill's own process, or agents will follow the summary instead of reading the content — and a semver `version`
- Right under the title: a `**Run on:** <opus|sonnet|haiku|main> · effort <low|medium|high> — <reason>` line (what model and effort should apply this skill; `README.md` lists them all). An `opus` skill also carries `model: opus` and the same `effort:` in its frontmatter; sonnet/haiku/main skills never set `model`/`effort` (an override lasts the rest of the turn, so a downward one would trap a long autonomous run on a weaker model) — `validate.py` enforces both
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
- Run `python3 scripts/validate.py` before committing: it checks frontmatter, versions, `Run on` lines, agent frontmatter, `Pairs with` cross-references and the README matrix. CI runs the same script.
- Adding a skill or agent also means a row in `README.md`'s model matrix and, if it is a stage of the workflow, a row in `autonomous-workflow`'s stage map.
- **A rule that keeps being violated usually has wrong data behind it — fix the data before adding a check.** When a rule is broken systematically, the reflex is to write it more forcefully or to enforce it with a hook or a script. Look first for artifacts in the repo that *contradict* it: a backlog carrying the label the rule forbids, a config using the pattern it bans, existing files doing it the old way. Observed precedent beats prose — a session reads the rule once and sees the counter-examples repeatedly, so it follows the counter-examples. And measure before building any check: count the actual violations (`git log`, the issue list) instead of assuming there are many. **Why:** `product-ownership`'s "never `enhancement`, always `feature`" was written on 2026-08-16 (`bd8fa36`). Every issue opened after it — #16, #18, #19, #22, then #24 — used `enhancement` anyway: three different sessions, each with the rule loaded in context, each following the seven existing issues in front of it. The fix was deleting the label, not enforcing the sentence: GitHub then rejects the wrong value in every session and every client, with nothing to maintain. The same measurement killed a proposed commit hook for the version-bump rule — 2 violations in 27 `SKILL.md` commits, none in the last month, i.e. a rule already being followed, where a fragile matcher would only have added false confidence.
- **Date and source every volatile fact.** A price, free-tier quota, billing multiplier, plan limit or OS/browser-version claim written into a skill carries "as of YYYY-MM" and, where one exists, the source it came from — and the skill says it is re-checked at decision time (`market-analyst` for costs) rather than quoted as current. Prefer the rule ("macOS minutes cost several times Linux on a private repo") over the number when the rule is what drives the decision. **Why:** the mobile/PWA additions of 2026-10-15 quoted build quotas and runner multipliers that a review could only confirm from third-party pages; an undated number in a skill reads as current long after it stops being true, and gets passed to the user as fact.
- Don't skip verification because "it's just a reference" or "a simple addition" — an untested skill's gaps cost more to find later than to test now.

## Boundary
This governs authoring and testing skills in this repo. It doesn't decide which skill applies to a given task — that's each skill's own description doing its job at discovery time.
