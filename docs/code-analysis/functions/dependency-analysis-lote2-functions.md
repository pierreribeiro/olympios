# 📊 SQL Server Dependency Analysis - Lote 2: Functions
## Perseus Database Migration Project - DinamoTech

**Analysis Date:** 2025-12-15  
**Analyst:** Pierre Ribeiro + Claude (Database Expert)  
**Scope:** 24 Functions in `source/original/sqlserver/Functions/`  
**Repository:** pierreribeiro/sqlserver-to-postgresql-migration

---

## 🎯 Executive Summary

This document provides comprehensive dependency analysis of all 24 user-defined functions in the Perseus SQL Server database. Each function has been analyzed to identify:
- **WHAT it references** (Tables, Views, Types, other Functions)
- **WHO references it** (Stored Procedures, Views, other Functions)

### Key Findings

| Category | Count | Critical Dependencies |
|----------|-------|----------------------|
| **Total Functions Analyzed** | 24 | 100% coverage |
| **McGet* Family (CRITICAL)** | 4 | Material graph traversal - Called by P0 SPs |
| **Get* Family (HIGH)** | 16 | Legacy material hierarchy - Mixed usage |
| **Utility Functions (LOW)** | 4 | String/date manipulation |
| **Recursive CTEs** | 8 | PostgreSQL recursive CTE conversion needed |
| **Cursor Usage** | 2 | PostgreSQL refactoring required |

### Dependency Summary from Lote 1

**Functions Called by P0/P1 Stored Procedures:**
- `McGetUpStream()` → Called by: AddArc, RemoveArc
- `McGetDownStream()` → Called by: AddArc, RemoveArc  
- `McGetUpStreamByList()` → Called by: ReconcileMUpstream, ProcessSomeMUpstream

---

## 📋 Detailed Dependency Analysis

### 1. McGet* Family Functions ⭐ **CRITICAL PRIORITY**

These are the **core material lineage tracking functions** used by P0 stored procedures.

#### 1.1 `dbo.McGetUpStream()` ⭐⭐⭐ **P0 CRITICAL**

**Purpose:** Returns upstream material lineage for a single material using recursive CTE.

**Signature:**
```sql
CREATE FUNCTION McGetUpStream(@StartPoint VARCHAR(50))
RETURNS @Paths TABLE (start_point, end_point, neighbor, path, level)
```

**Dependencies - WHAT it references:**
- **Views:**
  - `translated` (R) - Unified view of material_transition + transition_material
- **Pattern:**
  - Recursive CTE with path accumulation
  - Uses `WITH (NOLOCK)` hint

**Referenced By - WHO references it:**
- **Stored Procedures:**
  - `dbo.AddArc` ⭐ P0 - Called before/after adding material arc
  - `dbo.RemoveArc` ⭐ P0 - Called in commented-out cleanup logic
- **Potential Users:**
  - Other Get* functions (McGetUpDownStream)
  - Application queries (direct calls)

**Complexity Score:** 8/10  
**Business Criticality:** CRITICAL - Core P0 dependency  
**PostgreSQL Notes:** 
- Recursive CTE supported natively
- Remove `WITH (NOLOCK)` hints
- Consider MATERIALIZED view for translated

---

#### 1.2 `dbo.McGetDownStream()` ⭐⭐⭐ **P0 CRITICAL**

**Purpose:** Returns downstream material lineage for a single material using recursive CTE.

**Signature:**
```sql
CREATE FUNCTION McGetDownStream(@StartPoint VARCHAR(50))
RETURNS @Paths TABLE (start_point, end_point, neighbor, path, level)
```

**Dependencies - WHAT it references:**
- **Views:**
  - `translated` (R) - Unified view of material/transition relationships
- **Pattern:**
  - Recursive CTE (inverse direction of McGetUpStream)
  - Uses path concatenation for cycle detection

**Referenced By - WHO references it:**
- **Stored Procedures:**
  - `dbo.AddArc` ⭐ P0 - Called before/after adding material arc
  - `dbo.RemoveArc` ⭐ P0 - Called in commented-out cleanup logic
- **Functions:**
  - `dbo.GetUpstreamMasses()` - Mass calculation function
- **Applications:**
  - Direct queries for lineage visualization

**Complexity Score:** 8/10  
**Business Criticality:** CRITICAL - Core P0 dependency  
**PostgreSQL Notes:**
- Identical conversion strategy to McGetUpStream
- Consider function result caching for frequently queried materials

---

#### 1.3 `dbo.McGetUpStreamByList()` ⭐⭐⭐ **P0 CRITICAL**

**Purpose:** Batch version - returns upstream lineage for MULTIPLE materials simultaneously.

**Signature:**
```sql
CREATE FUNCTION McGetUpStreamByList(@StartPoint GooList READONLY)
RETURNS @Paths TABLE (start_point, end_point, neighbor, path, level)
```

**Dependencies - WHAT it references:**
- **Types:**
  - `GooList` - Table-valued parameter (TVP) with uid column
- **Views:**
  - `translated` (R) - Material/transition relationships
- **Tables:**
  - `goo` (R) - Validates material exists before processing
- **Pattern:**
  - Recursive CTE with JOIN to input parameter
  - Batch processing optimization

**Referenced By - WHO references it:**
- **Stored Procedures:**
  - `dbo.ReconcileMUpstream` ⭐ P0 - Core reconciliation engine
  - `dbo.ProcessSomeMUpstream` ⭐ P1 - Batch processor
- **Business Use:**
  - Scheduled reconciliation jobs
  - Batch lineage updates

**Complexity Score:** 9/10  
**Business Criticality:** CRITICAL - Used by P0 reconciliation  
**PostgreSQL Notes:**
- ⚠️ **GooList TVP conversion required:**
  - Option 1: TEMPORARY TABLE pattern
  - Option 2: ARRAY of VARCHAR
  - Option 3: JSONB array input
- Recommend TEMPORARY TABLE for PostgreSQL compatibility

---

#### 1.4 `dbo.McGetDownStreamByList()` ⭐⭐ **P1 HIGH**

**Purpose:** Batch version - returns downstream lineage for multiple materials.

**Signature:**
```sql
CREATE FUNCTION McGetDownStreamByList(@StartPoint GooList READONLY)
RETURNS @Paths TABLE (start_point, end_point, neighbor, path, level)
```

**Dependencies - WHAT it references:**
- **Types:**
  - `GooList` - Table-valued parameter
- **Views:**
  - `translated` (R)
- **Pattern:**
  - Batch recursive CTE (inverse direction)

**Referenced By - WHO references it:**
- **Inferred Users:**
  - Batch downstream analysis (not explicitly called in Lote 1 SPs)
  - Possible application-level queries
- **Potential:**
  - Future downstream reconciliation procedures

**Complexity Score:** 8/10  
**Business Criticality:** HIGH - Mirror of McGetUpStreamByList  
**PostgreSQL Notes:**
- Same GooList conversion strategy as McGetUpStreamByList

---

### 2. Get* Family Functions (Legacy Material Hierarchy)

These functions use **nested sets model** (tree_left_key, tree_right_key) and `goo_relationship` table for material hierarchies.

#### 2.1 `dbo.GetUpStream()` 🔸 **MEDIUM**

**Purpose:** Legacy upstream traversal using goo table nested sets + goo_relationship.

**Signature:**
```sql
CREATE FUNCTION GetUpStream(@StartPoint INT)
RETURNS @Paths TABLE (start_point INT, end_point INT, level INT)
```

**Dependencies - WHAT it references:**
- **Tables:**
  - `goo` (R) - Uses nested set fields: tree_scope_key, tree_left_key, tree_right_key
  - `goo_relationship` (R) - Explicit parent-child relationships
- **Pattern:**
  - Recursive CTE with TWO branches:
    1. Nested sets traversal
    2. Explicit relationship traversal

**Referenced By - WHO references it:**
- **Views:**
  - Likely used by `upstream` view
- **Stored Procedures:**
  - ProcessDirtyTrees (inferred)
- **Applications:**
  - Legacy queries using goo.id instead of goo.uid

**Complexity Score:** 7/10  
**Business Criticality:** MEDIUM - Legacy system, being replaced by McGet*  
**PostgreSQL Notes:**
- Nested sets model fully supported in PostgreSQL
- Consider ltree extension for modern hierarchy queries

---

#### 2.2 `dbo.GetDownStream()` 🔸 **MEDIUM**

**Purpose:** Legacy downstream traversal (inverse of GetUpStream).

**Dependencies:** Same as GetUpStream  
**Referenced By:** Views, legacy applications  
**Complexity:** 7/10 | **Criticality:** MEDIUM

---

#### 2.3 `dbo.GetUpStreamFamily()` 🔸 **MEDIUM**

**Purpose:** Returns entire upstream family tree for a material.

**Dependencies - WHAT it references:**
- **Tables:**
  - `goo` (R) - Nested sets
  - `goo_relationship` (R)
- **Pattern:**
  - Extended recursive traversal
  - Returns full ancestry

**Referenced By - WHO references it:**
- **Stored Procedures:**
  - `dbo.ProcessDirtyTrees` (inferred)
- **Views:**
  - Possible view dependencies

**Complexity:** 6/10 | **Criticality:** MEDIUM

---

#### 2.4 `dbo.GetDownStreamFamily()` 🔸 **MEDIUM**

**Purpose:** Returns entire downstream family tree.

**Dependencies:** Same pattern as GetUpStreamFamily  
**Complexity:** 6/10 | **Criticality:** MEDIUM

---

#### 2.5 `dbo.GetUpStreamContainers()` 🔸 **MEDIUM**

**Purpose:** Returns upstream materials filtered by container type.

**Dependencies - WHAT it references:**
- **Tables:**
  - `goo` (R) - Material data
  - `container` (R) - Container information (inferred)
  - `goo_relationship` (R)

**Referenced By - WHO references it:**
- **Applications:** Container-specific lineage queries

**Complexity:** 6/10 | **Criticality:** MEDIUM

---

#### 2.6 `dbo.GetDownStreamContainers()` 🔸 **MEDIUM**

**Purpose:** Returns downstream materials filtered by container.

**Dependencies:** Same pattern as GetUpStreamContainers  
**Complexity:** 6/10 | **Criticality:** MEDIUM

---

#### 2.7 `dbo.GetUnProcessedUpStream()` 🔸 **MEDIUM**

**Purpose:** Returns upstream materials that have not been processed (status filtering).

**Dependencies - WHAT it references:**
- **Tables:**
  - `goo` (R) - Status checking
  - Uses GetUpStream or similar pattern
- **Referenced By:**
  - `dbo.GetUpstreamMasses()` ⭐ - Mass calculation function

**Complexity:** 5/10 | **Criticality:** MEDIUM

---

#### 2.8 `dbo.GetUpstreamMasses()` 🔸 **HIGH COMPLEXITY**

**Purpose:** Calculates aggregated masses for upstream materials.

**Signature:**
```sql
CREATE FUNCTION GetUpstreamMasses(@StartPoint NVARCHAR(50))
RETURNS @Masses TABLE (end_point NVARCHAR(50), mass float, level INT)
```

**Dependencies - WHAT it references:**
- **Functions:**
  - `dbo.GetUnProcessedUpStream()` - Get upstream materials
  - `dbo.McGetDownStream()` - Validate downstream paths
- **Tables:**
  - `goo` (R) - original_mass, container_id fields
- **Pattern:**
  - ⚠️ **Uses CURSOR** - T-SQL cursor loop
  - Complex mass aggregation logic
  - Multiple DELETE passes for filtering

**Referenced By - WHO references it:**
- **Applications:**
  - Mass balance calculations
  - Inventory reports

**Complexity Score:** 9/10 - HIGHEST in Get* family  
**Business Criticality:** MEDIUM-HIGH  
**PostgreSQL Notes:**
- ⚠️ **CURSOR must be refactored** to set-based operations
- Consider PostgreSQL window functions for aggregation
- Mass calculation logic needs careful testing

---

#### 2.9-2.16 Additional Get* Functions

**GetReadCombos(), GetTransferCombos(), GetSampleTime():**
- **Purpose:** Robot/automation log data processing
- **Dependencies:** 
  - `robot_log`, `robot_log_read`, `robot_log_transfer` tables
  - Complex JOIN logic
- **Complexity:** 7-8/10
- **Criticality:** MEDIUM - Automation systems

**GetExperiment(), GetHermesExperiment(), GetHermesRun(), GetHermesUid():**
- **Purpose:** Experiment/run ID extraction functions
- **Dependencies:**
  - `hermes.run` table (schema: hermes)
  - `goo` table
- **Pattern:** String parsing from UIDs
- **Complexity:** 3-4/10
- **Criticality:** LOW-MEDIUM

**GetFermentationFatSmurf():**
- **Purpose:** Fermentation-specific material lookup
- **Dependencies:**
  - `fatsmurf`, `smurf`, `goo` tables
- **Complexity:** 5/10
- **Criticality:** MEDIUM

**McGetUpDownStream():**
- **Purpose:** Combined upstream + downstream traversal
- **Dependencies:**
  - `dbo.McGetUpStream()`
  - `dbo.McGetDownStream()`
- **Complexity:** 4/10
- **Criticality:** MEDIUM

---

### 3. Utility Functions 🔧 **LOW PRIORITY**

#### 3.1 `dbo.ReversePath()` 

**Purpose:** Reverses path string format: `/uid/uid2/uid3/` → `/uid3/uid2/uid/`

**Signature:**
```sql
CREATE FUNCTION ReversePath(@source VARCHAR(MAX))
RETURNS VARCHAR(MAX)
```

**Dependencies:** None (pure string manipulation)

**Referenced By - WHO references it:**
- **Potential Users:**
  - Path mirroring for m_upstream → m_downstream conversion
  - Reverse lineage display

**Complexity:** 3/10  
**Criticality:** LOW - Utility function  
**PostgreSQL Notes:**
- Use string_to_array() + array_reverse() + array_to_string()
- Or regexp_split_to_array() pattern

---

#### 3.2 `dbo.RoundDateTime()`

**Purpose:** Rounds datetime values to specific intervals.

**Dependencies:** None (pure date math)  
**Referenced By:** Date rounding in queries/reports  
**Complexity:** 2/10 | **Criticality:** LOW  
**PostgreSQL Notes:** Use date_trunc() or custom interval rounding

---

#### 3.3 `dbo.initCaps()`

**Purpose:** Converts string to InitCap format (Title Case).

**Dependencies:** None (string manipulation)  
**Referenced By:** Display formatting in applications  
**Complexity:** 3/10 | **Criticality:** LOW  
**PostgreSQL Notes:** Use initcap() built-in function

---

#### 3.4 `dbo.udf_datetrunc()`

**Purpose:** Date truncation utility.

**Dependencies:** None  
**Referenced By:** Date grouping in queries  
**Complexity:** 2/10 | **Criticality:** LOW  
**PostgreSQL Notes:** Use date_trunc() built-in function directly

---

## 🔗 Dependency Graph Summary

### Critical Function Call Chains

```
1. P0 Material Lineage Chain:
   dbo.AddArc / dbo.RemoveArc
   ├─> dbo.McGetUpStream()
   │   └─> VIEW translated
   │       └─> TABLES: material_transition, transition_material
   └─> dbo.McGetDownStream()
       └─> VIEW translated

2. P0 Reconciliation Chain:
   dbo.ReconcileMUpstream / dbo.ProcessSomeMUpstream
   └─> dbo.McGetUpStreamByList()
       ├─> TYPE GooList
       ├─> VIEW translated
       └─> TABLE goo (validation)

3. Mass Calculation Chain:
   Applications
   └─> dbo.GetUpstreamMasses()
       ├─> dbo.GetUnProcessedUpStream()
       │   └─> TABLE goo
       └─> dbo.McGetDownStream()
```

### View Dependencies Matrix

| View | Used By Functions | Purpose |
|------|-------------------|---------|
| `translated` | McGetUpStream, McGetDownStream, McGetUpStreamByList, McGetDownStreamByList | ⭐ CRITICAL - Unified material/transition view |
| `upstream` | GetUpStream family (inferred) | Legacy upstream view |
| `downstream` | GetDownStream family (inferred) | Legacy downstream view |

### Table Dependencies Matrix

| Table | Read By Functions | Purpose |
|-------|-------------------|---------|
| `goo` | GetUpStream, GetDownStream, GetUpStreamContainers, GetDownStreamContainers, GetUnProcessedUpStream, GetUpstreamMasses, McGetUpStreamByList, Get*Experiment*, GetFermentationFatSmurf | ⭐ CRITICAL - Main material table |
| `goo_relationship` | GetUpStream, GetDownStream, GetUpStreamFamily, GetDownStreamFamily | HIGH - Explicit parent-child relationships |
| `material_transition` | (via VIEW translated) | ⭐ CRITICAL - Parent→Transition edges |
| `transition_material` | (via VIEW translated) | ⭐ CRITICAL - Transition→Material edges |
| `container` | GetUpStreamContainers, GetDownStreamContainers | MEDIUM - Container filtering |
| `robot_log*` | GetReadCombos, GetTransferCombos, GetSampleTime | MEDIUM - Automation logs |
| `hermes.run` | Get*Experiment*, Get*Hermes* | MEDIUM - Experiment data |
| `fatsmurf` | GetFermentationFatSmurf | MEDIUM - Fermentation data |

### Type Dependencies Matrix

| Type | Used By Functions | Purpose |
|------|-------------------|---------|
| `GooList` | McGetUpStreamByList, McGetDownStreamByList | ⭐ CRITICAL - Batch processing TVP |

---

## 🎯 Critical Observations & Recommendations

### 1. **McGet* Family is Core Migration Priority**
- **Impact:** Called by ALL P0 stored procedures (AddArc, RemoveArc, ReconcileMUpstream)
- **Risk:** Any conversion errors cascade to entire lineage system
- **Recommendation:** 
  - Migrate McGet* functions FIRST in Lote 2 migration
  - Create comprehensive test suite comparing SQL Server vs PostgreSQL outputs
  - Test with production-scale material counts (stress testing)

### 2. **VIEW translated is Single Point of Dependency**
- **Impact:** 4 CRITICAL functions depend on this single view
- **Risk:** View performance = function performance
- **Recommendation:**
  - Analyze `translated` view definition (Lote 3)
  - Consider MATERIALIZED VIEW in PostgreSQL for performance
  - Add appropriate indexes on source tables (material_transition, transition_material)

### 3. **GooList Type Conversion Strategy Required**
- **Impact:** Used by batch processing functions (P0/P1 priority)
- **PostgreSQL Options:**
  1. **TEMPORARY TABLE** (recommended) - Compatible with existing logic
  2. **ARRAY[]** - Simpler but requires function signature changes
  3. **JSONB** - Modern but more refactoring needed
- **Recommendation:** Use TEMPORARY TABLE pattern for minimal code changes

### 4. **Cursor Usage Must Be Refactored**
- **Function:** GetUpstreamMasses() uses T-SQL CURSOR
- **Issue:** PostgreSQL cursors have different semantics and performance characteristics
- **Recommendation:**
  - Refactor to set-based operations using CTEs or window functions
  - Test mass calculation accuracy after refactoring
  - Consider caching results for frequently-accessed materials

### 5. **Nested Sets Model is Fully Supported**
- **Good News:** PostgreSQL handles nested sets (tree_left_key/tree_right_key) natively
- **Enhancement Opportunity:** Consider ltree extension for modern hierarchy queries
- **Recommendation:**
  - Migrate Get* legacy functions AS-IS initially
  - Evaluate ltree conversion in Phase 2 optimization

### 6. **WITH (NOLOCK) Hints Must Be Removed**
- **Impact:** McGetUpStream, McGetDownStream use SQL Server locking hints
- **PostgreSQL:** No equivalent; PostgreSQL uses MVCC (Multi-Version Concurrency Control)
- **Recommendation:**
  - Remove all `WITH (NOLOCK)` during conversion
  - Adjust transaction isolation level at connection level if needed
  - Test concurrent query behavior

### 7. **Function Return Type Differences**
- **SQL Server:** Uses table variables (@Paths TABLE)
- **PostgreSQL:** Use `RETURNS TABLE` or `SETOF custom_type`
- **Recommendation:**
  - Define custom composite types for complex return structures
  - Use `RETURNS TABLE(col1 type1, col2 type2...)` for simpler cases

---

## 📊 Migration Priority Matrix

### P0 - CRITICAL (Immediate - Sprint 9-10)

| Function | Reason | SP Dependencies | Complexity |
|----------|--------|-----------------|------------|
| McGetUpStream | Called by P0 SPs (AddArc, RemoveArc) | AddArc, RemoveArc | 8/10 |
| McGetDownStream | Called by P0 SPs (AddArc, RemoveArc) | AddArc, RemoveArc | 8/10 |
| McGetUpStreamByList | Called by P0/P1 SPs (ReconcileMUpstream) | ReconcileMUpstream, ProcessSomeMUpstream | 9/10 |
| McGetDownStreamByList | Mirror of McGetUpStreamByList | Future batch operations | 8/10 |

### P1 - HIGH (Next Sprint 11-12)

| Function | Reason | Dependencies | Complexity |
|----------|--------|--------------|------------|
| GetUpStream | Used by views and legacy SPs | ProcessDirtyTrees, views | 7/10 |
| GetDownStream | Mirror of GetUpStream | ProcessDirtyTrees, views | 7/10 |
| GetUpStreamFamily | Extended hierarchy traversal | ProcessDirtyTrees | 6/10 |
| GetDownStreamFamily | Mirror of GetUpStreamFamily | ProcessDirtyTrees | 6/10 |
| GetUpStreamContainers | Container-filtered queries | Applications | 6/10 |
| GetDownStreamContainers | Mirror of GetUpStreamContainers | Applications | 6/10 |
| GetUnProcessedUpStream | Status filtering | GetUpstreamMasses | 5/10 |

### P2 - MEDIUM (Sprint 13-14)

| Function | Reason | Usage | Complexity |
|----------|--------|-------|------------|
| GetUpstreamMasses | Complex but isolated function | Inventory reports | 9/10 (cursor!) |
| GetReadCombos | Robot automation queries | Automation systems | 7/10 |
| GetTransferCombos | Robot automation queries | Automation systems | 7/10 |
| GetSampleTime | Sample timing calculations | Lab systems | 8/10 |
| GetFermentationFatSmurf | Fermentation lookup | Fermentation module | 5/10 |
| McGetUpDownStream | Combined traversal | Applications | 4/10 |

### P3 - LOW (Sprint 15+)

| Function | Reason | Usage | Complexity |
|----------|--------|-------|------------|
| GetExperiment | Simple ID extraction | Applications | 3/10 |
| GetHermesExperiment | Simple ID extraction | Applications | 3/10 |
| GetHermesRun | Simple ID extraction | Applications | 3/10 |
| GetHermesUid | Simple ID extraction | Applications | 3/10 |
| ReversePath | String utility | Path mirroring | 3/10 |
| RoundDateTime | Date utility | Date formatting | 2/10 |
| initCaps | String utility | Display formatting | 3/10 |
| udf_datetrunc | Date utility | Date grouping | 2/10 |

---

## 🔄 Migration Strategy Recommendations

### Phase 1: Core Functions (P0)
**Timeline:** Sprint 9-10 (2 weeks)
1. Migrate McGet* family (4 functions)
2. Convert GooList TVP to TEMPORARY TABLE pattern
3. Remove `WITH (NOLOCK)` hints
4. Test with production-scale data
5. Performance benchmark vs SQL Server

### Phase 2: Legacy Hierarchy (P1)
**Timeline:** Sprint 11-12 (2 weeks)
1. Migrate Get* family (7 functions)
2. Validate nested sets model behavior
3. Test integration with existing views
4. Consider ltree extension evaluation

### Phase 3: Complex & Specialized (P2)
**Timeline:** Sprint 13-14 (2 weeks)
1. Refactor GetUpstreamMasses (cursor → set-based)
2. Migrate robot automation functions
3. Test calculation accuracy
4. Performance optimization

### Phase 4: Utilities (P3)
**Timeline:** Sprint 15 (1 week)
1. Migrate utility functions
2. Use PostgreSQL built-ins where possible
3. Minimal testing required

---

## 🔗 Integration with Lote 1 Analysis

### Functions → Stored Procedures Dependencies

**From Lote 1, we know:**

| SP (Lote 1) | Priority | Calls Functions |
|-------------|----------|-----------------|
| dbo.AddArc | P0 | McGetUpStream, McGetDownStream |
| dbo.RemoveArc | P0 | McGetUpStream, McGetDownStream (commented) |
| dbo.ReconcileMUpstream | P0 | McGetUpStreamByList |
| dbo.ProcessSomeMUpstream | P1 | McGetUpStreamByList |
| dbo.ProcessDirtyTrees | P1 | GetUpStream family (inferred) |

**This confirms:**
- McGet* functions MUST be migrated before AddArc/RemoveArc testing
- McGetUpStreamByList MUST be migrated before ReconcileMUpstream testing
- Functions are on critical path for P0 SP migration

---

## 🔄 Next Steps

### Immediate Actions:
1. ✅ **Lote 1 Complete:** 21 Stored Procedures analyzed
2. ✅ **Lote 2 Complete:** 24 Functions analyzed
3. ⏭️ **Lote 3:** Analyze 22 Views in `Views/` directory (focus on `translated` view)
4. ⏭️ **Lote 4:** Analyze 1 Type (`GooList`) and create final dependency tree

### Questions for Stakeholders:
1. What is the typical batch size for McGetUpStreamByList calls?
2. Are Get* legacy functions still actively used or can they be deprecated?
3. What is the acceptable performance baseline for GetUpstreamMasses?
4. Can we access production query statistics for these functions?

---

## 📌 Document Metadata

**Version:** 1.0  
**Last Updated:** 2025-12-15  
**Next Review:** Lote 3 - Views Analysis  
**Maintained By:** Pierre Ribeiro (Senior DBA/DBRE)  
**Project:** Perseus Database Migration - SQL Server → PostgreSQL 17  
**Dependency:** Lote 1 (Stored Procedures Analysis)

---

**End of Lote 2 Analysis**
