# Analysis: sp_move_node
## AWS SCT Conversion Quality Report

**Analyzed:** 2025-11-22  
**Analyst:** Pierre Ribeiro + Claude (Desktop)  
**AWS SCT Output:** `procedures/aws-sct-converted/sp_move_node.sql`  
**Original T-SQL:** `procedures/original/dbo.sp_move_node.sql`  
**GitHub Issue:** #9  
**Sprint:** Sprint 5 (P2 Priority)

---

## 📊 Executive Summary

| Metric | Score | Status |
|--------|-------|--------|
| Syntax Correctness | 4/10 | ❌ CRITICAL |
| Logic Preservation | 9/10 | ✅ EXCELLENT |
| Performance | 6/10 | ⚠️ NEEDS WORK |
| Maintainability | 4/10 | ❌ POOR |
| Security | 7/10 | ⚠️ ACCEPTABLE |
| **OVERALL SCORE** | **6.2/10** | **⚠️ NEEDS CORRECTIONS** |

### 🎯 Verdict
**NEEDS CORRECTIONS** - Below production-ready threshold (8.0/10)

**Key Issues:**
- ❌ Missing transaction control (tree corruption risk)
- ❌ No error handling (silent failures)
- ❌ Unreadable code (75% AWS SCT warning comments)
- ⚠️ Missing critical indexes (performance degradation)

**Expected Post-Fix Score:** 8.5/10 (if all P0+P1 issues resolved)

---

## 🔍 Context & Complexity Analysis

### Business Logic
Tree manipulation procedure using nested set model. Moves node `@myId` to become child of node `@parentId` while maintaining tree structure integrity.

**Critical Operation:** Must be ATOMIC - partial execution corrupts entire tree structure.

### Size Analysis - **MISLEADING 541% INCREASE**

| Metric | Value | Analysis |
|--------|-------|----------|
| **Original T-SQL** | 32 lines | Clean, compact code |
| **AWS SCT Converted** | 205 lines | **75% are AWS SCT warning comments!** |
| **Real Code Size** | ~50 lines | Actual executable code |
| **Real Growth** | 56% | Much more reasonable |

**ROOT CAUSE:** AWS SCT inserted verbose multi-line warning comments for EVERY reference to columns `tree_scope_key`, `tree_left_key`, `tree_right_key` (5 warnings × ~30 occurrences = 150+ lines of comments).

**FINDING:** Size explosion is AWS SCT verbosity, NOT code complexity.

### AWS SCT Warnings Analysis

**Total Warnings:** 5 (all ERROR 9997 - Severity HIGH)

| Warning | Column | Assessment |
|---------|--------|------------|
| 9997 | tree_scope_key | FALSE POSITIVE - column exists |
| 9997 | tree_left_key | FALSE POSITIVE - column exists |
| 9997 | tree_right_key | FALSE POSITIVE - column exists |

**Explanation:** AWS SCT could not resolve these columns during static analysis (missing schema metadata), but the columns DO exist in the `perseus_dbo.goo` table. The warnings are NOISE.

**Impact:** Warnings themselves are harmless, but the verbose inline comments make code unreadable.

---

## 🚨 Critical Issues (P0) - Must Fix

### 1. Missing Transaction Control ❌ CRITICAL
**Impact:** Tree corruption if any UPDATE fails mid-execution

**Current State:**
```sql
CREATE PROCEDURE sp_move_node(...) AS
BEGIN
    -- 4 UPDATE statements with NO transaction wrapper
    UPDATE perseus_dbo.goo SET tree_left_key = ...;
    UPDATE perseus_dbo.goo SET tree_right_key = ...;
    UPDATE perseus_dbo.goo SET tree_scope_key = ...;
    UPDATE perseus_dbo.goo SET tree_left_key = ...;
    -- If statement 3 fails, statements 1-2 already committed!
END;
```

**Required Fix:**
```sql
CREATE OR REPLACE PROCEDURE perseus_dbo.sp_move_node(
    p_my_id INTEGER,
    p_parent_id INTEGER
) 
LANGUAGE plpgsql
AS $$
DECLARE
    v_my_former_scope VARCHAR(100);
    v_my_former_left INTEGER;
    v_my_former_right INTEGER;
    v_my_parent_scope VARCHAR(100);
    v_my_parent_left INTEGER;
BEGIN
    BEGIN  -- Start transaction block
        -- All 4 UPDATE statements here
        
        RAISE NOTICE 'Successfully moved node % to parent %', p_my_id, p_parent_id;
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Failed to move node % to parent %: %', 
                p_my_id, p_parent_id, SQLERRM
                USING ERRCODE = 'P0001';
            ROLLBACK;
    END;
END;
$$;
```

**Severity:** P0 - CRITICAL BLOCKER  
**Estimated Fix Time:** 15 minutes

---

### 2. No Error Handling ❌ CRITICAL
**Impact:** Silent failures, no debugging information, tree corruption goes undetected

**Current State:**
```sql
-- If this SELECT returns NULL, procedure continues silently
SELECT tree_scope_key, tree_left_key
INTO var_myParentScope, var_myParentLeft
FROM perseus_dbo.goo WHERE id = par_parentId;

-- If parent doesn't exist, this updates NOTHING (0 rows) with no error
UPDATE perseus_dbo.goo SET tree_left_key = ...
WHERE tree_scope_key = var_myParentScope;  -- NULL value!
```

**Required Fix:**
```sql
-- Validate parent exists
SELECT tree_scope_key, tree_left_key
INTO STRICT v_my_parent_scope, v_my_parent_left
FROM perseus_dbo.goo WHERE id = p_parent_id;

IF NOT FOUND THEN
    RAISE EXCEPTION 'Parent node % does not exist', p_parent_id
        USING ERRCODE = 'P0002';
END IF;

-- Validate node to move exists
SELECT tree_scope_key, tree_left_key, tree_right_key
INTO STRICT v_my_former_scope, v_my_former_left, v_my_former_right
FROM perseus_dbo.goo WHERE id = p_my_id;

IF NOT FOUND THEN
    RAISE EXCEPTION 'Node % does not exist', p_my_id
        USING ERRCODE = 'P0002';
END IF;
```

**Severity:** P0 - CRITICAL BLOCKER  
**Estimated Fix Time:** 30 minutes

---

### 3. Verbose AWS SCT Warning Comments ❌ UNREADABLE
**Impact:** Code review impossible, maintenance nightmare, git diffs unusable

**Current State:** (example from line 10-15)
```sql
UPDATE perseus_dbo.goo
SET tree_left_key
/*
[9997 - Severity HIGH - Unable to resolve the object tree_left_key. 
Verify if the unresolved object is present in the database. If it isn't, 
check the object name or add the object. If the object is present, 
transform the code manually.]
tree_left_key
*/
= tree_left_key
/*
[9997 - Severity HIGH - Unable to resolve the object tree_left_key...] 
tree_left_key
*/
+ (var_myFormerRight - var_myFormerLeft) + 1
WHERE tree_left_key
/*
[9997 - Severity HIGH - Unable to resolve...]
*/
> var_myParentLeft;
```

**Result:** 15 lines for what should be 2 lines of code.

**Required Fix:** **STRIP ALL AWS SCT WARNING COMMENTS**

**Clean Version:**
```sql
UPDATE perseus_dbo.goo
SET tree_left_key = tree_left_key + (v_my_former_right - v_my_former_left) + 1
WHERE tree_left_key > v_my_parent_left
  AND tree_scope_key = v_my_parent_scope;
```

**Severity:** P0 - CRITICAL (makes code unmaintainable)  
**Estimated Fix Time:** 10 minutes (automated find/replace)

---

## ⚠️ High Priority Issues (P1) - Should Fix

### 1. Missing Composite Indexes 🔥 PERFORMANCE
**Impact:** Full table scans on tree operations, 10-100× slower than SQL Server

**Required Indexes:**
```sql
-- Index for tree_left_key range scans with scope filtering
CREATE INDEX idx_goo_tree_scope_left 
ON perseus_dbo.goo(tree_scope_key, tree_left_key)
WHERE tree_scope_key IS NOT NULL;

-- Index for tree_right_key range scans with scope filtering
CREATE INDEX idx_goo_tree_scope_right 
ON perseus_dbo.goo(tree_scope_key, tree_right_key)
WHERE tree_scope_key IS NOT NULL;

-- Analyze table after index creation
ANALYZE perseus_dbo.goo;
```

**Performance Estimate:**
- **Before:** Full table scan (1000+ rows) = 50-100ms
- **After:** Index scan (10-50 rows) = 1-5ms
- **Improvement:** 10-20× faster

**Severity:** P1 - HIGH  
**Estimated Fix Time:** 5 minutes

---

### 2. No Documentation 📝
**Impact:** Developers don't understand what procedure does, how to use it, or what it affects

**Required Fix:**
```sql
/*******************************************************************************
* Procedure: sp_move_node
* Purpose: Move a node in the tree hierarchy using nested set model
* 
* Parameters:
*   p_my_id      - ID of node to move
*   p_parent_id  - ID of new parent node
*
* Business Rules:
*   - Both nodes must exist
*   - Cannot move node to be its own parent
*   - Cannot create cycles (node becoming descendant of itself)
*   - All tree keys (left/right/scope) are recalculated atomically
*
* Performance:
*   - Requires composite indexes on (tree_scope_key, tree_left_key/tree_right_key)
*   - Affects all nodes in source and target scopes
*   - Transaction-safe: all-or-nothing operation
*
* Example Usage:
*   CALL perseus_dbo.sp_move_node(123, 456);  -- Move node 123 under node 456
*
* Version History:
*   2025-11-22 - Initial PostgreSQL conversion (AWS SCT + manual fixes)
*
* Related Procedures:
*   - ProcessDirtyTrees (tree maintenance)
*   - AddArc/RemoveArc (arc operations)
*******************************************************************************/
```

**Severity:** P1 - HIGH  
**Estimated Fix Time:** 20 minutes

---

### 3. Unnecessary Type Casting ⚡
**Impact:** Minor performance overhead (1-2%), code clutter

**Current State:**
```sql
WHERE tree_scope_key = var_myParentScope::VARCHAR
```

**Issue:** `var_myParentScope` is already `VARCHAR(100)`, so casting is redundant.

**Fix:**
```sql
WHERE tree_scope_key = v_my_parent_scope
```

**Severity:** P1 - MEDIUM  
**Estimated Fix Time:** 5 minutes (automated find/replace)

---

### 4. Poor Naming Conventions 🏷️
**Impact:** Inconsistent code style, harder to maintain

**Current AWS SCT Names:**
```sql
var_myFormerScope    -- Inconsistent: camelCase with prefix
var_myFormerLeft
par_parentId         -- Inconsistent: camelCase parameter
```

**PostgreSQL Convention:**
```sql
v_my_former_scope    -- Consistent: lowercase_with_underscores
v_my_former_left
p_parent_id          -- Consistent: lowercase_with_underscores
```

**Severity:** P1 - LOW (cosmetic but important for standards)  
**Estimated Fix Time:** 10 minutes (automated find/replace)

---

## 💡 Medium Priority Issues (P2) - Nice to Have

### 1. No Observability 📊
**Impact:** Cannot track procedure execution, debug issues, or monitor performance

**Recommended Additions:**
```sql
RAISE NOTICE 'sp_move_node: Starting move of node % to parent %', p_my_id, p_parent_id;
RAISE NOTICE 'sp_move_node: Former position - scope:%, left:%, right:%', 
    v_my_former_scope, v_my_former_left, v_my_former_right;
RAISE NOTICE 'sp_move_node: New parent - scope:%, left:%', 
    v_my_parent_scope, v_my_parent_left;
RAISE NOTICE 'sp_move_node: Successfully moved node % to parent %', p_my_id, p_parent_id;
```

**Benefits:**
- Debugging support
- Performance monitoring (can log execution time)
- Audit trail (who moved what when)

**Severity:** P2 - NICE TO HAVE  
**Estimated Fix Time:** 15 minutes

---

### 2. No Business Validations 🛡️
**Impact:** Procedure allows invalid tree states (cycles, self-parenting)

**Missing Validations:**
```sql
-- Prevent self-parenting
IF p_my_id = p_parent_id THEN
    RAISE EXCEPTION 'Cannot move node to be its own parent'
        USING ERRCODE = 'P0003';
END IF;

-- Prevent moving node to be descendant of itself (cycle detection)
IF EXISTS (
    SELECT 1 FROM perseus_dbo.goo
    WHERE id = p_parent_id
      AND tree_scope_key = v_my_former_scope
      AND tree_left_key > v_my_former_left
      AND tree_right_key < v_my_former_right
) THEN
    RAISE EXCEPTION 'Cannot move node % to descendant % (would create cycle)', 
        p_my_id, p_parent_id
        USING ERRCODE = 'P0003';
END IF;
```

**Severity:** P2 - MEDIUM (business logic, not technical)  
**Estimated Fix Time:** 30 minutes

---

### 3. No Audit Trail 📜
**Impact:** Cannot track who moved what when (compliance, debugging)

**Recommended Addition:**
```sql
-- Insert audit record
INSERT INTO perseus_dbo.tree_audit_log (
    operation_type,
    node_id,
    old_parent_id,
    new_parent_id,
    operation_timestamp,
    operation_user
) VALUES (
    'MOVE_NODE',
    p_my_id,
    (SELECT parent_id FROM perseus_dbo.goo WHERE id = p_my_id),
    p_parent_id,
    CURRENT_TIMESTAMP,
    CURRENT_USER
);
```

**Severity:** P2 - LOW (requires audit table creation)  
**Estimated Fix Time:** 45 minutes (including table creation)

---

## 📝 Instructions for Code Web Environment

### File Output
**Path:** `procedures/corrected/sp_move_node.sql`

### Template Base
Use: `templates/postgresql-procedure-template.sql`

---

### P0 Fixes Required (CRITICAL - Must Do)

#### 1. Strip AWS SCT Warning Comments
**Find:** All comment blocks matching pattern:
```
/*
[9997 - Severity HIGH - Unable to resolve...]
column_name
*/
```

**Replace:** Remove entirely (keep only code)

**Result:** File size drops from 205 lines to ~50 lines.

---

#### 2. Add Transaction Control Block
**Wrap entire procedure logic:**
```sql
CREATE OR REPLACE PROCEDURE perseus_dbo.sp_move_node(
    p_my_id INTEGER,
    p_parent_id INTEGER
) 
LANGUAGE plpgsql
AS $$
DECLARE
    -- declarations here
BEGIN
    BEGIN  -- ← START TRANSACTION BLOCK
        -- All SELECT and UPDATE statements here
        
        RAISE NOTICE 'Successfully moved node % to parent %', p_my_id, p_parent_id;
        
    EXCEPTION  -- ← ERROR HANDLER
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Failed to move node % to parent %: %', 
                p_my_id, p_parent_id, SQLERRM
                USING ERRCODE = 'P0001';
            ROLLBACK;
    END;  -- ← END TRANSACTION BLOCK
END;
$$;
```

---

#### 3. Add Existence Validation
**Before first SELECT, add:**
```sql
-- Validate parent node exists
SELECT tree_scope_key, tree_left_key
INTO STRICT v_my_parent_scope, v_my_parent_left
FROM perseus_dbo.goo 
WHERE id = p_parent_id;

IF NOT FOUND THEN
    RAISE EXCEPTION 'Parent node % does not exist', p_parent_id
        USING ERRCODE = 'P0002';
END IF;

-- Validate node to move exists
SELECT tree_scope_key, tree_left_key, tree_right_key
INTO STRICT v_my_former_scope, v_my_former_left, v_my_former_right
FROM perseus_dbo.goo 
WHERE id = p_my_id;

IF NOT FOUND THEN
    RAISE EXCEPTION 'Node % does not exist', p_my_id
        USING ERRCODE = 'P0002';
END IF;
```

---

### P1 Optimizations (HIGH - Should Do)

#### 1. Create Composite Indexes
**Execute AFTER procedure creation:**
```sql
-- Index for left_key range scans
CREATE INDEX IF NOT EXISTS idx_goo_tree_scope_left 
ON perseus_dbo.goo(tree_scope_key, tree_left_key)
WHERE tree_scope_key IS NOT NULL;

-- Index for right_key range scans
CREATE INDEX IF NOT EXISTS idx_goo_tree_scope_right 
ON perseus_dbo.goo(tree_scope_key, tree_right_key)
WHERE tree_scope_key IS NOT NULL;

-- Update statistics
ANALYZE perseus_dbo.goo;
```

---

#### 2. Add Procedure Header Documentation
**Insert at top of file:**
```sql
/*******************************************************************************
* Procedure: sp_move_node
* Purpose: Move a node in the tree hierarchy using nested set model
* 
* Parameters:
*   p_my_id      - ID of node to move
*   p_parent_id  - ID of new parent node
*
* Business Rules:
*   - Both nodes must exist
*   - All tree keys recalculated atomically
*   - Transaction-safe operation
*
* Performance:
*   - Requires indexes on (tree_scope_key, tree_left_key/tree_right_key)
*
* Example: CALL perseus_dbo.sp_move_node(123, 456);
* Version: 2025-11-22 - PostgreSQL conversion
*******************************************************************************/
```

---

#### 3. Fix Naming Conventions
**Find and Replace:**
```
var_myFormerScope     → v_my_former_scope
var_myFormerLeft      → v_my_former_left
var_myFormerRight     → v_my_former_right
var_myParentScope     → v_my_parent_scope
var_myParentLeft      → v_my_parent_left
par_parentId          → p_parent_id
par_myId              → p_my_id
```

---

#### 4. Remove Unnecessary Type Casting
**Find:** `::VARCHAR` casts on variables that are already VARCHAR
**Replace:** Remove the cast

**Example:**
```sql
-- Before
WHERE tree_scope_key = var_myParentScope::VARCHAR

-- After
WHERE tree_scope_key = v_my_parent_scope
```

---

### Additional Notes

**Dependencies:**
- Table: `perseus_dbo.goo` must have columns: `id`, `tree_scope_key`, `tree_left_key`, `tree_right_key`
- Indexes: Create the 2 composite indexes BEFORE performance testing

**Testing Requirements:**
1. Test with valid nodes (should succeed)
2. Test with non-existent parent (should raise exception)
3. Test with non-existent node (should raise exception)
4. Test transaction rollback (kill mid-execution, verify no partial changes)
5. Performance test with 1000+ nodes in tree

**Risk Mitigation:**
- Test in DEV environment first
- Backup `goo` table before testing
- Monitor execution time (should be <100ms for typical trees)
- Verify tree integrity after each test (no orphaned nodes, no broken ranges)

---

## 📊 Expected Results

### Post-Correction Quality Score
**Expected:** 8.5/10 (production-ready)

| Dimension | Before | After | Change |
|-----------|--------|-------|--------|
| Syntax Correctness | 4/10 | 9/10 | +5 ✅ |
| Logic Preservation | 9/10 | 9/10 | 0 (already excellent) |
| Performance | 6/10 | 8/10 | +2 ✅ |
| Maintainability | 4/10 | 8/10 | +4 ✅ |
| Security | 7/10 | 8/10 | +1 ✅ |

### Validation Criteria
- ✅ Syntax validates in PostgreSQL 16+
- ✅ All P0 issues resolved (transaction control, error handling, comments)
- ✅ Performance within 20% of SQL Server baseline (with indexes)
- ✅ Code is readable and maintainable
- ✅ Test coverage plan defined (5 test cases)

---

## 🎯 Comparison with Project Baseline

### Project Statistics (9 procedures analyzed)
- **Average Quality Score:** 6.39/10
- **Best Score:** RemoveArc (8.1/10)
- **Worst Score:** ProcessDirtyTrees (4.75/10)

### sp_move_node Performance
- **Current Score:** 6.2/10 (slightly below average)
- **Post-Fix Score:** 8.5/10 (above best in project) ✅
- **Ranking:** Will be 2nd best (after RemoveArc)

### Similar Procedures
- **AddArc:** 5.5/10 (tree manipulation, similar issues)
- **ProcessDirtyTrees:** 4.75/10 (complex tree processing)

**Key Differentiator:** sp_move_node has simpler logic (4 UPDATEs vs recursive cursors), making it easier to fix.

---

## 🔗 References

- **Analysis Template:** `procedures/analysis/reconcilemupstream-analysis.md`
- **PostgreSQL Template:** `templates/postgresql-procedure-template.sql`
- **Priority Matrix:** `tracking/priority-matrix.csv`
- **Related Procedures:** ProcessDirtyTrees, AddArc, RemoveArc (tree operations)
- **GitHub Issue:** #9 - [Sprint 5] Analysis: sp_move_node

---

## 📈 Project Impact

### Milestone Progress
- **Analyzed:** 9 of 15 procedures (60%)
- **Sprint 5:** 2 of 3 procedures analyzed (sp_move_node complete)
- **Remaining:** TransitionToMaterial (Sprint 5), MaterialToTransition (Sprint 6), 4 procedures (Sprints 7-8)

### Pattern Library Updates
**New Pattern Identified:**
- ✅ AWS SCT creates verbose warning comments for unresolved columns (false positives)
- ✅ Comment removal is CRITICAL P0 fix for readability
- ✅ Tree manipulation requires ATOMIC operations (transaction control mandatory)

### Risk Assessment Update
**sp_move_node Risk:** MEDIUM → LOW (after P0 fixes)
- Logic is sound (9/10 preservation)
- Issues are systematic (same as other procedures)
- Fixes are straightforward (no complex refactoring needed)

---

## ✅ Ready for Correction Phase

**Status:** ✅ ANALYSIS COMPLETE  
**Next Step:** Delegate to Claude Code Web for corrected procedure generation  
**Estimated Correction Time:** 2-3 hours (P0+P1 fixes + testing)  
**Priority:** HIGH (P2 procedure, Sprint 5)

---

**Analysis completed:** 2025-11-22  
**Analyst:** Pierre Ribeiro + Claude (Desktop)  
**Quality Score:** 6.2/10 → 8.5/10 (projected)  
**Recommendation:** PROCEED TO CORRECTION

---

*End of Analysis Report - sp_move_node*