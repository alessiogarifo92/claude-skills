---
name: sql-performance
description: Use when a query is slow, a query plan looks wrong, or you're adding an index, join, or pagination and need to reason about planner behavior, selectivity, or locking
version: 1.0.0
---

# SQL Performance

Optimize queries for correctness first, then performance.

**Pairs with:** database-design when the fix is a schema/index change rather than a query rewrite.

## Analyze
- query shape
- filter selectivity
- join strategy
- index usage
- N+1 risk
- locking behavior
- sort and pagination cost
- aggregation cost
- write amplification

## Cross-database caution
MySQL, PostgreSQL, and SQLite differ in planner behavior and SQL capabilities. Do not assume the same query shape behaves identically across all three.

## Inspect for
- missing indexes
- bad composite index order
- duplicate indexes
- functions preventing index use
- implicit casts
- inefficient OR conditions
- large OFFSET pagination
- full scans on hot paths
- lock contention

## Output
- Query goal
- Performance concern
- Likely cause
- Recommended rewrite or index
- Verification method
