# Example: How to Add Execution Requirements to tasks.md

This file shows the recommended structure for adding mandatory execution requirements to each User Story in tasks.md.

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
/ralph-loop

Task: Analyze 22 views from User Story 1 (per dependency-analysis-lote3-views.md)
Order: P3 (simple) → P2 → P1 → P0 (translated materialized view LAST)
Iterate: Read AWS SCT → Apply constitution → Schema-qualify → Syntax validate
Checkpoint: After every 5 views, commit with quality scores
Gate: Before P0 view, validate ALL 21 dependencies resolved
Exit: All 22 views analyzed + quality scores ≥7.0/10.0 + no P0/P1 issues
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

- [ ] T031 [P] [US1] Review dependency analysis for all 22 views in docs/code-analysis/dependency-analysis-lote3-views.md
- [ ] T032 [P] [US1] Identify base tables required by views (ensure tables exist or will be created in parallel)
- [ ] T033 [US1] Create dependency-ordered view migration sequence

### Phase 1: Analysis for User Story 1 Views

**Purpose**: Analyze AWS SCT output and document issues for all 22 views

- [ ] T034 [P] [US1] Analyze `translated` indexed view → materialized view in source/building/pgsql/refactored/views/translated-analysis.md
- [ ] T035 [P] [US1] Analyze `upstream` recursive CTE view in source/building/pgsql/refactored/views/upstream-analysis.md
- [ ] T036 [P] [US1] Analyze `downstream` recursive CTE view in source/building/pgsql/refactored/views/downstream-analysis.md
- [ ] T037 [P] [US1] Analyze `goo_relationship` standard view in source/building/pgsql/refactored/views/goo_relationship-analysis.md
- [ ] T038 [P] [US1] Analyze remaining 18 views in parallel (create analysis.md for each)
- [ ] T039 [US1] Consolidate view analysis findings and quality scores in tracking/progress-tracker.md

### Phase 2: Refactoring for User Story 1 Views

**Purpose**: Refactor views to production-ready PostgreSQL code

- [ ] T040 [US1] Refactor `translated` to materialized view in source/building/pgsql/refactored/views/translated.sql
- [ ] T041 [US1] Create UNIQUE index for CONCURRENT refresh in source/building/pgsql/refactored/views/translated.sql
- [ ] T042 [P] [US1] Refactor `upstream` recursive CTE in source/building/pgsql/refactored/views/upstream.sql
- [ ] T043 [P] [US1] Refactor `downstream` recursive CTE in source/building/pgsql/refactored/views/downstream.sql
- [ ] T044 [P] [US1] Refactor `goo_relationship` in source/building/pgsql/refactored/views/goo_relationship.sql
- [ ] T045 [P] [US1] Refactor remaining 18 views in parallel (one .sql file per view)
- [ ] T046 [US1] Validate all view definitions compile with scripts/validation/syntax-check.sh

### Phase 3: Validation for User Story 1 Views

**Purpose**: Test views against validation contracts

- [ ] T047 [P] [US1] Create unit tests for `translated` view in tests/unit/views/test_translated.sql
- [ ] T048 [P] [US1] Create unit tests for `upstream` view in tests/unit/views/test_upstream.sql
- [ ] T049 [P] [US1] Create unit tests for `downstream` view in tests/unit/views/test_downstream.sql
- [ ] T050 [P] [US1] Create unit tests for remaining 19 views in tests/unit/views/
- [ ] T051 [US1] Run result set comparison tests (SQL Server vs PostgreSQL) using scripts/validation/data-integrity-check.sql
- [ ] T052 [US1] Run performance baseline tests for all views using scripts/validation/performance-test.sql
- [ ] T053 [US1] Validate materialized view refresh performance for `translated`
- [ ] T054 [US1] Verify all views meet ≥7.0/10 quality score threshold
- [ ] T055 [US1] Document any performance optimizations needed in tracking/progress-tracker.md

### Phase 4: Deployment for User Story 1 Views

**Purpose**: Deploy views to DEV → STAGING → PRODUCTION

- [ ] T056 [US1] Deploy all 22 views to DEV environment using scripts/deployment/deploy-batch.sh
- [ ] T057 [US1] Run smoke tests in DEV using scripts/deployment/smoke-test.sh
- [ ] T058 [US1] Deploy all 22 views to STAGING environment
- [ ] T059 [US1] Execute integration tests in STAGING with application queries
- [ ] T060 [US1] Create rollback procedures for all views in scripts/deployment/rollback-object.sh
- [ ] T061 [US1] Document operational runbook for view maintenance
- [ ] T062 [US1] Obtain deployment approval from technical lead and DBA

**Checkpoint**: At this point, all 22 views should be deployed to STAGING and independently testable

---

## KEY DIFFERENCES FROM ORIGINAL

**ADDED**:
1. **🔧 Execution Requirements** section (MANDATORY callout)
2. **Worktree Setup** commands (copy-paste ready)
3. **Pre-Flight Checklist** (force verification before start)
4. **Mandatory Agents** with ratings (enforce CLAUDE.md compliance)
5. **Ralph Loop Plugin** with concrete example (force batch efficiency)
6. **Parallelization Strategy** (explicit sequential dependencies)
7. **Quality Gates** (enforce constitution compliance)

**PRESERVED**:
- All original task definitions (T031-T062)
- Task markers ([P] for parallel)
- Phase structure (Dependency → Analysis → Refactoring → Validation → Deployment)
- Checkpoint notes

**BENEFITS**:
- ✅ Forces consultation of WORKFLOW-GUIDE.md
- ✅ Enforces worktree isolation
- ✅ Mandates database agent usage
- ✅ Ensures Ralph Loop for batch tasks
- ✅ Clarifies parallel vs sequential execution
- ✅ Sets quality gates upfront
