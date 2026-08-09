---
name: test-verification
description: Use when deciding what to run to verify a code change - choosing the narrowest meaningful set of tests, lint, type checks, or manual smoke checks for backend, frontend, database, or API changes - and before claiming any change is done, fixed, or passing
version: 1.3.0
---

# Test Verification

Select the narrowest meaningful verification set first, then expand if justified.

**Pairs with:** `test-driven-development` governs *when* a test gets written (before the code); this skill governs *what* gets run once code exists. `product-ownership`'s manual user gate comes after this — green checks are evidence, never merge authorization.

**Evidence before assertion.** Never claim a change is done, fixed, or passing without having actually run the check in this session first. "It should work," a manual test from an earlier conversation, or confidence in the diff are not evidence — the command output is.

| Excuse | Reality |
|--------|---------|
| "The change is small/obvious, no need to run it" | Small changes break imports and types too; the run takes seconds |
| "I already verified this earlier in the session" | Re-verify after every subsequent edit — a later change can silently undo it |
| "Reading the diff is enough to know it's correct" | Reading confirms intent, not behavior; run it |

**Execution:** this skill decides *what* to run; delegate the actual runs to the `test-runner` agent, which executes suites/lint/typechecks and reports only the outcome, keeping verbose logs out of the conversation. Browser checks are the exception — drive those from the main session, because their output is the handoff the user reads, not a pass/fail line.

## Verification order
1. targeted unit or feature tests
2. formatter or lint
3. type checks
4. integration tests
5. build
6. browser smoke check on the change's own surface, when it has one

## Rules
- Verify the changed behavior directly.
- Prefer regression tests for bug fixes.
- Do not run the entire suite unless the change size justifies it.
- State clearly what remains unverified.

## By change type
- backend logic: focused tests around changed behavior
- frontend UI: render, interaction, loading/error states, responsive behavior
- migrations: migrate up/down plus affected data paths
- APIs: contract shape, status codes, validation errors
- performance-sensitive code: targeted benchmarks or query plans when relevant

## Browser checks
When the change has a browser-observable surface, drive a real browser with the `playwright` MCP server (`browser_navigate`, `browser_snapshot`, `browser_click`, `browser_fill_form`, `browser_console_messages`) instead of describing what the page should do. The accessibility snapshot and the console output are the evidence; a paragraph of expected behavior is not.

- Point it at the stack the user actually runs — real data, standard ports, one environment at a time, per CLAUDE.md. Never spin up a throwaway environment to make the check easier.
- Read the console on every page you touch. A correct-looking render with a red console is not a pass.
- Know the limit. Playwright proves the page loads, the element exists, the action fires, the state changes, nothing errored. It cannot prove the result looks right, the copy reads well, or the data is plausible. Those belong to the user — they are the reason the handoff below exists, not a gap to paper over.

## Manual handoff — telling the user what to test
Your browser check does not replace the user's; it produces the checklist for it. Never hand over a vague "please have a look". Split the handoff into three parts:

1. **Verified automatically** — one line each so the user doesn't redo it: URL, action, observed result.
2. **Needs your eyes** — numbered steps runnable without reconstructing context: the absolute URL (host and port included), what to click or type, and an expected result concrete enough to be falsifiable. "The totals row reads 3 articoli — €45,00" is checkable; "the totals look right" is not.
3. **Not verified, and why** — anything out of reach: a state the real data doesn't contain, an external integration, a device or browser you can't drive. State it plainly rather than letting it pass in silence.

If a case the user needs to see doesn't exist in the real dataset, seed temporary mock data for it per CLAUDE.md instead of dropping the step — and label it as mock in the handoff.

## Output
- What was checked
- What passed
- What remains unverified
- Why the chosen verification is sufficient

## Boundary
This picks the checks and enforces evidence before "done". It does not authorize a merge or push — that's `product-ownership`'s manual user gate — and it does not decide the test/code authoring order, which is `test-driven-development`'s.
