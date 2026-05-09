#!/usr/bin/env bash
# =============================================================================
#  init-db.sh — Perseus PG18 infrastructure orchestrator (native, no Docker)
# =============================================================================
#  Commands:
#    init       Initialize cluster from scratch (initdb + role + DB + extensions)
#    start      Start the cluster
#    stop       Stop the cluster
#    restart    Stop + start
#    status     Show cluster status and connection info
#    shell      Connect to perseus_dev as perseus_owner via psql
#    destroy    Stop + wipe PGDATA (DESTRUCTIVE)
#    recreate   destroy + init + start
#    help       Show this help
#
#  Role hierarchy:
#    - postgres       (SUPERUSER, owns 'postgres' system DB)
#    - perseus_owner  (LOGIN+CREATEDB, owns 'perseus_dev' + perseus* schemas)
#
#  All configuration comes from .env (see .env.example).
#  IRON RULE: no hardcoded values.
#  Compatibility: bash 3.2+
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"
TEMPLATE_FILE="$SCRIPT_DIR/postgresql.conf.template"
INIT_SQL="$SCRIPT_DIR/init-scripts/01-init-database.sql"
export PG_VERSION="18"
export PG_BIN="/opt/homebrew/opt/postgresql@$PG_VERSION/bin"
export PG_CONFIG="$PG_BIN/pg_config"
export GETTEXT_PREFIX=$(brew --prefix gettext)
export PERL5_DIR="$HOME/perl5"


# Source shared helpers
# shellcheck disable=SC1091
. "$SCRIPT_DIR/lib/common.sh"

# ----------------------------------------------------------------------------
#  Commands
# ----------------------------------------------------------------------------

cmd_init() {
    load_env "$ENV_FILE"
    validate_prereqs

    log_info "Initializing Perseus PG18 cluster"
    log_info "  PGDATA:    $PERSEUS_PGDATA_DIR"
    log_info "  Superuser: $PERSEUS_PG_SUPERUSER"
    log_info "  DB owner:  $PERSEUS_DB_OWNER"
    log_info "  Database:  $PERSEUS_DB_NAME"

    # Idempotency guard
    if [ -f "$PERSEUS_PGDATA_DIR/PG_VERSION" ]; then
        log_die "PGDATA already initialized at $PERSEUS_PGDATA_DIR
   Hint: use './init-db.sh recreate' to wipe and reinitialize" 10
    fi

    # 1. Create PGDATA parent (handles the v18/pgdata/ subdirectory creation)
    mkdir -p "$PERSEUS_PGDATA_DIR"
    chmod 700 "$PERSEUS_PGDATA_DIR"

    # 2. Run initdb — creates the cluster with 'postgres' as SUPERUSER
    log_info "Running initdb (encoding=$PERSEUS_PG_ENCODING, locale=$PERSEUS_PG_LOCALE)…"
    initdb \
        --pgdata="$PERSEUS_PGDATA_DIR" \
        --encoding="$PERSEUS_PG_ENCODING" \
        --locale="$PERSEUS_PG_LOCALE" \
        --auth-local=trust \
        --auth-host=md5 \
        --data-checksums \
        --username="$PERSEUS_PG_SUPERUSER" \
        --no-instructions \
        > /dev/null
    log_ok "Cluster initialized (superuser: $PERSEUS_PG_SUPERUSER)"

    # 3. Render postgresql.conf
    log_info "Rendering postgresql.conf from template…"
    render_template "$TEMPLATE_FILE" "$PERSEUS_PGDATA_DIR/postgresql.conf"
    log_ok "postgresql.conf written"

    # 4. Append authentication rules to pg_hba.conf
    cat > "$PERSEUS_PGDATA_DIR/pg_hba.conf" <<-EOF

# Perseus local development access
local   all   $PERSEUS_PG_SUPERUSER  trust
local   all   $PERSEUS_DB_OWNER      md5
host    all   $PERSEUS_PG_SUPERUSER  127.0.0.1/32  trust
host    all   $PERSEUS_PG_SUPERUSER  ::1/128       trust
host    all   $PERSEUS_DB_OWNER      127.0.0.1/32  md5
host    all   $PERSEUS_DB_OWNER      ::1/128       md5
EOF

    # 5. Start cluster
    cmd_start

    # 6. Generate password and create the application owner role + database
    local pwd
    pwd=$(generate_password)

    log_info "Creating role '$PERSEUS_DB_OWNER' and database '$PERSEUS_DB_NAME'…"
    PGPASSWORD="" psql -X -v ON_ERROR_STOP=1 \
        -h "$PERSEUS_PG_HOST" -p "$PERSEUS_PG_PORT" \
        -U "$PERSEUS_PG_SUPERUSER" -d postgres <<-SQL
        -- Application owner role: NOT a superuser; can log in and create DBs
        CREATE ROLE $PERSEUS_DB_OWNER
            WITH LOGIN
                 CREATEDB
                 SUPERUSER
                 CREATEROLE
                 PASSWORD '$pwd';

        -- Application database, owned by the application owner role
        CREATE DATABASE $PERSEUS_DB_NAME
            WITH OWNER      = $PERSEUS_DB_OWNER
                 ENCODING   = '$PERSEUS_PG_ENCODING'
                 LC_COLLATE = '$PERSEUS_PG_LOCALE'
                 LC_CTYPE   = '$PERSEUS_PG_LOCALE'
                 TEMPLATE   = template0;
SQL
    log_ok "Role '$PERSEUS_DB_OWNER' and database '$PERSEUS_DB_NAME' created"

    # 7. Run init SQL connected as perseus_owner (extensions, schemas, audit, etc.)
    log_info "Running 01-init-database.sql as $PERSEUS_DB_OWNER"
    PGPASSWORD="$pwd" psql -X -v ON_ERROR_STOP=1 \
        -h "$PERSEUS_PG_HOST" -p "$PERSEUS_PG_PORT" \
        -U "$PERSEUS_DB_OWNER" -d "$PERSEUS_DB_NAME" \
        -f "$INIT_SQL" > /dev/null
    log_ok "Initialization SQL applied"

    # 8. Print password and ~/.pgpass instructions
    cat <<-EOF

  ┌─────────────────────────────────────────────────────────────────┐
  │  ✅  Perseus PG18 cluster initialized and running                │
  ├─────────────────────────────────────────────────────────────────┤
  │  Host       : $PERSEUS_PG_HOST
  │  Port       : $PERSEUS_PG_PORT
  │  Superuser  : $PERSEUS_PG_SUPERUSER (no password — local trust)
  │  Database   : $PERSEUS_DB_NAME
  │  DB Owner   : $PERSEUS_DB_OWNER
  │  Password   : $pwd
  │  PGDATA     : $PERSEUS_PGDATA_DIR
  │
  │  🔐 ACTION REQUIRED: add this line to ~/.pgpass:
  │
  │    $PERSEUS_PG_HOST:$PERSEUS_PG_PORT:*:$PERSEUS_DB_OWNER:$pwd
  │
  │  Then:  chmod 600 ~/.pgpass
  │
  │  Quick start:
  │    ./init-db.sh shell      # connect as $PERSEUS_DB_OWNER via psql
  │    ./init-db.sh status     # health check
  │
  │  Admin access (no password needed locally):
  │    psql -U $PERSEUS_PG_SUPERUSER -d postgres
  └─────────────────────────────────────────────────────────────────┘

EOF
}

cmd_start() {
    load_env "$ENV_FILE"
    validate_prereqs

    if [ ! -f "$PERSEUS_PGDATA_DIR/PG_VERSION" ]; then
        log_die "Cluster not initialized at $PERSEUS_PGDATA_DIR
   Hint: run './init-db.sh init' first" 11
    fi

    if [ -d "$PERSEUS_PGDATA_DIR/pg_log" ] && [ -f "$PERSEUS_PGDATA_DIR/pg_log/startup.log" ]; then
        echo "Success: Both the directory and the file exist."
    else
        echo "Directory $PERSEUS_PGDATA_DIR/pg_log not found. Creating it..."
        mkdir -p "$PERSEUS_PGDATA_DIR/pg_log"
        echo "File $PERSEUS_PGDATA_DIR/pg_log/startup.log not found. Creating it..."
        touch "$PERSEUS_PGDATA_DIR/pg_log/startup.log"
    fi

    if pg_isready -h "$PERSEUS_PG_HOST" -p "$PERSEUS_PG_PORT" -q 2>/dev/null; then
        log_ok "Cluster is already running"
        return 0
    fi

    log_info "Starting cluster…"
    pg_ctl start \
        -D "$PERSEUS_PGDATA_DIR" \
        -l "$PERSEUS_PGDATA_DIR/pg_log/startup.log" \
        -w \
        -t 30 \
        > /dev/null
    log_ok "Cluster started"
}

cmd_stop() {
    load_env "$ENV_FILE"
    validate_prereqs

    if ! pg_isready -h "$PERSEUS_PG_HOST" -p "$PERSEUS_PG_PORT" -q 2>/dev/null; then
        log_ok "Cluster already stopped"
        return 0
    fi

    log_info "Stopping cluster…"
    pg_ctl stop -D "$PERSEUS_PGDATA_DIR" -m fast -w -t 30 > /dev/null
    log_ok "Cluster stopped"
}

cmd_restart() {
    cmd_stop
    cmd_start
}

cmd_status() {
    load_env "$ENV_FILE"
    validate_prereqs

    if [ ! -f "$PERSEUS_PGDATA_DIR/PG_VERSION" ]; then
        log_warn "Cluster not initialized at $PERSEUS_PGDATA_DIR"
        return 1
    fi

    if pg_isready -h "$PERSEUS_PG_HOST" -p "$PERSEUS_PG_PORT" -q 2>/dev/null; then
        local pid
        pid=$(cat "$PERSEUS_PGDATA_DIR/postmaster.pid" | head -1 || echo "?")
        log_ok "Cluster running (PID $pid)"
        log_info "  Host:      $PERSEUS_PG_HOST"
        log_info "  Port:      $PERSEUS_PG_PORT"
        log_info "  Database:  $PERSEUS_DB_NAME"
        log_info "  Owner:     $PERSEUS_DB_OWNER"
        log_info "  Superuser: $PERSEUS_PG_SUPERUSER"
        log_info "  PGDATA:    $PERSEUS_PGDATA_DIR"
    else
        log_warn "Cluster initialized but NOT running"
        log_info "  Hint: ./init-db.sh start"
    fi
}

cmd_shell() {
    load_env "$ENV_FILE"
    validate_prereqs

    if ! pg_isready -h "$PERSEUS_PG_HOST" -p "$PERSEUS_PG_PORT" -q 2>/dev/null; then
        log_die "Cluster not running. Run './init-db.sh start' first." 12
    fi

    # Connect as the application owner — uses ~/.pgpass for authentication
    exec psql \
        -h "$PERSEUS_PG_HOST" \
        -p "$PERSEUS_PG_PORT" \
        -U "$PERSEUS_DB_OWNER" \
        -d "$PERSEUS_DB_NAME"
}

cmd_destroy() {
    load_env "$ENV_FILE"
    validate_prereqs

    log_warn "This will PERMANENTLY DELETE all data at $PERSEUS_PGDATA_DIR"
    printf "Type 'yes' to confirm: "
    read -r confirm
    if [ "$confirm" != "yes" ]; then
        log_info "Cancelled"
        return 0
    fi

    # Stop if running
    if pg_isready -h "$PERSEUS_PG_HOST" -p "$PERSEUS_PG_PORT" -q 2>/dev/null; then
        cmd_stop
    fi

    if [ -d "$PERSEUS_PGDATA_DIR" ]; then
        rm -rf "$PERSEUS_PGDATA_DIR"
        log_ok "PGDATA wiped: $PERSEUS_PGDATA_DIR"
    fi
}

cmd_recreate() {
    cmd_destroy
    cmd_init
}

cmd_help() {
    cat <<-EOF
Perseus PG18 Infrastructure — init-db.sh

Usage: $0 <command>

Commands:
  init       Initialize cluster from scratch
  start      Start the cluster
  stop       Stop the cluster
  restart    Stop + start
  status     Show cluster status
  shell      Connect via psql as DB owner
  destroy    Stop + wipe PGDATA (DESTRUCTIVE)
  recreate   destroy + init + start
  help       Show this help

Configuration: edit .env (see .env.example).

Role hierarchy:
  postgres       — cluster superuser (DBA admin)
  perseus_owner  — application owner (DB + schemas)
EOF
}

# ----------------------------------------------------------------------------
#  Main
# ----------------------------------------------------------------------------
case "${1:-help}" in
    init)     cmd_init ;;
    start)    cmd_start ;;
    stop)     cmd_stop ;;
    restart)  cmd_restart ;;
    status)   cmd_status ;;
    shell)    cmd_shell ;;
    destroy)  cmd_destroy ;;
    recreate) cmd_recreate ;;
    help|-h|--help) cmd_help ;;
    *)        log_error "Unknown command: $1"; cmd_help; exit 1 ;;
esac