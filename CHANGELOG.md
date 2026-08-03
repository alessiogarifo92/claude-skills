# Changelog

Storia dei cambiamenti delle skill di questa repo. Ogni skill ha una versione
semver nel campo `version` del proprio frontmatter (`SKILL.md`).

Regole di bump:

- **MAJOR** — cambio di comportamento o approccio della skill
- **MINOR** — nuova sezione, regola o capacità
- **PATCH** — correzioni, chiarimenti, refusi

Il bump di versione e la riga di changelog vanno nello stesso commit della
modifica alla skill.

## 2026-08-03

Copertura completa 1:1 delle 14 skill del plugin `superpowers`, per poterlo disattivare (costo token per turno dell'hook SessionStart) senza perdere nessuna area. Analisi iniziale: 5 skill superpowers avevano già un equivalente più forte con nome proprio (orchestrating-agents ~ dispatching-parallel-agents, worktree-manager ~ using-git-worktrees, debugging-workflow ~ systematic-debugging, test-verification ~ verification-before-completion, product-ownership copre gran parte del lifecycle); per le restanti 9 sono state create skill nuove, usando il nome superpowers dove calzava 1:1 e un nome più chiaro altrove. `using-superpowers` non ha equivalente: è il bootstrap del plugin stesso (l'hook forzato ad ogni turno), non una tecnica da replicare — è esattamente il meccanismo di costo che la disattivazione elimina.

- brainstorming 1.0.0 — nuova skill (nome invariato da superpowers), esplorazione di requisiti fuzzy prima di codice/piano
- test-driven-development 1.0.0 — nuova skill (nome invariato da superpowers), ciclo red-green-refactor; distinta da test-verification che sceglie cosa far girare, non quando scrivere il test. Verificata con test di pressione (scenario time/sunk-cost su un agente sonnet): ha rifiutato la scorciatoia e seguito il ciclo correttamente
- writing-plans 1.0.0 — nuova skill (nome invariato), sequenziamento di un piano multi-step prima di toccare codice; distinta da docs-and-specs (formato del documento) ed executing-plans (esecuzione)
- executing-plans 1.0.0 — nuova skill (nome invariato), esecuzione sequenziale di un piano già scritto con checkpoint per step, anche tra sessioni/context reset
- subagent-driven-development 1.0.0 — nuova skill (nome invariato), variante a dispatch parallelo di executing-plans per step del piano genuinamente indipendenti, sopra le convenzioni di orchestrating-agents
- finishing-a-development-branch 1.0.0 — nuova skill (nome invariato), scelta del meccanismo di integrazione (push diretto/PR squash/merge/rebase) dopo il gate manuale di product-ownership
- requesting-code-review 1.0.0 — nuova skill (nome invariato), disciplina del chiedere review prima del merge, distinta dal plugin `code-review` che la esegue
- receiving-code-review 1.0.0 — nuova skill (nome invariato), rigore tecnico nel processare i commenti di review invece di accordo performativo
- writing-skills 1.0.0 — nuova skill (nome invariato), come/quando creare o modificare skill in questa repo, con verifica scalata al tipo di skill (disciplinare/tecnica/orchestratore)
- project-lifecycle 1.0.0 — nuova skill orchestratore custom (nessun equivalente superpowers): incatena brainstorming → market-analyst → architecture-review/principal-engineering-core → product-ownership (per-ticket) → deploy per un intero progetto/applicazione, non un singolo ticket
- multi-agent-brainstorm 1.0.0 — nuova skill custom (nessun equivalente superpowers): dispatch parallelo di agenti general-purpose con lenti diverse (UI/UX, architettura, costi/tooling, fattibilità codice) sulla stessa idea, sintesi in main session; resta nella fase 2 (raccolta dati) di orchestrating-agents, la decisione non viene mai delegata
- test-verification 1.1.0 — assorbe la disciplina "evidenza prima di dichiarare fatto" di superpowers:verification-before-completion (tabella scuse/realtà, mai claim senza aver rieseguito il check nella sessione corrente)
- product-ownership 1.8.0 — tabella end-to-end aggiornata su tutte le 7 fasi con i nomi finali: brainstorming/multi-agent-brainstorm, worktree-manager, writing-plans, test-driven-development, subagent-driven-development/executing-plans, requesting/receiving-code-review, finishing-a-development-branch
- debugging-workflow 1.0.2 — rimando a superpowers:systematic-debugging sostituito con test-driven-development (la riproduzione diventa il RED test)
- Plugin `superpowers@claude-plugins-official` disattivato in `~/.claude/settings.json` (`enabledPlugins`)

Passata di revisione sulle skill preesistenti che *instradano* verso le altre: erano rimaste indietro rispetto ai nuovi nomi, con riferimenti a senso unico (tutti puntavano a `direct-execution`, che non rimandava a nessuno).

- orchestrating-agents 1.1.0 — tabella delle fasi allineata ai nomi finali: fase 1 `brainstorming`/`multi-agent-brainstorm`, fase 4 `test-driven-development` + `executing-plans`/`subagent-driven-development`, fase 6 `requesting-code-review`/`receiving-code-review` attorno al plugin `code-review`
- direct-execution 1.2.0 — riga `**Pairs with:**` e sezione "Escalating to planning" con le destinazioni esplicite dell'escalation (brainstorming → writing-plans → executing-plans/subagent-driven-development → project-lifecycle) invece di "brainstorming/planning" generico
- test-verification 1.2.0 — riga `**Pairs with:**` (confine con `test-driven-development` sull'ordine test/codice, e col gate manuale di `product-ownership`: i check verdi sono evidenza, mai autorizzazione al merge) e sezione `Boundary`
- multi-agent-brainstorm 1.1.0 — modello per lente invece di quattro agenti `general-purpose` che ereditano opus: UI/UX e architettura `general-purpose` (sonnet), costi `researcher` (sonnet, pagine di pricing come fonti), fattibilità codice `Explore` (haiku) su repo esistente; nuovo check "ogni lente è davvero decisiva?" per non dispatchare tutte e quattro di default
- project-lifecycle 1.1.0 — fase 5 esplicita l'intera catena per-ticket (writing-plans → test-driven-development → test-verification → requesting-code-review → gate → finishing-a-development-branch); fase 6 aggiunge `security-review` prima di rendere qualcosa pubblicamente raggiungibile e la riconferma del costo ricorrente al deploy
- writing-skills 1.1.0 — due regole nuove: aggiungere/rinominare una skill impone di ricontrollare le tre tabelle di instradamento (product-ownership, orchestrating-agents, project-lifecycle) nello stesso commit; i riferimenti incrociati devono essere bidirezionali

## 2026-07-23

Due nuove regole globali su worktree/label, richieste esplicitamente dall'utente:

- `CLAUDE.md` — "One git worktree per ticket" ora condizionata al momento in cui il codice viene effettivamente scritto/modificato (non al pickup del ticket, non per i research ticket che restano un commento); nuova sezione "Remove the in progress label when a ticket closes" — rimozione della label incondizionata su qualunque percorso di chiusura (fix, report di ricerca, duplicate/wontfix, commit che supera una PR)
- worktree-manager 1.1.0 — description e lifecycle chiariscono che `start` è un trigger di code-work, non di pickup; nuova sezione "Research tickets: no worktree, label it directly" (`gh issue edit --add-label` senza worktree per i ticket che restano commento)
- product-ownership 1.6.0 — fase 3 della tabella end-to-end: label sempre al pickup, worktree solo al code-work; sezione "Ticket types" (Research) e "When work lands via a different path" rimandano esplicitamente alla rimozione della label; "Work-in-progress label" riscritta come regola incondizionata per ogni percorso di chiusura, non solo il flusso fix-shippato

## 2026-07-19

Sistema di orchestrazione custom (sostituisce l'orchestrazione superpowers per i task lineari) — regola globale + skill + agent:

- `CLAUDE.md` — nuova sezione "Orchestration: direct execution by default" (esecuzione diretta per task lineari, subagent solo per lavoro davvero parallelo) + politica modelli, contratto di report e verification gate
- direct-execution 1.1.0 — nuova skill (albero decisionale anti-over-orchestration), poi estesa con lista agent completa (con modelli) e rimando a orchestrating-agents
- orchestrating-agents 1.0.0 — nuova skill: fasi del workflow (brainstorming → ricerca → piano → implementazione → verifica → deploy) con owner e modello per fase; politica modelli (haiku meccanico, sonnet codice/ricerca, main session per decisioni e git); dispatch brief; contratto di report STATUS/CHANGES/EVIDENCE/FINDINGS/OPEN; verification gate dell'orchestratore prima di ogni fase successiva
- (senza versione) `agents/quick-debugger.md`, `agents/implementer.md`, `agents/refactor-optimizer.md` — nuovi agent (model: sonnet), report nel contratto strutturato, git vietato
- (senza versione) `agents/researcher.md`, `agents/Explore.md`, `agents/test-runner.md`, `agents/github-ops.md` — report allineato al contratto (riga STATUS, evidenze ri-verificabili)
- product-ownership 1.4.0 — fase 4 della tabella end-to-end passa a esecuzione diretta di default (subagent solo per workstream paralleli indipendenti); ogni dispatch segue orchestrating-agents
- product-ownership 1.5.0 — sezione "Work-in-progress label": la label non era mai stata applicata all'issue #34 (creata worktree, lavoro consegnato, nessun evento "labeled") perché il passo esisteva solo come frase nella skill, scollegato dall'azione di pickup. Aggiunta indicazione di automatizzare il passo nel tooling di pickup del repo quando possibile (vedi ps-plus-catalog `.claude/skills/worktree-manager`, repo-local, non versionata qui), invece di lasciarlo alla memoria

## 2026-07-19 (bis)

Il worktree manager, prima duplicato per-repo, diventa una skill globale — stessa convenzione (naming branch/path, label "in progress") su tutti i progetti presenti e futuri, cambia solo lo stack/linguaggio del singolo repo:

- worktree-manager 1.0.0 — nuova skill globale, sposta lo script da `ps-plus-catalog/.claude/scripts/worktree.sh` a `~/.claude/skills/worktree-manager/scripts/worktree.sh` (già repo-agnostico: risolve la root via `git rev-parse --git-common-dir`, nessun percorso hardcoded); rimossa la copia locale in ps-plus-catalog
- `CLAUDE.md` — sezione "One git worktree per ticket" ora punta sempre alla skill globale invece di "usa quella del repo se esiste, altrimenti fai a mano"
- product-ownership 1.5.0 (fix di seguito) — riferimento a `worktree-manager` corretto da "implementazione di questo repo" a skill globale condivisa

## 2026-07-18

Nuovo agent globale `github-ops` (model: haiku) per operazioni git/GitHub meccaniche e convention-following (worktree/branch, PR, issue) senza giudizio editoriale:

- (senza versione) `agents/github-ops.md` — nuovo agent
- product-ownership 1.3.0 — `github-ops` in fase 3 (creazione worktree/branch del ticket) e fase 7 (merge/push, chiusura issue, cleanup branch/worktree) della tabella end-to-end

`CLAUDE.md` globale (regole per tutti i progetti) ora versionato in questa repo, stesso pattern di `agents/`:

- `CLAUDE.md` spostato qui da `~/.claude/CLAUDE.md`, che ora è un symlink a `~/.claude/skills/CLAUDE.md`
- Aggiunte due regole: "Manual verification: real data, standard ports, one environment at a time" e "Manual verification: mock data when the real dataset can't cover the case"

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
