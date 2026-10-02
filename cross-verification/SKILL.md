---
name: cross-verification
description: Use when a decision or result is high-stakes or hard to reverse — an idea direction, stack, architecture, security-sensitive or data-migrating change, a non-trivial diff before merge, marketing copy or a launch, a deploy — (including a choice between two named options) and one agent's answer is not enough, so independent agents must work in parallel and be compared against each other before the result is accepted
version: 1.1.4
model: opus
effort: high
---

# Cross-Verification

**Run on:** opus · effort high — the orchestrator is the main session; panelists per the model column below.

Independent agents work the same question in parallel, then a critic compares their outputs and the orchestrator decides on evidence. The point is not "more agents": it is catching what a single line of reasoning cannot see about itself — a shared wrong premise, an unexamined alternative, a claim nobody re-ran.

**Pairs with:** `orchestrating-agents` (dispatch brief, report contract, verification gate — all apply to every panelist), `direct-execution` (the default; this skill is the exception for stakes), `autonomous-workflow` (which stages call which mode), `multi-agent-brainstorm` (Mode A for ideas), `requesting-code-review` (Mode C for diffs), `deploy-readiness` (Mode D for releases).

## When this applies
Use the stakes ladder — never "to be safe" on linear work:

| Level | Examples | Treatment |
|---|---|---|
| 0 trivial, easy to undo | rename, typo, one-line fix, test addition | none — `direct-execution` |
| 1 normal ticket | scoped feature or bug with tests | verification gate only: one narrowest re-run (via `test-runner`) and a single `reviewer`; no `verifier`, no panel |
| 2 non-trivial or costly to reverse | multi-file change, new dependency, UI direction, copy for a public page | diffs: `reviewer` + the one relevant lens; other results: one independent check (`critic` or a blind second run) |
| 3 high-stakes | architecture and stack choice, auth/payments/PII, data migration, public API, deploy, public launch, anything that spends money | full panel, below |

NOT for: linear tasks whose steps depend on each other; questions with one verifiable answer (look it up); anything the user already decided.

## Modes
Pick the mode by what is being decided. Every mode follows the same skeleton: **blind parallel → critique → decide on evidence**.

| Mode | Use for | Panel (one message, parallel `Agent` calls) | Model mix |
|---|---|---|---|
| A. Competing proposals | idea shape, stack, architecture, UI direction, naming, plan | 2-3 proposers with the **identical** brief but different lens or model: `architect`, `researcher` (cost/tooling, via `market-analyst`), `general-purpose` (UI/UX), `marketing-strategist` for positioning → then `critic` over all outputs | different lens **or** model per panelist, ideally both an opus and a sonnet, so errors correlate less (pass `model:` explicitly — `general-purpose` inherits the session model) |
| B. Blind re-derivation | a result that gates the next phase: root cause, test counts, research claim, benchmark | the author's agent + `verifier` who is given the **claim and the check, not the author's reasoning** | sonnet + sonnet (verifier reproduces, does not review) |
| C. Review panel | an L3 diff before merge (L2: `reviewer` + one lens, no panel) | `reviewer` (correctness) ‖ `security-auditor` (if a trust boundary is touched) ‖ `architect` (if structure moves) → `critic` dedupes, ranks, drops what has no failure scenario | opus panel |
| D. Release gate | deploy, public launch | `release-auditor` ‖ `security-auditor` ‖ `verifier` replaying CI/staging checks (the live smoke test follows the deploy) → `critic` on go/no-go | sonnet + opus |
| E. Dual implementation | rare: an algorithm or migration where being wrong is expensive and a spec can be tested differentially | two `implementer` agents, each in its own worktree (`isolation: worktree` is the sanctioned exception to `worktree.sh` here, since both trees are throwaway), same spec, no sight of each other → run the same tests and a differential/property test on both → keep one or merge by test evidence | sonnet ×2 |
| F. Copy red-team | landing page, launch post, release notes | `marketing-strategist` ×2 variants with different theses → `critic` reads as the target reader and as a skeptic | opus |

## Procedure
1. **Write one problem statement and the scoring criteria before dispatch** (what "better" means: cost, risk, reversibility, fit with confirmed decisions). Criteria written after seeing the outputs get bent to the favourite.
2. **Dispatch blind and in parallel**: a single message with all `Agent` calls; panelists never see each other's output in round 1. Announce each model and effort at launch per the global rule. Use `run_in_background` when the orchestrator has other independent work.
3. **Gate each report individually** (`orchestrating-agents` verification gate). A panelist with STATUS ≠ done is resolved or replaced, not averaged in.
4. **Critique round**: hand all round-1 outputs to a `critic` (or, for Mode B, compare directly). Ask for agreements, disagreements with evidence, and the strongest case for the option least favoured.
5. **Decide on evidence, not votes.**
   - Agreement of independent agents is a signal, not proof: check they did not share a wrong premise from the brief.
   - A disagreement is resolved by going to the source — run the test, open the file, fetch the doc — never by majority or by who sounds surer. If it cannot be resolved cheaply, run a time-boxed spike (`product-ownership` spike) or put the trade-off to the user.
   - Decisions that belong to the user (idea direction, stack, architecture, design direction, spend) go to the user with the panel's comparison and one recommendation — the panel informs, it does not decide.
6. **One more round only if the critique found something fatal.** Hard cap: 2 rounds, 3 panelists per round. Non-convergence after that is an escalation to the user, not a third round.
7. **Record the outcome** where the next phase can reach it (ticket comment or project docs): options considered, the deciding evidence, the rejected objections and why. This is what stops phase N+1 from re-litigating.

## Cost control
- Total concurrency is capped by `autonomous-workflow`'s global limits (4 agents at once).
- Panelists are read-only except Mode E; parallel runs cost tokens, not risk — but stakes decide whether they are worth it, per the ladder.
- Give panelists the minimum context (problem statement + the files that matter), not the whole conversation: independence and cost both depend on it.
- Prefer one `critic` over N pairwise critiques.

## Red flags
| Thought | Reality |
|---|---|
| "Three agents agreed, so it's right" | If they got the same brief and the same blind spot, you ran one opinion three times. Vary lens and model; check the premise. |
| "Let me show agent 2 what agent 1 said" | Round 1 is blind; sharing collapses independence. Sharing is the critic's job in round 4. |
| "Panel everything to be safe" | Level 0-1 work gets none; `direct-execution` is the default. |
| "The opus agent disagreed, so it wins" | Evidence wins. A model rank is not evidence. |
| "Average the proposals" | A blend nobody argued for is the likeliest to be wrong. Pick, or ask the user. |
| "Another round, they still differ" | Cap is 2. Escalate with the comparison. |

## Boundary
This compares and verifies; it never decides what belongs to the user, never replaces the manual user gate before merge/push, and never lets an agent touch git (`orchestrating-agents`). Which stage calls which mode is `autonomous-workflow`'s table.
