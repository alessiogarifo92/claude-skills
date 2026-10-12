---
name: test-verification
description: Use when deciding what to run to verify a code change - choosing the narrowest meaningful set of tests, lint, type checks, or manual smoke checks for backend, frontend, database, or API changes - and before claiming any change is done, fixed, or passing
version: 1.6.0
---

# Test Verification

**Run on:** sonnet · effort medium — choosing checks; `test-runner` (haiku) runs them.

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
- migrations: migrate up/down plus affected data paths — a destructive reset/seed against a shared DB checks no other ticket is `in progress` first (global CLAUDE.md, "Never wipe shared DB data while another ticket is in progress")
- APIs: contract shape, status codes, validation errors
- performance-sensitive code: targeted benchmarks or query plans when relevant

## Browser checks
When the change has a browser-observable surface, drive a real browser with the `playwright` MCP server (`browser_navigate`, `browser_snapshot`, `browser_click`, `browser_fill_form`, `browser_console_messages`) instead of describing what the page should do. The accessibility snapshot and the console output are the evidence; a paragraph of expected behavior is not. Never hand over a check you haven't opened yourself first — a broken page discovered by the user is a wasted round trip.

- **Real data, standard ports, one environment at a time.** Verify against the project's real, full dataset on its standard ports — never spin up an ad-hoc scratch environment (a throwaway DB seeded with a handful of fixtures, alternate ports) to avoid disturbing a running stack. Do the implementation work in the ticket's isolated worktree, but never `git checkout` the ticket branch inside the primary checkout itself, even temporarily, to run it — instead swap the code-serving layer (bind-mount paths, `docker compose` service source, symlink) over to the worktree while reusing the same database/volume/network the primary checkout normally uses, so real data stays intact and the app stays reachable on its usual host/port.
  - For stacks with no swappable serving layer (Expo/React Native via Expo Go, or any dev server that serves source directly — `expo start`, `npm run dev`), "swap" means stopping the process bound to the standard port and restarting the same command from the worktree directory instead, reusing the same backend/DB env vars. The port and connection endpoint don't change, so a URL the user already has open keeps working.
  - Leave the swap in place through your own walkthrough **and** through the user's manual check that follows it — swap back to the primary checkout only once the user confirms the check is done (see `worktree-manager` / global CLAUDE.md for closing the ticket), never right after your own walkthrough finishes. Finishing your own pass is not "the check is done" — the user's confirmation is.
  - If two tickets are in progress at once, don't run two parallel environments — verify one, get confirmation, then swap the same environment over to the other and verify that one. Same port, same real data, one at a time.
- Read the console on every page you touch. A correct-looking render with a red console is not a pass.
- Know the limit. Playwright proves the page loads, the element exists, the action fires, the state changes, nothing errored. It cannot prove the result looks right, the copy reads well, or the data is plausible. Those belong to the user — they are the reason the handoff below exists, not a gap to paper over.

## Local verification is the push gate; CI is the second net
Every push (topic branch included) is preceded by the full local run of the same checks CI would run — tests with coverage, lint/format, typecheck, build, and the e2e/browser suite — with the output read in this session. A project carries one entry point for it (e.g. `npm run verify`, `make verify`) that the CI workflow also calls, so local and CI can never drift apart. Never push "to let CI tell me".

**Know the repo's visibility before relying on CI — every session, every repo.** Run `gh api repos/<owner>/<repo> --jq .private` (REST works through the remote-session proxy; `gh repo view` does not) at session start, or read the line the project's SessionStart hook prints, and again before the first push of a session. It decides the CI budget:
- `true` (private): GitHub Actions minutes are finite. Local `verify` is the push gate as always, and a CI job that never starts is most likely the quota or spending limit: go straight to the steps below instead of waiting on it.
- `false` (public): standard GitHub-hosted runners have unlimited minutes, so a job that does not start is not a minutes problem: investigate it as a real failure.
- Visibility can change (a repo made public to get free Pages or unlimited CI): re-check it rather than trusting an earlier answer, and keep the project `CLAUDE.md` "Repo visibility" line current.

**When GitHub Actions cannot run because the monthly minutes (or the spending limit) are used up** — the job fails before any step runs, with an annotation like *"The job was not started because recent account payments have failed or your spending limit needs to be increased"* / *"...account is locked due to a billing issue"*, or the run sits `queued` with a billing notice. That is not a code failure and not a flake:
1. Confirm it is billing: the annotation/run log names billing or minutes, and no test step started. Anything else stays a real CI failure.
2. Run the workflow's jobs locally, step for step — the same `verify` entry point, plus any extra job the workflow defines (the matrix entries that matter, the build of each package). Use `act` only if Docker is available; otherwise run the commands directly. Never edit, skip, or disable the workflow to make the red go away.
3. Record the evidence where reviewers look: one comment on the PR (or ticket, if no PR) naming the blocked check, the commands run locally, and their pass/fail counts and commit SHA. That comment replaces the missing CI evidence; without it the push does not happen.
4. Tell the user once that Actions is out of minutes and when the quota resets (start of the billing month), or that raising the spending limit is their call — never change billing yourself.
5. Merge to the default branch stays behind the manual user gate exactly as before; local evidence substitutes for CI, never for the user's check.
- **Why:** Daily-smile started as a private repo, where the free Actions quota is limited; the user asked that an exhausted quota never become either a blocker or an excuse to push untested — everything is still checked and tested before every push, just without spending GitHub minutes.

## Mobile + browser: verify both interfaces when a project ships both
When a project ships both a browser/web frontend and a mobile app (native or Expo/React Native) against the same backend, a ticket touching shared behavior (API, auth, shared business logic, shared UI components) is verified on **both** interfaces before handoff — not just whichever one the change happened to be written in. The two clients often reach the backend through different paths (web via same-origin fetch, mobile via an explicit base URL), so a change can pass on one and silently regress the other.

- At ticket pickup, check whether the project has both surfaces (a mobile client dir — Expo/React Native/Flutter/native — alongside the web frontend) so the dual check is planned into the handoff up front, not discovered after.
- Browser side: Playwright against `localhost`/its usual host, per "Browser checks" above.
- Mobile side: test against the LAN IP, not `localhost` — a physical device or emulator cannot reach the dev machine's `localhost`. Get the current LAN IP and confirm the mobile app's API base URL / dev server is actually reachable at `http://<lan-ip>:<port>` from the device — don't just assume it matches what works on `localhost`.
- Both must be confirmed working before the ticket is handed off as verified. If you can't drive the mobile client yourself (no device/emulator available), say so explicitly in "Not verified, and why" below, and add the mobile-over-LAN check as one of the user's manual steps rather than silently skipping it.
- **Why:** `localhost` vs. LAN is a distinct failure class — code that works over `localhost` in a browser can fail over LAN on mobile due to CORS, IP allow-lists, insecure-origin/HTTPS restrictions, or a hardcoded base URL, and neither a code review nor a browser-only Playwright pass catches that.

## Manual handoff — telling the user what to test
Your browser check does not replace the user's; it produces the checklist for it. Never hand over a vague "please have a look". Split the handoff into three parts:

1. **Verified automatically** — one line each so the user doesn't redo it: URL, action, observed result.
2. **Needs your eyes** — numbered steps runnable without reconstructing context: the absolute URL (host and port included), what to click or type, and an expected result concrete enough to be falsifiable. "The totals row reads 3 articoli — €45,00" is checkable; "the totals look right" is not.
3. **Not verified, and why** — anything out of reach: a state the real data doesn't contain, an external integration, a device or browser you can't drive. State it plainly rather than letting it pass in silence.

The environment must still be pointed at the ticket's code at the moment this handoff is given — restoring it to the primary checkout is a separate, later step (after the user confirms), never done between finishing your own walkthrough and handing off the checklist. A checklist handed off against an environment already reverted sends the user to look at the wrong code.

**Mock data for cases the real dataset can't cover.** If the real dataset doesn't contain a case the user needs to see (an edge case, empty state, boundary condition, error state), don't skip the check or just describe what "should" happen — insert temporary mock/seed data into the running environment so the scenario is actually reproducible and clickable. Do this proactively, before handing off, not after the user says they can't find anything to test. Default to at least 3 varied scenarios per handoff when state varies over time or across repeated periods, picking cases that exercise different branches of the acceptance criteria rather than three copies of the same case. Tell the user plainly which parts are temporary mock data, not real data. Only delete it after the user's explicit approval of the check (deletion is a destructive action, same confirm-first default as any other) — then clean it up promptly so it doesn't linger and get mistaken for real data later.

**Test credentials go in chat, never in a committed artifact.** Whenever a check uses or resets a test account's login, show the credentials (email/username + password) back to the user directly in the chat response — plainly, and per-account if more than one role is relevant (admin vs. member, etc.). Never write the password, or an email meant to stay private, into test files, commit messages, PR descriptions, screenshots that get committed, or any other artifact that persists — chat-only.

## Output
- What was checked
- What passed
- What remains unverified
- Why the chosen verification is sufficient

## Boundary
This picks the checks and enforces evidence before "done". It does not authorize a merge or push — that's `product-ownership`'s manual user gate — and it does not decide the test/code authoring order, which is `test-driven-development`'s.
