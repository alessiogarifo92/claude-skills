---
name: api-design
description: Use when designing or reviewing a REST-style API contract - new endpoints, request/response shapes, validation and error formats, pagination, filtering, idempotency, or breaking-change risk
---

# API Design

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
