#!/usr/bin/env bash
# Cloud environment setup script: paste into claude.ai -> the environment's settings -> Setup script.
# It runs once per container, before Claude Code starts, whatever repos the session has.
# Project hooks (`<project>/.claude/settings.json`) only load for the session's primary directory, so in a
# multi-repo session they may not run at all; this registers the SessionStart hook at user level instead,
# so every session updates and installs the skills before the first turn, with or without claude-skills attached.
# Best effort: never fails the container. Safe to re-run: re-pasting a newer version replaces the old hook entry.
# It also registers scripts/careful-guard.sh (PreToolUse, Bash): destructive commands ask for confirmation even in auto mode.
t() { timeout 60 "$@"; }
mkdir -p "$HOME/.claude/skills" "$HOME/.claude/agents"   # agents/ must exist at session start to be detected

# A clone of our own, so sessions without claude-skills attached still get it (the repo is public).
own="$HOME/.claude-skills-repo"
[ -d "$own/.git" ] || t git clone -q https://github.com/alessiogarifo92/claude-skills.git "$own" 2>/dev/null || true

# The hook runs whichever copy exists, preferring an attached one; session-start-hook.sh itself picks the
# same clone (same search order), fast-forwards it and re-runs install.sh.
cmd='for f in /home/user/claude-skills/templates/session-start-hook.sh "$HOME/claude-skills/templates/session-start-hook.sh" "$HOME/.claude-skills-repo/templates/session-start-hook.sh"; do [ -f "$f" ] && exec bash "$f"; done; echo "claude-skills: NOT INSTALLED (no clone found). Attach it (add_repo) and run scripts/install.sh before any work, and say so in visible text."'
guard='f="$HOME/.claude/hooks/careful-guard.sh"; [ -f "$f" ] && exec bash "$f"; exit 0'
s="$HOME/.claude/settings.json"
[ -s "$s" ] || echo '{}' > "$s"
# Replace any earlier session-start-hook / careful-guard entry with this one, keep every other hook: jq, else python3.
if ! { command -v jq >/dev/null 2>&1 && jq --arg c "$cmd" --arg g "$guard" '
    .hooks.SessionStart = ([.hooks.SessionStart[]? | select(([.hooks[]?.command] | map(contains("session-start-hook.sh")) | any) | not)]
                           + [{"hooks": [{"type": "command", "command": $c}]}])
    | .hooks.PreToolUse = ([.hooks.PreToolUse[]? | select(([.hooks[]?.command] | map(contains("careful-guard.sh")) | any) | not)]
                           + [{"matcher": "Bash", "hooks": [{"type": "command", "command": $g}]}])' "$s" > "$s.tmp" && mv "$s.tmp" "$s"; }; then
  rm -f "$s.tmp"
  python3 - "$s" "$cmd" "$guard" <<'PY' 2>/dev/null || echo "claude-skills setup: could not register the SessionStart and careful-guard hooks (no jq, no python3): sessions will not auto-update the skills" >&2
import json, sys
path, cmd, guard = sys.argv[1], sys.argv[2], sys.argv[3]
cfg = json.load(open(path))
hooks = cfg.setdefault("hooks", {})
def keep(event, marker):
    return [e for e in hooks.get(event, []) if not any(marker in h.get("command", "") for h in e.get("hooks", []))]
hooks["SessionStart"] = keep("SessionStart", "session-start-hook.sh") + [{"hooks": [{"type": "command", "command": cmd}]}]
hooks["PreToolUse"] = keep("PreToolUse", "careful-guard.sh") + [{"matcher": "Bash", "hooks": [{"type": "command", "command": guard}]}]
json.dump(cfg, open(path, "w"), indent=2)
PY
fi
for d in /home/user/claude-skills "$HOME/claude-skills" "$own"; do
  [ -f "$d/scripts/install.sh" ] && { bash "$d/scripts/install.sh" >/dev/null 2>&1; t bash "$d/scripts/install-design-skills.sh" >/dev/null 2>&1; break; }
done
exit 0
