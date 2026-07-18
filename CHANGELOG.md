# Changelog

Storia dei cambiamenti delle skill di questa repo. Ogni skill ha una versione
semver nel campo `version` del proprio frontmatter (`SKILL.md`).

Regole di bump:

- **MAJOR** — cambio di comportamento o approccio della skill
- **MINOR** — nuova sezione, regola o capacità
- **PATCH** — correzioni, chiarimenti, refusi

Il bump di versione e la riga di changelog vanno nello stesso commit della
modifica alla skill.

## 2026-07-18

Nuovo agent globale `github-ops` (model: haiku) per operazioni git/GitHub meccaniche e convention-following (worktree/branch, PR, issue) senza giudizio editoriale:

- (senza versione) `agents/github-ops.md` — nuovo agent
- product-ownership 1.3.0 — `github-ops` in fase 3 (creazione worktree/branch del ticket) e fase 7 (merge/push, chiusura issue, cleanup branch/worktree) della tabella end-to-end

## 2026-07-17

Ticket #8 — skill market-analyst e integrazione nel workflow decisionale:

- market-analyst 1.0.0 — nuova skill: due diligence su costi (pricing verificato, free tier, stima a volume attuale e 10x, lock-in) e licenze/legale (SPDX, copyleft vs permissive, ToS delle API, copyright e attribuzione degli asset) di tool, API, SaaS, librerie e asset esterni
- product-ownership 1.2.0 — `market-analyst` nelle fasi 1–2 della tabella end-to-end (prima di fissare l'adozione di dipendenze esterne; il ticket ne cita il verdetto) e come lente in fase 6 quando il change introduce nuove dipendenze o servizi a pagamento

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
