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
rm -rf .claude/worktrees/orphan2

# --- cleanup: squash-merged branch (not a git ancestor) is still detected via gh ---
# Simulates GitHub's squash-and-merge: the branch's content lands on main as a
# brand-new commit, so `merge-base --is-ancestor` can never see it — this is the
# gap `is_branch_merged()`'s gh-pr fallback exists to close.
SQUASH_BRANCH="worktree-55-squash"
"$SCRIPT" start 55 squash >/dev/null
( cd .claude/worktrees/squash && echo squash-content > s.txt && git add s.txt && git commit -qm squash-work )
echo squash-content > s.txt && git add s.txt && git commit -qm "squash merge simulate (not an ancestor)"
git worktree unlock .claude/worktrees/squash

REAL_GH="$(command -v gh || true)"
FAKE_GH_DIR="$TMP/fakebin"
mkdir -p "$FAKE_GH_DIR"
cat > "$FAKE_GH_DIR/gh" <<EOF
#!/usr/bin/env bash
if [[ "\$1" == "api" && "\$2" == repos/*/pulls\?* ]]; then
  # the script asks REST for closed PRs of this head branch and extracts the merged one's number
  if [[ "\$2" == *"head={owner}:$SQUASH_BRANCH"* ]]; then echo 999; exit 0; fi
  exit 0
fi
exec "$REAL_GH" "\$@"
EOF
chmod +x "$FAKE_GH_DIR/gh"

# Without gh confirming the PR, the branch isn't a literal ancestor — it must survive.
"$SCRIPT" cleanup >/dev/null 2>&1
check "squash-merged worktree survives cleanup without gh PR confirmation" test -d .claude/worktrees/squash

# With the fake gh reporting a merged PR for this branch, cleanup must now remove it.
PATH="$FAKE_GH_DIR:$PATH" "$SCRIPT" cleanup >/dev/null
check "squash-merged worktree removed once gh confirms a merged PR" test ! -d .claude/worktrees/squash
check "squash-merged branch force-deleted" bash -c "! git show-ref -q refs/heads/$SQUASH_BRANCH"

exit $FAIL
