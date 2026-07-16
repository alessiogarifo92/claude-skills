---
name: python-backend
description: Use when writing or reviewing Python backend code - services, scripts, or API handlers - for typing, error handling, async correctness, resource or subprocess safety, or input validation
---

# Python Backend

Review and design Python code for clarity, reliability, and safety.

**Pairs with:** security-review for a full threat-model pass on security-sensitive Python services.

## Preferred practices
- use type hints where useful
- keep functions focused
- make side effects explicit
- validate inputs at boundaries
- separate domain logic from I/O and transport
- prefer readability over cleverness

## Quality checks
- explicit error handling
- structured logging
- correct async usage
- safe resource management
- constrained subprocess usage
- safe file handling
- no hardcoded or logged secrets

## Security checks
- injection
- unsafe deserialization
- path traversal
- SSRF
- unsafe shell execution

## Output
- Design summary
- Correctness risks
- Security risks
- Testing approach
- Refactor suggestions
