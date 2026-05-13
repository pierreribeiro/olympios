#!/usr/bin/env bash
# =============================================================================
#  preRemove.sh — gtr hook entry point for Project Perseus (worktree REMOVE)
# =============================================================================
#  Purpose: Glue layer between gtr's preRemove hook and our domain logic.
#           Validates GTR_* environment variables, then delegates to
#           deprovision-branch-db.sh.
#
#  Symmetry: This script is the mirror of postCreate.sh. Both are thin
#            glue layers that delegate to the actual DB logic, preserving
#            separation of concerns:
#              postCreate.sh → provision-branch-db.sh
#              preRemove.sh  → deprovision-branch-db.sh
#
#  Configured via .gtrconfig:
#      [hooks]
#          postCreate = scripts/gtr-hooks/postCreate.sh
#          preRemove  = scripts/gtr-hooks/preRemove.sh
#
#  Environment variables provided by gtr (preRemove context):
#      GTR_WORKTREE_PATH    — absolute path to the worktree about to be removed
#      GTR_BRANCH_NAME      — git branch name
#      GTR_REPO_ROOT        — main repo root
#      GTR_WORKTREE_NAME    — worktree folder name
#
#  Behavior:
#      - Always runs deprovision-branch-db.sh with --force (the user
#        already explicitly invoked `gtr rm`, no double-confirmation).
#      - Always dumps the DB before drop (safety net to ~/.perseus/branch-dumps/).
#      - If this hook fails, gtr will block worktree removal — protective
#        on purpose. To bypass intentionally, use `gtr rm --no-verify`.
#
#  Design note (v2.1):
#      In v2.0, this functionality lived in a bash function wrapper around
#      `gtr` in the developer's ~/.zshrc. v2.1 moves it to a declarative
#      hook because:
#        1. Empirical confirmation that gtr.hook.preRemove is native
#        2. Team-shared via committed .gtrconfig (vs per-developer .zshrc)
#        3. Works in any shell (zsh, bash, fish) — not tied to ZSH
#        4. Versionable in git, auditable in PRs
#
#  Compatibility: bash 3.2+ (default macOS shell)
#
#  Author:  Pierre Ribeiro <pierreribeiro@dinamotech.com.br>
#  Version: 1.0.0  (introduced in Perseus v2.1, 2026-04-30)
#  License: Internal — DinamoTech / Project Perseus
# =============================================================================

set -euo pipefail

# ----------------------------------------------------------------------------
#  Validate gtr environment
# ----------------------------------------------------------------------------
: "${GTR_WORKTREE_PATH:?GTR_WORKTREE_PATH not set — are we running under gtr?}"
: "${GTR_BRANCH_NAME:?GTR_BRANCH_NAME not set — are we running under gtr?}"

# ----------------------------------------------------------------------------
#  Resolve script paths
# ----------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"  # scripts/gtr-hooks/ → repo root
DEPROVISION_SCRIPT="$REPO_ROOT/scripts/deprovision-branch-db.sh"

if [ ! -x "$DEPROVISION_SCRIPT" ]; then
    echo "[preRemove] ❌ Deprovisioner not found or not executable: $DEPROVISION_SCRIPT" >&2
    echo "[preRemove]    Hint: chmod +x $DEPROVISION_SCRIPT" >&2
    exit 1
fi

# ----------------------------------------------------------------------------
#  Delegate to domain logic
# ----------------------------------------------------------------------------
echo "[preRemove] 🛡️  Pre-removal: dumping and dropping per-branch DB…"
echo "[preRemove]    Branch: $GTR_BRANCH_NAME"
echo "[preRemove]    Worktree: $GTR_WORKTREE_PATH"

# --force: skip interactive confirmation (user already chose to gtr rm)
# (no --no-dump: we ALWAYS dump as the safety net for accidental removals)
exec "$DEPROVISION_SCRIPT" \
    --branch "$GTR_BRANCH_NAME" \
    --force
