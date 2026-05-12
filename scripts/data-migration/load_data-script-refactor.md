# New `load_data.sh` — Load CSVs into Local PostgreSQL
## Problem Statement
The existing `load-data.sh` loads CSV data into PostgreSQL **inside a Docker container** using `docker exec ... psql`. A new script is needed that targets a **local PostgreSQL instance on localhost**, authenticates via a pre-configured `.pgpass` file, and reads all configuration from a `.env` file.
## Current State
* **Existing `load-data.sh`** (276 lines): Functional, but tightly coupled to Docker (`docker exec "$DB_CONTAINER" psql …`). This is the only part that changes — the tier structure, table lists, FK-trigger management logic, and validation approach are all reusable.
* **Tier structure** (76 tables across 5 tiers, dependency-ordered) is well-defined and battle-tested.
* **CSV naming convention**: `##perseus_tier_{N}_{table_name}.csv` (no header row, comma-delimited).
* **`.env.example`** currently only covers SQL Server extraction variables. It needs PostgreSQL-specific variables for the load side.
## Proposed Changes
### 1. New `.env` variables for `load_data.sh`
Add the following to `.env.example` (under a new `# PostgreSQL Load Settings` section):
* `PG_HOST` — PostgreSQL hostname (default: `localhost`)
* `PG_PORT` — PostgreSQL port (default: `5432`)
* `PG_DATABASE` — Target database name (default: `perseus_dev`)
* `PG_USER` — PostgreSQL user (default: `perseus_admin`)
* `PG_SCHEMA` — Target schema (default: `perseus`)
* `DATA_DIR` — Path to CSV directory (reuses existing var, default: `/tmp/perseus-data-export`)
* `LOG_DIR` — Directory for log files (default: `./logs`)
Authentication is **not** stored in `.env` — it is handled by `~/.pgpass` per the requirements.
### 2. Create `load_data.sh`
New script at `scripts/data-migration/load_data.sh`. Core design:
**a) Configuration loading**
* Source `.env` from the script directory (same pattern as `extract-data.sh`).
* Apply defaults for any missing variable.
* Build `PSQL_CMD` once: `psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$PG_DATABASE" -v ON_ERROR_STOP=1`.
**b) Pre-flight checks**
* Verify `psql` is installed.
* Verify `DATA_DIR` exists and contains CSV files.
* Test database connectivity (`$PSQL_CMD -c 'SELECT 1'`) — will fail if `.pgpass` is missing/incorrect.
* Verify target schema exists.
**c) FK-trigger management**
Same approach as existing script (proven to work):
* `disable_fk_triggers()` — `ALTER TABLE … DISABLE TRIGGER ALL` for all tables in the schema.
* `enable_fk_triggers()` — re-enable after load.
Since `psql` connects directly (no Docker exec boundary), a single session can use `SET session_replication_role = 'replica'` instead of per-table ALTER TABLE. This is simpler and more efficient. We'll use this approach with a fallback note.
**d) Tier-ordered loading**
Reuse the exact 5-tier table arrays from existing `load-data.sh` (lines 187-275). For each table:
1. `TRUNCATE perseus.{table} CASCADE` (unless `--no-truncate`).
2. `\copy perseus.{table} FROM '{csv_path}' WITH (FORMAT CSV, HEADER false, DELIMITER ',')`.
    * Uses `\copy` (client-side) instead of `COPY FROM STDIN` piped through Docker — simpler and works with local psql.
3. Log row count after load.
Missing or empty CSV files are warnings, not errors (same as existing behavior).
**e) CLI options**
Same interface as existing script for familiarity:
* `--validate-only` — Run validation SQL only.
* `--tier N` — Load specific tier (0-4).
* `--no-truncate` — Append mode.
* `--help` — Usage info.
**f) Logging**
* Log file written to `$LOG_DIR/load_data-{timestamp}.log`.
* Color-coded terminal output (same pattern as `extract-data.sh`).
* Summary at end: tables loaded, rows loaded, duration, failures.
**g) Validation (post-load)**
Run `validate-referential-integrity.sql` via `psql -f` after loading all tiers. Also print table count, total rows, and FK constraint count (same as existing final validation block).
**h) Error handling**
* `set -euo pipefail`.
* Trap `EXIT` to re-enable FK triggers if script fails mid-load.
* Non-zero exit on any COPY failure.
### 3. Update `.env.example`
Append the PostgreSQL load variables from item 1 above, with documentation comments.
### 4. Summary of key differences from existing `load-data.sh`
* `psql` called directly — no `docker exec`.
* Authentication via `.pgpass` — no password variables in `.env`.
* `\copy` (client-side) instead of `COPY … FROM STDIN` piped through Docker stdin.
* `session_replication_role = 'replica'` for FK deferral (single session, more efficient).
* Log file goes to `$LOG_DIR` (configurable) instead of hardcoded `$SCRIPT_DIR/load-data.log`.
* Adds pre-flight connectivity check.
