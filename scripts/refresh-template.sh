#!/usr/bin/env bash
# =============================================================================
#  refresh-template.sh — Rebuild the dev_template golden DB from STAGING
# =============================================================================
#  Purpose: Re-import the latest STAGING snapshot into dev_template.
#           Intended for weekly cron or manual monthly runs.
#
#  PII SANITIZATION: This script must apply data masking before flagging
#  the new template as datistemplate=true. THIS IS NON-NEGOTIABLE for
#  LGPD compliance.
# =============================================================================

set -euo pipefail

DUMP_FILE="${1:-}"
[ -z "$DUMP_FILE" ] && { echo "Usage: refresh-template.sh <staging_dump.dump>"; exit 1; }
[ -f "$DUMP_FILE" ] || { echo "Dump file not found: $DUMP_FILE"; exit 1; }

PG_USER="${PERSEUS_PG_USER:-perseus}"
PG_TEMPLATE="${PERSEUS_PG_TEMPLATE:-dev_template}"
PG_ADMIN_URL="postgres://${PG_USER}@localhost:5432/postgres"

echo "🔄 Refreshing $PG_TEMPLATE from $DUMP_FILE…"

# Step 1: terminate connections
psql -X "$PG_ADMIN_URL" <<-SQL
    SELECT pg_terminate_backend(pid) FROM pg_stat_activity
      WHERE datname='${PG_TEMPLATE}' AND pid<>pg_backend_pid();
    UPDATE pg_database SET datistemplate=false WHERE datname='${PG_TEMPLATE}';
SQL

# Step 2: drop and recreate
psql -X "$PG_ADMIN_URL" -c "DROP DATABASE IF EXISTS ${PG_TEMPLATE};"
psql -X "$PG_ADMIN_URL" -c "CREATE DATABASE ${PG_TEMPLATE} OWNER ${PG_USER};"

# Step 3: restore
pg_restore -v -d "postgres://${PG_USER}@localhost/${PG_TEMPLATE}" "$DUMP_FILE"

# ⚠️ Step 4: PII SANITIZATION (MANDATORY)
echo "⚠️  Applying PII sanitization…"
psql -X -v ON_ERROR_STOP=1 -d "$PG_TEMPLATE" -U "$PG_USER" <<-SQL
    -- EXAMPLE rules — adapt to your schema!
    UPDATE users
       SET email = 'user_' || id || '@example.test',
           phone = '+5500000000' || lpad(id::text, 5, '0'),
           cpf   = lpad(id::text, 11, '0');
    UPDATE customers
       SET tax_id = lpad(id::text, 14, '0');
    -- TODO: extend for every PII column in the schema
SQL

# Step 5: VACUUM ANALYZE
psql -X -d "$PG_TEMPLATE" -U "$PG_USER" -c "VACUUM (ANALYZE, INDEX_CLEANUP ON);"

# Step 6: flag as template
psql -X "$PG_ADMIN_URL" -c "UPDATE pg_database SET datistemplate=true WHERE datname='${PG_TEMPLATE}';"

echo "✅ Template refreshed."

# Optional: refresh existing branches
echo ""
read -p "Refresh existing per-branch DBs (drop + re-clone)? [y/N] " yn
if [ "$yn" = "y" ] || [ "$yn" = "Y" ]; then
    for db in $(psql -At "$PG_ADMIN_URL" -c "
        SELECT datname FROM pg_database
         WHERE datname LIKE 'perseus_%'
           AND datname<>'${PG_TEMPLATE}'
           AND datname NOT LIKE '%_eph_%';"); do
        echo "  Refreshing $db…"
        psql -X "$PG_ADMIN_URL" <<-SQL
            SELECT pg_terminate_backend(pid) FROM pg_stat_activity
              WHERE datname IN ('${db}','${PG_TEMPLATE}') AND pid<>pg_backend_pid();
            DROP DATABASE IF EXISTS ${db};
            CREATE DATABASE ${db}
                WITH TEMPLATE = ${PG_TEMPLATE}
                     STRATEGY = FILE_COPY
                     OWNER = ${PG_USER};
SQL
        echo "    ✅ $db refreshed"
    done
fi