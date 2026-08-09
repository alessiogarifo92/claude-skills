---
name: laravel-architecture
description: Use when writing or reviewing Laravel code - controllers, Form Requests, policies/gates, actions or services, jobs, events, Eloquent models, or API resources
version: 1.2.0
---

# Laravel Architecture

Design Laravel code for clarity, correctness, security, and maintainability.

**Pairs with:** security-review for a full threat-model pass on auth, uploads, or mass-assignment-sensitive endpoints.

## Ground the design in the running app, not the files
Laravel Boost is standard equipment in every Laravel project — if this repo doesn't have it yet, install it before going further, per CLAUDE.md's rule. Then use its MCP tools rather than reasoning from source alone. The files tell you what was written; Boost tells you what the app actually has.

- Registered routes, middleware, and their names — not what `routes/*.php` appears to declare after service providers, packages, and route caching have had their say.
- The real database schema and the applied migration state, rather than replaying the migration folder in your head.
- Installed package versions, so the pattern you recommend matches the Laravel and package majors in this app instead of the most common one on the internet.
- Boost's documentation search, version-matched to those packages, ahead of a generic web search.
- `tinker` to test an assumption about a model, relation, or query in the actual app before writing code around it.
- Application logs when diagnosing, instead of asking the user to paste them.

Without Boost, say which conclusions came from reading files and could be contradicted at runtime.

## Layering rules
- Controllers stay thin.
- Form Requests handle validation and authorization entry points.
- Policies and Gates handle access control.
- Actions or services hold application workflows.
- Eloquent models should not become god objects.
- Resources shape responses.
- Jobs encapsulate async work cleanly.

## Key checks
- mass assignment safety
- transaction boundaries
- N+1 risk
- authorization on protected routes
- secure file uploads
- safe rendering of untrusted content
- queue retry safety
- idempotency where needed

## Prefer
- explicit method names
- small controllers
- domain logic outside Blade and Vue templates
- explicit transactions for multi-step writes
- focused tests for actions, policies, and requests

## Output
- Recommended placement
- Risks
- Tests to add
- Refactor path if current layering is weak
