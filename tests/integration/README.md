# Integration Tests

## 📁 Directory Purpose

This directory contains **integration tests** that validate multiple procedures working together, testing real-world workflows and cross-procedure dependencies.

**Test Scope:** Multiple procedures, real database objects, end-to-end workflows

**Test Framework:** pgTAP + Custom SQL scripts

---

## 🎯 Integration Testing Philosophy

**Test Real-World Workflows**

Integration tests should:
- ✅ Test multiple procedures in sequence
- ✅ Use actual database schema (no mocking)
- ✅ Verify data flows between procedures
- ✅ Test transaction boundaries across procedures
- ✅ Validate referential integrity
- ✅ Simulate production scenarios

**Coverage Goal:** All critical business workflows tested

---

## 📋 Test Structure

### Workflow Test Template

```sql
-- =============================================================================
-- Integration Test: Material Reconciliation Workflow
-- Author: Pierre Ribeiro
-- Created: YYYY-MM-DD
-- Framework: pgTAP + Custom
-- =============================================================================

BEGIN;

SELECT plan(20);  -- Number of tests in workflow

-- =============================================================================
-- TEST SETUP: Prepare Environment
-- =============================================================================

-- Use real schema (not mocked)
SET search_path TO perseus, public;

-- Clean existing test data
DELETE FROM M_Upstream WHERE MaterialID BETWEEN 90000 AND 99999;
DELETE FROM M_Downstream WHERE MaterialID BETWEEN 90000 AND 99999;
DELETE FROM Materials WHERE MaterialID BETWEEN 90000 AND 99999;

-- Insert test dataset (realistic data)
INSERT INTO Materials (MaterialID, MaterialName, Status) VALUES
    (90001, 'Test Material A', 'Active'),
    (90002, 'Test Material B', 'Active'),
    (90003, 'Test Material C', 'Pending');

INSERT INTO M_Upstream (MaterialID, ParentID, Quantity) VALUES
    (90001, 1000, 100),
    (90002, 1000, 200);

-- =============================================================================
-- WORKFLOW TEST: Complete Material Reconciliation
-- =============================================================================

-- Step 1: Add Arc (create relationship)
SELECT lives_ok(
    $$SELECT * FROM AddArc(90001, 90002, 'PARENT_CHILD')$$,
    'Step 1: AddArc executes successfully'
);

SELECT is(
    (SELECT COUNT(*) FROM Material_Arcs 
     WHERE MaterialID = 90001 AND RelatedID = 90002),
    1,
    'Step 1: Arc created in Material_Arcs table'
);

-- Step 2: Process Upstream (reconcile hierarchy)
SELECT lives_ok(
    $$SELECT * FROM ReconcileMUpstream(90001, 'Active')$$,
    'Step 2: ReconcileMUpstream executes successfully'
);

SELECT ok(
    (SELECT COUNT(*) FROM M_Upstream WHERE MaterialID = 90001) > 0,
    'Step 2: M_Upstream updated'
);

-- Step 3: Update Downstream (propagate changes)
SELECT lives_ok(
    $$CALL usp_UpdateMDownstream(90002)$$,
    'Step 3: UpdateMDownstream executes successfully'
);

SELECT is(
    (SELECT Status FROM M_Downstream WHERE MaterialID = 90002),
    'Active',
    'Step 3: Downstream status propagated correctly'
);

-- Step 4: Link Materials (finalize relationships)
SELECT lives_ok(
    $$SELECT * FROM LinkUnlinkedMaterials()$$,
    'Step 4: LinkUnlinkedMaterials executes successfully'
);

-- =============================================================================
-- VALIDATION: Verify Complete Workflow Results
-- =============================================================================

-- Check referential integrity
SELECT is(
    (SELECT COUNT(*) FROM M_Upstream mu
     WHERE NOT EXISTS (
         SELECT 1 FROM Materials m WHERE m.MaterialID = mu.MaterialID
     )),
    0,
    'All M_Upstream records have valid Materials FK'
);

-- Check data consistency
SELECT is(
    (SELECT COUNT(*) FROM M_Upstream WHERE MaterialID = 90001),
    (SELECT COUNT(*) FROM M_Downstream WHERE MaterialID = 90001),
    'Upstream and Downstream record counts match'
);

-- Check transaction atomicity
BEGIN;
    -- Attempt workflow that should fail
    SELECT throws_ok(
        $$SELECT * FROM AddArc(NULL, 90002, 'INVALID')$$,
        'Workflow fails atomically on bad input'
    );
ROLLBACK;

-- Verify original state preserved
SELECT is(
    (SELECT COUNT(*) FROM Material_Arcs WHERE MaterialID IS NULL),
    0,
    'Failed transaction did not corrupt data'
);

-- =============================================================================
-- TEST CLEANUP
-- =============================================================================

-- Remove test data
DELETE FROM M_Upstream WHERE MaterialID BETWEEN 90000 AND 99999;
DELETE FROM M_Downstream WHERE MaterialID BETWEEN 90000 AND 99999;
DELETE FROM Material_Arcs WHERE MaterialID BETWEEN 90000 AND 99999;
DELETE FROM Materials WHERE MaterialID BETWEEN 90000 AND 99999;

SELECT * FROM finish();

ROLLBACK;
```

---

## 🔍 Test Categories

### 1. Workflow Tests
Test complete business processes end-to-end:

```sql
-- Example: Material Creation → Linking → Reconciliation → Transition
test_material_complete_lifecycle.sql
test_container_movement_workflow.sql
test_upstream_downstream_sync.sql
```

### 2. Cross-Procedure Dependency Tests
```sql
-- Test procedures that call other procedures
SELECT lives_ok(
    'CALL ProcessSomeMUpstream(1)',
    'Parent procedure calls child procedures successfully'
);

-- Verify all dependencies executed
SELECT is(
    (SELECT COUNT(*) FROM audit_log 
     WHERE procedure_name IN ('ReconcileMUpstream', 'UpdateMDownstream')),
    2,
    'All dependent procedures executed'
);
```

### 3. Transaction Boundary Tests
```sql
-- Test multi-procedure transactions
BEGIN;
    SELECT AddArc(1, 2, 'PARENT');
    SELECT ReconcileMUpstream(1, 'Active');
    -- Simulate error
    SELECT 1/0;  -- Division by zero
EXCEPTION WHEN OTHERS THEN
    ROLLBACK;
END;

-- Verify complete rollback
SELECT is(
    (SELECT COUNT(*) FROM Material_Arcs WHERE MaterialID = 1),
    0,
    'Transaction rolled back all changes'
);
```

### 4. Data Integrity Tests
```sql
-- Test referential integrity across procedures
SELECT is(
    (SELECT COUNT(*) FROM M_Upstream mu
     WHERE MaterialID NOT IN (SELECT MaterialID FROM Materials)),
    0,
    'No orphaned M_Upstream records'
);

SELECT is(
    (SELECT COUNT(*) FROM M_Downstream md
     WHERE MaterialID NOT IN (SELECT MaterialID FROM Materials)),
    0,
    'No orphaned M_Downstream records'
);
```

### 5. Concurrency Tests
```sql
-- Test multiple procedures running concurrently
-- (Requires database connection pooling)

-- Session 1
BEGIN;
    SELECT ReconcileMUpstream(1, 'Active');
    -- Hold lock

-- Session 2 (concurrent)
SELECT throws_ok(
    'SELECT ReconcileMUpstream(1, "Pending")',
    '55P03',  -- Lock timeout
    'Concurrent modification properly blocked'
);

COMMIT;  -- Session 1
```

---

## 🛠️ Running Tests

### Single Integration Test
```bash
# Run one workflow test
psql -h localhost -d perseus_test -f tests/integration/test_material_workflow.sql

# With detailed output
psql -h localhost -d perseus_test \
  -f tests/integration/test_material_workflow.sql \
  -v ON_ERROR_STOP=1 \
  --echo-errors
```

### All Integration Tests
```bash
# Run all tests sequentially
for test in tests/integration/test_*.sql; do
  echo "=========================================="
  echo "Running: $(basename $test)"
  echo "=========================================="
  psql -h localhost -d perseus_test -f "$test"
  
  if [ $? -ne 0 ]; then
    echo "❌ FAILED: $test"
    exit 1
  fi
done

echo "✅ All integration tests passed"
```

### Parallel Execution (Advanced)
```bash
# Run tests in parallel (use with caution!)
parallel -j 4 'psql -h localhost -d perseus_test -f {}' ::: tests/integration/test_*.sql
```

---

## 📊 Test Scenarios

### Scenario 1: Material Complete Lifecycle
**File:** `test_material_complete_lifecycle.sql`

**Workflow:**
1. Create Material (via AddMaterial)
2. Add upstream relationships (via AddArc)
3. Reconcile upstream (via ReconcileMUpstream)
4. Update downstream (via usp_UpdateMDownstream)
5. Transition to new state (via MaterialToTransition)
6. Verify final state

**Success Criteria:**
- All steps execute without errors
- Data consistency maintained throughout
- Referential integrity preserved
- Audit trail complete

---

### Scenario 2: Container Movement
**File:** `test_container_movement_workflow.sql`

**Workflow:**
1. Create container hierarchy
2. Move container (via MoveContainer)
3. Update related materials (via usp_UpdateContainerTypeFromArgus)
4. Verify container location
5. Verify material locations updated

**Success Criteria:**
- Container moved to correct location
- Child containers moved with parent
- Material locations updated
- No orphaned relationships

---

### Scenario 3: Dirty Tree Processing
**File:** `test_dirty_tree_processing.sql`

**Workflow:**
1. Mark trees as dirty (data changes)
2. Process dirty trees (via ProcessDirtyTrees)
3. Process M_Upstream (via ProcessSomeMUpstream)
4. Reconcile all (via ReconcileMUpstream)
5. Verify clean state

**Success Criteria:**
- All dirty flags cleared
- Trees reprocessed correctly
- Data consistency restored
- Performance acceptable

---

## 🎯 Test Data Management

### Test Database Setup
```bash
# Create dedicated test database
createdb perseus_test

# Restore schema (no production data)
pg_restore -d perseus_test --schema-only perseus_prod_backup.dump

# Load test fixtures
psql -d perseus_test -f tests/fixtures/sample_materials.sql
psql -d perseus_test -f tests/fixtures/sample_containers.sql
psql -d perseus_test -f tests/fixtures/sample_relationships.sql
```

### Test Data Isolation
```sql
-- Use dedicated test ID ranges
-- Test data: 90000-99999
-- Production data: 1-89999

-- Easy cleanup
DELETE FROM Materials WHERE MaterialID BETWEEN 90000 AND 99999;
```

### Test Fixtures
Located in: `/tests/fixtures/`

- `sample_materials.sql` - Representative material data
- `sample_containers.sql` - Container hierarchy
- `sample_relationships.sql` - Material relationships
- `sample_arcs.sql` - Upstream/downstream arcs

---

## 📈 Performance Tracking

### Execution Time Monitoring
```sql
-- Wrap workflow in timing
\timing on

BEGIN;
    -- Run workflow
    SELECT * FROM test_material_workflow();
    
    -- Log execution time
    INSERT INTO test_performance_log VALUES
        ('test_material_workflow', 
         clock_timestamp() - transaction_timestamp(),
         current_timestamp);
COMMIT;

\timing off
```

### Performance Baseline
```sql
-- Establish baseline (first run in clean environment)
-- Target: All integration tests < 10 seconds total

-- Example targets per workflow:
-- test_material_workflow: < 2 seconds
-- test_container_movement: < 1 second
-- test_dirty_trees: < 5 seconds (more complex)
```

---

## 🚀 CI/CD Integration

### GitHub Actions Workflow
```yaml
name: Integration Tests

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  integration-test:
    runs-on: ubuntu-latest
    
    services:
      postgres:
        image: postgres:16
        env:
          POSTGRES_DB: perseus_test
          POSTGRES_PASSWORD: postgres
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Test Database
        run: |
          psql -h localhost -U postgres -d perseus_test \
            -f scripts/setup-test-db.sql
      
      - name: Load Test Fixtures
        run: |
          for fixture in tests/fixtures/*.sql; do
            psql -h localhost -U postgres -d perseus_test -f "$fixture"
          done
      
      - name: Run Integration Tests
        run: |
          for test in tests/integration/test_*.sql; do
            echo "Running $(basename $test)..."
            psql -h localhost -U postgres -d perseus_test -f "$test"
          done
      
      - name: Collect Test Results
        if: always()
        run: |
          psql -h localhost -U postgres -d perseus_test \
            -c "SELECT * FROM test_results;" > test-report.txt
      
      - name: Upload Results
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: integration-test-results
          path: test-report.txt
```

---

## 🔗 Related Documentation

- Unit tests: `/tests/unit/`
- Performance tests: `/tests/performance/`
- Test fixtures: `/tests/fixtures/`
- Validation scripts: `/scripts/validation/`

---

## 🚨 Troubleshooting

### Test Hangs or Times Out
```bash
# Check for locks
psql -c "SELECT * FROM pg_locks WHERE NOT granted;"

# Kill hanging queries
psql -c "SELECT pg_terminate_backend(pid) 
         FROM pg_stat_activity 
         WHERE state = 'idle in transaction';"
```

### Test Data Contamination
```bash
# Reset test database completely
dropdb perseus_test
createdb perseus_test
psql -d perseus_test -f scripts/setup-test-db.sql
```

### Flaky Tests (Intermittent Failures)
```bash
# Run test multiple times to identify flakiness
for i in {1..10}; do
  echo "Run $i:"
  psql -f tests/integration/test_suspect.sql
done
```

---

**Maintained by:** Pierre Ribeiro (DBA/DBRE)  
**Last Updated:** 2025-11-13  
**Version:** 1.0
