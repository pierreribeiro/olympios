#!/usr/bin/env bash
# =============================================================================
#  bootstrap-perseus-repo.sh — One-time Perseus repository bootstrap
# =============================================================================
#  Purpose:  Solve the chicken-and-egg problem of "scripts live inside the repo
#            you don't have yet". Downloaded via curl-from-raw-GitHub, this
#            script clones the bare repo and creates the main worktree under
#            the DinamoTech per-client layout convention.
#
#  Layout (Option B — per-client organization):
#      $REPO_BASE_DIR/                            (e.g., $HOME/workspace/projects/)
#      └── $PERSEUS_CLIENT/                       (e.g., amyris/)
#          └── sqlserver-to-postgresql-migration/ ← project root
#              ├── .bare/                         (GIT_DIR — bare repo)
#              ├── .git                           (pointer file)
#              └── main/                          (main worktree)
#
#  Usage (self-pulling via curl):
#      curl -fsSL https://raw.githubusercontent.com/pierreribeiro/\
#        sqlserver-to-postgresql-migration/main/scripts/bootstrap-perseus-repo.sh | bash
#
#  Or local execution (after first clone, for re-bootstrap):
#      ./scripts/bootstrap-perseus-repo.sh
#
#  Required environment variables:
#      REPO_BASE_DIR     Global root for all projects on this machine
#                        (e.g., $HOME/workspace/projects)
#      PERSEUS_CLIENT    Client identifier — sub-folder under REPO_BASE_DIR
#                        (e.g., amyris)
#
#  Optional environment variables:
#      PERSEUS_REPO_URL  Git URL of the remote repo
#                        (default: git@github.com:pierreribeiro/sqlserver-to-postgresql-migration.git)
#      PERSEUS_REPO_NAME Folder name inside $REPO_BASE_DIR/$PERSEUS_CLIENT/
#                        (default: sqlserver-to-postgresql-migration)
#
#  IRON RULE: zero hardcoded paths. All location info comes from the environment.
#  Defaults exist for convention but never override an explicit env value.
#
#  Idempotent: safe to re-run; existing layouts are detected and skipped.
#  Compatibility: bash 3.2+ (default macOS shell)
#
#  Author:   Pierre Ribeiro <pierreribeiro@dinamotech.com.br>
#  Version:  2.0.0 (parametrized for per-client layout)
# =============================================================================

set -euo pipefail

# ----------------------------------------------------------------------------
#  Logging helpers (inline — script must work standalone, before repo exists)
# ----------------------------------------------------------------------------
if [ -t 1 ]; then
    _C_RESET="\033[0m"
    _C_BLUE="\033[0;34m"
    _C_GREEN="\033[0;32m"
    _C_YELLOW="\033[0;33m"
    _C_RED="\033[0;31m"
else
    _C_RESET=""; _C_BLUE=""; _C_GREEN=""; _C_YELLOW=""; _C_RED=""
fi

log_info()  { printf "${_C_BLUE}[bootstrap]${_C_RESET} ℹ️  %s\n" "$*"; }
log_ok()    { printf "${_C_GREEN}[bootstrap]${_C_RESET} ✅ %s\n" "$*"; }
log_warn()  { printf "${_C_YELLOW}[bootstrap]${_C_RESET} ⚠️  %s\n" "$*" >&2; }
log_error() { printf "${_C_RED}[bootstrap]${_C_RESET} ❌ %s\n" "$*" >&2; }
log_die()   { log_error "$1"; exit "${2:-1}"; }

# ----------------------------------------------------------------------------
#  Validate required environment
# ----------------------------------------------------------------------------
if [ -z "${REPO_BASE_DIR:-}" ]; then
    log_die "REPO_BASE_DIR not set.
   Hint: add to ~/.zshrc:
     export REPO_BASE_DIR=\"\$HOME/workspace/projects\"
   Then: source ~/.zshrc  (or open a new terminal) and re-run." 2
fi

if [ -z "${PERSEUS_CLIENT:-}" ]; then
    log_die "PERSEUS_CLIENT not set.
   Hint: add to ~/.zshrc:
     export PERSEUS_CLIENT=\"amyris\"
   Then: source ~/.zshrc  (or open a new terminal) and re-run." 3
fi

# Optional with conventional defaults
REPO_URL="${PERSEUS_REPO_URL:-git@github.com:pierreribeiro/sqlserver-to-postgresql-migration.git}"
REPO_NAME="${PERSEUS_REPO_NAME:-sqlserver-to-postgresql-migration}"

# Compute target path (no hardcoded segments — all from env)
PROJECT_ROOT="$REPO_BASE_DIR/$PERSEUS_CLIENT/$REPO_NAME"

log_info "Bootstrapping Perseus repo (per-client layout):"
log_info "  REPO_BASE_DIR  = $REPO_BASE_DIR"
log_info "  PERSEUS_CLIENT = $PERSEUS_CLIENT"
log_info "  Repo URL       = $REPO_URL"
log_info "  Repo folder    = $REPO_NAME"
log_info "  Project root   = $PROJECT_ROOT"

# ----------------------------------------------------------------------------
#  Validate prereqs (git + network reachability)
# ----------------------------------------------------------------------------
command -v git >/dev/null 2>&1 || log_die "'git' not found in PATH. Install Xcode CLT or git via Homebrew." 4

# ----------------------------------------------------------------------------
#  Create client parent dir
# ----------------------------------------------------------------------------
mkdir -p "$REPO_BASE_DIR/$PERSEUS_CLIENT"

# ----------------------------------------------------------------------------
#  Clone bare repo (idempotent)
# ----------------------------------------------------------------------------
if [ -d "$PROJECT_ROOT/.bare" ]; then
    log_ok "Bare repo already exists at $PROJECT_ROOT/.bare — skipping clone"
else
    if [ -d "$PROJECT_ROOT" ] && [ "$(ls -A "$PROJECT_ROOT" 2>/dev/null)" ]; then
        log_die "Target directory exists and is not empty (no .bare/ inside):
     $PROJECT_ROOT
   Hint: remove or rename it before bootstrap." 5
    fi
    mkdir -p "$PROJECT_ROOT"
    cd "$PROJECT_ROOT"
    log_info "Cloning bare repo from $REPO_URL …"
    git clone --bare "$REPO_URL" .bare
    echo "gitdir: ./.bare" > .git
    git --git-dir=.bare config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'
    git --git-dir=.bare fetch origin
    log_ok "Bare repo cloned"
fi

# ----------------------------------------------------------------------------
#  Create main worktree (idempotent)
# ----------------------------------------------------------------------------
cd "$PROJECT_ROOT"
if [ -d "main" ] && [ -f "main/.git" -o -d "main/.git" ]; then
    log_ok "main worktree already exists — skipping"
else
    log_info "Creating main worktree …"
    git worktree add main main
    log_ok "main worktree created"
fi

# ----------------------------------------------------------------------------
#  Summary
# ----------------------------------------------------------------------------
cat <<-EOF

  ┌─────────────────────────────────────────────────────────────────┐
  │  ✅  Bootstrap complete                                          │
  ├─────────────────────────────────────────────────────────────────┤
  │  Layout:
  │
  │    $PROJECT_ROOT/
  │      .bare/         (GIT_DIR — bare repo)
  │      .git           (pointer: gitdir: ./.bare)
  │      main/          (main worktree)
  │
  │  Next steps (per WORKFLOW-PERSEUS-v3.1.md § 0):
  │
  │    cd "\$PERSEUS_BASE/main"
  │
  │    # Step 0.3.4 — per-developer git locals
  │    git config --local perseus.pg.user     perseus_owner
  │    git config --local perseus.pg.template dev_template
  │    git gtr config set gtr.ai.default      claude
  │
  │    # Step 0.3.5 — initialize PG18 cluster (deployment v1.1)
  │    cp infra/database/.env.example infra/database/.env
  │    \$EDITOR infra/database/.env
  │    ./infra/database/init-db.sh init
  │
  │    # Step 0.3.6 — populate \~/.pgpass with generated password
  │    # Step 0.3.7 — populate perseus_dev (developer's choice)
  │    # Step 0.3.8 — promote to template
  │    ./scripts/promote-dev-to-template.sh
  │
  │    # Step 0.3.9 — verify
  │    git gtr doctor
  └─────────────────────────────────────────────────────────────────┘

EOF
exit 0
