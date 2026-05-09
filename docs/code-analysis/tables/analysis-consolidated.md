# Perseus Table Schema Analysis - Executive Summary (T107)
## Consolidated Analysis of 101 Tables (SQL Server → PostgreSQL)

**Analysis Date**: 2026-01-26
**Analyst**: Claude (database-expert)
**User Story**: US3 - Table Structures Migration
**Tasks Completed**: T101-T107
**Status**: Analysis Phase Complete - Ready for Refactoring
**Scope**: All 101 Perseus tables across 3 schemas (dbo, hermes, demeter)

---

## Executive Overview

This document consolidates the comprehensive analysis of all 101 Perseus database tables from SQL Server to PostgreSQL migration using AWS Schema Conversion Tool (SCT) output.

### Analysis Coverage

| Analysis Document | Tables Covered | Focus Area | Status |
|-------------------|----------------|------------|--------|
| **core-tables-analysis.md** (T101) | 4 | P0 critical path (goo, material_transition, transition_material, goo_type) | ✅ Complete |
| **relationship-tables-analysis.md** (T102) | 3 | Cached lineage graphs (m_upstream, m_downstream, m_upstream_dirty_leaves) | ✅ Complete |
| **container-tables-analysis.md** (T103) | 4 | Container management (container, container_type, history, positions) | ✅ Complete |
| **remaining-tables-analysis.md** (T104) | 90 | All other tables grouped by functional area | ✅ Complete |
| **data-type-conversions.md** (T105) | ~1,700 columns | Comprehensive data type mapping reference | ✅ Complete |
| **identity-columns-analysis.md** (T106) | 90 IDENTITY columns | Auto-increment column conversions | ✅ Complete |
| **THIS DOCUMENT** (T107) | 101 (All) | Consolidated rollup and priorities | ✅ Complete |

---

## Section 1: Quality Score Summary (All 101 Tables)

### Overall Quality Distribution

| Score Range | Table Count | Percentage | Category | Action Required |
|-------------|-------------|------------|----------|-----------------|
| **8.0-10.0** | 0 | 0% | Excellent | None - ready for deployment |
| **7.0-7.9** | 0 | 0% | Good | Minor cleanup |
| **6.0-6.9** | 18 | 18% | Acceptable | Standard refactoring |
| **5.0-5.9** | 64 | 63% | Needs Improvement | Moderate refactoring |
| **4.0-4.9** | 11 | 11% | Poor | Significant refactoring |
| **0.0-3.9** | 8 | 8% | Critical | Architecture redesign (FDW tables) |
| **AVERAGE** | **5.4/10** | - | **NEEDS IMPROVEMENT** | **~500 column-level fixes needed** |

### Quality Score Breakdown by Analysis Phase

| Analysis Phase | Tables | Avg Score | Key Issues | Priority |
|----------------|--------|-----------|------------|----------|
| **Core Tables (T101)** | 4 | 6.5/10 | Schema naming, CITEXT, OIDS | P0 - Critical |
| **Relationship Tables (T102)** | 3 | 5.0/10 | Missing PKs, CITEXT on joins, OIDS | P0 - Critical |
| **Container Tables (T103)** | 4 | 5.5/10 | CITEXT overuse, boolean as INTEGER | P1 - High |
| **Remaining Tables (T104)** | 90 | 5.4/10 | All issues (see Section 2) | P1-P3 |

**AWS SCT Overall Accuracy: ~71%** (1,200 of 1,700 columns correct)

---

## Section 2: Issue Summary (P0-P3 Severity)

### P0 Critical Issues (BLOCKS ALL DEPLOYMENT) - 450 instances

| Issue Category | Count | Affected Tables | Impact | Fix Effort |
|----------------|-------|-----------------|--------|------------|
| **Schema Naming** | 101 | ALL tables | Wrong schema (`perseus_dbo` vs `perseus`) | 2 hours (scripted) |
| **OIDS Clause** | 101 | ALL tables | Deprecated syntax (PostgreSQL 12+) | 1 hour (scripted) |
| **FDW Architecture** | 8 | hermes.*, demeter.* | Local tables instead of FOREIGN TABLE | 8 hours (manual) |
| **Missing PRIMARY KEYS** | 90 | All with IDENTITY | No unique row identification | 3 hours (scripted) |
| **CITEXT on Paths/URLs** | 15 | *_attachment, workflow | File paths case-sensitive | 2 hours (manual) |
| **Case-Sensitive Lost** | 15 | hermes.run, others | CS collation → CITEXT | 2 hours (manual) |
| **Computed Columns Lost** | 5 | fatsmurf, others | Business logic not preserved | 8 hours (triggers) |

**P0 Total**: 335 issues | **Estimated Fix Time**: ~26 hours

---

### P1 High Issues (MUST FIX BEFORE PRODUCTION) - 225 instances

| Issue Category | Count | Affected Tables | Impact | Fix Effort |
|----------------|-------|-----------------|--------|------------|
| **Boolean as INTEGER** | 35 | 25 tables | Type mismatch, query logic broken | 3 hours (scripted) |
| **CITEXT Overuse** | 120 | 80 tables | Performance overhead, wrong semantics | 12 hours (manual review) |
| **Missing FOREIGN KEYS** | 50 | 40 tables | No referential integrity | 8 hours (manual) |
| **Missing UNIQUE Constraints** | 20 | Junction tables | Duplicate data risk | 2 hours (manual) |

**P1 Total**: 225 issues | **Estimated Fix Time**: ~25 hours

---

### P2 Medium Issues (FIX BEFORE STAGING) - 120 instances

| Issue Category | Count | Affected Tables | Impact | Fix Effort |
|----------------|-------|-----------------|--------|------------|
| **Missing Comments** | 101 | ALL tables | No documentation | 8 hours (scripted template) |
| **Missing Indexes** | 30 | Various | Query performance gaps | 6 hours (after profiling) |
| **Column Name Case Changes** | 10 | Permissions, recipe | Query compatibility | 2 hours (document) |
| **Missing CHECK Constraints** | 25 | Various | Data validation gaps | 4 hours (manual) |

**P2 Total**: 166 issues | **Estimated Fix Time**: ~20 hours

---

### P3 Low Issues (TRACK FOR FUTURE) - 50 instances

| Issue Category | Count | Affected Tables | Impact | Fix Effort |
|----------------|-------|-----------------|--------|------------|
| **Parentheses in Defaults** | 30 | Various | Code style | 1 hour (optional cleanup) |
| **varchar(max) → TEXT** | 20 | Various | Documentation clarity | 2 hours (review limits) |

**P3 Total**: 50 instances | **Estimated Fix Time**: ~3 hours

---

### **TOTAL ISSUES: 776** | **ESTIMATED FIX TIME: ~74 hours (~9.5 days)**

---

## Section 3: Tables by Refactoring Priority

### Tier 1: IMMEDIATE - P0 Dependencies (8 tables) - Fix FIRST

| # | Table | Schema | Priority | Quality Score | Key Issues | Dependencies |
|---|-------|--------|----------|---------------|------------|--------------|
| 1 | **goo** | perseus | P0 | 6.5/10 | Schema, CITEXT on uid/paths, OIDS, missing PK | None (Tier 3) |
| 2 | **goo_type** | perseus | P0 | 7.0/10 | Schema, CITEXT, OIDS, missing PK | None (Tier 0) |
| 3 | **material_transition** | perseus | P0 | 6.0/10 | Schema, OIDS, missing PK/FKs | goo (Tier 4) |
| 4 | **transition_material** | perseus | P0 | 6.0/10 | Schema, OIDS, missing PK/FKs | goo (Tier 4) |
| 5-8 | **hermes.*** (6 tables) | hermes | P1 | 3.0/10 | **FDW architecture** (local vs foreign) | None (external) |
| 9-10 | **demeter.*** (2 tables) | demeter | P1 | 3.0/10 | **FDW architecture** (local vs foreign) | None (external) |

**Estimated Time**: 16 hours

---

### Tier 2: HIGH PRIORITY - P1 Dependencies (15 tables)

| # | Table | Schema | Priority | Quality Score | Key Issues |
|---|-------|--------|----------|---------------|------------|
| 11 | **m_upstream** | perseus | P0 | 5.0/10 | Missing PK, CITEXT on join columns, OIDS |
| 12 | **m_downstream** | perseus | P0 | 5.0/10 | Missing PK, CITEXT on join columns, OIDS |
| 13 | **m_upstream_dirty_leaves** | perseus | P0 | 5.0/10 | Missing PK, OIDS |
| 14 | **goo_type_combine_component** | perseus | P1 | 4.5/10 | Missing FKs, unique constraint |
| 15 | **goo_type_combine_target** | perseus | P1 | 4.5/10 | Missing FKs, unique constraint |
| 16 | **goo_attachment** | perseus | P1 | 5.0/10 | CITEXT on file_path (P0), missing FKs |
| 17 | **goo_comment** | perseus | P1 | 5.0/10 | CITEXT overuse, missing FKs |
| 18 | **goo_history** | perseus | P1 | 5.0/10 | Missing FKs to history table |
| 19 | **recipe** | perseus | P1 | 5.0/10 | Boolean as INTEGER (3 cols), missing FKs |
| 20 | **recipe_part** | perseus | P1 | 5.0/10 | Missing FKs |
| 21 | **fatsmurf** | perseus | P2 | 4.5/10 | **Computed column lost** (run_complete), boolean |
| 22 | **material_inventory*** (4 tables) | perseus | P1 | 5.4/10 | Standard issues |
| 23 | **workflow*** (4 tables) | perseus | P1 | 5.7/10 | Standard issues |

**Estimated Time**: 20 hours

---

### Tier 3: MEDIUM PRIORITY - P2 Functional Groups (30 tables)

| Group | Tables | Priority | Avg Score | Key Issues |
|-------|--------|----------|-----------|------------|
| **Smurf System** | 6 | P2 | 5.2/10 | Boolean as INTEGER, CITEXT |
| **Field Maps** | 7 | P2 | 5.5/10 | CITEXT overuse |
| **Robot Logs** | 7 | P2 | 5.4/10 | CITEXT, missing FKs |
| **Container System** | 4 | P1 | 5.5/10 | Boolean, CITEXT, nested sets |
| **Submissions** | 2 | P2 | 5.5/10 | Standard issues |
| **History/Audit** | 3 | P2 | 5.7/10 | Missing indexes, FKs |
| **COA** | 2 | P2 | 5.5/10 | Standard issues |

**Estimated Time**: 18 hours

---

### Tier 4: LOW PRIORITY - P3 Config/Lookup (48 tables)

| Group | Tables | Priority | Avg Score | Key Issues |
|-------|--------|----------|-----------|------------|
| **Configuration Management (cm_*)** | 10 | P3 | 5.5/10 | Standard issues (low usage) |
| **Lookups** (unit, color, manufacturer, etc.) | 18 | P2-P3 | 6.0/10 | Minimal issues (simple tables) |
| **System Tables** (Permissions, Scraper, etc.) | 3 | P3 | 5.3/10 | Case changes, CITEXT |
| **Polls** | 2 | P3 | 5.5/10 | Standard issues |
| **Misc** (tmp_messy_links, sequences) | 5 | P3 | 5.0/10 | Review if still needed |

**Estimated Time**: 10 hours

---

## Section 4: Top 10 Critical Issues (Actionable)

| Rank | Issue | Severity | Tables | Columns | Impact | Fix Time |
|------|-------|----------|--------|---------|--------|----------|
| 1 | **FDW Tables as Local** | P0 | 8 | 300+ | Architecture broken, data sync issues | 8h |
| 2 | **Schema Naming (perseus_dbo)** | P0 | 101 | ALL | Wrong schema, breaks organization | 2h |
| 3 | **Missing PRIMARY KEYS** | P0 | 90 | 90 | No unique identification, replication breaks | 3h |
| 4 | **Boolean as INTEGER** | P1 | 25 | 35 | Query logic broken, type mismatch | 3h |
| 5 | **CITEXT Overuse (Performance)** | P1 | 80 | 400+ | Unnecessary overhead, wrong semantics | 12h |
| 6 | **OIDS=FALSE Deprecated** | P0 | 101 | ALL | Future PostgreSQL compatibility | 1h |
| 7 | **Computed Columns Lost** | P0 | 5 | 5 | Business logic not preserved | 8h |
| 8 | **File Paths as CITEXT** | P0 | 10 | 15 | Case-sensitivity broken (Linux paths) | 2h |
| 9 | **Missing FOREIGN KEYS** | P1 | 40 | 50+ | No referential integrity | 8h |
| 10 | **clock_timestamp() vs CURRENT_TIMESTAMP** | P1 | 60 | 150+ | Timestamp stability in transactions | 2h |

**Total Fix Time for Top 10**: 49 hours (~6 days)

---

## Section 5: Data Type Conversion Summary

### Conversion Accuracy by Type

| Data Type | Total Columns | AWS SCT Correct | Needs Fix | Accuracy | Status |
|-----------|---------------|-----------------|-----------|----------|--------|
| **IDENTITY** | 90 | 90 | 0 | 100% | ✅ Perfect |
| **INTEGER** | 450 | 450 | 0 | 100% | ✅ Perfect |
| **SMALLINT** | 20 | 20 | 0 | 100% | ✅ Perfect |
| **FLOAT/DOUBLE** | 100 | 100 | 0 | 100% | ✅ Perfect |
| **NUMERIC/DECIMAL** | 150 | 150 | 0 | 100% | ✅ Perfect |
| **DATE** | 50 | 50 | 0 | 100% | ✅ Perfect |
| **DATETIME** | 200 | 160 | 40 | 80% | ⚠️ clock_timestamp() issue |
| **STRING (VARCHAR/CITEXT)** | 600 | 180 | 420 | 30% | ❌ CITEXT overuse |
| **BOOLEAN (bit)** | 35 | 0 | 35 | 0% | ❌ All INTEGER |
| **COMPUTED** | 5 | 0 | 5 | 0% | ❌ Logic lost |
| **TOTAL** | **~1,700** | **~1,200** | **~500** | **71%** | ⚠️ Needs work |

---

### Critical Data Type Issues

#### 1. String Types: CITEXT Overuse (420 columns)

**Problem**: AWS SCT converts ALL `varchar` columns to `CITEXT` (case-insensitive), regardless of actual need.

**Impact**:
- Performance overhead (CITEXT is slower than VARCHAR)
- Wrong semantics (file paths, IDs, URLs are case-sensitive)
- Length constraints lost (`varchar(100)` → unbounded `CITEXT`)

**Fix Strategy**:
```sql
-- Keep CITEXT for user-facing search columns
name CITEXT
email CITEXT

-- Change to VARCHAR for case-sensitive data
file_path VARCHAR(500)  -- NOT CITEXT
uid VARCHAR(50)          -- NOT CITEXT
barcode VARCHAR(100)     -- NOT CITEXT
```

**Estimated Fix**: 12 hours (manual review of 420 columns)

---

#### 2. Boolean Types: INTEGER Instead of BOOLEAN (35 columns)

**Problem**: AWS SCT converts `bit` columns to `INTEGER` instead of `BOOLEAN`.

**Impact**:
- Type mismatch in queries (`WHERE is_preferred` fails)
- Storage waste (4 bytes vs 1 byte per value)
- Logic errors (0/1 vs TRUE/FALSE semantics)

**Fix Strategy**:
```sql
-- Change all INTEGER boolean columns to BOOLEAN
ALTER TABLE perseus.recipe
    ALTER COLUMN is_preferred TYPE BOOLEAN USING (is_preferred::INTEGER != 0),
    ALTER COLUMN qc TYPE BOOLEAN USING (qc::INTEGER != 0),
    ALTER COLUMN is_archived TYPE BOOLEAN USING (is_archived::INTEGER != 0);

-- Update defaults
ALTER TABLE perseus.recipe
    ALTER COLUMN is_preferred SET DEFAULT FALSE,
    ALTER COLUMN qc SET DEFAULT FALSE,
    ALTER COLUMN is_archived SET DEFAULT FALSE;
```

**Estimated Fix**: 3 hours (scripted conversion)

---

#### 3. Computed Columns: Business Logic Lost (5 columns)

**Problem**: SQL Server computed columns not preserved in PostgreSQL.

**Example**:
```sql
-- SQL Server
[run_complete] AS (
    CASE WHEN [duration] IS NULL THEN getdate()
    ELSE dateadd(minute, [duration] * 60, [run_on])
    END
)

-- AWS SCT (WRONG - logic lost)
run_complete TIMESTAMP WITHOUT TIME ZONE
```

**Fix Strategy**: Use triggers (GENERATED COLUMN not supported for non-deterministic functions)

```sql
CREATE OR REPLACE FUNCTION perseus.fatsmurf_compute_run_complete()
RETURNS TRIGGER AS $$
BEGIN
    NEW.run_complete := CASE
        WHEN NEW.duration IS NULL THEN CURRENT_TIMESTAMP
        ELSE NEW.run_on + (NEW.duration * INTERVAL '1 hour')
    END;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_fatsmurf_run_complete
    BEFORE INSERT OR UPDATE OF run_on, duration ON perseus.fatsmurf
    FOR EACH ROW EXECUTE FUNCTION perseus.fatsmurf_compute_run_complete();
```

**Estimated Fix**: 8 hours (5 triggers + testing)

---

## Section 6: Migration Workflow Recommendations

### Phase 1: Critical Infrastructure (Week 1) - 8 tables

**Focus**: P0 tables + FDW architecture

| Order | Tables | Tasks | Hours |
|-------|--------|-------|-------|
| 1 | hermes.*, demeter.* | Convert to FOREIGN TABLE, setup postgres_fdw | 8h |
| 2 | goo, goo_type | Fix schema, CITEXT, OIDS, add PKs | 4h |
| 3 | material_transition, transition_material | Fix schema, OIDS, add PKs/FKs | 4h |

**Deliverable**: P0 critical path functional
**Estimated Time**: 16 hours (2 days)

---

### Phase 2: Core Lineage System (Week 2) - 12 tables

**Focus**: Cached graphs + core goo-related tables

| Order | Tables | Tasks | Hours |
|-------|--------|-------|-------|
| 4 | m_upstream, m_downstream, m_upstream_dirty_leaves | Fix PKs, CITEXT on joins, OIDS | 6h |
| 5 | goo_attachment, goo_comment, goo_history | Fix file paths, CITEXT, FKs | 6h |
| 6 | goo_type_combine_* | Fix FKs, unique constraints | 4h |

**Deliverable**: Material lineage system functional
**Estimated Time**: 16 hours (2 days)

---

### Phase 3: Business Logic Tables (Week 3) - 25 tables

**Focus**: Recipes, workflows, containers, fatsmurf

| Order | Tables | Tasks | Hours |
|-------|--------|-------|-------|
| 7 | recipe, recipe_part, recipe_project_assignment | Fix boolean columns, FKs | 4h |
| 8 | fatsmurf + related (5 tables) | **Computed column trigger**, boolean, FKs | 8h |
| 9 | workflow + related (4 tables) | Fix CITEXT, FKs | 4h |
| 10 | container + related (4 tables) | Fix boolean, CITEXT, nested sets | 6h |
| 11 | material_inventory + related (4 tables) | Standard fixes | 4h |

**Deliverable**: Core business processes functional
**Estimated Time**: 26 hours (3.5 days)

---

### Phase 4: Supporting Systems (Week 4) - 30 tables

**Focus**: Smurf, robot logs, field maps, submissions

| Order | Tables | Tasks | Hours |
|-------|--------|-------|-------|
| 12 | smurf + related (6 tables) | Fix boolean, CITEXT, FKs | 6h |
| 13 | robot_log + related (7 tables) | Standard fixes | 6h |
| 14 | field_map + related (7 tables) | CITEXT review, FKs | 6h |
| 15 | submission + related (2 tables) | Standard fixes | 2h |
| 16 | history + related (3 tables) | Indexes, FKs | 3h |
| 17 | COA + related (2 tables) | Standard fixes | 2h |

**Deliverable**: All functional systems operational
**Estimated Time**: 25 hours (3 days)

---

### Phase 5: Configuration & Lookups (Week 5) - 26 tables

**Focus**: cm_*, lookups, system tables

| Order | Tables | Tasks | Hours |
|-------|--------|-------|-------|
| 18 | cm_* (10 tables) | Standard fixes (low priority) | 5h |
| 19 | Lookup tables (18 tables) | Minimal fixes (simple tables) | 5h |
| 20 | System tables (Permissions, Scraper, etc.) | Case changes, CITEXT | 3h |
| 21 | Polls, misc (5 tables) | Standard fixes | 2h |

**Deliverable**: Complete schema migrated
**Estimated Time**: 15 hours (2 days)

---

### Phase 6: Post-Migration (Week 6)

| Order | Tasks | Hours |
|-------|-------|-------|
| 22 | Add ALL PRIMARY KEY constraints (90 tables) | 3h |
| 23 | Add ALL FOREIGN KEY constraints (~50 FKs) | 8h |
| 24 | Add CHECK constraints (25 tables) | 4h |
| 25 | Add comments (101 tables - scripted) | 4h |
| 26 | Add indexes (30 indexes after profiling) | 6h |
| 27 | Data migration testing (preserve IDs) | 8h |
| 28 | Sequence reset validation | 2h |

**Deliverable**: Production-ready schema with all constraints
**Estimated Time**: 35 hours (4.5 days)

---

### **TOTAL MIGRATION TIME: ~133 hours (~17 days @ 8h/day)**

**With parallel work (2-3 developers)**: 6-8 weeks including testing

---

## Section 7: Quality Metrics & Success Criteria

### Pre-Migration Quality (AWS SCT Output)

| Dimension | Score | Issues |
|-----------|-------|--------|
| **Syntax Correctness** | 6.0/10 | OIDS deprecated, schema naming |
| **Logic Preservation** | 5.0/10 | Computed columns lost, boolean types |
| **Performance** | 6.0/10 | CITEXT overhead, missing indexes |
| **Maintainability** | 4.0/10 | No comments, wrong types |
| **Security** | 5.0/10 | No row-level security, FDW issues |
| **OVERALL** | **5.4/10** | **NEEDS IMPROVEMENT** |

---

### Post-Migration Target Quality

| Dimension | Target Score | Success Criteria |
|-----------|--------------|------------------|
| **Syntax Correctness** | 9.0/10 | All PostgreSQL 17 standard syntax, no deprecated features |
| **Logic Preservation** | 9.5/10 | All computed columns restored, boolean logic correct |
| **Performance** | 8.5/10 | CITEXT only where needed, indexes optimized |
| **Maintainability** | 8.0/10 | All tables/columns documented, correct types |
| **Security** | 7.5/10 | FDW properly configured, schema permissions set |
| **OVERALL** | **8.5/10** | **PRODUCTION READY** |

---

### Deployment Gates

#### DEV Environment
- ✅ Syntax valid (can CREATE all tables)
- ⚠️ Can have P2/P3 issues
- Minimum Score: 6.0/10

#### STAGING Environment
- ✅ ZERO P0/P1 issues
- ✅ All PKs, FKs added
- ✅ All tests passing
- Minimum Score: 7.5/10

#### PRODUCTION Environment
- ✅ STAGING sign-off
- ✅ Performance benchmarks within ±20% of SQL Server
- ✅ Rollback plan tested
- Target Score: 8.5/10

---

## Section 8: Risk Assessment

### High Risk Items (Mitigation Required)

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| **FDW Performance** | Medium | High | Benchmark queries, optimize fetch_size, consider caching |
| **Computed Column Logic Errors** | Medium | High | Unit test all triggers, compare results with SQL Server |
| **CITEXT Performance Regression** | Medium | Medium | Profile queries, add indexes, convert to VARCHAR where possible |
| **Data Migration ID Conflicts** | Low | High | Use OVERRIDING SYSTEM VALUE, reset sequences, validate |
| **Boolean Query Failures** | High | Medium | Comprehensive query testing, update application code |

---

### Medium Risk Items

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| **Missing Indexes** | Medium | Medium | Profile workload, add indexes incrementally |
| **Case-Sensitivity Issues** | Low | Medium | Test all hermes.run queries with CS columns |
| **Nested Sets (Container Hierarchy)** | Low | Medium | Validate left/right calculations, test edge cases |

---

### Low Risk Items

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| **Schema Naming Confusion** | Low | Low | Update all queries to use correct schema |
| **Documentation Gaps** | High | Low | Generate comments from SQL Server extended properties |

---

## Section 9: Recommended Tooling & Automation

### Schema Refactoring Scripts

```bash
# 1. Fix schema names (perseus_dbo → perseus)
./scripts/refactor/fix-schema-names.sh

# 2. Remove OIDS clauses
./scripts/refactor/remove-oids.sh

# 3. Add PRIMARY KEYS
./scripts/refactor/add-primary-keys.sh

# 4. Fix boolean columns (INTEGER → BOOLEAN)
./scripts/refactor/fix-boolean-columns.sh

# 5. Fix CITEXT overuse (semi-automated - needs review)
./scripts/refactor/review-citext-columns.sh

# 6. Fix datetime defaults (clock_timestamp → CURRENT_TIMESTAMP)
./scripts/refactor/fix-timestamp-defaults.sh

# 7. Add FOREIGN KEYS
./scripts/refactor/add-foreign-keys.sh

# 8. Add comments
./scripts/refactor/add-table-comments.sh
```

### Validation Scripts

```bash
# Check for remaining issues
./scripts/validation/check-schema-names.sh
./scripts/validation/check-missing-pks.sh
./scripts/validation/check-boolean-columns.sh
./scripts/validation/check-citext-usage.sh
./scripts/validation/check-missing-fks.sh

# Performance benchmarks
./scripts/validation/benchmark-queries.sh
```

---

## Section 10: Next Steps (Immediate Actions)

### Week 1: Preparation

1. ✅ **Review this analysis** with project lead (Pierre Ribeiro)
2. ⚠️ **Prioritize FDW setup** - hermes/demeter connectivity
3. ⚠️ **Create refactoring scripts** - automate schema naming, OIDS, PKs
4. ⚠️ **Setup DEV environment** - PostgreSQL 17 instance
5. ⚠️ **Test FDW connectivity** - hermes-db, demeter-db connection strings

---

### Week 2-3: Core Refactoring (T108-T110 in User Story plan)

1. **T108**: Refactor P0 tables (goo, goo_type, material_transition, transition_material)
2. **T109**: Setup FDW for hermes/demeter (8 tables)
3. **T110**: Refactor cached graph tables (m_upstream, m_downstream, m_upstream_dirty_leaves)

---

### Week 4-5: Business Logic Refactoring

4. **T111**: Refactor recipe, workflow, fatsmurf systems
5. **T112**: Add computed column triggers
6. **T113**: Refactor container, material_inventory systems

---

### Week 6: Supporting Systems & Constraints

7. **T114**: Refactor smurf, robot_log, field_map systems
8. **T115**: Add all PRIMARY KEY constraints
9. **T116**: Add all FOREIGN KEY constraints
10. **T117**: Add CHECK constraints and comments

---

### Week 7: Testing & Validation

11. **T118**: Data migration testing (preserve IDs)
12. **T119**: Query performance benchmarks
13. **T120**: Integration testing with procedures/views

---

## Section 11: Key Takeaways

### What AWS SCT Got Right (71% accuracy)

✅ **IDENTITY columns** - 100% correct (GENERATED ALWAYS AS IDENTITY)
✅ **Numeric types** - 100% correct (INTEGER, SMALLINT, NUMERIC, FLOAT)
✅ **Date types** - 100% correct (DATE)
✅ **Table structure** - Preserved column order, nullability

### What AWS SCT Got Wrong (29% errors)

❌ **String types** - 70% error rate (CITEXT overuse)
❌ **Boolean types** - 100% error rate (INTEGER instead of BOOLEAN)
❌ **Computed columns** - 100% error rate (logic lost)
❌ **FDW tables** - 100% error rate (local tables instead of foreign)
❌ **Defaults** - 20% error rate (clock_timestamp vs CURRENT_TIMESTAMP)
❌ **Schema naming** - 100% error rate (perseus_dbo vs perseus)
❌ **Deprecated syntax** - 100% use OIDS=FALSE

### Manual Review Required

⚠️ **420 CITEXT columns** - Review each for case-sensitivity needs
⚠️ **35 boolean columns** - Convert all to BOOLEAN
⚠️ **5 computed columns** - Recreate with triggers
⚠️ **8 FDW tables** - Redesign as FOREIGN TABLE
⚠️ **90 PRIMARY KEYS** - Add all
⚠️ **50+ FOREIGN KEYS** - Add all

---

## Section 12: Contact & Support

**Project Lead**: Pierre Ribeiro (Senior DBA/DBRE)
**Database Expert Agent**: Available for SQL analysis, optimization
**Documentation**: See individual analysis files (T101-T106)

---

**Status**: ✅ Analysis Phase Complete (T101-T107)
**Next Phase**: Refactoring (T108-T120)
**Estimated Completion**: 6-8 weeks (with parallel work)
**Risk Level**: Medium (FDW architecture, computed columns, CITEXT performance)
**Go/No-Go**: ✅ PROCEED with refactoring (issues are manageable, well-documented)

---

**End of T107 Executive Summary**
**Ready for User Story US3 Phase 2: Refactoring**
