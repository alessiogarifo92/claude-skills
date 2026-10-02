---
name: receiving-code-review
description: Use when receiving code review feedback, before implementing any suggested change, to verify it technically rather than agreeing performatively or blindly applying it
version: 1.1.0
model: opus
effort: medium
---

# Receiving Code Review

**Run on:** opus · effort medium — judging feedback technically, not applying it blindly.

A review comment is a claim, not a fact — verify it before acting, exactly like `orchestrating-agents`' verification gate treats a subagent's report.

**Pairs with:** `requesting-code-review` triggers the review this skill processes the output of. `orchestrating-agents`' verification-gate mindset ("claim, not fact") is the same discipline applied here.

## When this applies
- Any feedback from a review pass (human or the `code-review` plugin), before touching code to address it

## Loop
1. Restate the comment's technical claim in your own words — if it's unclear, ask; don't guess at intent.
2. Check it against the actual code/behavior: reproduce the concern if it describes a bug, read the referenced line if it's a style/architecture point.
3. If correct: apply the fix, scoped to exactly what the comment asked — not an opening for unrelated cleanup.
4. If the comment is wrong, outdated, or based on a misunderstanding: say so explicitly, with the evidence, rather than implementing a change that doesn't actually fix anything.
5. If genuinely unclear which of two valid approaches the reviewer prefers, ask rather than silently picking one.

## Red flags
| Behavior | Reality |
|---|---|
| "Good catch!" applied without checking if it's actually correct | Performative agreement isn't verification |
| Implementing a suggestion you believe is wrong, without saying so | Silent compliance hides a real disagreement that should surface |
| Treating every comment as equally urgent | Distinguish blocking issues from optional nits |

## Boundary
This is about processing feedback once received. Deciding whether/when to request the review in the first place is `requesting-code-review`.
