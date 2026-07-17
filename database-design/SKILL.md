---
name: database-design
description: Use when designing a new table, writing a migration, or reviewing schema changes for cardinality, nullability, constraints, indexes, transaction boundaries, or migration rollout risk
version: 1.0.0
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

## Output
- Data model summary
- Constraints
- Indexes
- Migration notes
- Risks
- Rollback considerations
