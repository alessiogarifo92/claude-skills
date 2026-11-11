#!/usr/bin/env bash
# Cloud environment setup script: paste into claude.ai -> the environment's settings -> Setup script.
# It runs once per container, before Claude Code starts, whatever repos the session has.
# Project hooks (`<project>/.claude/settings.json`) only load for the session's primary directory, so in a
# multi-repo session they may not run at all; this registers the SessionStart hook at user level instead,
# so every session updates and installs the skills before the first turn, with or without claude-skills attached.
# Best effort: never fails the container. Safe to re-run: re-pasting a newer version replaces the old hook entry.
# It also registers scripts/careful-guard.sh (PreToolUse, Bash): destructive commands ask for confirmation even in auto mode,
# and sets promptSuggestionEnabled: true (prompt suggestions stay on in every cloud session).
# Usage limits: autoContinueAtUsageLimit only waits in an interactive local terminal, so a cloud session hitting a
# claude.ai limit just stops. env CLAUDE_CODE_RETRY_WATCHDOG=1 makes the request wait out the limit and go on after
# the reset (re-checked every _USAGE_LIMIT_RECHECK_MS, here 5 min); CLAUDE_CODE_AUTO_COMPACT_WINDOW=400000 compacts
# around 360K tokens (200K was too tight: "Your context window is full"). The SessionStart hook also turns off
# claude.ai plugin sync and denies unused connectors (templates/lean-context.json); this script does the same
# (deny list inline, kept equal to that file by scripts_test.sh), because MCP servers and plugins load when Claude
# starts: written by the hook they would apply only from the next session, which a fresh cloud container never has.
# Other env keys and denied servers are kept.
t() { timeout 60 "$@"; }
mkdir -p "$HOME/.claude/skills" "$HOME/.claude/agents"   # agents/ must exist at session start to be detected

# A clone of our own, so sessions without claude-skills attached still get it (the repo is public).
own="$HOME/.claude-skills-repo"
[ -d "$own/.git" ] || t git clone -q https://github.com/alessiogarifo92/claude-skills.git "$own" 2>/dev/null || true

# The hook runs whichever copy exists, preferring an attached one; session-start-hook.sh itself picks the
# same clone (same search order), fast-forwards it and re-runs install.sh.
cmd='for f in /home/user/claude-skills/templates/session-start-hook.sh "$HOME/claude-skills/templates/session-start-hook.sh"'
cmd="$cmd"' "$HOME/.claude-skills-repo/templates/session-start-hook.sh"; do [ -f "$f" ] && exec bash "$f"; done;'
cmd="$cmd"' echo "claude-skills: NOT INSTALLED (no clone found). Attach it (add_repo) and run scripts/install.sh'
cmd="$cmd"' before any work, and say so in visible text."'
# same string as the project entry: Claude Code runs an identical handler once
guard='for f in "$HOME/.claude/hooks/careful-guard.sh" /home/user/claude-skills/scripts/careful-guard.sh'
guard="$guard"' "$HOME/claude-skills/scripts/careful-guard.sh" "$HOME/.claude-skills-repo/scripts/careful-guard.sh";'
guard="$guard"' do [ -f "$f" ] && exec bash "$f"; done; exit 0'
deny='["Booking.com", "claude.ai Booking.com", "eDreams", "claude.ai eDreams", "Gmail", "claude.ai Gmail",
 "Google Compute Engine", "claude.ai Google Compute Engine", "Postman", "claude.ai Postman",
 "Cloudflare Developer Platform", "claude.ai Cloudflare Developer Platform", "Booking_com", "claude.ai Booking_com",
 "Google_Compute_Engine", "claude.ai Google_Compute_Engine",
 "Cloudflare_Developer_Platform", "claude.ai Cloudflare_Developer_Platform"]'
# Sessions opened with create_session get claude.ai connectors named by their account ID (a UUID), not by name:
# list those IDs here, in the environment's own copy only (they identify the user's account; never commit them).
deny_extra='[]'
deny="$(jq -nc --argjson a "$deny" --argjson b "$deny_extra" '$a + $b' 2>/dev/null || echo "$deny")"
s="$HOME/.claude/settings.json"
[ -s "$s" ] || echo '{}' > "$s"
# Replace any earlier session-start-hook / careful-guard entry with this one, keep every other hook: jq, else python3.
if ! { command -v jq >/dev/null 2>&1 && jq --arg c "$cmd" --arg g "$guard" --argjson d "$deny" '
    .hooks.SessionStart = ([.hooks.SessionStart[]? | select(([.hooks[]?.command] | map(contains("session-start-hook.sh")) | any) | not)]
                           + [{"hooks": [{"type": "command", "command": $c}]}])
    | .hooks.PreToolUse = ([.hooks.PreToolUse[]? | select(([.hooks[]?.command] | map(contains("careful-guard.sh")) | any) | not)]
                           + [{"matcher": "Bash", "hooks": [{"type": "command", "command": $g}]}])
    | .promptSuggestionEnabled = true | .autoContinueAtUsageLimit = true
    | .env = ((.env // {}) + {"CLAUDE_CODE_AUTO_COMPACT_WINDOW": "400000", "CLAUDE_CODE_RETRY_WATCHDOG": "1", "CLAUDE_CODE_RETRY_WATCHDOG_USAGE_LIMIT_RECHECK_MS": "300000"})
    | .syncClaudeAiPlugins = false
    | .deniedMcpServers = ((.deniedMcpServers // []) + ($d - [.deniedMcpServers[]?.serverName] | map({serverName: .})))' "$s" > "$s.tmp" && mv "$s.tmp" "$s"; }; then
  rm -f "$s.tmp"
  err="claude-skills setup: could not register the SessionStart and careful-guard hooks (no jq, no python3)"
  python3 - "$s" "$cmd" "$guard" "$deny" <<'PY' 2>/dev/null || echo "$err: sessions will not auto-update the skills" >&2
import json, sys
path, cmd, guard, deny = sys.argv[1], sys.argv[2], sys.argv[3], json.loads(sys.argv[4])
cfg = json.load(open(path))
hooks = cfg.setdefault("hooks", {})
def keep(event, marker):
    return [e for e in hooks.get(event, []) if not any(marker in h.get("command", "") for h in e.get("hooks", []))]
hooks["SessionStart"] = keep("SessionStart", "session-start-hook.sh") + [{"hooks": [{"type": "command", "command": cmd}]}]
hooks["PreToolUse"] = keep("PreToolUse", "careful-guard.sh") + [{"matcher": "Bash", "hooks": [{"type": "command", "command": guard}]}]
cfg["promptSuggestionEnabled"] = True
cfg["autoContinueAtUsageLimit"] = True
cfg.setdefault("env", {}).update({"CLAUDE_CODE_AUTO_COMPACT_WINDOW": "400000", "CLAUDE_CODE_RETRY_WATCHDOG": "1", "CLAUDE_CODE_RETRY_WATCHDOG_USAGE_LIMIT_RECHECK_MS": "300000"})
cfg["syncClaudeAiPlugins"] = False
have = [e.get("serverName") for e in cfg.setdefault("deniedMcpServers", [])]
cfg["deniedMcpServers"] += [{"serverName": n} for n in deny if n not in have]
json.dump(cfg, open(path, "w"), indent=2)
PY
fi
for d in /home/user/claude-skills "$HOME/claude-skills" "$own"; do
  [ -f "$d/scripts/install.sh" ] && { bash "$d/scripts/install.sh" >/dev/null 2>&1; t bash "$d/scripts/install-design-skills.sh" >/dev/null 2>&1; break; }
done
exit 0
