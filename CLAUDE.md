# Global rules (all projects)

## Commands handed to the user
Any command the user is asked to run must use absolute paths, or explicitly state the directory (`cd /path && ...`) and the environment (host shell vs a specific Docker container) to run it in. Never hand over a bare relative path.

## Announce agent model/effort
Every time the Agent tool is used (any subagent_type — built-in or custom), state in visible text which model it runs on (its frontmatter `model:` field, or the `model` override passed to the call) and its effort/reasoning level if one applies (e.g. a `low`/`medium`/`high` review effort). Announce this at launch time, not only after the result comes back — a one-line note is enough (e.g. "Lancio `github-ops` (modello haiku).").

## Sudo and installing missing tools
Ask the user for the OK before any `sudo` or tool installation. Once the OK is given, try running the command yourself; hand it to the user for manual execution only when it genuinely cannot be run (needs an interactive password/tty, sandbox denial, missing permissions) — and say that's the reason.

## Manual verification: real data, standard ports, one environment at a time
When a ticket needs a manual browser/functional check before merge/push, verify it against the project's real, full dataset on its standard ports — never spin up an ad-hoc scratch environment (throwaway DB seeded with a handful of fixture records, alternate ports) to avoid disturbing a running stack.
- Do the implementation work in the ticket's isolated worktree (per "One git worktree per ticket" below), but never `git checkout` the ticket branch inside the primary checkout itself, even temporarily, to run it.
- To point the already-running stack at the worktree's code instead: swap only the code-serving layer (e.g. bind-mount paths, `docker compose` service source, symlink) over to the worktree while reusing the same database/volume/network/service the primary checkout normally uses, so real data stays intact and the app stays reachable on its usual host/port. Swap it back to the primary checkout when the check is done.
- If two tickets are in progress at once, don't run two parallel environments — verify one, get confirmation, then swap the same environment over to the other ticket and verify that one. Same port, same real data, one at a time.

## Manual verification: mock data when the real dataset can't cover the case
If the real dataset doesn't contain a case the user needs to see with their own eyes (a specific edge case, empty state, boundary condition, error state), don't skip the check, don't fake having verified it, and don't just describe what "should" happen — insert temporary mock/seed data into the running environment so the scenario is actually reproducible and clickable for the user's manual check.
- Make clear to the user that what they're looking at is temporary mock data inserted for this check, not real catalog data.
- Only delete the mock data after the user has given explicit approval of the check — deleting data is a hard-to-reverse action, so it follows the same confirm-first default as any other destructive operation, it doesn't get a standing exception just because the data is fake.
- Clean it up promptly once approved, so it doesn't linger and get mistaken for real data in later tests.

## One git worktree per ticket
When starting implementation work on a ticket/issue in any git repo, never work directly on the default branch of the primary checkout — use an isolated worktree:

- If the repo has its own worktree helper or convention (e.g. `.claude/scripts/worktree.sh` or a `worktree-manager` skill), use that.
- Otherwise apply this convention manually: branch `worktree-<issue>-<slug>`, worktree at `.claude/worktrees/<slug>` (ensure that directory is git-ignored in the committed `.gitignore`), locked via `git worktree lock --reason "issue #<n>"` so other sessions can see who owns it.
- Two sessions must never write to the same branch. A locked worktree belongs to another session — do not touch it; unlocking is the owner's explicit handoff step.
- After the branch merges: unlock and remove the worktree, delete the branch (local and remote), and clean up any orphaned worktree directories.
