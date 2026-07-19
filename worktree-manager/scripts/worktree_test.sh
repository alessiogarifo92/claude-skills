#!/usr/bin/env bash
# Tests for worktree.sh, run against a throwaway repo — never touches the real repo.
# Run: .claude/scripts/worktree_test.sh   (exit 0 = all ok)
set -euo pipefail

SCRIPT="$(cd "$(dirname "$0")" && pwd -P)/worktree.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/worktree-test.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
FAIL=0

check() { # check <desc> <cmd...>
  local desc="$1"; shift
  if "$@" >/dev/null 2>&1; then echo "ok   - $desc"
  else echo "FAIL - $desc"; FAIL=1; fi
}

cd "$TMP"
git init -q -b main repo
cd repo
REPO="$(pwd -P)"
git config user.email t@t && git config user.name t
echo hi > README.md && git add . && git commit -qm init
printf '.env' > .gitignore   # deliberately no trailing newline

# --- start ---
out="$("$SCRIPT" start 42 my-feature)"
check "start prints worktree path" test "$out" = "$REPO/.claude/worktrees/my-feature"
check "worktree dir exists" test -d .claude/worktrees/my-feature
check "branch name is worktree-42-my-feature" \
  test "$(git -C .claude/worktrees/my-feature symbolic-ref --short HEAD)" = "worktree-42-my-feature"
check "worktree is locked with issue reason" \
  bash -c "git worktree list --porcelain | grep -qx 'locked issue #42'"
check ".claude/worktrees/ added to .gitignore" grep -qx '\.claude/worktrees/' .gitignore
check "existing .gitignore line intact (no-newline append guard)" grep -qx '\.env' .gitignore
check "start refuses duplicate slug" bash -c "! \"$SCRIPT\" start 43 my-feature"
check "start refuses invalid slug" bash -c "! \"$SCRIPT\" start 43 'Bad Slug!'"

# --- list ---
list_out="$("$SCRIPT" list)"
check "list shows slug" grep -q "my-feature" <<<"$list_out"
check "list shows issue number" grep -q "issue #42" <<<"$list_out"
check "list shows lock reason" grep -q "locked: issue #42" <<<"$list_out"

# --- start from inside a linked worktree resolves the main checkout ---
out2="$(cd .claude/worktrees/my-feature && "$SCRIPT" start 7 second)"
check "start from linked worktree lands in main checkout" test "$out2" = "$REPO/.claude/worktrees/second"

# --- cleanup: locked worktree is never removed, even if merged ---
( cd .claude/worktrees/my-feature && echo x > f.txt && git add f.txt && git commit -qm work )
git merge -q worktree-42-my-feature
"$SCRIPT" cleanup >/dev/null 2>&1
check "locked merged worktree is skipped" test -d .claude/worktrees/my-feature

# --- cleanup: merged + unlocked worktree removed, branch deleted ---
git worktree unlock .claude/worktrees/my-feature
"$SCRIPT" cleanup >/dev/null
check "merged worktree removed" test ! -d .claude/worktrees/my-feature
check "merged branch deleted" bash -c "! git show-ref -q refs/heads/worktree-42-my-feature"

# --- cleanup: unmerged worktree survives ---
( cd .claude/worktrees/second && echo y > g.txt && git add g.txt && git commit -qm wip )
"$SCRIPT" cleanup >/dev/null
check "unmerged worktree survives cleanup" test -d .claude/worktrees/second
check "unmerged branch survives cleanup" git show-ref -q refs/heads/worktree-7-second

# --- cleanup: dirty-but-merged (unlocked) worktree is skipped ---
git merge -q worktree-7-second
git worktree unlock .claude/worktrees/second
( cd .claude/worktrees/second && echo z > dirty.txt )
"$SCRIPT" cleanup >/dev/null 2>&1
check "dirty merged worktree is skipped" test -d .claude/worktrees/second
rm .claude/worktrees/second/dirty.txt
"$SCRIPT" cleanup >/dev/null
check "clean merged worktree then removed" test ! -d .claude/worktrees/second

# --- cleanup: orphan dir removed ---
mkdir -p .claude/worktrees/orphan && echo "gitdir: /nowhere" > .claude/worktrees/orphan/.git
"$SCRIPT" cleanup >/dev/null
check "orphan dir removed" test ! -d .claude/worktrees/orphan

# --- cleanup: undeletable orphan warns but does not abort the run ---
mkdir -p .claude/worktrees/stuck/inner && touch .claude/worktrees/stuck/inner/f
chmod 555 .claude/worktrees/stuck/inner
git branch worktree-99-leftover
rc=0; "$SCRIPT" cleanup >/dev/null 2>&1 || rc=$?
check "cleanup exits 0 despite undeletable orphan" test "$rc" -eq 0
check "leftover merged branch still deleted after rm failure" bash -c "! git show-ref -q refs/heads/worktree-99-leftover"
chmod -R u+w .claude/worktrees/stuck && rm -rf .claude/worktrees/stuck

# --- cleanup --dry-run touches nothing ---
mkdir -p .claude/worktrees/orphan2 && echo "gitdir: /nowhere" > .claude/worktrees/orphan2/.git
"$SCRIPT" cleanup --dry-run >/dev/null
check "dry-run leaves orphan in place" test -d .claude/worktrees/orphan2

exit $FAIL
