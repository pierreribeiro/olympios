# Analysis: mcgetupstream

**Object Type:** function
**Analyst:** analyze-object.py (automated)
**Date:** 2026-01-25 14:39:31

---

## Quality Score Summary

| Dimension | Score | Weight | Contribution |
|-----------|-------|--------|--------------|
| Syntax Correctness | 10.0/10 | 20% | 2.00 |
| Logic Preservation | 10.0/10 | 30% | 3.00 |
| Performance | 10.0/10 | 20% | 2.00 |
| Maintainability | 10.0/10 | 15% | 1.50 |
| Security | 10.0/10 | 15% | 1.50 |
| **OVERALL** | **10.0/10** | 100% | **10.00** |

**Status:** ✅ PASS (Minimum: 7.0/10 overall, no dimension below 6.0/10)

---

## Issue Summary

- **P0 Critical:** 0 (Blocks deployment)
- **P1 High:** 0 (Must fix before PROD)
- **P2 Medium:** 0 (Fix before STAGING)
- **P3 Low:** 0 (Track for improvement)

**Total Issues:** 0

---

## Complexity Metrics

- **Lines of Code:** 52
- **Cyclomatic Complexity:** 6
- **Branching Points:** 2 (IF/CASE statements)
- **Loop Structures:** 3 (WHILE/FOR loops)
- **Nesting Depth:** 1
- **Comment Ratio:** 5.6%

**Complexity Assessment:** Simple (low risk)

---

## Detailed Issues

✅ No issues detected

---

## Source Files

- **Original (SQL Server):** `/Users/pierre.ribeiro/workspace/projects/amyris/sqlserver-to-postgresql-migration/source/original/sqlserver/11.create-routine/39.perseus.dbo.McGetUpStreamByList.sql`
- **Converted (PostgreSQL):** `/Users/pierre.ribeiro/workspace/projects/amyris/sqlserver-to-postgresql-migration/source/original/pgsql-aws-sct-converted/19.create-function/25.perseus.mcgetupstream.sql`

---

## Recommendations

⚡ **PERFORMANCE:** Consider converting loops to set-based operations (CTEs/window functions)

✅ **QUALITY GATE:** Object meets minimum quality threshold

---

**Analysis completed:** 2026-01-25 14:39:31
**Tool version:** analyze-object.py v1.0