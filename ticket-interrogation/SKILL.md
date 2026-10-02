---
name: ticket-interrogation
description: Use when the user asks to interrogate, stress-test, pressure-test, poke holes in, sanity-check or "grill" a plan, design, approach or architecture, is about to start building something non-trivial while a direction is already chosen but its decisions are still open, or asks for help turning a rough idea into a well-specified ticket — not when the direction itself is still undecided, which is `brainstorming`
version: 1.4.1
model: opus
effort: high
---

# Ticket Interrogation

**Run on:** opus · effort high — interview and adversarial attack are judgment work that needs the user (AskUserQuestion), so it runs in the main session and is never delegated.

Two phases: interview, then attack. The interview collects decisions. The attack tries to break them. The output is a ticket.

**Pairs with:** `product-ownership` owns everything that happens to the ticket once its body exists (ticket type, labels, relationships, milestone, the confirm-before-create gate) — this skill only produces the body. `brainstorming` comes *before* when the idea itself isn't settled yet; `writing-plans` comes *after*, when an accepted ticket needs an implementation plan. `direct-execution` still decides whether the resulting work gets orchestrated or just done.

## When this applies
- A plan, design or approach exists in the user's head and needs pressure before code gets written
- A rough idea has to become a ticket someone (or Claude Code) can implement without guessing
- The user explicitly asks to have a plan interrogated, stress-tested or grilled

## NOT for
- Work already scoped by a confirmed ticket — that's `writing-plans` / direct execution, not another interview
- Deciding *what* to build next or in what order — that's the user's call (see `product-ownership`'s Boundary)
- A question with a factual answer. Look it up, don't interview about it

## Before anything: figure out the stack yourself

The project may be in any language or framework. **Never ask the user what the stack is** — read the repo (in a greenfield project with no code yet, read the confirmed stage 2-3 decisions in `docs/decisions.md` or the project docs instead). Look at dependency manifests, config files, directory layout, test setup, CI config, and a couple of recent commits.

Then phrase every subsequent question in that project's own vocabulary. If the project calls them "handlers", say handlers. If it calls them "resources", say resources. Generic framework-agnostic phrasing is a fallback, not the goal.

## Pick an intensity

Decide from context; only ask if it's genuinely unclear.

| Mode | When | Budget | Attack phase | Output |
|---|---|---|---|---|
| `light` | Bug fix, small change, well-understood area | Max 3 questions | Skipped | Short summary |
| `full` | New feature, architectural change, anything touching data or external contracts | 8–10 questions | Yes | Full ticket |

State which mode you picked in one line, then start.

**A mode can be raised, never silently.** If the user asks for more depth than the picked mode allows ("dig deeper", "ask me everything", "don't be superficial"), that is a request to switch to `full` — not a licence to overrun `light`'s budget under a `light` header. Say you are switching and why, then run `full` properly, attack phase included. **The budget does not reset**: questions already asked count toward the new mode's total, so a raise after two `light` questions leaves six to eight, not eight to ten. The same in reverse when the user cuts you short. What must never happen is a stated mode the run then contradicts.

## Phase 1 — Interview

Use **AskUserQuestion** for every question — never type a question into prose while the tool is available. Only if AskUserQuestion is genuinely unavailable in the current client, fall back to one numbered question per message, still one at a time and still with its options listed. That fallback is the single exception to the AskUserQuestion rule (the autopilot batch below is an exception to the one-at-a-time rule, not to the tool); it is not a matter of preference.

Ask in the language the user is writing in, not only the final output.

Rules:

- **One question per turn.** Wait for the answer before the next one.
- **2–4 concrete options per question**, drawn from what this project would realistically do. "Yes / No" is only acceptable when the question is genuinely binary. AskUserQuestion appends "Other" by itself — never spend one of the 2–4 slots on it, or a four-option question silently becomes a three-option one.
- **Explore before asking.** Before each question, check whether the repo already answers it: existing conventions, how a similar feature was built, dependency and config files, recent commits. Never ask what the code already says.
- **Acknowledge briefly** — one or two sentences max — then move to the next question.
- **Stop at the budget.** When the remaining decisions are cheap to reverse, stop asking: propose an explicit default and ask for confirmation instead of opening a new branch. What counts against the budget is a question that *opens* a decision; confirming a default you proposed closes one, so it doesn't count.

Walk the decision tree branch by branch, resolving dependencies between decisions in order. Don't jump between unrelated branches.

### Areas to cover

Not a checklist to run through mechanically — open the branches that actually apply, skip the rest.

- **Data and persistence** — does the schema change? Is the change reversible? Does it touch existing data? Is a backfill needed?
- **Code boundaries** — where does the new logic live relative to the layers already present? Extend something existing, or introduce a new module?
- **Sync vs async** — can the work be deferred? On failure: retry, dead letter, or nothing?
- **Authorization and access** — who can perform the action, and how is that enforced with the mechanisms already in use?
- **User interface**, if any — new component or modification? Where does state live? How are loading, error and empty states handled?
- **External contracts** — new interface or extension of an existing one? Breaking change for consumers?
- **Testing** — which levels are actually needed? What's the most likely edge case?
- **Deploy and configuration** — new environment variables or secrets? Atomic release or gradual rollout? How do we roll back?
- **Observability** — how would we notice this is broken after release?

## Phase 2 — Attack
(Light mode skips it, except under autopilot: there the attack runs on the proposed defaults even for a light slice, because nobody is interviewed to catch them.)

**Full mode only.** The interview is closed — no *new* decisions get opened here. Now actively try to break the plan you just helped build. Be direct — this is the half the interview cannot do, and the reason the skill exists.

Work through:

- Which assumption, if false, collapses the whole thing?
- What happens under load, with dirty data, under concurrency?
- What does this cost to maintain in six months?
- Is there a simpler approach that gets 80% of the value?
- How do we roll back if this is already in production and going wrong?

**Output: risks ordered by severity, each with a proposed mitigation.**

If a risk is severe enough to invalidate a decision made during the interview, reopen that one decision: name the risk that forces it, then ask it again as a normal AskUserQuestion (under autopilot, add it to the batched brief instead). That is the single exception to "the interview is closed", and it spends one question against the budget. Resolving it is the default. **provvisoria** is for a decision the user genuinely cannot settle now — it needs a fact nobody in the conversation has (a consumer outside this repo, a number from production, someone else's call) — not for one you'd rather not spend a question on. When it applies, don't stall the ticket: carry the decision into Phase 3 marked **provvisoria**, with the risk that makes it so listed under *Rischi noti*.

A mitigation the plan now depends on is a **decision**, and belongs in *Decisioni tecniche* as well as in *Rischi noti* — a reconciliation job the ticket cannot ship without is not a footnote. A mitigation that is only advice for later (rotate these credentials, watch this metric) stays in *Rischi noti* alone.

Don't manufacture risks to look thorough. Three real ones beat eight padded ones.

## Phase 3 — Output

The output shape follows the mode, not the other way round.

### `light` — short summary

No ticket template. Four lines, nothing else:

```markdown
**Titolo:** <imperative, one line>
**Problema:** <what is actually wrong or needed, root cause if you found it>
**Fix deciso:**
- <decision + reason>
**Da coprire nel test:** <the edge case that triggered this>
```

The title is there because `light` output goes one of two ways, and only the user's original ask decides which: if they asked for a ticket, `product-ownership` publishes this as a `bug` ticket, mapping *Problema* to the context and *Da coprire nel test* to an acceptance criterion; if they asked for the fix itself, this is the brief for the fix and no issue gets created. Never decide that for them by silently inventing a ticket, or by silently skipping one.

### `full` — ticket

A ready-to-paste ticket. The first line is the **title**: `product-ownership` publishes a title *and* a body, so a body alone stalls the handoff.

```markdown
# <title: imperative, one line, no issue number>

## Contesto
<why this is needed>

## Obiettivo
<what it must do>

## Decisioni tecniche
- <decision + reason>
- <decision left open by Phase 2 + reason> — **provvisoria**, vedi Rischi noti

## Fuori scope
- <what this ticket deliberately does not do — only what the interview actually ruled out>

## Dipendenze
- <only if the interview surfaced one: this ticket is blocked by / blocks / belongs under X>

## Rischi noti
- <risk + mitigation>

## Criteri di accettazione
- [ ] <verifiable>
```

Write the output in the language the user has been using in the conversation (the headings above are the Italian defaults this repo's issues use — translate them if the conversation is in another language). Keep every line traceable to something actually decided or surfaced — no invented requirements. **That binds *Fuori scope* exactly as much as the rest**: list only what the interview or the attack actually ruled out, not everything a reader might imagine. An exclusion nobody decided is an invented requirement wearing a negation.

These headings are this repo's default, not a contract: `product-ownership` may reshape them to match a repo whose issues are structured differently, as its own convention rule requires. What must survive that reshaping is the content, not the heading names.

Then invoke `product-ownership` to publish it. The output stops here: creating the issue on GitHub, choosing its labels and wiring its relationships is that skill's job, including its confirm-before-create gate — but handing the body over is *this* skill's last step, not someone else's problem.

## Under autopilot (`autonomous-workflow` stage 4)
Autopilot replaces many small questions with one decision brief per gate, so one-question-per-turn is relaxed here and only here:
- Anything derivable from the confirmed idea/stack/architecture/design decisions becomes a **proposed default** in the ticket; confirming a default does not count against the question budget.
- Only decisions that genuinely belong to the user go into the stage-4 brief, as **one batched set** (at most 4 questions in a single AskUserQuestion call), across all tickets of the batch rather than ticket by ticket.
- The attack phase still runs, on the defaults too; findings that change a default are listed in the brief.
- More than 4 genuine user decisions across the batch: ask the 4 that block the most tickets, park the rest in the brief with a proposed default marked `unconfirmed`, and let each affected ticket stay `blocked: needs decision` rather than guessing.
- If the user is unreachable, park the batch with the brief complete and move on to tickets that need no decision; never leave an interview half-finished mid-state.

## Common mistakes

| Mistake | Why it's wrong |
|---|---|
| Asking the user what the stack/framework is | It's in the repo. Read it — a question whose answer is in the code burns the budget for nothing |
| Framing questions in generic framework-neutral terms | The user has to translate them back to their project. Use the project's own nouns |
| Free-text questions ("what do you think about X?") | The whole point is 2–4 tappable options — that's what makes this usable from a phone |
| Batching three questions into one turn | Later questions depend on earlier answers; batching pre-empts the branch you should have taken |
| Running the full interview on a one-line bug fix | That's `light` mode. Three questions, no attack phase |
| Continuing past the budget because "one more decision is open" | Cheap-to-reverse decisions get an explicit proposed default and a confirmation, not a new branch |
| Skipping the attack phase because the plan looks fine | The interview *builds* the plan, so of course it looks fine. The attack is the part that wasn't asked for politely |
| Padding the risk list to look rigorous | Invented risks dilute the real ones and get the whole list ignored |
| Putting requirements in the ticket that nobody decided | Every line must trace to an answer or a surfaced risk |
| Handing over a ticket body with no title | `product-ownership` publishes both. A body alone stalls the handoff |
| Emitting the full ticket template in `light` mode | `light`'s output is the three-block summary. The template belongs to `full` |
| Running nine questions under a `light` header because the user pushed for depth | Raising the mode is allowed, doing it silently is not. Announce the switch, then run `full` properly |
| Spending one of the 2–4 option slots on "Other" | AskUserQuestion adds it for free — you just cut the real choices to three |
| Emitting the ticket and stopping | Handing it to `product-ownership` is this skill's last step, not the next session's |
| Filling *Fuori scope* with plausible exclusions nobody decided | Same rule as the rest of the ticket: an invented exclusion is an invented requirement |
| Marking a decision **provvisoria** to avoid spending a question on it | That marker is for what the user genuinely cannot answer yet, not for what you didn't ask |
| Restarting the budget after raising the mode | Questions already spent still count — a raise buys the difference, not a clean slate |

## Boundary

This produces a ticket body and a risk list. It does not create the issue, pick its labels, decide priority, or plan the implementation — those belong to `product-ownership` and `writing-plans`.
