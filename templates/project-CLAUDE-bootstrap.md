## Bootstrap: load the shared skills repo (do this before any work)

This project relies on the private repo `alessiogarifo92/claude-skills` (skills, agents, global rules). A remote session (Claude Code on the web, a cloud container, a GitHub Action) does not have `~/.claude/`, so without this step none of those rules apply.

1. Attach it: `mcp__claude-code-remote__add_repo` with `owner=alessiogarifo92`, `repo=claude-skills` (access `read`), run the clone command it returns, then `register_repo_root`.
2. Read its `CLAUDE.md` and `README.md`; link or copy `skills/*` and `agents/*` as described there (`scripts/install.sh` does it on a machine with a writable `~/.claude`).
3. For a multi-stage goal ("build this", "take it from here") invoke the `autonomous-workflow` skill first; for a single ticket, `product-ownership`.
4. If the attach fails, say so in visible text and ask the user how to proceed. Never continue silently without the rules.

Needed environment variables / connectors for this project: <list them here; document every variable `.mcp.json` expects>.
