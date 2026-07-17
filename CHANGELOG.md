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

Ticket #7 — workflow end-to-end skills+agents (decisione del report #4):

- product-ownership 1.1.0 — nuova sezione "End-to-end workflow and handoffs" (tabella fasi → skill → agent, ordine del gate di chiusura, regole anti-attrito, agents `researcher`/`Explore`/`test-runner`) e riga di checklist sul sync della sezione
- debugging-workflow 1.0.1 — chiarito che `superpowers:systematic-debugging` governa il processo e viene prima; questa skill aggiunge il livello repo-specifico
- test-verification 1.0.1 — esplicitata la delega dell'esecuzione all'agent `test-runner`
- (senza versione) `agents/researcher.md` — rimando alla regola di chiusura research; report del #4 marcato come decision record

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
