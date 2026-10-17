#!/usr/bin/env bash
# Tests for careful-guard.sh: destructive commands get "ask", everything else falls through. Run: bash scripts/careful-guard_test.sh
set -u
G="$(cd "$(dirname "$0")" && pwd)/careful-guard.sh"
FAIL=0
json() { python3 -c 'import json,sys; print(json.dumps({"tool_name":"Bash","tool_input":{"command":sys.argv[1]}}))' "$1"; }
verdict() { # prints "ask" or "pass"; with $2=raw feeds JSON built without python3-quality escaping
  local out
  out="$(json "$1" | env ${2:-} bash "$G")"
  case "$out" in *'"permissionDecision":"ask"'*) echo ask ;; "") echo pass ;; *) echo "bad:$out" ;; esac
}
expect() { # expect <ask|pass> <command> [env]
  local got; got="$(verdict "$2" "${3:-}")"
  if [ "$got" = "$1" ]; then echo "ok   - $1 <- $2"; else echo "FAIL - expected $1, got $got <- $2"; FAIL=1; fi
}
for c in "rm -rf /" "rm -rf ~" "rm -rf src" "rm -r docs/reports" "rm -fr ./app" "sudo rm -rf /var/lib/mysql" \
         "rm -rf node_modules src" "rm --recursive --force lib" "cd x && rm -rf ." "rm -rf *" \
         "git push --force origin main" "git push -f" "git push --force-with-lease origin feat" "git push origin +main" \
         "git push origin --delete old-branch" "git -C /repo reset --hard origin/main" "git reset --hard" \
         "git clean -fdx" "git branch -D feature" "git stash drop" "git stash clear" \
         "php artisan migrate:fresh --seed" "php artisan db:wipe" "bin/rails db:drop" "rails db:reset" \
         "npx prisma migrate reset --force" "npx prisma db push --force-reset" "python manage.py flush --noinput" \
         "dropdb app_test" "psql -c 'DROP TABLE users'" "mysql -e \"truncate table orders\"" "psql -c 'drop database app'" \
         "docker compose down -v" "docker-compose down --volumes" "docker volume rm app_db" "docker volume prune -f" \
         "docker system prune -af" "gh repo delete o/r --yes" "FOO=1 rm -rf build src"; do
  expect ask "$c"
done
for c in "rm -rf node_modules" "rm -rf dist build .next coverage" "rm -rf ./node_modules/" "rm -rf dist/*" \
         "rm -rf /tmp/x" "rm -rf \"\$TMPDIR/scratch\"" "rm -rf /tmp/claude-0/p/scratchpad/gstack" "rm file.txt" "rm -f a.log" \
         "git push -u origin feat" "git push origin HEAD" "git status" "git reset HEAD~1 --soft" "git reset --soft HEAD~1" \
         "git clean -n" "git branch -d merged" "git stash" "git stash pop" "php artisan migrate" "rails db:migrate" \
         "npx prisma migrate dev" "docker compose down" "docker compose up -d" "grep -r 'drop table' src" \
         "npm test" "pytest -q" "ls -la" "echo force" "gh repo view"; do
  expect pass "$c"
done
# the off switch, and a command with no python3-parsable JSON still decided on the raw text
expect pass "git push --force" "CAREFUL_GUARD_OFF=1"
out="$(printf '{"tool_input":{"command":"git reset --hard"' | bash "$G")"
case "$out" in *ask*) echo "ok   - ask on malformed JSON (raw fallback)";; *) echo "FAIL - malformed JSON fell through"; FAIL=1;; esac
exit $FAIL
