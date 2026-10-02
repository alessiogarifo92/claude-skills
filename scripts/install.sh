#!/usr/bin/env bash
# Link this repo's skills, agents and global CLAUDE.md into ~/.claude (idempotent, never overwrites real files).
# Usage: scripts/install.sh [--dry-run]
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
dest="${CLAUDE_HOME:-$HOME/.claude}"
dry=0; [ "${1:-}" = "--dry-run" ] && dry=1
say() { [ $dry -eq 1 ] || echo "$@"; }
run() { if [ $dry -eq 1 ]; then echo "would: $*"; else "$@"; fi; }
link() { # link <src> <dst>
  if [ -L "$2" ]; then [ "$(readlink "$2")" = "$1" ] && return 0; run ln -sfn "$1" "$2"; say "relinked $2"
  elif [ -e "$2" ]; then echo "SKIP $2 exists and is not a symlink (move it aside to link)"
  else run ln -s "$1" "$2"; say "linked $2"; fi
}
run mkdir -p "$dest/skills" "$dest/agents"
for d in "$repo"/*/SKILL.md; do n="$(basename "$(dirname "$d")")"; link "$repo/$n" "$dest/skills/$n"; done
for a in "$repo"/agents/*.md; do link "$a" "$dest/agents/$(basename "$a")"; done
link "$repo/CLAUDE.md" "$dest/CLAUDE.md"
echo "Done. settings.json is not touched (merge $repo/settings.json by hand if wanted)."
