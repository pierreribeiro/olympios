# Analysis: ReconcileMUpstream

**Object Type:** procedure
**Analyst:** analyze-object.py (automated)
**Date:** 2026-01-25 14:41:58

---

## Quality Score Summary

| Dimension | Score | Weight | Contribution |
|-----------|-------|--------|--------------|
| Syntax Correctness | 10.0/10 | 20% | 2.00 |
| Logic Preservation | 5.0/10 | 30% | 1.50 |
| Performance | 10.0/10 | 20% | 2.00 |
| Maintainability | 8.0/10 | 15% | 1.20 |
| Security | 10.0/10 | 15% | 1.50 |
| **OVERALL** | **8.2/10** | 100% | **8.20** |

**Status:** ❌ FAIL (Minimum: 7.0/10 overall, no dimension below 6.0/10)

---

## Issue Summary

- **P0 Critical:** 0 (Blocks deployment)
- **P1 High:** 3 (Must fix before PROD)
- **P2 Medium:** 1 (Fix before STAGING)
- **P3 Low:** 0 (Track for improvement)

**Total Issues:** 4

---

## Complexity Metrics

- **Lines of Code:** 240
- **Cyclomatic Complexity:** 21
- **Branching Points:** 18 (IF/CASE statements)
- **Loop Structures:** 2 (WHILE/FOR loops)
- **Nesting Depth:** 3
- **Comment Ratio:** 8.9%

**Complexity Assessment:** Complex (high risk - consider refactoring)

---

## Detailed Issues

### P1 Issues (3)

**1. BEGIN TRAN should be BEGIN (PostgreSQL)**
   - Constitution Principle: IV (Atomic Transaction Management)
   - Location: Line 91
   - Context: `[7807 - Severity CRITICAL - PostgreSQL does not support explicit transaction management commands such as BEGIN TRAN, SAVE TRAN in functions. Convert your source code manually.]`

**2. BEGIN TRAN should be BEGIN (PostgreSQL)**
   - Constitution Principle: IV (Atomic Transaction Management)
   - Location: Line 92
   - Context: `BEGIN TRANSACTION`

**3. BEGIN TRAN should be BEGIN (PostgreSQL)**
   - Constitution Principle: IV (Atomic Transaction Management)
   - Location: Line 233
   - Context: `[7807 - Severity CRITICAL - PostgreSQL does not support explicit transaction management commands such as BEGIN TRAN, SAVE TRAN in functions. Convert your source code manually.]`

### P2 Issues (1)

**1. Prefer specific exceptions over WHEN OTHERS only**
   - Constitution Principle: VI (Structured Error Resilience)
   - Location: Line 215
   - Context: `WHEN OTHERS THEN`

---

## Source Files

- **Original (SQL Server):** `/Users/pierre.ribeiro/workspace/projects/amyris/sqlserver-to-postgresql-migration/source/original/sqlserver/11.create-routine/8.perseus.dbo.ReconcileMUpstream.sql`
- **Converted (PostgreSQL):** `/Users/pierre.ribeiro/workspace/projects/amyris/sqlserver-to-postgresql-migration/source/original/pgsql-aws-sct-converted/19.create-function/32.perseus.reconcilemupstream.sql`

---

## Recommendations

⚠️ **HIGH PRIORITY:** P1 issues must be fixed before production deployment

🔄 **REFACTORING:** High complexity - consider breaking into smaller functions/CTEs

⚡ **PERFORMANCE:** Consider converting loops to set-based operations (CTEs/window functions)

❌ **QUALITY GATE:** Object does not meet minimum quality threshold (7.0/10)

---

**Analysis completed:** 2026-01-25 14:41:58
**Tool version:** analyze-object.py v1.0