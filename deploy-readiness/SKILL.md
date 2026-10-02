---
name: deploy-readiness
description: Use when a project or change is about to be deployed or made publicly reachable — choosing the hosting target, preparing secrets and config, migrations and rollback, the go/no-go check, post-deploy smoke tests, and the recurring cost actually billed — the deploy itself, not the earlier choice of stack or hosting (`market-analyst`)
version: 1.1.3
model: opus
effort: high
---

# Deploy Readiness

**Run on:** opus · effort high — the Level-3 go/no-go and hosting choice stay in the main session; the audit runs on `release-auditor` (sonnet).

Deploy is where an unverified assumption becomes an incident. This skill makes the last gate explicit: a pinned commit, a checked rollback, a smoke test on the real target, and a user go/no-go.

**Pairs with:** `project-lifecycle`'s Deploy phase (the entry), `security-review` (mandatory before anything is publicly reachable), `market-analyst` (hosting cost), `database-design` (migration rollout), `test-verification` (smoke tests are evidence, not claims), `cross-verification` Mode D (the panel for this gate), `finishing-a-development-branch` (merge before deploy), `product-marketing-strategist` (launch comes after a verified deploy).

## When this applies
- First deploy of a project, a release to production, a migration that runs against live data, a change that opens a new public endpoint
- NOT for merging to a branch that does not auto-deploy, or for a local/dev stack

## Procedure
1. **Pin the release**: full commit SHA of default branch, CI green on that SHA, changelog/ticket list.
2. **Choose the target** the cheapest viable way (`market-analyst`): state the cost today and at 10x, free tier limits, and what happens when they are exceeded. The user confirms the target and its cost before anything is provisioned.
3. **Config and secrets**: every variable listed per environment; none in the repo or history; the deploy target holds them. Document which variables a project needs (this also protects remote sessions, per the global `.mcp.json` rule).
4. **Data**: migrations reversible or expand/contract; order of deploy vs migration stated; a backup or restore point taken before a migration that cannot be undone.
5. **Rollback**: name the previous artifact and the exact command or button; confirm it is data-compatible. No rollback path means the deploy is a Level-3 decision for the user.
6. **Audit**: dispatch `release-auditor` + `security-auditor` + `verifier` in parallel per `cross-verification` Mode D; resolve blockers; `critic` gives the go/no-go reading. At this point there is no live target yet: the `verifier` replays CI/staging checks, and the live smoke test happens at step 9.
7. **User go/no-go**: present SHA, cost, blockers/follow-ups, rollback, smoke list, in one self-contained message. Deploying, tagging, DNS changes and spend need the user's explicit yes — standing approval for a ticket does not cover them.
8. **Deploy the pinned SHA** (main session; provider credentials come from the environment's secrets or the user — `read_documentation` topic `environment.secrets` in a remote session — never from the repo). Take the pre-deploy restore point first.
9. **Smoke test on the real target** (not only locally): run the list, record outputs (`## Test info` convention from `product-ownership` where a ticket exists). A failed smoke test triggers the rollback decision immediately.
10. **After**: restate the recurring cost actually billed vs the estimate; confirm error reporting and logs are live; check the public-facing basics before launch — analytics/measurement in place, privacy policy and terms where personal data is collected (GDPR for EU users), cookie consent if tracking, an observation window and alert threshold after the deploy, and the store-submission path for a mobile app — then, if a public launch was asked for, hand to launch (`product-marketing-strategist`) — only now.

## Common mistakes
| Mistake | Fix |
|---|---|
| Deploying a branch name | Pin a SHA and verify against it |
| "CI is green" without checking which commit | Check the run's SHA |
| Smoke test only on localhost | Run it on the live URL |
| Secrets pasted into the PR or ticket | Reference the variable name only |
| Launching marketing before the deploy is verified | Launch last |

## Boundary
This is the gate and the checklist; infrastructure choices belong to `market-analyst` and `architecture-review`, and the user always owns go/no-go and spend.
