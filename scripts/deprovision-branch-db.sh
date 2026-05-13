#!/usr/bin/env bash
# =============================================================================
#  deprovision-branch-db.sh — Safe per-branch DB removal
# =============================================================================
#  Purpose: Dump (safety net) and drop a per-branch DB.
#           Called by preRemove.sh; also runnable manually.
#
#  Usage:
#    deprovision-branch-db.sh --branch feat/users-rbac [--no-dump] [--force]
#
#  Idempotent: safe to call on a non-existent DB (drop is IF EXISTS).
# =============================================================================

set -euo pipefail

_die() { echo "[deprovision] ❌ $1" >&2; exit "${2:-1}"; }

BRANCH_NAME=""
SKIP_DUMP=0
FORCE=0
while [ $# -gt 0 ]; do
    case "$1" in
        --branch)   BRANCH_NAME="$2"; shift 2 ;;
        --no-dump)  SKIP_DUMP=1;      shift   ;;
        --force)    FORCE=1;          shift   ;;
        *) _die "Unknown argument: $1" 1 ;;
    esac
done

[ -z "$BRANCH_NAME" ] && _die "--branch required"

PG_HOST="${PERSEUS_PG_HOST:-localhost}"
PG_PORT="${PERSEUS_PG_PORT:-5432}"
PG_USER="${PERSEUS_PG_USER:-perseus}"
DB_PREFIX="${PERSEUS_DB_PREFIX:-perseus}"

# Sanitize (same as provision)
clean=$(printf '%s' "$BRANCH_NAME" \
    | tr '[:upper:]' '[:lower:]' \
    | tr '/.\- ' '____' \
    | tr -cd 'a-z0-9_')
[ -z "$clean" ] && _die "Branch produced empty DB name" 2
DB_NAME="${DB_PREFIX}_${clean:0:55}"

PG_ADMIN_URL="postgres://${PG_USER}@${PG_HOST}:${PG_PORT}/postgres"

# Confirm if not --force (preRemove always passes --force)
if [ $FORCE -eq 0 ]; then
    printf "About to drop database '%s'. Continue? [y/N] " "$DB_NAME"
    read -r yn
    [ "$yn" = "y" ] || [ "$yn" = "Y" ] || { echo "Aborted."; exit 0; }
fi

# Dump (safety net)
if [ $SKIP_DUMP -eq 0 ]; then
    DUMP_DIR="$HOME/.perseus/branch-dumps"
    mkdir -p "$DUMP_DIR"
    DUMP_FILE="$DUMP_DIR/${DB_NAME}_$(date +%Y%m%d_%H%M%S).dump"
    echo "[deprovision] 🛡️  Dumping to $DUMP_FILE…"
    if pg_dump -Fc -d "$DB_NAME" -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" \
               -f "$DUMP_FILE" 2>/dev/null; then
        echo "[deprovision] ✅ Dump saved"
    else
        echo "[deprovision] ⚠️  Dump skipped (DB may not exist)"
    fi
fi

# Drop
echo "[deprovision] 🧹 Dropping database '$DB_NAME'…"
psql -X -v ON_ERROR_STOP=1 "$PG_ADMIN_URL" <<-SQL
    SELECT pg_terminate_backend(pid)
      FROM pg_stat_activity
     WHERE datname='${DB_NAME}' AND pid<>pg_backend_pid();
    DROP DATABASE IF EXISTS "${DB_NAME}";
SQL
echo "[deprovision] ✅ Database '$DB_NAME' dropped"