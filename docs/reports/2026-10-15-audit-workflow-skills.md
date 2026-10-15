# Audit di workflow, skill, agent e script — 2026-10-15

Base: `af24c03`. Metodo: esecuzione di tutti i controlli esistenti (`validate.py`, `worktree_test.sh`, `install.sh --dry-run`, `bash -n`), lettura delle skill di orchestrazione e degli agent, controlli incrociati scriptati (riferimenti, simmetria `Pairs with`, comandi `gh`), riproduzione di ogni bug prima della correzione.

## Stato di partenza
- `validate.py`: 37 skill, 14 agent, 0 errori, 0 warning.
- `worktree_test.sh`: 26/26 ok.
- Nessun riferimento a skill o agent inesistenti.

## Corretti in questo branch
| # | Gravità | Problema | Prova | Correzione |
|---|---|---|---|---|
| 1 | Alta (perdita di dati) | `worktree.sh cleanup` considerava mergiato un branch con *qualsiasi* PR mergiata dallo stesso nome e lo cancellava con `-D`: i commit aggiunti dopo il merge della PR andavano persi | Riprodotto con un `gh` finto: "DATA LOSS: branch with unmerged commit force-deleted" | Conta solo se la punta del branch coincide con l'head SHA della PR mergiata; test nuovo |
| 2 | Media | `DEFAULT_BRANCH` fisso a `main` (e frase troncata nella skill) | Lettura del codice | Letto da `origin/HEAD`, fallback `main`, override `WORKTREE_DEFAULT_BRANCH`; test nuovo |
| 3 | Media | In sessione remota `gh issue/pr/repo ...` risponde 403 (GraphQL), ma CLAUDE.md, `worktree-manager`, `autonomous-workflow` e `product-ownership` li prescrivono per controllo `in progress`, etichetta, chiusura, repo privata | `gh issue list` → `HTTP 403: GitHub GraphQL is not available` in questa sessione; `gh api` REST ok | Aggiunti gli equivalenti REST/MCP nei punti operativi |
| 4 | Bassa | Nel repo delle skill l'hook SessionStart girava due volte e stampava lo stato due volte (visibile all'avvio di questa sessione) | Output dell'hook duplicato | L'entry di progetto passa `--project` e tace se c'è quella utente |
| 5 | Bassa | `product-ownership` rimandava alla regola globale "always surface test credentials", rimossa da CLAUDE.md | `grep`: esiste solo nel CHANGELOG | Rimando alla sezione di `test-verification` |

## Da decidere (non toccati: scelte dell'utente o cambi più ampi)
1. **Gli agent "read-only" hanno `Bash`** (`reviewer`, `critic`, `architect`, `security-auditor`, `release-auditor`, `researcher`, `verifier`): il divieto di scrivere o fare `git commit/push` è solo nel prompt. Proposta: un hook `PreToolUse` che blocca `git (commit|push|reset|checkout)` e redirezioni di scrittura quando chi chiama è un subagent read-only, oppure `disallowedTools` nel frontmatter se la versione di Claude Code lo supporta.
2. **CLAUDE.md costa ~25 KB in ogni conversazione**, e la sua stessa regola dice che le regole di fase vanno nelle skill. Candidati a scendere di livello: "Never skip a Design UI/UX phase" → `project-lifecycle` (che già contiene la fase 3.5), "Restore the stack to main" e "One git worktree per ticket" → `worktree-manager`/`product-ownership`, "Every implementation ticket ships with unit tests" → `test-verification`. In CLAUDE.md resterebbe una riga di rimando per ciascuna.
3. **`/design` e `taste` non sono installati** né dagli script né in questa sessione, ma CLAUDE.md e `project-lifecycle` li prescrivono per la fase 3.5. Il fallback (Artifact quickstart con intent `design`) è scritto solo in `autonomous-workflow`. Proposta: stesso fallback in `project-lifecycle` step 3 e nella regola globale.
4. **CI non verifica gli script shell oltre a `worktree.sh`**: niente `shellcheck`, nessun test per `install.sh` (idempotenza, mai sovrascrivere file reali), `session-start-hook.sh` (deduplica, rilevamento "BEHIND") e `cloud-setup-script.sh` (merge `jq` di `settings.json`). `shellcheck` è preinstallato sui runner `ubuntu-latest`; aggiungerlo richiede prima di ripulire i warning (qui non è installato, quindi non verificabile localmente senza installarlo).
5. **`cloud-setup-script.sh` senza `jq`** non registra l'hook e non lo dice. Proposta: fallback con `python3` e una riga di avviso.
6. **`github-ops` non ha `sub_issue_write` né `get_file_contents`**, che `product-ownership` elenca come strumenti MCP per epic e verifica degli screenshot: delegando quei passi in remoto l'agent ripiega in silenzio.
7. **`Pairs with` non simmetrici**: 22 collegamenti A→B senza B→A, 9 skill senza riga `Pairs with` (che `writing-skills` richiede). Per gli hub (`project-lifecycle`, `deploy-readiness`) l'asimmetria è normale; ha senso un warning in `validate.py` solo per le coppie di sequenza (passo precedente/successivo).
8. **`review-animations` ha `disable-model-invocation: true` upstream**: `test-verification` lo gestisce già (Read del file), ma `autonomous-workflow` stage 6 lo nomina come se fosse invocabile.
