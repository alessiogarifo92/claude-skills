---
name: laravel-architecture
description: Use when writing or reviewing Laravel code - controllers, Form Requests, policies/gates, actions or services, jobs, events, Eloquent models, or API resources
version: 1.3.0
---

# Laravel Architecture

Design Laravel code for clarity, correctness, security, and maintainability.

**Pairs with:** security-review for a full threat-model pass on auth, uploads, or mass-assignment-sensitive endpoints.

## Ground the design in the running app, not the files
Laravel Boost is standard equipment in every Laravel project — one just scaffolded, or an existing one being touched for the first time. It's the difference between reasoning about the app from its source files and interrogating the app that is actually running: registered routes, real schema, installed package versions, logs, tinker, plus documentation matched to those versions instead of the most common answer on the internet.

- **Check, then install.** On the first substantive work in a Laravel repo, check whether `laravel/boost` is in `composer.json`. If it isn't: `composer require laravel/boost --dev`, then `php artisan boost:install`. It's a dev dependency and never ships to production.
- **Announce it, keep it separate.** Adding a dependency to someone's repo is a change in its own right — say you're doing it, and give it its own commit rather than folding it silently into a ticket's diff.
- **`boost:install` is interactive** — it asks which agents and features to set up. If it can't be driven from here, hand it to the user to run with the `!` prefix instead of guessing at undocumented `--no-interaction` behavior. Claude Code registration is normally automatic; the documented fallback is `claude mcp add -s local -t stdio laravel-boost php artisan boost:mcp`.
- **It generates a project-root `CLAUDE.md`.** Boost writes guideline files (`CLAUDE.md`, `AGENTS.md`, …) and regenerates them on every later `boost:install`/`boost:update`. If the project already has its own `CLAUDE.md`, read and preserve it first — losing a project's own instructions to a regenerated file is a real regression. This is the project root file, not `~/.claude/CLAUDE.md`.
- **What's committed differs by file.** `.mcp.json`, the generated guideline files, and `boost.json` are regenerated on demand and may be gitignored. `.ai/rules/` is the opposite — it's the team's shared project rules and belongs in version control.
- **Record project rules through the tool, never by hand.** Use Boost's `record-rule` MCP tool: it files the rule under the right glob and regenerates `.ai/rules/index.md`, which is how agents discover it. A rule file written by hand stays invisible until that index is next rebuilt.
- **Existing codebase:** after installing, offer the `infer-conventions` skill to bootstrap `.ai/rules` from what the code already does. It presents each convention with its evidence for approval before writing anything — don't let it record unreviewed.
- **Keep it from drifting:** add `@php artisan boost:update --ansi` to the project's Composer `post-update-cmd` scripts, so guidelines and skills track the installed package versions instead of aging in place.

Then use Boost's MCP tools rather than reasoning from source alone once it's installed. The files tell you what was written; Boost tells you what the app actually has.

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
