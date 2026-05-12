# load_data.sh — Local PostgreSQL CSV Loader

**Purpose:** Load CSV data exported from SQL Server into a **local PostgreSQL instance** (running outside Docker) using `psql` with `.pgpass` authentication.

**Replaces:** `load-data.sh` (Docker-based loader). Use this script when PostgreSQL runs directly on the host.

---

## Prerequisites

### 1. PostgreSQL Client

`psql` must be installed and available in `$PATH`.

```bash
# macOS (Homebrew)
brew install libpq && brew link --force libpq

# Verify
psql --version
```

### 2. ~/.pgpass Authentication

The script authenticates exclusively via `~/.pgpass` — no passwords are stored in `.env` or passed via CLI.

```bash
# Create or edit ~/.pgpass
# Format: hostname:port:database:username:password
echo 'localhost:5432:perseus_dev:perseus_admin:your_password' >> ~/.pgpass

# REQUIRED: restrict permissions (psql ignores .pgpass if permissions are too open)
chmod 600 ~/.pgpass

# Verify authentication works
psql -h localhost -p 5432 -U perseus_admin -d perseus_dev -c "SELECT 1;"
```

### 3. CSV Files

CSV files must be pre-exported using `extract-data.sh`. They follow the naming convention:

```
##perseus_tier_{N}_{table_name}.csv
```

- No header row
- Comma-delimited
- Default location: `/tmp/perseus-data-export/`

### 4. Target Schema

The `perseus` schema (or whichever `PG_SCHEMA` is configured) must already exist in the target database with all table DDL applied.

---

## Configuration

All settings are read from `.env` in the script directory. Copy the template and customize:

```bash
cp .env.example .env
chmod 600 .env
vim .env
```

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `PG_HOST` | PostgreSQL hostname or IP | `localhost` |
| `PG_PORT` | PostgreSQL port | `5432` |
| `PG_DATABASE` | Target database name | `perseus_dev` |
| `PG_USER` | PostgreSQL username | `perseus_admin` |
| `PG_SCHEMA` | Target schema | `perseus` |
| `DATA_DIR` | Path to CSV directory | `/tmp/perseus-data-export` |
| `LOG_DIR` | Log output directory | `./logs` |

### Configuration Precedence

1. **CLI flags** — highest priority
2. **.env file** — primary configuration
3. **Script defaults** — fallback if not set in `.env`

### Example .env

```bash
PG_HOST=localhost
PG_PORT=5432
PG_DATABASE=perseus_dev
PG_USER=perseus_admin
PG_SCHEMA=perseus
DATA_DIR=/tmp/perseus-data-export
LOG_DIR=./logs
```

---

## Usage

```bash
./load_data.sh [OPTIONS]
```

### Options

| Option | Description |
|--------|-------------|
| `--validate-only` | Run referential integrity validation only, skip data loading |
| `--tier N` | Load only tier N (0–4); default: all tiers |
| `--no-truncate` | Skip `TRUNCATE` before each table (append mode, not idempotent) |
| `--help` | Show help message |

### Examples

```bash
# Load all tiers (default — idempotent with TRUNCATE)
./load_data.sh

# Load only tier 3 (P0 critical: goo, fatsmurf, etc.)
./load_data.sh --tier 3

# Validate referential integrity without loading data
./load_data.sh --validate-only

# Append data without truncating existing rows
./load_data.sh --no-truncate
```

### Expected Output

```
============================================================
Perseus Data Migration — Local PostgreSQL Loader
============================================================

[INFO] Target:    localhost:5432/perseus_dev (schema: perseus)
[INFO] User:      perseus_admin (auth via .pgpass)
[INFO] Data dir:  /tmp/perseus-data-export

============================================================
Pre-flight Checks
============================================================

[SUCCESS] psql found: psql (PostgreSQL) 17.x
[SUCCESS] Data directory OK: 76 CSV file(s) found
[SUCCESS] Database connectivity OK (localhost:5432/perseus_dev)
[SUCCESS] Schema 'perseus' exists

[SUCCESS] FK triggers disabled via session_replication_role

============================================================
TIER 0: Loading 32 tables
============================================================

[SUCCESS]   ✓ permissions: 15 rows
[SUCCESS]   ✓ unit: 42 rows
...

============================================================
Load Summary
============================================================

[INFO] Tables loaded:  75
[INFO] Tables skipped: 0
[INFO] Tables failed:  0
[INFO] Total rows:     125340
[INFO] Duration:       2m 15s
[INFO] Log file:       ./logs/load_data-20260512_034500.log

[SUCCESS] Data load complete!
```

---

## Dependency Tiers

Data is loaded in strict dependency order to respect referential integrity. FK triggers are disabled during load for performance, then re-enabled after all tiers complete.

| Tier | Description | Tables | Key Tables |
|------|-------------|--------|------------|
| 0 | Base tables (no FK dependencies) | 32 | `goo_type`, `unit`, `manufacturer`, `container` |
| 1 | Depends on Tier 0 only | 9 | `property`, `perseus_user`, `workflow` |
| 2 | Depends on Tier 0–1 | 11 | `recipe`, `smurf_group`, `workflow_step` |
| 3 | Depends on Tier 0–2 **(P0 critical)** | 12 | `goo`, `fatsmurf`, `goo_attachment` |
| 4 | Depends on Tier 0–3 **(P0 lineage)** | 11 | `material_transition`, `transition_material` |

**Total:** 75 tables across 5 tiers.

---

## FK Trigger Management

The script disables FK triggers before loading to allow out-of-order inserts within a tier, then re-enables them after.

**Primary method:** `SET session_replication_role = 'replica'` — efficient, single-session scope. Requires the PostgreSQL user to have the `SUPERUSER` attribute or `REPLICATION` role.

**Fallback:** If `session_replication_role` is not available (insufficient privileges), the script automatically falls back to per-table `ALTER TABLE ... DISABLE TRIGGER ALL`.

**Safety:** An `EXIT` trap ensures FK triggers are always re-enabled, even if the script fails mid-load or is interrupted with `Ctrl+C`.

---

## Logging

Each run produces a timestamped log file in `$LOG_DIR`:

```
logs/load_data-20260512_034500.log
```

The log contains:
- Every table load attempt (success, skip, or failure)
- `TRUNCATE` and `\copy` command output
- Row counts per table
- Timing and summary statistics

Terminal output is color-coded: `[INFO]`, `[SUCCESS]`, `[WARN]`, `[ERROR]`.

---

## Testing

### Offline Tests (no database required)

```bash
./test_load_data.sh
```

Runs 31 tests verifying:
- Script structure (exists, executable, syntax, shebang, strict mode)
- Code patterns (no docker exec, uses `\copy`, `.pgpass` refs, EXIT trap, FK management)
- Tier completeness (correct table counts per tier)
- CLI handling (`--help`, invalid/missing tier, unknown options)
- Pre-flight checks (missing/empty data directory)
- `.env.example` completeness (all variables defined)

### Integration Tests (requires live PostgreSQL)

```bash
./test_load_data.sh --integration
```

Additional tests with a running database:
- Database connectivity
- Schema existence
- `session_replication_role` settable
- Table and FK constraint counts
- `--validate-only` mode execution

---

## Post-Load Validation

After loading, run the validation scripts to verify data integrity:

```bash
# 1. Referential integrity (CRITICAL — must pass 100%)
./load_data.sh --validate-only
# Or directly:
psql -h localhost -U perseus_admin -d perseus_dev -f validate-referential-integrity.sql

# 2. Row count validation (15% ±2% of source)
psql -h localhost -U perseus_admin -d perseus_dev -f validate-row-counts.sql

# 3. Checksum validation (sample-based)
psql -h localhost -U perseus_admin -d perseus_dev -f validate-checksums.sql
```

---

## Troubleshooting

### "Cannot connect to PostgreSQL"

- Verify PostgreSQL is running: `pg_isready -h localhost -p 5432`
- Verify `~/.pgpass` has the correct entry and `0600` permissions
- Test manually: `psql -h localhost -U perseus_admin -d perseus_dev -c "SELECT 1;"`

### "Schema 'perseus' does not exist"

- The DDL must be applied before loading data
- Check: `psql -c "SELECT schema_name FROM information_schema.schemata WHERE schema_name = 'perseus';"`

### "No CSV files found"

- Verify `DATA_DIR` points to the correct directory
- CSV files must match `##perseus_tier_*.csv`
- Run `extract-data.sh` first if CSVs haven't been exported

### "session_replication_role not available"

- The script will automatically fall back to per-table `ALTER TABLE ... DISABLE TRIGGER ALL`
- To use the primary method, grant the PostgreSQL user `SUPERUSER` or `REPLICATION`:
  ```sql
  ALTER ROLE perseus_admin WITH SUPERUSER;
  ```

### "CRITICAL: Failed to re-enable FK triggers"

- This means the cleanup trap failed. FK triggers may be left disabled.
- Manual fix:
  ```sql
  DO $$
  DECLARE r RECORD;
  BEGIN
      FOR r IN SELECT tablename FROM pg_tables WHERE schemaname = 'perseus'
      LOOP
          EXECUTE format('ALTER TABLE perseus.%I ENABLE TRIGGER ALL', r.tablename);
      END LOOP;
  END $$;
  ```

### Table load failures

- Check the log file in `$LOG_DIR` for the specific `\copy` error
- Common causes: column count mismatch, data type errors, encoding issues
- Re-run a single tier after fixing: `./load_data.sh --tier N`

---

## Differences from load-data.sh (Docker)

| Aspect | `load-data.sh` (Docker) | `load_data.sh` (Local) |
|--------|------------------------|-----------------------|
| PostgreSQL access | `docker exec ... psql` | Direct `psql` on host |
| Authentication | Docker container user | `~/.pgpass` |
| CSV loading | `COPY FROM STDIN` piped via Docker | `\copy` (client-side) |
| FK management | Per-table `ALTER TABLE` | `session_replication_role` + fallback |
| Log location | Hardcoded `$SCRIPT_DIR/load-data.log` | Configurable `$LOG_DIR` with timestamps |
| Pre-flight checks | Container running check | psql, connectivity, schema verification |

---

## Related Documentation

- **Main pipeline README:** `scripts/data-migration/README.md`
- **Data extraction:** `scripts/data-migration/extract-data.sh`
- **FK constraint fixes:** `docs/FK-CONSTRAINT-FIXES.md`
- **DEV deployment:** `docs/DEV-DEPLOYMENT-COMPLETE.md`
- **Data migration plan:** `docs/DATA-MIGRATION-PLAN-DEV.md`
