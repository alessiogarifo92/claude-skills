#!/usr/bin/env bash
# Link the external design skills this repo routes to (project-lifecycle phase 3.5, test-verification's
# design pass) into ~/.claude/skills. Idempotent, never overwrites real files, best effort when offline.
#   - impeccable (pbakaus/impeccable, Apache-2.0): design direction, critique, audit, polish, harden,
#     plus a deterministic anti-pattern detector. Supersedes Anthropic's frontend-design, which it extends.
#   - a subset of emilkowalski/skills (MIT): motion and interaction craft, worst-case-data stress tests.
# Upstream is pinned to a reviewed commit: bump the SHAs below on purpose, after reading the diff.
# Usage: scripts/install-design-skills.sh [--dry-run]
set -euo pipefail
dest="${CLAUDE_HOME:-$HOME/.claude}"
cache="${DESIGN_SKILLS_DIR:-$HOME/.claude-design-skills}"
dry=0; [ "${1:-}" = "--dry-run" ] && dry=1
run() { if [ $dry -eq 1 ]; then echo "would: $*"; else "$@"; fi; }
link() { # link <src> <dst>
  [ -d "$1" ] || { echo "SKIP $1 missing upstream"; return 0; }
  if [ -L "$2" ]; then [ "$(readlink "$2")" = "$1" ] && return 0; run ln -sfn "$1" "$2"; echo "relinked $2"
  elif [ -e "$2" ]; then echo "SKIP $2 exists and is not a symlink (move it aside to link)"
  else run ln -s "$1" "$2"; echo "linked $2"; fi
}
fetch() { # fetch <name> <url> <sha> <subdir>: shallow, sparse checkout of <subdir> at exactly <sha>
  local d="$cache/$1"
  if [ "$(git -C "$d" rev-parse HEAD 2>/dev/null)" = "$3" ]; then return 0; fi
  run mkdir -p "$d"
  [ -d "$d/.git" ] || { run git -C "$d" init -q && run git -C "$d" sparse-checkout set "$4"; }
  run git -C "$d" fetch -q --depth 1 --filter=blob:none "$2" "$3" && run git -C "$d" checkout -q --detach FETCH_HEAD \
    || { echo "design skills: fetch of $1 failed (offline?), keeping what is there"; return 1; }
}

run mkdir -p "$dest/skills"
if fetch impeccable https://github.com/pbakaus/impeccable.git 245ad82def45831dc56a21b683c7a1ff530b06cc plugin/skills/impeccable; then
  link "$cache/impeccable/plugin/skills/impeccable" "$dest/skills/impeccable"
fi
if fetch emil https://github.com/emilkowalski/skills.git 2d228630ba1446365f614a108cb8252f1feda202 skills; then
  # Left out on purpose: prototype (overlaps design / impeccable generate), pick-ui-library, ask-sonner,
  # write-swift, animation-vocabulary, apple-design, find-/improve-animations (audit-scale, rarely needed).
  for s in emil-design-eng animate animate-expo animation-performance review-animations break-ui mobile-native; do
    link "$cache/emil/skills/$s" "$dest/skills/$s"
  done
fi
