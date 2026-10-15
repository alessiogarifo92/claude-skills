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

## Seconda tornata: i punti aperti, tutti chiusi
| # | Punto | Esito |
|---|---|---|
| 1 | Agent "read-only" con `Bash` senza vincolo reale | `scripts/agent-guard.sh` come hook `PreToolUse` nel frontmatter di tutti gli agent tranne `github-ops`; 36 casi in `agent-guard_test.sh`; verificato dal vivo con una sessione headless (`git tag` bloccato). In una sessione già aperta l'hook non scatta finché non si riavvia (le definizioni degli agent sono caricate all'avvio): verificato anche questo |
| 2 | CLAUDE.md troppo pesante | 25 KB → 13 KB: titoli di sezione invariati (le skill li citano), dettagli spostati in `test-verification`, `project-lifecycle`, `worktree-manager`, `product-ownership`; nuova sezione su REST vs GraphQL |
| 3 | `/design` assente | Fallback al quickstart `Artifact` con intent `design` in `project-lifecycle` e CLAUDE.md |
| 4 | Script shell senza CI | `shellcheck` (0 warning) e `scripts_test.sh` (21 casi: install, hook di avvio, setup cloud) in CI |
| 5 | `cloud-setup-script.sh` senza `jq` | Fallback `python3`, avviso se non c'è nessuno dei due; testato con `jq` rotto |
| 6 | `github-ops` senza strumenti | Aggiunti `sub_issue_write`, `get_file_contents`, `actions_list`, `actions_get`; regola su GraphQL 403 |
| 7 | `Pairs with` mancanti | Aggiunti nelle 9 skill; `validate.py` li impone. L'asimmetria degli hub resta voluta |
| 8 | `review-animations` non invocabile | Nota in `autonomous-workflow` stage 6 |
