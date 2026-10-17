#!/usr/bin/env bash
# PreToolUse hook (matcher Bash) for the MAIN session, installed by install.sh as ~/.claude/hooks/careful-guard.sh
# and registered at user level by templates/cloud-setup-script.sh (locally: merge settings.json by hand).
# The destructive operations that autonomous-workflow and CLAUDE.md call hard gates (force-push, history resets,
# recursive deletes, DB wipes, volume removal) were prose only; this answers "ask" for them, which forces a
# permission prompt even in auto mode (and is denied, with the reason shown to Claude, in a -p run nobody watches).
# It never blocks outright and never approves: everything else falls through to the normal permission flow.
# Off switch for a session that genuinely needs it: CAREFUL_GUARD_OFF=1 in the environment.
set -u
input="$(cat)"
[ "${CAREFUL_GUARD_OFF:-}" = "1" ] && exit 0

# The command itself; without python3, the raw JSON (words stay intact, escaped quotes are stripped below).
cmd="$(python3 -c 'import json,sys; print(json.load(sys.stdin).get("tool_input",{}).get("command",""))' <<<"$input" 2>/dev/null)" || cmd="$input"
[ -n "$cmd" ] || cmd="$input"

ask() {
  local reason="careful-guard: $1 is a destructive operation (a hard gate). Confirm only if you asked for it; on a shared database first check that no other ticket is 'in progress'."
  reason="${reason//\\/\\\\}"; reason="${reason//\"/\\\"}"
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"%s"}}\n' "$reason"
  exit 0
}

# Paths a recursive delete may remove without asking: build output, caches, dependency dirs, temp/scratch space.
safe_path() {
  local p="${1%/}"; p="${p%/\*}"; p="${p#./}"
  case "$p" in
    /tmp/?*|/var/tmp/?*|\$TMPDIR/?*|\$\{TMPDIR\}/?*|\$TMP|\$TMP/*|\$TMPDIR|*/scratchpad/*|*/scratchpad) return 0 ;;
  esac
  case "${p##*/}" in
    node_modules|dist|build|out|.next|.nuxt|.output|.svelte-kit|coverage|.cache|__pycache__|.pytest_cache|.mypy_cache|.ruff_cache|.turbo|.parcel-cache|.expo|target|tmp|.tmp) return 0 ;;
  esac
  return 1
}

check_rm() { # check_rm <segment words...>
  local recursive=0 a; local -a targets=()
  for a in "$@"; do
    case "$a" in
      --recursive) recursive=1 ;;
      --*) ;;
      -*) [[ "$a" == *[rR]* ]] && recursive=1 ;;
      *) targets+=("$a") ;;
    esac
  done
  [ $recursive -eq 1 ] || return 0
  [ ${#targets[@]} -gt 0 ] || return 0
  for a in "${targets[@]}"; do safe_path "$a" || ask "rm -r $a"; done
}

# A command word starts at the line start or after a non-word char (also ':' in the raw-JSON fallback).
B='(^|[^[:alnum:]_.-])'
sql_client="${B}(psql|mysql|mariadb|sqlite3|sqlcmd|mongosh|clickhouse-client|duckdb)[[:space:]]"

# One segment per simple command: split on ; && || | and newlines.
segments="$(printf '%s\n' "$cmd" | tr -d '\\' | sed -E 's/(\&\&|\|\||;|\|)/\n/g')"
while IFS= read -r seg; do
  # strip quotes, leading env assignments and sudo
  seg="${seg//\"/}"; seg="${seg//\'/}"
  seg="$(sed -E 's/^[[:space:]]*(([A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+)*)(sudo[[:space:]]+)?//' <<<"$seg")"
  [ -n "$seg" ] || continue
  read -r -a w <<<"$seg"
  case "${w[0]:-}" in
    rm) check_rm "${w[@]:1}" ;;
  esac
  s=" $seg "
  if [[ "$s" =~ ${B}git[[:space:]].*push[[:space:]] ]] && [[ "$s" =~ [[:space:]](-f|--force|--force-with-lease[^[:space:]]*|--force-if-includes|--mirror|--delete|-d|\+[^[:space:]]+)[[:space:]] ]]; then ask "git push (force/delete)"; fi
  [[ "$s" =~ ${B}git[[:space:]].*reset[[:space:]].*--hard ]] && ask "git reset --hard"
  [[ "$s" =~ ${B}git[[:space:]].*clean[[:space:]]+(-[a-zA-Z]*f|--force) ]] && ask "git clean -f"
  [[ "$s" =~ ${B}git[[:space:]].*branch[[:space:]].*(-D[[:space:]]|--delete[[:space:]].*--force|--force[[:space:]].*--delete) ]] && ask "git branch -D"
  [[ "$s" =~ ${B}git[[:space:]].*stash[[:space:]]+(drop|clear) ]] && ask "git stash drop/clear"
  [[ "$s" =~ (migrate:(fresh|reset|refresh)|db:(wipe|drop|reset|schema:load)|schema:drop)[[:space:]] ]] && ask "a database reset/wipe"
  [[ "$s" =~ ${B}prisma[[:space:]]+migrate[[:space:]]+reset|--force-reset|${B}manage\.py[[:space:]]+flush|${B}dropdb[[:space:]] ]] && ask "a database reset/wipe"
  shopt -s nocasematch
  [[ "$s" =~ $sql_client ]] && [[ "$s" =~ (drop[[:space:]]+(table|database|schema)|truncate[[:space:]]+(table[[:space:]]+)?[a-z_\"\`]) ]] && { shopt -u nocasematch; ask "SQL DROP/TRUNCATE"; }
  shopt -u nocasematch
  [[ "$s" =~ ${B}docker[[:space:]].*(compose[[:space:]].*down[[:space:]].*(-v|--volumes)[[:space:]]|volume[[:space:]]+(rm|prune)|system[[:space:]]+prune) ]] && ask "removing Docker volumes/data"
  [[ "$s" =~ ${B}docker-compose[[:space:]].*down[[:space:]].*(-v|--volumes)[[:space:]] ]] && ask "removing Docker volumes/data"
  [[ "$s" =~ ${B}gh[[:space:]]+repo[[:space:]]+delete ]] && ask "gh repo delete"
done <<<"$segments"
exit 0
