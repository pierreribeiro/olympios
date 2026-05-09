# Tasks: T-SQL to PostgreSQL Database Migration

**Input**: Design documents from `/specs/001-tsql-to-pgsql/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: Test tasks are included based on the testing requirements defined in the specification.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each database object type.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

This is a database migration project with the following structure:
- **Database objects**: `source/building/pgsql/refactored/`
- **Tests**: `tests/unit/`, `tests/integration/`, `tests/performance/`
- **Scripts**: `scripts/validation/`, `scripts/deployment/`, `scripts/automation/`
- **Tracking**: `tracking/`

---

## Clarifications Applied (2026-01-23)

**60 clarification questions answered** affecting task execution. Key decisions for implementers:

### Validation Tasks
- **Row validation**: Use row-by-row MD5/SHA256 hash comparison
- **Floating-point tolerance**: 1e-10 relative tolerance acceptable
- **NULL validation**: Compare column-level NULL counts
- **Performance baseline**: Warm cache, 3-run median, production-equivalent data

### Rollback & Recovery Tasks
- **Rollback window**: 7 days (not 30 days)
- **Rollback scope**: Object-level (revert failed object only, keep successful ones)
- **Cutover checkpoint**: Go/no-go decision at hour 6

### Quality Gate Tasks
- **Quality scores**: Tiered by priority (P0≥9.0, P1≥8.0, P2/P3≥7.0)
- **Test coverage**: 100% P0 objects, 90% P1, 80% P2/P3
- **Constitution gate**: Block PROD only (allow DEV/STAGING for iteration)

### Integration Tasks
- **FDW retry**: 3x exponential backoff (1s, 2s, 4s)
- **FDW pool**: Size 10, lifetime 30 min, idle timeout 5 min
- **FDW validation**: Pre-migration connectivity test in staging
- **Replication SLA**: p95 within 5 minutes
- **Replication alerts**: 2 min info, 5 min warning, 10 min critical

### Deployment Tasks
- **Phase gates**: Automated prerequisite checks, block on failure
- **Schema validation**: Automated pre-deployment scan for unqualified references
- **Constitution compliance**: Automated linting + manual spot-check

### Edge Case Tasks
- **Original 8 edge cases**: P0 priority, mandatory 100% test coverage
- **3 new edge cases**: Empty tables, max-row tables, concurrent DDL

**Full details**: See `spec.md` Clarifications section and `plan.md` Clarifications Applied section

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization, tooling, and basic migration framework

- [X] T001 Create complete project directory structure per plan.md
- [X] T002 [P] Initialize tracking inventory in tracking/database-objects-inventory.csv with all 769 objects
- [X] T003 [P] Create priority matrix in tracking/priority-matrix.csv mapping objects to P1/P2/P3
- [X] T004 [P] Initialize progress tracker in tracking/progress-tracker.md
- [X] T005 [P] Create risk register in tracking/risk-register.md
- [X] T006 Setup PostgreSQL 17 development environment (local or AWS RDS)
- [X] T007 [P] Configure AWS Schema Conversion Tool (SCT) for baseline conversion
- [X] T008 [P] Extract all SQL Server object definitions to source/original/sqlserver/
- [X] T009 Run AWS SCT baseline conversion to source/original/pgsql-aws-sct-converted/
- [X] T010 [P] Create analysis template in templates/analysis-template.md
- [X] T011 [P] Create object template in templates/object-template.sql
- [X] T012 [P] Create test templates in templates/test-templates/

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core validation scripts, deployment automation, and quality gate infrastructure that ALL user stories depend on

**⚠️ CRITICAL**: No user story migration work can begin until this phase is complete

- [X] T013 Create syntax validation script in scripts/validation/syntax-check.sh ✅ COMPLETE (9.0/10.0)
- [X] T014 [P] Create performance test framework in scripts/validation/performance-test-framework.sql ✅ COMPLETE (8.5/10.0)
- [X] T015 [P] Create data integrity check script in scripts/validation/data-integrity-check.sql ✅ COMPLETE (9.0/10.0)
- [X] T016 [P] Create dependency check script in scripts/validation/dependency-check.sql ✅ COMPLETE (8.0/10.0, all 6 sections working)
- [X] T017 [P] Create phase gate check script in scripts/validation/phase-gate-check.sql ✅ COMPLETE (8.5/10.0)
- [X] T018 Create deployment automation script in scripts/deployment/deploy-object.sh ✅ COMPLETE (8.7/10.0)
- [X] T019 [P] Create batch deployment script in scripts/deployment/deploy-batch.sh ✅ COMPLETE
- [X] T020 [P] Create rollback script in scripts/deployment/rollback-object.sh ✅ COMPLETE
- [X] T021 [P] Create smoke test script in scripts/deployment/smoke-test.sh ✅ COMPLETE
- [X] T022 Create object analysis automation in scripts/automation/analyze-object.py ✅ COMPLETE (9.2/10.0)
- [X] T023 [P] Create version comparison tool in scripts/automation/compare-versions.py ✅ COMPLETE (9.5/10.0)
- [X] T024 [P] Create test generator in scripts/automation/generate-tests.py ✅ COMPLETE (8.8/10.0)
- [X] T025 Setup test database schema in PostgreSQL development environment ✅ COMPLETE
- [X] T026 [P] Load representative test data fixtures in tests/fixtures/sample-data/ ✅ COMPLETE
- [X] T027 Configure connection pooling (PgBouncer) for development environment ✅ COMPLETE (9.7/10.0) 2026-01-25
- [X] T028 Create naming conversion mapping table (PascalCase → snake_case) ✅ COMPLETE (8.5/10.0) 2026-01-25
- [X] T029 Document quality score calculation methodology per contracts/validation-contracts.md ✅ COMPLETE (9.0/10.0) 2026-01-25
- [X] T030 Setup CI/CD pipeline for automated syntax and dependency validation ✅ COMPLETE (9.7/10.0) 2026-01-25

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Database Administrator Migrates Critical Views (Priority: P1) 🎯 MVP

**Goal**: Migrate all 22 views from SQL Server to PostgreSQL preserving query logic and result sets

**Independent Test**: Deploy migrated views to test environment, execute application queries against them, compare result sets with SQL Server outputs using scripts/validation/data-integrity-check.sql

---

### 🔧 **Execution Requirements** (MANDATORY - Read Before Starting)

⚠️ **CRITICAL**: See **`specs/001-tsql-to-pgsql/WORKFLOW-GUIDE.md`** for complete workflow instructions

#### **Worktree Setup**
```bash
# Create worktree from parent branch
git worktree add ~/.claude-worktrees/US1-critical-views -b us1-critical-views 001-tsql-to-pgsql
cd ~/.claude-worktrees/US1-critical-views
```

#### **Pre-Flight Checklist**
- [ ] **Worktree Created**: `~/.claude-worktrees/US1-critical-views`
- [ ] **Branch Name**: `us1-critical-views` (from `001-tsql-to-pgsql`)
- [ ] **Parent Branch Updated**: `git pull origin 001-tsql-to-pgsql` (no conflicts)

#### **Mandatory Agents** (Use Proactively - See CLAUDE.md)
- [X] **`database-expert`** ⭐⭐⭐⭐⭐ (PRIMARY) - Use for ALL analysis/validation tasks
- [X] **`sql-pro`** ⭐⭐⭐⭐⭐ (CO-PRIMARY) - Use for ALL refactoring tasks
- [X] **`database-optimization`** ⭐⭐⭐⭐ - Use for performance validation (T052, T118)
- [X] **`systematic-debugging`** ⭐⭐⭐⭐ - Use for ANY errors/test failures

#### **Ralph Loop Plugin** (MANDATORY for Batch Tasks)
**Activate for**:
- T034-T038: Batch analyze 22 views (5 parallel agents)
- T040-T045: Batch refactor 22 views (pattern-based conversion)
- T047-T050: Batch create unit tests for 22 views

**Example Usage**:
```bash
/ralph-loop "Analyze 22 views from User Story 1 (per dependency-analysis-lote3-views.md). Order: P3 (simple) → P2 → P1 → P0 (translated materialized view LAST). Iterate: Read AWS SCT → Apply constitution → Schema-qualify → Syntax validate. Checkpoint: After every 5 views, commit with quality scores. Gate: Before P0 view, validate ALL 21 dependencies resolved. Output <promise>ANALYSIS COMPLETE</promise> when all 22 views analyzed + quality scores ≥7.0/10.0 + no P0/P1 issues." --completion-promise "ANALYSIS COMPLETE" --max-iterations 10
```

#### **Parallelization Strategy**
**Tasks marked `[P]` can run concurrently**:
- T031, T032: Dependency analysis (2 parallel sessions)
- T034-T038: View analysis (5+ parallel agents via Ralph Loop)
- T042-T045: View refactoring (4+ parallel agents via Ralph Loop)
- T047-T050: Unit test creation (4+ parallel agents)

**Sequential dependencies**:
- T033 depends on T031-T032 (must run AFTER)
- T039 depends on T034-T038 (consolidation AFTER analysis)
- T046 depends on T040-T045 (validation AFTER refactoring)

#### **Quality Gates**
- **Minimum Score**: ≥7.0/10.0 for all objects (T054)
- **Performance**: Within ±20% of SQL Server baseline (T052)
- **Constitution**: Zero P0 violations, <3 P1 violations per object
- **Syntax**: 100% pass rate on `scripts/validation/syntax-check.sh`

---

### Dependency Analysis for User Story 1

- [x] T031 [P] [US1] Review dependency analysis for all 22 views in docs/code-analysis/dependency-analysis-lote3-views.md
- [x] T032 [P] [US1] Identify base tables required by views (ensure tables exist or will be created in parallel)
- [x] T033 [US1] Create dependency-ordered view migration sequence

### Phase 1: Analysis for User Story 1 Views

**Purpose**: Analyze AWS SCT output and document issues for all 22 views

- [x] T034 [P] [US1] Analyze `translated` indexed view → materialized view in source/building/pgsql/refactored/15.create-view/analysis/translated-analysis.md ✅ 2026-02-19
- [x] T035 [P] [US1] Analyze `upstream` recursive CTE view in source/building/pgsql/refactored/15.create-view/analysis/upstream-analysis.md ✅ 2026-02-19
- [x] T036 [P] [US1] Analyze `downstream` recursive CTE view in source/building/pgsql/refactored/15.create-view/analysis/downstream-analysis.md ✅ 2026-02-19
- [x] T037 [P] [US1] Analyze `goo_relationship` + `hermes_run` views in source/building/pgsql/refactored/15.create-view/analysis/ ✅ 2026-02-19
- [x] T038 [P] [US1] Analyze remaining 18 views in parallel (22 analysis.md files total) ✅ 2026-02-19
- [x] T039 [US1] Consolidate view analysis findings and quality scores in tracking/progress-tracker.md

### Phase 2: Refactoring for User Story 1 Views

**Purpose**: Refactor views to production-ready PostgreSQL code

- [X] T040 [US1] Refactor `translated` to materialized view in source/building/pgsql/refactored/views/translated.sql ✅ 2026-03-08
- [X] T041 [US1] Create UNIQUE index for CONCURRENT refresh in source/building/pgsql/refactored/views/translated.sql ✅ 2026-03-08
- [X] T042 [P] [US1] Refactor `upstream` recursive CTE in source/building/pgsql/refactored/views/upstream.sql ✅ 2026-03-08
- [X] T043 [P] [US1] Refactor `downstream` recursive CTE in source/building/pgsql/refactored/views/downstream.sql ✅ 2026-03-08
- [X] T044 [P] [US1] Refactor `goo_relationship` in source/building/pgsql/refactored/views/goo_relationship.sql ✅ 2026-03-08
- [X] T045 [P] [US1] Refactor remaining 18 views in parallel (one .sql file per view) ✅ 2026-03-08
- [X] T046 [US1] Validate all view definitions compile with scripts/validation/syntax-check.sh ✅ 2026-03-08

### Phase 3: Validation for User Story 1 Views

**Purpose**: Test views against validation contracts

- [X] T047 [P] [US1] Create unit tests for `translated` view in tests/unit/views/test_translated.sql
- [X] T048 [P] [US1] Create unit tests for `upstream` view in tests/unit/views/test_upstream.sql
- [X] T049 [P] [US1] Create unit tests for `downstream` view in tests/unit/views/test_downstream.sql
- [X] T050 [P] [US1] Create unit tests for remaining 19 views in tests/unit/views/
- [X] T051 [US1] Run result set comparison tests (SQL Server vs PostgreSQL) using scripts/validation/data-integrity-check.sql
- [X] T052 [US1] Run performance baseline tests for all views using scripts/validation/performance-test.sql
- [X] T053 [US1] Validate materialized view refresh performance for `translated`
- [X] T054 [US1] Verify all views meet ≥7.0/10 quality score threshold
- [X] T055 [US1] Document any performance optimizations needed in tracking/progress-tracker.md

### Phase 4: Deployment for User Story 1 Views

**Purpose**: Deploy views to DEV → STAGING → PRODUCTION

- [X] T056 [US1] Deploy all 22 views to DEV environment using scripts/deployment/deploy-batch.sh
- [X] T057 [US1] Run smoke tests in DEV using scripts/deployment/smoke-test.sh
- [X] T058 [US1] Deploy all 22 views to STAGING environment
- [X] T059 [US1] Execute integration tests in STAGING with application queries
- [X] T060 [US1] Create rollback procedures for all views in scripts/deployment/rollback-object.sh
- [X] T061 [US1] Document operational runbook for view maintenance
- [X] T062 [US1] Obtain deployment approval from technical lead and DBA

**Checkpoint**: At this point, all 22 views should be deployed to STAGING and independently testable

---

## Phase 4: User Story 2 - Database Administrator Migrates Table-Valued Functions (Priority: P1)

**Goal**: Migrate all 25 functions (15 table-valued, 10 scalar) from T-SQL to PL/pgSQL preserving input/output signatures and logic

**Independent Test**: Call each migrated function with known input parameters and compare output result sets with SQL Server using scripts/validation/data-integrity-check.sql

---

### 🔧 **Execution Requirements** (MANDATORY - Read Before Starting)

⚠️ **CRITICAL**: See **`specs/001-tsql-to-pgsql/WORKFLOW-GUIDE.md`** for complete workflow instructions

#### **Worktree Setup**
```bash
# Create worktree from parent branch
git worktree add ~/.claude-worktrees/US2-table-valued-functions -b us2-table-valued-functions 001-tsql-to-pgsql
cd ~/.claude-worktrees/US2-table-valued-functions
```

#### **Pre-Flight Checklist**
- [ ] **Worktree Created**: `~/.claude-worktrees/US2-table-valued-functions`
- [ ] **Branch Name**: `us2-table-valued-functions` (from `001-tsql-to-pgsql`)
- [ ] **Parent Branch Updated**: `git pull origin 001-tsql-to-pgsql` (no conflicts)
- [ ] **US1 Dependency**: Verify US1 views deployed (functions may depend on views)

#### **Mandatory Agents** (Use Proactively - See CLAUDE.md)
- [X] **`database-expert`** ⭐⭐⭐⭐⭐ (PRIMARY) - Use for ALL analysis/validation tasks
- [X] **`sql-pro`** ⭐⭐⭐⭐⭐ (CO-PRIMARY) - Use for ALL T-SQL → PL/pgSQL conversions
- [X] **`database-optimization`** ⭐⭐⭐⭐ - Use for performance validation (T089, T118)
- [X] **`systematic-debugging`** ⭐⭐⭐⭐ - Use for function signature/logic errors

#### **Ralph Loop Plugin** (MANDATORY for Batch Tasks)
**Activate for**:
- T066-T070: Batch analyze 25 functions (McGet* family + others)
- T072-T076: Batch refactor table-valued functions (15 functions)
- T077-T081: Batch refactor scalar functions (10 functions)
- T082-T086: Batch create unit tests for 25 functions

**Example Usage**:
```bash
/ralph-loop "Refactor 15 table-valued functions from T-SQL to PL/pgSQL (per dependency-analysis-lote2-functions.md). Priority: McGet* family first (mcgetupstream, mcgetdownstream, mcgetupstreambylist, mcgetdownstreambylist), then remaining 11 functions. Preserve: input/output signatures, RETURNS TABLE, logic equivalence. Apply: PostgreSQL constitution, schema-qualify all refs, explicit casting. Output <promise>TVF REFACTOR COMPLETE</promise> when all 15 functions refactored + syntax validated + quality scores ≥7.0/10.0." --completion-promise "TVF REFACTOR COMPLETE" --max-iterations 10
```

#### **Parallelization Strategy**
**Tasks marked `[P]` can run concurrently**:
- T063, T064: Dependency analysis (2 parallel sessions)
- T066-T070: Function analysis (5+ parallel agents via Ralph Loop)
- T072-T076, T077-T081: Refactoring (split by function type, parallel agents)
- T082-T086: Unit test creation (5+ parallel agents)

**Sequential dependencies**:
- T065 depends on T063-T064 (must run AFTER)
- T071 depends on T066-T070 (consolidation AFTER analysis)
- T091 depends on T082-T090 (validation AFTER tests)

#### **Quality Gates**
- **Minimum Score**: ≥7.0/10.0 for all functions (T091)
- **Performance**: Within ±20% of SQL Server baseline (T089)
- **Signature Preservation**: 100% match for input/output types
- **Constitution**: Zero P0 violations, <3 P1 violations per function
- **Syntax**: 100% pass rate on `scripts/validation/syntax-check.sh`

---

### Dependency Analysis for User Story 2

- [ ] T063 [P] [US2] Review dependency analysis for all 25 functions in docs/code-analysis/dependency-analysis-lote2-functions.md
- [ ] T064 [P] [US2] Identify view and table dependencies for each function
- [ ] T065 [US2] Create dependency-ordered function migration sequence (McGet* family first)

### Phase 1: Analysis for User Story 2 Functions

**Purpose**: Analyze AWS SCT output and document issues for all 25 functions

- [ ] T066 [P] [US2] Analyze `mcgetupstream` function in source/building/pgsql/refactored/functions/mcgetupstream-analysis.md
- [ ] T067 [P] [US2] Analyze `mcgetdownstream` function in source/building/pgsql/refactored/functions/mcgetdownstream-analysis.md
- [ ] T068 [P] [US2] Analyze `mcgetupstreambylist` (GooList TVP) in source/building/pgsql/refactored/functions/mcgetupstreambylist-analysis.md
- [ ] T069 [P] [US2] Analyze `mcgetdownstreambylist` (GooList TVP) in source/building/pgsql/refactored/functions/mcgetdownstreambylist-analysis.md
- [ ] T070 [P] [US2] Analyze remaining 21 functions in parallel (create analysis.md for each)
- [ ] T071 [US2] Consolidate function analysis findings and identify GooList conversion requirements

### Phase 2: Refactoring for User Story 2 Functions

**Purpose**: Refactor functions to production-ready PostgreSQL code

- [ ] T072 [US2] Implement GooList temporary table pattern per research.md decision
- [ ] T073 [US2] Refactor `mcgetupstream` to PL/pgSQL in source/building/pgsql/refactored/functions/mcgetupstream.sql
- [ ] T074 [US2] Refactor `mcgetdownstream` to PL/pgSQL in source/building/pgsql/refactored/functions/mcgetdownstream.sql
- [ ] T075 [US2] Refactor `mcgetupstreambylist` with temp table pattern in source/building/pgsql/refactored/functions/mcgetupstreambylist.sql
- [ ] T076 [US2] Refactor `mcgetdownstreambylist` with temp table pattern in source/building/pgsql/refactored/functions/mcgetdownstreambylist.sql
- [ ] T077 [P] [US2] Refactor remaining 21 functions in parallel (one .sql file per function)
- [ ] T078 [US2] Update function signatures to replace GooList type with temp table parameters
- [ ] T079 [US2] Validate all function definitions compile with scripts/validation/syntax-check.sh
- [ ] T080 [US2] Verify set-based execution (no cursors) per constitution principle III

### Phase 3: Validation for User Story 2 Functions

**Purpose**: Test functions against validation contracts

- [ ] T081 [P] [US2] Create unit tests for `mcgetupstream` in tests/unit/functions/test_mcgetupstream.sql
- [ ] T082 [P] [US2] Create unit tests for `mcgetdownstream` in tests/unit/functions/test_mcgetdownstream.sql
- [ ] T083 [P] [US2] Create unit tests for `mcgetupstreambylist` in tests/unit/functions/test_mcgetupstreambylist.sql
- [ ] T084 [P] [US2] Create unit tests for `mcgetdownstreambylist` in tests/unit/functions/test_mcgetdownstreambylist.sql
- [ ] T085 [P] [US2] Create unit tests for remaining 21 functions in tests/unit/functions/
- [ ] T086 [US2] Run result set comparison tests (SQL Server vs PostgreSQL) for all functions
- [ ] T087 [US2] Run performance baseline tests for all functions using scripts/validation/performance-test.sql
- [ ] T088 [US2] Verify GooList temporary table pattern performs acceptably (10k-20k batch sizes)
- [ ] T089 [US2] Verify all functions meet ≥7.0/10 quality score threshold
- [ ] T090 [US2] Test functions with edge cases (NULL inputs, empty lists, large batches)

### Phase 4: Deployment for User Story 2 Functions

**Purpose**: Deploy functions to DEV → STAGING → PRODUCTION

- [ ] T091 [US2] Deploy all 25 functions to DEV environment using scripts/deployment/deploy-batch.sh
- [ ] T092 [US2] Run smoke tests in DEV using scripts/deployment/smoke-test.sh
- [ ] T093 [US2] Deploy all 25 functions to STAGING environment
- [ ] T094 [US2] Execute integration tests in STAGING with calling procedures
- [ ] T095 [US2] Create rollback procedures for all functions in scripts/deployment/rollback-object.sh
- [ ] T096 [US2] Document GooList temporary table pattern usage for application teams
- [ ] T097 [US2] Obtain deployment approval from technical lead and DBA

**Checkpoint**: At this point, all 25 functions should be deployed to STAGING and independently testable

---

## Phase 5: User Story 3 - Database Administrator Migrates Table Structures (Priority: P1)

**Goal**: Migrate all 91 table schemas, 352 indexes, and 271 constraints from SQL Server to PostgreSQL preserving data structures and referential integrity

**Independent Test**: Create tables in PostgreSQL, validate all constraints, test index performance, verify data type compatibility using scripts/validation/data-integrity-check.sql and scripts/validation/dependency-check.sql

---

### 🔧 **Execution Requirements** (MANDATORY - Read Before Starting)

⚠️ **CRITICAL**: See **`specs/001-tsql-to-pgsql/WORKFLOW-GUIDE.md`** for complete workflow instructions

#### **Worktree Setup**
```bash
# Create worktree from parent branch
git worktree add ~/.claude-worktrees/US3-table-structures -b us3-table-structures 001-tsql-to-pgsql
cd ~/.claude-worktrees/US3-table-structures
```

#### **Pre-Flight Checklist**
- [ ] **Worktree Created**: `~/.claude-worktrees/US3-table-structures`
- [ ] **Branch Name**: `us3-table-structures` (from `001-tsql-to-pgsql`)
- [ ] **Parent Branch Updated**: `git pull origin 001-tsql-to-pgsql` (no conflicts)
- [ ] **US1/US2 Dependencies**: Verify views/functions deployed (tables may be referenced)

#### **Mandatory Agents** (Use Proactively - See CLAUDE.md)
- [X] **`database-expert`** ⭐⭐⭐⭐⭐ (PRIMARY) - Use for ALL schema/constraint analysis
- [X] **`sql-pro`** ⭐⭐⭐⭐⭐ (CO-PRIMARY) - Use for complex constraints/triggers
- [X] **`database-optimization`** ⭐⭐⭐⭐ - Use for index strategy (352 indexes!)
- [X] **`systematic-debugging`** ⭐⭐⭐⭐ - Use for FK/constraint errors

#### **Ralph Loop Plugin** (MANDATORY for Batch Tasks)
**Activate for**:
- T101-T105: Batch analyze 91 tables (schema + data types)
- T106-T111: Batch analyze 352 indexes (performance impact)
- T112-T116: Batch analyze 271 constraints (FK cascades)
- T117-T121: Batch refactor tables (dependency-ordered)
- T137-T141: Batch create DDL tests for 91 tables

**Example Usage**:
```bash
/ralph-loop "Refactor 91 table schemas from SQL Server to PostgreSQL (dependency-ordered per dependency graph). Priority: Base tables FIRST (no FKs), then dependent tables. Convert: IDENTITY → GENERATED ALWAYS AS IDENTITY, data types per constitution, schema-qualify all references. Preserve: FK relationships, check constraints, unique constraints. Output <promise>TABLES REFACTORED</promise> when all 91 tables created + dependency validation passed + quality scores ≥7.0/10.0." --completion-promise "TABLES REFACTORED" --max-iterations 10
```

#### **Parallelization Strategy**
**Tasks marked `[P]` can run concurrently**:
- T098, T099: Dependency analysis (2 parallel sessions)
- T101-T105: Table schema analysis (5+ parallel agents via Ralph Loop)
- T106-T111: Index analysis (6+ parallel agents, split by table groups)
- T112-T116: Constraint analysis (5+ parallel agents)
- T117-T121: Table refactoring (dependency-ordered batches, parallel within batch)

**Sequential dependencies**:
- T100 depends on T098-T099 (dependency graph MUST be created first)
- T117-T121 depend on T100 (refactoring follows dependency order)
- T122 depends on T117-T121 (FK validation AFTER all tables exist)
- T136 depends on T122-T135 (syntax validation AFTER refactoring)

#### **Quality Gates**
- **Minimum Score**: ≥7.0/10.0 for all objects (T155)
- **Performance**: Indexes within ±20% of SQL Server baseline (T147)
- **Referential Integrity**: 100% FK constraint validation (T122)
- **Data Type Mapping**: Zero lossy conversions (T101-T105)
- **Constitution**: Zero P0 violations, <3 P1 violations per object
- **Syntax**: 100% pass rate on `scripts/validation/syntax-check.sh`

---

### Dependency Analysis for User Story 3

- [ ] T098 [P] [US3] Review table dependencies in docs/code-analysis/dependency-analysis-consolidated.md
- [ ] T099 [P] [US3] Identify foreign key relationships and create dependency graph
- [ ] T100 [US3] Create dependency-ordered table creation sequence (base tables first, then dependent tables)

### Phase 1: Analysis for User Story 3 Tables

**Purpose**: Analyze AWS SCT output for table schemas, indexes, and constraints

- [ ] T101 [P] [US3] Analyze core tables (`goo`, `material_transition`, `transition_material`) in source/building/pgsql/refactored/tables/core-tables-analysis.md
- [ ] T102 [P] [US3] Analyze relationship tables (`m_upstream`, `m_downstream`) in source/building/pgsql/refactored/tables/relationship-tables-analysis.md
- [ ] T103 [P] [US3] Analyze container and tracking tables in source/building/pgsql/refactored/tables/container-tables-analysis.md
- [ ] T104 [P] [US3] Analyze remaining tables (batch analysis by functional area)
- [ ] T105 [US3] Document data type conversions (NVARCHAR→VARCHAR, MONEY→NUMERIC, UNIQUEIDENTIFIER→UUID, DATETIME→TIMESTAMP)
- [ ] T106 [US3] Identify IDENTITY column conversions to GENERATED ALWAYS AS IDENTITY
- [ ] T107 [US3] Consolidate table analysis findings and quality scores

### Phase 2: Refactoring for User Story 3 Tables

**Purpose**: Refactor table DDL to production-ready PostgreSQL code

- [ ] T108 [P] [US3] Refactor core table schemas in source/building/pgsql/refactored/tables/goo.sql
- [ ] T109 [P] [US3] Refactor `material_transition` table in source/building/pgsql/refactored/tables/material_transition.sql
- [ ] T110 [P] [US3] Refactor `transition_material` table in source/building/pgsql/refactored/tables/transition_material.sql
- [ ] T111 [P] [US3] Refactor remaining 88 tables in parallel (one .sql file per table)
- [ ] T112 [US3] Apply explicit data type conversions with CAST/:: per constitution principle II
- [ ] T113 [US3] Convert IDENTITY columns to GENERATED ALWAYS AS IDENTITY
- [ ] T114 [US3] Validate all table DDL compiles with scripts/validation/syntax-check.sh

### Phase 3: Indexes for User Story 3

**Purpose**: Create all 352 indexes in PostgreSQL

- [ ] T115 [P] [US3] Create primary key indexes in source/building/pgsql/refactored/indexes/pk-indexes.sql
- [ ] T116 [P] [US3] Create foreign key indexes in source/building/pgsql/refactored/indexes/fk-indexes.sql
- [ ] T117 [P] [US3] Create query optimization indexes in source/building/pgsql/refactored/indexes/query-indexes.sql
- [ ] T118 [US3] Validate index definitions compile with scripts/validation/syntax-check.sh
- [ ] T119 [US3] Create index naming convention mapping (IX_* → ix_*)

### Phase 4: Constraints for User Story 3

**Purpose**: Create all 271 constraints in PostgreSQL

- [ ] T120 [P] [US3] Create primary key constraints in source/building/pgsql/refactored/constraints/pk-constraints.sql
- [ ] T121 [P] [US3] Create foreign key constraints in source/building/pgsql/refactored/constraints/fk-constraints.sql
- [ ] T122 [P] [US3] Create unique constraints in source/building/pgsql/refactored/constraints/unique-constraints.sql
- [ ] T123 [P] [US3] Create check constraints in source/building/pgsql/refactored/constraints/check-constraints.sql
- [ ] T124 [US3] Validate all constraints compile with scripts/validation/syntax-check.sh
- [ ] T125 [US3] Test constraint enforcement with violation test cases

### Phase 5: Data Migration for User Story 3

**Purpose**: Migrate all data from SQL Server to PostgreSQL

- [ ] T126 [US3] Extract production data from SQL Server (91 tables)
- [ ] T127 [US3] Create data migration scripts in scripts/deployment/migrate-data.sh
- [ ] T128 [US3] Load data into PostgreSQL tables in dependency order
- [ ] T129 [US3] Run row count validation for all 91 tables using scripts/validation/data-integrity-check.sql
- [ ] T130 [US3] Run checksum validation for all 91 tables
- [ ] T131 [US3] Verify zero data loss (100% integrity validation)

### Phase 6: Validation for User Story 3

**Purpose**: Test tables, indexes, and constraints against validation contracts

- [ ] T132 [P] [US3] Create unit tests for core tables in tests/unit/tables/test_goo.sql
- [ ] T133 [P] [US3] Create constraint violation tests in tests/unit/tables/test_constraints.sql
- [ ] T134 [P] [US3] Create index usage tests in tests/unit/tables/test_indexes.sql
- [ ] T135 [US3] Run performance baseline tests for indexed queries using scripts/validation/performance-test.sql
- [ ] T136 [US3] Verify EXPLAIN ANALYZE shows index usage for critical queries
- [ ] T137 [US3] Verify all tables meet ≥7.0/10 quality score threshold
- [ ] T138 [US3] Test referential integrity across all 271 constraints

### Phase 7: Deployment for User Story 3

**Purpose**: Deploy tables to DEV → STAGING → PRODUCTION

- [ ] T139 [US3] Deploy all table schemas to DEV environment using scripts/deployment/deploy-batch.sh
- [ ] T140 [US3] Deploy all indexes to DEV environment
- [ ] T141 [US3] Deploy all constraints to DEV environment
- [ ] T142 [US3] Load test data into DEV environment
- [ ] T143 [US3] Run smoke tests in DEV using scripts/deployment/smoke-test.sh
- [ ] T144 [US3] Deploy tables/indexes/constraints to STAGING environment
- [ ] T145 [US3] Load representative production data into STAGING
- [ ] T146 [US3] Execute integration tests in STAGING
- [ ] T147 [US3] Create rollback procedures for all tables in scripts/deployment/rollback-object.sh
- [ ] T148 [US3] Document data migration runbook with cutover procedures
- [ ] T149 [US3] Obtain deployment approval from technical lead and DBA

**Checkpoint**: At this point, all 91 tables with 352 indexes and 271 constraints should be deployed to STAGING and independently testable

---

## Phase 6: User Story 4 - Database Administrator Configures External Data Integrations (Priority: P2)

**Goal**: Configure Foreign Data Wrappers (FDW) to replace SQL Server linked servers for external database access (hermes, sqlapps, deimeter)

**Independent Test**: Configure FDW connections, execute queries joining local and foreign tables, validate result sets match current linked server queries using scripts/validation/data-integrity-check.sql

---

### 🔧 **Execution Requirements** (MANDATORY - Read Before Starting)

⚠️ **CRITICAL**: See **`specs/001-tsql-to-pgsql/WORKFLOW-GUIDE.md`** for complete workflow instructions

#### **Worktree Setup**
```bash
# Create worktree from parent branch
git worktree add ~/.claude-worktrees/US4-fdw-integrations -b us4-fdw-integrations 001-tsql-to-pgsql
cd ~/.claude-worktrees/US4-fdw-integrations
```

#### **Pre-Flight Checklist**
- [ ] **Worktree Created**: `~/.claude-worktrees/US4-fdw-integrations`
- [ ] **Branch Name**: `us4-fdw-integrations` (from `001-tsql-to-pgsql`)
- [ ] **Parent Branch Updated**: `git pull origin 001-tsql-to-pgsql` (no conflicts)
- [ ] **US1/US2/US3 Dependencies**: Verify views/functions/tables deployed (FDW queries may reference them)
- [ ] **Network Access**: Verify connectivity to hermes, sqlapps, deimeter databases

#### **Mandatory Agents** (Use Proactively - See CLAUDE.md)
- [X] **`database-expert`** ⭐⭐⭐⭐⭐ (PRIMARY) - Use for ALL FDW configuration/analysis
- [X] **`sql-pro`** ⭐⭐⭐⭐⭐ (CO-PRIMARY) - Use for FDW query optimization
- [X] **`database-optimization`** ⭐⭐⭐⭐ - Use for FDW performance tuning (latency <2×)
- [X] **`systematic-debugging`** ⭐⭐⭐⭐ - Use for connection/auth errors

#### **Ralph Loop Plugin** (MANDATORY for Batch Tasks)
**Activate for**:
- T153-T155: Batch analyze 3 FDW connections (hermes, sqlapps, deimeter)
- T158-T162: Batch configure 17 foreign tables (6+9+2)
- T168-T172: Batch create FDW tests for 17 foreign tables

**Example Usage**:
```bash
/ralph-loop "Configure 3 postgres_fdw connections (hermes, sqlapps, deimeter) with 17 foreign tables total. For each: create SERVER, USER MAPPING, import FOREIGN SCHEMA, test connectivity, optimize fetch_size (start 1000). Apply: retry logic (3× exponential backoff), connection pooling (size 10, lifetime 30min), error handling. Output <promise>FDW CONFIGURED</promise> when all 3 connections active + 17 foreign tables accessible + latency <2× linked server baseline." --completion-promise "FDW CONFIGURED" --max-iterations 10
```

#### **Parallelization Strategy**
**Tasks marked `[P]` can run concurrently**:
- T150, T151: FDW requirements analysis (2 parallel sessions)
- T153-T155: FDW connection analysis (3 parallel agents, 1 per database)
- T158-T162: Foreign table configuration (3 parallel agents, 1 per server)
- T168-T172: FDW test creation (3 parallel agents, 1 per connection)

**Sequential dependencies**:
- T152 depends on T150-T151 (dependency mapping AFTER requirements)
- T157 depends on T153-T156 (performance expectations AFTER analysis)
- T163 depends on T158-T162 (retry wrapper AFTER all tables configured)
- T167 depends on T158-T166 (syntax validation AFTER configuration)

#### **Quality Gates**
- **Minimum Score**: ≥7.0/10.0 for all FDW configurations (T180)
- **Performance**: FDW latency <2× SQL Server linked server baseline (T157, T176)
- **Reliability**: 3× retry with exponential backoff (1s, 2s, 4s) - T163
- **Connection Pooling**: Size 10, lifetime 30min, idle timeout 5min - T164
- **Security**: No hardcoded credentials, use postgres USER MAPPING
- **Syntax**: 100% pass rate on `scripts/validation/syntax-check.sh`

---

### Dependency Analysis for User Story 4

- [ ] T150 [P] [US4] Review FDW requirements in docs/PROJECT-SPECIFICATION.md
- [ ] T151 [P] [US4] Document external database connection details (hermes - 6 tables, sqlapps.common - 9 tables, deimeter - 2 tables)
- [ ] T152 [US4] Identify views and functions that depend on FDW tables

### Phase 1: Analysis for User Story 4 FDW

**Purpose**: Analyze FDW configuration requirements

- [ ] T153 [P] [US4] Analyze hermes FDW requirements in source/building/pgsql/refactored/fdw/hermes-analysis.md
- [ ] T154 [P] [US4] Analyze sqlapps FDW requirements in source/building/pgsql/refactored/fdw/sqlapps-analysis.md
- [ ] T155 [P] [US4] Analyze deimeter FDW requirements in source/building/pgsql/refactored/fdw/deimeter-analysis.md
- [ ] T156 [US4] Document network connectivity and authentication requirements
- [ ] T157 [US4] Document performance expectations (FDW latency <2x linked server latency)

### Phase 2: Refactoring for User Story 4 FDW

**Purpose**: Configure FDW connections and foreign tables

- [ ] T158 [US4] Install postgres_fdw extension in PostgreSQL
- [ ] T159 [US4] Configure PgBouncer connection pooling per research.md
- [ ] T160 [US4] Create hermes foreign server in source/building/pgsql/refactored/fdw/hermes-server.sql
- [ ] T161 [US4] Create sqlapps foreign server in source/building/pgsql/refactored/fdw/sqlapps-server.sql
- [ ] T162 [US4] Create deimeter foreign server in source/building/pgsql/refactored/fdw/deimeter-server.sql
- [ ] T163 [P] [US4] Create 6 foreign tables for hermes in source/building/pgsql/refactored/fdw/hermes-tables.sql
- [ ] T164 [P] [US4] Create 9 foreign tables for sqlapps in source/building/pgsql/refactored/fdw/sqlapps-tables.sql
- [ ] T165 [P] [US4] Create 2 foreign tables for deimeter in source/building/pgsql/refactored/fdw/deimeter-tables.sql
- [ ] T166 [US4] Configure fetch_size and use_remote_estimate options per research.md
- [ ] T167 [US4] Implement read-only access pattern (no distributed transactions)
- [ ] T168 [US4] Validate all FDW definitions compile with scripts/validation/syntax-check.sh

### Phase 3: Validation for User Story 4 FDW

**Purpose**: Test FDW connections and query performance

- [ ] T169 [P] [US4] Create integration tests for hermes FDW in tests/integration/fdw-tests/test_hermes_fdw.sql
- [ ] T170 [P] [US4] Create integration tests for sqlapps FDW in tests/integration/fdw-tests/test_sqlapps_fdw.sql
- [ ] T171 [P] [US4] Create integration tests for deimeter FDW in tests/integration/fdw-tests/test_deimeter_fdw.sql
- [ ] T172 [US4] Test cross-database queries joining local and foreign tables
- [ ] T173 [US4] Verify predicate pushdown with EXPLAIN ANALYZE
- [ ] T174 [US4] Run performance baseline tests for FDW queries using scripts/validation/performance-test.sql
- [ ] T175 [US4] Verify FDW latency <2x linked server baseline
- [ ] T176 [US4] Test FDW connection retry logic and error handling (sqlstate 08000)
- [ ] T177 [US4] Verify all FDW configurations meet ≥7.0/10 quality score threshold

### Phase 4: Deployment for User Story 4 FDW

**Purpose**: Deploy FDW to DEV → STAGING → PRODUCTION

- [ ] T178 [US4] Deploy FDW configurations to DEV environment using scripts/deployment/deploy-object.sh
- [ ] T179 [US4] Test FDW connectivity in DEV environment
- [ ] T180 [US4] Run smoke tests in DEV using scripts/deployment/smoke-test.sh
- [ ] T181 [US4] Deploy FDW configurations to STAGING environment
- [ ] T182 [US4] Execute integration tests in STAGING with production-like queries
- [ ] T183 [US4] Monitor FDW connection stability over 24-hour period
- [ ] T184 [US4] Create rollback procedures for FDW in scripts/deployment/rollback-object.sh
- [ ] T185 [US4] Document FDW operational runbook (connection management, troubleshooting)
- [ ] T186 [US4] Obtain deployment approval from technical lead and DBA

**Checkpoint**: At this point, all FDW connections should be deployed to STAGING and independently testable

---

## Phase 7: User Story 5 - Database Administrator Establishes Data Replication (Priority: P2)

**Goal**: Configure SymmetricDS replication from PostgreSQL to sqlwarehouse2 for downstream data warehouse systems

**Independent Test**: Configure SymmetricDS, insert/update/delete data in source tables, verify changes replicate to sqlwarehouse2 within acceptable latency (<5 minutes p95)

---

### 🔧 **Execution Requirements** (MANDATORY - Read Before Starting)

⚠️ **CRITICAL**: See **`specs/001-tsql-to-pgsql/WORKFLOW-GUIDE.md`** for complete workflow instructions

#### **Worktree Setup**
```bash
# Create worktree from parent branch
git worktree add ~/.claude-worktrees/US5-data-replication -b us5-data-replication 001-tsql-to-pgsql
cd ~/.claude-worktrees/US5-data-replication
```

#### **Pre-Flight Checklist**
- [ ] **Worktree Created**: `~/.claude-worktrees/US5-data-replication`
- [ ] **Branch Name**: `us5-data-replication` (from `001-tsql-to-pgsql`)
- [ ] **Parent Branch Updated**: `git pull origin 001-tsql-to-pgsql` (no conflicts)
- [ ] **US3 Dependency**: Verify tables deployed (replication requires source tables)
- [ ] **Network Access**: Verify connectivity to sqlwarehouse2
- [ ] **SymmetricDS**: Verify SymmetricDS installation/access

#### **Mandatory Agents** (Use Proactively - See CLAUDE.md)
- [X] **`database-expert`** ⭐⭐⭐⭐⭐ (PRIMARY) - Use for ALL replication config/analysis
- [X] **`database-admin`** ⭐⭐⭐ - Use for SymmetricDS setup/monitoring
- [X] **`database-optimization`** ⭐⭐⭐⭐ - Use for replication performance tuning
- [X] **`systematic-debugging`** ⭐⭐⭐⭐ - Use for replication lag/failure debugging

#### **Ralph Loop Plugin** (MANDATORY for Batch Tasks)
**Activate for**:
- T190-T194: Batch analyze replication requirements for multiple tables
- T195-T199: Batch configure SymmetricDS channels/triggers
- T205-T209: Batch create replication tests for all channels

**Example Usage**:
```bash
/ralph-loop "Configure SymmetricDS replication channels for PostgreSQL → sqlwarehouse2. Setup: node groups (perseus_source, warehouse_target), routers (default), triggers (INSERT/UPDATE/DELETE on replicated tables), channels (batch_size 1000, period 60s). Monitor: replication lag <5min p95, alerts at 2min (info), 5min (warning), 10min (critical). Output <promise>REPLICATION CONFIGURED</promise> when all channels active + initial sync complete + lag monitoring operational." --completion-promise "REPLICATION CONFIGURED" --max-iterations 10
```

#### **Parallelization Strategy**
**Tasks marked `[P]` can run concurrently**:
- T187, T188: Replication requirements analysis (2 parallel sessions)
- T190-T194: Table replication analysis (5+ parallel agents)
- T195-T199: SymmetricDS channel config (batches, parallel within batch)
- T205-T209: Replication test creation (5+ parallel agents)

**Sequential dependencies**:
- T189 depends on T187-T188 (topology AFTER requirements)
- T200 depends on T195-T199 (initial sync AFTER channel config)
- T204 depends on T200-T203 (validation AFTER initial sync)
- T210 depends on T205-T209 (lag testing AFTER all tests created)

#### **Quality Gates**
- **Minimum Score**: ≥7.0/10.0 for all replication configurations (T218)
- **Performance**: p95 latency <5 minutes (T210)
- **Reliability**: Alerting at 2min (info), 5min (warning), 10min (critical) - T202
- **Data Integrity**: 100% row count match after initial sync (T200)
- **Monitoring**: Real-time lag tracking + automated alerts - T201-T203
- **Recovery**: Documented failover/resync procedures - T216

---

### Dependency Analysis for User Story 5

- [ ] T187 [P] [US5] Review replication requirements in docs/PROJECT-SPECIFICATION.md
- [ ] T188 [P] [US5] Identify tables requiring replication to sqlwarehouse2
- [ ] T189 [US5] Document replication topology and data flow

### Phase 1: Analysis for User Story 5 Replication

**Purpose**: Analyze SymmetricDS configuration requirements

- [ ] T190 [US5] Analyze SymmetricDS architecture and licensing in source/building/pgsql/refactored/replication/symmetricds-analysis.md
- [ ] T191 [US5] Document replication performance requirements (lag <5 minutes p95)
- [ ] T192 [US5] Identify triggers and routing configuration needed

### Phase 2: Refactoring for User Story 5 Replication

**Purpose**: Configure SymmetricDS for PostgreSQL → sqlwarehouse2 replication

- [ ] T193 [US5] Install and configure SymmetricDS on PostgreSQL node
- [ ] T194 [US5] Create replication node configuration in source/building/pgsql/refactored/replication/node-config.properties
- [ ] T195 [US5] Register tables for replication in source/building/pgsql/refactored/replication/table-registration.sql
- [ ] T196 [US5] Create triggers for replicated tables in source/building/pgsql/refactored/replication/triggers.sql
- [ ] T197 [US5] Configure routing and conflict resolution in source/building/pgsql/refactored/replication/routing-config.sql
- [ ] T198 [US5] Setup replication monitoring and alerting
- [ ] T199 [US5] Validate all replication configurations compile and load successfully

### Phase 3: Validation for User Story 5 Replication

**Purpose**: Test replication integrity and performance

- [ ] T200 [P] [US5] Create integration tests for INSERT replication in tests/integration/replication-tests/test_insert_replication.sql
- [ ] T201 [P] [US5] Create integration tests for UPDATE replication in tests/integration/replication-tests/test_update_replication.sql
- [ ] T202 [P] [US5] Create integration tests for DELETE replication in tests/integration/replication-tests/test_delete_replication.sql
- [ ] T203 [US5] Test replication lag under normal load (verify <5 minutes p95)
- [ ] T204 [US5] Test replication lag under peak load (stress test)
- [ ] T205 [US5] Test replication recovery after network failure
- [ ] T206 [US5] Verify zero data loss during replication failures
- [ ] T207 [US5] Setup alerting for replication lag exceeding thresholds
- [ ] T208 [US5] Verify all replication configurations meet ≥7.0/10 quality score threshold

### Phase 4: Deployment for User Story 5 Replication

**Purpose**: Deploy replication to DEV → STAGING → PRODUCTION

- [ ] T209 [US5] Deploy SymmetricDS to DEV environment using scripts/deployment/deploy-object.sh
- [ ] T210 [US5] Test replication in DEV with sample data changes
- [ ] T211 [US5] Run smoke tests in DEV using scripts/deployment/smoke-test.sh
- [ ] T212 [US5] Deploy SymmetricDS to STAGING environment
- [ ] T213 [US5] Execute integration tests in STAGING with production-like load
- [ ] T214 [US5] Monitor replication stability over 48-hour period
- [ ] T215 [US5] Create rollback procedures for replication in scripts/deployment/rollback-object.sh
- [ ] T216 [US5] Document SymmetricDS operational runbook (monitoring, troubleshooting, recovery)
- [ ] T217 [US5] Obtain deployment approval from technical lead and DBA

**Checkpoint**: At this point, SymmetricDS replication should be deployed to STAGING and independently testable

---

## Phase 8: User Story 6 - Database Administrator Migrates SQL Agent Jobs (Priority: P3)

**Goal**: Migrate 7 SQL Server Agent jobs to PostgreSQL scheduling mechanisms (pgAgent or cron) preserving execution schedules and error handling

**Independent Test**: Configure equivalent jobs in PostgreSQL, execute manually first, then validate scheduled execution produces expected results (logs created, reconciliation completes)

---

### 🔧 **Execution Requirements** (MANDATORY - Read Before Starting)

⚠️ **CRITICAL**: See **`specs/001-tsql-to-pgsql/WORKFLOW-GUIDE.md`** for complete workflow instructions

#### **Worktree Setup**
```bash
# Create worktree from parent branch
git worktree add ~/.claude-worktrees/US6-sql-agent-jobs -b us6-sql-agent-jobs 001-tsql-to-pgsql
cd ~/.claude-worktrees/US6-sql-agent-jobs
```

#### **Pre-Flight Checklist**
- [ ] **Worktree Created**: `~/.claude-worktrees/US6-sql-agent-jobs`
- [ ] **Branch Name**: `us6-sql-agent-jobs` (from `001-tsql-to-pgsql`)
- [ ] **Parent Branch Updated**: `git pull origin 001-tsql-to-pgsql` (no conflicts)
- [ ] **US1/US2/US3 Dependencies**: Verify objects deployed (jobs call procedures/functions)
- [ ] **Scheduling Tool**: Decide between pgAgent vs pg_cron (T220)

#### **Mandatory Agents** (Use Proactively - See CLAUDE.md)
- [X] **`database-expert`** ⭐⭐⭐⭐⭐ (PRIMARY) - Use for ALL job migration/analysis
- [X] **`database-admin`** ⭐⭐⭐ - Use for pgAgent/pg_cron setup
- [X] **`shell-scripting-pro`** ⭐⭐⭐⭐ - Use for cron scripts (if pg_cron chosen)
- [X] **`systematic-debugging`** ⭐⭐⭐⭐ - Use for job failure debugging

#### **Ralph Loop Plugin** (MANDATORY for Batch Tasks)
**Activate for**:
- T221-T225: Batch analyze 7 SQL Agent jobs (schedules, steps, dependencies)
- T226-T230: Batch migrate 7 jobs to pgAgent/pg_cron
- T236-T240: Batch create job tests for all 7 jobs

**Example Usage**:
```bash
/ralph-loop "Migrate 7 SQL Server Agent jobs to pg_cron. For each job: extract schedule (cron format), convert T-SQL steps to PL/pgSQL CALL statements, add error handling (EXCEPTION blocks + logging), configure retry logic (3× on failure). Jobs: reconciliation (daily 2am), cleanup (weekly), monitoring (hourly). Output <promise>JOBS MIGRATED</promise> when all 7 jobs scheduled + manual execution successful + logs verified." --completion-promise "JOBS MIGRATED" --max-iterations 10
```

#### **Parallelization Strategy**
**Tasks marked `[P]` can run concurrently**:
- T218, T219: Job requirements analysis (2 parallel sessions)
- T221-T225: Job analysis (5+ parallel agents, 1-2 jobs each)
- T226-T230: Job migration (batches, parallel within batch if independent)
- T236-T240: Job test creation (5+ parallel agents)

**Sequential dependencies**:
- T220 depends on T218-T219 (tool selection AFTER requirements)
- T231 depends on T220, T226-T230 (scheduling AFTER jobs migrated)
- T235 depends on T226-T234 (syntax validation AFTER migration)
- T241 depends on T236-T240 (integration testing AFTER all tests created)

#### **Quality Gates**
- **Minimum Score**: ≥7.0/10.0 for all job migrations (T247)
- **Schedule Accuracy**: 100% match with SQL Server schedules (cron equivalent)
- **Error Handling**: Comprehensive logging + retry logic (3× with backoff)
- **Monitoring**: Job execution logs + failure alerts - T233-T234
- **Recovery**: Documented manual override/restart procedures - T245
- **Syntax**: 100% pass rate on manual execution tests (T241)

---

### Dependency Analysis for User Story 6

- [ ] T218 [P] [US6] Review job requirements in docs/PROJECT-SPECIFICATION.md
- [ ] T219 [P] [US6] Document all 7 SQL Server Agent jobs (schedules, steps, error handling)
- [ ] T220 [US6] Select scheduling mechanism (pgAgent vs pg_cron)

### Phase 1: Analysis for User Story 6 Jobs

**Purpose**: Analyze SQL Server Agent job configurations

- [ ] T221 [P] [US6] Analyze job 1 in source/building/pgsql/refactored/jobs/job1-analysis.md
- [ ] T222 [P] [US6] Analyze job 2 in source/building/pgsql/refactored/jobs/job2-analysis.md
- [ ] T223 [P] [US6] Analyze job 3 in source/building/pgsql/refactored/jobs/job3-analysis.md
- [ ] T224 [P] [US6] Analyze remaining 4 jobs in parallel
- [ ] T225 [US6] Document job dependencies and execution sequences
- [ ] T226 [US6] Document notification and retry requirements

### Phase 2: Refactoring for User Story 6 Jobs

**Purpose**: Convert jobs to PostgreSQL scheduling mechanism

- [ ] T227 [US6] Install pgAgent extension in PostgreSQL
- [ ] T228 [P] [US6] Create job 1 in source/building/pgsql/refactored/jobs/job1.sql
- [ ] T229 [P] [US6] Create job 2 in source/building/pgsql/refactored/jobs/job2.sql
- [ ] T230 [P] [US6] Create job 3 in source/building/pgsql/refactored/jobs/job3.sql
- [ ] T231 [P] [US6] Create remaining 4 jobs in parallel (one .sql file per job)
- [ ] T232 [US6] Configure job schedules matching SQL Server Agent schedules
- [ ] T233 [US6] Implement error handling and notification equivalent to SQL Server
- [ ] T234 [US6] Configure job logging for troubleshooting and audit
- [ ] T235 [US6] Validate all job definitions compile with scripts/validation/syntax-check.sh

### Phase 3: Validation for User Story 6 Jobs

**Purpose**: Test job execution and error handling

- [ ] T236 [P] [US6] Create integration tests for job 1 execution in tests/integration/job-tests/test_job1.sql
- [ ] T237 [P] [US6] Create integration tests for job 2 execution in tests/integration/job-tests/test_job2.sql
- [ ] T238 [P] [US6] Create integration tests for job 3 execution in tests/integration/job-tests/test_job3.sql
- [ ] T239 [P] [US6] Create integration tests for remaining 4 jobs
- [ ] T240 [US6] Test manual job execution for all 7 jobs
- [ ] T241 [US6] Test scheduled job execution over 24-hour period
- [ ] T242 [US6] Test job failure scenarios and retry logic
- [ ] T243 [US6] Test job dependency sequencing (if applicable)
- [ ] T244 [US6] Verify job logging captures execution history
- [ ] T245 [US6] Verify all job configurations meet ≥7.0/10 quality score threshold

### Phase 4: Deployment for User Story 6 Jobs

**Purpose**: Deploy jobs to DEV → STAGING → PRODUCTION

- [ ] T246 [US6] Deploy all 7 jobs to DEV environment using scripts/deployment/deploy-object.sh
- [ ] T247 [US6] Test jobs in DEV with manual execution
- [ ] T248 [US6] Run smoke tests in DEV using scripts/deployment/smoke-test.sh
- [ ] T249 [US6] Deploy all 7 jobs to STAGING environment
- [ ] T250 [US6] Execute integration tests in STAGING with scheduled execution
- [ ] T251 [US6] Monitor job execution stability over 48-hour period
- [ ] T252 [US6] Create rollback procedures for jobs in scripts/deployment/rollback-object.sh
- [ ] T253 [US6] Document pgAgent operational runbook (monitoring, troubleshooting)
- [ ] T254 [US6] Obtain deployment approval from technical lead and DBA

**Checkpoint**: At this point, all 7 jobs should be deployed to STAGING and independently testable

---

## Phase 9: GooList User-Defined Type Migration (Cross-Cutting)

**Goal**: Migrate GooList user-defined table type to PostgreSQL temporary table pattern

**Independent Test**: Test functions using GooList pattern with batch input (10k-20k materials) and verify performance

### Phase 1: Analysis for GooList Type

- [ ] T255 [US2] Analyze GooList type usage in docs/code-analysis/dependency-analysis-lote4-types.md
- [ ] T256 [US2] Document all functions using GooList parameter
- [ ] T257 [US2] Validate temporary table pattern decision from research.md

### Phase 2: Refactoring for GooList Type

- [ ] T258 [US2] Create temporary table pattern template in source/building/pgsql/refactored/types/goolist-pattern.sql
- [ ] T259 [US2] Document GooList conversion pattern in source/building/pgsql/refactored/types/goolist-pattern.md
- [ ] T260 [US2] Update function signatures to accept temporary table pattern

### Phase 3: Validation for GooList Type

- [ ] T261 [US2] Test GooList pattern with small batches (100 materials)
- [ ] T262 [US2] Test GooList pattern with medium batches (1000 materials)
- [ ] T263 [US2] Test GooList pattern with large batches (10k-20k materials)
- [ ] T264 [US2] Verify ON COMMIT DROP cleans up temporary tables correctly

---

## Phase 10: Materialized View Refresh Configuration (Cross-Cutting)

**Goal**: Configure pg_cron for scheduled materialized view refresh

**Independent Test**: Execute manual refresh, then verify scheduled refresh runs every 10 minutes

### Phase 1: Materialized View Refresh Setup

- [ ] T265 [US1] Install pg_cron extension in PostgreSQL
- [ ] T266 [US1] Create refresh schedule for `translated` view per research.md
- [ ] T267 [US1] Create refresh schedules for any other materialized views
- [ ] T268 [US1] Setup monitoring for refresh failures

### Phase 2: Validation for Materialized View Refresh

- [ ] T269 [US1] Test manual REFRESH MATERIALIZED VIEW CONCURRENTLY for `translated`
- [ ] T270 [US1] Verify refresh completes without blocking queries
- [ ] T271 [US1] Test scheduled refresh execution over 24-hour period
- [ ] T272 [US1] Verify refresh performance (staleness acceptable: 5-15 minutes)
- [ ] T273 [US1] Monitor refresh failures and alerting

---

## Phase 11: Production Cutover (Final Deployment)

**Goal**: Execute production cutover with <8 hour downtime window

**Independent Test**: Full production deployment with rollback capability tested

### Pre-Cutover Preparation

- [ ] T274 Create production cutover runbook
- [ ] T275 [P] Validate all STAGING deployments are stable (7-day measurement)
- [ ] T276 [P] Verify all quality scores ≥8.0/10 average (SC-013)
- [ ] T277 [P] Verify all performance baselines within 20% degradation (SC-004)
- [ ] T278 Create production backup and rollback procedures
- [ ] T279 Schedule cutover downtime window (<8 hours)
- [ ] T280 Obtain final deployment approval from stakeholders

### Cutover Execution

- [ ] T281 Stop application services
- [ ] T282 Create final SQL Server backup
- [ ] T283 Deploy all views to PRODUCTION using scripts/deployment/deploy-batch.sh
- [ ] T284 Deploy all functions to PRODUCTION
- [ ] T285 Deploy all tables to PRODUCTION
- [ ] T286 Deploy all indexes to PRODUCTION
- [ ] T287 Deploy all constraints to PRODUCTION
- [ ] T288 Migrate production data (91 tables)
- [ ] T289 Validate row count and checksum for all tables (SC-003)
- [ ] T290 Deploy FDW configurations to PRODUCTION
- [ ] T291 Deploy SymmetricDS replication to PRODUCTION
- [ ] T292 Deploy pgAgent jobs to PRODUCTION
- [ ] T293 Configure materialized view refresh schedules

### Post-Cutover Validation

- [ ] T294 Run full smoke test suite in PRODUCTION using scripts/deployment/smoke-test.sh
- [ ] T295 Verify application connectivity to PostgreSQL
- [ ] T296 Execute critical business workflows end-to-end
- [ ] T297 Monitor database performance for 24 hours
- [ ] T298 Verify zero production incidents (SC-010)
- [ ] T299 Confirm cutover downtime <8 hours (SC-011)

### Post-Production Monitoring (7-day period)

- [ ] T300 Monitor database availability (target: 99.9% uptime per SC-015)
- [ ] T301 Monitor query performance trends
- [ ] T302 Monitor replication lag (target: <5 minutes p95 per SC-008)
- [ ] T303 Monitor FDW connection stability
- [ ] T304 Monitor materialized view refresh performance
- [ ] T305 Monitor job execution success rates
- [ ] T306 Maintain rollback capability for 7 days (AS-014 aligned with CN-023)
- [ ] T307 Decommission SQL Server after 7-day stability period

---

## Phase 12: Polish & Cross-Cutting Concerns

**Purpose**: Documentation, training, and final quality improvements

- [ ] T308 [P] Create complete technical documentation in docs/
- [ ] T309 [P] Create operational runbooks for DBAs
- [ ] T310 [P] Update naming conversion mapping table with all object conversions
- [ ] T311 [P] Create training materials for application teams
- [ ] T312 [P] Document lessons learned and migration retrospective
- [ ] T313 Code quality review and final refactoring
- [ ] T314 Performance optimization for objects below target quality scores
- [ ] T315 Security hardening review
- [ ] T316 [P] Validate against quickstart.md example
- [ ] T317 Archive migration artifacts and close project

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-8)**: All depend on Foundational phase completion
  - **US1 (Views)**: Can start after Foundational - Requires tables to exist (coordinate with US3)
  - **US2 (Functions)**: Can start after Foundational - Requires views and tables (coordinate with US1, US3)
  - **US3 (Tables)**: Can start after Foundational - No dependencies on other stories (foundational for US1, US2)
  - **US4 (FDW)**: Can start after Foundational - Requires tables (coordinate with US3)
  - **US5 (Replication)**: Can start after Foundational - Requires tables (coordinate with US3)
  - **US6 (Jobs)**: Can start after Foundational - Requires all database objects (depends on US1, US2, US3)
- **GooList Type (Phase 9)**: Part of US2 (Functions) - Must complete before function deployment
- **Materialized View Refresh (Phase 10)**: Part of US1 (Views) - Must complete before view deployment
- **Production Cutover (Phase 11)**: Depends on all user stories deployed to STAGING
- **Polish (Phase 12)**: Depends on production cutover completion

### User Story Dependencies (Critical Path)

**Recommended Sequencing**:
1. **Phase 3 (US1 - Views)** and **Phase 5 (US3 - Tables)** in parallel (tables are foundational for views)
2. **Phase 4 (US2 - Functions)** after US1 and US3 (functions depend on views and tables)
3. **Phase 6 (US4 - FDW)** after US3 (FDW depends on tables)
4. **Phase 7 (US5 - Replication)** after US3 (replication depends on tables)
5. **Phase 8 (US6 - Jobs)** after all other stories (jobs depend on all database objects)

**Alternative: Sequential by Priority**:
- User Story 1 (P1) → User Story 2 (P1) → User Story 3 (P1) → User Story 4 (P2) → User Story 5 (P2) → User Story 6 (P3)
- **Risk**: Tables (US3) may block views (US1) and functions (US2) if not coordinated

### Within Each User Story

- Dependency analysis before phase 1 (analysis)
- Phase 1 (Analysis) before Phase 2 (Refactoring)
- Phase 2 (Refactoring) before Phase 3 (Validation)
- Phase 3 (Validation) before Phase 4 (Deployment)
- Within each phase: Tasks marked [P] can run in parallel

### Parallel Opportunities

- **Setup phase**: All tasks marked [P] (T002, T003, T004, T005, T007, T008, T010, T011, T012) can run in parallel
- **Foundational phase**: All validation/deployment scripts marked [P] can run in parallel
- **User Story 1 (Views)**:
  - Analysis: All 22 view analyses can run in parallel (T034-T038)
  - Refactoring: Most views can be refactored in parallel (T042-T045) after `translated` is complete
  - Validation: Unit tests can run in parallel (T047-T050)
- **User Story 2 (Functions)**:
  - Analysis: All 25 function analyses can run in parallel (T066-T070)
  - Refactoring: Most functions can be refactored in parallel (T077)
  - Validation: Unit tests can run in parallel (T081-T085)
- **User Story 3 (Tables)**:
  - Analysis: Table groups can be analyzed in parallel (T101-T104)
  - Refactoring: Tables can be refactored in parallel (T108-T111)
  - Indexes: Index groups can be created in parallel (T115-T117)
  - Constraints: Constraint groups can be created in parallel (T120-T123)
  - Validation: Unit tests can run in parallel (T132-T134)
- **User Story 4 (FDW)**:
  - Analysis: All 3 FDW analyses can run in parallel (T153-T155)
  - Refactoring: Foreign table creation can run in parallel (T163-T165)
  - Validation: Integration tests can run in parallel (T169-T171)
- **User Story 5 (Replication)**:
  - Validation: Replication tests can run in parallel (T200-T202)
- **User Story 6 (Jobs)**:
  - Analysis: All 7 job analyses can run in parallel (T221-T224)
  - Refactoring: All 7 jobs can be created in parallel (T228-T231)
  - Validation: Job tests can run in parallel (T236-T239)
- **Polish phase**: Documentation tasks marked [P] can run in parallel (T308-T312)

---

## Parallel Example: User Story 1 (Views)

```bash
# Launch all view analyses together (Phase 1):
Task: "Analyze `translated` indexed view → materialized view in source/building/pgsql/refactored/views/translated-analysis.md"
Task: "Analyze `upstream` recursive CTE view in source/building/pgsql/refactored/views/upstream-analysis.md"
Task: "Analyze `downstream` recursive CTE view in source/building/pgsql/refactored/views/downstream-analysis.md"
Task: "Analyze `goo_relationship` standard view in source/building/pgsql/refactored/views/goo_relationship-analysis.md"
Task: "Analyze remaining 18 views in parallel (create analysis.md for each)"

# Launch all view refactoring together (Phase 2, after translated is complete):
Task: "Refactor `upstream` recursive CTE in source/building/pgsql/refactored/views/upstream.sql"
Task: "Refactor `downstream` recursive CTE in source/building/pgsql/refactored/views/downstream.sql"
Task: "Refactor `goo_relationship` in source/building/pgsql/refactored/views/goo_relationship.sql"
Task: "Refactor remaining 18 views in parallel (one .sql file per view)"

# Launch all unit tests together (Phase 3):
Task: "Create unit tests for `translated` view in tests/unit/views/test_translated.sql"
Task: "Create unit tests for `upstream` view in tests/unit/views/test_upstream.sql"
Task: "Create unit tests for `downstream` view in tests/unit/views/test_downstream.sql"
Task: "Create unit tests for remaining 19 views in tests/unit/views/"
```

---

## Parallel Example: User Story 3 (Tables)

```bash
# Launch all table refactoring together (Phase 2):
Task: "Refactor core table schemas in source/building/pgsql/refactored/tables/goo.sql"
Task: "Refactor `material_transition` table in source/building/pgsql/refactored/tables/material_transition.sql"
Task: "Refactor `transition_material` table in source/building/pgsql/refactored/tables/transition_material.sql"
Task: "Refactor remaining 88 tables in parallel (one .sql file per table)"

# Launch all index creation together (Phase 3):
Task: "Create primary key indexes in source/building/pgsql/refactored/indexes/pk-indexes.sql"
Task: "Create foreign key indexes in source/building/pgsql/refactored/indexes/fk-indexes.sql"
Task: "Create query optimization indexes in source/building/pgsql/refactored/indexes/query-indexes.sql"

# Launch all constraint creation together (Phase 4):
Task: "Create primary key constraints in source/building/pgsql/refactored/constraints/pk-constraints.sql"
Task: "Create foreign key constraints in source/building/pgsql/refactored/constraints/fk-constraints.sql"
Task: "Create unique constraints in source/building/pgsql/refactored/constraints/unique-constraints.sql"
Task: "Create check constraints in source/building/pgsql/refactored/constraints/check-constraints.sql"
```

---

## Implementation Strategy

### MVP First (Minimum Viable Migration)

**Recommended MVP**: User Stories 1 + 2 + 3 (Views, Functions, Tables)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 5: User Story 3 (Tables) - Foundation for all other objects
4. Complete Phase 3: User Story 1 (Views) - Core data access layer
5. Complete Phase 4: User Story 2 (Functions) - Core business logic
6. **STOP and VALIDATE**: Test all core database objects independently in STAGING
7. Deploy to production if ready (excludes FDW, replication, jobs)

### Incremental Delivery

1. **Foundation** (Weeks 1-2): Setup + Foundational → Migration infrastructure ready
2. **Core Objects** (Weeks 3-5): US3 (Tables) + US1 (Views) + US2 (Functions) → Core database functional
3. **External Integration** (Week 6): US4 (FDW) → Cross-database queries restored
4. **Data Synchronization** (Week 7): US5 (Replication) → Warehouse integration restored
5. **Automation** (Week 8): US6 (Jobs) → Full operational capability
6. **Production Cutover** (Week 9): Cutover + 7-day monitoring
7. Each phase adds value without breaking previous phases

### Parallel Team Strategy

With multiple database engineers:

1. Team completes Setup + Foundational together (Weeks 1-2)
2. Once Foundational is done:
   - **Engineer A**: User Story 3 (Tables) - CRITICAL PATH
   - **Engineer B**: User Story 1 (Views) - Depends on tables being available
   - **Engineer C**: User Story 2 (Functions) - Depends on views and tables
3. After core objects (US1, US2, US3) complete:
   - **Engineer A**: User Story 4 (FDW)
   - **Engineer B**: User Story 5 (Replication)
   - **Engineer C**: User Story 6 (Jobs)
4. Stories complete and integrate independently

### Critical Success Factors

1. **Tables first**: User Story 3 (Tables) is foundational - must complete before views and functions can be fully tested
2. **Quality gates**: Enforce ≥7.0/10 quality score threshold at each validation phase
3. **Performance validation**: Ensure ≤20% degradation before proceeding to next phase
4. **Dependency order**: Follow dependency analysis files (lote1-4) strictly
5. **Rollback readiness**: Test rollback procedures before production deployment

---

## Notes

- **[P] tasks**: Different files, no dependencies - can run in parallel
- **[Story] label**: Maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Verify quality scores ≥7.0/10 before proceeding to deployment phase
- Document all naming conversions in the mapping table
- Follow constitution's seven core principles throughout implementation
- Maintain SQL Server rollback capability for 7 days post-migration

---

## Task Count Summary

- **Total Tasks**: 317
- **Setup (Phase 1)**: 12 tasks
- **Foundational (Phase 2)**: 18 tasks
- **User Story 1 (Views)**: 32 tasks
- **User Story 2 (Functions)**: 35 tasks
- **User Story 3 (Tables)**: 52 tasks
- **User Story 4 (FDW)**: 37 tasks
- **User Story 5 (Replication)**: 29 tasks
- **User Story 6 (Jobs)**: 37 tasks
- **GooList Type (Phase 9)**: 10 tasks (part of US2)
- **Materialized View Refresh (Phase 10)**: 9 tasks (part of US1)
- **Production Cutover (Phase 11)**: 34 tasks
- **Polish (Phase 12)**: 10 tasks

**Parallel Opportunities**: 127 tasks marked [P] can run in parallel with other tasks

**Estimated Timeline**: 8-9 weeks (per research.md implementation roadmap)

---

## Suggested MVP Scope

**MVP = User Stories 1 + 2 + 3 (Core Database Objects)**

This delivers:
- ✅ All 91 tables with data (US3)
- ✅ All 22 views (US1)
- ✅ All 25 functions (US2)
- ✅ All 352 indexes (US3)
- ✅ All 271 constraints (US3)
- ✅ Core database functional for application use

**Deferred to Post-MVP**:
- FDW external integration (US4)
- SymmetricDS replication (US5)
- pgAgent jobs (US6)

**Rationale**: Core objects enable application functionality. External integration and automation can be configured incrementally post-migration.
