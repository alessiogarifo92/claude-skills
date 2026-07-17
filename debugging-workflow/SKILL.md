---
name: debugging-workflow
description: Use when investigating a regression, an unexplained failure, or a production incident and need a structured, evidence-first reproduction-to-root-cause process
version: 1.0.0
---

# Debugging Workflow

Debug systematically and evidence-first.

**Pairs with:** superpowers:systematic-debugging for one-hypothesis-at-a-time discipline under pressure; this skill is the domain checklist (bug classes, reproduction, output shape).

## Steps
1. Restate the observed problem precisely.
2. Find the smallest reproducible case.
3. Separate symptoms from root-cause candidates.
4. Inspect logs, traces, stack traces, and state transitions.
5. Form one hypothesis at a time.
6. Change one variable at a time.
7. Reproduce the fix.
8. Add or update a regression test when possible.

## Good discipline
- Do not patch multiple areas blindly.
- Do not assume the error surface is the root cause.
- Do not hide uncertainty.
- Prefer instrumentation over guesswork.

## Common bug classes
- shape mismatch
- stale cache or state
- race condition
- serialization mismatch
- environment mismatch
- authorization oversight
- lifecycle or timing issue
- query behavior difference

## Output
- Reproduction
- Root cause
- Minimal fix
- Verification
- Residual risk
