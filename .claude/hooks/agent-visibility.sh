#!/usr/bin/env bash
# =============================================================================
#  agent-visibility.sh — PostToolUse hook for subagent visibility in TMUX
# =============================================================================
#  Purpose: when a Task tool (Agent) completes, write a structured log entry
#  to the `cc-agents` TMUX pane. Gives Pierre delayed visibility into
#  subagent activity without breaking subagent context isolation.
#
#  Triggered by: PostToolUse hook with matcher="Agent" in .claude/settings.json
#  Compatibility: bash 3.2+, jq, tmux
# =============================================================================

set -euo pipefail

INPUT=$(cat)
RESULT=$(echo "$INPUT" | jq -r '.tool_result // empty' | head -20)
PROMPT=$(echo "$INPUT" | jq -r '.tool_input.prompt // empty' | head -c 120)
BG=$(echo "$INPUT" | jq -r '.tool_input.run_in_background // false')

# We expect to be inside a TMUX session named perseus-<worktree>
SESSION="${TMUX_PANE:+$(tmux display-message -p '#S' 2>/dev/null || true)}"
[ -z "$SESSION" ] && exit 0   # not inside TMUX — silently no-op

PANE_TITLE="cc-agents"

# Locate the cc-agents pane in the current session
PANE_ID=$(tmux list-panes -t "$SESSION" -F '#{pane_title} #{pane_id}' 2>/dev/null \
            | awk -v t="$PANE_TITLE" '$1==t {print $2; exit}')

if [ -z "$PANE_ID" ]; then
  # Create the pane if missing (defensive — should already exist from gtr-tmux.sh)
  PANE_ID=$(tmux split-window -h -t "$SESSION" -d -P -F '#{pane_id}')
  tmux select-pane -t "$PANE_ID" -T "$PANE_TITLE"
fi

# Compose log entry
{
  echo "━━━ $(date +%H:%M:%S) Agent [bg=$BG] ━━━"
  echo "Task: $PROMPT"
  if [ -n "$RESULT" ]; then
    echo "Result (first 20 lines):"
    echo "$RESULT"
  else
    echo "(running in background...)"
  fi
  echo ""
} | while IFS= read -r line; do
  tmux send-keys -t "$PANE_ID" "echo $(printf '%q' "$line")" Enter 2>/dev/null || true
done