# Research: T-SQL to PostgreSQL Migration Technical Decisions

**Created**: 2026-01-19
**Feature**: T-SQL to PostgreSQL Database Migration (001-tsql-to-pgsql)
**Purpose**: Resolve technical unknowns and establish implementation patterns for migration

---

## Overview

This document consolidates research findings for three critical technical decisions in the Perseus database migration from SQL Server to PostgreSQL:

1. **Materialized View Refresh Strategy** - How to maintain the `translated` view
2. **GooList Type Conversion Pattern** - How to replace SQL Server table-valued parameters
3. **Foreign Data Wrapper Configuration** - How to replace SQL Server linked servers

---

## 1. Materialized View Refresh Strategy

### Context

The `translated` view is the **most critical object** in the Perseus database:
- **Purpose**: Unified view of material lineage edges (parent→transition→child)
- **Current State**: SQL Server indexed view with UNIQUE CLUSTERED INDEX
- **Dependencies**: Used by 4 P0 functions (McGetUpStream, McGetDownStream, McGetUpStreamByList, McGetDownStreamByList)
- **Base Tables**: `material_transition` and `transition_material`

### Decision: Scheduled CONCURRENT Refresh with pg_cron

Use scheduled refreshes with `REFRESH MATERIALIZED VIEW CONCURRENTLY` at 5-15 minute intervals via the pg_cron extension.

### Rationale

1. **Concurrency During Refresh**: The CONCURRENTLY option allows queries to continue using the view during refresh, critical for P0 function availability.

2. **Predictable Performance**: Scheduled refreshes provide controlled resource consumption patterns and can be timed for lower-traffic periods.

3. **Production Stability**: Avoids performance penalties of trigger-based refreshes (which can cause INSERT/UPDATE operations to take multiple seconds).

4. **Avoids Deadlock Risks**: Multiple concurrent refresh triggers can cause deadlocks; scheduled refreshes eliminate this risk.

5. **Acceptable Staleness**: Material lineage tracking doesn't require millisecond-fresh data; 5-15 minute staleness is acceptable for business operations.

### Alternatives Considered

#### Alternative 1: Trigger-Based Refresh (REJECTED)
- **Why rejected**: INSERT/UPDATE on source tables become drastically slower (multiple seconds per operation), synchronous execution blocks transactions, potential deadlocks
- **Trade-off**: Real-time freshness vs. severe performance degradation

#### Alternative 2: pg_ivm Extension for Incremental Maintenance (REJECTED)
- **Why rejected**: Not recommended for production deployments, not available on AWS RDS/Aurora, stability concerns as of 2026
- **Trade-off**: Automatic maintenance vs. production risk

#### Alternative 3: Manual Refresh Only (REJECTED)
- **Why rejected**: Operational burden, inconsistent freshness, risk of forgotten refreshes
- **Trade-off**: Simplicity vs. reliability

#### Alternative 4: Regular View (Non-Materialized) (REJECTED)
- **Why rejected**: Performance critical - indexed view provides 10-100x speedup vs regular view
- **Trade-off**: Always-fresh data vs. query performance

### Implementation

```sql
-- Create materialized view with required index
CREATE MATERIALIZED VIEW perseus_dbo.translated AS
SELECT
    mt.material_id AS source_material,
    tm.material_id AS destination_material,
    mt.transition_id
FROM perseus_dbo.material_transition AS mt
JOIN perseus_dbo.transition_material AS tm
    ON tm.transition_id = mt.transition_id;

-- REQUIRED: Create unique index for CONCURRENTLY option
CREATE UNIQUE INDEX ix_translated_unique
ON perseus_dbo.translated (source_material, destination_material, transition_id);

-- Install pg_cron extension
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Schedule refresh every 10 minutes
SELECT cron.schedule(
    'refresh_translated_view',
    '*/10 * * * *',
    $$REFRESH MATERIALIZED VIEW CONCURRENTLY perseus_dbo.translated$$
);

-- Schedule vacuum after refresh
SELECT cron.schedule(
    'vacuum_translated_view',
    '5,15,25,35,45,55 * * * *',
    $$VACUUM ANALYZE perseus_dbo.translated$$
);
```

### Technical Considerations

**Refresh Frequency Tuning**:
- Start with 10-minute intervals
- Adjust based on data volatility and acceptable staleness
- Options: 5 minutes (high-frequency), 10 minutes (moderate), 15-30 minutes (low-frequency)

**Performance Metrics** (from benchmarks):
- Traditional refresh: ~1.3 seconds
- Concurrent refresh: ~6.5 seconds (5x slower but allows concurrent queries)
- Test with production data volume to establish actual baselines

**CONCURRENTLY Requirements**:
- At least one UNIQUE index required (implemented above)
- Slower than non-concurrent refresh but critical for availability
- Creates temporary copy, compares differences, performs atomic swap

**Monitoring**:
```sql
-- Check last refresh time
SELECT schemaname, matviewname, last_refresh
FROM pg_matviews
WHERE matviewname = 'translated';

-- Monitor refresh job execution
SELECT jobid, jobname, status, return_message, start_time, end_time
FROM cron.job_run_details
WHERE jobname = 'refresh_translated_view'
ORDER BY start_time DESC
LIMIT 10;
```

---

## 2. GooList Type Conversion Pattern

### Context

SQL Server user-defined type `GooList` (TVP with single column `uid NVARCHAR(50)`) is used by McGet* functions for batch processing (up to 20,000 materials per execution).

### Decision: TEMPORARY TABLE Pattern

Use session-scoped temporary tables with `ON COMMIT DROP` for transaction-scoped lifetime.

### Rationale

1. **Performance for Large Batches**: For 10,000-20,000 material UIDs with complex JOINs, temporary tables outperform arrays due to indexing and query optimizer support.

2. **Closest SQL Server Semantics**: Preserves PRIMARY KEY constraint from original GooList definition, maintains table-like JOIN syntax.

3. **Transaction Scope & Cleanup**: `ON COMMIT DROP` provides automatic cleanup, prevents session bloat in connection pooling environments.

4. **Query Optimizer Support**: PostgreSQL can ANALYZE temp tables and generate optimal query plans with index statistics.

### Alternatives Considered

#### Alternative 1: Array Parameters (VARCHAR[]) (REJECTED for Large Batches)
- **Pros**: 29x faster for simple operations (14,937 TPS vs 517 TPS), simpler syntax
- **Cons**: No PRIMARY KEY, performance degrades >1,000 elements, cannot be indexed, memory-bound
- **When to use**: Small batches (<100 UIDs), simple queries
- **Why rejected**: Perseus batch sizes (10,000-20,000) exceed practical array limits

#### Alternative 2: JSONB Parameters (REJECTED)
- **Pros**: Modern, flexible, supports GIN indexes, good for API integration
- **Cons**: Overkill for simple UID lists, serialization overhead, 2000x slower queries (no planner statistics), TOAST storage issues >2KB
- **When to use**: API-driven architecture, complex nested structures
- **Why rejected**: Unnecessary complexity and performance penalty for simple UID lists

### Implementation

**Function Signature Changes**:

```sql
-- SQL Server (Original)
CREATE FUNCTION McGetUpStreamByList(@StartPoint GooList READONLY)
RETURNS @Paths TABLE(start_point VARCHAR(50), ...)

-- PostgreSQL (Converted)
CREATE FUNCTION mcgetupstreambylist(p_temp_table_name TEXT)
RETURNS TABLE (start_point VARCHAR(50), ...)
```

**Caller Pattern**:

```sql
-- STEP 1: Defensive cleanup
DROP TABLE IF EXISTS temp_us_goo_uids;

-- STEP 2: Create temporary table with ON COMMIT DROP
CREATE TEMPORARY TABLE temp_us_goo_uids (
    uid VARCHAR(255) NOT NULL,
    PRIMARY KEY (uid)
) ON COMMIT DROP;

-- STEP 3: Use within transaction
BEGIN
    -- Populate temp table
    INSERT INTO temp_us_goo_uids VALUES ('uid1'), ('uid2'), ...;

    -- Call function passing table name
    INSERT INTO m_upstream
    SELECT * FROM mcgetupstreambylist('temp_us_goo_uids');

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;

-- STEP 4: Auto-cleanup at transaction end (no explicit DROP needed)
```

### Technical Considerations

**Cleanup Handling**:
- `DROP TABLE IF EXISTS`: Prevents "table already exists" from failed previous runs
- `ON COMMIT DROP`: Ties lifetime to transaction, not session (critical for connection pooling)
- Defensive pattern handles edge cases where cleanup failed

**Connection Pooler Compatibility**:
- PgBouncer (transaction mode): ✅ Works perfectly with `ON COMMIT DROP`
- PgBouncer (session mode): ✅ Works but `ON COMMIT DROP` less critical
- PgBouncer (statement mode): ❌ Not recommended for temp tables
- Pgpool-II: ✅ Compatible with proper `ON COMMIT DROP` usage

**Performance Expectations**:
- usp_UpdateMUpstream: <5 seconds for 20,000 records
- ReconcileMUpstream: <5 seconds for 10 materials
- PRIMARY KEY on temp table enables efficient JOIN optimization

---

## 3. Foreign Data Wrapper Configuration

### Context

Replace SQL Server linked servers with postgres_fdw connections to 3 external databases:
- hermes: 6 tables (experimental runs, conditions)
- sqlapps.common: 9 tables (lookup data)
- deimeter: 2 tables (field data)

### Decision: Layered Connection Management with Read-Only Access

**Architecture**:
```
Application → PgBouncer (20 connections) → PostgreSQL → FDW (60 max connections for 3 servers)
```

**Access Pattern**: Read-only FDW with local processing for writes (no distributed transactions).

### Rationale

1. **Connection Pooling**: FDW maintains connections for entire session lifetime; PgBouncer in transaction mode prevents connection exhaustion.

2. **Automatic Retry**: PostgreSQL 14+ automatically retries failed connections at transaction start; supplement with application-level exponential backoff.

3. **Performance Optimization**: Multi-layered approach using fetch_size tuning, predicate pushdown verification, and use_remote_estimate for complex joins.

4. **Security**: SCRAM-SHA-256 authentication with dedicated read-only roles prevents accidental writes to external databases.

5. **No Two-Phase Commit**: postgres_fdw does NOT support 2PC; read-only pattern avoids distributed transaction complexity.

### Alternatives Considered

#### Alternative 1: Write-Through FDW (REJECTED)
- **Why rejected**: No atomic rollback across multiple foreign servers, risk of orphaned records if local commit fails after foreign commits succeed
- **Trade-off**: Direct writes vs. data consistency guarantees

#### Alternative 2: dblink Extension (REJECTED)
- **Why rejected**: postgres_fdw provides better performance (predicate pushdown, join pushdown), cleaner SQL syntax, automatic connection management
- **Trade-off**: Legacy compatibility vs. modern features

#### Alternative 3: Application-Level Federation (REJECTED)
- **Why rejected**: Requires application code changes (out of scope per OOS-001), adds complexity to application layer
- **Trade-off**: Application control vs. database-level abstraction

### Implementation

**Server Configuration** (example for hermes):

```sql
CREATE SERVER hermes_fdw
  FOREIGN DATA WRAPPER postgres_fdw
  OPTIONS (
    host 'hermes.production.internal',
    port '5432',
    dbname 'hermes',
    connect_timeout '5',
    keepalives '1',
    keepalives_idle '30',
    keepalives_interval '10',
    keepalives_count '3',
    fetch_size '5000',
    use_remote_estimate 'true',
    async_capable 'true',
    sslmode 'verify-full'
  );

-- Create read-only user mapping
CREATE USER MAPPING FOR perseus_app
SERVER hermes_fdw
OPTIONS (
    user 'perseus_fdw_reader',
    password 'SCRAM-SHA-256$...'
);

-- Import foreign schema (6 tables)
IMPORT FOREIGN SCHEMA public
  LIMIT TO (runs, experiments, run_conditions, ...)
  FROM SERVER hermes_fdw
  INTO public;
```

**Connection Limit Calculation**:
- Application connections to PgBouncer: 20
- Foreign servers: 3 (hermes, sqlapps, deimeter)
- Maximum FDW connections: 20 × 3 = 60 concurrent

### Technical Considerations

**fetch_size Tuning**:
- Analytical queries (hermes runs): `fetch_size='10000'`
- OLTP queries (lookups): `fetch_size='500'`
- Default: `fetch_size='5000'`
- **Impact**: 100× reduction in network round trips for large result sets

**Predicate Pushdown Verification**:
```sql
-- Verify pushdown with EXPLAIN
EXPLAIN (VERBOSE, COSTS OFF)
SELECT * FROM hermes_run WHERE experiment_id = 'EXP123';

-- Look for: "Remote SQL: SELECT ... WHERE experiment_id = 'EXP123'"
-- If absent, predicate filters locally (slow)
```

**use_remote_estimate**:
- Set `use_remote_estimate='true'` for accurate join cost estimates
- Adds 10-50ms planning overhead but improves join strategies
- Critical for queries joining foreign tables with local tables

**Cross-Server Join Optimization**:
- **Problem**: Joins between different foreign servers fetch all data locally (very slow)
- **Solution**: Replicate small lookup tables locally (9 sqlapps.common tables)
- Refresh via pg_cron daily or hourly depending on volatility

**Monitoring Metrics**:
- Connection counts per foreign server (alert at 80% of limit)
- Query latency (p50, p95, p99)
- Error rates (connection failures, timeouts)
- Predicate pushdown effectiveness (query plan analysis)

**Health Check Function**:
```sql
CREATE FUNCTION check_fdw_health()
RETURNS TABLE(
    server_name TEXT,
    status TEXT,
    latency_ms NUMERIC,
    error_message TEXT
) AS $$
BEGIN
    -- Test connection to each foreign server
    -- Return status and latency
END;
$$ LANGUAGE plpgsql;

-- Schedule via pg_cron every 5 minutes
SELECT cron.schedule(
    'fdw_health_check',
    '*/5 * * * *',
    $$INSERT INTO fdw_health_log SELECT * FROM check_fdw_health()$$
);
```

**Error Handling Pattern**:
```sql
BEGIN
    -- Query foreign table
    SELECT * FROM hermes_run WHERE ...;
EXCEPTION
    WHEN sqlstate '08000' THEN  -- Connection exception
        -- Retry with exponential backoff
        -- Log error
        RAISE NOTICE 'FDW connection failed: %', SQLERRM;
END;
```

**Security Configuration**:
```sql
-- Create read-only role on foreign database
CREATE ROLE perseus_fdw_reader WITH LOGIN;
GRANT USAGE ON SCHEMA public TO perseus_fdw_reader;
GRANT SELECT ON hermes.runs, hermes.experiments, ... TO perseus_fdw_reader;
REVOKE INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public FROM perseus_fdw_reader;

-- Use SCRAM-SHA-256 authentication (not MD5)
-- Passwords stored encrypted in pg_user_mapping catalog
```

---

## Implementation Roadmap

### Phase 1: Materialized View Setup (Week 1)
1. Create `translated` materialized view with unique index
2. Install pg_cron extension
3. Schedule refresh and vacuum jobs
4. Establish monitoring queries
5. Performance test with production-scale data

### Phase 2: GooList Pattern Migration (Week 2)
1. Update McGetUpStreamByList function signature
2. Update McGetDownStreamByList function signature
3. Update ReconcileMUpstream procedure
4. Update ProcessSomeMUpstream procedure
5. Test with 10,000-20,000 material batches

### Phase 3: FDW Infrastructure (Week 3)
1. Install postgres_fdw extension
2. Create foreign servers (hermes, sqlapps, deimeter)
3. Create read-only roles on foreign databases
4. Configure user mappings with SCRAM-SHA-256
5. Import foreign schemas (17 tables total)

### Phase 4: FDW Optimization (Week 4)
1. Run EXPLAIN ANALYZE on critical queries
2. Verify predicate pushdown effectiveness
3. Tune fetch_size per table
4. Implement local caching for sqlapps lookup tables
5. Set up health checks and monitoring

### Phase 5: Integration Testing (Week 5)
1. Test materialized view refresh under load
2. Test temp table pattern with concurrent connections
3. Test FDW queries with connection pooling
4. Validate performance within 20% baseline
5. Test failure scenarios and error handling

---

## Key Decisions Summary

| Decision Area | Chosen Approach | Primary Driver |
|---------------|-----------------|----------------|
| Materialized View Refresh | Scheduled CONCURRENT (pg_cron) | Balance freshness vs. performance, production stability |
| GooList Type Conversion | TEMPORARY TABLE pattern | Large batch sizes (10k-20k), JOIN performance, connection pooling |
| FDW Configuration | Read-only with layered pooling | Avoid 2PC complexity, ensure connection availability |
| FDW Optimization | fetch_size tuning + predicate pushdown | Network efficiency, query performance |
| Monitoring | pg_cron health checks + pg_stat_statements | Proactive issue detection, performance visibility |

---

## References

### Materialized Views
- PostgreSQL Official Documentation: REFRESH MATERIALIZED VIEW
- Epsio Blog: Postgres REFRESH MATERIALIZED VIEW Comprehensive Guide
- Cybertec: Creating and Refreshing Materialized Views in PostgreSQL
- AWS Blog: Migrate SQL Server Indexed Views to Materialized Views

### Table-Valued Parameters
- PostgreSQL Array Functions and Operators Documentation
- MinervaDB: Table-Valued Parameters in PostgreSQL
- Neon: PostgreSQL Temporary Tables
- Percona Blog: What Hurts in PostgreSQL Part One - Temporary Tables

### Foreign Data Wrappers
- PostgreSQL Official Documentation: postgres_fdw
- Crunchy Data: FDW Best Practices
- EDB: Foreign Data Wrapper Security
- Microsoft: Migrate SQL Server Linked Servers to FDW

---

**Status**: ✅ All technical unknowns resolved - Ready for Phase 1 (Design & Contracts)
