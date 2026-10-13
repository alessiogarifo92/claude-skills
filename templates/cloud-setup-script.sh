#!/usr/bin/env bash
# Cloud environment setup script: paste into claude.ai -> the environment's settings -> Setup script.
# It runs once per container, before Claude Code starts, whatever repos the session has.
# Project hooks (`<project>/.claude/settings.json`) only load for the session's primary directory, so in a
# multi-repo session they may not run at all; this registers the SessionStart hook at user level instead,
# so every session that has claude-skills attached updates and installs it before the first turn.
# Best effort: never fails the container.
mkdir -p "$HOME/.claude/skills" "$HOME/.claude/agents"   # agents/ must exist at session start to be detected
cmd='for f in /home/user/claude-skills/templates/session-start-hook.sh "$HOME/claude-skills/templates/session-start-hook.sh"; do [ -f "$f" ] && exec bash "$f"; done; echo "claude-skills: NOT ATTACHED. Attach it (add_repo) and run scripts/install.sh before any work, and say so in visible text."'
s="$HOME/.claude/settings.json"
[ -s "$s" ] || echo '{}' > "$s"
if command -v jq >/dev/null 2>&1 && ! grep -q 'session-start-hook.sh' "$s"; then
  jq --arg c "$cmd" '.hooks.SessionStart += [{"hooks": [{"type": "command", "command": $c}]}]' "$s" > "$s.tmp" && mv "$s.tmp" "$s"
fi
for d in /home/user/claude-skills "$HOME/claude-skills"; do
  [ -f "$d/scripts/install.sh" ] && { bash "$d/scripts/install.sh" >/dev/null 2>&1; break; }
done
exit 0
