#!/usr/bin/env bash
# =============================================================================
#  run-pgtap.sh — Smart pgTAP runner (stateless vs ephemeral DB)
#  v2.1: ephemeral cycle empirically validated at < 3 s
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
[ -f "$WT_ROOT/.env" ] || { echo "❌ .env not found"; exit 1; }
set -a; . "$WT_ROOT/.env"; set +a

PG_ADMIN_URL="postgres://${PERSEUS_PG_USER}@${PERSEUS_PG_HOST}:${PERSEUS_PG_PORT}/postgres"

run_test() {
    local file="$1"
    if [[ "$file" == */tests/procedures/* ]]; then
        local stem
        stem=$(basename "$file" .sql | tr -c 'a-z0-9' '_')
        local eph="${PERSEUS_DB_NAME}_eph_${stem}_$$"
        echo "🧪 [ephemeral] $file → $eph"
        psql -X -v ON_ERROR_STOP=1 "$PG_ADMIN_URL" >/dev/null <<-SQL
            SELECT pg_terminate_backend(pid) FROM pg_stat_activity
              WHERE datname='${PERSEUS_PG_TEMPLATE}' AND pid<>pg_backend_pid();
            CREATE DATABASE "${eph}"
                WITH TEMPLATE = "${PERSEUS_PG_TEMPLATE}"
                     STRATEGY = FILE_COPY
                     OWNER = "${PERSEUS_PG_USER}";
SQL
        local rc=0
        pg_prove -d "$eph" -h "$PERSEUS_PG_HOST" -p "$PERSEUS_PG_PORT" \
                 -U "$PERSEUS_PG_USER" "$file" || rc=$?
        psql -X "$PG_ADMIN_URL" -c "DROP DATABASE IF EXISTS \"${eph}\";" >/dev/null
        return $rc
    else
        echo "🧪 [stateless] $file"
        pg_prove -d "$PERSEUS_DB_NAME" -h "$PERSEUS_PG_HOST" -p "$PERSEUS_PG_PORT" \
                 -U "$PERSEUS_PG_USER" "$file"
    fi
}

if [ $# -eq 0 ]; then
    failures=0
    for f in "$WT_ROOT"/tests/**/*.sql; do
        run_test "$f" || failures=$((failures+1))
    done
    exit $failures
else
    for f in "$@"; do run_test "$f"; done
fi