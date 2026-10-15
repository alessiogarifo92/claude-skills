---
name: test-verification
description: Use when deciding what to run to verify a code change - choosing the narrowest meaningful set of tests, lint, type checks, or manual smoke checks for backend, frontend, mobile app, database, or API changes - and before claiming any change is done, fixed, or passing
version: 1.10.0
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

## Unit layer: mandatory on every implementation ticket
Playwright and the manual handoff prove the feature works end to end on a real stack; they do not substitute for unit tests. Every implementation ticket — feature, bug fix, or behavior-changing refactor — ships unit tests for the changed logic before it is done. (Moved here from the global CLAUDE.md, which keeps a one-line pointer.)
- Cover error paths and edge cases (invalid input, failure/exception branches, boundaries, empty/null), not only the happy path a walkthrough already exercises. "The page loaded and nothing errored" is not unit evidence.
- This governs *coverage*, not write order — `test-driven-development` decides that.
- If the project has (or is getting) a CI pipeline that tracks coverage, wire the new tests into it so they show up in its report; don't bolt a coverage tool onto a project that has none unless the user asks.
- **Why:** a green walkthrough only proves the wiring on the scenario walked; unit tests keep re-verifying the logic on every later change and surface regressions in CI before anyone clicks through the UI again.

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
- frontend UI: render, interaction, loading/error states, responsive behavior, then the design quality pass below
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

## Design quality pass (tickets that change UI)
Playwright proves the UI works; this pass catches what makes it look generated or feel cheap, before the user spends a manual check on it. Run it after the browser walkthrough, against the running page and the changed files, in **one bounded round**: collect findings, fix them in one batch, re-check once, stop. Open-ended self-polish burns budget and is the user's gate anyway.

| Run | When | What it catches |
|---|---|---|
| `/impeccable audit <target>` (+ `critique` on a new screen) | every UI-changing ticket | its deterministic detector (no LLM, 59 rules: Inter everywhere, purple gradients, cards in cards, gray-on-color text, icon tile above every heading) plus a11y, contrast, responsive; drift from the project's `DESIGN.md` |
| `break-ui` | a new list, card, table, form or profile | worst-case data: long names, unbreakable emails, zero/huge counts, missing fields, non-Latin text — what real data does to it |
| `review-animations` (`emil-design-eng` rules; it is user-invocable only, so Read `~/.claude/skills/review-animations/SKILL.md` and follow it) | the diff adds or changes motion | `transition: all`, durations over ~300 ms, `ease-in` on entering UI, scale from 0, animated keyboard actions, no `prefers-reduced-motion` |
| `mobile-native` | the web UI is used on phones | 100vh bug, inputs zooming the page, sticky hover, tap highlight, content under the notch |
| `animate-expo` | Expo / React Native motion | JS-thread animations, gesture hand-off, haptics |

- Fix what the pass finds inside the ticket's scope; anything wider (a token change, a redesign) goes back to the user as a proposal, never silently into this ticket — `DESIGN.md` was a phase-3.5 decision.
- List what was run and what was fixed in the `## Test info` comment, so the user's check starts from a cleaner page and knows what was already looked at.
- If the skills are missing (`ls ~/.claude/skills/impeccable`), run `scripts/install-design-skills.sh` from the skills clone; if it cannot fetch (offline), say so in the handoff and skip the pass visibly — never report it as run.

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

## Mobile UI automation: Maestro is the mobile Playwright
For a native mobile client (Expo/React Native, Flutter, native, or a web app wrapped with Capacitor), the automated UI check is a **Maestro** flow; a PWA is a web app and is covered by the next section instead. Maestro flows are YAML, one set for Android and iOS — the counterpart of the Playwright pass above, with the same evidence rule: a flow you ran and its screenshots, not a description of what the screen should do. For an app with no web frontend, "both interfaces" in the section above means Android and iOS.
- **Driving it from the session:** the MCP server ships in the Maestro CLI (`maestro mcp`; register it with `claude mcp add maestro -- maestro mcp`, local scope only — never in a committed `.mcp.json`, per the global `.mcp.json` rule: a stdio server that needs an emulator cannot start in a cloud container). It lists devices, inspects the screen, runs flows and takes screenshots. Missing CLI → `handling-sudo-and-missing-tools` before installing.
- **What it runs on:** Android emulator (needs KVM) or Android device; iOS **simulator** only (needs macOS and a simulator build — `.app`, e.g. an EAS build with `ios.simulator: true`). Physical iPhones and App Store/TestFlight `.ipa` builds are not supported, so build a simulator build of the same SHA for the flows and keep TestFlight for the human real-device pass.
- **Checks that cannot run where you are:** a remote/cloud session has no `/dev/kvm` and no macOS, so the flows run in CI — Android on a Linux runner with an emulator, iOS on a macOS runner — or on Maestro Cloud (paid). This is the one named exception to "Local verification is the push gate": everything that *can* run locally still runs before the push; the flows that cannot are listed under "Not verified, and why" with where and when they will run, and their CI result is read before the manual gate, never assumed.
- **Coverage, honestly:** unit tests cover the logic (global unit-test rule); for UI, cover the critical flows (login, the core task, payment/permissions) on both platforms, not every screen.
- **CI budget:** macOS runners on a private repo burn the included minutes about 10x faster than Linux (as of 2026-10); on a public repo standard runners are free. Run iOS flows on the release branch or nightly rather than every push on a private repo, and check visibility first (section above). The real-device pass before a store release belongs to `deploy-readiness` 2c.

## Installable web apps (PWA): Android and iOS, always
Any site that can be installed as a PWA (it has a web manifest and a service worker) must work on **both Android (Chrome) and iOS (Safari)**, installed and in the browser — by default, without the user asking. A ticket that touches the manifest, the service worker, install, offline, storage, push or the app shell is not verified until both platforms are covered. `product-ownership` raises this at pickup so it shapes the build, not only the verification. If the user explicitly drops one platform for a ticket, that is their call: record it under "Not verified, and why", and don't drop it on later tickets.
- **Build it for both, not only for Chrome:**
  - Manifest: `id`, `name`, `short_name`, `start_url`, `scope`, `display: standalone`, `theme_color`/`background_color`, icons 192 and 512 plus a `maskable` one for Android; also `<link rel="apple-touch-icon">` (180×180) for iOS.
  - Install: iOS has no `beforeinstallprompt`, so an install button that relies on it shows nothing there. Show iOS users a short "Add to Home Screen" hint (from the browser's share menu; since iOS 16.4 not only Safari) instead, and hide it when already installed (`display-mode: standalone`).
  - Storage and login: on iOS an installed PWA does not share cookies/storage with Safari, so a user logged in in Safari is logged out in the installed app — the login flow must work inside the installed app. Safari may evict the data of a site opened in the browser and not used for a while: never keep the only copy of user data in `localStorage`/IndexedDB.
  - Push: on iOS web push works only for an app added to the Home Screen (iOS 16.4+) and the permission must be asked from a user tap; feature-detect it and explain the install step instead of failing silently. Background Sync and similar APIs are missing on iOS: feature-detect and degrade.
  - Service worker updates: a new deploy must reach installed users — a versioned cache plus an update path (prompt or reload), checked by deploying twice.
  - Layout: `viewport-fit=cover` with `env(safe-area-inset-*)` for the notch and home indicator in standalone mode; run `mobile-native` from the design pass.
- **Verify on both — and know what Playwright cannot see:** Chromium with an Android device profile for the manifest, service worker and offline (`context.setOffline`) — Playwright's service-worker support is Chromium-only; WebKit with an iPhone profile for layout and the iOS install hint (WebKit needs `playwright install webkit` plus system packages: the install gate applies). Playwright cannot install the app, cannot emulate `display-mode: standalone`, and cannot show a real push notification: check the push subscription is created and saved and unit-test the service worker's push handler, but installability, standalone mode and push delivery always go to the real-device list. That list is in every handoff: install on an Android phone and on an iPhone, open from the icon, log in, go offline, receive a push if the app uses push. If no real iPhone check happened, it goes under "Not verified, and why" — never folded into "verified".
- **Why:** the user wants every installable site to work on Android and Apple alike without having to ask for it each time; the iOS differences (no install prompt, separate storage, push only once installed) are exactly what a Chrome-only check misses.

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
