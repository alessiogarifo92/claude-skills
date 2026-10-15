#!/usr/bin/env bash
# PreToolUse hook for subagents (wired in each agent's frontmatter `hooks:`, installed by install.sh as
# ~/.claude/hooks/agent-guard.sh). Version control and GitHub writes belong to the main session
# (orchestrating-agents): this turns the "never run git write commands" line of every agent prompt
# into a hard block instead of a request the model may ignore.
# Reads the hook JSON on stdin; exit 2 blocks the Bash call and shows stderr to the agent.
# No jq/python dependency: the command is matched in the raw JSON, where words stay intact.
set -u
input="$(cat)"

git_write='(^|[^[:alnum:]_-])git([[:space:]]+-[Cc][[:space:]]+[^[:space:]]+)*[[:space:]]+(commit|push|reset|checkout|switch|merge|rebase|tag|stash|clean|restore|am|cherry-pick|revert|apply|rm|mv|pull|worktree[[:space:]]+(add|remove|prune|move|lock|unlock)|branch[[:space:]]+(-[a-zA-Z]*[dDmMcC]|--delete|--move|--copy|--force)|remote[[:space:]]+(add|remove|rm|set-url|rename))([^[:alnum:]_-]|$)'
gh_write='(^|[^[:alnum:]_-])gh[[:space:]]+((pr|issue)[[:space:]]+(create|merge|close|reopen|edit|comment|review|delete|lock|transfer|ready)|release[[:space:]]+(create|edit|delete|upload)|repo[[:space:]]+(create|edit|delete|rename|archive|fork)|label[[:space:]]+(create|edit|delete|clone)|workflow[[:space:]]+(run|enable|disable)|run[[:space:]]+(rerun|cancel|delete)|secret|variable|api[[:space:]].*(-X|--method)[[:space:]]*(POST|PATCH|PUT|DELETE))'

if grep -Eq "$git_write" <<<"$input"; then
  echo "agent-guard: git write commands are reserved to the main session (orchestrating-agents). Report what you would run under OPEN instead." >&2
  exit 2
fi
if grep -Eq "$gh_write" <<<"$input"; then
  echo "agent-guard: GitHub write operations are reserved to the main session. Report what you would run under OPEN instead." >&2
  exit 2
fi
exit 0
