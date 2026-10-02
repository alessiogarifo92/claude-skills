# claude-skills

Private skills, agents and global rules for Claude Code. Goal: run a project from idea to deploy and launch with the right skill, agent and model at every step, parallel agents that check each other, and hard gates only where a human decision is needed.

## Where to start

| You want to… | Invoke |
|---|---|
| Build a whole app / run a backlog end to end, even unattended | `autonomous-workflow` (enters `project-lifecycle` for a new project) |
| Work one ticket | `product-ownership` |
| Decide something high-stakes with independent agents compared against each other | `cross-verification` |
| Ship to production | `deploy-readiness` |
| Fix a linear task fast | nothing — `direct-execution` is the default |

## Layout

- `CLAUDE.md` — global rules, loaded in every session.
- `<skill>/SKILL.md` — one skill per folder (frontmatter: name, description = trigger, semver version; body starts with a `Run on` line).
- `agents/*.md` — subagents (frontmatter: model, effort, tools, preloaded skills).
- `templates/project-CLAUDE-bootstrap.md` — section every project's `CLAUDE.md` must carry so remote sessions attach this repo.
- `scripts/validate.py` — consistency check (CI runs it); `scripts/install.sh` — link into `~/.claude`.
- `CHANGELOG.md` — one line per skill change, same commit as the change.

## Setup

- Local: `scripts/install.sh` (symlinks skills, agents, `CLAUDE.md` into `~/.claude`; never overwrites real files). `settings.json` is merged by hand.
- Remote session: paste `templates/project-CLAUDE-bootstrap.md` into the project's `CLAUDE.md`.

## How the workflow runs

1. `autonomous-workflow` holds the stage map: idea → tools & cost → architecture → design → tickets → implementation → verification → review → manual gate/merge → deploy → launch → close, with the owner skill, agents, models and gate type per stage.
2. Linear work stays direct. Independent work (research per tool, unblocked tickets, panelists) is dispatched in parallel, in one message.
3. High-stakes work goes through `cross-verification`: blind parallel agents (mixed models) → a `critic` compares them on evidence → the orchestrator decides; user-owned decisions go to the user with a recommendation. Caps: 3 panelists, 2 rounds.
4. Every agent report is a claim: the orchestrator verifies it (`orchestrating-agents`) before the next phase; gating claims are re-derived blind by `verifier`.
5. Hard gates that autonomy never skips: user decisions (idea, stack, architecture, design), spend, anything published/sent, push/merge before the manual check, deploy, destructive operations.

## Models and effort

Policy: **opus** where judgment is expensive and no test catches the error (architecture, review, security, critique, positioning); **sonnet** for bounded code, research and verification work; **haiku** for mechanical run/locate/git work. The main session decides and owns git. Escalate a sonnet agent to opus when its task turns out to be a judgment call or a second attempt failed. `Run on` for a skill is advisory: skills execute on the session's model, so it tells you what to select (or which agent runs the work); only an agent's `model:`/`effort:` frontmatter is applied (the docs say the available effort levels depend on the model and do not say what happens for an unsupported one, so treat `effort` as best effort, notably on the haiku agents), and a dispatch can override the model but not the effort. The table is generated from the files (`python3 scripts/validate.py --write-readme`); the `Run on` line in each skill is the source for skills, frontmatter for agents.

<!-- matrix:begin -->
| Skill | Version | Run on | Effort |
|---|---|---|---|
| `api-design` | 1.0.1 | sonnet | high |
| `architecture-review` | 1.0.1 | opus | high |
| `autonomous-workflow` | 1.0.0 | opus | high |
| `brainstorming` | 1.0.1 | opus | high |
| `brand-strategist` | 1.0.1 | opus | medium |
| `cross-verification` | 1.0.0 | opus | high |
| `database-design` | 1.1.1 | opus | high |
| `debugging-workflow` | 1.0.3 | sonnet | high |
| `deploy-readiness` | 1.0.0 | opus | high |
| `direct-execution` | 1.3.0 | main | medium |
| `docs-and-specs` | 1.0.1 | sonnet | medium |
| `executing-plans` | 1.0.1 | sonnet | medium |
| `finishing-a-development-branch` | 1.2.0 | sonnet | low |
| `go-backend` | 1.0.1 | sonnet | high |
| `handling-sudo-and-missing-tools` | 1.0.1 | haiku | low |
| `laravel-architecture` | 1.3.1 | sonnet | high |
| `market-analyst` | 1.0.1 | sonnet | medium |
| `multi-agent-brainstorm` | 1.2.0 | opus | high |
| `orchestrating-agents` | 2.0.1 | opus | high |
| `principal-engineering-core` | 1.1.1 | opus | high |
| `product-marketing-strategist` | 1.0.1 | opus | medium |
| `product-ownership` | 1.18.0 | sonnet | medium |
| `project-lifecycle` | 1.7.0 | opus | high |
| `python-backend` | 1.0.1 | sonnet | high |
| `receiving-code-review` | 1.0.1 | opus | medium |
| `refactoring-strategy` | 1.0.1 | sonnet | high |
| `requesting-code-review` | 1.1.0 | opus | high |
| `security-review` | 1.0.1 | opus | high |
| `sql-performance` | 1.0.1 | sonnet | high |
| `subagent-driven-development` | 1.1.0 | opus | medium |
| `test-driven-development` | 1.0.1 | sonnet | medium |
| `test-verification` | 1.4.1 | sonnet | medium |
| `vue-frontend` | 1.0.1 | sonnet | high |
| `worktree-manager` | 1.5.2 | haiku | low |
| `writing-plans` | 1.0.1 | opus | high |
| `writing-skills` | 1.3.0 | opus | medium |

| Agent | Model | Effort | Preloaded skills | Role |
|---|---|---|---|---|
| `Explore` | haiku | low | — | Read-only search agent for broad fan-out searches |
| `architect` | opus | high | `principal-engineering-core`, `architecture-review` | Read-only design agent |
| `critic` | opus | high | — | Adversarial critic |
| `github-ops` | haiku | low | — | Runs mechanical git/GitHub operations |
| `implementer` | sonnet | high | `test-driven-development`, `test-verification` | Implements one clearly scoped feature or code change with tests |
| `marketing-strategist` | opus | medium | `product-marketing-strategist`, `brand-strategist` | Drafts and critiques positioning, landing/home copy, launch plans, release notes and SEO titles/meta for a pro |
| `quick-debugger` | sonnet | high | `debugging-workflow` | Finds and fixes a localized bug with a clear symptom |
| `refactor-optimizer` | sonnet | medium | `refactoring-strategy` | Simplifies working code without changing behavior |
| `release-auditor` | sonnet | high | `security-review` | Read-only pre-deploy auditor |
| `researcher` | sonnet | medium | — | Research agent for gathering facts from documentation, web sources, and the codebase |
| `reviewer` | opus | high | — | Read-only code reviewer |
| `security-auditor` | opus | high | `security-review` | Read-only security reviewer |
| `test-runner` | haiku | low | — | Runs a test suite, linter, or type check and reports only the outcome |
| `verifier` | sonnet | medium | `test-verification` | Independent verifier |
<!-- matrix:end -->

## Changing things

Read `writing-skills`. Short version: edit, bump the version, add the CHANGELOG line, regenerate the matrix, run `python3 scripts/validate.py`.
