#!/usr/bin/env bash
# =============================================================================
#  gtr-tmux.sh — Launch 2-pane TMUX cockpit for a Perseus worktree
# =============================================================================
#  Usage:
#    gtr-tmux <worktree-name>      # e.g., gtr-tmux feat-users-rbac
#    gtr-tmux                       # uses current directory
#
#  Cockpit:
#    Pane 0 (left, ~60%):  Claude Code orchestrator (Pierre interacts here)
#    Pane 1 (right, ~40%): cc-agents log (PostToolUse hook writes here)
#
#  IRON RULE: no hardcoded values — everything from .env or env vars.
#  Compatibility: bash 3.2+, tmux
# =============================================================================

set -euo pipefail

WT_NAME="${1:-$(basename "$PWD")}"

# Resolve worktree path
if [ -d "$PWD/.git" ] || [ -f "$PWD/.git" ]; then
    WT_PATH="$PWD"
elif [ -n "${PERSEUS_BASE:-}" ] && [ -d "$PERSEUS_BASE/$WT_NAME" ]; then
    WT_PATH="$PERSEUS_BASE/$WT_NAME"
else
    echo "❌ Cannot resolve worktree: $WT_NAME" >&2
    exit 1
fi

[ -f "$WT_PATH/.env" ] || { echo "❌ .env missing in $WT_PATH" >&2; exit 1; }

SESSION="perseus-$WT_NAME"

# Attach if already exists
if tmux has-session -t "$SESSION" 2>/dev/null; then
    echo "🔗 Attaching to existing session: $SESSION"
    exec tmux attach -t "$SESSION"
fi

echo "🚀 Creating cockpit session: $SESSION"

# Pane 0: Claude Code orchestrator
tmux new-session -d -s "$SESSION" -n cockpit -c "$WT_PATH" -x 200 -y 50
tmux select-pane -t "$SESSION:cockpit.0" -T "claude-orchestrator"
tmux send-keys -t "$SESSION:cockpit.0" \
    "set -a && . .env && set +a && clear && claude" C-m

# Pane 1: cc-agents log — split horizontally, ~40% width
tmux split-window -h -t "$SESSION:cockpit" -c "$WT_PATH" -p 40
tmux select-pane -t "$SESSION:cockpit.1" -T "cc-agents"
tmux send-keys -t "$SESSION:cockpit.1" \
    "clear && echo '═══ cc-agents log (subagent visibility) ═══' && echo 'Waiting for first Task tool invocation...' && echo ''" C-m

# Default focus on orchestrator
tmux select-pane -t "$SESSION:cockpit.0"

exec tmux attach -t "$SESSION"