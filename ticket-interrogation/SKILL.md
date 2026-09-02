---
name: ticket-interrogation
description: Use when the user asks to interrogate, stress-test, pressure-test, poke holes in, sanity-check or "grill" a plan, design, approach or architecture, is about to start building something non-trivial while a direction is already chosen but its decisions are still open, or asks for help turning a rough idea into a well-specified ticket — not when the direction itself is still undecided, which is `brainstorming`
version: 1.1.0
---

# Ticket Interrogation

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

The project may be in any language or framework. **Never ask the user what the stack is** — read the repo. Look at dependency manifests, config files, directory layout, test setup, CI config, and a couple of recent commits.

Then phrase every subsequent question in that project's own vocabulary. If the project calls them "handlers", say handlers. If it calls them "resources", say resources. Generic framework-agnostic phrasing is a fallback, not the goal.

## Pick an intensity

Decide from context; only ask if it's genuinely unclear.

| Mode | When | Budget | Attack phase | Output |
|---|---|---|---|---|
| `light` | Bug fix, small change, well-understood area | Max 3 questions | Skipped | Short summary |
| `full` | New feature, architectural change, anything touching data or external contracts | 8–10 questions | Yes | Full ticket |

State which mode you picked in one line, then start.

**A mode can be raised, never silently.** If the user asks for more depth than the picked mode allows ("dig deeper", "ask me everything", "don't be superficial"), that is a request to switch to `full` — not a licence to overrun `light`'s budget under a `light` header. Say you are switching and why, then run `full` properly, attack phase included. The same in reverse when the user cuts you short. What must never happen is a stated mode the run then contradicts.

## Phase 1 — Interview

Use **AskUserQuestion** for every question. Never pose questions as plain text. If AskUserQuestion is unavailable in the current client, fall back to one numbered question per message — still one at a time, still with the options listed.

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

**Full mode only.** The interview is closed — no *new* decisions get opened here. Now actively try to break the plan you just helped build. Be direct — this is the half the interview cannot do, and the reason the skill exists.

Work through:

- Which assumption, if false, collapses the whole thing?
- What happens under load, with dirty data, under concurrency?
- What does this cost to maintain in six months?
- Is there a simpler approach that gets 80% of the value?
- How do we roll back if this is already in production and going wrong?

**Output: risks ordered by severity, each with a proposed mitigation.**

If a risk is severe enough to invalidate a decision made during the interview, reopen that one decision: name the risk that forces it, then ask it again as a normal AskUserQuestion. That is the single exception to "the interview is closed", and it spends one question against the budget. If it can't be resolved here, don't stall the ticket — carry the decision into Phase 3 marked **provvisoria**, with the risk that makes it so listed under *Rischi noti*.

Don't manufacture risks to look thorough. Three real ones beat eight padded ones.

## Phase 3 — Output

The output shape follows the mode, not the other way round.

### `light` — short summary

No ticket template. Three blocks, nothing else:

```markdown
**Problema:** <what is actually wrong or needed, root cause if you found it>
**Fix deciso:**
- <decision + reason>
**Da coprire nel test:** <the edge case that triggered this>
```

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
- <what this ticket deliberately does not do>

## Rischi noti
- <risk + mitigation>

## Criteri di accettazione
- [ ] <verifiable>
```

Write the output in the language the user has been using in the conversation (the headings above are the Italian defaults this repo's issues use — translate them if the conversation is in another language). Keep every line traceable to something actually decided or surfaced — no invented requirements.

The output stops here: creating the issue on GitHub, choosing its labels and wiring its relationships is `product-ownership`'s job, including its confirm-before-create gate.

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

## Boundary

This produces a ticket body and a risk list. It does not create the issue, pick its labels, decide priority, or plan the implementation — those belong to `product-ownership` and `writing-plans`.
