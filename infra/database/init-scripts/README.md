# PostgreSQL Initialization Scripts

This directory contains SQL scripts that run automatically when the PostgreSQL container is first created.

## 🚀 How It Works

Scripts in this directory are executed by the `postgres` Docker image's `docker-entrypoint-initdb.d` mechanism:

1. **When:** Only when the container starts with an empty data volume (`pgdata/`)
2. **Order:** Alphanumeric order (use numeric prefixes like `01-`, `02-`, etc.)
3. **User:** Scripts run as the `POSTGRES_USER` (perseus_admin)
4. **Database:** Scripts run against the `POSTGRES_DB` (perseus_dev)

## 📂 Included Scripts

### 01-init-database.sql

Initial database setup script that creates:

- **Extensions:**
  - `uuid-ossp` - UUID generation functions
  - `pg_stat_statements` - Query performance monitoring
  - `btree_gist` - Additional index types
  - `pg_trgm` - Trigram matching for text search

- **Schemas:**
  - `perseus` - Main application schema
  - `perseus_test` - Testing schema
  - `fixtures` - Test data fixtures schema

- **Audit Tables:**
  - `perseus.migration_log` - Migration tracking and quality scores

- **Helper Functions:**
  - `perseus.object_exists()` - Check if database object exists

- **Configuration:**
  - Search path configuration
  - Timezone settings
  - Statement timeout
  - Parallel query settings

## ➕ Adding New Scripts

To add custom initialization scripts:

1. Create a new SQL file with numeric prefix:
   ```
   02-create-tables.sql
   03-load-fixtures.sql
   04-grant-permissions.sql
   ```

2. Place in this directory

3. Scripts execute in alphanumeric order

4. Restart with fresh database to apply:
   ```bash
   cd ../..  # Return to infra/database/
   ./init-db.sh clean
   ./init-db.sh setup
   ./init-db.sh start
   ```

## 📝 Best Practices

### Script Structure

```sql
-- Header comment explaining what the script does
-- Author, date, purpose

-- Use transactions for safety
BEGIN;

-- Set error handling
\set ON_ERROR_STOP on

-- Your SQL commands here
CREATE TABLE IF NOT EXISTS ...;

-- Commit transaction
COMMIT;

-- Verify results
SELECT 'Script completed successfully!' AS status;
```

### Idempotency

Make scripts idempotent so they can run multiple times safely:

```sql
-- Good - idempotent
CREATE TABLE IF NOT EXISTS mytable (...);
CREATE SCHEMA IF NOT EXISTS myschema;
DROP TABLE IF EXISTS temp_table;

-- Avoid - not idempotent
CREATE TABLE mytable (...);  -- Fails on second run
```

### Error Handling

```sql
-- Stop on first error
\set ON_ERROR_STOP on

-- Or use DO blocks with exception handling
DO $$
BEGIN
    -- Your code here
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error: %', SQLERRM;
        -- Don't re-raise if you want to continue
END $$;
```

### Logging

Use `RAISE NOTICE` for progress tracking:

```sql
RAISE NOTICE 'Creating tables...';
CREATE TABLE ...;
RAISE NOTICE 'Tables created successfully';
```

## 🔍 Verification

After container initialization, verify scripts ran successfully:

```bash
# Connect to database
./init-db.sh shell

# Check logs
\! tail -50 /var/lib/postgresql/data/pg_log/postgresql-*.log

# Verify schemas
\dn

# Verify extensions
\dx

# Verify tables
\dt perseus.*
```

## 🐛 Troubleshooting

### Scripts Didn't Run

**Symptom:** Expected objects don't exist

**Solution:**
- Scripts only run on **empty** data volume
- Clean and recreate:
  ```bash
  ./init-db.sh clean
  ./init-db.sh setup
  ./init-db.sh start
  ```

### Script Failed

**Symptom:** Container starts but some objects missing

**Check logs:**
```bash
docker logs perseus-postgres-dev | grep -A 10 "init-scripts"
```

**Common causes:**
- Syntax error in SQL
- Missing dependencies (extension not installed)
- Permission issues
- Non-idempotent script run twice

### Modify Existing Scripts

**After modifying a script:**

1. Clean existing data:
   ```bash
   ./init-db.sh clean
   ```

2. Setup and start:
   ```bash
   ./init-db.sh setup
   ./init-db.sh start
   ```

3. Verify changes:
   ```bash
   ./init-db.sh shell
   \dt  # List tables
   ```

## 📚 Resources

- [PostgreSQL Docker Init Scripts](https://github.com/docker-library/docs/blob/master/postgres/README.md#initialization-scripts)
- [PostgreSQL Extensions](https://www.postgresql.org/docs/current/contrib.html)
- [PostgreSQL Schemas](https://www.postgresql.org/docs/current/ddl-schemas.html)

---

**Note:** For migration scripts (after initial setup), use the scripts in `source/building/pgsql/refactored/` and deploy via `scripts/deployment/` instead of putting them here.
