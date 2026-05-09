# SQL Server Original T-SQL (READ-ONLY)

## Purpose

Original T-SQL source code extracted from SQL Server 2014 Perseus database. **READ-ONLY reference** for understanding business logic and comparing with PostgreSQL conversions.

## Structure

Organized in **dependency order** (0-14 categories): drop operations first, create operations last.

## Contents

### Object Categories (822 SQL files total)

| Category | Files | Description |
|----------|-------|-------------|
| **0. drop-foreign-key-constraint/** | 124 | Drop FK constraints first (dependencies) |
| **0. drop-linked-server/** | 3 | Drop linked server connections |
| **0. drop-sys-schedule/** | 7 | Drop SQL Agent schedules |
| **1. drop-routine/** | 40 | Drop procedures/functions |
| **1. drop-server-trigger/** | 6 | Drop server-level triggers |
| **2. drop-job/** | 7 | Drop SQL Agent jobs |
| **2. drop-view/** | 22 | Drop views |
| **3. drop-table/** | 101 | Drop tables |
| **4. drop-type/** | 1 | Drop user-defined types |
| **5. drop-schema/** | 2 | Drop schemas |
| **6. create-schema/** | 2 | Create schemas |
| **6. create-sys-schedule/** | 7 | Create SQL Agent schedules |
| **7. create-type/** | 1 | Create UDT (GooList) |
| **8. create-table/** | 101 | Create tables |
| **9. create-index/** | 37 | Create indexes |
| **10. create-view/** | 22 | Create views |
| **11. create-routine/** | 40 | Create procedures/functions |
| **12. create-constraint/** | 141 | Create constraints |
| **13. create-foreign-key-constraint/** | 124 | Create FK constraints last |
| **14. create-other/** | 34 | Other objects |

Total: **822 files** (101 tables, 40 routines, 22 views, 37 indexes, 265 constraints, 7 jobs, 1 UDT, 349 other)

## Key Objects

**P0 Critical (must migrate first):**
- `11. create-routine/` - AddArc, RemoveArc, ReconcileMUpstream procedures
- `11. create-routine/` - McGet* functions (upstream, downstream, upstreambylist, downstreambylist)
- `10. create-view/` - translated indexed view
- `8. create-table/` - goo, material_transition, transition_material tables
- `7. create-type/` - GooList TVP

## Usage

**READ-ONLY** - Do not modify these files. Use for:
- Understanding original business logic
- Identifying T-SQL patterns to convert
- Comparing with AWS SCT and PostgreSQL versions

## Navigation

Up: [../README.md](../README.md)

---

**Last Updated:** 2026-01-22 | **Files:** 822 T-SQL | **Status:** ✅ Extracted
