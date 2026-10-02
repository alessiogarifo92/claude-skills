---
name: security-review
description: Use when reviewing any change that touches authentication, authorization, user input, file uploads, webhooks, SQL, secrets, or other trust boundaries, for realistic exploit paths and abuse scenarios
version: 1.1.0
model: opus
effort: high
---

# Security Review

**Run on:** opus · effort high — exploit reasoning; `security-auditor` runs it.

**Pairs with:** `deploy-readiness` (this review is mandatory before anything becomes publicly reachable), `requesting-code-review` (the `security-auditor` agent runs it as a panel lens).

You review changes for realistic security risk, abuse paths, and implementation mistakes.

## Threat model first
Identify:
- trust boundaries,
- user-controlled inputs,
- privileged operations,
- sensitive outputs,
- persistence points,
- external integrations,
- replay or abuse opportunities.

## Always check
- Authentication.
- Authorization.
- Input validation.
- Output encoding.
- CSRF.
- CORS.
- XSS.
- SQL injection.
- SSRF.
- Deserialization risks.
- File upload safety.
- Secrets handling.
- Logging of sensitive data.
- Rate limiting and abuse controls.
- Race conditions in sensitive flows.
- Insecure direct object references.
- Privilege escalation paths.

## Web-specific checks
- Frontend state is never treated as trusted authorization.
- Dangerous HTML rendering must be escaped or sanitized.
- Uploaded files must be validated by type, size, and storage policy.
- Webhooks must be verified with signatures or shared secrets.
- Redirects must be constrained to safe targets.
- Error messages must not leak secrets or internal structure.

## Backend-specific checks
- Server-side authorization must exist for every protected operation.
- Parameter binding must be used for SQL.
- Transactions should cover multi-step sensitive writes.
- Default-deny is preferred for access control.
- Sensitive actions should be auditable.
- Background jobs should re-check authorization when needed.

## What to return
For each finding:
- severity,
- exact location,
- why it matters,
- exploit scenario,
- recommended fix,
- how to verify the fix.

## Risk priorities
1. Remote code execution.
2. Authentication bypass.
3. Authorization bypass.
4. Secret exposure.
5. Injection.
6. Data corruption or unauthorized mutation.
7. Availability issues.
8. Privacy leaks.

## Safe defaults
- Fail closed.
- Avoid implicit trust.
- Prefer server-enforced controls.
- Minimize attack surface.
