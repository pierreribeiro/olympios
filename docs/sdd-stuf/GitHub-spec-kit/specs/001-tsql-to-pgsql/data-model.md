# Data Model: T-SQL to PostgreSQL Migration

**Created**: 2026-01-19
**Feature**: 001-tsql-to-pgsql
**Purpose**: Define database object structure and relationships for migration

---

## Overview

This document defines the data model for the Perseus database migration from SQL Server to PostgreSQL. Unlike traditional application data models, this focuses on **database objects as entities** since this is a database migration project.

The model covers 9 entity types representing database objects:
1. Views (22 objects)
2. Functions (25 objects)
3. Tables (91 objects)
4. Indexes (352 objects)
5. Constraints (271 objects)
6. User-Defined Types (1 object)
7. Foreign Data Wrappers (3 connections)
8. Replication Configurations (1 target)
9. Jobs (7 scheduled tasks)

---

## Entity Definitions

### 1. View

**Description**: Virtual table providing data abstraction layer for application queries

**Types**:
- **Standard View**: Regular SELECT-based view
- **Recursive CTE View**: View using WITH RECURSIVE for hierarchical queries
- **Materialized View**: Physically stored view (converted from SQL Server indexed views)

**Attributes**:
- `name`: VARCHAR(63) - PostgreSQL identifier (snake_case)
- `schema`: VARCHAR(63) - Schema name (default: perseus)
- `type`: ENUM('standard', 'recursive_cte', 'materialized')
- `definition`: TEXT - View SELECT statement
- `base_tables`: VARCHAR(63)[] - Array of dependent table names
- `dependent_objects`: VARCHAR(63)[] - Functions/views that reference this view
- `refresh_strategy`: VARCHAR(50) - For materialized views: 'scheduled', 'manual', 'trigger'
- `refresh_interval`: INTERVAL - For scheduled refresh: '10 minutes', '1 hour', etc.

**Critical Views** (P0):
- `translated`: Materialized view (from SQL Server indexed view), joins material_transition + transition_material
- `upstream`: Recursive CTE view for material lineage traversal (parent direction)
- `downstream`: Recursive CTE view for material lineage traversal (child direction)
- `goo_relationship`: Union view combining goo, fatsmurf, hermes.run

**Validation Rules**:
- Name must be snake_case lowercase (constitution principle V)
- Schema-qualified references required in definition (constitution principle VII)
- Result set must match SQL Server output 100% (SC-001)
- Query performance within 20% of SQL Server baseline (SC-004)
- Materialized views require at least one UNIQUE index for CONCURRENTLY refresh

**State Transitions**:
```
SQL Server View → AWS SCT Converted → Manually Refactored → Syntax Validated → Result Validated → Deployed
```

---

### 2. Function

**Description**: Reusable logic returning table sets or scalar values

**Types**:
- **Table-Valued Function (TVF)**: Returns TABLE with multiple rows
- **Scalar Function**: Returns single value
- **Aggregate Function**: Returns aggregated value (if any)

**Attributes**:
- `name`: VARCHAR(63) - PostgreSQL identifier (snake_case, action verb prefix)
- `schema`: VARCHAR(63) - Schema name (default: perseus)
- `type`: ENUM('table_valued', 'scalar', 'aggregate')
- `return_type`: TEXT - RETURNS clause definition
- `parameters`: JSONB - Array of {name, type, mode} objects
- `body`: TEXT - Function implementation (PL/pgSQL)
- `language`: VARCHAR(20) - 'plpgsql', 'sql' (default: plpgsql)
- `depends_on`: VARCHAR(63)[] - Views, tables, other functions referenced

**Critical Functions** (P0):
- `mcgetupstream()`: Table-valued, returns upstream material lineage
- `mcgetdownstream()`: Table-valued, returns downstream material lineage
- `mcgetupstreambylist()`: Table-valued, batch upstream query (uses temp table pattern)
- `mcgetdownstreambylist()`: Table-valued, batch downstream query (uses temp table pattern)

**Validation Rules**:
- Name must be snake_case with action verb prefix (get_*, process_*, calculate_*) per constitution
- Schema-qualified references in function body required (CN-010)
- Explicit CAST or :: notation for all type conversions (constitution principle II)
- Set-based operations only, no cursors/loops (constitution principle III)
- Specific exception types, no WHEN OTHERS except for final catch-all (constitution principle VI)
- Named parameters only, not positional (constitution principle VII)

**Parameter Pattern Changes**:
```sql
-- SQL Server TVP
@StartPoint GooList READONLY

-- PostgreSQL Temp Table Pattern
p_temp_table_name TEXT  -- Pass table name, caller creates temp table
```

**State Transitions**:
```
SQL Server Function → AWS SCT Converted → Cursor Refactored → Temp Table Pattern Applied → Tested → Deployed
```

---

### 3. Table

**Description**: Physical data storage structure with rows and columns

**Attributes**:
- `name`: VARCHAR(63) - Table name (snake_case, plural noun)
- `schema`: VARCHAR(63) - Schema name (default: perseus)
- `columns`: JSONB - Array of {name, data_type, nullable, default} objects
- `row_count`: BIGINT - Production row count (for migration planning)
- `storage_size`: BIGINT - Bytes (for capacity planning)
- `has_identity`: BOOLEAN - Uses GENERATED ALWAYS AS IDENTITY
- `partition_key`: VARCHAR(63) - If partitioned (null if not)

**Critical Tables** (P0):
- `goo`: Material master table
- `material_transition`: Parent→Transition edges for material lineage
- `transition_material`: Transition→Child edges for material lineage
- `m_upstream`: Cached upstream graph (performance optimization)
- `m_downstream`: Cached downstream graph (performance optimization)
- `m_upstream_dirty_leaves`: Reconciliation queue for graph updates

**Data Type Mappings** (SQL Server → PostgreSQL):
- `NVARCHAR(n)` → `VARCHAR(n)` (UTF-8 encoding)
- `MONEY` → `NUMERIC(19,4)`
- `UNIQUEIDENTIFIER` → `UUID`
- `DATETIME` → `TIMESTAMP`
- `IDENTITY(1,1)` → `GENERATED ALWAYS AS IDENTITY`
- `ROWVERSION` → `BIGINT` with trigger (no direct equivalent)

**Validation Rules**:
- Name must be snake_case, plural noun (customers, order_items) per constitution
- Zero data loss: row count + checksum must match SQL Server (SC-003, CN-001)
- All column data types explicitly mapped (FR-004)
- Referential integrity preserved via constraints (FR-006)

**State Transitions**:
```
SQL Server Table → AWS SCT DDL → Data Type Mapped → Constraints Added → Data Migrated → Validated → Deployed
```

---

### 4. Index

**Description**: Performance optimization structure for tables

**Types**:
- **Primary Key Index** (_pkey suffix)
- **Foreign Key Index** (_fkey suffix)
- **Query Optimization Index** (_idx suffix)
- **Unique Index** (for materialized view CONCURRENTLY)

**Attributes**:
- `name`: VARCHAR(63) - Index name (descriptive with suffix)
- `table_name`: VARCHAR(63) - Parent table
- `columns`: VARCHAR(63)[] - Indexed columns (ordered)
- `index_type`: ENUM('btree', 'hash', 'gist', 'gin', 'brin') - Default: btree
- `is_unique`: BOOLEAN - Unique constraint enforced
- `is_primary`: BOOLEAN - Primary key index
- `include_columns`: VARCHAR(63)[] - INCLUDE columns (covering index)
- `where_clause`: TEXT - Partial index filter (if any)

**Naming Convention**:
```
ix_{table}_{column1}_{column2}_pkey   -- Primary key
ix_{table}_{column}_fkey               -- Foreign key
ix_{table}_{column}_idx                -- Query optimization
```

**Validation Rules**:
- Query plans must utilize indexes appropriately (verified via EXPLAIN ANALYZE per SC-005)
- Performance within 20% of SQL Server baseline (SC-004)
- Covering indexes preferred over table lookups (INCLUDE clause)

**State Transitions**:
```
SQL Server Index → AWS SCT Converted → Naming Convention Applied → Type Mapped → Created → EXPLAIN Validated
```

---

### 5. Constraint

**Description**: Data integrity rules enforcing business logic

**Types**:
- **Primary Key**: Unique identifier for rows
- **Foreign Key**: Referential integrity between tables
- **Unique**: Uniqueness constraint (non-primary)
- **Check**: Domain/business rule validation

**Attributes**:
- `name`: VARCHAR(63) - Constraint name (descriptive)
- `type`: ENUM('primary_key', 'foreign_key', 'unique', 'check')
- `table_name`: VARCHAR(63) - Parent table
- `columns`: VARCHAR(63)[] - Constrained columns
- `referenced_table`: VARCHAR(63) - For foreign keys
- `referenced_columns`: VARCHAR(63)[] - For foreign keys
- `on_delete`: ENUM('CASCADE', 'SET NULL', 'SET DEFAULT', 'RESTRICT', 'NO ACTION') - FK behavior
- `on_update`: ENUM('CASCADE', 'SET NULL', 'SET DEFAULT', 'RESTRICT', 'NO ACTION') - FK behavior
- `check_expression`: TEXT - For check constraints

**Validation Rules**:
- All 271 constraints must enforce same business rules as SQL Server (FR-006, SC-006)
- Cascading behavior must match SQL Server exactly (delete/update propagation)
- Check constraints must be tested with violation attempts
- Case sensitivity differences in unique constraints handled (PostgreSQL case-sensitive by default)

**State Transitions**:
```
SQL Server Constraint → AWS SCT Converted → ON DELETE/UPDATE Verified → Tested → Deployed
```

---

### 6. User-Defined Type (UDT)

**Description**: Custom data type (GooList - table-valued parameter in SQL Server)

**PostgreSQL Pattern**: TEMPORARY TABLE (no direct UDT equivalent)

**Attributes**:
- `name`: VARCHAR(63) - Type name (goolist → temp_goolist)
- `sql_server_definition`: TEXT - Original TVP structure
- `postgresql_pattern`: TEXT - Replacement pattern description
- `temp_table_template`: TEXT - CREATE TEMPORARY TABLE template

**GooList Specification**:
```sql
-- SQL Server UDT (Original)
CREATE TYPE GooList AS TABLE (
    uid NVARCHAR(50) PRIMARY KEY
);

-- PostgreSQL Pattern (Conversion)
CREATE TEMPORARY TABLE temp_us_goo_uids (
    uid VARCHAR(255) NOT NULL,
    PRIMARY KEY (uid)
) ON COMMIT DROP;
```

**Usage Pattern**:
- Caller creates temp table with specific name
- Passes table name as TEXT parameter to function
- Function uses dynamic SQL (EXECUTE format()) to query temp table
- Auto-cleanup via ON COMMIT DROP

**Validation Rules**:
- Batch sizes 10,000-20,000 materials must process in <5 seconds
- PRIMARY KEY enforced for JOIN optimization
- Connection pooling compatibility (PgBouncer transaction mode)

**State Transitions**:
```
SQL Server TVP → Pattern Research → Temp Table Implementation → Performance Tested → Deployed
```

---

### 7. Foreign Data Wrapper (FDW)

**Description**: Connection to external database for cross-database queries

**Attributes**:
- `server_name`: VARCHAR(63) - FDW server identifier (hermes_fdw, sqlapps_fdw, deimeter_fdw)
- `foreign_db_host`: VARCHAR(255) - Remote database host
- `foreign_db_port`: INTEGER - Remote database port (default: 5432)
- `foreign_db_name`: VARCHAR(63) - Remote database name
- `foreign_schema`: VARCHAR(63) - Remote schema to import
- `imported_tables`: VARCHAR(63)[] - List of foreign tables
- `table_count`: INTEGER - Number of tables accessed
- `user_mapping_role`: VARCHAR(63) - Local PostgreSQL role
- `foreign_user`: VARCHAR(63) - Remote database user (read-only)
- `connection_options`: JSONB - {connect_timeout, keepalives, fetch_size, use_remote_estimate}

**FDW Servers**:
1. **hermes_fdw**: 6 tables (experimental runs, conditions, metadata)
2. **sqlapps_fdw**: 9 tables (lookup/reference data)
3. **deimeter_fdw**: 2 tables (field data)

**Connection Configuration**:
```sql
OPTIONS (
    connect_timeout '5',
    keepalives '1',
    keepalives_idle '30',
    keepalives_interval '10',
    keepalives_count '3',
    fetch_size '5000',          -- Tuned per table (500-10000)
    use_remote_estimate 'true', -- Accurate join cost estimates
    async_capable 'true',
    sslmode 'verify-full'
)
```

**Validation Rules**:
- Query results must match SQL Server linked server output (SC-007)
- Performance <2x SQL Server linked server latency (SC-007)
- Predicate pushdown verified via EXPLAIN (VERBOSE, COSTS OFF)
- Read-only access only (no INSERT/UPDATE/DELETE)
- Connection health checks every 5 minutes via pg_cron

**State Transitions**:
```
SQL Server Linked Server → FDW Configured → Tables Imported → Queries Tested → Performance Validated → Deployed
```

---

### 8. Replication Configuration

**Description**: SymmetricDS setup for synchronizing data to downstream warehouse

**Attributes**:
- `source_database`: VARCHAR(63) - Perseus (PostgreSQL)
- `target_database`: VARCHAR(63) - sqlwarehouse2
- `replication_tool`: VARCHAR(50) - 'SymmetricDS'
- `replicated_tables`: VARCHAR(63)[] - Tables configured for replication
- `replication_mode`: ENUM('push', 'pull', 'bidirectional') - Default: push
- `sync_sla_minutes`: INTEGER - 5 minutes (p95 target)
- `triggers`: JSONB - Array of {table, trigger_name, trigger_type} for change capture

**Replication Workflow**:
```
PostgreSQL INSERT/UPDATE/DELETE → SymmetricDS Trigger → Change Captured → Batched → Replicated → sqlwarehouse2
```

**Validation Rules**:
- Replication lag <5 minutes (p95) per SC-008
- Data integrity preserved (row counts match, no data loss)
- Conflict resolution strategy defined (if bidirectional)
- Alerts configured for lag exceeding thresholds
- Resumption after failures without data loss (SC-008)

**Monitoring**:
- Replication lag (time difference between source and target)
- Failed batch count
- Conflict count (if bidirectional)
- Throughput (rows/second)

**State Transitions**:
```
SQL Server Replication → SymmetricDS Configured → Tables Registered → Triggers Created → Tested → Monitored
```

---

### 9. Job

**Description**: Scheduled automated task (SQL Server Agent → pgAgent/cron)

**Attributes**:
- `name`: VARCHAR(255) - Job name (descriptive)
- `schedule`: VARCHAR(100) - Cron expression ('*/10 * * * *')
- `job_type`: ENUM('pg_cron', 'pgAgent', 'external_cron')
- `command`: TEXT - SQL statement or shell script
- `enabled`: BOOLEAN - Job active/inactive
- `failure_action`: ENUM('continue', 'retry', 'notify', 'disable')
- `retry_count`: INTEGER - Max retries on failure
- `notification_emails`: VARCHAR(255)[] - Alert recipients
- `execution_log_retention`: INTERVAL - How long to keep logs

**Jobs** (7 total):
- Data reconciliation jobs (material lineage updates)
- Cleanup jobs (old audit logs, temp data)
- Maintenance jobs (VACUUM, ANALYZE, index rebuild)
- Monitoring jobs (health checks, statistics collection)

**pgAgent vs pg_cron**:
- **pg_cron**: Simpler, cron syntax, extension-based, recommended for SQL-only jobs
- **pgAgent**: GUI management (pgAdmin), job dependencies, step-based workflows, better for complex multi-step jobs

**Validation Rules**:
- Jobs execute successfully on schedule (SC-009)
- Logging equivalent to SQL Server Agent (execution history, error messages) per SC-009
- Error handling matches SQL Server behavior (notifications, retries) per SC-009
- Job dependencies execute in correct sequence (if dependent)

**State Transitions**:
```
SQL Server Agent Job → Schedule Converted → pg_cron/pgAgent Created → Tested Manually → Scheduled → Monitored
```

---

## Relationships Between Entities

### Dependency Graph

```
Tables (91)
    ↓
Indexes (352) + Constraints (271)
    ↓
Views (22)
    ├─→ Standard Views
    ├─→ Recursive CTE Views
    └─→ Materialized Views
        ↓
Functions (25)
    ├─→ Table-Valued Functions
    └─→ Scalar Functions
        ↓
Foreign Data Wrappers (3)
    ├─→ hermes_fdw (6 tables)
    ├─→ sqlapps_fdw (9 tables)
    └─→ deimeter_fdw (2 tables)
        ↓
Replication Config (1)
    └─→ SymmetricDS → sqlwarehouse2
        ↓
Jobs (7)
    ├─→ Materialized view refresh
    ├─→ FDW health checks
    ├─→ Replication monitoring
    └─→ Maintenance tasks

User-Defined Type (1): GooList → Temp Table Pattern (used by Functions)
```

### Critical Dependencies

**translated View** (materialized):
- **Depends on**: material_transition, transition_material (tables)
- **Used by**: mcgetupstream, mcgetdownstream, mcgetupstreambylist, mcgetdownstreambylist (functions)
- **Refresh job**: pg_cron scheduled every 10 minutes

**McGet* Functions**:
- **Depend on**: translated view, temp table pattern (GooList replacement)
- **Used by**: Stored procedures (already migrated), application queries
- **Performance**: <5 seconds for 20,000 materials

**FDW Connections**:
- **Depend on**: Network connectivity, external database availability
- **Used by**: Views (hermes_run), queries joining local + foreign tables
- **Health check**: pg_cron every 5 minutes

---

## Data Volume Metrics

### Object Counts

| Object Type | Count | Notes |
|-------------|-------|-------|
| Tables | 91 | All require data migration |
| Indexes | 352 | 3.87 indexes per table average |
| Constraints | 271 | 2.98 constraints per table average |
| Views | 22 | 1 materialized, 21 standard/recursive |
| Functions | 25 | 15 table-valued, 10 scalar |
| User-Defined Types | 1 | GooList (converted to temp table pattern) |
| FDW Servers | 3 | 17 foreign tables total |
| Replication Targets | 1 | sqlwarehouse2 |
| Jobs | 7 | Converted from SQL Server Agent |

### Storage Estimates (Production)

- **Total Tables**: 91 (row counts and sizes: NEEDS PRODUCTION DATA)
- **Total Indexes**: 352 (estimated 20-30% of table size)
- **Materialized View (translated)**: NEEDS ROW COUNT from material_transition + transition_material
- **FDW Overhead**: Minimal (foreign tables not stored locally)

**Action Required**: Gather production metrics:
```sql
-- Run on SQL Server to establish baselines
SELECT
    t.NAME AS TableName,
    p.rows AS RowCounts,
    SUM(a.total_pages) * 8 AS TotalSpaceKB
FROM sys.tables t
INNER JOIN sys.indexes i ON t.OBJECT_ID = i.object_id
INNER JOIN sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
WHERE t.is_ms_shipped = 0
GROUP BY t.Name, p.Rows
ORDER BY TotalSpaceKB DESC;
```

---

## Validation Matrix

| Entity | Validation Method | Success Criteria | Reference |
|--------|-------------------|------------------|-----------|
| View | Result set comparison | 100% match with SQL Server | SC-001 |
| View (Materialized) | Query performance | Within 20% baseline | SC-004 |
| Function | Output comparison | 100% match with SQL Server | SC-002 |
| Table | Row count + checksum | Zero data loss | SC-003, CN-001 |
| Index | EXPLAIN ANALYZE | Query plan uses index | SC-005 |
| Constraint | Violation testing | Enforces same rules | SC-006 |
| FDW | Result comparison + latency | Match output, <2x latency | SC-007 |
| Replication | Lag monitoring | <5 minutes (p95) | SC-008 |
| Job | Execution history | Successful on schedule | SC-009 |

---

## Migration Sequencing

Based on dependency analysis (lote1-4 documents):

### Phase 1: Foundation (Week 1-2)
1. Tables (91) - Schema creation, no data yet
2. Indexes (352) - Structure only
3. Constraints (271) - Referential integrity

### Phase 2: Data Population (Week 3)
1. Table data migration (full load)
2. Checksum validation
3. Row count verification

### Phase 3: Views & Functions (Week 4-5)
1. Standard views (non-materialized)
2. Materialized view (`translated`) with refresh job
3. Recursive CTE views (upstream, downstream)
4. Scalar functions
5. Table-valued functions (with temp table pattern)

### Phase 4: External Integration (Week 6)
1. FDW server configuration (hermes, sqlapps, deimeter)
2. Foreign table imports (17 tables)
3. FDW query testing and optimization
4. Health check job setup

### Phase 5: Replication & Jobs (Week 7)
1. SymmetricDS configuration
2. Replication trigger setup
3. Initial synchronization
4. pg_cron/pgAgent job migration (7 jobs)
5. Monitoring and alerting

---

## Quality Gates

Each entity type must pass before proceeding:

1. **Syntax Validation**: Object creates without errors
2. **Logic Validation**: Output matches SQL Server
3. **Performance Validation**: Within 20% baseline
4. **Constitution Compliance**: 7 core principles verified
5. **Quality Score**: ≥7.0/10 overall (≥8.0/10 target)

---

**Status**: ✅ Data model complete - Ready for contract generation
