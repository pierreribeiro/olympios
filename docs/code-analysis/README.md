# Code Analysis Directory

## Purpose

Comprehensive analysis artifacts documenting all 769 database objects, their dependencies, priorities, and migration strategies. Used to guide systematic conversion from SQL Server to PostgreSQL.

## Structure

```
code-analysis/
├── procedures/                              # Per-procedure detailed analysis (17 files)
├── dependency-analysis-consolidated.md      # All 769 objects + P0 critical path
├── dependency-analysis-lote1-stored-procedures.md  # 21 procedures
├── dependency-analysis-lote2-functions.md   # 25 functions
├── dependency-analysis-lote3-views.md       # 22 views
└── dependency-analysis-lote4-types.md       # 1 type (GooList)
```

## Contents

### Consolidated Analysis

- **[dependency-analysis-consolidated.md](dependency-analysis-consolidated.md)** (37 KB) - Master document covering all 769 database objects with complete dependency graph, P0 critical path (9 objects), priority classifications (P0-P3), and migration order recommendations.

### Lote-Based Analysis (By Object Type)

- **[dependency-analysis-lote1-stored-procedures.md](dependency-analysis-lote1-stored-procedures.md)** (17 KB) - Analysis of 21 stored procedures with dependencies, priority levels, complexity ratings, and migration strategies. **Status:** 15/21 complete (71%).

- **[dependency-analysis-lote2-functions.md](dependency-analysis-lote2-functions.md)** (23 KB) - Analysis of 25 functions (15 table-valued, 10 scalar) including critical McGet* family (P0) and legacy Get* family (P1). **Status:** 0/25 complete.

- **[dependency-analysis-lote3-views.md](dependency-analysis-lote3-views.md)** (25 KB) - Analysis of 22 views including critical `translated` materialized view (P0), recursive CTEs, and relationship views. **Status:** 0/22 complete.

- **[dependency-analysis-lote4-types.md](dependency-analysis-lote4-types.md)** (26 KB) - Analysis of GooList user-defined table type (UDT) requiring conversion to TEMPORARY TABLE pattern. **Status:** 0/1 complete.

### Per-Procedure Analysis

**[procedures/](procedures/)** subdirectory contains 17 detailed analysis documents covering completed procedures:

1. `addarc-analysis.md` - Add arc to material transition graph
2. `getmaterialbyrunproperties-analysis.md` - Retrieve materials by run properties
3. `linkunlinkedmaterials-analysis.md` - Link unlinked materials
4. `materialtotransition-analysis.md` - Convert material to transition
5. `movecontainer-analysis.md` - Move container between locations
6. `movegootype-analysis.md` - Update goo type assignments
7. `processdirtytrees-analysis.md` - Process dirty tree structures
8. `processsomemupstream-analysis.md` - Process upstream relationships
9. `reconcilemupstream-analysis.md` - Reconcile upstream material data
10. `removearc-analysis.md` - Remove arc from material transition graph
11. `sp-move-node-analysis.md` - Move node in hierarchy
12. `transitiontomaterial-analysis.md` - Convert transition to material
13. `usp-updatecontainertypefromargus-analysis.md` - Update container type
14. `usp-updatemdownstream-analysis.md` - Update downstream relationships
15. `usp-updatemupstream-analysis.md` - Update upstream relationships
16-17. (Additional analysis documents)

Each procedure analysis includes: original T-SQL review, AWS SCT baseline assessment, P0-P3 issue identification, complexity rating, dependency mapping, quality score calculation, and correction recommendations.

## Analysis Framework

### Priority Classification

- **P0 (Critical)**: Must complete before other migrations. Blocks dependencies.
- **P1 (High)**: High-value objects with moderate dependencies.
- **P2 (Medium)**: Standard business logic with low dependencies.
- **P3 (Low)**: Utility objects with minimal dependencies.

### Complexity Rating

- **High (8-10)**: Complex logic, multiple dependencies, requires detailed analysis
- **Medium (4-7)**: Moderate complexity, standard patterns
- **Low (1-3)**: Simple logic, minimal dependencies

### Quality Score Dimensions

1. **Syntax Correctness** (20%): Valid PostgreSQL 17 syntax
2. **Logic Preservation** (30%): Business logic identical to SQL Server
3. **Performance** (20%): Within ±20% of baseline
4. **Maintainability** (15%): Readable, documented, follows constitution
5. **Security** (15%): No SQL injection, proper permissions

**Minimum:** 7.0/10 overall, NO dimension below 6.0/10

## Key Findings

### P0 Critical Path (9 Objects)

**MUST complete before other migrations:**
1. **VIEW** `translated` - Indexed view → materialized view conversion
2. **FUNCTIONS (4)**: `mcgetupstream`, `mcgetdownstream`, `mcgetupstreambylist`, `mcgetdownstreambylist`
3. **TABLES (3)**: `goo`, `material_transition`, `transition_material`
4. **TYPE** `GooList` - User-defined table type → TEMPORARY TABLE pattern

### Migration Statistics

| Object Type | Total | Complete | Pending | Progress |
|-------------|-------|----------|---------|----------|
| **Procedures** | 21 | 15 ✅ | 6 | 71% |
| **Functions** | 25 | 0 | 25 | 0% |
| **Views** | 22 | 0 | 22 | 0% |
| **Tables** | 91 | 0 | 91 | 0% |
| **Indexes** | 352 | 0 | 352 | 0% |
| **Constraints** | 271 | 0 | 271 | 0% |
| **Types** | 1 | 0 | 1 | 0% |
| **FDW** | 3 | 0 | 3 | 0% |
| **Jobs** | 7 | 0 | 7 | 0% |
| **TOTAL** | **769** | **15** | **754** | **2%** |

## Usage

**For Planning:**
- Start with `dependency-analysis-consolidated.md` for project overview
- Review lote-specific analysis for object type patterns
- Identify dependencies before starting conversion

**For Implementation:**
- Review per-procedure analysis before converting similar objects
- Follow P0 → P1 → P2 → P3 priority order
- Use analysis documents to understand AWS SCT issues

**For Validation:**
- Compare corrected version against analysis recommendations
- Verify all P0/P1 issues addressed
- Confirm quality score meets targets

## Navigation

- Up: [../README.md](../README.md)
- See: [procedures/](procedures/) for detailed procedure analysis

---

**Last Updated:** 2026-01-22 | **Documents:** 5 lote analyses + 17 procedure analyses | **Coverage:** All 769 objects documented
