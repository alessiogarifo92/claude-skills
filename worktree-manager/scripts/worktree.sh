#!/usr/bin/env bash
# Global per-ticket worktree manager — same convention across every project
# (branch/path naming, label handling); languages/stack differ per repo, this
# doesn't. Resolves the current repo dynamically, so it works from inside any
# git repo without per-project copies.
#
#   start <issue> [slug]  create + lock .claude/worktrees/<slug> on branch worktree-<issue>-<slug>,
#                          apply the "in progress" label to the issue
#   list                  active worktrees with their issue and lock state, plus orphan directories
#   cleanup [--dry-run]   remove orphan dirs and merged worktrees/branches (never unmerged work;
#                          "merged" includes squash/rebase merges, detected via a merged GitHub PR
#                          when the branch isn't a literal git ancestor)
set -euo pipefail

die() { echo "worktree.sh: $*" >&2; exit 1; }

# Resolve the main checkout even when called from inside a linked worktree.
COMMON="$(git rev-parse --git-common-dir 2>/dev/null)" || die "not in a git repository"
COMMON="$(cd "$COMMON" && pwd -P)"
ROOT="$(dirname "$COMMON")"
WT_DIR="$ROOT/.claude/worktrees"
DEFAULT_BRANCH="main"

ensure_ignored() {
  grep -qxF '.claude/worktrees/' "$ROOT/.gitignore" 2>/dev/null || {
    # Guard against a .gitignore whose last line has no trailing newline.
    [[ -s "$ROOT/.gitignore" && -n "$(tail -c1 "$ROOT/.gitignore")" ]] && printf '\n' >> "$ROOT/.gitignore"
    printf '.claude/worktrees/\n' >> "$ROOT/.gitignore"
    echo "note: added .claude/worktrees/ to .gitignore (commit it)" >&2
  }
}

slug_from_issue() {
  gh issue view "$1" --json title -q .title 2>/dev/null \
    | tr '[:upper:]' '[:lower:]' | sed -e 's/[^a-z0-9]\{1,\}/-/g' -e 's/^-//' \
    | cut -c1-40 | sed 's/-$//'
}

registered_paths() { # absolute paths of linked worktrees under WT_DIR
  git -C "$ROOT" worktree list --porcelain | sed -n 's/^worktree //p' | grep -F "$WT_DIR/" || true
}

# Applies the "in progress" label at pickup time (creating the label first if the
# repo doesn't have it yet). Non-fatal on failure — a label/gh hiccup should never
# block getting the worktree itself, but it must never be silently skipped either.
mark_in_progress() {
  local issue="$1"
  gh label list 2>/dev/null | grep -qF $'in progress\t' \
    || gh label create "in progress" --color fbca04 --description "Actively being worked on" >&2 \
    || { echo "warn: could not create 'in progress' label — add it manually: gh issue edit $issue --add-label 'in progress'" >&2; return; }
  gh issue edit "$issue" --add-label "in progress" >&2 \
    || echo "warn: could not label issue #$issue in progress — add it manually: gh issue edit $issue --add-label 'in progress'" >&2
}

lock_reason() { # lock_reason <path> — prints the lock reason, empty if unlocked
  git -C "$ROOT" worktree list --porcelain \
    | awk -v p="worktree $1" '$0 == p {f=1; next} f && /^locked/ {sub(/^locked ?/, ""); print; exit} f && /^$/ {exit}'
}

# is_branch_merged <branch> — true if branch is already incorporated into
# DEFAULT_BRANCH. A regular/fast-forward merge makes branch a literal ancestor,
# which `merge-base --is-ancestor` sees directly. A squash or rebase merge does
# NOT: GitHub replays the diff as a brand-new commit with different parents, so
# the original branch tip is never an ancestor of DEFAULT_BRANCH even though its
# content is fully in there. For that case, fall back to asking GitHub whether a
# PR with this branch as head was merged — any gh failure (no remote, not
# authenticated, no such PR) just means "not merged this way", not an abort.
is_branch_merged() {
  local branch="$1"
  git -C "$ROOT" merge-base --is-ancestor "$branch" "$DEFAULT_BRANCH" && return 0
  local merged_pr
  merged_pr="$(cd "$ROOT" && gh pr list --head "$branch" --state merged --json number -q '.[0].number' 2>/dev/null)" || return 1
  [[ -n "$merged_pr" ]]
}

# delete_branch_if_merged <branch> — assumes is_branch_merged already returned
# true for it. `git branch -d` (safe delete) works and is preferred when branch
# is a literal ancestor. When it isn't (squash/rebase merge, confirmed only via
# a merged GitHub PR above) `-d` refuses because git genuinely can't see it as
# merged — force-delete with `-D` there, since the merge was independently
# verified through GitHub rather than guessed from local history.
delete_branch_if_merged() {
  local branch="$1"
  if git -C "$ROOT" merge-base --is-ancestor "$branch" "$DEFAULT_BRANCH"; then
    run git -C "$ROOT" branch -d "$branch" || echo "skip: could not delete branch $branch" >&2
  else
    echo "note: $branch isn't a literal ancestor of $DEFAULT_BRANCH (squash/rebase merge) — verified merged via a GitHub PR, force-deleting" >&2
    run git -C "$ROOT" branch -D "$branch" || echo "skip: could not delete branch $branch" >&2
  fi
}

cmd_start() {
  local issue="${1:-}" slug="${2:-}"
  [[ "$issue" =~ ^[0-9]+$ ]] || die "usage: worktree.sh start <issue-number> [slug]"
  if [[ -z "$slug" ]]; then
    slug="$(slug_from_issue "$issue")"
    [[ -n "$slug" ]] || die "could not derive slug from issue #$issue (is gh authenticated?); pass one: worktree.sh start $issue <slug>"
  fi
  [[ "$slug" =~ ^[a-z0-9][a-z0-9-]*$ ]] || die "invalid slug '$slug' (lowercase letters, digits, dashes)"
  local branch="worktree-${issue}-${slug}"
  local path="$WT_DIR/$slug"
  [[ -e "$path" ]] && die "path already exists: $path (another session owns this slug — pick a different one)"
  git -C "$ROOT" show-ref -q "refs/heads/$branch" && die "branch already exists: $branch"
  ensure_ignored
  mkdir -p "$WT_DIR"
  git -C "$ROOT" worktree add "$path" -b "$branch" >&2
  git -C "$ROOT" worktree lock "$path" --reason "issue #$issue"
  mark_in_progress "$issue"
  echo "$path"
}

cmd_list() {
  local path branch issue reason
  while read -r path; do
    [[ -n "$path" ]] || continue
    branch="$(git -C "$path" symbolic-ref --short -q HEAD || echo 'detached')"
    issue="?"
    [[ "$branch" =~ ^worktree-([0-9]+)- ]] && issue="${BASH_REMATCH[1]}"
    reason="$(lock_reason "$path")"
    printf '%-28s %-42s issue #%-5s %s\n' "$(basename "$path")" "$branch" "$issue" "${reason:+locked: $reason}"
  done < <(registered_paths)
  local d
  for d in "$WT_DIR"/*/; do
    [[ -d "$d" ]] || continue
    registered_paths | grep -qxF "${d%/}" \
      || printf '%-28s %s\n' "$(basename "$d")" "ORPHAN (not a registered worktree — run cleanup)"
  done
}

cmd_cleanup() {
  local dry=""
  [[ "${1:-}" == "--dry-run" ]] && dry=1
  run() { if [[ -n "$dry" ]]; then echo "[dry-run] $*"; else "$@"; fi; }

  [[ -n "$dry" ]] || git -C "$ROOT" worktree prune

  # 1) Registered worktrees whose branch is fully merged into DEFAULT_BRANCH
  local path branch
  while read -r path; do
    [[ -n "$path" ]] || continue
    branch="$(git -C "$path" symbolic-ref --short -q HEAD || true)"
    [[ -n "$branch" && "$branch" != "$DEFAULT_BRANCH" ]] || continue
    if is_branch_merged "$branch"; then
      # A lock means a session owns this worktree (a fresh branch with no commits
      # of its own also counts as "merged" — never yank it from under a session).
      local reason
      reason="$(lock_reason "$path")"
      if [[ -n "$reason" ]]; then
        echo "skip: $path is locked ($reason) — 'git worktree unlock' it first if its work is done" >&2
        continue
      fi
      if [[ -n "$(git -C "$path" status --porcelain)" ]]; then
        echo "skip: $path is merged but has uncommitted changes" >&2
        continue
      fi
      echo "removing merged worktree $(basename "$path") ($branch)"
      echo "  reminder: if a running stack was swapped to serve this worktree, point it back at $DEFAULT_BRANCH first — the path is about to disappear" >&2
      run git -C "$ROOT" worktree remove "$path" || { echo "skip: could not remove $path" >&2; continue; }
      delete_branch_if_merged "$branch"
    fi
  done < <(registered_paths)

  # 2) Orphan directories under WT_DIR (present on disk, unknown to git)
  local d
  for d in "$WT_DIR"/*/; do
    [[ -d "$d" ]] || continue
    registered_paths | grep -qxF "${d%/}" && continue
    echo "removing orphan directory ${d%/}"
    # Keep going on failure (e.g. root-owned files left behind by Docker builds).
    run rm -rf "${d%/}" \
      || echo "warn: could not fully remove ${d%/} — check ownership (files created inside Docker may need sudo)" >&2
  done

  # 3) Leftover convention branches already merged, with no worktree attached.
  # Iterate every worktree-* branch (not just what `git branch --merged` reports)
  # since that native filter has the same blind spot for squash/rebase merges
  # that is_branch_merged() exists to cover.
  while read -r branch; do
    [[ -n "$branch" ]] || continue
    git -C "$ROOT" worktree list --porcelain | grep -qx "branch refs/heads/$branch" && continue
    is_branch_merged "$branch" || continue
    echo "deleting merged branch $branch"
    delete_branch_if_merged "$branch"
  done < <(git -C "$ROOT" branch --format='%(refname:short)' | grep '^worktree-' || true)
}

case "${1:-}" in
  start)   shift; cmd_start "$@" ;;
  list)    shift; cmd_list "$@" ;;
  cleanup) shift; cmd_cleanup "$@" ;;
  *) die "usage: worktree.sh {start <issue> [slug] | list | cleanup [--dry-run]}" ;;
esac
