#!/usr/bin/env bash
# Tests for agent-guard.sh: blocked git/gh writes, allowed reads. Run: bash scripts/agent-guard_test.sh
set -u
G="$(cd "$(dirname "$0")" && pwd)/agent-guard.sh"
FAIL=0
run() { printf '{"tool_name":"Bash","tool_input":{"command":"%s"}}' "$1" | bash "$G" 2>/dev/null; echo $?; }
expect() { # expect <0|2> <command>
  local got; got="$(run "$2")"
  if [ "$got" = "$1" ]; then echo "ok   - $1 <- $2"; else echo "FAIL - expected $1, got $got <- $2"; FAIL=1; fi
}
for c in "git commit -m x" "git push origin main" "git -C /repo reset --hard" "npm test && git commit -am wip" \
         "git checkout -- a.txt" "git switch -c x" "git branch -D old" "git branch --delete old" "git stash" \
         "git worktree remove .claude/worktrees/x" "git tag v1" "git rebase main" "git pull" \
         "gh pr merge 3 --squash" "gh issue close 4" "gh pr create --fill" "gh api -X POST repos/o/r/issues/1/labels" \
         "gh api --method DELETE repos/o/r/git/refs/heads/x" "gh repo edit --delete-branch-on-merge" "gh release create v1"; do
  expect 2 "$c"
done
for c in "git status" "git log --oneline -5" "git diff --stat" "git show HEAD:README.md" "git branch -a" \
         "git branch --contains abc" "git worktree list" "git log --grep commit" "git rev-parse HEAD" \
         "gh api repos/o/r/issues --jq .[].number" "gh pr view 3" "npm test" "pytest -q" "rg reset src" \
         "ls .git/refs" "digit commit"; do
  expect 0 "$c"
done
exit $FAIL
