# Changelog

Storia dei cambiamenti delle skill di questa repo. Ogni skill ha una versione
semver nel campo `version` del proprio frontmatter (`SKILL.md`).

Regole di bump:

- **MAJOR** — cambio di comportamento o approccio della skill
- **MINOR** — nuova sezione, regola o capacità
- **PATCH** — correzioni, chiarimenti, refusi

Il bump di versione e la riga di changelog vanno nello stesso commit della
modifica alla skill.

## 2026-08-23 (3)

Verifica dei due commit precedenti: cercati i riferimenti incrociati rimasti appesi dopo lo spostamento di contenuto fuori da CLAUDE.md, e controllato come le regole spostate raggiungono i subagent.

- orchestrating-agents 1.2.0 — sezione "Dispatch brief": nuova regola "Inline every rule the agent must follow — agents cannot load skills". Verificato sui frontmatter di tutti e 7 gli agent in `agents/`: nessuno ha il tool `Skill`, quindi nessun subagent può invocare una skill per scoprire come si lavora in questo progetto. Le skill sono una risorsa lato orchestratore: la sessione principale le carica ed estrae il vincolo concreto nel brief. Conseguenza diretta dello spostamento di regole da CLAUDE.md (che gli agent vedono) alle skill (che non possono caricare) — senza questa regola il refactor avrebbe reso invisibili agli agent le regole spostate, con fallimento silenzioso.
- project-lifecycle 1.4.1 — corretto riferimento appeso nel "Check": il bullet su Laravel Boost puntava a CLAUDE.md, da cui la regola è stata rimossa nel commit precedente; ora punta a `laravel-architecture`.
- product-ownership 1.14.1 — sezione "Labels": ripristinato il dettaglio operativo che era solo nella memoria di progetto poi cancellata — `feature` è deliberatamente al posto del default `enhancement`, e un repo con la label stock va corretto con `gh label edit enhancement --name feature` (rinominare preserva le associazioni esistenti; creare un duplicato spacca il backlog su due label).

## 2026-08-23 (2)

- CLAUDE.md — nuova sezione in testa "Where a new rule/lesson goes: skill → CLAUDE.md → project memory", regola di instradamento per i prossimi apprendimenti; rimosse le sezioni "Manual verification" (4 sezioni + "always surface test credentials") e "Laravel Boost is standard equipment", spostate integralmente sotto. File sceso da 126 a 81 righe (~28KB → ~18.5KB) pur avendo aggiunto la nuova sezione.
- test-verification 1.4.0 — assorbite le 5 sezioni "Manual verification" di CLAUDE.md: "Browser checks" arricchita con real data/standard ports/one environment at a time e lo swap del layer di serving (incl. dev server diretto tipo Expo); nuova sezione "Mobile + browser: verify both interfaces"; "Manual handoff" arricchita con l'apertura "walk it yourself first", il vincolo di non ripristinare l'ambiente prima dell'handoff, mock data per casi non coperti dal dataset reale, credenziali di test solo in chat mai in artefatti committati.
- laravel-architecture 1.3.0 — sezione "Ground the design in the running app" ora contiene per intero la regola "Laravel Boost is standard equipment" (prima era solo un rimando a CLAUDE.md), così si carica solo quando si lavora davvero su un repo Laravel invece che in ogni conversazione.

## 2026-08-23 (1)

- CLAUDE.md — sezione "Invoke product-ownership itself at ticket pickup" sostituisce le 5 sezioni globali aggiunte in precedenza oggi stesso (Test info comment, link blob su repo private, ListAgents prima di considerare orfano un worktree, blocco classificatore su `gh pr merge`, checkoff todo Notion): quelle regole pesavano su ogni conversazione di ogni progetto anche quando irrilevanti, essendo CLAUDE.md caricato per intero e sempre, a differenza delle skill (di cui sta sempre in contesto solo il nome+descrizione, il corpo si carica solo quando la skill viene invocata). Spostate nelle skill che già governano quelle fasi, sotto.
- product-ownership 1.14.0 — sezione "Recording the check" step 3: aggiunto il caveat sui repo privati (link `blob/<sha>/...` al posto di `raw.githubusercontent.com`, che non renderizza) e la nota su non far comparire credenziali reali negli screenshot committati; sezione "Before creating on GitHub": nuovo bullet per spuntare il todo Notion sorgente quando un ticket nasce da lì; nuove voci nel "Check" finale.
- worktree-manager 1.4.0 — sezione "Lifecycle" step 1 (Pickup): nuova regola `ListAgents` prima di considerare orfano un worktree/ticket altrui, con l'incidente del ticket #8 come esempio; rimando dallo step 2 (During) alla stessa disciplina applicata al DB condiviso.
- finishing-a-development-branch 1.1.0 — nuova sezione "`gh pr merge` is hard-blocked by the auto-mode classifier": il classificatore blocca `gh pr merge` e le modifiche a settings.json anche con autorizzazione esplicita dell'utente in conversazione; va girato all'utente via `!`; incluso anche il caso pratico del `git checkout` locale che fallisce se `main` è già in uso da un altro worktree (il merge remoto di solito è comunque riuscito).

## 2026-08-16 (6)

- product-ownership 1.13.1 — rinominato il label di tipo ticket `enhancement` in `feature` nella sezione "Labels" (nome preferito dall'utente, che non gradisce "enhancement"); nessun cambio di comportamento.

## 2026-08-16 (5)

- product-ownership 1.12.0 — nuova sottosezione "Recording the check: 'Test info' section on the ticket" dentro "Manual user check": screenshot Playwright per ogni step del walkthrough (o per gli step fondamentali sui walkthrough lunghi/ripetitivi), committati sotto `docs/test-evidence/<issue>-<slug>/`, referenziati in un commento `## Test info` via URL `raw.githubusercontent.com` sul commit SHA (non sul branch, che viene cancellato al merge). Chiude #11.
- product-ownership 1.13.0 — nuovo tipo di ticket "Spike" (esplorazione a tempo limitato, deliverable throwaway invece di un report) e nuova sezione "Labels": convenzione bug→`bug`, feature/implementation→`enhancement`, research→`question`, spike→`spike` (label creata: `gh label create "spike" ...`); regola di priorità bug > enhancement quando l'utente non specifica altrimenti. Chiude #12.

## 2026-08-16 (4)

- CLAUDE.md — nuova regola globale "Never wipe shared DB data while another ticket is in progress": operazioni distruttive su un DB condiviso (reset/seed fixture, `migrate:fresh`, wipe tabelle, cancellazione mock data) possono avvenire solo se nessun altro ticket ha la label `in progress`, altrimenti va usata una soluzione non distruttiva (dati scoped, transazione con rollback, schema/DB separato per i test automatici). Estende "one environment at a time" oltre il solo check manuale, coprendo anche i run di test automatici. Chiude #9.
- CLAUDE.md — sezioni "Manual verification: real data, standard ports, one environment at a time" e "Restore the stack to main when a ticket closes" generalizzate a stack senza layer di serving swappabile (es. Expo/React Native via Expo Go): lo "swap" diventa fermare/riavviare il dev server dalla directory del worktree sulla stessa porta, riusando le stesse env var di backend/DB, invece del bind-mount/`docker compose` usato per stack containerizzati. Chiude #10.
- worktree-manager 1.3.1 — rimando alla nuova regola no-wipe DB nella sezione "Lifecycle" (bullet 2, "During"), e nota nel bullet 3 ("After merge") che il meccanismo di swap include ora anche il riavvio di un dev server diretto (es. `expo start`), non solo bind mount/`docker compose`/symlink.
- test-verification 1.3.1 — rimando alla regola no-wipe DB nella voce "migrations" di "By change type".

## 2026-08-16 (3)

- product-ownership 1.11.1 — nota nella sezione Milestones: `gh issue create/edit --milestone <title>` risolve il titolo solo tra i milestone **aperti**, quindi assegnare un ticket a un milestone creato già `closed` fallisce con "not found" anche se esiste. Riscontrato davvero creando "Setup"/"Design UI/UX" su subsplit già chiusi (tutti i ticket coperti erano già fatti) — fix: riaprire via API, assegnare, richiudere.

## 2026-08-16 (2)

- product-ownership 1.11.0 — nuova sezione "Milestones — grouping tickets by phase or goal": creare un milestone GitHub per ogni batch di ticket di fase/obiettivo (es. "MVP") e assegnarci i ticket, invece di nominare solo l'intervallo ("ticket #2-#11") come testo libero nel body — non interrogabile e fragile nel tempo. `gh` non ha un subcommand `milestone` dedicato, quindi si passa da `gh api repos/<owner>/<repo>/milestones` per crearlo e da `gh issue create/edit --milestone` per assegnarlo (verificato l'endpoint in lettura su subsplit, nessun milestone esistente). Esplicitamente ortogonale alle relazioni di dipendenza/epic appena introdotte (1.10.x): milestone = "appartiene a questo obiettivo", blocked-by/blocking = "può partire adesso". Stesso principio anti-burocrazia delle sezioni precedenti: niente milestone su un obiettivo già chiuso al 100%, nessun beneficio in avanti.
- project-lifecycle 1.4.0 — riga della fase 4 "Tickets" aggiornata per rimandare alla nuova convenzione milestone di product-ownership: il batch di ticket di una fase riceve il proprio milestone, non solo un intervallo nominato nel testo.

## 2026-08-16

- product-ownership 1.10.0 — nuova sezione "Ticket relationships — dependencies and epics": usare i campi nativi di `gh` (`--blocked-by`/`--blocking` per dipendenze sequenziali, `--parent`/`--add-sub-issue` per epic) invece di convenzioni ad-hoc (frase "Blocked by #N" nel body, checklist scritta a mano per gli epic) — sono nativamente renderizzati in UI, restano sincronizzati da soli e sono interrogabili via `--json`. Include il one-liner per trovare, su tutto il backlog aperto, quali ticket sono bloccati adesso (hanno un blocker ancora aperto) e quali sono liberi e quindi assegnabili in parallelo. Richiesta esplicita dell'utente durante il lavoro sul progetto subsplit, a livello globale (non solo per quel repo): verificato che `gh` 2.96.0 espone questi campi/flag nativamente (`blockedBy`, `blocking`, `parent`, `subIssues`, `subIssuesSummary`), niente `issueType`/Issue Types nativi però su repo personali (campo risultato `null` via GraphQL) quindi gli epic restano un label `epic` + sub-issue, non un issue type dedicato.
- product-ownership 1.10.1 — fix nel one-liner della sezione appena aggiunta: `blockedBy`/`blocking` tornano come `{nodes: [...], totalCount: N}`, non come array piatto — verificato creando davvero la relazione (subsplit #29 blocked-by #22) e ispezionando l'output reale di `gh issue view`/`gh issue list`, non assunto a memoria.

## 2026-08-09

- project-lifecycle 1.3.0 — nuova fase 3.5 "Design UI/UX" (proposta esplicitamente per ogni progetto con superficie utente, non solo quando il piano del progetto la prevede già), da confermare prima di disegnare qualunque ticket che tocchi schermate; nuovo check per intercettare il caso. Gap scoperto sul progetto subsplit: 5 ticket UI-bearing (#3/#4/#6/#8/#9) erano stati disegnati senza nessuna direzione di design, e la skill non aveva alcuna fase che lo prevenisse — la regola globale CLAUDE.md sul "non saltare una fase di design" scatta solo se il piano del progetto ne definisce già una, non se project-lifecycle stesso non la prevede mai.

Aggiunti due server MCP a user scope (`~/.claude.json`, disponibili in tutti i progetti): `context7` per la documentazione version-specific delle librerie, `playwright` per guidare un browser reale. Le skill sono state allineate perché il browser venga effettivamente usato al posto del fallback a riga di comando, e perché la verifica automatica sfoci sempre in una checklist manuale per l'utente invece di sostituirla. Nota: `laravel-boost` non è a user scope per costruzione — è una dev dependency Composer per progetto, installata con `php artisan boost:install` in ogni repo Laravel.

- test-verification 1.3.0 — nuova sezione "Browser checks" (guidare Playwright sullo stack reale, leggere la console, limiti di ciò che prova) e "Manual handoff" (i tre blocchi del passaggio all'utente: già verificato / serve il tuo occhio / non verificato e perché); il passo 6 dell'ordine di verifica passa da "manual smoke checks if needed" a smoke check browser sulla superficie toccata. I check browser restano in main session, non delegati: il loro output è la consegna che legge l'utente, non un pass/fail
- product-ownership 1.9.0 — il gate manuale passa dal semplice "apri/curl la pagina" al walk completo con Playwright prima della consegna, e la consegna adotta la struttura a tre blocchi di test-verification; nuova riga nella tabella scuse/realtà contro il trattare un flusso Playwright verde come sostituto del giudizio dell'utente
- laravel-architecture 1.1.0 — nuova sezione "Ground the design in the running app, not the files": con Laravel Boost installato, interrogare route/schema/versioni/log/tinker a runtime invece di dedurli dai sorgenti, e ricerca doc version-matched prima della ricerca web generica; senza Boost, dichiarare quali conclusioni derivano solo dalla lettura dei file
- agents/test-runner — aggiunto `mcp__playwright__*` alla lista `tools` (pattern server-level supportato nel frontmatter) con un vincolo esplicito nel prompt: solo replay di un check già specificato passo-passo su uno stack già avviato, mai esplorazione autonoma né avvio di stack
- CLAUDE.md — nuova regola globale "Laravel Boost is standard equipment in every Laravel project": Boost va installato in ogni progetto Laravel che non ce l'ha, appena inizia il primo lavoro sostanziale, non solo usato dove esiste già. La regola copre i punti non ovvi verificati sui doc ufficiali: `boost:install` è interattivo (niente flag `--no-interaction` documentato, in caso si passa all'utente col prefisso `!`); genera un `CLAUDE.md` di progetto e lo rigenera a ogni run, quindi un `CLAUDE.md` di progetto preesistente va letto e preservato; `.mcp.json` + file di guideline + `boost.json` sono rigenerabili e gitignorabili mentre `.ai/rules/` va committato; le project rule si registrano solo col tool `record-rule` perché rigenera `.ai/rules/index.md` (un file scritto a mano resta invisibile); `infer-conventions` per bootstrappare le rule su codebase esistenti, con approvazione per convenzione; `boost:update --ansi` in `post-update-cmd` per evitare drift
- laravel-architecture 1.2.0 — la sezione runtime non presuppone più che Boost ci sia: se manca, si installa prima di procedere (rimando alla regola in CLAUDE.md)
- project-lifecycle 1.2.0 — nuovo item in `Check`: progetto Laravel scaffoldato senza Boost va sistemato prima del primo ticket

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
- `settings.json` ora versionato qui, stesso pattern di `CLAUDE.md` e `agents/`: il file è stato spostato in `~/.claude/skills/settings.json` e `~/.claude/settings.json` è un symlink ad esso — così la disattivazione del plugin (e ogni altra impostazione globale) è riproducibile su un'altra macchina invece di restare locale. Nessun segreto nel file: permessi, modello, plugin, marketplace, tema, notifiche. `settings.local.json` resta fuori dalla repo, è l'override per-macchina. Verificato che il symlink regge a una scrittura reale di Claude Code (`claude plugin enable` + `disable` su superpowers, due salvataggi consecutivi): la scrittura è atomica — l'inode del file cambia a ogni salvataggio — ma il symlink viene risolto *prima*, quindi il rename atterra sul file dentro la repo e il symlink non viene mai sostituito. La copia versionata riceve l'aggiornamento invece di divergere; md5 e `git diff` invariati a fine test

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
