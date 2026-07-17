---
name: refactoring-strategy
description: Use when planning a refactor - sequencing safe steps, isolating mechanical changes from behavior changes, or deciding how to de-risk a large structural change
version: 1.0.0
---

# Refactoring Strategy

Refactor deliberately, with low blast radius and strong validation.

**Pairs with:** architecture-review for the structural diagnosis this plan should be based on.

## Rules
- preserve behavior unless the goal is explicitly behavioral
- prefer small sequential refactors
- isolate mechanical changes from logic changes
- add safety tests before high-risk refactors when possible
- keep rollback easy
- do not mix cleanup with broad redesign unless justified

## Output
- Refactor goal
- Current pain points
- Step sequence
- Safety checks
- Rollback approach
- Expected payoff
