#!/usr/bin/env bash
# =============================================================================
#  promote-dev-to-template.sh — Promote perseus_dev to dev_template
# =============================================================================
#  Purpose: Clone the developer's seed DB (perseus_dev) into the golden
#           template (dev_template) via PG18 FILE_COPY + APFS clone (~200ms).
#           Mark the resulting database as datistemplate=true so per-branch
#           worktree DBs can clone from it.
#
#  Flow (3 actors only):
#      perseus_dev  →  dev_template  →  perseus_<branch>
#      (seed)          (golden)         (worktree, via provision-branch-db.sh)
#
#  Usage:
#      ./scripts/promote-dev-to-template.sh
#      ./scripts/promote-dev-to-template.sh --force   # promote even with active branch DBs
#
#  IRON RULE: no hardcoded values — everything from .env.
#  Compatibility: bash 3.2+
#
#  Author:   Pierre Ribeiro <pierreribeiro@dinamotech.com.br>
#  Version:  1.0.0
# =============================================================================
 
set -euo pipefail
 
# ----------------------------------------------------------------------------
#  Paths & shared library
# ----------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
COMMON_LIB="$REPO_ROOT/infra/database/lib/common.sh"
ENV_FILE="$REPO_ROOT/infra/database/.env"
 
if [ ! -f "$COMMON_LIB" ]; then
    echo "[promote] ❌ Shared lib not found: $COMMON_LIB" >&2
    echo "[promote]    Hint: this script requires infra/database/lib/common.sh" >&2
    exit 1
fi
# shellcheck disable=SC1090
. "$COMMON_LIB"
 
# ----------------------------------------------------------------------------
#  Argument parsing
# ----------------------------------------------------------------------------
FORCE=0
while [ $# -gt 0 ]; do
    case "$1" in
        --force) FORCE=1; shift ;;
        --help|-h)
            cat <<-EOF
Usage: $0 [--force]
 
Promote perseus_dev → dev_template (PG18 FILE_COPY+clone).
 
Options:
  --force    Promote even when active branch DBs are detected.
  --help     Show this help.
 
Configuration: edit infra/database/.env (see .env.example).
EOF
            exit 0
            ;;
        *) log_die "Unknown argument: $1. Try --help." 1 ;;
    esac
done
 
# ----------------------------------------------------------------------------
#  Load env & validate prereqs
# ----------------------------------------------------------------------------
load_env "$ENV_FILE"
validate_prereqs
 
# Resolve required vars (with defaults from .env.example)
PG_HOST="${PERSEUS_PG_HOST}"
PG_PORT="${PERSEUS_PG_PORT}"
PG_SUPERUSER="${PERSEUS_PG_SUPERUSER}"
DB_OWNER="${PERSEUS_DB_OWNER}"
DEV_DB="${PERSEUS_DEV_DB_NAME}"
TEMPLATE_DB="${PERSEUS_TEMPLATE_DB_NAME:-dev_template}"
PII_HOOK="${PERSEUS_PII_SANITIZE_HOOK:-}"
 
PG_ADMIN_URL="postgres://${PG_SUPERUSER}@${PG_HOST}:${PG_PORT}/postgres"
 
log_info "Promoting '${DEV_DB}' → '${TEMPLATE_DB}'"
log_info "  Host: ${PG_HOST}:${PG_PORT}  Owner: ${DB_OWNER}  Mode: $([ $FORCE -eq 1 ] && echo FORCE || echo SAFE)"
 
# ----------------------------------------------------------------------------
#  Step 1 — Cluster up?
# ----------------------------------------------------------------------------
if ! pg_isready -h "$PG_HOST" -p "$PG_PORT" -q 2>/dev/null; then
    log_die "Cluster not running at ${PG_HOST}:${PG_PORT}
   Hint: ./infra/database/init-db.sh start" 10
fi
 
# ----------------------------------------------------------------------------
#  Step 2 — perseus_dev exists and is NOT empty?
# ----------------------------------------------------------------------------
DEV_EXISTS=$(psql -X -At -v ON_ERROR_STOP=1 "$PG_ADMIN_URL" \
    -c "SELECT count(*) FROM pg_database WHERE datname='${DEV_DB}';" 2>/dev/null || echo "0")
 
if [ "$DEV_EXISTS" != "1" ]; then
    log_die "Source database '${DEV_DB}' does not exist
   Hint: ./infra/database/init-db.sh init  then populate ${DEV_DB} from production data" 11
fi
 
# Count user-defined relations to check non-empty (anything in non-system schemas)
DEV_OBJ_COUNT=$(psql -X -At -v ON_ERROR_STOP=1 \
    "postgres://${PG_SUPERUSER}@${PG_HOST}:${PG_PORT}/${DEV_DB}" \
    -c "SELECT count(*) FROM pg_class
         WHERE relnamespace NOT IN (
           SELECT oid FROM pg_namespace
            WHERE nspname IN ('pg_catalog','information_schema','pg_toast')
              OR nspname LIKE 'pg_temp_%'
              OR nspname LIKE 'pg_toast_temp_%'
         );" 2>/dev/null || echo "0")
 
if [ "$DEV_OBJ_COUNT" -lt 1 ]; then
    log_die "Source database '${DEV_DB}' appears empty (no user objects)
   Hint: populate ${DEV_DB} from production data before promoting" 12
fi
log_ok "Source '${DEV_DB}' validated (${DEV_OBJ_COUNT} user objects)"
 
# ----------------------------------------------------------------------------
#  Step 3 — file_copy_method = clone?
# ----------------------------------------------------------------------------
FCM=$(psql -X -At "$PG_ADMIN_URL" -c "SHOW file_copy_method;" 2>/dev/null || echo "")
if [ "$FCM" != "clone" ]; then
    log_warn "file_copy_method='${FCM}' (expected 'clone')"
    log_warn "  → clone will fall back to byte-copy, which may be SLOW on large DBs"
    log_warn "  → fix: ALTER SYSTEM SET file_copy_method='clone'; SELECT pg_reload_conf();"
fi
 
# ----------------------------------------------------------------------------
#  Step 4 — Active branch DBs check (edge case #2)
# ----------------------------------------------------------------------------
# Find any DB whose name starts with the perseus_ prefix EXCLUDING dev/template
ACTIVE_BRANCHES=$(psql -X -At "$PG_ADMIN_URL" -c "
    SELECT datname FROM pg_database
     WHERE datname LIKE 'perseus_%'
       AND datname NOT IN ('${DEV_DB}', '${TEMPLATE_DB}')
       AND datname NOT LIKE '%_eph_%'
     ORDER BY datname;" 2>/dev/null || echo "")
 
if [ -n "$ACTIVE_BRANCHES" ]; then
    log_warn "Detected branch DBs cloned from a previous template version:"
    while IFS= read -r b; do
        [ -n "$b" ] && log_warn "    - $b"
    done <<< "$ACTIVE_BRANCHES"
    log_warn "After this promotion they will be STALE (point to old data)."
    if [ $FORCE -eq 0 ]; then
        log_die "Refusing to promote with active branches present.
   Hint: drop the branch DBs first (git gtr rm <worktree>) OR re-run with --force" 13
    fi
    log_warn "  → proceeding because --force was given"
fi
 
# ----------------------------------------------------------------------------
#  Step 5 — PII sanitization hook (placeholder)
# ----------------------------------------------------------------------------
if [ -n "$PII_HOOK" ]; then
    PII_HOOK_PATH="$REPO_ROOT/$PII_HOOK"
    if [ -x "$PII_HOOK_PATH" ]; then
        log_info "Running PII sanitization hook: $PII_HOOK"
        "$PII_HOOK_PATH" "$DEV_DB" || log_die "PII hook failed" 14
    else
        log_warn "PII hook configured but not executable: $PII_HOOK_PATH"
        log_warn "  → skipping (configure chmod +x if you want it to run)"
    fi
else
    log_warn "No PII sanitization hook configured (PERSEUS_PII_SANITIZE_HOOK unset)"
    log_warn "  → mandatory before any production data flows here"
fi
 
# ----------------------------------------------------------------------------
#  Step 6 — Drop existing template (unflag, terminate, drop)
# ----------------------------------------------------------------------------
TEMPLATE_EXISTS=$(psql -X -At "$PG_ADMIN_URL" \
    -c "SELECT count(*) FROM pg_database WHERE datname='${TEMPLATE_DB}';" 2>/dev/null || echo "0")
 
if [ "$TEMPLATE_EXISTS" = "1" ]; then
    log_info "Dropping existing '${TEMPLATE_DB}'…"
    psql -X -v ON_ERROR_STOP=1 "$PG_ADMIN_URL" >/dev/null <<-SQL
        UPDATE pg_database SET datistemplate=false WHERE datname='${TEMPLATE_DB}';
        SELECT pg_terminate_backend(pid)
          FROM pg_stat_activity
         WHERE datname='${TEMPLATE_DB}' AND pid<>pg_backend_pid();
        DROP DATABASE IF EXISTS "${TEMPLATE_DB}";
SQL
    log_ok "Existing template dropped"
fi
 
# ----------------------------------------------------------------------------
#  Step 7 — Terminate connections to source and clone
# ----------------------------------------------------------------------------
log_info "Cloning '${DEV_DB}' → '${TEMPLATE_DB}' (FILE_COPY+clone)…"
START_TS=$(date +%s)
 
psql -X -v ON_ERROR_STOP=1 "$PG_ADMIN_URL" >/dev/null <<-SQL
    SELECT pg_terminate_backend(pid)
      FROM pg_stat_activity
     WHERE datname='${DEV_DB}' AND pid<>pg_backend_pid();
 
    CREATE DATABASE "${TEMPLATE_DB}"
        WITH TEMPLATE = "${DEV_DB}"
             STRATEGY = FILE_COPY
             OWNER    = "${DB_OWNER}";
SQL
 
ELAPSED=$(( $(date +%s) - START_TS ))
log_ok "Clone complete in ${ELAPSED}s"
 
# ----------------------------------------------------------------------------
#  Step 8 — Mark as template (datistemplate=true)
# ----------------------------------------------------------------------------
psql -X -v ON_ERROR_STOP=1 "$PG_ADMIN_URL" \
    -c "UPDATE pg_database SET datistemplate=true WHERE datname='${TEMPLATE_DB}';" \
    >/dev/null
log_ok "'${TEMPLATE_DB}' marked as datistemplate=true"
 
# ----------------------------------------------------------------------------
#  Step 9 — Smoke test: clone template into a throwaway DB, then drop
# ----------------------------------------------------------------------------
SMOKE_DB="${TEMPLATE_DB}_smoke_$$"
log_info "Smoke test: cloning into throwaway '${SMOKE_DB}'…"
psql -X -v ON_ERROR_STOP=1 "$PG_ADMIN_URL" >/dev/null <<-SQL
    CREATE DATABASE "${SMOKE_DB}"
        WITH TEMPLATE = "${TEMPLATE_DB}"
             STRATEGY = FILE_COPY
             OWNER    = "${DB_OWNER}";
    DROP DATABASE "${SMOKE_DB}";
SQL
log_ok "Smoke test passed — template is operationally ready"
 
# ----------------------------------------------------------------------------
#  Summary
# ----------------------------------------------------------------------------
cat <<-EOF
 
  ┌─────────────────────────────────────────────────────────────────┐
  │  ✅  Template promotion complete                                  │
  ├─────────────────────────────────────────────────────────────────┤
  │  Source       : ${DEV_DB}
  │  Template     : ${TEMPLATE_DB}  (datistemplate=true)
  │  Elapsed      : ${ELAPSED}s
  │  Smoke test   : PASS
  │
  │  Next: any worktree provisioned via 'git gtr new' will now clone
  │        from '${TEMPLATE_DB}' (via scripts/provision-branch-db.sh).
  └─────────────────────────────────────────────────────────────────┘
 
EOF
exit 0