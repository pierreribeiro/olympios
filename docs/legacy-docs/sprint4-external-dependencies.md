# GetMaterialByRunProperties - External Dependencies
## Sprint 4 - Issue #21

**Purpose:** Document all external dependencies for integration planning

---

## 📋 External Function/Procedure Inventory

### 1. perseus_dbo.mcgetdownstream (Function)

**Type:** Function (returns TABLE)

**Signature:**
```sql
perseus_dbo.mcgetdownstream(material_uid VARCHAR)
RETURNS TABLE(end_point VARCHAR, ...)
```

**Purpose:**
- Returns all materials downstream from given material in the graph
- Traverses material→transition→material relationships
- Used to find timepoint materials created from original run material

**Usage in GetMaterialByRunProperties:**
```sql
SELECT regexp_replace(g.uid, 'm', '', 'gi')
INTO var_TimePointGoo
FROM perseus_dbo.mcgetdownstream(var_OriginalGoo) AS d
JOIN perseus_dbo.goo AS g
    ON d.end_point = g.uid
WHERE g.added_on = var_StartTime + (var_SecondTimePoint::NUMERIC || ' SECOND')::INTERVAL
  AND g.goo_type_id = 9;
```

**Criticality:** HIGH
- **Impact if missing:** Cannot find existing timepoint materials
- **Impact if fails:** Returns no rows, var_TimePointGoo = NULL
- **Fallback behavior:** Creates new material (duplicate possible)

**Error Handling Needed:**
- ❌ Current: No error checking (assumes function exists)
- ✅ Fix: Function should exist, but add logging if no results

**Testing Required:**
- [ ] Verify function exists in target database
- [ ] Test with valid material_uid
- [ ] Test with invalid material_uid (should return 0 rows)
- [ ] Test with material that has no downstream (should return 0 rows)

---

### 2. perseus_dbo.materialtotransition (Procedure)

**Type:** Procedure (CALL statement)

**Signature:**
```sql
PROCEDURE perseus_dbo.materialtotransition(
    material_uid VARCHAR,
    transition_uid VARCHAR
)
```

**Purpose:**
- Creates link from material to transition in graph
- Inserts record into material_transition table (or similar)
- May also update m_downstream table for graph propagation

**Usage in GetMaterialByRunProperties:**
```sql
CALL perseus_dbo.materialtotransition(var_OriginalGoo, var_Split);
```

**Flow Position:**
```
INSERT goo (var_TimePointGoo)
  ↓
INSERT fatsmurf (var_Split)
  ↓
CALL materialtotransition(var_OriginalGoo → var_Split)  ← HERE
  ↓
CALL transitiontomaterial(var_Split → var_TimePointGoo)
```

**Criticality:** P0 - DATA INTEGRITY
- **Impact if missing:** Procedure not found error, ROLLBACK needed
- **Impact if fails:** Partial graph state (goo + fatsmurf exist, no link)
- **Consequence:** Orphaned records, graph corruption

**Error Handling Needed:**
- ❌ Current: No verification after CALL
- ✅ Fix Option A: Check link exists after CALL
  ```sql
  CALL perseus_dbo.materialtotransition(var_OriginalGoo, var_Split);

  IF NOT EXISTS (
      SELECT 1 FROM perseus_dbo.material_transition
      WHERE material_id = var_OriginalGoo
        AND transition_id = var_Split
  ) THEN
      RAISE EXCEPTION '[GetMaterialByRunProperties] MaterialToTransition failed for % -> %',
            var_OriginalGoo, var_Split
            USING ERRCODE = 'P0001';
  END IF;
  ```

- ✅ Fix Option B: Procedure returns status code (if supported)
  ```sql
  DECLARE v_status INTEGER;

  CALL perseus_dbo.materialtotransition(var_OriginalGoo, var_Split, v_status);

  IF v_status != 0 THEN
      RAISE EXCEPTION 'MaterialToTransition failed with status %', v_status;
  END IF;
  ```

**Testing Required:**
- [ ] Verify procedure exists in target database
- [ ] Test successful link creation
- [ ] Test failure scenario (invalid UIDs)
- [ ] Verify rollback on failure
- [ ] Check for orphaned records after error

---

### 3. perseus_dbo.transitiontomaterial (Procedure)

**Type:** Procedure (CALL statement)

**Signature:**
```sql
PROCEDURE perseus_dbo.transitiontomaterial(
    transition_uid VARCHAR,
    material_uid VARCHAR
)
```

**Purpose:**
- Creates link from transition to material in graph
- Inserts record into transition_material table (or similar)
- May also update m_upstream table for graph propagation

**Usage in GetMaterialByRunProperties:**
```sql
CALL perseus_dbo.transitiontomaterial(var_Split, var_TimePointGoo);
```

**Flow Position:**
```
INSERT goo (var_TimePointGoo)
  ↓
INSERT fatsmurf (var_Split)
  ↓
CALL materialtotransition(var_OriginalGoo → var_Split)
  ↓
CALL transitiontomaterial(var_Split → var_TimePointGoo)  ← HERE
```

**Criticality:** P0 - DATA INTEGRITY
- **Impact if missing:** Procedure not found error, ROLLBACK needed
- **Impact if fails:** Partial graph state (goo + fatsmurf + first link, no second link)
- **Consequence:** Incomplete graph, dangling transition

**Error Handling Needed:**
- ❌ Current: No verification after CALL
- ✅ Fix Option A: Check link exists after CALL
  ```sql
  CALL perseus_dbo.transitiontomaterial(var_Split, var_TimePointGoo);

  IF NOT EXISTS (
      SELECT 1 FROM perseus_dbo.transition_material
      WHERE transition_id = var_Split
        AND material_id = var_TimePointGoo
  ) THEN
      RAISE EXCEPTION '[GetMaterialByRunProperties] TransitionToMaterial failed for % -> %',
            var_Split, var_TimePointGoo
            USING ERRCODE = 'P0001';
  END IF;
  ```

- ✅ Fix Option B: Procedure returns status code (if supported)
  ```sql
  DECLARE v_status INTEGER;

  CALL perseus_dbo.transitiontomaterial(var_Split, var_TimePointGoo, v_status);

  IF v_status != 0 THEN
      RAISE EXCEPTION 'TransitionToMaterial failed with status %', v_status;
  END IF;
  ```

**Testing Required:**
- [ ] Verify procedure exists in target database
- [ ] Test successful link creation
- [ ] Test failure scenario (invalid UIDs)
- [ ] Verify rollback on failure
- [ ] Check graph consistency after error

---

## 🗄️ External Table Dependencies

### Tables Read

| Table | Schema | Columns Used | Purpose |
|-------|--------|--------------|---------|
| **run** | perseus_hermes | experiment_id, local_id, resultant_material, start_time | Find run and original material |
| **goo** | perseus_dbo | uid, added_by, added_on, goo_type_id, name, original_volume | Material storage |
| **fatsmurf** | perseus_dbo | uid, added_on, added_by, smurf_id, run_on | Transition/split storage |

### Tables Written

| Table | Schema | Operation | Columns | Criticality |
|-------|--------|-----------|---------|-------------|
| **goo** | perseus_dbo | INSERT | uid, name, original_volume, added_on, added_by, goo_type_id | HIGH |
| **fatsmurf** | perseus_dbo | INSERT | uid, added_on, added_by, smurf_id, run_on | HIGH |
| **material_transition** | perseus_dbo | INSERT (via proc) | material_id, transition_id | P0 |
| **transition_material** | perseus_dbo | INSERT (via proc) | transition_id, material_id | P0 |

### Indexes Required (for performance)

```sql
-- For joining run with goo (STEP 2)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_run_lookup
ON perseus_hermes.run (experiment_id, local_id, resultant_material);

-- For joining goo with resultant_material
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_goo_uid
ON perseus_dbo.goo (uid);

-- For finding existing timepoint (STEP 3)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_goo_timepoint_lookup
ON perseus_dbo.goo (added_on, goo_type_id, uid);

-- For MAX() query optimization (STEP 4A) - if not using sequences
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_goo_uid_prefix
ON perseus_dbo.goo (uid) WHERE uid LIKE 'm%';

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_fatsmurf_uid_prefix
ON perseus_dbo.fatsmurf (uid) WHERE uid LIKE 's%';

-- For verification queries (error checking)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_material_transition_lookup
ON perseus_dbo.material_transition (material_id, transition_id);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_transition_material_lookup
ON perseus_dbo.transition_material (transition_id, material_id);
```

---

## ⚠️ Dependency Risks & Mitigation

### Risk 1: Missing External Functions/Procedures
**Scenario:** mcgetdownstream, materialtotransition, or transitiontomaterial doesn't exist

**Impact:**
- Runtime error: "function/procedure does not exist"
- Immediate failure, no data corruption

**Mitigation:**
- ✅ **Pre-deployment check:**
  ```sql
  -- Verify function exists
  SELECT COUNT(*) FROM pg_proc
  WHERE proname = 'mcgetdownstream'
    AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'perseus_dbo');

  -- Verify procedures exist
  SELECT COUNT(*) FROM pg_proc
  WHERE proname IN ('materialtotransition', 'transitiontomaterial')
    AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'perseus_dbo');
  ```

### Risk 2: External Procedure Silent Failure
**Scenario:** materialtotransition succeeds but doesn't create link

**Impact:**
- Orphaned goo + fatsmurf records
- Incomplete graph (missing edges)
- Future graph traversals skip this node

**Mitigation:**
- ✅ **Verify after CALL:**
  ```sql
  CALL perseus_dbo.materialtotransition(var_OriginalGoo, var_Split);

  -- Verification
  IF NOT EXISTS (SELECT 1 FROM perseus_dbo.material_transition
                 WHERE material_id = var_OriginalGoo AND transition_id = var_Split) THEN
      RAISE EXCEPTION 'MaterialToTransition failed silently';
  END IF;
  ```

### Risk 3: External Procedure Raises Exception
**Scenario:** materialtotransition raises exception (constraint violation, etc.)

**Impact:**
- Current: No EXCEPTION block → procedure fails, no rollback
- goo + fatsmurf INSERTs persist (partial state)

**Mitigation:**
- ✅ **Add transaction control (P0-1):**
  ```sql
  BEGIN
      BEGIN  -- Inner transaction
          INSERT INTO goo ...;
          INSERT INTO fatsmurf ...;
          CALL materialtotransition(...);
          CALL transitiontomaterial(...);
      EXCEPTION
          WHEN OTHERS THEN
              ROLLBACK;
              RAISE;
      END;
  END;
  ```

### Risk 4: Concurrent Access Race Condition
**Scenario:** Two calls for same RunId+TimePoint execute simultaneously

**Impact:**
1. Both check: var_TimePointGoo = NULL
2. Both calculate: var_MaxGooIdentifier = same value
3. Both INSERT → second fails with UNIQUE violation

**Mitigation Option A: Use Sequences (Best)**
```sql
var_MaxGooIdentifier := nextval('perseus_dbo.seq_goo_identifier');
var_MaxFsIdentifier := nextval('perseus_dbo.seq_fatsmurf_identifier');
```

**Mitigation Option B: Retry Logic**
```sql
DECLARE
    v_retry_count INTEGER := 0;
    v_max_retries CONSTANT INTEGER := 3;
BEGIN
    LOOP
        BEGIN
            -- Generate IDs
            -- INSERT operations
            EXIT;  -- Success
        EXCEPTION
            WHEN unique_violation THEN
                v_retry_count := v_retry_count + 1;
                IF v_retry_count >= v_max_retries THEN
                    RAISE;
                END IF;
                -- Wait and retry
                PERFORM pg_sleep(0.1 * v_retry_count);  -- Exponential backoff
        END;
    END LOOP;
END;
```

---

## ✅ Dependency Resolution Plan

### Phase 2 (P0) - During Correction
1. **Verify external objects exist:**
   - Check mcgetdownstream function
   - Check materialtotransition procedure
   - Check transitiontomaterial procedure

2. **Add error handling:**
   - Wrap CALLs in transaction
   - Verify after each CALL
   - Proper rollback on failure

### Phase 5 (Testing) - Before Deployment
1. **Integration tests:**
   - Test with real mcgetdownstream results
   - Test materialtotransition success/failure
   - Test transitiontomaterial success/failure
   - Test rollback scenarios

2. **Performance tests:**
   - Benchmark with/without indexes
   - Test concurrent access (race conditions)
   - Verify sequence performance

---

## 📊 Dependency Summary

| Dependency | Type | Criticality | Error Handling | Status |
|------------|------|-------------|----------------|--------|
| mcgetdownstream | Function | HIGH | Assumed exists, returns 0 rows if issues | ⏳ To verify |
| materialtotransition | Procedure | P0 | ❌ None → ✅ Add verification | ⏳ To fix |
| transitiontomaterial | Procedure | P0 | ❌ None → ✅ Add verification | ⏳ To fix |
| run (table) | Table | HIGH | Standard SQL error | ✅ Assumed exists |
| goo (table) | Table | HIGH | Standard SQL error | ✅ Assumed exists |
| fatsmurf (table) | Table | HIGH | Standard SQL error | ✅ Assumed exists |

---

## ✅ External Dependencies Documented

**Next Step:** Begin Phase 2 - P0 Corrections

---

**Document Version:** 1.0
**Created:** 2025-11-25
**Status:** COMPLETE
**Next:** Phase 2 - Apply P0 Fixes
