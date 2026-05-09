# Feature Specification: T-SQL to PostgreSQL Database Migration

**Feature Branch**: `001-tsql-to-pgsql`
**Created**: 2026-01-19
**Status**: Draft
**Input**: User description: "Migrate T-SQL (SQL Server) objects to PGSQL (PostgreSQL)"

## Clarifications

### Session 2026-01-23

- Q: What methodology should be used to validate "identical result sets" between SQL Server and PostgreSQL? → A: Row-by-row hash comparison (MD5/SHA256 per row, then aggregate)
- Q: What tolerance is acceptable for floating-point/numeric data type conversions? → A: 1e-10 relative tolerance (0.0000000001% difference allowed)
- Q: What is the rollback scope when a migration phase fails? → A: Object-level rollback (revert only failed object, keep successful ones)
- Q: What retry behavior should FDW connections use when queries fail? → A: 3 retries with exponential backoff (1s, 2s, 4s delays)
- Q: What conditions should be used for performance baseline measurements? → A: Warm cache, 3-run median (run query 3x after warmup, take middle value)
- Q: How should the 8-hour cutover window be allocated across phases? → A: 1h pre-checks, 4h migration, 2h validation, 1h buffer
- Q: Should the 5-minute replication SLA be absolute or percentile-based? → A: p95 within 5 minutes (95% of replications complete within 5 min)
- Q: How should migrated functions handle PostgreSQL-specific exceptions? → A: Catch and wrap in standardized error format with original SQLSTATE preserved
- Q: What should happen when row count or checksum validation fails? → A: Block deployment, generate detailed diff report for analysis
- Q: What should happen when a query exceeds the 20% performance degradation threshold? → A: Flag for optimization, allow deployment with documented exception
- Q: What should happen if cutover is behind schedule (e.g., 80% at hour 7)? → A: Go/no-go checkpoint at hour 6; decide to continue or rollback with 2h remaining
- Q: How should replication conflicts (concurrent updates to same row) be handled? → A: Source wins (PostgreSQL overwrites sqlwarehouse2 changes)
- Q: Who should be notified when an object migration fails and how? → A: Auto-alert DBA team via Slack/email, escalate to management after 30 min unresolved
- Q: What data volume should be used for performance baseline testing? → A: Production-equivalent volume (full copy or anonymized production data)
- Q: What are the disaster recovery targets (RPO/RTO) for PostgreSQL post-migration? → A: RPO 5 minutes / RTO 1 hour (standard HA with streaming replication)
- Q: What should happen if SQL Server data exceeds PostgreSQL column length during migration? → A: Auto-expand PostgreSQL column length to accommodate the data
- Q: What should happen if existing SQL Server data violates constraints when loaded into PostgreSQL? → A: Load data first, then enable constraints with violation report
- Q: How should applications transition from SQL Server to PostgreSQL during cutover? → A: Rolling restart (apps reconnect one-by-one to PostgreSQL)
- Q: At what replication lag thresholds should alerts be triggered? → A: Three-tier: info at 2 min, warning at 5 min, critical at 10 min
- Q: What concurrent user load should be used for performance testing? → A: Production-equivalent concurrent load (match typical production users)
- Q: How should character encoding be handled during migration (UTF-16 to UTF-8)? → A: Convert to UTF-8 with validation, flag characters that can't convert
- Q: How should datetime values be handled during migration? → A: Treat SQL Server DATETIME as UTC, convert to TIMESTAMP WITH TIME ZONE
- Q: How should cascading delete/update behavior be validated? → A: Trust schema migration, validate only if issues reported
- Q: What is the acceptable refresh time for materialized views? → A: Under 10 minutes with REFRESH CONCURRENTLY (no query blocking)
- Q: How should database permissions be migrated? → A: Map to PostgreSQL roles with documented equivalence table
- Q: What specific tests should pass immediately after cutover? → A: Critical path tests only (top 10 queries, key functions, FDW connectivity)
- Q: How should circular dependencies between views and functions be handled? → A: Refactor to eliminate circular dependencies before migration
- Q: What is the acceptable failover time if the primary PostgreSQL instance fails? → A: Under 60 seconds with automatic failover
- Q: What encryption should be configured for the PostgreSQL deployment? → A: TLS 1.3 for transit, AES-256 for at rest
- Q: How should the 90% test coverage requirement be distributed across object types? → A: Focus on critical path: 100% P0 objects, 90% P1, 80% P2/P3
- Q: How should NULL values be validated during table migration? → A: Column-level NULL counts comparison (COUNT where column IS NULL)
- Q: When should rollback procedures be tested? → A: Document-only (rollback procedure documented but not tested before production)
- Q: What connection pooling settings should be used for FDW? → A: Pool size 10, lifetime 30 min, idle timeout 5 min
- Q: What level of audit logging should be configured? → A: DDL and security events only (schema changes, login/logout, permission changes)
- Q: When should maintenance windows be scheduled? → A: Monthly 4-hour window for major maintenance
- Q: How should recursive CTE results be validated (upstream/downstream views)? → A: Traversal depth + node count per level comparison
- Q: What is the maximum time window for executing a rollback after cutover? → A: 7 days (one week to detect major issues)
- Q: How should FDW query pushdown be validated? → A: EXPLAIN ANALYZE verification for key FDW queries (check "Remote SQL")
- Q: How should quality scores be applied consistently across FR-013 and SC-013? → A: Tiered by priority: P0=9.0/10, P1=8.0/10, P2/P3=7.0/10 minimum
- Q: How should the PostgreSQL deployment be sized for future data growth? → A: Auto-scaling infrastructure (cloud-native, scale on demand)
- Q: How should SymmetricDS recover when replication falls significantly behind? → A: Auto-recovery with batch catch-up (larger batches until caught up)
- Q: How should transaction deadlocks be handled in PostgreSQL? → A: Automatic retry with exponential backoff (3 retries, 100ms/200ms/400ms)
- Q: What must pass before proceeding to each migration phase? → A: Automated gate checks (scripts verify prerequisites, block if failed)
- Q: Should all objects be renamed to snake_case or maintain backward compatibility? → A: Full snake_case conversion, mapping table for application team reference only
- Q: What should happen when AWS SCT cannot convert an object? → A: Flag for manual conversion, continue with other objects
- Q: How should constraint functional equivalence be validated? → A: Test with boundary values (attempt violations, verify rejection)
- Q: How should index execution plan utilization be validated? → A: EXPLAIN ANALYZE on key queries (verify index scans in plans)
- Q: What should happen if external database schema changes after FDW configuration? → A: Automated periodic validation with alerts on schema drift
- Q: Should query performance validation be tiered by complexity? → A: Yes - Simple (CRUD) spot-check, Medium (joins) full test, Complex (CTEs/subqueries) deep analysis
- Q: Are performance requirements (SC-004, CN-004, AS-009) aligned or differentiated? → A: Differentiated by object type: SC-004 for views, CN-004 for functions, AS-009 for tables
- Q: How should AS-014 (30-day SQL Server) and CN-023 (7-day rollback) be reconciled? → A: Align both to 7 days (SQL Server decommissioned after 7 days)
- Q: How should AS-001 (AWS SCT 70% quality) be validated? → A: Trust assumption, validate only during object-by-object migration
- Q: Are current validation methods (row count + hash + NULL counts) sufficient to guarantee zero data loss? → A: Yes, current methods are sufficient - row counts verify no missing rows, row-by-row hashing verifies exact data match, column-level NULL counts verify null handling
- Q: How should constitution compliance (7 core principles) be validated for all migrated objects? → A: Automated linting + manual spot-check (linting tools for automated detection, manual review for complex cases)
- Q: How should schema-qualified references be enforced across all objects (CN-010)? → A: Automated pre-deployment scan (script scans all SQL for unqualified table/view/function references)
- Q: How should dependency analysis files (lote1-4) accuracy be validated (AS-006)? → A: Automated cross-reference with SQL Server catalog (compare dependency files against sys.sql_expression_dependencies)
- Q: How should FDW compatibility with external databases be validated (AS-010)? → A: Pre-migration connectivity test (test FDW connections and sample queries to hermes/sqlapps/deimeter in staging)
- Q: What deployment gate should enforce constitution compliance (AS-012)? → A: Production gate only (allow DEV/STAGING with violations for iteration, block PROD deployment until compliant)
- Q: Should the original 8 edge cases be prioritized over the 24 expanded cases? → A: Yes, mark original 8 as P0 edge cases with mandatory 100% test coverage
- Q: Should additional edge cases (empty tables, max-row tables, concurrent DDL) be added to spec? → A: Yes, add these three specific edge cases to ensure known gaps are addressed

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Database Administrator Migrates Critical Views (Priority: P1)

As a Database Administrator, I need to migrate all views from SQL Server to PostgreSQL so that applications querying data through views continue to function after the migration.

**Why this priority**: Views provide essential data abstractions used by the Pegasus application. The `translated` view (materialized) and recursive CTEs (`upstream`, `downstream`) are critical for material lineage tracking - a core business capability.

**Independent Test**: Can be fully tested by deploying migrated views to a test environment, executing existing application queries against them, and comparing result sets with SQL Server outputs. Delivers immediate value by validating that data access patterns remain intact.

**Acceptance Scenarios**:

1. **Given** a SQL Server view with standard SELECT logic, **When** the view is migrated to PostgreSQL, **Then** queries against the PostgreSQL view return identical results to the SQL Server version
2. **Given** an indexed view in SQL Server, **When** migrated to PostgreSQL as a materialized view, **Then** query performance remains within 20% of the SQL Server baseline
3. **Given** a recursive CTE view, **When** migrated to PostgreSQL, **Then** the recursion logic produces correct hierarchical results for material lineage queries
4. **Given** a view with cross-database references (linked servers), **When** migrated to PostgreSQL, **Then** Foreign Data Wrappers (FDW) provide equivalent data access to external databases

---

### User Story 2 - Database Administrator Migrates Table-Valued Functions (Priority: P1)

As a Database Administrator, I need to migrate all table-valued functions (TVFs) from SQL Server to PostgreSQL so that stored procedures and application code calling these functions continue to work correctly.

**Why this priority**: The McGet* function family (McGetUpStream, McGetDownStream, McGetUpStreamByList, McGetDownStreamByList) are called by multiple procedures and represent core material lineage logic. Without these functions, material reconciliation and processing workflows will fail.

**Independent Test**: Can be fully tested by calling each migrated function with known input parameters and comparing output result sets with SQL Server. Delivers value by validating critical data retrieval logic independently of calling procedures.

**Acceptance Scenarios**:

1. **Given** a table-valued function accepting parameters, **When** the function is migrated to PostgreSQL, **Then** calling the function with the same parameters returns identical rows and columns as SQL Server
2. **Given** a function using the GooList user-defined table type, **When** migrated to PostgreSQL using temporary table pattern, **Then** the function correctly processes batch input lists
3. **Given** a function with complex CTEs and joins, **When** migrated to PostgreSQL, **Then** query execution completes within 20% of SQL Server performance
4. **Given** a scalar function, **When** migrated to PostgreSQL, **Then** the function returns the same scalar value for equivalent inputs

---

### User Story 3 - Database Administrator Migrates Table Structures (Priority: P1)

As a Database Administrator, I need to migrate all table schemas, indexes, and constraints from SQL Server to PostgreSQL so that data storage structures support application operations and maintain referential integrity.

**Why this priority**: Tables are the foundation of the database. Without properly migrated table schemas, indexes, and constraints, no other database objects can function. The 91 tables include critical structures like `goo` (material master), `material_transition`, and `transition_material` that store core business data.

**Independent Test**: Can be fully tested by creating tables in PostgreSQL, validating all constraints (primary keys, foreign keys, check constraints), testing index performance, and verifying data type compatibility. Delivers value by establishing the foundational data layer.

**Acceptance Scenarios**:

1. **Given** a SQL Server table schema, **When** migrated to PostgreSQL, **Then** all columns preserve data types with appropriate conversions (e.g., NVARCHAR to VARCHAR, IDENTITY to GENERATED ALWAYS AS IDENTITY)
2. **Given** table constraints (primary keys, foreign keys, check constraints), **When** migrated to PostgreSQL, **Then** all constraints enforce the same business rules and referential integrity
3. **Given** table indexes, **When** migrated to PostgreSQL, **Then** query performance for indexed columns remains within 20% of SQL Server baseline
4. **Given** tables with large row counts, **When** migrated to PostgreSQL, **Then** data loads complete successfully with zero data loss and matching row counts

---

### User Story 4 - Database Administrator Configures External Data Integrations (Priority: P2)

As a Database Administrator, I need to configure Foreign Data Wrappers (FDW) to replace SQL Server linked servers so that the Perseus database can continue accessing data from external databases (hermes, sqlapps, deimeter).

**Why this priority**: The Pegasus application requires cross-database queries to enrich material data with experimental and run information. While critical for full functionality, this can be implemented after core objects are migrated since applications can temporarily use direct database connections.

**Independent Test**: Can be fully tested by configuring FDW connections, executing queries that join local tables with foreign tables, and validating that result sets match current linked server queries. Delivers value by restoring cross-database query capabilities.

**Acceptance Scenarios**:

1. **Given** SQL Server linked server queries to hermes database, **When** replaced with postgres_fdw, **Then** queries return identical results with acceptable performance
2. **Given** views joining local and foreign tables, **When** executed in PostgreSQL, **Then** the query optimizer efficiently pushes predicates to foreign servers where appropriate
3. **Given** FDW connections to sqlapps.common database, **When** queries access foreign tables, **Then** connection pooling and authentication work reliably without manual intervention
4. **Given** scheduled jobs querying foreign data, **When** executed in PostgreSQL, **Then** FDW connections remain stable and do not cause job failures

---

### User Story 5 - Database Administrator Establishes Data Replication (Priority: P2)

As a Database Administrator, I need to configure SymmetricDS replication from PostgreSQL to sqlwarehouse2 so that downstream data warehouse systems continue receiving updated Perseus data.

**Why this priority**: Data warehouse systems depend on Perseus data for reporting and analytics. While important, replication can be configured after core migration since warehouse refreshes can temporarily run in batch mode or use alternative data pipelines.

**Independent Test**: Can be fully tested by configuring SymmetricDS, inserting/updating/deleting data in source tables, and verifying changes replicate to sqlwarehouse2 within acceptable latency. Delivers value by restoring automated data synchronization.

**Acceptance Scenarios**:

1. **Given** a table configured for replication, **When** rows are inserted in PostgreSQL, **Then** the same rows appear in sqlwarehouse2 within the defined replication SLA (e.g., 5 minutes)
2. **Given** a table with updates, **When** rows are modified in PostgreSQL, **Then** changes replicate to sqlwarehouse2 preserving data integrity
3. **Given** replication monitoring, **When** replication lag exceeds thresholds, **Then** alerts notify administrators of replication issues
4. **Given** a replication failure scenario, **When** connectivity is restored, **Then** SymmetricDS resumes replication without data loss

---

### User Story 6 - Database Administrator Migrates SQL Agent Jobs (Priority: P3)

As a Database Administrator, I need to migrate SQL Server Agent jobs to PostgreSQL scheduling mechanisms (pgAgent or cron) so that automated database maintenance and processing tasks continue running on schedule.

**Why this priority**: Jobs automate routine tasks like data reconciliation and cleanup. While necessary for long-term operations, these can be manually executed during initial migration phases, making this lower priority than core data objects.

**Independent Test**: Can be fully tested by configuring equivalent jobs in PostgreSQL, executing them manually first, then validating scheduled execution produces expected results (e.g., reconciliation completes, logs are created). Delivers value by restoring automation and reducing manual intervention.

**Acceptance Scenarios**:

1. **Given** a SQL Server Agent job calling stored procedures, **When** migrated to pgAgent, **Then** the job executes on the same schedule and calls equivalent PostgreSQL procedures
2. **Given** job failure scenarios, **When** a job step fails in PostgreSQL, **Then** error handling behaves equivalently to SQL Server (e.g., notifications sent, retries attempted)
3. **Given** job dependencies, **When** jobs are scheduled in PostgreSQL, **Then** dependent jobs execute in the correct sequence
4. **Given** job logging, **When** jobs execute in PostgreSQL, **Then** execution history is captured for troubleshooting and audit purposes

---

### Edge Cases

- What happens when a view references a table that hasn't been migrated yet? Migration must follow dependency order identified in dependency analysis files.
- What happens when circular dependencies exist between views and functions? Refactor to eliminate circular dependencies during analysis phase before migration; this ensures clean dependency ordering and prevents deployment failures.
- How are recursive CTE views (upstream/downstream) validated for correctness? Compare traversal depth and node count per level between SQL Server and PostgreSQL results; validate that maximum recursion depth matches and each level contains identical node counts.
- How does the system handle views with proprietary SQL Server syntax (e.g., NOLOCK hints)? Remove hints and rely on PostgreSQL's MVCC model for concurrency.
- What happens when a table has SQL Server-specific data types (e.g., MONEY, UNIQUEIDENTIFIER)? Convert to appropriate PostgreSQL types (NUMERIC, UUID) with explicit casting.
- What tolerance applies to floating-point comparisons (FLOAT, REAL, DOUBLE PRECISION)? Apply 1e-10 relative tolerance for validation; differences within this threshold are considered equivalent.
- What happens when SQL Server data exceeds PostgreSQL column length? Auto-expand PostgreSQL column length to accommodate the data (e.g., VARCHAR(50) → VARCHAR(100)); log all column length adjustments for documentation and application team notification.
- What happens when existing SQL Server data violates constraints during PostgreSQL load? Load data with constraints disabled, then enable constraints and generate violation report; violating rows indicate pre-existing data quality issues in source system to be addressed separately.
- How do applications transition during cutover? Rolling restart approach: applications are restarted one-by-one with updated PostgreSQL connection strings; each app is validated before proceeding to the next; allows controlled rollback if issues detected with specific applications.
- How is character encoding handled (SQL Server UTF-16 to PostgreSQL UTF-8)? Convert all text data to UTF-8 during migration; validate each row and flag any characters that cannot be represented in UTF-8; generate report of affected rows for manual review before proceeding.
- How are datetime values handled during migration? SQL Server DATETIME columns are treated as UTC and converted to PostgreSQL TIMESTAMP WITH TIME ZONE; this preserves temporal accuracy and enables proper timezone-aware operations in PostgreSQL.
- How is cascading delete/update behavior validated? Schema migration is trusted for cascade clauses (ON DELETE/UPDATE); detailed cascade testing is performed only if application issues are reported post-migration; schema comparison verifies clause presence.
- What smoke tests run immediately after cutover? Critical path tests: top 10 most-used queries, McGet* function family, FDW connectivity to hermes/sqlapps/deimeter, materialized view refresh, and basic CRUD on core tables (goo, material_transition); all must pass before declaring cutover complete.
- How does the system handle functions using cursors? Refactor to set-based operations following the constitution's prohibition of Row-By-Agonizing-Row patterns.
- What happens when GooList table-valued parameter type is used by functions? Implement temporary table pattern as defined in the constitution and project specification.
- How does the system handle indexed views that don't exist in PostgreSQL? Convert to materialized views with trigger-based or scheduled refresh strategies.
- What happens when AWS SCT cannot convert an object? Flag the object for manual conversion, log the SCT error details, continue with remaining objects; flagged objects are prioritized in manual refactoring queue with SCT error as context for the manual conversion approach.
- What happens when FDW connections to external databases fail? Implement 3 retries with exponential backoff (1s, 2s, 4s delays); after exhausting retries, raise exception with connection details for troubleshooting; configure connection pooling (pool size 10, lifetime 30 min, idle timeout 5 min) to minimize connection overhead.
- How does the system handle replication lag exceeding acceptable thresholds? Configure SymmetricDS monitoring with three-tier alerting: info at 2 minutes (logged), warning at 5 minutes (Slack notification), critical at 10 minutes (page DBA on-call); automatic retry on transient failures.
- How does the system handle transaction deadlocks in PostgreSQL? Implement automatic retry with exponential backoff (3 retries at 100ms/200ms/400ms delays) for deadlock errors (SQLSTATE 40P01); if all retries exhausted, raise exception to caller with deadlock context.
- How does the system handle replication conflicts (concurrent updates)? Source wins strategy: PostgreSQL (system of record) overwrites any conflicting changes in sqlwarehouse2; conflicts are logged for audit but do not halt replication.
- How does the system recover from replication backlog after outages? SymmetricDS auto-recovers using batch catch-up mode with larger batch sizes until fully synchronized; no manual intervention required; progress monitored via replication lag metrics.
- What happens if external database schemas (hermes, sqlapps, deimeter) change after FDW setup? Automated weekly validation job compares foreign table definitions against remote schemas; alerts DBA on schema drift; FDW definitions updated manually after review to prevent breaking changes.
- What happens when an object migration fails during a phase? Apply object-level rollback: revert only the failed object (DROP IF EXISTS + restore from SQL Server definition), keep successfully migrated objects, fix the issue, and retry the failed object.
- What happens when data validation (row count or checksum) fails? Block deployment immediately, generate detailed diff report showing mismatched rows/values, investigate root cause before proceeding; deployment cannot continue until validation passes.
- What happens when a query exceeds the 20% performance threshold? Flag the query for post-migration optimization, allow deployment with documented exception including query name, measured degradation percentage, and remediation plan; track in performance exception register.
- What happens if cutover is behind schedule at hour 6? Mandatory go/no-go checkpoint: if projected completion exceeds 8 hours, initiate rollback; if completion is achievable within remaining 2 hours, continue with heightened monitoring.
- Who is notified when migration fails? Automated alerts sent to DBA team via Slack/email immediately upon failure; if unresolved after 30 minutes, escalate to management; all failures logged with timestamp, object name, error details, and remediation attempts.
- What happens when migrating empty tables (zero rows)? Empty tables are migrated with schema only; validation confirms zero row count matches; no data hash comparison needed for empty tables.
- What happens when migrating tables with maximum row counts? Large tables (>10M rows) use batch migration with progress tracking; row count validation performed incrementally per batch; memory-efficient streaming approach prevents OOM errors.
- What happens if DDL changes occur during migration (concurrent DDL)? Migration acquires advisory locks on objects being migrated; concurrent DDL attempts are blocked during object migration; post-migration validation confirms no schema drift occurred.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST migrate all 22 SQL Server views to PostgreSQL preserving query logic and result sets
- **FR-002**: System MUST convert SQL Server indexed views to PostgreSQL materialized views with REFRESH CONCURRENTLY capability completing in under 10 minutes without blocking queries
- **FR-003**: System MUST migrate all 25 functions (15 table-valued, 10 scalar) from T-SQL to PL/pgSQL preserving input/output signatures and logic
- **FR-004**: System MUST migrate all 91 tables with correct data type mappings, preserving all columns and metadata
- **FR-005**: System MUST migrate all 352 indexes ensuring query performance remains within 20% of SQL Server baseline
- **FR-006**: System MUST migrate all 271 constraints (primary keys, foreign keys, check constraints, unique constraints) maintaining referential integrity
- **FR-007**: System MUST convert SQL Server user-defined type GooList to PostgreSQL temporary table pattern for use in functions
- **FR-008**: System MUST configure Foreign Data Wrappers for external database access (hermes - 6 tables, sqlapps.common - 9 tables, deimeter - 2 tables)
- **FR-009**: System MUST configure SymmetricDS replication to sqlwarehouse2 for all replicated tables maintaining data synchronization
- **FR-010**: System MUST migrate 7 SQL Server Agent jobs to PostgreSQL scheduling mechanism (pgAgent or cron) preserving execution schedules
- **FR-011**: System MUST validate each migrated object through analysis, refactoring, validation, and deployment phases as defined in the project workflow
- **FR-012**: System MUST maintain dependency order during migration, ensuring dependent objects are migrated after their dependencies
- **FR-013**: System MUST achieve tiered quality scores: P0 critical objects ≥9.0/10, P1 objects ≥8.0/10, P2/P3 objects ≥7.0/10 across all five dimensions (syntax correctness, logic preservation, performance, maintainability, security)
- **FR-014**: System MUST produce identical result sets for queries executed against PostgreSQL compared to SQL Server for equivalent inputs
- **FR-015**: System MUST convert all object names from PascalCase to snake_case (no aliases/synonyms) and document conversions in a mapping table for application team reference to update hardcoded references
- **FR-016**: System MUST use schema-qualified object references for all database objects to prevent ambiguity and security vulnerabilities
- **FR-017**: System MUST implement explicit error handling with specific exception types for all migrated functions and procedures; PostgreSQL-specific exceptions must be caught and wrapped in standardized error format preserving original SQLSTATE for debugging
- **FR-018**: System MUST preserve all business logic from SQL Server objects while adapting to PostgreSQL idioms and best practices

### Key Entities *(include if feature involves data)*

- **View**: Represents a virtual table providing data abstraction; includes standard views, recursive CTE views, and materialized views (converted from indexed views); critical examples include `translated`, `upstream`, `downstream`, `goo_relationship`
- **Function**: Represents reusable logic returning table sets or scalar values; includes McGet* family (upstream/downstream lineage), Get* family (legacy queries), and utility functions; depends on views and temporary tables
- **Table**: Represents physical data storage structure; 91 tables including critical entities like `goo` (material master), `material_transition`, `transition_material`, `m_upstream`, `m_downstream`, `container`, `fatsmurf`; foundation for all other objects
- **Index**: Represents performance optimization structure for tables; 352 indexes including primary key indexes, foreign key indexes, and query optimization indexes
- **Constraint**: Represents data integrity rules including primary keys, foreign keys, unique constraints, check constraints; 271 constraints enforce business rules
- **User-Defined Type**: Represents custom data type (GooList) used as table-valued parameter; requires conversion to temporary table pattern in PostgreSQL
- **Foreign Data Wrapper (FDW)**: Represents connection to external database allowing local queries to access remote tables; replaces SQL Server linked servers for hermes, sqlapps, deimeter
- **Replication Configuration**: Represents SymmetricDS setup for synchronizing data to sqlwarehouse2; includes table registration, triggers, and routing configuration
- **Job**: Represents scheduled automated task; 7 SQL Server Agent jobs require migration to pgAgent or cron with equivalent schedules and error handling

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: All 22 views return identical result sets in PostgreSQL compared to SQL Server for the same queries (100% data correctness), verified by row-by-row hash comparison (MD5/SHA256 per row with aggregate hash match)
- **SC-002**: All 25 functions produce identical outputs in PostgreSQL compared to SQL Server for equivalent inputs (100% logic preservation), verified by row-by-row hash comparison for table-valued functions and exact value match for scalar functions
- **SC-003**: All 91 tables are migrated with zero data loss verified by row count validation, row-by-row hash comparison (MD5/SHA256 per row with aggregate hash match), AND column-level NULL counts comparison (100% data integrity)
- **SC-004**: View query performance remains within 20% of SQL Server baseline measured by execution time comparison using warm cache, 3-run median methodology (applies to all 22 views including materialized view refresh)
- **SC-005**: All 352 indexes are created and query plans utilize them appropriately verified by EXPLAIN ANALYZE on key queries (confirming Index Scan/Index Only Scan nodes appear where expected)
- **SC-006**: All 271 constraints are enforced correctly verified by boundary value testing (attempt constraint violations, verify PostgreSQL rejects them identically to SQL Server)
- **SC-007**: Foreign Data Wrapper queries to external databases (hermes, sqlapps, deimeter) return correct results with acceptable performance (<2x SQL Server linked server latency); query pushdown verified via EXPLAIN ANALYZE showing predicates in "Remote SQL"
- **SC-008**: SymmetricDS replication to sqlwarehouse2 maintains data synchronization within 5-minute SLA at p95 (95% of replications complete within 5 minutes) measured by replication lag monitoring
- **SC-009**: All 7 migrated jobs execute successfully on schedule with logging and error handling equivalent to SQL Server Agent
- **SC-010**: Zero production incidents during cutover to PostgreSQL verified by incident tracking
- **SC-011**: Migration cutover downtime is less than 8 hours measured from application shutdown to successful restart
- **SC-012**: Test coverage follows priority-based distribution: 100% coverage for P0 critical objects (translated view, McGet* functions, core tables), 90% for P1 objects, 80% for P2/P3 objects
- **SC-013**: All migrated objects achieve tiered quality scores: P0 critical objects ≥9.0/10, P1 objects ≥8.0/10, P2/P3 objects ≥7.0/10 with no dimension below 6.0/10
- **SC-014**: Complete documentation is delivered including technical specifications, operational runbooks, and training materials verified by documentation review checklist
- **SC-015**: Database availability post-migration meets 99.9% uptime SLA measured over 30-day period
- **SC-016**: Disaster recovery capabilities meet RPO 5 minutes (maximum data loss) and RTO 1 hour (maximum recovery time) verified by DR drill
- **SC-017**: High availability failover completes in under 60 seconds with automatic promotion verified by failover testing

## Assumptions

- **AS-001**: AWS Schema Conversion Tool (SCT) output provides a reasonable starting point (70% complete) requiring manual review and correction for remaining 30%
- **AS-002**: Development, Staging, and Production PostgreSQL environments are available and properly configured before migration begins
- **AS-003**: Production SQL Server database remains available for parallel validation during migration phases
- **AS-004**: Test data at production-equivalent volume (full copy or anonymized production data) is available for performance benchmarking to ensure realistic measurements
- **AS-005**: Stored procedures (15 core + 6 MS replication) have already been successfully migrated and are excluded from this scope
- **AS-006**: Dependency analysis files (lote1-lote4 and consolidated) accurately represent object dependencies and will be used for migration sequencing
- **AS-007**: Application code changes are out of scope; applications will connect to PostgreSQL using updated connection strings without code modifications
- **AS-008**: PostgreSQL 17 is the target version and provides all required features for migration
- **AS-009**: Table query performance degradation up to 20% is acceptable for all 91 tables based on cost/benefit analysis of migration, measured using warm cache, 3-run median methodology
- **AS-010**: External databases (hermes, sqlapps, deimeter) are PostgreSQL-compatible or have FDW drivers available
- **AS-011**: SymmetricDS is the approved replication tool for synchronizing data to sqlwarehouse2
- **AS-012**: The constitution's seven core principles (ANSI-SQL primacy, strict typing, set-based execution, atomic transactions, idiomatic naming, structured error handling, modular logic) are binding requirements for all migrated objects
- **AS-013**: Each object follows the four-phase workflow: Analysis, Refactoring (correction), Validation (testing), Deployment
- **AS-014**: Rollback capability to SQL Server must be maintained for 7 days post-cutover; SQL Server can be decommissioned after 7-day rollback window expires (aligned with CN-023)

## Dependencies

- **DP-001**: Migration depends on availability of PostgreSQL 17 cluster (AWS RDS or EC2) with appropriate sizing and configuration
- **DP-002**: Migration depends on completion of stored procedure migration (15 procedures already completed)
- **DP-003**: Migration depends on access to production SQL Server database for extracting object definitions and test data
- **DP-004**: Migration depends on availability of dependency analysis documents (docs/code-analysis/dependency-analysis-*.md) for correct sequencing
- **DP-005**: Migration depends on access to AWS Schema Conversion Tool for baseline object conversion
- **DP-006**: Migration depends on availability of project constitution (`.specify/memory/constitution.md`) defining coding standards
- **DP-007**: Foreign Data Wrapper configuration depends on network connectivity and authentication to external databases (hermes, sqlapps, deimeter)
- **DP-008**: Replication configuration depends on SymmetricDS installation and licensing
- **DP-009**: Job migration depends on selection and installation of PostgreSQL job scheduling tool (pgAgent recommended)
- **DP-010**: Testing depends on availability of representative test data and test environments (DEV, STAGING)
- **DP-011**: Production deployment depends on approval from technical lead and DBA reviewers based on quality gate criteria
- **DP-012**: Application teams depend on naming conversion mapping table to update any hardcoded object references

## Out of Scope

- **OOS-001**: Application code changes and API modifications are out of scope; applications must work with migrated database using connection string updates only
- **OOS-002**: New replication topology design is out of scope; existing replication to sqlwarehouse2 will be recreated with same architecture using SymmetricDS
- **OOS-003**: End-user acceptance testing (UAT) is out of scope; testing focuses on technical validation of database objects
- **OOS-004**: User manuals and end-user documentation are out of scope; focus is on technical documentation for database administrators and developers
- **OOS-005**: Stored procedures migration is out of scope (already completed in previous sprints 1-8)
- **OOS-006**: Database redesign or schema optimization is out of scope; migration preserves existing structure and logic with minimal changes required for PostgreSQL compatibility
- **OOS-007**: Performance optimization beyond 20% baseline is out of scope unless critical issues emerge
- **OOS-008**: Migration of non-Perseus databases is out of scope; focus is exclusively on Perseus database objects
- **OOS-009**: Application architecture changes or microservices refactoring are out of scope
- **OOS-010**: Data archival or purging strategies are out of scope; all current production data will be migrated

## Constraints

- **CN-001**: Migration must achieve zero data loss verified through row count validation AND row-by-row hash comparison (MD5/SHA256 per row with aggregate hash match)
- **CN-002**: Migration cutover downtime must not exceed 8 hours to minimize business impact; allocated as: 1h pre-checks, 4h migration execution, 2h validation, 1h buffer for issues
- **CN-003**: All migrated objects must comply with the seven core principles defined in the project constitution
- **CN-004**: Function execution performance must remain within 20% of SQL Server baseline for all 25 functions, measured using warm cache, 3-run median methodology
- **CN-005**: Quality scores for all migrated objects must achieve ≥7.0/10 overall with no dimension below 6.0/10
- **CN-006**: Migration must maintain referential integrity across all 271 constraints
- **CN-007**: All object names must follow snake_case lowercase naming convention per constitution
- **CN-008**: All transactions must be explicitly managed with BEGIN/COMMIT/ROLLBACK per constitution
- **CN-009**: All type conversions must use explicit CAST or :: notation per constitution's strict typing principle
- **CN-010**: All database object references must be schema-qualified to prevent search_path vulnerabilities
- **CN-011**: Migration must preserve existing security model by mapping SQL Server permissions to PostgreSQL roles with documented equivalence table for audit and reference
- **CN-012**: Rollback procedures must be documented and ready before production deployment; rollback scope is object-level (revert only failed objects while preserving successfully migrated ones); testing is document-based review only
- **CN-013**: Floating-point comparisons (FLOAT, REAL, DOUBLE PRECISION) must use 1e-10 relative tolerance; differences within this threshold are considered equivalent
- **CN-014**: FDW queries must implement 3 retries with exponential backoff (1s, 2s, 4s delays) before returning failure to caller
- **CN-015**: Data validation failures (row count or checksum mismatch) must block deployment and generate detailed diff report; deployment cannot proceed until validation passes
- **CN-016**: Queries exceeding 20% performance threshold may proceed with documented exception (query name, degradation %, remediation plan) tracked in performance exception register for post-migration optimization
- **CN-017**: Mandatory go/no-go checkpoint at hour 6 of cutover; if projected completion exceeds 8 hours, initiate rollback with 2 hours buffer for safe recovery
- **CN-018**: PostgreSQL deployment must support RPO 5 minutes and RTO 1 hour through streaming replication and automated failover configuration
- **CN-019**: Performance validation must be conducted under production-equivalent concurrent load to accurately measure the 20% threshold under realistic conditions
- **CN-020**: PostgreSQL deployment must use TLS 1.3 for all connections (encryption in transit) and AES-256 for storage (encryption at rest)
- **CN-021**: Audit logging must capture DDL statements and security events (schema changes, login/logout, permission changes) for compliance
- **CN-022**: Monthly 4-hour maintenance window must be scheduled for major maintenance operations (index rebuilds, VACUUM FULL, PostgreSQL updates)
- **CN-023**: Rollback to SQL Server must be executable within 7 days of cutover; after 7 days, rollback is no longer supported and PostgreSQL becomes the permanent system of record
- **CN-024**: PostgreSQL deployment must use auto-scaling cloud-native infrastructure (AWS RDS or Aurora) to handle data growth on demand without manual capacity planning
- **CN-025**: Each migration phase must pass automated gate checks (prerequisite validation scripts) before proceeding; manual override requires DBA approval and documented justification
- **CN-026**: Performance validation must be tiered by query complexity: Simple queries (CRUD) get spot-check validation, Medium queries (joins) get full testing, Complex queries (CTEs, subqueries, recursive) get deep EXPLAIN ANALYZE analysis
