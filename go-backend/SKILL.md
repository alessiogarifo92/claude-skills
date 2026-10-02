---
name: go-backend
description: Use when writing or reviewing Go service code - goroutine lifecycle, context propagation and cancellation, channel ownership, error handling, or interface boundaries
version: 1.0.1
---

# Go Backend

**Run on:** sonnet · effort high — writing and reviewing code.

Review and design Go code for correctness, concurrency safety, and simplicity.

**Pairs with:** security-review for a full threat-model pass on security-sensitive Go services.

## Principles
- keep packages focused
- use interfaces when they improve boundary clarity or testability
- pass context through request-scoped work
- handle errors deliberately
- keep contracts explicit

## Concurrency checks
- context cancellation is respected
- goroutines do not leak
- shared state is protected
- channels have clear ownership
- timeouts exist where appropriate
- background work has lifecycle control

## Security checks
- unsafe file handling
- command execution risks
- injection through external input
- weak secret handling
- trust in client claims

## Output
- Structural assessment
- Correctness risks
- Concurrency risks
- Error-handling issues
- Suggested improvements
