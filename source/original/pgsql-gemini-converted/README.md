# AWS SCT Converted Baseline (READ-ONLY)

## Purpose

AWS Schema Conversion Tool (SCT) output - **baseline for manual correction** (~70% complete). Contains automated conversion from SQL Server T-SQL to PostgreSQL PL/pgSQL. **Requires ~30% manual review and correction.**

## Structure

Organized in **dependency order** (0-21 categories): drop operations first, create operations last. More granular than SQL Server original (21 vs 14 categories).

## Contents

### Object Categories (1,385 files total)

| Category | Files | Description | Status |
|----------|-------|-------------|--------|
| **0. drop-trigger/** | 6 | Drop triggers first | ✅ Baseline |
| **1. drop-function/** | 48 | Drop functions | ✅ Baseline |
| **2. drop-procedure/** | 16 | Drop procedures | ✅ Baseline |
| **3-10. drop-*** | 890+ | Drop other objects | ✅ Baseline |
| **11. create-database/** | 1 | Create database | ✅ Baseline |
| **12. create-type/** | 1 | Create types (GooList) | 🚧 Needs manual conversion |
| **13. create-domain/** | 1 | Create domains | ✅ Baseline |
| **14. create-table/** | 101 | Create tables | 🚧 Needs review |
| **15. create-view/** | 22 | Create views | 🚧 Needs review (indexed → materialized) |
| **16. create-index/** | 36 | Create indexes | ✅ Baseline |
| **17. create-constraint/** | 335 | Create constraints (expanded) | 🚧 Needs consolidation |
| **18. create-foreign-key-constraint/** | 124 | Create FK constraints | ✅ Baseline |
| **19. create-function/** | 48 | Create functions | 🚧 Needs manual correction |
| **20. create-procedure/** | 16 | Create procedures | 🚧 Needs manual correction |
| **21. create-trigger/** | 6 | Create triggers | 🚧 Needs review |

**Total: 1,385 files** (822 original → 1,385 converted = +69% expansion)

## Known AWS SCT Issues

**P0 Critical Issues (Fix immediately):**
- Missing parameters in function signatures
- Incorrect CITEXT type usage everywhere
- Temp table syntax errors (`#temp` not converted properly)
- Transaction control missing (`BEGIN TRAN` not converted)
- NULL comparison errors (`= NULL` not converted to `IS NULL`)

**P1 High Priority Issues:**
- Excessive `LOWER()` function calls (unnecessary)
- Missing error handling (`EXCEPTION` blocks)
- No schema-qualification of object references
- Index hints not removed (PostgreSQL doesn't support)

**P2 Medium Priority:**
- Constraint explosion (335 vs 141 original - needs consolidation)
- Function vs Procedure misclassification (48 functions, only 16 procedures)
- Embedded AWS SCT warning comments in code

## Usage

**DO:**
- ✅ Use as baseline/starting point for manual correction
- ✅ Compare with SQL Server original to identify issues
- ✅ Copy to `building/pgsql/refactored/` and correct

**DO NOT:**
- ❌ Deploy directly to production (~70% complete, needs correction)
- ❌ Trust blindly (~30% requires manual fixes)
- ❌ Modify files here (copy to refactored/ first)

## Workflow Integration

1. **Baseline:** This directory provides starting point
2. **Analysis:** Identify P0-P3 issues (categorize by severity)
3. **Correction:** Copy to `building/pgsql/refactored/` and fix
4. **Validation:** Test corrected version thoroughly

## Navigation

Up: [../README.md](../README.md)

---

**Last Updated:** 2026-01-22 | **Files:** 1,385 PL/pgSQL | **Status:** 🚧 Baseline (~70% complete)
