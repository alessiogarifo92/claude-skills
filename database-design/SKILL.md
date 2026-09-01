---
name: database-design
description: Use when designing a new table, writing a migration, or reviewing schema changes for cardinality, nullability, constraints, indexes, transaction boundaries, or migration rollout risk
version: 1.1.0
---

# Database Design

Design schemas for integrity, clarity, and safe evolution.

**Pairs with:** sql-performance once the schema exists and you're optimizing queries against it.

## Always consider
- cardinality
- nullability
- uniqueness
- foreign keys
- transaction boundaries
- isolation needs
- index strategy
- retention and lifecycle
- migration rollout risk

## Rules
- choose types carefully
- enforce constraints in the database when practical
- avoid meaningless nullable fields
- separate large data migrations from schema changes when needed
- keep migrations reversible when possible
- explain indexes intentionally

## Before assuming a DB connector gives you the live schema
An MCP database connector (Neon, Supabase, PlanetScale, MongoDB Atlas) talks to a **hosting platform's API**, not to a database protocol. It returns live schema, branches and query tuning only when the database is actually hosted on that platform:

- **Neon** — Postgres on Neon, and nothing else. It is not a Postgres client: it does nothing for MySQL, and nothing for a Postgres running in a container, on Cloud SQL, on RDS, or on a VM.
- **PlanetScale** — MySQL or Postgres, but only databases hosted on PlanetScale. This is the MySQL answer; there is no generic MySQL connector.
- **Supabase** — projects on Supabase. **MongoDB Atlas** — clusters on Atlas.
- **Laravel** — already covered by `laravel-boost`, which exposes the runtime schema whatever the database is. A DB connector there is redundant.

So establish where the database actually runs — `DATABASE_URL`, `compose.yaml`, the deploy target — before proposing one. When none applies, the schema still comes from the migrations and the model definitions, and `EXPLAIN` comes from a `psql`/`mysql` session over Bash: say that plainly instead of asking for a connector that would not connect to anything.

Connecting one is also only half the work: a subagent sees only what its `tools:` frontmatter lists, so `implementer` keeps reading migrations until `mcp__<Server>__*` is added there — see `orchestrating-agents`.

## Output
- Data model summary
- Constraints
- Indexes
- Migration notes
- Risks
- Rollback considerations
