# GetMaterialByRunProperties - Logic Flow Map
## Sprint 4 - Issue #21

**Purpose:** Map complete execution flow for correction planning

---

## 🔄 Execution Flow Diagram

```
START
  │
  ├─ INPUT PARAMETERS
  │   ├─ par_RunId: VARCHAR (e.g., "123-45")
  │   ├─ par_HourTimePoint: NUMERIC (e.g., 2.5 hours)
  │   └─ return_code: INOUT INTEGER (returns goo identifier)
  │
  ├─ STEP 1: Calculate Time in Seconds
  │   └─ var_SecondTimePoint = par_HourTimePoint * 60 * 60
  │
  ├─ STEP 2: Find Original Material (goo) from Run
  │   ├─ Query: perseus_hermes.run + perseus_dbo.goo
  │   ├─ Join ON: g.uid = r.resultant_material
  │   ├─ Filter: experiment_id || '-' || local_id = par_RunId
  │   └─ Extract:
  │       ├─ var_CreatorId = g.added_by
  │       ├─ var_OriginalGoo = g.uid
  │       └─ var_StartTime = r.start_time
  │
  ├─ DECISION 1: Is var_OriginalGoo NULL?
  │   │
  │   ├─ YES → EARLY EXIT
  │   │   ├─ return_code = NULL (problematic!)
  │   │   └─ RETURN
  │   │
  │   └─ NO → CONTINUE
  │
  ├─ STEP 3: Find Existing Timepoint Material
  │   ├─ Call: perseus_dbo.mcgetdownstream(var_OriginalGoo)
  │   ├─ Query: downstream + perseus_dbo.goo
  │   ├─ Join ON: d.end_point = g.uid
  │   ├─ Filter:
  │   │   ├─ g.added_on = var_StartTime + var_SecondTimePoint seconds
  │   │   └─ g.goo_type_id = 9 (sample timepoint type)
  │   └─ Extract:
  │       └─ var_TimePointGoo = REPLACE(g.uid, 'm', '')
  │
  ├─ DECISION 2: Is var_TimePointGoo NULL?
  │   │
  │   ├─ YES → CREATE NEW TIMEPOINT MATERIAL
  │   │   │
  │   │   ├─ STEP 4A: Generate New IDs
  │   │   │   ├─ Query MAX(goo.uid) WHERE uid LIKE 'm%'
  │   │   │   │   └─ var_MaxGooIdentifier = MAX + 1
  │   │   │   ├─ Query MAX(fatsmurf.uid) WHERE uid LIKE 's%'
  │   │   │   │   └─ var_MaxFsIdentifier = MAX + 1
  │   │   │   ├─ var_TimePointGoo = 'm' || var_MaxGooIdentifier
  │   │   │   └─ var_Split = 's' || var_MaxFsIdentifier
  │   │   │
  │   │   ├─ STEP 4B: Insert New Goo (Material)
  │   │   │   └─ INSERT INTO perseus_dbo.goo
  │   │   │       ├─ uid = var_TimePointGoo (e.g., "m1234")
  │   │   │       ├─ name = "Sample TP: " || par_HourTimePoint
  │   │   │       ├─ original_volume = 0.00001
  │   │   │       ├─ added_on = var_StartTime + var_SecondTimePoint
  │   │   │       ├─ added_by = var_CreatorId
  │   │   │       └─ goo_type_id = 9 (sample timepoint)
  │   │   │
  │   │   ├─ STEP 4C: Insert New FatSmurf (Transition/Split)
  │   │   │   └─ INSERT INTO perseus_dbo.fatsmurf
  │   │   │       ├─ uid = var_Split (e.g., "s5678")
  │   │   │       ├─ added_on = NOW()
  │   │   │       ├─ added_by = var_CreatorId
  │   │   │       ├─ smurf_id = 110 (auto-generated type)
  │   │   │       └─ run_on = var_StartTime + var_SecondTimePoint
  │   │   │
  │   │   ├─ STEP 4D: Create Material→Transition Link
  │   │   │   └─ CALL perseus_dbo.materialtotransition(
  │   │   │         var_OriginalGoo,  -- From material
  │   │   │         var_Split         -- To transition
  │   │   │       )
  │   │   │
  │   │   └─ STEP 4E: Create Transition→Material Link
  │   │       └─ CALL perseus_dbo.transitiontomaterial(
  │   │             var_Split,         -- From transition
  │   │             var_TimePointGoo   -- To material
  │   │           )
  │   │
  │   └─ NO → USE EXISTING TIMEPOINT MATERIAL
  │       └─ (var_TimePointGoo already set from STEP 3)
  │
  ├─ STEP 5: Prepare Return Value
  │   └─ return_code = CAST(REPLACE(var_TimePointGoo, 'm', '') AS INTEGER)
  │       └─ Example: 'm1234' → 1234
  │
  └─ END
      └─ RETURN (with return_code set)
```

---

## 🎯 Business Logic Summary

### Purpose
Get or create a material sample at a specific timepoint in a run.

### Inputs
1. **RunId** - Identifies experiment run (format: "experimentId-localId")
2. **HourTimePoint** - Time offset from run start (in hours, e.g., 2.5)

### Output
- **return_code** - Goo identifier (integer) of the timepoint material

### Behavior
1. **Find original material** from run (resultant_material)
2. **Calculate timepoint** (hours → seconds from run start)
3. **Search for existing timepoint material** at that exact timestamp
4. **If not found:**
   - Generate new IDs (goo + fatsmurf)
   - Insert new material (goo) record
   - Insert new transition (fatsmurf) record
   - Link original → split → timepoint via graph procedures
5. **Return** goo identifier (without 'm' prefix)

---

## 📋 Data Flow Analysis

### Tables Accessed

| Table | Access Type | Purpose | Columns |
|-------|-------------|---------|---------|
| **perseus_hermes.run** | SELECT | Find run by ID | experiment_id, local_id, resultant_material, start_time |
| **perseus_dbo.goo** | SELECT | Find original material | uid, added_by |
| **perseus_dbo.goo** | SELECT | Find existing timepoint | uid, added_on, goo_type_id |
| **perseus_dbo.goo** | SELECT | Get MAX id for new goo | uid |
| **perseus_dbo.goo** | INSERT | Create new timepoint | uid, name, original_volume, added_on, added_by, goo_type_id |
| **perseus_dbo.fatsmurf** | SELECT | Get MAX id for new split | uid |
| **perseus_dbo.fatsmurf** | INSERT | Create new split | uid, added_on, added_by, smurf_id, run_on |

### External Function/Procedure Calls

| Call | Type | Purpose | Parameters | Return |
|------|------|---------|------------|--------|
| **perseus_dbo.mcgetdownstream** | Function | Get materials downstream from original | (material_uid VARCHAR) | TABLE(end_point VARCHAR) |
| **perseus_dbo.materialtotransition** | Procedure | Link material→transition | (material_uid, transition_uid) | void |
| **perseus_dbo.transitiontomaterial** | Procedure | Link transition→material | (transition_uid, material_uid) | void |

---

## 🔍 Critical Decision Points

### Decision 1: Original Material Exists?
```
IF var_OriginalGoo IS NULL
```
- **TRUE:** Run not found or has no resultant material
  - **Current behavior:** return_code = NULL, silent return
  - **Problem:** NULL return indicates both "not found" and "error"
  - **Fix needed:** Add validation, raise exception or return 0/-1

- **FALSE:** Run found with material
  - **Continue:** Proceed to find/create timepoint

### Decision 2: Timepoint Material Exists?
```
IF var_TimePointGoo IS NULL
```
- **TRUE:** No material at this timepoint yet
  - **Action:** Create new material + split + links (STEP 4A-4E)
  - **Risk:** Race condition (concurrent calls)
  - **Risk:** External call failures

- **FALSE:** Material already exists at timepoint
  - **Action:** Use existing material
  - **Return:** Existing goo identifier

---

## ⚠️ Edge Cases & Risks

### Edge Case 1: Concurrent Calls
**Scenario:** Two processes call simultaneously for same RunId + TimePoint

**Current behavior:**
1. Both check: var_TimePointGoo = NULL ✅
2. Both calculate: MAX + 1 = same ID
3. Both try INSERT → second fails with UNIQUE constraint

**Risk:** Second call fails with cryptic error

**Mitigation:**
- Add unique constraint verification
- Retry logic with exponential backoff
- Use sequences instead of MAX()

### Edge Case 2: External Call Failure
**Scenario:** materialtotransition fails after goo INSERT

**Current behavior:**
1. INSERT goo succeeds
2. INSERT fatsmurf succeeds
3. CALL materialtotransition fails
4. No rollback → orphaned records

**Risk:** Data inconsistency, graph corruption

**Mitigation:**
- Add transaction control (P0-1)
- Verify after each CALL (P0-2)
- Rollback on failure

### Edge Case 3: Invalid RunId
**Scenario:** RunId doesn't exist in database

**Current behavior:**
1. SELECT returns no rows
2. var_OriginalGoo = NULL
3. return_code = NULL
4. Silent return

**Risk:** Caller thinks success (no error raised)

**Mitigation:**
- Add input validation (P1-2)
- Raise exception if RunId not found
- Return -1 or 0 for "not found"

### Edge Case 4: Negative/Invalid TimePoint
**Scenario:** par_HourTimePoint < 0 or > 1000

**Current behavior:**
1. Calculates negative seconds
2. DATEADD goes backward in time
3. Finds/creates material at wrong timestamp

**Risk:** Wrong data, invalid business logic

**Mitigation:**
- Validate par_HourTimePoint >= 0 and <= 240 (10 days max)
- Raise exception if out of range

### Edge Case 5: mcgetdownstream Returns No Rows
**Scenario:** Original material has no downstream

**Current behavior:**
1. SELECT from mcgetdownstream returns 0 rows
2. var_TimePointGoo = NULL
3. Proceeds to create new material

**Risk:** None - this is expected behavior

**Mitigation:** None needed (working as intended)

---

## 🎭 Control Flow Patterns

### Pattern 1: Early Exit
```sql
IF var_OriginalGoo IS NULL THEN
    -- Silent early exit (PROBLEMATIC)
    RETURN;
END IF;
```
**Issue:** No error signaling, return_code undefined

**Fix:** Raise exception or set return_code = -1

### Pattern 2: Nested IF (Simple)
```sql
IF var_OriginalGoo IS NOT NULL THEN
    -- Find timepoint
    IF var_TimePointGoo IS NULL THEN
        -- Create material
    END IF;
END IF;
```
**Complexity:** 2 levels (acceptable)

**Not "hadouken" code** - simple, readable

### Pattern 3: Sequential Operations (Risky)
```sql
INSERT INTO goo (...) VALUES (...);
INSERT INTO fatsmurf (...) VALUES (...);
CALL materialtotransition(...);
CALL transitiontomaterial(...);
```
**Issue:** No transaction control, no error checking

**Fix:** Wrap in BEGIN...EXCEPTION, verify after each

---

## 📊 Variable Dependencies

### Input → Derived
```
par_RunId
  └─> (used in WHERE clause to find run)

par_HourTimePoint
  ├─> var_SecondTimePoint = par_HourTimePoint * 60 * 60
  └─> (used in INSERT name, date calculations)
```

### Query 1 → Variables
```
SELECT ... FROM run + goo WHERE RunId = par_RunId
  ├─> var_CreatorId (used in INSERT operations)
  ├─> var_OriginalGoo (used in mcgetdownstream, materialtotransition)
  └─> var_StartTime (used in date calculations)
```

### Query 2 → Variables (Conditional)
```
IF var_OriginalGoo IS NOT NULL:
  SELECT ... FROM mcgetdownstream + goo
    └─> var_TimePointGoo (determines create vs. use existing)
```

### Query 3-4 → Variables (Conditional)
```
IF var_TimePointGoo IS NULL:
  SELECT MAX(uid) FROM goo
    └─> var_MaxGooIdentifier
        └─> var_TimePointGoo = 'm' || var_MaxGooIdentifier

  SELECT MAX(uid) FROM fatsmurf
    └─> var_MaxFsIdentifier
        └─> var_Split = 's' || var_MaxFsIdentifier
```

### Final Derivation
```
var_TimePointGoo (from existing OR new)
  └─> return_code = CAST(REPLACE(var_TimePointGoo, 'm', '') AS INTEGER)
```

---

## 🎯 Correction Strategy

Based on flow analysis:

### Phase 2 (P0) - Transaction & Error Control
1. **Wrap in transaction:** BEGIN...EXCEPTION...END
2. **Verify external calls:**
   - After materialtotransition: Check link created
   - After transitiontomaterial: Check link created
3. **Handle NULL var_OriginalGoo:** Raise exception or return -1

### Phase 3 (P1) - Performance & Quality
1. **Remove all LOWER():**
   - Lines 20, 25, 38, 50, 59 (10 calls total)
2. **Add input validation:**
   - par_RunId: NOT NULL, not empty, format check
   - par_HourTimePoint: NOT NULL, >= 0, <= 240
3. **Optimize MAX() queries:**
   - Option A: Create sequences (best)
   - Option B: Combine into single query
4. **Add logging:**
   - Start: Parameters
   - Decision points: Original found? Timepoint exists?
   - Operations: INSERTs, CALLs
   - End: Return value, execution time

### Phase 4 (P2) - Polish
1. **Rename variables:** var_CreatorId → v_creator_id
2. **Add constants:** c_goo_type_sample = 9, c_smurf_auto = 110
3. **Rename parameter:** return_code → out_goo_identifier

---

## 📈 Complexity Assessment

| Metric | Value | Rating |
|--------|-------|--------|
| **Lines of code** | 80 (AWS SCT) | Medium |
| **Decision points** | 2 | Simple |
| **Nested levels** | 2 | Simple |
| **Table accesses** | 4 (SELECT) + 2 (INSERT) | Medium |
| **External calls** | 3 (1 function + 2 procedures) | Medium |
| **Temp tables** | 0 | ✅ Simple |
| **Loops** | 0 | ✅ Simple |
| **Recursion** | 0 | ✅ Simple |

**Overall Complexity:** Medium (3.0/5) - Manageable

**Why not higher:**
- No temp tables (major simplification)
- No recursion (major simplification)
- No loops (simple straight-line logic)
- Only 2 decision points (shallow nesting)

**Why not lower:**
- External function/procedure dependencies
- Multiple table operations
- Requires transaction coordination

---

## ✅ Flow Mapping Complete

**Next Step:** Identify external dependencies and begin Phase 2 (P0 fixes)

---

**Document Version:** 1.0
**Created:** 2025-11-25
**Status:** COMPLETE
**Next:** Phase 2 - P0 Corrections
