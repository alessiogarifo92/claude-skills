---
name: api-design
description: Use when designing or reviewing a REST-style API contract - new endpoints, request/response shapes, validation and error formats, pagination, filtering, idempotency, or breaking-change risk
version: 1.0.2
---

# API Design

**Run on:** sonnet · effort high — contract design is bounded; the review gate catches slips.

**Pairs with:** `architecture-review` (where the boundary sits), `database-design` (the data behind the contract), `security-review` (auth, input validation), `docs-and-specs` (writing the contract down), `ticket-interrogation` (external contracts are one of its interview areas).

Design APIs that are explicit, stable, and easy to consume safely.

## Principles
- contracts should be predictable
- validation errors should be structured
- status codes should reflect intent
- pagination must be explicit
- field naming should be consistent
- backward compatibility matters

## Check
- request validation
- response shape consistency
- error envelope quality
- pagination semantics
- filtering and sorting safety
- idempotency for retryable operations
- authorization on every protected endpoint

## Output
- Contract summary
- Breaking-change risk
- Validation concerns
- Error design notes
- Suggested improvements
