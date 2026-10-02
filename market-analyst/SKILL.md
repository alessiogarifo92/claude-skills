---
name: market-analyst
description: Use when choosing or adding a third-party tool, API, SaaS, library, font, dataset, model, or other external asset to a project, when estimating recurring or usage-based costs of a stack, or when auditing existing dependencies for license compatibility, copyright obligations, and unwanted costs, or choosing a database, hosting or other infrastructure service by cost
version: 1.0.2
---

# Market Analyst

**Run on:** sonnet · effort medium — research synthesis (via `researcher`); opus for a final stack recommendation.

Own the market level of the project: every tool, API, SaaS, library, or asset that enters the stack is a purchase decision — even when it's free. This skill runs due diligence on two axes before the choice hardens into a ticket: what it will actually cost, and what its license or terms actually allow. The goal is no surprise invoices and no legal exposure discovered after shipping.

## Principles
- Verify pricing from the official source at decision time — never from memory or training data. Prices, tiers, and free-tier limits change; the `researcher` agent fetches the current pricing page and ToS.
- Read the free tier's fine print: is a card required, does it auto-upgrade when the quota is exceeded, or does it hard-stop? Quantify the quota against the project's realistic volumes.
- Estimate usage-based costs at today's volume *and* at 10x. A per-request price that is negligible in dev can dominate the budget in production.
- Every dependency has a license — identify it by SPDX id, don't guess from the README. Copyleft (GPL, AGPL, SSPL) vs permissive (MIT, Apache-2.0, BSD) determines what the project may do; flag any copyleft entering a proprietary or commercially distributed codebase as a decision, not a default.
- Assets are dependencies too: fonts, icons, images, audio, datasets, and model weights all carry licenses, attribution obligations, or usage restrictions (e.g. non-commercial clauses).
- API terms of service matter as much as the license: data retention, prohibition of resale or scraping, rate limits, and termination clauses can kill a use case that the pricing page allows.
- Compare before committing: 2–3 candidate options with cost estimate, license, and a verdict each. Name the lock-in risk (proprietary formats, egress fees, no export path) explicitly.
- This is risk analysis, not legal advice. For high-stakes calls (redistribution of copyleft code, trademark questions, regulated data) the output is a flag recommending professional legal review, not a green light.

## Check
- Every new dependency or asset in the change has a known SPDX license compatible with the project's license and intended use (commercial or not)
- Recurring and usage-based costs are estimated with stated volume assumptions, at current scale and 10x
- Free-tier limits and the overrun behavior (auto-billing vs hard stop) are documented
- Attribution and notice obligations (NOTICE files, credits, watermarks) are tracked, not silently dropped
- Billing alerts or spend caps exist for any pay-per-use API before its key reaches production
- No copyleft license enters distributed code without an explicit recorded decision

## Output
- Comparison table of candidate options: estimated cost (with volume assumptions), license/ToS verdict, lock-in risk, recommendation
- Risk flags: unwanted-cost traps, license incompatibilities, attribution obligations, clauses needing legal review
- A verdict quotable in the ticket that adopts the dependency (see product-ownership phases 1–2)

## Boundary
Naming, identity, and voice belong to brand-strategist; messaging and launch belong to product-marketing-strategist. Vulnerabilities and supply-chain risk of a dependency belong to security-review — this skill decides whether adopting it is affordable and lawful, not whether it is safe.
