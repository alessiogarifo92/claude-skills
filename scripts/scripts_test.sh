#!/usr/bin/env bash
# Tests for install.sh, templates/session-start-hook.sh, templates/cloud-setup-script.sh and templates/release-workflow.yml,
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
check "install links the model guard hook" test "$(readlink "$H/hooks/model-guard.sh")" = "$ROOT/scripts/model-guard.sh"
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
check "hook warns when careful-guard is not registered" grep -q "^careful-guard: NOT REGISTERED" <<<"$out"
check "hook warns when model-guard is not registered" grep -q "^model-guard: NOT REGISTERED" <<<"$out"
mkdir -p "$HH/.claude" && echo '{"hooks":{"PreToolUse":[{"matcher":"Bash","hooks":[{"command":"bash ~/.claude/hooks/careful-guard.sh"}]}]}}' > "$HH/.claude/settings.json"
check "hook is silent about careful-guard once registered" bash -c "! grep -q 'careful-guard' <<<\"\$(HOME='$HH' SKILLS_REPO_DIR='$C' CLAUDE_PROJECT_DIR='$TMP/noproject' HOOK_TIMEOUT=2 DESIGN_SKILLS_DIR='$TMP/design' bash '$ROOT/templates/session-start-hook.sh' 2>/dev/null)\""
rm -f "$HH/.claude/settings.json"
P="$TMP/proj"; mkdir -p "$P/.claude" && cp "$ROOT/.claude/settings.json" "$P/.claude/settings.json"
check "hook is silent about careful-guard when the project settings register it" bash -c "! grep -q 'careful-guard' <<<\"\$(HOME='$HH' SKILLS_REPO_DIR='$C' CLAUDE_PROJECT_DIR='$P' HOOK_TIMEOUT=2 DESIGN_SKILLS_DIR='$TMP/design' bash '$ROOT/templates/session-start-hook.sh' 2>/dev/null)\""

# session env (2d): auto-compact window + usage-limit watchdog written at user level, existing values kept, idempotent
cp "$ROOT/templates/lean-context.json" "$C/templates/lean-context.json"  # the working copy, committed or not
EH="$TMP/envhome"; mkdir -p "$EH/.claude"; echo '{"env":{"KEEP":"me","CLAUDE_CODE_RETRY_WATCHDOG":"0"}}' > "$EH/.claude/settings.json"
envhook() { env -u CLAUDE_CODE_AUTO_COMPACT_WINDOW -u CLAUDE_CODE_RETRY_WATCHDOG -u CLAUDE_CODE_RETRY_WATCHDOG_USAGE_LIMIT_RECHECK_MS \
  HOME="$EH" SKILLS_REPO_DIR="$C" CLAUDE_PROJECT_DIR="$TMP/noproject" HOOK_TIMEOUT=2 DESIGN_SKILLS_DIR="$TMP/design" \
  bash "$ROOT/templates/session-start-hook.sh" 2>/dev/null; }
out="$(envhook)"
check "hook reports the session env it set" grep -q "^session env: set .*CLAUDE_CODE_AUTO_COMPACT_WINDOW" <<<"$out"
check "hook sets the auto-compact window, keeps existing env values" python3 -c "
import json; e=json.load(open('$EH/.claude/settings.json'))['env']
assert e['CLAUDE_CODE_AUTO_COMPACT_WINDOW']=='400000' and e['KEEP']=='me' and e['CLAUDE_CODE_RETRY_WATCHDOG']=='0'
assert e['CLAUDE_CODE_RETRY_WATCHDOG_USAGE_LIMIT_RECHECK_MS']=='300000'"
check "hook is silent about session env once set" bash -c "! grep -q 'session env' <<<\"\$(HOME='$EH' SKILLS_REPO_DIR='$C' CLAUDE_PROJECT_DIR='$TMP/noproject' HOOK_TIMEOUT=2 DESIGN_SKILLS_DIR='$TMP/design' bash '$ROOT/templates/session-start-hook.sh' 2>/dev/null)\""
check "hook turns off claude.ai plugin sync and denies the lean-context servers" python3 -c "
import json; c=json.load(open('$EH/.claude/settings.json')); l=json.load(open('$ROOT/templates/lean-context.json'))
assert c['syncClaudeAiPlugins'] is False
assert {d['serverName'] for d in l['deniedMcpServers']} <= {d['serverName'] for d in c['deniedMcpServers']}"
echo '{"env":{"CLAUDE_CODE_AUTO_COMPACT_WINDOW":"200000"},"deniedMcpServers":[{"serverName":"Mine"},{"serverName":"Gmail"}]}' > "$EH/.claude/settings.json"
out="$(envhook)"
check "hook upgrades the stale 200K window it wrote earlier" python3 -c "
import json; assert json.load(open('$EH/.claude/settings.json'))['env']['CLAUDE_CODE_AUTO_COMPACT_WINDOW']=='400000'"
echo '{"env":{"CLAUDE_CODE_AUTO_COMPACT_WINDOW":"200000"}}' > "$EH/.claude/settings.json"
CLAUDE_CODE_AUTO_COMPACT_WINDOW=200000 HOME="$EH" SKILLS_REPO_DIR="$C" CLAUDE_PROJECT_DIR="$TMP/noproject" HOOK_TIMEOUT=2 DESIGN_SKILLS_DIR="$TMP/design" bash "$ROOT/templates/session-start-hook.sh" >/dev/null 2>&1
check "hook upgrades the stale window even when settings already exported it to the session env" python3 -c "
import json; assert json.load(open('$EH/.claude/settings.json'))['env']['CLAUDE_CODE_AUTO_COMPACT_WINDOW']=='400000'"
CLAUDE_CODE_AUTO_COMPACT_WINDOW=500000 HOME="$EH" SKILLS_REPO_DIR="$C" CLAUDE_PROJECT_DIR="$TMP/noproject" HOOK_TIMEOUT=2 DESIGN_SKILLS_DIR="$TMP/design" bash "$ROOT/templates/session-start-hook.sh" >/dev/null 2>&1
check "hook leaves settings alone when the environment sets its own window" python3 -c "
import json; assert json.load(open('$EH/.claude/settings.json'))['env']['CLAUDE_CODE_AUTO_COMPACT_WINDOW']=='400000'"
echo '{"env":{"CLAUDE_CODE_AUTO_COMPACT_WINDOW":"200000"},"deniedMcpServers":[{"serverName":"Mine"},{"serverName":"Gmail"}]}' > "$EH/.claude/settings.json"; envhook >/dev/null
check "hook keeps a hand-denied server and adds no duplicate" python3 -c "
import json; n=[d['serverName'] for d in json.load(open('$EH/.claude/settings.json'))['deniedMcpServers']]
assert 'Mine' in n and n.count('Gmail')==1"
echo '{"env":{"CLAUDE_CODE_AUTO_COMPACT_WINDOW":"300000"}}' > "$EH/.claude/settings.json"; envhook >/dev/null
check "hook keeps a window the user chose by hand" python3 -c "
import json; assert json.load(open('$EH/.claude/settings.json'))['env']['CLAUDE_CODE_AUTO_COMPACT_WINDOW']=='300000'"
check "repo settings.json carries the lean-context deny list" python3 -c "
import json; c=json.load(open('$ROOT/settings.json')); l=json.load(open('$ROOT/templates/lean-context.json'))
assert c['deniedMcpServers']==l['deniedMcpServers'] and c['syncClaudeAiPlugins'] is False"
echo '{}' > "$EH/.claude/settings.json"
check "hook keeps a value the environment already sets" bash -c "CLAUDE_CODE_AUTO_COMPACT_WINDOW=150000 HOME='$EH' SKILLS_REPO_DIR='$C' CLAUDE_PROJECT_DIR='$TMP/noproject' HOOK_TIMEOUT=2 DESIGN_SKILLS_DIR='$TMP/design' bash '$ROOT/templates/session-start-hook.sh' >/dev/null 2>&1; python3 -c \"import json; assert 'CLAUDE_CODE_AUTO_COMPACT_WINDOW' not in json.load(open('$EH/.claude/settings.json')).get('env', {})\""

# --- careful-guard entry: one command string everywhere (Claude Code runs an identical handler once) ---
guard_cmds() { python3 - "$ROOT" <<'PY2'
import json, re, sys
root = sys.argv[1]
out = []
for p in (".claude/settings.json", "settings.json"):
    c = json.load(open(f"{root}/{p}"))
    out += [h["command"] for e in c["hooks"]["PreToolUse"] for h in e["hooks"] if "careful-guard.sh" in h["command"]]
hdr = open(f"{root}/templates/session-start-hook.sh").read()
m = re.search(r'#\s+"command": ("for f in .*?exit 0")\}', hdr)
out.append(json.loads(m.group(1)))
setup = open(f"{root}/templates/cloud-setup-script.sh").read()
import subprocess  # the setup script builds guard over several lines: evaluate them as bash does
lines = "\n".join(l for l in setup.splitlines() if l.startswith("guard="))
out.append(subprocess.run(["bash", "-c", lines + '\nprintf %s "$guard"'], capture_output=True, text=True).stdout)
print(len(out), len(set(out)))
for x in set(out): print(x)
PY2
}
check "careful-guard command identical in project settings, settings.json, hook header and cloud setup" bash -c "guard_out=\"\$(cd /; $(declare -f guard_cmds); ROOT='$ROOT' guard_cmds)\"; head -1 <<<\"\$guard_out\" | grep -qx '4 1'"
gcmd="$(python3 -c "import json; print(json.load(open('$ROOT/.claude/settings.json'))['hooks']['PreToolUse'][0]['hooks'][0]['command'])")"
GH="$TMP/guardhome"; mkdir -p "$GH/.claude/hooks"
check "guard command finds nothing and passes silently" bash -c "test -z \"\$(printf '{\"tool_input\":{\"command\":\"git reset --hard\"}}' | HOME='$GH' bash -c '${gcmd//\'/\'\\\'\'}')\" || [ -f /home/user/claude-skills/scripts/careful-guard.sh ]"
ln -s "$ROOT/scripts/careful-guard.sh" "$GH/.claude/hooks/careful-guard.sh"
check "guard command runs the installed guard (ask on reset --hard)" bash -c "printf '{\"tool_input\":{\"command\":\"git reset --hard\"}}' | HOME='$GH' bash -c '${gcmd//\'/\'\\\'\'}' | grep -q '\"ask\"'"
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
{"theme": "dark", "env": {"KEEP": "me"}, "deniedMcpServers": [{"serverName": "Mine"}, {"serverName": "Gmail"}], "hooks": {"SessionStart": [
  {"hooks": [{"type": "command", "command": "echo unrelated"}]},
  {"hooks": [{"type": "command", "command": "bash /old/templates/session-start-hook.sh"}]}],
 "PreToolUse": [{"matcher": "Bash", "hooks": [{"type": "command", "command": "bash /old/careful-guard.sh"}]},
  {"matcher": "mcp__claude-code-remote__create_session", "hooks": [{"type": "command", "command": "bash /old/model-guard.sh"}]},
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
  check "$2: exactly one model-guard entry, on create_session, the new one, and the other PreToolUse hook kept" python3 -c "
import json; c=json.load(open('$s')); p=c['hooks']['PreToolUse']; e=[e for e in p if any('model-guard.sh' in h['command'] for h in e['hooks'])]
assert len(e)==1 and e[0]['matcher']=='mcp__claude-code-remote__create_session' and '/old/' not in e[0]['hooks'][0]['command']
assert any(h['command']=='echo other-pre' for x in p for h in x['hooks'])"
  check "$2: registered model-guard command runs the guard (deny sonnet without the code-free line)" bash -c "c=\"\$(python3 -c \"import json; c=json.load(open('$s')); print([h['command'] for e in c['hooks']['PreToolUse'] for h in e['hooks'] if 'model-guard.sh' in h['command']][0])\")\"; mkdir -p '$1/.claude/hooks'; ln -sf '$ROOT/scripts/model-guard.sh' '$1/.claude/hooks/model-guard.sh'; printf '{\"tool_name\":\"mcp__claude-code-remote__create_session\",\"tool_input\":{\"model\":\"claude-sonnet-5-5\",\"prompt\":\"x\"}}' | HOME='$1' bash -c \"\$c\" | grep -q deny"
  check "$2: usage-limit watchdog env set, other env kept, auto-continue on" python3 -c "
import json; c=json.load(open('$s')); e=c['env']
assert e['CLAUDE_CODE_RETRY_WATCHDOG']=='1' and e['KEEP']=='me' and c['autoContinueAtUsageLimit'] is True
assert e['CLAUDE_CODE_AUTO_COMPACT_WINDOW']=='400000'"
  check "$2: plugin sync off, lean-context servers denied once, hand-denied server kept" python3 -c "
import json; c=json.load(open('$s')); l=json.load(open('$ROOT/templates/lean-context.json'))
n=[d['serverName'] for d in c['deniedMcpServers']]
assert c['syncClaudeAiPlugins'] is False and 'Mine' in n and n.count('Gmail')==1
assert {d['serverName'] for d in l['deniedMcpServers']} <= set(n)"
  check "$2: unrelated PreToolUse hook kept" python3 -c "
import json; c=json.load(open('$s')); assert any(h['command']=='echo other-pre' for e in c['hooks']['PreToolUse'] for h in e['hooks'])"
}
run_setup() { HOME="$1" PATH="$2" bash "$ROOT/templates/cloud-setup-script.sh" >/dev/null 2>&1; }
if command -v jq >/dev/null 2>&1; then
  setup_home "$TMP/cs1"; run_setup "$TMP/cs1" "$PATH"; assert_settings "$TMP/cs1" "jq path"
fi
mkdir -p "$TMP/nojq"; printf '#!/bin/sh\nexit 127\n' > "$TMP/nojq/jq"; chmod +x "$TMP/nojq/jq"
setup_home "$TMP/cs2"; run_setup "$TMP/cs2" "$TMP/nojq:$PATH"; assert_settings "$TMP/cs2" "python fallback (jq broken)"
check "usage-limit config stays global: no env/autoContinue in project settings or the hook template" python3 -c "
import json; c=json.load(open('$ROOT/.claude/settings.json')); assert 'env' not in c and 'autoContinueAtUsageLimit' not in c
assert 'CLAUDE_CODE_RETRY_WATCHDOG' not in open('$ROOT/templates/session-start-hook.sh').read().split('set -u')[0]"
check "setup script's inline deny list equals templates/lean-context.json" python3 -c "
import json,re; l=[d['serverName'] for d in json.load(open('$ROOT/templates/lean-context.json'))['deniedMcpServers']]
m=re.search(r\"^deny='(.*?)'$\", open('$ROOT/templates/cloud-setup-script.sh').read(), re.M|re.S); assert json.loads(m.group(1))==l"
check "setup script commits no account connector IDs (deny_extra stays empty)" grep -qx "deny_extra='\[\]'" "$ROOT/templates/cloud-setup-script.sh"
check "setup script fits the environment editor (lines <= 200 bytes, <= 100 lines)" python3 -c "
L=open('$ROOT/templates/cloud-setup-script.sh','rb').read().split(b'\\n'); assert len(L)<=100 and max(map(len,L))<=200"
check "setup creates ~/.claude/agents before the session starts" test -d "$TMP/cs2/.claude/agents"

# --- release-workflow.yml: structure, then its two run scripts against a fake project with git/gh stubs ---
RW="$ROOT/templates/release-workflow.yml"; RWD="$TMP/rw"; mkdir -p "$RWD/bin" "$RWD/proj" "$RWD/tmp"
rw_yaml() { python3 -c "
import yaml; w=yaml.safe_load(open('$RW')); on=w.get('on', w.get(True)); steps=w['jobs']['release']['steps']
checks=[s for s in steps if s.get('name')=='Release checks'][0]
publish=[s for s in steps if str(s.get('name','')).startswith('Publish')][0]
$1"; }
check "release workflow: valid YAML, workflow_dispatch only" rw_yaml "assert list(on)==['workflow_dispatch']"
check "release workflow: version required string, dry_run boolean defaulting to true" rw_yaml "
i=on['workflow_dispatch']['inputs']; assert i['version']['required'] is True and i['version']['type']=='string'
assert i['dry_run']['type']=='boolean' and i['dry_run']['default'] is True"
check "release workflow: permissions contents write + actions read" rw_yaml "
assert w['jobs']['release']['permissions']=={'contents':'write','actions':'read'}"
check "release workflow: no \${{ }} inside any run script (inputs only via env)" rw_yaml "
assert all('\${{' not in s['run'] for s in steps if 'run' in s)"
check "release workflow: checks run unconditionally, before the publish step" rw_yaml "
assert 'if' not in checks and steps.index(checks) < steps.index(publish)"
rw_yaml "open('$RWD/checks.sh','w').write(checks['run']); open('$RWD/publish.sh','w').write(publish['run'])" 2>/dev/null
cat > "$RWD/bin/git" <<'SH'
#!/bin/sh
echo "git $*" >> "$CALLS"
if [ "$1" = ls-remote ] && [ -n "${FAKE_TAGS:-}" ]; then printf '%s\n' "$FAKE_TAGS"; fi
exit 0
SH
cat > "$RWD/bin/gh" <<'SH'
#!/bin/sh
echo "gh $*" >> "$CALLS"
if [ "$1" = api ]; then  # apply the step's own --jq to a fake runs list, as gh does
  while [ $# -gt 0 ]; do if [ "$1" = --jq ]; then printf '%s' "$FAKE_RUNS" | jq -r "$2"; exit; fi; shift; done
fi
exit 0
SH
chmod +x "$RWD/bin/git" "$RWD/bin/gh"
echo '{"name": "p", "version": "1.2.3"}' > "$RWD/proj/package.json"
cat > "$RWD/proj/CHANGELOG.md" <<'MD'
# Changelog

## 1.2.10 — later

- notes of ten

## [1.2.4] - 2026-11-20

## 1.2.3 — first

### Added

- notes of three
MD
GREEN='{"workflow_runs":[{"status":"completed","conclusion":"success","html_url":"https://x/run/1"}]}'
rw() { # rw <checks|publish> [VAR=value...]: run a step script in the fake project; output in $RWD/out, calls in $RWD/calls
  local s="$1"; shift; : > "$RWD/calls"
  (cd "$RWD/proj" && env PATH="$RWD/bin:$PATH" CALLS="$RWD/calls" RUNNER_TEMP="$RWD/tmp" GITHUB_STEP_SUMMARY="$RWD/summary" \
    GITHUB_REF=refs/heads/main DEFAULT_BRANCH=main GITHUB_SHA=abc123 GITHUB_REPOSITORY=o/r CI_WORKFLOW=ci.yml \
    VERSION=1.2.3 FAKE_TAGS='' FAKE_RUNS="$GREEN" ASSETS='' DRY_RUN=true "$@" bash "$RWD/$s.sh") > "$RWD/out" 2>&1; }
rw_fails() { # rw_fails <message regex> [VAR=value...]: the checks exit non-zero and say why
  local m="$1"; shift; ! rw checks "$@" && grep -Eq "::error.*$m" "$RWD/out"; }
rw_all_failures() { rw_fails 'package.json' VERSION=1.2.5 GITHUB_REF=refs/heads/topic && test "$(grep -c '::error' "$RWD/out")" -eq 3; }
rw_created_nothing() { ! grep -Eq '^git (tag|push)|^gh release' "$RWD/calls"; }
rw_published() {
  rw publish DRY_RUN=false ASSETS='a.zip b.zip' && grep -Eq '^git tag -a v1\.2\.3 -m .* abc123$' "$RWD/calls" &&
    grep -qx 'git push origin refs/tags/v1.2.3' "$RWD/calls" &&
    grep -Eq "^gh release create v1\.2\.3 a\.zip b\.zip --verify-tag .*--notes-file $RWD/tmp/release-notes\.md" "$RWD/calls"; }
check "release checks pass on a clean release" rw checks
check "release checks read the CI runs of this commit from the configured workflow" grep -q 'actions/workflows/ci.yml/runs?head_sha=abc123' "$RWD/calls"
check "release notes are the exact section (1.2.3 never reads 1.2.10)" bash -c "grep -q 'notes of three' '$RWD/tmp/release-notes.md' && ! grep -q 'notes of ten' '$RWD/tmp/release-notes.md'"
check "release checks refuse a version with v" rw_fails 'X\.Y\.Z' VERSION=v1.2.3
check "release checks refuse a suffix" rw_fails 'X\.Y\.Z' VERSION=1.2.3-rc.1
check "release checks refuse an empty version" rw_fails 'X\.Y\.Z' VERSION=
check "release checks refuse a version other than package.json" rw_fails 'package.json is at 1.2.3' VERSION=1.2.10
check "release checks refuse a version with no CHANGELOG section" rw_fails 'no "## 1.2.5" section' VERSION=1.2.5
check "release checks never take 1.2.10 for the 1.2.1 section" rw_fails 'no "## 1.2.1" section' VERSION=1.2.1
check "release checks refuse an empty CHANGELOG section (Keep a Changelog heading)" rw_fails 'is empty' VERSION=1.2.4
check "release checks refuse an existing tag" rw_fails 'v1.2.3 already exists' FAKE_TAGS="$(printf 'abc\trefs/tags/v1.2.3')"
check "release checks refuse a run off the default branch" rw_fails 'default branch' GITHUB_REF=refs/heads/topic
check "release checks refuse a commit with no CI run" rw_fails 'No CI run' FAKE_RUNS='{"workflow_runs":[]}'
check "release checks refuse CI still running" rw_fails 'still in_progress' FAKE_RUNS='{"workflow_runs":[{"status":"in_progress","conclusion":null,"html_url":"u"}]}'
check "release checks refuse red CI" rw_fails 'ended with failure' FAKE_RUNS='{"workflow_runs":[{"status":"completed","conclusion":"failure","html_url":"u"}]}'
check "release checks report every failure, not only the first" rw_all_failures
rw checks; : > "$RWD/summary"
check "dry run exits 0" rw publish
check "dry run creates nothing" rw_created_nothing
check "dry run summary shows tag, commit and notes" bash -c "grep -q 'v1.2.3' '$RWD/summary' && grep -q 'abc123' '$RWD/summary' && grep -q 'notes of three' '$RWD/summary'"
check "dry run prints the same to the job log (get_job_logs has no step summary)" bash -c "grep -q 'tag \`v1.2.3\` on commit \`abc123\`' '$RWD/out' && grep -q 'notes of three' '$RWD/out'"
check "anything but dry_run=false is a dry run" bash -c "$(declare -f rw rw_created_nothing); RWD='$RWD' GREEN='$GREEN'; rw publish DRY_RUN='' && rw_created_nothing"
check "dry_run=false pushes an annotated tag on the built commit, then the release on it" rw_published

exit $FAIL
