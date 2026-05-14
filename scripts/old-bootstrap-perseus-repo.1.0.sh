#!/usr/bin/env bash
# =============================================================================
#  bootstrap-perseus-repo.sh — One-time Perseus repository bootstrap
# =============================================================================
#  Purpose: Create the bare-repo + main worktree layout that gtr operates on.
#           Equivalent of `repo get github.com/.../perseus` from repo-manager.
#
#  Usage: ./bootstrap-perseus-repo.sh [REPO_URL]
#
#  Idempotent: safe to re-run; existing layouts are detected and skipped.
# =============================================================================

set -euo pipefail

REPO_URL="${1:-${PERSEUS_REPO_URL:-git@github.com:pierreribeiro/sqlserver-to-postgresql-migration.git}}"
REPO_BASE_DIR="${REPO_BASE_DIR:-$HOME/dev/repos}"

# Parse host/owner/repo from the URL
if [[ "$REPO_URL" =~ ^git@([^:]+):([^/]+)/(.+)\.git$ ]]; then
    HOST="${BASH_REMATCH[1]}"
    OWNER="${BASH_REMATCH[2]}"
    REPO="${BASH_REMATCH[3]}"
elif [[ "$REPO_URL" =~ ^https?://([^/]+)/([^/]+)/(.+)\.git$ ]]; then
    HOST="${BASH_REMATCH[1]}"
    OWNER="${BASH_REMATCH[2]}"
    REPO="${BASH_REMATCH[3]}"
else
    echo "❌ Cannot parse repo URL: $REPO_URL"
    exit 1
fi

REPO_ROOT="$REPO_BASE_DIR/$HOST/$OWNER/$REPO"

echo "🚀 Bootstrapping Perseus repo:"
echo "   URL:  $REPO_URL"
echo "   Path: $REPO_ROOT"
echo ""

# Idempotency check
if [ -d "$REPO_ROOT/.bare" ]; then
    echo "✅ Bare repo already exists at $REPO_ROOT/.bare — skipping clone"
else
    mkdir -p "$REPO_ROOT"
    cd "$REPO_ROOT"
    git clone --bare "$REPO_URL" .bare
    echo "gitdir: ./.bare" > .git
    git --git-dir=.bare config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'
    git --git-dir=.bare fetch origin
    echo "✅ Bare repo cloned"
fi

# Create main worktree if absent
cd "$REPO_ROOT"
if [ ! -d "main" ]; then
    git worktree add main main
    echo "✅ main worktree created"
else
    echo "✅ main worktree already exists — skipping"
fi

# Suggest next steps
echo ""
echo "═════════════════════════════════════════════════════════════════"
echo "  Bootstrap complete. Layout:"
echo ""
echo "    $REPO_ROOT/"
echo "      .bare/         (GIT_DIR — bare repo)"
echo "      .git           (pointer file)"
echo "      main/          (main worktree)"
echo ""
echo "  Next steps:"
echo "    1. cd $REPO_ROOT/main"
echo "    2. git config --local perseus.pg.user perseus"
echo "    3. git config --local perseus.pg.template dev_template"
echo "    4. git gtr config set gtr.ai.default claude"
echo "    5. git gtr config set gtr.editor.default vscode"
echo "    6. git gtr doctor   # verify everything works"
echo "═════════════════════════════════════════════════════════════════"