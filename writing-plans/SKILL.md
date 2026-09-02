---
name: writing-plans
description: Use when you have a spec or confirmed requirements for a multi-step task and need to sequence it into a written plan before touching code — turning confirmed intent into ordered, checkable steps
version: 1.1.0
---

# Writing Plans

Turn confirmed intent into an ordered, checkable sequence before any code is written. This is the sequencing discipline; `docs-and-specs` is the document format the plan gets written in.

**Pairs with:** `brainstorming` confirms intent first — this skill starts once direction is picked, not before; `grill-me` sits between the two when the picked direction still has open decisions, and hands over a ticket to plan against. `docs-and-specs` supplies the Context/Goal/Constraints/Options/Decision/Risks/Verification structure for the plan document itself. `direct-execution` skips this entirely for linear, single-focus tasks. `executing-plans` and `subagent-driven-development` run the plan once written.

## When this applies
- Multi-step task where steps have real dependencies or a real risk of drift between them, and the spec/requirements are already confirmed (post-`brainstorming`)
- NOT for: a task `direct-execution`'s decision tree already resolves directly, or a plan so short it's just a mental TODO

## What a good plan has
- The goal restated in one line
- Ordered steps, each with what "done" looks like for that step specifically
- Explicit dependency markers: which steps block which, which are independent (candidates for `subagent-driven-development`)
- Risks/unknowns called out, not buried in prose
- A verification point per phase, not just one at the very end

## Rules
- Confirm the plan with the user before executing it — a plan is a commitment device, not a formality to skip when the shape feels obvious.
- Steps are units of decision/behavior, not units of "files touched."
- Use `docs-and-specs`' output structure for the plan document itself rather than inventing a new shape each time.

## Common mistakes
| Mistake | Fix |
|---|---|
| Plan as vague prose ("first do X, then improve things") | Each step names a concrete artifact/check |
| Steps split by file touched, not by dependency | Steps are units of decision/behavior |
| No user checkpoint before execution starts | Show the plan, wait for confirmation |

## Boundary
This decides the shape and sequencing of the plan. Writing it up as a polished document is `docs-and-specs`; running it step by step is `executing-plans` or `subagent-driven-development`; whether to plan at all is `direct-execution`'s call.
