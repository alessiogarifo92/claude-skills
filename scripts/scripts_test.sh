#!/usr/bin/env bash
# Tests for install.sh, templates/session-start-hook.sh and templates/cloud-setup-script.sh,
# each run against a throwaway HOME — never touches the real ~/.claude. Run: bash scripts/scripts_test.sh
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/scripts-test.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
FAIL=0
check() { # check <desc> <cmd...>
  local desc="$1"; shift
  if "$@" >/dev/null 2>&1; then echo "ok   - $desc"; else echo "FAIL - $desc"; FAIL=1; fi
}
gitc() { git -c user.email=t@t -c user.name=t "$@"; }

# --- install.sh ---
H="$TMP/install"; mkdir -p "$H/skills"
echo "mine" > "$H/skills/api-design"            # a real file the user owns: must survive
CLAUDE_HOME="$H" bash "$ROOT/scripts/install.sh" > "$TMP/i1.out"
check "install links a skill" test "$(readlink "$H/skills/test-verification")" = "$ROOT/test-verification"
check "install links agents" test -L "$H/agents/reviewer.md"
check "install links CLAUDE.md" test "$(readlink "$H/CLAUDE.md")" = "$ROOT/CLAUDE.md"
check "install links the agent guard hook" test "$(readlink "$H/hooks/agent-guard.sh")" = "$ROOT/scripts/agent-guard.sh"
check "install links the careful guard hook" test "$(readlink "$H/hooks/careful-guard.sh")" = "$ROOT/scripts/careful-guard.sh"
check "install never overwrites a real file" grep -qx mine "$H/skills/api-design"
check "install reports the skipped file" grep -q "SKIP $H/skills/api-design" "$TMP/i1.out"
CLAUDE_HOME="$H" bash "$ROOT/scripts/install.sh" > "$TMP/i2.out"
check "install is idempotent (second run links nothing)" bash -c "! grep -q '^linked\|^relinked' '$TMP/i2.out'"

# --- session-start-hook.sh ---
# A fake skills origin + clone, so the hook's fetch/fast-forward runs offline.
O="$TMP/origin"; git init -q -b main "$O"
mkdir -p "$O/scripts" "$O/templates"
cp "$ROOT/scripts/install.sh" "$ROOT/scripts/install-design-skills.sh" "$O/scripts/"
cp "$ROOT/templates/session-start-hook.sh" "$O/templates/"
gitc -C "$O" add . && gitc -C "$O" commit -qm one
C="$TMP/clone"; git clone -q "$O" "$C"
gitc -C "$O" commit -q --allow-empty -m two
HH="$TMP/hookhome"; mkdir -p "$HH"
hook() { HOME="$HH" SKILLS_REPO_DIR="$C" CLAUDE_PROJECT_DIR="$TMP/noproject" HOOK_TIMEOUT=2 \
  DESIGN_SKILLS_DIR="$TMP/design" bash "$ROOT/templates/session-start-hook.sh" "$@" 2>/dev/null; }
out="$(hook)"
check "hook fast-forwards a clean clone" test "$(git -C "$C" rev-parse HEAD)" = "$(git -C "$O" rev-parse HEAD)"
check "hook reports up to date" grep -q "up to date with origin/main" <<<"$out"
check "hook prints the entry skills line" grep -q "^skills entry:" <<<"$out"
gitc -C "$C" commit -q --allow-empty -m local-work
gitc -C "$O" commit -q --allow-empty -m three
out="$(hook)"
check "hook never moves a clone with commits of its own" bash -c "git -C '$C' log -1 --format=%s | grep -qx local-work"
check "hook reports BEHIND" grep -q "BEHIND origin/main by 1" <<<"$out"
mkdir -p "$HH/.claude" "$HH/.claude-skills-repo/templates"
touch "$HH/.claude-skills-repo/templates/session-start-hook.sh"
echo '{"hooks":{"SessionStart":[{"hooks":[{"command":"bash x/templates/session-start-hook.sh"}]}]}}' > "$HH/.claude/settings.json"
check "project entry (--project) stays silent when the user-level entry exists" test -z "$(hook --project)"
check "user-level entry still prints" bash -c "test -n \"\$(HOME='$HH' SKILLS_REPO_DIR='$C' HOOK_TIMEOUT=2 DESIGN_SKILLS_DIR='$TMP/design' bash '$ROOT/templates/session-start-hook.sh' 2>/dev/null)\""

# --- cloud-setup-script.sh ---
setup_home() { # setup_home <dir>: a HOME with its own clone in place (no network) and a settings.json to merge into
  mkdir -p "$1/.claude-skills-repo/.git" "$1/.claude"
  cat > "$1/.claude/settings.json" <<'JSON'
{"theme": "dark", "hooks": {"SessionStart": [
  {"hooks": [{"type": "command", "command": "echo unrelated"}]},
  {"hooks": [{"type": "command", "command": "bash /old/templates/session-start-hook.sh"}]}],
 "PreToolUse": [{"matcher": "Bash", "hooks": [{"type": "command", "command": "bash /old/careful-guard.sh"}]},
  {"matcher": "Edit", "hooks": [{"type": "command", "command": "echo other-pre"}]}]}}
JSON
}
assert_settings() { # assert_settings <home> <label>
  local s="$1/.claude/settings.json"
  check "$2: settings.json still valid JSON" python3 -c "import json; json.load(open('$s'))"
  check "$2: unrelated hook and settings kept" python3 -c "
import json; c=json.load(open('$s')); cmds=[h['command'] for e in c['hooks']['SessionStart'] for h in e['hooks']]
assert c['theme']=='dark' and 'echo unrelated' in cmds"
  check "$2: exactly one session-start-hook entry, the new one" python3 -c "
import json; c=json.load(open('$s')); cmds=[h['command'] for e in c['hooks']['SessionStart'] for h in e['hooks']]
s=[x for x in cmds if 'session-start-hook.sh' in x]; assert len(s)==1 and '/old/' not in s[0]"
  check "$2: exactly one careful-guard entry, on Bash, the new one" python3 -c "
import json; c=json.load(open('$s')); e=[e for e in c['hooks']['PreToolUse'] if any('careful-guard.sh' in h['command'] for h in e['hooks'])]
assert len(e)==1 and e[0]['matcher']=='Bash' and '/old/' not in e[0]['hooks'][0]['command']"
  check "$2: unrelated PreToolUse hook kept" python3 -c "
import json; c=json.load(open('$s')); assert any(h['command']=='echo other-pre' for e in c['hooks']['PreToolUse'] for h in e['hooks'])"
}
run_setup() { HOME="$1" PATH="$2" bash "$ROOT/templates/cloud-setup-script.sh" >/dev/null 2>&1; }
if command -v jq >/dev/null 2>&1; then
  setup_home "$TMP/cs1"; run_setup "$TMP/cs1" "$PATH"; assert_settings "$TMP/cs1" "jq path"
fi
mkdir -p "$TMP/nojq"; printf '#!/bin/sh\nexit 127\n' > "$TMP/nojq/jq"; chmod +x "$TMP/nojq/jq"
setup_home "$TMP/cs2"; run_setup "$TMP/cs2" "$TMP/nojq:$PATH"; assert_settings "$TMP/cs2" "python fallback (jq broken)"
check "setup creates ~/.claude/agents before the session starts" test -d "$TMP/cs2/.claude/agents"

exit $FAIL
