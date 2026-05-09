# Implementation Plan: T-SQL to PostgreSQL Database Migration

**Branch**: `001-tsql-to-pgsql` | **Date**: 2026-01-19 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/001-tsql-to-pgsql/spec.md`

**Note**: This plan guides the migration of Perseus database objects (views, functions, tables, indexes, constraints, FDW, replication, jobs) from SQL Server 2014 to PostgreSQL 17 following a four-phase workflow (Analysis, Refactoring, Validation, Deployment) with strict quality gates.

## Summary

**Primary Requirement**: Migrate all Perseus database objects from SQL Server to PostgreSQL preserving 100% data integrity, logic correctness, and performance within 20% of baseline while maintaining <8 hour cutover downtime.

**Technical Approach**:
- Use AWS Schema Conversion Tool (SCT) as 70% baseline, manually refactor remaining 30%
- Follow dependency-driven sequencing from analysis documents (lote1-4)
- Apply four-phase workflow per object: Analysis → Refactoring → Validation → Deployment
- Enforce constitution compliance (7 core principles) with ≥7.0/10 quality scores
- Maintain SQL Server rollback capability for 7 days post-migration

## Technical Context

**Language/Version**: SQL (T-SQL → PL/pgSQL), PostgreSQL 17, SQL Server 2014 Enterprise (source)
**Primary Dependencies**:
- AWS Schema Conversion Tool (SCT) - baseline conversion (70% complete)
- postgres_fdw - Foreign Data Wrapper for external database access
- SymmetricDS - replication engine for sqlwarehouse2 synchronization
- pgAgent or cron - job scheduling replacement for SQL Server Agent
**Storage**: PostgreSQL 17 cluster (AWS RDS or EC2) - 91 tables, 352 indexes, 271 constraints
**Testing**:
- Unit tests: per-object validation (functions, views, procedures)
- Integration tests: cross-object workflow validation
- Performance tests: EXPLAIN ANALYZE, baseline comparison (<20% degradation)
- Data integrity tests: row count, checksum validation, constraint verification
**Target Platform**: Linux server (PostgreSQL 17 on AWS RDS/EC2), multi-AZ deployment
**Project Type**: Database migration - schema and data migration with external integrations
**Performance Goals**:
- Query execution within 20% of SQL Server baseline
- FDW query latency <2x SQL Server linked server latency
- Replication lag <5 minutes (p95)
- Materialized view refresh performance: Under 10 minutes with REFRESH CONCURRENTLY (no query blocking)
**Constraints**:
- Zero data loss (100% integrity via row count + checksum)
- <8 hour cutover downtime window
- 99.9% availability post-migration (30-day measurement)
- Quality score ≥7.0/10 per object (≥8.0/10 average)
- Rollback capability maintained for 7 days
- Schema-qualified references only (no search_path usage)
**Scale/Scope**:
- 22 views (including materialized views for indexed views)
- 25 functions (15 table-valued, 10 scalar)
- 91 tables with full data migration
- 352 indexes
- 271 constraints
- 1 user-defined type (GooList → temporary table pattern)
- 3 FDW connections (hermes-6 tables, sqlapps-9 tables, deimeter-2 tables)
- 1 replication target (sqlwarehouse2)
- 7 SQL Agent jobs → pgAgent/cron
- Excludes 15 stored procedures (already migrated)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Based on the Perseus Database Migration Constitution (v1.0.0), this migration must comply with the following gates:

### Core Principles Compliance

✅ **I. ANSI-SQL Primacy** - PASS
- Migration prioritizes standard ANSI SQL over vendor-specific extensions
- AWS SCT conversion will be reviewed to remove SQL Server-specific syntax
- Constitution mandates portable, standard SQL for business logic

✅ **II. Strict Typing & Explicit Casting** - PASS
- All data type conversions require explicit CAST or :: notation
- Spec defines data type mapping requirements (FR-004)
- No implicit type coercion allowed (PostgreSQL enforces this)

✅ **III. Set-Based Execution** - PASS
- Constitution prohibits cursors and RBAR patterns
- Edge cases identify cursor refactoring requirement
- Set-based operations using CTEs, window functions mandated

✅ **IV. Atomic Transaction Management** - PASS
- Explicit BEGIN/COMMIT/ROLLBACK required (CN-008)
- Error handling with specific exception types required (FR-017)
- Transaction boundaries explicitly managed per constitution

✅ **V. Idiomatic Naming & Scoping** - PASS
- snake_case naming convention mandated (CN-007)
- Naming conversion mapping table required (FR-015)
- Schema-qualified references required (FR-016, CN-010)

✅ **VI. Structured Error Resilience** - PASS
- Explicit error handling with specific exception types (FR-017)
- Constitution requires meaningful error telemetry
- No silent error swallowing allowed

✅ **VII. Modular Logic Separation** - PASS
- Schema-qualified references mandatory (FR-016, CN-010)
- Clean schema architecture enforced
- One responsibility per function/procedure

### Quality Standards Compliance

✅ **Quality Score Requirements** - PASS
- Minimum 7.0/10 overall (FR-013, CN-005)
- Target 8.0/10 average (SC-013)
- No dimension below 6.0/10
- Five dimensions: Syntax Correctness, Logic Preservation, Performance, Maintainability, Security

✅ **Performance Validation** - PASS
- Within 20% of SQL Server baseline (SC-004, CN-004, AS-009)
- EXPLAIN ANALYZE required for validation
- Performance testing with representative data (AS-004)

✅ **Migration Standards** - PASS
- Four-phase workflow defined (Analysis, Refactoring, Validation, Deployment) per AS-013
- AWS SCT baseline with manual review (AS-001)
- Dependency analysis files guide sequencing (AS-006, DP-004)

### Gate Violations Requiring Justification

**NONE** - All constitution requirements are satisfied by the specification.

### Pre-Phase 0 Checklist

Before proceeding to Phase 0 research, verify:
- [x] All seven core principles addressed in requirements
- [x] Quality score thresholds defined and measurable
- [x] Migration workflow aligned with constitution
- [x] No unjustified complexity introduced
- [x] Schema qualification enforced across all objects
- [x] Error handling strategy defined
- [x] Performance baselines and validation approach specified

**GATE STATUS**: ✅ **PASS** - Proceed to Phase 0 Research

## Project Structure

### Documentation (this feature)

```text
specs/001-tsql-to-pgsql/
├── spec.md              # Feature specification (already exists)
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
│   ├── migration-api.md # Migration workflow API/interface definitions
│   └── validation-contracts.md # Data validation contracts
├── checklists/          # Requirements quality checklists (already exist)
│   ├── requirements.md
│   └── migration-thorough-gate.md
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

**Structure Type**: Database Migration Project (non-standard - SQL scripts and tooling)

```text
sqlserver-to-postgresql-migration/
├── docs/                            # Project documentation
│   ├── PROJECT-SPECIFICATION.md     # Overall migration spec (reference)
│   ├── POSTGRESQL-PROGRAMMING-CONSTITUTION.md # Coding standards
│   ├── Core-Principles-T-SQL-to-PostgreSQL-Refactoring.md
│   ├── Project-History.md
│   └── code-analysis/               # Dependency analysis (lote1-4 + consolidated)
│       ├── dependency-analysis-consolidated.md
│       ├── dependency-analysis-lote1-stored-procedures.md
│       ├── dependency-analysis-lote2-functions.md
│       ├── dependency-analysis-lote3-views.md
│       └── dependency-analysis-lote4-types.md
│
├── source/                          # Database object definitions
│   ├── original/                    # Read-only source objects
│   │   ├── sqlserver/               # Original T-SQL from SQL Server
│   │   └── pgsql-aws-sct-converted/ # AWS SCT baseline output (70% complete)
│   └── building/                    # Work-in-progress migrations
│       └── pgsql/
│           └── refactored/          # Production-ready PostgreSQL code
│               ├── views/           # Migrated views (22 objects)
│               ├── functions/       # Migrated functions (25 objects)
│               ├── tables/          # Table DDL (91 schemas)
│               ├── indexes/         # Index definitions (352 indexes)
│               ├── constraints/     # Constraint definitions (271 constraints)
│               ├── types/           # User-defined types (1 object: GooList pattern)
│               ├── fdw/             # Foreign Data Wrapper configs
│               ├── replication/     # SymmetricDS configurations
│               └── jobs/            # pgAgent/cron job definitions (7 jobs)
│
├── scripts/                         # Automation and tooling
│   ├── validation/                  # Validation scripts
│   │   ├── syntax-check.sh
│   │   ├── performance-test.sql
│   │   ├── data-integrity-check.sql
│   │   └── dependency-check.sql
│   ├── deployment/                  # Deployment automation
│   │   ├── deploy-object.sh
│   │   ├── deploy-batch.sh
│   │   ├── rollback-object.sh
│   │   └── smoke-test.sh
│   └── automation/                  # Helper scripts
│       ├── analyze-object.py
│       ├── compare-versions.py
│       └── generate-tests.py
│
├── tests/                           # Test suites
│   ├── unit/                        # Per-object unit tests
│   │   ├── views/
│   │   ├── functions/
│   │   └── tables/
│   ├── integration/                 # Cross-object integration tests
│   │   ├── workflow-tests/
│   │   └── fdw-tests/
│   ├── performance/                 # Performance benchmarks
│   │   └── baseline-comparisons/
│   └── fixtures/                    # Test data
│       └── sample-data/
│
├── templates/                       # Templates for generated artifacts
│   ├── analysis-template.md
│   ├── object-template.sql
│   └── test-templates/
│
├── tracking/                        # Progress tracking
│   ├── database-objects-inventory.csv
│   ├── priority-matrix.csv
│   ├── progress-tracker.md
│   └── risk-register.md
│
└── specs/                           # Feature specifications (speckit workflow)
    └── 001-tsql-to-pgsql/          # This migration feature
```

**Structure Decision**:
This is a **database migration project**, not a traditional application. The structure organizes:
1. **Source objects** by migration state (original/converted/refactored)
2. **Database object types** (views, functions, tables, etc.) for clear separation
3. **Test organization** matching source structure (unit per object type, integration for workflows)
4. **Migration tooling** (validation, deployment, automation scripts)
5. **Documentation** (specs, analysis, tracking)

The structure reflects the four-phase workflow: original → AWS SCT converted → manually refactored → validated/deployed.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

**No violations detected.** All requirements align with the constitution's seven core principles and quality standards.

**Inherent Complexity (Not Violations)**:
This migration carries inherent complexity due to:
- **Large scope**: 91 tables + 22 views + 25 functions + 352 indexes + 271 constraints
- **External dependencies**: 3 FDW connections + replication + 7 jobs
- **Data integrity requirements**: Zero data loss with 100% correctness validation
- **Performance constraints**: 20% degradation maximum across all objects
- **Cutover window**: <8 hours for full migration

However, this complexity is **justified and unavoidable** for a production database migration. The four-phase workflow (Analysis, Refactoring, Validation, Deployment) with quality gates provides appropriate risk mitigation without introducing unnecessary complexity.


---

## Post-Phase 1 Constitution Check Re-evaluation

*Re-evaluated after Phase 1 (Design & Contracts) completion*

### Core Principles Re-verification

✅ **I. ANSI-SQL Primacy** - PASS (Confirmed)
- Research document confirms standard SQL approach
- Materialized view refresh uses standard pg_cron extension
- FDW configuration uses standard postgres_fdw
- GooList conversion uses standard temporary table pattern (no proprietary extensions)

✅ **II. Strict Typing & Explicit Casting** - PASS (Confirmed)
- Data model documents data type mappings (NVARCHAR→VARCHAR, MONEY→NUMERIC, etc.)
- All conversions explicitly defined in data-model.md
- Validation contracts require explicit type compatibility verification

✅ **III. Set-Based Execution** - PASS (Confirmed)
- GooList pattern uses set-based temp tables (not cursors)
- Research confirms no WHILE loops or cursors in implementation
- Temporary table pattern enables set-based JOINs

✅ **IV. Atomic Transaction Management** - PASS (Confirmed)
- Temp table pattern uses `ON COMMIT DROP` for transaction-scoped cleanup
- Validation contracts require explicit transaction management verification
- FDW pattern uses read-only approach (no distributed transactions)

✅ **V. Idiomatic Naming & Scoping** - PASS (Confirmed)
- Data model defines snake_case naming throughout (mcgetupstream, translated, etc.)
- All objects use schema-qualified references (perseus.*)
- Naming conversion mapping table included in requirements

✅ **VI. Structured Error Resilience** - PASS (Confirmed)
- FDW research documents specific exception handling (sqlstate 08000 for connection errors)
- Validation contracts require structured error handling verification
- Error logging and monitoring defined

✅ **VII. Modular Logic Separation** - PASS (Confirmed)
- Schema-qualified references mandatory throughout (CN-010)
- FDW uses separate foreign server objects (hermes_fdw, sqlapps_fdw, deimeter_fdw)
- Clear separation of concerns in data model

### Quality Standards Re-verification

✅ **Quality Score Requirements** - PASS (Confirmed)
- Validation contracts define 5-dimension scoring (syntax, logic, performance, maintainability, security)
- Minimum 7.0/10 overall threshold documented
- Target 8.0/10 average specified
- Quickstart example achieves 8.4/10 quality score

✅ **Performance Validation** - PASS (Confirmed)
- Research confirms 20% degradation threshold approach
- Materialized view provides 10-100x speedup (exceeds baseline)
- FDW optimization strategies documented (fetch_size tuning, predicate pushdown)
- Performance testing methodology defined in validation contracts

✅ **Migration Standards** - PASS (Confirmed)
- Four-phase workflow maintained (Analysis → Refactoring → Validation → Deployment)
- AWS SCT baseline + manual review approach confirmed in quickstart
- Dependency analysis files referenced for sequencing
- Quality gates defined for each phase transition

### Technical Unknowns Resolution

✅ **Materialized View Refresh Strategy** - RESOLVED
- **Decision**: Scheduled CONCURRENT refresh with pg_cron (every 10 minutes)
- **Rationale**: Balances freshness (5-15 minute staleness acceptable) vs production stability
- **Implementation**: Documented in research.md with complete configuration

✅ **GooList Type Conversion Pattern** - RESOLVED
- **Decision**: TEMPORARY TABLE pattern with ON COMMIT DROP
- **Rationale**: Optimal for large batches (10k-20k materials), supports PRIMARY KEY for JOINs
- **Implementation**: Documented in research.md and data-model.md with function signature changes

✅ **FDW Configuration Strategy** - RESOLVED
- **Decision**: Layered connection management with read-only access
- **Rationale**: Avoids distributed transaction complexity, ensures connection availability
- **Implementation**: Complete FDW production best practices documented in research.md

### Gate Violations Requiring Justification

**NONE** - All constitution requirements satisfied after Phase 1 design.

**Inherent Complexity Confirmed**:
- Large scope (91 tables + 22 views + 25 functions + 352 indexes + 271 constraints) - JUSTIFIED (production migration requirement)
- External dependencies (3 FDW + replication + 7 jobs) - JUSTIFIED (system integration requirement)
- Four-phase workflow - JUSTIFIED (risk mitigation for production database)

### Post-Phase 1 Checklist

- [x] All technical unknowns resolved (materialized view refresh, GooList pattern, FDW config)
- [x] Data model complete with 9 entity types documented
- [x] Migration workflow contracts defined (4 phases + validation contracts)
- [x] Quickstart guide created with complete example walkthrough
- [x] Constitution compliance verified across all design artifacts
- [x] Agent context updated with technology stack
- [x] No new constitution violations introduced during design

**POST-PHASE 1 GATE STATUS**: ✅ **PASS** - Ready for Phase 2 (Tasks Generation via /speckit.tasks)

---

## Implementation Readiness

### Artifacts Generated

**Phase 0 (Research)**: ✅ Complete
- `research.md`: All technical decisions documented (materialized views, GooList, FDW)

**Phase 1 (Design & Contracts)**: ✅ Complete
- `data-model.md`: 9 entity types with validation rules and state transitions
- `contracts/migration-workflow-api.md`: Four-phase workflow interfaces and quality gates
- `contracts/validation-contracts.md`: 5 validation contracts with pass/fail criteria
- `quickstart.md`: Complete walkthrough migrating `translated` view
- Agent context: CLAUDE.md updated with technology stack

**Phase 2 (Tasks)**: ⏳ Pending - Run `/speckit.tasks` to generate implementation tasks

### Next Steps

1. **Run `/speckit.tasks`** to generate task breakdown from this plan
2. **Execute tasks** following dependency order from data-model.md
3. **Track progress** using task checklist and quality gates
4. **Deploy incrementally** DEV → STAGING → PRODUCTION per phase 4 contracts

---

## Clarifications Applied (Session 2026-01-23)

**60 clarification questions answered** to achieve ~100% coverage of migration-thorough-gate.md checklist. Key decisions:

### Data Integrity & Validation
- **Row validation**: Row-by-row hash comparison (MD5/SHA256 per row)
- **Floating-point tolerance**: 1e-10 relative tolerance
- **NULL validation**: Column-level NULL counts comparison
- **Column length mismatch**: Auto-expand PostgreSQL column to accommodate data

### Migration Workflow & Sequencing
- **Rollback scope**: Object-level rollback (revert failed object only)
- **Rollback window**: 7 days (aligned AS-014 and CN-023)
- **Cutover allocation**: 1h pre-checks, 4h migration, 2h validation, 1h buffer
- **Cutover checkpoint**: Go/no-go at hour 6; rollback if projected >8h
- **Phase gates**: Automated prerequisite checks, block on failure
- **Dependency validation**: Automated cross-reference with sys.sql_expression_dependencies

### External Integration
- **FDW retry**: 3 retries with exponential backoff (1s, 2s, 4s)
- **FDW connection pool**: Size 10, lifetime 30 min, idle timeout 5 min
- **FDW pushdown validation**: EXPLAIN ANALYZE verification for key queries
- **FDW compatibility**: Pre-migration connectivity test in staging
- **Replication SLA**: p95 within 5 minutes
- **Replication conflicts**: Source wins (PostgreSQL overwrites sqlwarehouse2)
- **Replication recovery**: Auto-recovery with batch catch-up
- **Replication alerts**: Three-tier (2 min info, 5 min warning, 10 min critical)

### Exception & Error Handling
- **PostgreSQL exceptions**: Catch and wrap in standardized format
- **Deadlock handling**: 3 retries with exponential backoff (100ms/200ms/400ms)
- **Validation failure**: Block deployment, generate detailed diff report
- **Performance degradation**: Flag for optimization, allow with documented exception
- **Migration failure alerts**: Auto-alert DBA, escalate after 30 minutes

### Non-Functional Requirements
- **Performance baseline**: Warm cache, 3-run median, production-equivalent data
- **Concurrent load**: Production-equivalent user load
- **Materialized view refresh**: Under 10 minutes with REFRESH CONCURRENTLY
- **Failover time**: Under 60 seconds automatic failover
- **Disaster recovery**: RPO 5 minutes / RTO 1 hour
- **Encryption**: TLS 1.3 for transit, AES-256 for at rest
- **Maintenance window**: Monthly 4-hour window
- **Audit logging**: DDL and security events only
- **Auto-scaling**: Cloud-native infrastructure (AWS RDS/Aurora)

### Quality & Compliance
- **Quality scores**: Tiered by priority (P0=9.0, P1=8.0, P2/P3=7.0 minimum)
- **Constitution compliance**: Automated linting + manual spot-check
- **Constitution gate**: Production only (allow DEV/STAGING for iteration)
- **Schema qualification**: Automated pre-deployment scan
- **Test coverage**: 100% P0 objects, 90% P1, 80% P2/P3
- **Naming convention**: Full snake_case, mapping table for reference

### Edge Cases
- **Original 8 edge cases**: Marked as P0 with mandatory 100% test coverage
- **Added 3 new edge cases**: Empty tables, max-row tables, concurrent DDL
- **Circular dependencies**: Refactor to eliminate before migration
- **Encoding conversion**: UTF-8 with validation, flag unconvertible characters
- **Datetime handling**: Treat as UTC → TIMESTAMP WITH TIME ZONE
- **Constraint loading**: Load data first, enable constraints with violation report

### Traceability
- **User story alignment**: All acceptance scenarios map to functional requirements
- **AWS SCT validation**: Trust assumption, validate during object migration
- **Zero data loss**: Current methods sufficient (row count + hash + NULL counts)

**Full details**: See `spec.md` Clarifications section (60 Q&A entries)

---


