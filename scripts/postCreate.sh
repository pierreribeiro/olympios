#!/usr/bin/env bash
# =============================================================================
#  postCreate.sh — gtr hook for Project Perseus
# =============================================================================
#  Purpose:
#    Provision a per-branch PostgreSQL 18 database (cloned from dev_template
#    via STRATEGY=FILE_COPY + file_copy_method=clone) and generate a per-
#    worktree .env file when a new worktree is created via `gtr new`.
#
#  Replaces:
#    The v1.0 ZSH `post_wt_add` function (RAG-LIBRARY-v2 § 3.7 — superseded).
#
#  Activation:
#    Configured in .gtrconfig (team-shared, committed to repo) via:
#        [hooks]
#            postCreate = scripts/gtr-hooks/postCreate.sh
#
#  Compatibility:
#    bash 3.2+ (default macOS shell) — NO associative arrays, NO mapfile.
#    Tested on macOS Tahoe 26.4.1 + PostgreSQL 18.x + gtr v2.4+
#
#  Environment variables provided by gtr at runtime:
#    GTR_WORKTREE_PATH    — absolute path to the new worktree
#    GTR_BRANCH_NAME      — git branch name (e.g., feat/users-rbac)
#    GTR_REPO_ROOT        — main repo root (the bare-repo wrapper dir)
#    GTR_WORKTREE_NAME    — worktree folder name
#
#  Configuration via git config (per-repo overrides):
#    perseus.pg.host      — default: localhost
#    perseus.pg.port      — default: 5432
#    perseus.pg.user      — default: perseus
#    perseus.pg.template  — default: dev_template
#    perseus.pg.dbprefix  — default: perseus
#
#  Exit codes:
#    0  — success
#    1  — generic provisioning error
#    2  — invalid branch name (sanitization produced empty string)
#    3  — psql not found
#    4  — template database not found or not flagged datistemplate
#    5  — DB creation failed (likely concurrent connection on template)
#
#  Author:  Pierre Ribeiro <pierreribeiro@dinamotech.com.br>
#  Version: 2.0.0  (2026-04-30)
#  License: Internal — DinamoTech / Project Perseus
# =============================================================================

set -euo pipefail

# ----------------------------------------------------------------------------
#  Logging helpers (no external deps)
# ----------------------------------------------------------------------------
_log()      { printf "[postCreate] %s\n" "$*"; }
_info()     { printf "[postCreate] ℹ️  %s\n" "$*"; }
_ok()       { printf "[postCreate] ✅ %s\n" "$*"; }
_warn()     { printf "[postCreate] ⚠️  %s\n" "$*" >&2; }
_err()      { printf "[postCreate] ❌ %s\n" "$*" >&2; }
_die()      { _err "$1"; exit "${2:-1}"; }

# ----------------------------------------------------------------------------
#  Pre-flight checks
# ----------------------------------------------------------------------------
command -v psql >/dev/null 2>&1 || _die "psql not found in PATH" 3

: "${GTR_WORKTREE_PATH:?GTR_WORKTREE_PATH not set — are we running under gtr?}"
: "${GTR_BRANCH_NAME:?GTR_BRANCH_NAME not set — are we running under gtr?}"

# ----------------------------------------------------------------------------
#  Resolve configuration (git config → defaults)
# ----------------------------------------------------------------------------
_git_cfg() {
    # $1 = config key, $2 = default
    local v
    v="$(git -C "$GTR_WORKTREE_PATH" config --get "$1" 2>/dev/null || true)"
    [ -n "$v" ] && printf "%s" "$v" || printf "%s" "$2"
}

PG_HOST="$(_git_cfg perseus.pg.host    "${PERSEUS_PG_HOST:-localhost}")"
PG_PORT="$(_git_cfg perseus.pg.port    "${PERSEUS_PG_PORT:-5432}")"
PG_USER="$(_git_cfg perseus.pg.user    "${PERSEUS_PG_USER:-perseus}")"
PG_TEMPLATE="$(_git_cfg perseus.pg.template "${PERSEUS_PG_TEMPLATE:-dev_template}")"
DB_PREFIX="$(_git_cfg perseus.pg.dbprefix "${PERSEUS_DB_PREFIX:-perseus}")"

PG_ADMIN_URL="postgres://${PG_USER}@${PG_HOST}:${PG_PORT}/postgres"

# ----------------------------------------------------------------------------
#  Sanitize branch name → valid PostgreSQL identifier
#  Rules:
#    - lowercase
#    - replace [/.\- ] with underscores
#    - remove any other non-[a-z0-9_] chars
#    - prefix with $DB_PREFIX
#    - max 63 chars (PostgreSQL NAMEDATALEN)
# ----------------------------------------------------------------------------
_sanitize_db_name() {
    local raw="$1"
    local clean
    clean=$(printf '%s' "$raw" \
        | tr '[:upper:]' '[:lower:]' \
        | tr '/.\- ' '____' \
        | tr -cd 'a-z0-9_')
    [ -z "$clean" ] && return 1
    # Reserve room for prefix + underscore (e.g., "perseus_" = 8 chars)
    local prefix_len=$(( ${#DB_PREFIX} + 1 ))
    local max_clean=$(( 63 - prefix_len ))
    clean="${clean:0:$max_clean}"
    printf "%s_%s" "$DB_PREFIX" "$clean"
}

DB_NAME="$(_sanitize_db_name "$GTR_BRANCH_NAME")" || _die "Branch name '$GTR_BRANCH_NAME' produced empty DB name" 2
_info "Branch:    $GTR_BRANCH_NAME"
_info "Worktree:  $GTR_WORKTREE_PATH"
_info "DB name:   $DB_NAME"

# ----------------------------------------------------------------------------
#  Validate template database exists and is flagged datistemplate
# ----------------------------------------------------------------------------
TEMPLATE_OK=$(psql -X -At -v ON_ERROR_STOP=1 "$PG_ADMIN_URL" \
    -c "SELECT count(*) FROM pg_database WHERE datname='$PG_TEMPLATE' AND datistemplate;" \
    2>/dev/null || echo "0")

[ "$TEMPLATE_OK" = "1" ] || _die "Template '$PG_TEMPLATE' missing or not datistemplate=true" 4

# ----------------------------------------------------------------------------
#  Provision the per-branch database
#    1. Terminate any stale connections to the new DB name and to the template
#    2. DROP DATABASE IF EXISTS
#    3. CREATE DATABASE WITH TEMPLATE … STRATEGY=FILE_COPY
#  Note: file_copy_method=clone must be set cluster-wide via ALTER SYSTEM
# ----------------------------------------------------------------------------
_info "Provisioning database (STRATEGY=FILE_COPY, file_copy_method=clone)…"

START_TS=$(date +%s)

if ! psql -X -v ON_ERROR_STOP=1 "$PG_ADMIN_URL" >/dev/null 2>&1 <<-SQL
    SELECT pg_terminate_backend(pid)
      FROM pg_stat_activity
     WHERE datname IN ('${DB_NAME}', '${PG_TEMPLATE}')
       AND pid <> pg_backend_pid();
    DROP DATABASE IF EXISTS "${DB_NAME}";
    CREATE DATABASE "${DB_NAME}"
        WITH TEMPLATE = "${PG_TEMPLATE}"
             STRATEGY = FILE_COPY
             OWNER    = "${PG_USER}";
SQL
then
    _die "DB provisioning failed for '$DB_NAME' (check pg_stat_activity for live connections to '$PG_TEMPLATE')" 5
fi

ELAPSED=$(( $(date +%s) - START_TS ))
_ok "Database '${DB_NAME}' created in ${ELAPSED}s"

# ----------------------------------------------------------------------------
#  Generate per-worktree .env (NEVER commit; ensure .env is in .gitignore)
# ----------------------------------------------------------------------------
ENV_FILE="${GTR_WORKTREE_PATH}/.env"
DATABASE_URL="postgres://${PG_USER}@${PG_HOST}:${PG_PORT}/${DB_NAME}"

cat > "$ENV_FILE" <<-EOF
# =============================================================================
#  Auto-generated by gtr postCreate hook — DO NOT COMMIT
# =============================================================================
#  Generated: $(date '+%Y-%m-%d %H:%M:%S %Z')
#  Branch:    ${GTR_BRANCH_NAME}
#  Worktree:  ${GTR_WORKTREE_PATH}
# =============================================================================

PERSEUS_BRANCH=${GTR_BRANCH_NAME}
PERSEUS_DB_NAME=${DB_NAME}
PERSEUS_PG_HOST=${PG_HOST}
PERSEUS_PG_PORT=${PG_PORT}
PERSEUS_PG_USER=${PG_USER}
PERSEUS_PG_TEMPLATE=${PG_TEMPLATE}

# Standard libpq env vars (so plain psql works)
PGHOST=${PG_HOST}
PGPORT=${PG_PORT}
PGUSER=${PG_USER}
PGDATABASE=${DB_NAME}

# Application connection string
DATABASE_URL=${DATABASE_URL}
EOF

_ok ".env written: ${ENV_FILE}"

# ----------------------------------------------------------------------------
#  Optional: copy .env.example placeholders (when using gtr.copy.include)
#  This block is a safety net — if the team chooses to commit .env.example
#  with placeholders like {{DB_NAME}}, expand them here.
# ----------------------------------------------------------------------------
if [ -f "${GTR_WORKTREE_PATH}/.env.example" ]; then
    _info "Found .env.example — placeholder expansion skipped (use direnv or manual review)"
fi

# ----------------------------------------------------------------------------
#  Final summary for the developer
# ----------------------------------------------------------------------------
cat <<-EOF

  ┌─────────────────────────────────────────────────────────────────┐
  │  ✅  Worktree provisioning complete                              │
  ├─────────────────────────────────────────────────────────────────┤
  │  Branch     : ${GTR_BRANCH_NAME}
  │  Database   : ${DB_NAME}
  │  Connection : ${DATABASE_URL}
  │
  │  Quick start:
  │    cd "${GTR_WORKTREE_PATH}"
  │    source .env       # or use direnv
  │    psql              # connects via PGDATABASE
  │
  │  Run pgTAP tests:
  │    ./scripts/run-pgtap.sh
  │
  │  Open Claude Code:
  │    git gtr ai ${GTR_WORKTREE_NAME:-${GTR_BRANCH_NAME}}
  └─────────────────────────────────────────────────────────────────┘

EOF

exit 0
