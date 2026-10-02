---
name: test-driven-development
description: Use when implementing any feature or bugfix in a codebase with an existing test setup, before writing implementation code, to decide whether a test should be written first and to follow red-green-refactor instead of writing tests after the fact
version: 1.0.1
---

# Test-Driven Development

**Run on:** sonnet · effort medium — red-green-refactor discipline.

Write the test that describes the intended behavior before the code that produces it, whenever the codebase has a test setup capable of running it.

**Violating the letter of red-green-refactor is violating the spirit of it.** Writing the test after the code and calling it "TDD" produces a test that confirms what the code does, not one that specifies what it should do — the two are not interchangeable.

**Pairs with:** `test-verification` picks *what* to run once code exists; this skill governs *when* the first test gets written, before implementation. `debugging-workflow` for regressions — a failing repro there IS the red step.

## When this applies
- New feature or bugfix in a codebase with an existing test runner/framework
- NOT for: throwaway scripts, exploratory spikes explicitly framed as such, or codebases with no test infrastructure to hook into — say so explicitly instead of skipping silently

## Cycle
1. **RED** — write a test for the behavior that doesn't exist yet. Run it. Confirm it fails for the expected reason (not a typo/import error).
2. **GREEN** — write the minimum code to pass that test. Nothing extra "while I'm in there."
3. **REFACTOR** — clean up with the test as a safety net. Re-run to confirm still green.
4. Repeat per behavior, not per file.

## Rules
- Never write implementation before its test exists and has been run red.
- A bugfix's test reproduces the bug first (red), then the fix turns it green — this doubles as the regression test.
- Don't keep code written before its test as "reference" while you retrofit tests around it — delete it and restart the cycle.

## Red flags — stop and restart the cycle
| Excuse | Reality |
|---|---|
| "The fix is obvious, test after" | Obvious fixes break edge cases test-first would have caught |
| "I already manually checked it works" | Manual checks don't survive the next change; the test does |
| "Faster to write both together" | Then the test never fails red — it can't prove anything |
| "Tests after achieve the same purpose" | Tests-after answer "what does this do?"; tests-first answer "what should it do?" |
| "This case is too simple to need red first" | Simple cases regress too, and the red step takes seconds |

## Boundary
This governs the authoring order of test vs. code. Choosing which checks matter for a given change is `test-verification`'s job, not this skill's.
