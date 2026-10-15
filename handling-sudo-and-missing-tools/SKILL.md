---
name: handling-sudo-and-missing-tools
description: Use when a command needs sudo/root, fails with "permission denied", or a required tool is missing from the environment or a container (command not found — e.g. wget, curl, an apt/apk package) — BEFORE attempting installation or privilege escalation.
version: 1.0.2
---

# Sudo and Missing Tools: Ask First

**Run on:** haiku · effort low — a short ask-first rule.

**Pairs with:** `autonomous-workflow` (its preflight checks tool availability), `test-verification` (Playwright WebKit, Maestro and similar installs go through this rule).

## The Rule

Never run `sudo`, install packages, or modify the system/container to work around a missing tool. **Stop and ask the user** — they will either run the command manually themselves or explicitly grant permission.

This applies to:
- any command requiring `sudo` or root
- installing anything at system level (`apt-get`, `apk add`, `dnf`, system-wide `pip`, `npm -g`)
- a tool missing inside a Docker container (e.g. `wget`, `curl`) — including `docker exec ... install` and Dockerfile edits made solely to add the tool

## What to Do Instead

1. State exactly which command is needed and why (one line, copy-pasteable).
2. Ask the user to run it manually or approve it, and wait. For sudo/interactive commands, suggest they run it themselves in this session by typing `! <command>` (e.g. `! sudo apt-get install wget`) — the `!` prefix executes it in their shell and the output lands in the conversation.
3. If an already-available alternative exists (`curl` instead of `wget`, Python stdlib instead of a CLI tool), prefer it — and say which alternative you used.

Project-scoped dependencies declared in the repo's own manifests (`requirements.txt` + venv, `package.json` + `npm install`) are normal work and do NOT need permission.

## Red Flags — STOP and Ask

- "It's just one `apt-get install`"
- "I'll quickly add it to the Dockerfile"
- "`sudo` is probably passwordless here"
- "The task is almost done — installing is faster than asking"
- "It's inside a throwaway container, it doesn't matter"

**All of these mean: ask the user first.**
