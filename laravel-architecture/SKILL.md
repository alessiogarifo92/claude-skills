---
name: laravel-architecture
description: Use when writing or reviewing Laravel code - controllers, Form Requests, policies/gates, actions or services, jobs, events, Eloquent models, or API resources
version: 1.0.0
---

# Laravel Architecture

Design Laravel code for clarity, correctness, security, and maintainability.

**Pairs with:** security-review for a full threat-model pass on auth, uploads, or mass-assignment-sensitive endpoints.

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
