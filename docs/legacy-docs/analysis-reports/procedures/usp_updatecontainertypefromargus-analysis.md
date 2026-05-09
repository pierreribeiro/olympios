# Analysis: usp_UpdateContainerTypeFromArgus
## AWS SCT Conversion Quality Report

**Analyzed:** 2025-11-22  
**Analyst:** Pierre Ribeiro + Claude (Desktop)  
**GitHub Issue:** #11  
**Sprint:** 7  
**Priority:** P3  

**AWS SCT Output:** `procedures/aws-sct-converted/28. perseus_dbo.usp_updatecontainertypefromargus.sql`  
**Original T-SQL:** `procedures/original/dbo.usp_UpdateContainerTypeFromArgus.sql`

---

## 📊 Executive Summary

| Metric | Score | Status |
|--------|-------|--------|
| Syntax Correctness | 2/10 | ❌ CRITICAL |
| Logic Preservation | 0/10 | ❌ CRITICAL |
| Performance | N/A | ⚠️ Not Applicable |
| Maintainability | 3/10 | ❌ Poor |
| Security | 5/10 | ⚠️ Neutral |
| **OVERALL SCORE** | **2.0/10** | **❌ CRITICAL FAILURE** |

### 🎯 Verdict: ❌ COMPLETE CONVERSION FAILURE

**AWS SCT was UNABLE to convert this procedure.** The converted code is an **empty shell** with all business logic commented out as errors. This procedure requires **100% manual rewrite**.

---

## 📈 Size Analysis

| Metric | Original (T-SQL) | Converted (PL/pgSQL) | Change |
|--------|------------------|---------------------|--------|
| Total Lines | 11 | 21 | +91% |
| Code Lines | 7 | 2 | **-71%** |
| Comment Lines | 0 | 15 | +∞ |
| Effective Code | 7 lines | **0 lines** | **-100%** |

**Root Cause:** AWS SCT couldn't handle `OPENQUERY` linked server syntax and commented out the entire UPDATE statement.

---

## 🔍 Original T-SQL Logic Analysis

```sql
CREATE PROCEDURE [dbo].[usp_UpdateContainerTypeFromArgus]
AS
BEGIN
    UPDATE perseus.dbo.container
    SET container_type_id = 12
    FROM perseus.dbo.container c
    JOIN OPENQUERY(SCAN2, 'select * from scan2.argus.root_plate 
                   WHERE plate_format_id = 8 
                   AND hermes_experiment_id IS NOT NULL') rp 
        ON rp.uid = c.uid 
        AND c.container_type_id != 12;
END
```

### Business Logic Understanding

| Component | Value | Purpose |
|-----------|-------|---------|
| **Target Table** | `perseus.dbo.container` | Container registry |
| **Updated Column** | `container_type_id` | Set to `12` |
| **External System** | `SCAN2` (linked server) | Argus system |
| **External Table** | `scan2.argus.root_plate` | Plate metadata |
| **Filter 1** | `plate_format_id = 8` | Specific plate format |
| **Filter 2** | `hermes_experiment_id IS NOT NULL` | Has experiment link |
| **Join Condition** | `rp.uid = c.uid` | Match by UID |
| **Guard Clause** | `c.container_type_id != 12` | Only update if not already 12 |

### Business Rule Summary
> "Update container_type_id to 12 for all containers that exist in Argus system with plate_format_id=8 and have a hermes_experiment_id, but only if they're not already type 12."

---

## 🔍 AWS SCT Converted Code Analysis

```sql
CREATE OR REPLACE PROCEDURE perseus_dbo.usp_updatecontainertypefromargus()
AS 
$BODY$
BEGIN
    /*
    [9996 - Severity CRITICAL - Transformer error occurred in fromClause. 
     Please submit report to developers.]
    UPDATE perseus.dbo.container...
    
    [9997 - Severity HIGH - Unable to resolve the object SCAN2...]
    [9997 - Severity HIGH - Unable to resolve the object uid...]
    */
    BEGIN
    END;  -- ← EMPTY! No business logic!
END;
$BODY$
LANGUAGE plpgsql;
```

### AWS SCT Warnings Analysis

| Code | Severity | Issue | Root Cause |
|------|----------|-------|------------|
| **9996** | CRITICAL | Transformer error in fromClause | OPENQUERY not supported |
| **9997** | HIGH | Unable to resolve SCAN2 | Linked server doesn't exist in PostgreSQL |
| **9997** | HIGH | Unable to resolve uid | Column reference broken due to OPENQUERY failure |

---

## 🚨 Critical Issues (P0) - Must Fix

### 1. ❌ COMPLETE LOGIC LOSS - EMPTY PROCEDURE

**Issue:** AWS SCT failed to convert the UPDATE statement entirely. The procedure body contains only `BEGIN END;` with no actual code.

**Impact:**
- **RUNTIME:** Procedure executes successfully but **does nothing**
- **BUSINESS:** Container types never updated from Argus
- **DATA:** Synchronization with external system completely broken
- **SEVERITY:** Complete business logic loss

**Solution:** Manual rewrite required using PostgreSQL Foreign Data Wrapper (FDW) or dblink.

---

### 2. ❌ OPENQUERY NOT SUPPORTED IN POSTGRESQL

**Issue:** SQL Server `OPENQUERY()` function has no direct PostgreSQL equivalent.

**Original T-SQL:**
```sql
JOIN OPENQUERY(SCAN2, 'select * from scan2.argus.root_plate 
               WHERE plate_format_id = 8 
               AND hermes_experiment_id IS NOT NULL') rp
```

**Impact:**
- Cannot query external Argus database
- Linked server architecture incompatible
- Requires infrastructure change

**Solution Options:**

| Option | Approach | Complexity | Recommendation |
|--------|----------|------------|----------------|
| **A** | `postgres_fdw` | Medium | ✅ **RECOMMENDED** |
| **B** | `dblink` | Low | ⚠️ Acceptable |
| **C** | ETL/Staging | High | For high-volume |
| **D** | Application Layer | Medium | If DB access restricted |

**Option A - postgres_fdw (Recommended):**
```sql
-- Setup (one-time, run as superuser)
CREATE EXTENSION IF NOT EXISTS postgres_fdw;

CREATE SERVER argus_server
    FOREIGN DATA WRAPPER postgres_fdw
    OPTIONS (host 'argus-db-host', port '5432', dbname 'scan2');

CREATE USER MAPPING FOR perseus_user
    SERVER argus_server
    OPTIONS (user 'argus_reader', password 'xxx');

CREATE FOREIGN TABLE argus_root_plate (
    uid VARCHAR(255),
    plate_format_id INTEGER,
    hermes_experiment_id VARCHAR(255)
)
SERVER argus_server
OPTIONS (schema_name 'argus', table_name 'root_plate');
```

**Option B - dblink:**
```sql
-- Simpler but less integrated
SELECT * FROM dblink(
    'host=argus-db port=5432 dbname=scan2 user=reader',
    'SELECT uid FROM argus.root_plate WHERE plate_format_id = 8 AND hermes_experiment_id IS NOT NULL'
) AS t(uid VARCHAR(255));
```

---

### 3. ❌ NO TRANSACTION CONTROL

**Issue:** Procedure has no error handling or transaction management.

**Impact:**
- Partial updates on failure
- No rollback capability
- Silent failures possible

**Solution:** Add proper transaction block with EXCEPTION handler.

---

## ⚠️ High Priority Issues (P1) - Should Fix

### 1. ⚠️ NO ERROR HANDLING

**Issue:** No EXCEPTION block to catch and handle errors.

**Solution:**
```sql
BEGIN
    -- business logic
EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING '[usp_UpdateContainerTypeFromArgus] Error: %', SQLERRM;
        RAISE;
END;
```

---

### 2. ⚠️ NO OBSERVABILITY

**Issue:** No logging of execution, row counts, or timing.

**Solution:**
```sql
RAISE NOTICE '[usp_UpdateContainerTypeFromArgus] Starting execution';
-- ... UPDATE ...
GET DIAGNOSTICS v_row_count = ROW_COUNT;
RAISE NOTICE '[usp_UpdateContainerTypeFromArgus] Updated % containers', v_row_count;
```

---

### 3. ⚠️ NO RETURN VALUE

**Issue:** Procedure doesn't return affected row count.

**Solution:** Add OUT parameter or use RAISE NOTICE for tracking.

---

## 💡 Medium Priority Issues (P2) - Nice to Have

### 1. 💡 NOMENCLATURE

**Issue:** Procedure name uses mixed case and prefix convention.

**Current:** `usp_updatecontainertypefromargus`  
**Recommended:** `update_container_type_from_argus`

---

### 2. 💡 SCHEMA REFERENCE

**Issue:** Original uses `perseus.dbo.container`, PostgreSQL should use `perseus_dbo.container`.

---

## 📝 Instructions for Code Web Environment

### Pre-Requisites (Infrastructure Team)

Before the procedure can work, the infrastructure team must:

1. **Determine External DB Type:**
   - Is Argus running on PostgreSQL, Oracle, or SQL Server?
   - This determines which FDW to use

2. **Setup Foreign Data Wrapper:**
   ```sql
   -- For PostgreSQL target:
   CREATE EXTENSION IF NOT EXISTS postgres_fdw;
   
   -- For Oracle target:
   CREATE EXTENSION IF NOT EXISTS oracle_fdw;
   
   -- For SQL Server target:
   CREATE EXTENSION IF NOT EXISTS tds_fdw;
   ```

3. **Create Foreign Server and User Mapping:**
   - Requires DBA privileges
   - Connection credentials needed

4. **Create Foreign Table:**
   ```sql
   CREATE FOREIGN TABLE perseus_dbo.argus_root_plate (
       uid VARCHAR(255),
       plate_format_id INTEGER,
       hermes_experiment_id VARCHAR(255)
   )
   SERVER argus_server
   OPTIONS (schema_name 'argus', table_name 'root_plate');
   ```

---

### Corrected Procedure Code (Post-FDW Setup)

**File:** `procedures/corrected/usp_updatecontainertypefromargus.sql`

```sql
-- ============================================================================
-- Procedure: update_container_type_from_argus
-- Schema: perseus_dbo
-- Purpose: Sync container types from external Argus system
-- 
-- Description:
--   Updates container_type_id to 12 for containers that exist in Argus
--   with plate_format_id=8 and have a hermes_experiment_id assigned.
--
-- Dependencies:
--   - Table: perseus_dbo.container
--   - Foreign Table: perseus_dbo.argus_root_plate (requires FDW setup)
--
-- Business Rules:
--   - Only updates containers not already type 12 (idempotent)
--   - Requires matching uid between systems
--   - Filter: plate_format_id = 8 AND hermes_experiment_id IS NOT NULL
--
-- Pre-Requisites:
--   - postgres_fdw extension installed
--   - Foreign server 'argus_server' configured
--   - Foreign table 'argus_root_plate' created
--
-- Created: 2025-11-22 by Pierre Ribeiro (SQL Server to PostgreSQL migration)
-- Version: 1.0.0
-- Original: procedures/original/dbo.usp_UpdateContainerTypeFromArgus.sql
-- ============================================================================

CREATE OR REPLACE PROCEDURE perseus_dbo.update_container_type_from_argus()
LANGUAGE plpgsql
AS $$
DECLARE
    -- Constants
    c_procedure_name CONSTANT VARCHAR := 'update_container_type_from_argus';
    c_target_type_id CONSTANT INTEGER := 12;
    
    -- Tracking variables
    v_row_count INTEGER;
    v_start_time TIMESTAMP;
    
    -- Error handling
    v_error_state TEXT;
    v_error_message TEXT;
BEGIN
    v_start_time := clock_timestamp();
    RAISE NOTICE '[%] Starting execution', c_procedure_name;
    
    BEGIN  -- Transaction block
        
        -- ===== MAIN UPDATE =====
        -- Update container_type_id for containers matching Argus criteria
        UPDATE perseus_dbo.container c
        SET container_type_id = c_target_type_id
        FROM perseus_dbo.argus_root_plate rp  -- Foreign table via FDW
        WHERE rp.uid = c.uid
          AND rp.plate_format_id = 8
          AND rp.hermes_experiment_id IS NOT NULL
          AND c.container_type_id != c_target_type_id;  -- Idempotent guard
        
        GET DIAGNOSTICS v_row_count = ROW_COUNT;
        
        RAISE NOTICE '[%] Updated % containers to type_id=%', 
                     c_procedure_name, v_row_count, c_target_type_id;
        
        RAISE NOTICE '[%] Completed in % ms', 
                     c_procedure_name,
                     EXTRACT(MILLISECONDS FROM clock_timestamp() - v_start_time)::INTEGER;
        
    EXCEPTION
        WHEN foreign_data_wrapper_error THEN
            GET STACKED DIAGNOSTICS v_error_state = RETURNED_SQLSTATE,
                                    v_error_message = MESSAGE_TEXT;
            RAISE WARNING '[%] FDW Error [%]: % - Check Argus connection', 
                          c_procedure_name, v_error_state, v_error_message;
            RAISE;
            
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS v_error_state = RETURNED_SQLSTATE,
                                    v_error_message = MESSAGE_TEXT;
            RAISE WARNING '[%] Error [%]: %', 
                          c_procedure_name, v_error_state, v_error_message;
            RAISE;
    END;
    
END;
$$;

-- ============================================================================
-- PERMISSIONS
-- ============================================================================
-- GRANT EXECUTE ON PROCEDURE perseus_dbo.update_container_type_from_argus() TO app_role;

-- ============================================================================
-- VERIFICATION
-- ============================================================================
-- CALL perseus_dbo.update_container_type_from_argus();
```

---

### Alternative: dblink Version (If FDW Not Available)

```sql
CREATE OR REPLACE PROCEDURE perseus_dbo.update_container_type_from_argus_dblink()
LANGUAGE plpgsql
AS $$
DECLARE
    c_procedure_name CONSTANT VARCHAR := 'update_container_type_from_argus';
    c_connection_string CONSTANT VARCHAR := 'host=argus-host port=5432 dbname=scan2 user=reader password=xxx';
    v_row_count INTEGER;
BEGIN
    RAISE NOTICE '[%] Starting execution (dblink mode)', c_procedure_name;
    
    -- Update using dblink for remote query
    UPDATE perseus_dbo.container c
    SET container_type_id = 12
    FROM dblink(
        c_connection_string,
        'SELECT uid FROM argus.root_plate 
         WHERE plate_format_id = 8 
         AND hermes_experiment_id IS NOT NULL'
    ) AS rp(uid VARCHAR(255))
    WHERE rp.uid = c.uid
      AND c.container_type_id != 12;
    
    GET DIAGNOSTICS v_row_count = ROW_COUNT;
    RAISE NOTICE '[%] Updated % containers', c_procedure_name, v_row_count;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING '[%] Error: %', c_procedure_name, SQLERRM;
        RAISE;
END;
$$;
```

---

## 📊 Expected Results

### Post-Fix Quality Score

| Metric | Before | After | Change |
|--------|--------|-------|--------|
| Syntax Correctness | 2/10 | 9/10 | +7 |
| Logic Preservation | 0/10 | 9/10 | +9 |
| Performance | N/A | 8/10 | New |
| Maintainability | 3/10 | 9/10 | +6 |
| Security | 5/10 | 8/10 | +3 |
| **OVERALL** | **2.0/10** | **8.6/10** | **+6.6** |

### Validation Checklist

- [ ] Foreign Data Wrapper extension installed
- [ ] Foreign server configured and tested
- [ ] Foreign table created and accessible
- [ ] Procedure created without syntax errors
- [ ] Test execution with sample data
- [ ] Row count verification
- [ ] Error handling tested
- [ ] Performance benchmark (<1 second expected)

---

## 🎯 Action Items Summary

| Priority | Item | Owner | Status |
|----------|------|-------|--------|
| **P0** | Determine Argus database type | Infra Team | ⏳ Pending |
| **P0** | Setup FDW extension | DBA | ⏳ Pending |
| **P0** | Create foreign server | DBA | ⏳ Pending |
| **P0** | Create foreign table | DBA | ⏳ Pending |
| **P0** | Implement corrected procedure | Code Web | ⏳ Pending |
| **P1** | Add error handling | Code Web | ⏳ Pending |
| **P1** | Add observability | Code Web | ⏳ Pending |
| **P2** | Rename to snake_case | Code Web | ⏳ Pending |

---

## 🔗 References

- **Original Analysis Template:** `procedures/analysis/reconcilemupstream-analysis.md`
- **PostgreSQL Template:** `templates/postgresql-procedure-template.sql`
- **PostgreSQL FDW Documentation:** https://www.postgresql.org/docs/current/postgres-fdw.html
- **dblink Documentation:** https://www.postgresql.org/docs/current/dblink.html

---

## 📌 Special Notes

### Infrastructure Dependency

⚠️ **This procedure CANNOT be tested until FDW infrastructure is configured.** 

The development team should:
1. Create a mock/stub version for unit testing
2. Work with DBA to setup FDW in DEV environment
3. Verify connectivity to Argus system
4. Test with representative data set

### Idempotency

The guard clause `c.container_type_id != 12` ensures the procedure is **idempotent** - running it multiple times produces the same result without side effects.

### Performance Consideration

If the Argus table is large, consider adding an index on the foreign table:
```sql
-- On Argus side (if possible)
CREATE INDEX idx_root_plate_format_hermes 
ON argus.root_plate(plate_format_id, hermes_experiment_id) 
WHERE plate_format_id = 8 AND hermes_experiment_id IS NOT NULL;
```

---

**Analysis Complete** ✅  
**Ready for Code Web implementation after FDW setup**
