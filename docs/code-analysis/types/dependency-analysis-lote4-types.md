# 📊 SQL Server Dependency Analysis - Lote 4: User-Defined Types
## Perseus Database Migration Project - DinamoTech

**Analysis Date:** 2025-12-15  
**Analyst:** Pierre Ribeiro + Claude (Database Expert)  
**Scope:** 1 User-Defined Table Type in Perseus Database  
**Repository:** pierreribeiro/olympios

---

## 🎯 Executive Summary

This document provides comprehensive dependency analysis of the user-defined table type (TVP - Table-Valued Parameter) in the Perseus SQL Server database. The type has been analyzed to identify:
- **Complete structure and definition**
- **WHAT uses it** (Functions and Stored Procedures)
- **Migration complexity and strategies**
- **PostgreSQL conversion options with detailed implementation**

### Key Findings

| Category | Detail | Impact |
|----------|--------|--------|
| **Total Types Analyzed** | 1 | GooList (100% coverage) |
| **Type Category** | Table-Valued Parameter (TVP) | No native PostgreSQL equivalent |
| **Structure** | Single column: uid NVARCHAR(50), PRIMARY KEY | Ensures uniqueness in batch operations |
| **Used by P0 Functions** | 2 | McGetUpStreamByList, McGetDownStreamByList |
| **Used by P0 Stored Procedures** | 2 | ReconcileMUpstream, ProcessSomeMUpstream |
| **PostgreSQL Conversion Options** | 3 | ARRAY of Composite Types, TEMP TABLE, JSONB, ARRAY, JSONB |
| **Migration Complexity** | HIGH | Requires function signature changes |

### Critical Discovery

**Type `GooList` is CRITICAL for batch processing operations:**
- Used by P0 reconciliation engine (`ReconcileMUpstream`) ⭐⭐⭐
- Used by P1 batch processor (`ProcessSomeMUpstream`) ⭐⭐
- Enables efficient batch lineage calculation for multiple materials simultaneously
- Has PRIMARY KEY constraint ensuring uniqueness (no duplicate UIDs)
- PostgreSQL has NO native Table-Valued Parameters
- Conversion strategy MUST be decided before function migration
- Recommended: ARRAY of Composite Types pattern (OPTION 4) - hybrid approach combining array parameters with internal temp tables

---

## 📋 Detailed Type Analysis

### 1. User-Defined Table Type ⭐⭐⭐ **P0 CRITICAL**

#### 1.1 `dbo.GooList` ⭐⭐⭐ **TABLE-VALUED PARAMETER TYPE**

**Purpose:** Table-Valued Parameter for batch material processing operations. Enables passing a set of material UIDs to functions/procedures for bulk lineage calculations.

**Complete SQL Server Definition:**
```sql
CREATE TYPE [dbo].[GooList] AS TABLE(
    [uid] [nvarchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    PRIMARY KEY CLUSTERED 
(
    [uid] ASC
)WITH (IGNORE_DUP_KEY = OFF)
)
GO
```

**Structure Details:**

| Component | Value | Significance |
|-----------|-------|--------------|
| **Column Name** | `uid` | Material unique identifier |
| **Data Type** | `NVARCHAR(50)` | Unicode string, max 50 characters |
| **Collation** | `SQL_Latin1_General_CP1_CI_AS` | Case-insensitive, accent-sensitive |
| **Constraint** | `NOT NULL` | UIDs required, no nulls allowed |
| **Primary Key** | `CLUSTERED` on `uid ASC` | Ensures uniqueness, orders by uid |
| **Duplicate Handling** | `IGNORE_DUP_KEY = OFF` | Errors on duplicate inserts |

**Key Characteristics:**

1. **PRIMARY KEY CLUSTERED:**
   - Ensures NO duplicate UIDs in batch
   - Orders data by uid (performance optimization)
   - Physical storage ordering in SQL Server

2. **IGNORE_DUP_KEY = OFF:**
   - If duplicate uid inserted → ERROR raised
   - Strict uniqueness enforcement
   - Caller must ensure unique UIDs before passing

3. **NVARCHAR vs VARCHAR:**
   - NVARCHAR = Unicode (2 bytes per character)
   - Supports international characters
   - PostgreSQL: TEXT or VARCHAR (UTF-8 by default)

4. **READONLY Parameter Semantics:**
   - TVPs are always READONLY in SQL Server
   - Cannot be modified inside function/procedure
   - Input-only, no output capability

**Dependencies - WHAT it references:**
- **None** - It's a type definition, doesn't reference other objects

**Referenced By - WHO references it:**

**Functions (from Lote 2):**

1. **`dbo.McGetUpStreamByList()`** ⭐⭐⭐ **P0 CRITICAL**
   - **Signature:** `CREATE FUNCTION McGetUpStreamByList(@StartPoint GooList READONLY)`
   - **Usage Pattern:**
     ```sql
     -- Join to table parameter
     FROM translated pt
     JOIN @StartPoint sp ON sp.uid = pt.destination_material
     
     -- Select from table parameter  
     INSERT INTO @Paths
     SELECT sp.uid, sp.uid, NULL, '', 0
     FROM @StartPoint sp
     WHERE EXISTS (SELECT 1 FROM goo WHERE sp.uid = goo.uid)
     ```
   - **Purpose:** Batch upstream lineage calculation for multiple materials
   - **Performance:** Processes N materials in single call vs N individual calls
   - **Complexity:** 9/10

2. **`dbo.McGetDownStreamByList()`** ⭐⭐ **P1 HIGH**
   - **Signature:** `CREATE FUNCTION McGetDownStreamByList(@StartPoint GooList READONLY)`
   - **Usage Pattern:** Similar to McGetUpStreamByList (downstream direction)
   - **Purpose:** Batch downstream lineage calculation
   - **Complexity:** 8/10

**Stored Procedures (from Lote 1):**

1. **`dbo.ReconcileMUpstream`** ⭐⭐⭐ **P0 CRITICAL**
   - **Usage Context:**
     ```sql
     DECLARE @dirty_in GooList
     DECLARE @clean_in GooList
     
     -- Populate dirty_in with UIDs from m_upstream_dirty_leaves
     INSERT INTO @dirty_in (uid)
     SELECT TOP 10 uid FROM m_upstream_dirty_leaves
     
     -- Call function with two GooList parameters
     EXEC McGetUpStreamByList @dirty_in, @clean_in
     ```
   - **Pattern:** Creates TWO GooList variables (dirty + clean materials)
   - **Business Impact:** Core reconciliation engine for material lineage
   - **Frequency:** Scheduled job (high frequency)

2. **`dbo.ProcessSomeMUpstream`** ⭐⭐ **P1 HIGH**
   - **Usage Context:**
     ```sql
     DECLARE @dirty_in GooList READONLY
     DECLARE @clean_in GooList READONLY
     
     -- Filter and process batch of materials
     -- Calls McGetUpStreamByList(@dirty_in, @clean_in)
     ```
   - **Pattern:** Batch processing with filtered material lists
   - **Business Impact:** Bulk update processor for upstream relationships
   - **Frequency:** On-demand or scheduled

**Typical Batch Sizes (inferred from code):**
- ReconcileMUpstream: TOP 10 materials per batch
- ProcessSomeMUpstream: Variable (could be larger batches)
- Function design: Supports any batch size (no hardcoded limits)

**Complexity Score:** 5/10 (simple structure, complex migration implications)  
**Business Criticality:** P0 CRITICAL - Used by core batch operations  
**Migration Impact:** HIGH - No native PostgreSQL equivalent

---

## 🔗 Dependency Graph Summary

### Complete Type Usage Chain

```
1. P0 Reconciliation Chain:
   Scheduled Job (Reconciliation)
   └─> SP: dbo.ReconcileMUpstream ⭐⭐⭐
       ├─> DECLARE @dirty_in GooList
       ├─> DECLARE @clean_in GooList
       └─> FUNCTION: McGetUpStreamByList(@dirty_in, @clean_in) ⭐⭐⭐
           └─> VIEW: translated ⭐⭐⭐⭐
               └─> TABLES: material_transition, transition_material

2. P1 Batch Processing Chain:
   Batch Job / Application
   └─> SP: dbo.ProcessSomeMUpstream ⭐⭐
       ├─> DECLARE @dirty_in GooList READONLY
       ├─> DECLARE @clean_in GooList READONLY
       └─> FUNCTION: McGetUpStreamByList(@dirty_in, @clean_in) ⭐⭐⭐

3. Future/Optional Chain:
   Applications
   └─> FUNCTION: McGetDownStreamByList(@StartPoint GooList) ⭐⭐
       └─> VIEW: translated ⭐⭐⭐⭐
```

### Usage Matrix

| Object | Type | Uses GooList | Pattern | Priority |
|--------|------|--------------|---------|----------|
| McGetUpStreamByList | Function | ✅ Parameter | JOIN + SELECT | ⭐⭐⭐ P0 |
| McGetDownStreamByList | Function | ✅ Parameter | JOIN + SELECT | ⭐⭐ P1 |
| ReconcileMUpstream | SP | ✅ Local Variable | DECLARE + INSERT + Pass to function | ⭐⭐⭐ P0 |
| ProcessSomeMUpstream | SP | ✅ Local Variable | DECLARE + INSERT + Pass to function | ⭐⭐ P1 |

---

## 🎯 Critical Observations & PostgreSQL Migration Strategies

### 1. **No Native Table-Valued Parameters in PostgreSQL** ⚠️

**Issue:**
- SQL Server: TVPs are first-class database objects (CREATE TYPE)
- PostgreSQL: No native equivalent for TABLE types as parameters

**Impact:**
- Function signatures must change
- Calling code must change
- Three conversion strategies available (detailed below)

---

### 2. **PostgreSQL Conversion Strategy Analysis**

We have THREE options for converting GooList to PostgreSQL. Each has tradeoffs:

---

#### **OPTION 1: TEMPORARY TABLE Pattern**

**Implementation:**

```sql
-- PostgreSQL: Functions receive table name as TEXT parameter
CREATE OR REPLACE FUNCTION mcget_upstream_by_list(
    p_temp_table_name TEXT  -- Name of temp table with UIDs
)
RETURNS TABLE (
    start_point VARCHAR(50),
    end_point VARCHAR(50),
    neighbor VARCHAR(50),
    path VARCHAR(500),
    level INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Query the temp table by name using EXECUTE
    RETURN QUERY EXECUTE format('
        WITH RECURSIVE upstream AS (
            SELECT 
                pt.destination_material AS start_point,
                pt.destination_material AS parent,
                pt.source_material AS child,
                ''/''::VARCHAR(500) AS path,
                1 AS level
            FROM translated pt
            JOIN %I sp ON sp.uid = pt.destination_material
            UNION ALL
            SELECT 
                r.start_point,
                pt.destination_material,
                pt.source_material,
                (r.path || r.child || ''/'')::VARCHAR(500),
                r.level + 1
            FROM translated pt
            JOIN upstream r ON pt.destination_material = r.child
            WHERE pt.destination_material != pt.source_material
        )
        SELECT start_point, child AS end_point, parent, path, level 
        FROM upstream
        UNION ALL
        SELECT uid, uid, NULL, '''', 0 
        FROM %I sp
        WHERE EXISTS (SELECT 1 FROM goo WHERE sp.uid = goo.uid)
    ', p_temp_table_name, p_temp_table_name);
END;
$$;

-- Calling pattern from stored procedure:
CREATE OR REPLACE PROCEDURE reconcile_m_upstream()
LANGUAGE plpgsql
AS $$
BEGIN
    -- Create temp table (session-scoped)
    CREATE TEMP TABLE temp_dirty_in (
        uid VARCHAR(50) NOT NULL PRIMARY KEY
    ) ON COMMIT DROP;
    
    CREATE TEMP TABLE temp_clean_in (
        uid VARCHAR(50) NOT NULL PRIMARY KEY
    ) ON COMMIT DROP;
    
    -- Populate temp tables
    INSERT INTO temp_dirty_in (uid)
    SELECT uid FROM m_upstream_dirty_leaves LIMIT 10;
    
    -- Call function with temp table names
    PERFORM * FROM mcget_upstream_by_list('temp_dirty_in');
    
    -- Temp tables auto-dropped at transaction end
END;
$$;
```

**Pros:**
- ✅ Most similar to SQL Server behavior
- ✅ Supports PRIMARY KEY constraints (uniqueness)
- ✅ Best performance for large batches (indexed temp table)
- ✅ Natural SQL syntax (JOIN to temp table)
- ✅ Session-scoped (isolated between connections)

**Cons:**
- ❌ Function signature changes (table name vs data)
- ❌ Requires EXECUTE + format() for dynamic SQL
- ❌ More verbose calling code
- ❌ Temp table management overhead

**When to Use:** 
- Large batch sizes (100+ UIDs)
- Complex queries (multiple JOINs to same batch)
- Need for PRIMARY KEY constraint enforcement

---

#### **OPTION 2: ARRAY Parameter** 🔶 **SIMPLER BUT LIMITED**

**Implementation:**

```sql
-- PostgreSQL: Functions receive ARRAY of VARCHAR
CREATE OR REPLACE FUNCTION mcget_upstream_by_list(
    p_uids VARCHAR(50)[]  -- Array of UIDs
)
RETURNS TABLE (
    start_point VARCHAR(50),
    end_point VARCHAR(50),
    neighbor VARCHAR(50),
    path VARCHAR(500),
    level INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    WITH RECURSIVE upstream AS (
        SELECT 
            pt.destination_material AS start_point,
            pt.destination_material AS parent,
            pt.source_material AS child,
            '/'::VARCHAR(500) AS path,
            1 AS level
        FROM translated pt
        WHERE pt.destination_material = ANY(p_uids)  -- Array membership
        UNION ALL
        SELECT 
            r.start_point,
            pt.destination_material,
            pt.source_material,
            (r.path || r.child || '/')::VARCHAR(500),
            r.level + 1
        FROM translated pt
        JOIN upstream r ON pt.destination_material = r.child
        WHERE pt.destination_material != pt.source_material
    )
    SELECT start_point, child AS end_point, parent, path, level 
    FROM upstream
    UNION ALL
    SELECT uid, uid, NULL::VARCHAR(50), '', 0
    FROM unnest(p_uids) AS uid
    WHERE EXISTS (SELECT 1 FROM goo WHERE goo.uid = uid);
END;
$$;

-- Calling pattern from stored procedure:
CREATE OR REPLACE PROCEDURE reconcile_m_upstream()
LANGUAGE plpgsql
AS $$
DECLARE
    v_dirty_uids VARCHAR(50)[];
    v_clean_uids VARCHAR(50)[];
BEGIN
    -- Populate arrays
    SELECT ARRAY_AGG(uid) INTO v_dirty_uids
    FROM (SELECT uid FROM m_upstream_dirty_leaves LIMIT 10) t;
    
    v_clean_uids := ARRAY[]::VARCHAR(50)[];  -- Empty array
    
    -- Call function with arrays
    PERFORM * FROM mcget_upstream_by_list(v_dirty_uids);
END;
$$;
```

**Pros:**
- ✅ Simpler syntax (no temp table management)
- ✅ Cleaner function signature
- ✅ Native PostgreSQL array operations (ANY, unnest)
- ✅ Less code overall

**Cons:**
- ❌ No PRIMARY KEY constraint (duplicates allowed)
- ❌ Performance degrades with large arrays (1000+ elements)
- ❌ Memory usage increases with array size
- ❌ Less SQL-like (unnest() is less intuitive than JOIN)

**When to Use:**
- Small to medium batch sizes (<100 UIDs)
- Simple queries (single use of parameter)
- Uniqueness not critical (handled by caller)

---

#### **OPTION 3: JSONB Parameter** 🔷 **MODERN BUT OVERKILL**

**Implementation:**

```sql
-- PostgreSQL: Functions receive JSONB array
CREATE OR REPLACE FUNCTION mcget_upstream_by_list(
    p_uids_json JSONB  -- JSONB array: ["m123", "m456", ...]
)
RETURNS TABLE (
    start_point VARCHAR(50),
    end_point VARCHAR(50),
    neighbor VARCHAR(50),
    path VARCHAR(500),
    level INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    WITH uids AS (
        SELECT jsonb_array_elements_text(p_uids_json) AS uid
    ),
    RECURSIVE upstream AS (
        SELECT 
            pt.destination_material AS start_point,
            pt.destination_material AS parent,
            pt.source_material AS child,
            '/'::VARCHAR(500) AS path,
            1 AS level
        FROM translated pt
        JOIN uids sp ON sp.uid = pt.destination_material
        UNION ALL
        SELECT 
            r.start_point,
            pt.destination_material,
            pt.source_material,
            (r.path || r.child || '/')::VARCHAR(500),
            r.level + 1
        FROM translated pt
        JOIN upstream r ON pt.destination_material = r.child
        WHERE pt.destination_material != pt.source_material
    )
    SELECT start_point, child AS end_point, parent, path, level 
    FROM upstream
    UNION ALL
    SELECT uid, uid, NULL::VARCHAR(50), '', 0
    FROM uids
    WHERE EXISTS (SELECT 1 FROM goo WHERE goo.uid = uids.uid);
END;
$$;

-- Calling pattern:
CREATE OR REPLACE PROCEDURE reconcile_m_upstream()
LANGUAGE plpgsql
AS $$
DECLARE
    v_dirty_json JSONB;
BEGIN
    -- Build JSONB array
    SELECT jsonb_agg(uid) INTO v_dirty_json
    FROM (SELECT uid FROM m_upstream_dirty_leaves LIMIT 10) t;
    
    -- Call function
    PERFORM * FROM mcget_upstream_by_list(v_dirty_json);
END;
$$;
```

**Pros:**
- ✅ Modern, flexible format
- ✅ Good for REST API integration
- ✅ Supports complex structures (if needed in future)
- ✅ JSON validation available

**Cons:**
- ❌ Overkill for simple list of UIDs
- ❌ Extra serialization/deserialization overhead
- ❌ Less readable than ARRAY or temp table
- ❌ No PRIMARY KEY constraint

**When to Use:**
- API-driven architecture (REST/JSON)
- Future extensibility needed (add metadata to UIDs)
- Already using JSONB heavily in application

---

#### OPTION 4: ARRAY of Composite Types Parameter ⭐ RECOMMENDED

**Implementation:** 

```sql
-- PostgreSQL: Functions receive ARRAY of VARCHAR
CREATE OR REPLACE FUNCTION mcgetupstreambylist(
    p_uids perseus.goolist[]  -- Array of composite type goolist
)
RETURNS TABLE (
    start_point VARCHAR(50),
    end_point VARCHAR(50),
    neighbor VARCHAR(50),
    path VARCHAR(500),
    level INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
	DROP TABLE IF EXISTS v_starting_point;
	-- create temp table to hold parameter values
	CREATE TEMP TABLE IF NOT EXISTS v_starting_point (
		uid VARCHAR(50),
		PRIMARY KEY (uid)
	) ON COMMIT DROP;

	INSERT INTO v_starting_point
	SELECT DISTINCT goo.uid
	FROM UNNEST(p_starting_point) AS goo;

	RETURN QUERY
	WITH RECURSIVE upstream (start_point, parent, child, path, level)
	AS ( 
		SELECT 
			CAST(pt.destination_material AS VARCHAR(50)) AS start_point,
			CAST(pt.destination_material AS VARCHAR(50)) AS parent,
			CAST(pt.source_material AS VARCHAR(50)) AS child,
			CAST('/' AS VARCHAR(500)) AS path,
			1 AS level
		FROM perseus.translated pt 
			JOIN v_starting_point sp ON sp.uid = pt.destination_material

		UNION ALL
	   
		SELECT 
			r.start_point, 
			CAST(pt.destination_material AS VARCHAR(50)) AS parent, 
			CAST(pt.source_material AS VARCHAR(50)) AS child,
		  	CAST(r.path || r.child || '/' AS VARCHAR(500)) AS path, 
		  	r.level + 1 AS level
		FROM perseus.translated pt
			JOIN upstream r ON pt.destination_material = r.child
		WHERE pt.destination_material != pt.source_material
	)
	SELECT u.start_point, u.child AS end_point, u.parent, u.path, u.level 
	FROM upstream u
	UNION
	SELECT 
		CAST(sp.uid AS VARCHAR(50)) AS start_point, 
		CAST(sp.uid AS VARCHAR(50)) AS end_point, 
		CAST(NULL AS VARCHAR(50)) AS parent, 
		CAST('' AS VARCHAR(500)) AS path, 
		CAST(0 AS INT) AS LEVEL 
	FROM v_starting_point sp
	WHERE EXISTS (SELECT 1 FROM perseus.goo WHERE sp.uid = goo.uid);
END;
$$;

-- Calling pattern from stored procedure:
CREATE OR REPLACE PROCEDURE reconcile_m_upstream()
LANGUAGE plpgsql
AS $$
DECLARE
    v_dirty_uids perseus.goolist[];
    v_clean_uids perseus.googlist[];
BEGIN
    -- Populate arrays
    SELECT ARRAY_AGG(uid) INTO v_dirty_uids
    FROM (SELECT uid FROM m_upstream_dirty_leaves LIMIT 10) t;

    v_dirty_uids := ARRAY(SELECT ROW(g.uid)::perseus.goolist FROM '"var_dirty$aws$tmp"' g)

    -- Call function with arrays

    INSERT INTO new_upstream (start_point, end_point, path, level)
    SELECT start_point, end_point, path, level
    FROM perseus.mcgetupstreambylist(v_dirty_uids);

END;
$$;
```

**Pros:**
- ✅ Syntax complicity similar to option 2 (composite type instead of VARCHAR)
- ✅ Native PostgreSQL array operations (ANY, unnest)
- ✅ Less code overall

**Cons:**
- ❌ No PRIMARY KEY constraint (duplicates allowed)
- ❌ Extra serialization/deserialization overhead
- ❌ Memory usage increases with array size
- ❌ Less SQL-like (unnest() is less intuitive than JOIN)

**When to Use:**
- Small to medium batch sizes (<100 UIDs)
- Simple queries (single use of parameter)
- Uniqueness not critical (handled by caller)
---

### 3. **Recommended Strategy: ARRAY of Composite Types Parameter (OPTION 4)** ⭐

**Rationale:**

1. **Hybrid Approach - Best of Both Worlds:**
   - Combines native PostgreSQL array operations with temp table performance
   - Array parameter at function signature level (clean interface)
   - Internal temp table for JOIN performance and PRIMARY KEY enforcement
   - Maintains SQL Server TVP semantics while leveraging PostgreSQL strengths

2. **Performance Optimization:**
   - UNNEST() converts array to temp table in single operation (O(n) linear time)
   - PRIMARY KEY on internal temp table enables indexed lookups
   - Query planner optimizes JOINs against temp table efficiently
   - No external temp table management overhead (handled internally)
   - Memory-efficient: temp table dropped automatically at function end

3. **Code Maintainability:**
   - Clean function signature: `mcgetupstreambylist(p_uids perseus.goolist[])`
   - No dynamic SQL (EXECUTE/format) required
   - Caller uses familiar ARRAY_AGG() pattern from standard SQL
   - Internal temp table implementation hidden from callers
   - Easy to debug: temp table queryable during function execution
   - Type-safe: `perseus.goolist[]` provides compile-time validation

4. **Future-Proof Architecture:**
   - Composite type `perseus.goolist` can evolve (add columns without breaking callers)
   - Supports extensibility: add metadata fields (timestamp, source_system, etc.)
   - Pattern reusable for other batch operations across codebase
   - Compatible with PostgreSQL array functions (array_length, array_append, etc.)
   - Migration path: if performance issues arise, internals can be optimized without changing external API

**Implementation Plan:**

**Phase 1: Create Composite Type**
```sql
-- Step 1: Define composite type matching SQL Server GooList structure
CREATE TYPE perseus.goolist AS (
    uid VARCHAR(50)
);

-- Step 2: Validate type creation
SELECT ROW('m123')::perseus.goolist;
-- Expected: ("m123")

-- Step 3: Test array creation
SELECT ARRAY[ROW('m123')::perseus.goolist, ROW('m456')::perseus.goolist];
-- Expected: {"(m123)","(m456)"}
```

**Validation Criteria:**
- ✅ Type created in `perseus` schema
- ✅ Can cast VARCHAR to goolist composite type
- ✅ Can create arrays of goolist type
- ✅ No conflicts with existing objects

---

**Phase 2: Convert McGetUpStreamByList Function**
```sql
-- Step 1: Create function with array parameter
CREATE OR REPLACE FUNCTION perseus.mcgetupstreambylist(
    p_uids perseus.goolist[]  -- Array of composite type goolist
)
RETURNS TABLE (
    start_point VARCHAR(50),
    end_point VARCHAR(50),
    neighbor VARCHAR(50),
    path VARCHAR(500),
    level INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Step 2: Create internal temp table from array parameter
    CREATE TEMP TABLE IF NOT EXISTS v_starting_point (
        uid VARCHAR(50) NOT NULL,
        PRIMARY KEY (uid)
    ) ON COMMIT DROP;

    -- Step 3: Populate temp table from array using UNNEST
    -- DISTINCT ensures uniqueness even if caller passes duplicates
    INSERT INTO v_starting_point (uid)
    SELECT DISTINCT (goo).uid  -- Note: (goo).uid syntax to extract field from composite
    FROM UNNEST(p_uids) AS goo
    ON CONFLICT (uid) DO NOTHING;  -- Graceful handling of duplicates

    -- Step 4: Execute recursive CTE with JOIN to temp table
    RETURN QUERY
    WITH RECURSIVE upstream (start_point, parent, child, path, level) AS ( 
        -- Base case: direct parents from translated view
        SELECT 
            CAST(pt.destination_material AS VARCHAR(50)) AS start_point,
            CAST(pt.destination_material AS VARCHAR(50)) AS parent,
            CAST(pt.source_material AS VARCHAR(50)) AS child,
            CAST('/' AS VARCHAR(500)) AS path,
            1 AS level
        FROM perseus.translated pt 
        JOIN v_starting_point sp ON sp.uid = pt.destination_material
        
        UNION ALL
        
        -- Recursive case: traverse up the lineage tree
        SELECT 
            r.start_point, 
            CAST(pt.destination_material AS VARCHAR(50)) AS parent, 
            CAST(pt.source_material AS VARCHAR(50)) AS child,
            CAST(r.path || r.child || '/' AS VARCHAR(500)) AS path, 
            r.level + 1 AS level
        FROM perseus.translated pt
        JOIN upstream r ON pt.destination_material = r.child
        WHERE pt.destination_material != pt.source_material  -- Prevent cycles
    )
    -- Return all upstream paths
    SELECT u.start_point, u.child AS end_point, u.parent, u.path, u.level 
    FROM upstream u
    
    UNION
    
    -- Include starting points themselves (level 0)
    SELECT 
        CAST(sp.uid AS VARCHAR(50)) AS start_point, 
        CAST(sp.uid AS VARCHAR(50)) AS end_point, 
        CAST(NULL AS VARCHAR(50)) AS parent, 
        CAST('' AS VARCHAR(500)) AS path, 
        CAST(0 AS INT) AS level 
    FROM v_starting_point sp
    WHERE EXISTS (SELECT 1 FROM perseus.goo WHERE sp.uid = goo.uid);
    
    -- Note: Temp table v_starting_point automatically dropped at function end
END;
$$;
```

**Testing Steps:**
1. Test with single UID: `SELECT * FROM perseus.mcgetupstreambylist(ARRAY[ROW('m123')::perseus.goolist])`
2. Test with multiple UIDs: `SELECT * FROM perseus.mcgetupstreambylist(ARRAY[ROW('m123')::perseus.goolist, ROW('m456')::perseus.goolist])`
3. Test with duplicates: Verify ON CONFLICT handling
4. Test with empty array: `SELECT * FROM perseus.mcgetupstreambylist(ARRAY[]::perseus.goolist[])`
5. Compare results with SQL Server original function

---

**Phase 3: Update Stored Procedures**
```sql
-- Step 1: Modify ReconcileMUpstream to use array pattern
CREATE OR REPLACE PROCEDURE perseus.reconcile_m_upstream()
LANGUAGE plpgsql
AS $$
DECLARE
    v_dirty_uids perseus.goolist[];
    v_clean_uids perseus.goolist[];
    v_batch_size INTEGER := 10;  -- Configurable batch size
BEGIN
    -- Step 2: Populate array from m_upstream_dirty_leaves table
    -- ARRAY_AGG collects rows into array, ROW()::type casts to composite
    SELECT ARRAY_AGG(ROW(uid)::perseus.goolist)
    INTO v_dirty_uids
    FROM (
        SELECT uid 
        FROM perseus.m_upstream_dirty_leaves 
        LIMIT v_batch_size
    ) t;

    -- Step 3: Handle empty array case
    IF v_dirty_uids IS NULL OR array_length(v_dirty_uids, 1) = 0 THEN
        RAISE NOTICE 'No dirty materials to reconcile';
        RETURN;
    END IF;

    -- Step 4: Initialize clean array (empty initially)
    v_clean_uids := ARRAY[]::perseus.goolist[];

    -- Step 5: Call function with array parameters
    -- Function returns table, so use INSERT INTO or FOR loop
    INSERT INTO perseus.new_upstream (start_point, end_point, neighbor, path, level)
    SELECT start_point, end_point, neighbor, path, level
    FROM perseus.mcgetupstreambylist(v_dirty_uids);

    -- Step 6: Log reconciliation metrics
    RAISE NOTICE 'Reconciled % materials', array_length(v_dirty_uids, 1);
END;
$$;
```

**Testing Steps:**
1. Execute procedure in test environment
2. Verify INSERT INTO new_upstream has correct row count
3. Compare results with SQL Server ReconcileMUpstream output
4. Test with various batch sizes (10, 50, 100 UIDs)
5. Validate performance metrics

---

**Phase 4: Production-Scale Testing & Optimization**

**Step 1: Benchmark Testing**
```sql
-- Test script for various batch sizes
DO $$
DECLARE
    v_test_uids perseus.goolist[];
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
    v_duration INTERVAL;
    v_result_count INTEGER;
BEGIN
    -- Test batch size: 10 UIDs
    SELECT ARRAY_AGG(ROW(uid)::perseus.goolist) INTO v_test_uids
    FROM (SELECT uid FROM perseus.goo LIMIT 10) t;
    
    v_start_time := clock_timestamp();
    SELECT COUNT(*) INTO v_result_count 
    FROM perseus.mcgetupstreambylist(v_test_uids);
    v_end_time := clock_timestamp();
    v_duration := v_end_time - v_start_time;
    
    RAISE NOTICE 'Batch size 10: % results in %', v_result_count, v_duration;
    
    -- Repeat for batch sizes: 50, 100, 500, 1000
    -- Compare with SQL Server baseline performance
END $$;
```

**Step 2: Index Optimization**
- Monitor query plans: `EXPLAIN ANALYZE SELECT * FROM perseus.mcgetupstreambylist(...)`
- Verify temp table PRIMARY KEY is used efficiently
- Check for sequential scans (should be avoided)
- Ensure `translated` materialized view index is utilized

**Step 3: Memory Tuning**
```sql
-- Adjust work_mem if large batches cause disk spills
SET work_mem = '256MB';  -- Per-session setting

-- Monitor temp table usage
SELECT schemaname, tablename, pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename))
FROM pg_tables
WHERE tablename LIKE 'v_starting_point%';
```

**Step 4: Edge Case Testing**
- Empty array: `ARRAY[]::perseus.goolist[]`
- Single UID: `ARRAY[ROW('m123')::perseus.goolist]`
- Duplicate UIDs: Verify ON CONFLICT handling
- Non-existent UIDs: Should return empty resultset gracefully
- NULL values: Type system should prevent, but test anyway
- Very large batch (1000+ UIDs): Monitor memory and performance

**Step 5: Validation Criteria**
- ✅ Functional correctness: Results match SQL Server 100%
- ✅ Performance: Within 20% of SQL Server baseline
- ✅ No data loss: All upstream relationships preserved
- ✅ Stability: No memory leaks or temp table bloat
- ✅ Error handling: Graceful failure modes

---
---

### 4. **NVARCHAR vs VARCHAR Conversion**

**SQL Server:**
```sql
[uid] NVARCHAR(50)  -- Unicode, 2 bytes per character
```

**PostgreSQL:**
```sql
uid VARCHAR(50)  -- UTF-8 encoding (1-4 bytes per character)
-- OR
uid TEXT  -- Unlimited length, UTF-8
```

**Recommendation:** Use `VARCHAR(50)` in PostgreSQL
- PostgreSQL VARCHAR is already UTF-8 (Unicode support)
- No need for separate NVARCHAR type
- Same character limit (50)

---

### 5. **PRIMARY KEY Constraint Migration**

**SQL Server:**
```sql
PRIMARY KEY CLUSTERED (uid ASC)
WITH (IGNORE_DUP_KEY = OFF)
```

**PostgreSQL:**
```sql
-- For TEMP TABLE pattern:
CREATE TEMP TABLE temp_goolist (
    uid VARCHAR(50) NOT NULL PRIMARY KEY
);

-- CLUSTERED index not needed (PostgreSQL uses heap storage by default)
-- IGNORE_DUP_KEY = OFF is default (errors on duplicate)
```

**Behavior Differences:**
- SQL Server CLUSTERED = physical ordering
- PostgreSQL PRIMARY KEY = unique B-tree index (no physical clustering)
- Both enforce uniqueness equally
- Both error on duplicate inserts (IGNORE_DUP_KEY = OFF equivalent)

---

### 6. **Collation Handling**

**SQL Server:**
```sql
COLLATE SQL_Latin1_General_CP1_CI_AS
-- CI = Case Insensitive
-- AS = Accent Sensitive
```

**PostgreSQL:**
```sql
-- Set at database level or column level
uid VARCHAR(50) COLLATE "en_US.utf8"

-- For case-insensitive comparisons:
WHERE LOWER(uid) = LOWER(input_uid)

-- OR use citext extension:
CREATE EXTENSION citext;
uid CITEXT  -- Case-insensitive text type
```

**Recommendation:**
- Use standard VARCHAR(50) 
- Material UIDs are likely case-sensitive (e.g., 'm123' != 'M123')
- If case-insensitive needed, use LOWER() in WHERE clauses
- Avoid citext unless required (adds complexity)

---

## 📊 Migration Priority Matrix

### P0 - ABSOLUTE CRITICAL (Before Functions)

| Object | Reason | Depends On | Blocks |
|--------|--------|------------|--------|
| **GooList Type** | Used by P0 functions & SPs | None (foundational) | McGetUpStreamByList, McGetDownStreamByList, ReconcileMUpstream, ProcessSomeMUpstream |

**Timeline:** MUST be completed BEFORE McGet*ByList functions migration  
**Strategy Decision:** MUST be decided in Week 1  
**Testing:** Proof-of-concept with small batch (10 UIDs) then production scale (100+ UIDs)

---

## 🔄 Migration Strategy Recommendations

### Phase 1: Strategy Decision & POC

**Step 1: Decide on Conversion Strategy**
- **Recommendation:** ARRAY of Composite Types pattern (OPTION 4)
- **Validation:** Prototype all 3 options with 10-row test
- **Benchmark:** Compare performance (temp table vs array vs jsonb)
- **Decision Criteria:** Performance + code clarity + maintainability

**Step 2: Create PostgreSQL Type Wrapper (if temp table pattern)**
```sql
-- Helper function to create standard GooList temp table
CREATE OR REPLACE FUNCTION create_goolist_temp_table(p_table_name TEXT)
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
    EXECUTE format('
        CREATE TEMP TABLE IF NOT EXISTS %I (
            uid VARCHAR(50) NOT NULL PRIMARY KEY
        ) ON COMMIT DROP
    ', p_table_name);
END;
$$;

-- Usage in procedures:
PERFORM create_goolist_temp_table('temp_dirty_in');
INSERT INTO temp_dirty_in (uid) VALUES ('m123'), ('m456');
```

**Step 3: Test with Small Batch**
- Create temp table with 10 UIDs
- Call converted function
- Validate results match SQL Server
- Check performance metrics

---

### Phase 2: Function Migration

**Step 1: Convert McGetUpStreamByList**
```sql
-- Before (SQL Server):
CREATE FUNCTION McGetUpStreamByList(@StartPoint GooList READONLY)

-- After (PostgreSQL - temp table pattern):
CREATE FUNCTION mcget_upstream_by_list(p_temp_table_name TEXT)
```

**Step 2: Convert McGetDownStreamByList**
- Same pattern as McGetUpStreamByList

**Step 3: Integration Testing**
- Test with ReconcileMUpstream (P0 SP)
- Test with ProcessSomeMUpstream (P1 SP)
- Validate lineage calculation results

---

### Phase 3: Stored Procedure Migration

**Step 1: Update ReconcileMUpstream**
```sql
-- Add temp table creation logic
CREATE TEMP TABLE temp_dirty_in (...);
CREATE TEMP TABLE temp_clean_in (...);

-- Populate temp tables
INSERT INTO temp_dirty_in SELECT ...;

-- Call function with temp table name
PERFORM * FROM mcget_upstream_by_list('temp_dirty_in');
```

**Step 2: Update ProcessSomeMUpstream**
- Same pattern as ReconcileMUpstream

**Step 3: End-to-End Testing**
- Test scheduled job execution
- Test with production-scale batches
- Performance validation

---

### Phase 4: Performance Optimization

**Step 1: Batch Size Tuning**
- Current: TOP 10 per batch (ReconcileMUpstream)
- Test: 10, 50, 100, 500 UIDs per batch
- Find optimal batch size for PostgreSQL

**Step 2: Temp Table Index Strategy**
- PRIMARY KEY already creates B-tree index
- Consider additional indexes if needed
- Monitor query plans

**Step 3: Memory Configuration**
- Adjust work_mem for large batches
- Monitor temp table disk usage
- Tune temp_buffers if needed

---

## 🔗 Integration with Lotes 1, 2, 3 Analysis

### Complete Cross-Lote Dependency Validation

```
FOUNDATIONAL LAYER (Lote 4):
TYPE GooList ⭐⭐⭐⭐
│
├─> FUNCTIONS (Lote 2):
│   ├─> McGetUpStreamByList() ⭐⭐⭐ P0
│   └─> McGetDownStreamByList() ⭐⭐ P1
│       └─> VIEW translated ⭐⭐⭐⭐ (Lote 3)
│           └─> TABLES: material_transition, transition_material
│
└─> STORED PROCEDURES (Lote 1):
    ├─> ReconcileMUpstream ⭐⭐⭐ P0
    └─> ProcessSomeMUpstream ⭐⭐ P1
        └─> Call McGetUpStreamByList()
```

**Critical Path Impact:**
- GooList is at the FOUNDATION of the P0 critical path
- Must be migrated FIRST (before functions)
- Conversion strategy affects ALL dependent functions/SPs
- Any performance issues cascade to entire batch processing system

**Migration Order (STRICT):**
1. ✅ **Lote 3:** VIEW translated (MATERIALIZED VIEW)
2. ⏭️ **Lote 4:** TYPE GooList (TEMP TABLE pattern)
3. ⏭️ **Lote 2:** FUNCTIONS McGet*ByList (using temp tables)
4. ⏭️ **Lote 1:** SPs ReconcileMUpstream, ProcessSomeMUpstream

---

## 🔄 Next Steps

### Immediate Actions:
1. ✅ **Lote 1 Complete:** 21 Stored Procedures analyzed
2. ✅ **Lote 2 Complete:** 24 Functions analyzed
3. ✅ **Lote 3 Complete:** 22 Views analyzed
4. ✅ **Lote 4 Complete:** 1 Type (GooList) analyzed
5. ⏭️ **FINAL DOCUMENT:** Create consolidated dependency tree with visual Mermaid diagram

### Questions for Stakeholders:

1. **Batch Size Strategy:**
   - What is the typical batch size for ReconcileMUpstream? (currently TOP 10)
   - What is the maximum batch size expected in production?
   - Should we increase batch size for better performance?

2. **Performance Requirements:**
   - What is the acceptable execution time for batch processing?
   - Current SQL Server performance baseline?
   - SLA for reconciliation job completion?

3. **Testing Strategy:**
   - Can we get production data sample for testing? (anonymized UIDs)
   - What is the test environment setup timeline?
   - Who validates lineage calculation correctness?

4. **Conversion Strategy Preference:**
   - Do stakeholders have preference: TEMP TABLE vs ARRAY vs JSONB?
   - Any concerns about EXECUTE + format() dynamic SQL?
   - Application compatibility considerations?

---

## 📌 Document Metadata

**Version:** 1.1  
**Last Updated:** 2025-12-30  
**Next Review:** Final Consolidated Dependency Tree  
**Maintained By:** Pierre Ribeiro (Senior DBA/DBRE)  
**Project:** Perseus Database Migration - SQL Server → PostgreSQL 17  
**Dependencies:** Lote 1 (Stored Procedures), Lote 2 (Functions), Lote 3 (Views)

### 📝 Version History

**Version 1.1** (2025-12-30)
- ⭐ **MAJOR CHANGE:** Shifted recommendation from OPTION 1 (TEMP TABLE Pattern) to OPTION 4 (ARRAY of Composite Types)
- ✅ **ADDED:** Complete OPTION 4 implementation with detailed code examples
- ✅ **REWRITTEN:** Section 3 "Recommended Strategy" completely rewritten with new rationale and 4-phase implementation plan
- ✅ **UPDATED:** Comparison matrix expanded to include OPTION 4 with 13 comparison criteria
- ✅ **ENHANCED:** Added type safety, caller code simplicity, and internal implementation complexity as evaluation criteria
- 📊 **RATIONALE:** OPTION 4 combines best of both worlds - clean array parameter API with internal temp table performance
- 🎯 **IMPACT:** Maintains PRIMARY KEY enforcement, provides type safety, and simplifies caller code while preserving performance

**Version 1.0** (2025-12-15)
- Initial analysis of GooList user-defined table type
- Documented 3 conversion strategies (TEMP TABLE, ARRAY, JSONB)
- Recommended TEMP TABLE pattern as primary strategy
- Complete dependency analysis with 4 objects (2 functions, 2 SPs)


---

## 📚 Appendix: Conversion Strategy Comparison Matrix

| Criterion | TEMP TABLE (Option 1) | ARRAY Simple (Option 2) | JSONB (Option 3) | ARRAY Composite ⭐ (Option 4) |
|-----------|--------------|-------|-------|------------------------|
| **Performance (small batch <100)** | Good | Excellent | Good | Excellent |
| **Performance (large batch >100)** | Excellent | Poor | Good | Excellent |
| **Code Complexity** | Medium | Low | Medium | Low-Medium |
| **SQL Server Similarity** | High | Low | Low | High |
| **PRIMARY KEY Support** | ✅ Yes | ❌ No | ❌ No | ✅ Yes (internal) |
| **Memory Usage** | Low (disk-backed) | High (in-memory) | Medium | Low (disk-backed) |
| **Query Plan Optimization** | Excellent | Poor | Good | Excellent |
| **Debugging Ease** | Excellent | Medium | Medium | Excellent |
| **Future Extensibility** | Excellent | Poor | Excellent | Excellent |
| **Learning Curve** | Low | Medium | High | Low |
| **Type Safety** | ✅ Strong | ⚠️ Weak | ⚠️ Weak | ✅ Strong |
| **Caller Code Simplicity** | ❌ Complex (temp table mgmt) | ✅ Simple (ARRAY_AGG) | ⚠️ Medium (JSON build) | ✅ Simple (ARRAY_AGG) |
| **Internal Implementation** | Simple (name passing) | Simple (direct use) | Simple (JSON parse) | Medium (UNNEST + temp) |
| **RECOMMENDATION** | ⭐⭐ | ⭐ | ⭐⭐ | ⭐⭐⭐⭐ |

**Winner:** ARRAY of Composite Types (OPTION 4) - Hybrid approach combining best of array parameters (clean API) with temp tables (performance).

**Key Advantages of OPTION 4:**
- Clean function signature with type-safe array parameter
- Internal temp table optimization for JOIN performance and PRIMARY KEY enforcement  
- Caller simplicity matches OPTION 2 (simple ARRAY_AGG pattern)
- Performance matches OPTION 1 (indexed temp table for large batches)
- Future-proof: composite type can evolve without breaking callers

---

**End of Lote 4 Analysis - Version 1.1**
