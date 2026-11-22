#!/usr/bin/env bash
# Tests for model-guard.sh: child sessions that may write code must be opened on opus. Run: bash scripts/model-guard_test.sh
set -u
G="$(cd "$(dirname "$0")" && pwd)/model-guard.sh"
FAIL=0
verdict() { # verdict <tool_name> <model|-> <prompt> [env]
  local out
  out="$(python3 -c 'import json,sys
ti={"prompt":sys.argv[3]}
if sys.argv[2]!="-": ti["model"]=sys.argv[2]
print(json.dumps({"tool_name":sys.argv[1],"tool_input":ti}))' "$1" "$2" "$3" | env ${4:-} bash "$G")"
  case "$out" in *'"permissionDecision": "deny"'*) echo deny ;; "") echo pass ;; *) echo "bad:$out" ;; esac
}
expect() { # expect <deny|pass> <label> <tool_name> <model|-> <prompt> [env]
  local got; got="$(verdict "$3" "$4" "$5" "${6:-}")"
  if [ "$got" = "$1" ]; then echo "ok   - $1 <- $2"; else echo "FAIL - expected $1, got $got <- $2"; FAIL=1; fi
}
T=mcp__claude-code-remote__create_session
expect deny "no model"                         $T -                  "Ticket #99 meccanica"
expect deny "empty model"                      $T ""                 "Ticket #99 meccanica"
expect deny "sonnet on a code ticket"          $T claude-sonnet-5-5  "Ticket da implementare: #99 corsie cieche"
expect deny "haiku on a code ticket"           $T claude-haiku-5-5   "Stage 31 livelli"
expect pass "opus"                             $T claude-opus-5-5    "Ticket da implementare: #99"
expect pass "opus alias, any case"             $T Opus               "x"
expect pass "sonnet declared code-free"        $T claude-sonnet-5-5  $'Playtest stage 30.\nSESSIONE SENZA CODICE: non modificare codice.'
expect pass "marker is case-insensitive"       $T claude-sonnet-5-5  "sessione senza codice — ricerca"
expect pass "other tool ignored"               Bash claude-sonnet-5-5 "x"
expect pass "off switch"                       $T claude-sonnet-5-5  "codice" MODEL_GUARD_OFF=1
expect pass "custom code models"               $T claude-fable-5-2   "x" "MODEL_GUARD_CODE_MODELS=opus|fable"
got="$(printf 'not json' | bash "$G")"
if [ -z "$got" ]; then echo "ok   - pass <- unreadable input fails open"; else echo "FAIL - unreadable input: $got"; FAIL=1; fi
reason="$(python3 -c 'import json; print(json.dumps({"tool_name":"mcp__claude-code-remote__create_session","tool_input":{"model":"claude-sonnet-5-5","prompt":"x"}}))' | bash "$G")"
if grep -q 'claude-opus-5-5' <<<"$reason" && grep -q 'SESSIONE SENZA CODICE' <<<"$reason"; then echo "ok   - deny reason names the fix"; else echo "FAIL - deny reason: $reason"; FAIL=1; fi
[ $FAIL -eq 0 ] && echo "all passed" || { echo "SOME FAILED"; exit 1; }
