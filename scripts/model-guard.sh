#!/usr/bin/env bash
# PreToolUse hook (matcher mcp__claude-code-remote__create_session) for the MAIN session, installed by install.sh as
# ~/.claude/hooks/model-guard.sh and registered at user level by templates/cloud-setup-script.sh (locally: merge
# settings.json by hand). It enforces orchestrating-agents' "Code-writing rule" at the one point where it was broken:
# a manager opening a child session for a code ticket on sonnet (mix-splash #99 and #236, 22 Nov 2026, model passed
# explicitly although the rule already required opus for a mechanic). A session cannot change its own model, so the
# choice made here is final for the child.
#   - no `model`                        -> deny: the child would inherit the caller's model silently
#   - model matches MODEL_GUARD_CODE_MODELS (default: opus) -> pass
#   - any other model (sonnet, haiku)   -> deny, unless the prompt carries the line "SESSIONE SENZA CODICE"
#     (a written, visible declaration that the child edits no source or test code; the child is bound by it too)
# Deny, not ask: the manager reads the reason and re-issues the call, with no user prompt in an unattended run.
# Fails open (passes) when python3 is missing or the input is unreadable. Off switch: MODEL_GUARD_OFF=1.
set -u
input="$(cat)"
[ "${MODEL_GUARD_OFF:-}" = "1" ] && exit 0
command -v python3 >/dev/null 2>&1 || exit 0
MODEL_GUARD_CODE_MODELS="${MODEL_GUARD_CODE_MODELS:-opus}" python3 -c '
import json, os, re, sys
try:
    d = json.loads(sys.argv[1])
except Exception:
    sys.exit(0)
if not d.get("tool_name", "").endswith("create_session"):
    sys.exit(0)
ti = d.get("tool_input") or {}
model = str(ti.get("model") or "").strip()
prompt = str(ti.get("prompt") or "")
code_models = os.environ["MODEL_GUARD_CODE_MODELS"]
def deny(reason):
    print(json.dumps({"hookSpecificOutput": {"hookEventName": "PreToolUse",
        "permissionDecision": "deny", "permissionDecisionReason": "model-guard: " + reason}}))
    sys.exit(0)
if not model:
    deny("pass `model` explicitly: without it the child inherits this session’s model. "
         "claude-opus-5-5 if the ticket will edit any source or test code (feature, mechanic, fix, refactor, "
         "a stage that touches scripts/src; when unsure, opus); claude-sonnet-5-5 only for code-free work, with the "
         "line \"SESSIONE SENZA CODICE\" in the prompt (orchestrating-agents, Code-writing rule).")
if re.search(code_models, model, re.I):
    sys.exit(0)
if "SESSIONE SENZA CODICE" in prompt.upper():
    sys.exit(0)
deny("model %s may not write code, and the prompt does not declare the session code-free. If the ticket edits any "
     "source or test code, re-issue with model claude-opus-5-5 (at most 2 opus code sessions at once). If it truly "
     "writes no code (coordination, research, playtest, docs, pure data, PR to green by re-run/merge only), add to "
     "the prompt the line: \"SESSIONE SENZA CODICE: non modificare codice sorgente o test; se serve, delega a "
     "implementer (opus) o fermati e avvisa il manager.\" (orchestrating-agents, Code-writing rule)" % model)
' "$input"
exit 0
