# Versioning per singola skill — design

**Data:** 2026-07-17 · **Ticket:** [#5](https://github.com/alessiogarifo92/claude-skills/issues/5)

## Obiettivo

Tracciare l'evoluzione di ogni singola skill nel tempo, con una versione esplicita per skill e una storia dei cambiamenti leggibile in un unico posto.

## Decisioni

- **Scopo:** versioning per singola skill (non tag/release a livello repo).
- **Formato:** semver `MAJOR.MINOR.PATCH` nel campo `version` del frontmatter di ogni `SKILL.md` (campo previsto dalla spec Agent Skills, già usato dai plugin ufficiali).
- **Storia:** un unico `CHANGELOG.md` alla radice della repo.

## Dettaglio

### 1. Campo `version` nel frontmatter

Ogni `SKILL.md` delle 18 skill riceve `version: 1.0.0` come baseline al 2026-07-17. Nessuna ricostruzione retroattiva di versioni dai commit precedenti.

### 2. `CHANGELOG.md` globale

In testa al file, le regole di bump:

- **MAJOR** — cambio di comportamento o approccio della skill
- **MINOR** — nuova sezione, regola o capacità
- **PATCH** — correzioni, chiarimenti, refusi

Sotto, voci raggruppate per data (più recente in alto), una riga per skill modificata:

```
## 2026-07-17
- product-ownership 1.1.0 — aggiunto gate browser-check
```

Prima voce: la baseline di oggi con tutte le 18 skill a 1.0.0.

### 3. Processo di bump

Chi modifica una skill bumpa la sua `version` e aggiunge la riga al `CHANGELOG.md` **nello stesso commit**. La regola viene aggiunta alla checklist della skill `product-ownership`, che già governa il ciclo di vita del lavoro in questa repo. L'aggiunta della regola rientra nella baseline 1.0.0 (il versioning parte da questo commit).

## Non in scope

- Tag git / GitHub Release a livello repo
- Automazione CI del bump o del changelog
- Changelog per singola skill
