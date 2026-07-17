# Per-Skill Versioning Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a semver `version` field to every skill's frontmatter and a global `CHANGELOG.md`, with the bump rule documented in `product-ownership`.

**Architecture:** Pure-markdown change: 18 `SKILL.md` frontmatter edits, one new root file, one skill-content edit. No code, no tests — verification is `grep`-based.

**Tech Stack:** Markdown, YAML frontmatter, bash/awk for the batch edit.

**Spec:** `docs/superpowers/specs/2026-07-17-skill-versioning-design.md`

## Global Constraints

- Baseline version for all 18 skills is exactly `1.0.0`, dated 2026-07-17.
- `version` goes in the YAML frontmatter of each `SKILL.md`, as the last key before the closing `---`.
- Bump rules (verbatim from spec): MAJOR = cambio di comportamento o approccio; MINOR = nuova sezione, regola o capacità; PATCH = correzioni, chiarimenti, refusi.
- Version bump + changelog line must land in the same commit as the skill change they describe.
- No git tags, no CI automation, no per-skill changelogs.

---

### Task 1: `version` field in all frontmatters + `CHANGELOG.md` baseline

**Files:**
- Modify: all 18 `*/SKILL.md` in the repo root (api-design, architecture-review, brand-strategist, database-design, debugging-workflow, docs-and-specs, go-backend, handling-sudo-and-missing-tools, laravel-architecture, principal-engineering-core, product-marketing-strategist, product-ownership, python-backend, refactoring-strategy, security-review, sql-performance, test-verification, vue-frontend)
- Create: `CHANGELOG.md`

**Interfaces:**
- Produces: `version: 1.0.0` key in every skill frontmatter; `CHANGELOG.md` structure (`## YYYY-MM-DD` sections, `- <skill> <semver> — <description>` lines) that Task 2's rule text refers to.

- [ ] **Step 1: Insert `version: 1.0.0` before the closing `---` of each frontmatter**

```bash
cd /home/alobombon/.claude/skills
for f in */SKILL.md; do
  awk 'BEGIN{n=0} /^---$/{n++; if(n==2){print "version: 1.0.0"}} {print}' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
done
```

- [ ] **Step 2: Verify every skill has exactly one version line**

Run: `grep -c '^version: 1.0.0$' */SKILL.md | grep -v ':1$'`
Expected: no output (every file has exactly 1 match).

Run: `grep -L '^version:' */SKILL.md`
Expected: no output (no file is missing the field).

- [ ] **Step 3: Create `CHANGELOG.md`**

```markdown
# Changelog

Storia dei cambiamenti delle skill di questa repo. Ogni skill ha una versione
semver nel campo `version` del proprio frontmatter (`SKILL.md`).

Regole di bump:

- **MAJOR** — cambio di comportamento o approccio della skill
- **MINOR** — nuova sezione, regola o capacità
- **PATCH** — correzioni, chiarimenti, refusi

Il bump di versione e la riga di changelog vanno nello stesso commit della
modifica alla skill.

## 2026-07-17

Baseline: tutte le skill partono da 1.0.0.

- api-design 1.0.0
- architecture-review 1.0.0
- brand-strategist 1.0.0
- database-design 1.0.0
- debugging-workflow 1.0.0
- docs-and-specs 1.0.0
- go-backend 1.0.0
- handling-sudo-and-missing-tools 1.0.0
- laravel-architecture 1.0.0
- principal-engineering-core 1.0.0
- product-marketing-strategist 1.0.0
- product-ownership 1.0.0 — include la nuova regola di versioning nella checklist
- python-backend 1.0.0
- refactoring-strategy 1.0.0
- security-review 1.0.0
- sql-performance 1.0.0
- test-verification 1.0.0
- vue-frontend 1.0.0
```

- [ ] **Step 4: Commit**

```bash
git add */SKILL.md CHANGELOG.md
git commit -m "Add version 1.0.0 to all skill frontmatters and CHANGELOG baseline (#5)"
```

---

### Task 2: Versioning rule in `product-ownership`

**Files:**
- Modify: `product-ownership/SKILL.md` (add a `## Skill versioning` section before `## Check`, and one bullet inside `## Check`)

**Interfaces:**
- Consumes: `CHANGELOG.md` structure and bump rules from Task 1.

- [ ] **Step 1: Add the section before `## Check`**

Insert this immediately before the `## Check` heading:

```markdown
## Skill versioning
Every skill in this repo carries a semver `version` in its `SKILL.md` frontmatter. When you modify a skill, bump its version (MAJOR = behavior/approach change, MINOR = new section/rule/capability, PATCH = fixes/clarifications) and add a line to the root `CHANGELOG.md` under today's date — in the same commit as the change.

```

- [ ] **Step 2: Add the checklist bullet**

Inside `## Check`, add:

```markdown
- Modified a skill → did you bump its frontmatter `version` and add the `CHANGELOG.md` line in the same commit?
```

- [ ] **Step 3: Verify**

Run: `grep -n 'Skill versioning' product-ownership/SKILL.md && grep -c '^version: 1.0.0$' product-ownership/SKILL.md`
Expected: the heading found; version count `1` (rule addition is part of the 1.0.0 baseline per spec).

- [ ] **Step 4: Commit**

```bash
git add product-ownership/SKILL.md
git commit -m "Document per-skill versioning rule in product-ownership (#5)"
```
