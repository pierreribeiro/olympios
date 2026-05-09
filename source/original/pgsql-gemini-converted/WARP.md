# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Repository Context

This is the **AWS Schema Conversion Tool (SCT) output directory** within a SQL Server → PostgreSQL migration project. You are currently in the `pgsql-aws-sct-converted` subdirectory, which contains the automated baseline conversion of the Perseus database schema and procedures from SQL Server to PostgreSQL.

**Project Mission:** Convert 15 stored procedures from SQL Server T-SQL to PostgreSQL PL/pgSQL with zero production incidents.

**Important:** This directory is part of a larger migration project. The root directory is at `D:\pierre.ribeiro\OneDrive - Amyris\Documents\Workspace\sqlserver-to-postgresql-migration`.

## Directory Structure

```
sqlserver-to-postgresql-migration/           # PROJECT ROOT
├── procedures/
│   ├── original/              # T-SQL source from SQL Server (READ-ONLY)
│   ├── aws-sct-converted/     # AWS SCT baseline (~70% complete)
│   ├── corrected/             # Production-ready procedures (100% complete)
│   └── analysis/              # Quality analysis reports
├── source/original/
│   ├── pgsql-aws-sct-converted/    ← YOU ARE HERE
│   │   ├── 0. drop-trigger/
│   │   ├── 1. drop-function/
│   │   ├── 11. create-database/
│   │   ├── 12. create-type/
│   │   ├── 13. create-domain/
│   │   ├── 14. create-table/         # 96 table definitions (perseus, perseus_demeter, perseus_hermes)
│   │   ├── 15. create-view/
│   │   ├── 16. create-index/
│   │   ├── 17. create-constraint/
│   │   ├── 18. create-foreign-key-constraint/
│   │   ├── 19. create-function/      # 48 functions/procedures (AWS SCT converted)
│   │   ├── 20. create-procedure/
│   │   └── 21. create-trigger/
│   └── sqlserver/             # Original SQL Server extracts
├── scripts/
│   ├── validation/            # Syntax/setup validation
│   └── automation/            # Python helpers (requires requirements.txt)
├── templates/                 # PostgreSQL procedure template
├── tests/                     # Unit/integration tests
├── tracking/                  # Priority matrix, progress tracker
└── docs/                      # Setup guide, project plan
```

## Key Files to Reference

When working on procedure migrations, always reference:

1. **Project README**: `../../../README.md` - Project status, completed procedures, achievements
2. **Setup Guide**: `../../../docs/SETUP-GUIDE.md` - Environment setup, Python dependencies
3. **Project Plan**: `../../../docs/PROJECT-PLAN.md` - 10-week roadmap, workflow phases
4. **Procedure Template**: `../../../templates/postgresql-procedure-template.sql` - Production-quality template
5. **Priority Matrix**: `../../../tracking/priority-matrix.csv` - All 15 procedures with status, quality scores, completion times

## Critical Migration Patterns

All 15 procedures have been completed (100%). When reviewing or maintaining existing work:

### 1. Transaction Control (P0 - CRITICAL)
- **AWS SCT Issue**: Removes `BEGIN TRANSACTION` but keeps `ROLLBACK`, causing runtime errors
- **Correct Approach**: Use `BEGIN...EXCEPTION...END` blocks within procedures
- **Template Reference**: Lines 113-240 in postgresql-procedure-template.sql

### 2. Temporary Tables (P0 - CRITICAL)
- **AWS SCT Pattern**: Creates temp tables as `tablename$procedurename` WITHOUT `ON COMMIT DROP`
- **Critical Fix**: Always add `ON COMMIT DROP` to prevent orphaned temp tables
- **Performance**: Add PRIMARY KEY constraints for join optimization
```sql
CREATE TEMPORARY TABLE temp_working_data (
    id INTEGER,
    value VARCHAR(100),
    PRIMARY KEY (id)
) ON COMMIT DROP;  -- MUST HAVE THIS
```

### 3. Defensive Cleanup (P0 - CRITICAL)
Always drop temp tables at procedure start to prevent "table already exists" errors:
```sql
DROP TABLE IF EXISTS temp_working_data;
DROP TABLE IF EXISTS temp_results;
```

### 4. Case-Sensitive String Comparisons (P1 - PERFORMANCE)
- **AWS SCT Issue**: Adds `LOWER()` everywhere (13+ occurrences per procedure)
- **Performance Impact**: 30-60% slowdown, prevents index usage
- **Correct Approach**: Remove `LOWER()` if data is normalized, use direct comparisons
```sql
-- BAD (AWS SCT):
WHERE LOWER(column) = LOWER('value')

-- GOOD:
WHERE column = 'value'
```

### 5. Error Handling (P2 - BEST PRACTICE)
- Use `GET STACKED DIAGNOSTICS` for PostgreSQL error details
- Use SQLSTATE 'P0001' (not '50000') for custom exceptions
- Include procedure name in all RAISE messages for observability

### 6. Materialized vs Function-based Relationships
The Perseus database uses materialized relationship tables:
- `m_upstream`: Pre-computed upstream material relationships
- `m_downstream`: Pre-computed downstream material relationships
- **Helper Functions**: `mcgetupstream()`, `mcgetdownstream()`, `mcgetupstreamcontainers()`, `mcgetdownstreamcontainers()`
- **Arc Operations**: `AddArc`, `RemoveArc` modify graph and propagate changes
- **Tree Processing**: `ProcessDirtyTrees` coordinates batch updates via `ProcessSomeMUpstream`

## Database Schema

### Core Schemas
- **perseus**: Main schema with material/transition tracking, containers, workflow
- **perseus_demeter**: Seed/vial tracking
- **perseus_hermes**: Experiment run tracking

### Critical Tables
- `material`: Core material tracking
- `transition`: State transitions
- `material_transition`, `transition_material`: Graph edges (arcs)
- `m_upstream`, `m_downstream`: Materialized relationship views
- `container`, `container_history`: Physical container tracking
- `goo`, `goo_type`: Material type tracking
- `workflow`, `workflow_step`: Process definitions

## Common Development Commands

### Validation
```bash
# Change to project root first
cd ../../../

# Validate setup (Python packages, PostgreSQL, etc.)
./scripts/validation/check-setup.sh

# Validate PostgreSQL syntax (example for specific procedure)
psql -h localhost -U postgres -d perseus_dev -f procedures/corrected/addarc.sql
```

### Python Automation
```bash
# Install dependencies (from project root)
cd ../../../
pip install -r scripts/automation/requirements.txt

# Required packages: sqlparse, click, pandas, rich, jinja2, pyyaml
```

### Working with Procedures
```bash
# Navigate between directories
cd ../../../procedures/corrected/           # Production-ready procedures
cd ../../../procedures/aws-sct-converted/   # AWS SCT baseline
cd ../../../procedures/original/            # T-SQL originals

# View completed procedures
ls ../../../procedures/corrected/

# Check test suites
ls ../../../tests/unit/
```

### Git Workflow
```bash
# From project root
cd ../../../

# Commit using Conventional Commits format
git commit -m "feat: correct ProcedureName with P0 fixes"
git commit -m "docs: update Sprint X completion status"
git commit -m "test: add integration tests for ProcedureName"
git commit -m "chore: update priority matrix"
```

## Quality Standards

All 15 procedures were corrected to meet these standards:

### Quality Metrics (Target: 8.0-8.5/10)
- **Achieved Average**: 8.71/10 (exceeds target)
- **Range**: 8.0 (ProcessSomeMUpstream) to 9.6 (LinkUnlinkedMaterials - PROJECT RECORD)

### Performance Targets
- Must be within ±20% of SQL Server baseline
- **Achieved**: +63% to +97% average improvement
- Notable: AddArc improved 90% (15-20s → 1-2s)

### Time Efficiency
- **Estimated**: 115-120 hours for 15 procedures
- **Actual**: 43.1 hours (37% of budget)
- **Average**: 2.87 hours per procedure (vs 7.67h estimate)
- **Velocity**: 5-6× faster than estimated after pattern establishment

## Project Status (As of 2025-11-29)

**Phase 2: COMPLETE** ✅ (100% - All 15 procedures corrected)

### Completed Procedures by Sprint
- **Sprint 1**: usp_UpdateMUpstream (8.5/10, 3.5h) ✅
- **Sprint 2**: ReconcileMUpstream (8.2/10, 5h), ProcessSomeMUpstream (8.0/10, 4.5h), usp_UpdateMDownstream (8.5/10, 5h) ✅
- **Sprint 3**: AddArc (8.5/10, 2h), RemoveArc (9.0/10, 0.5h), ProcessDirtyTrees (8.5/10, 1.5h) ✅
- **Sprint 4**: GetMaterialByRunProperties (8.8/10, 5.1h) ✅
- **Sprint 5**: TransitionToMaterial (9.5/10, 1.5h), sp_move_node (8.5/10, 2h) ✅
- **Sprint 6**: MaterialToTransition (9.5/10, 3h) ✅
- **Sprint 7**: usp_UpdateContainerTypeFromArgus (8.6/10, 4h - 100% manual rewrite from AWS SCT failure) ✅
- **Sprint 8**: LinkUnlinkedMaterials (9.6/10, 2h - NEW RECORD), MoveContainer (9.0/10, 3h), MoveGooType (8.7/10, 1.5h) ✅

### Next Phase: Integration & Staging
- Sprint 9: Integration testing across all procedures
- Sprint 10: Production deployment

## AWS SCT Conversion Characteristics

When reviewing AWS SCT output in this directory:

### Common Issues
1. **Broken Transaction Control**: Removes BEGIN TRANSACTION, keeps ROLLBACK (P0 blocker)
2. **Missing ON COMMIT DROP**: Temp tables lack automatic cleanup (P0 blocker)
3. **Excessive LOWER() Usage**: 13+ unnecessary case conversions per procedure (P1 performance)
4. **Bloated Code**: 2-3× larger than necessary (e.g., 258 lines vs 82 original)
5. **Strange Naming**: `tablename$procedurename` instead of clean names
6. **Parameter Quoting**: Uses `"@ParameterName"` instead of proper variable names

### Quality Score (Typical)
- **AWS SCT Average**: 2.0-6.6/10 (NOT production-ready)
- **Correction Adds**: +2-4 quality points to reach 8.0-9.6/10

### Warnings to Prioritize
- **[7807] CRITICAL**: Transaction management issues
- **[7615] CRITICAL**: Transaction control in exception handlers  
- **[7659] LOW**: Table variable scope differences (review but usually OK)
- **[7795] LOW**: Case-sensitive string operations (performance impact, remove LOWER())

## Testing Approach

### Test Location
- Unit tests: `../../../tests/unit/test_procedurename.sql`
- Integration tests: `../../../tests/integration/`
- Performance tests: `../../../tests/performance/`

### Test Coverage (Completed Procedures)
- 34+ comprehensive test scenarios created
- Focus on edge cases, error handling, performance benchmarks
- Example: ProcessDirtyTrees has 20+ test scenarios

### Running Tests
```bash
# From project root
cd ../../../

# Run unit tests for specific procedure
psql -h localhost -U postgres -d perseus_test -f tests/unit/test_addarc.sql

# Performance benchmarks
psql -h localhost -U postgres -d perseus_dev -f tests/performance/benchmark_reconcilemupstream.sql
```

## Important Notes

1. **Never Commit Changes Without Context**: This directory contains AWS SCT output. Production-ready versions are in `procedures/corrected/` at the project root.

2. **Pattern Reuse is Key**: After Sprint 3, velocity increased 5-6× due to established patterns. Reference completed procedures in `../../../procedures/corrected/` for examples.

3. **Twin Procedures**: Some procedures are nearly identical:
   - MaterialToTransition ↔ TransitionToMaterial (90% pattern reuse)
   - MoveContainer ↔ MoveGooType (80% pattern reuse)

4. **Dependency Chains**: ProcessDirtyTrees depends on ProcessSomeMUpstream, which depends on ReconcileMUpstream. Consider dependencies when testing.

5. **External Dependencies**: usp_UpdateContainerTypeFromArgus integrates with Argus system via postgres_fdw (not OPENQUERY).

6. **Observability**: All procedures include RAISE NOTICE for step tracking, execution time logging, and comprehensive error messages with procedure names.

## References

- **PostgreSQL Documentation**: https://www.postgresql.org/docs/16/
- **AWS SCT User Guide**: https://docs.aws.amazon.com/SchemaConversionTool/
- **Project Issues**: GitHub issues #15-26 track all completed procedures
- **Retrospective**: `../../../docs/sprint3-retrospective.md` contains key learnings

## Co-Authorship

When creating commits or PRs, include:
```
Co-Authored-By: Warp <agent@warp.dev>
```
