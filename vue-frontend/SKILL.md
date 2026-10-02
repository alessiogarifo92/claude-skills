---
name: vue-frontend
description: Use when writing or reviewing Vue components - composables, state ownership, props/emits design, accessibility, or loading/empty/error UI states
version: 1.0.1
---

# Vue Frontend

**Run on:** sonnet · effort high — writing and reviewing code.

Design Vue code for maintainability, predictable state, and good UX.

**Pairs with:** security-review for auth-sensitive UI flows or anywhere raw HTML is rendered.

## Core rules
- Components should have one clear responsibility.
- Reusable behavior goes in composables when repetition is real.
- Business logic stays out of templates.
- Props and emits should be explicit.
- State ownership must be clear.
- Avoid duplicated sources of truth.

## UX quality
- Design loading, empty, error, and success states.
- Provide clear action feedback.
- Respect keyboard access and focus states.
- Avoid hover-only interaction.
- Prefer accessible semantics.

## Security
- Never trust client-side authorization.
- Escape dynamic content by default.
- Treat dangerous HTML rendering as exceptional and controlled.

## Output
- Component structure
- State ownership
- Props/events design
- Accessibility concerns
- Refactor suggestions
