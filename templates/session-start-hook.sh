#!/usr/bin/env bash
# SessionStart hook for a project's .claude/settings.json (best effort, untested in a cloud container):
# clones the shared skills repo and links it into ~/.claude BEFORE the session registers agents,
# so a fresh container does not need a restart. Never fails the session: it prints what it did.
#
# .claude/settings.json:
#   {"hooks": {"SessionStart": [{"hooks": [{"type": "command", "command": "bash .claude/session-start-hook.sh"}]}]}}
set -u
dest="${SKILLS_REPO_DIR:-$HOME/.claude-skills-repo}"
repo="${SKILLS_REPO_URL:-https://github.com/alessiogarifo92/claude-skills.git}"
if [ ! -d "$dest/.git" ]; then
  git clone --depth 1 "$repo" "$dest" >/dev/null 2>&1 || { echo "claude-skills: clone failed (attach the repo with add_repo instead)"; exit 0; }
else
  git -C "$dest" pull --ff-only -q >/dev/null 2>&1 || true
fi
bash "$dest/scripts/install.sh" >/dev/null 2>&1 && echo "claude-skills: installed into ~/.claude" || echo "claude-skills: install failed"
exit 0
