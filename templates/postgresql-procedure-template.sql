-- ============================================================================
-- POSTGRESQL PROCEDURE TEMPLATE - Perseus Project
-- ============================================================================
-- Purpose: Standard template for T-SQL to PL/pgSQL conversion
-- Author: Pierre Ribeiro (Database Reliability Engineer)
-- Created: 2025-11-13
-- Version: 1.0
-- 
-- Based on: ReconcileMUpstream analysis (aws-sct-conversion-analysis)
-- Compliance: PostgreSQL 16+ best practices
-- 
-- KEY PRINCIPLES:
-- 1. Performance first (avoid unnecessary operations)
-- 2. Simplicity over complexity (no "hadouken" code)
-- 3. Explicit transaction control
-- 4. Comprehensive error handling
-- 5. Observability built-in
-- ============================================================================

-- ============================================================================
-- PROCEDURE HEADER
-- ============================================================================
CREATE OR REPLACE PROCEDURE schema_name.procedure_name(
    -- Input parameters (use explicit types)
    p_param1 VARCHAR(50),
    p_param2 INTEGER DEFAULT NULL,
    p_param3 BOOLEAN DEFAULT FALSE
)
LANGUAGE plpgsql
AS $BODY$

-- ============================================================================
-- VARIABLE DECLARATIONS
-- ============================================================================
DECLARE
    -- Business logic variables
    v_row_count INTEGER := 0;
    v_affected_rows INTEGER := 0;
    
    -- Performance tracking variables
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
    v_execution_time_ms INTEGER;
    
    -- Error handling variables
    v_error_message TEXT;
    v_error_state TEXT;
    v_error_detail TEXT;
    
    -- Constants (use for magic numbers)
    c_batch_size CONSTANT INTEGER := 100;
    c_procedure_name CONSTANT VARCHAR(100) := 'procedure_name';

BEGIN
    -- ========================================================================
    -- INITIALIZATION
    -- ========================================================================
    v_start_time := clock_timestamp();
    
    RAISE NOTICE '[%] Starting execution with params: p_param1=%, p_param2=%', 
                 c_procedure_name, p_param1, p_param2;
    
    -- ========================================================================
    -- INPUT VALIDATION
    -- ========================================================================
    -- Validate required parameters
    IF p_param1 IS NULL OR p_param1 = '' THEN
        RAISE EXCEPTION '[%] Required parameter p_param1 is null or empty', 
                        c_procedure_name
              USING ERRCODE = 'P0001',
                    HINT = 'Provide a valid value for p_param1';
    END IF;
    
    -- Validate business rules
    IF p_param2 IS NOT NULL AND p_param2 < 0 THEN
        RAISE EXCEPTION '[%] Invalid parameter p_param2: % (must be >= 0)', 
                        c_procedure_name, p_param2
              USING ERRCODE = 'P0001';
    END IF;
    
    -- ========================================================================
    -- DEFENSIVE CLEANUP
    -- ========================================================================
    -- Drop leftover temp tables from failed previous runs
    -- NOTE: This prevents "table already exists" errors
    DROP TABLE IF EXISTS temp_working_data;
    DROP TABLE IF EXISTS temp_results;
    
    -- ========================================================================
    -- TEMPORARY TABLE CREATION
    -- ========================================================================
    -- CRITICAL: Always use ON COMMIT DROP for automatic cleanup
    -- PERFORMANCE: Add primary keys for join optimization
    
    CREATE TEMPORARY TABLE temp_working_data (
        id INTEGER,
        value VARCHAR(100),
        status VARCHAR(20),
        processed_at TIMESTAMP,
        PRIMARY KEY (id)
    ) ON COMMIT DROP;
    
    CREATE TEMPORARY TABLE temp_results (
        source_id INTEGER,
        target_id INTEGER,
        delta_value NUMERIC(10,2),
        PRIMARY KEY (source_id, target_id)
    ) ON COMMIT DROP;
    
    -- ========================================================================
    -- MAIN TRANSACTION BLOCK
    -- ========================================================================
    -- CRITICAL: Explicit transaction control for proper rollback
    BEGIN
        
        -- ====================================================================
        -- STEP 1: DATA COLLECTION
        -- ====================================================================
        RAISE NOTICE '[%] Step 1: Collecting data...', c_procedure_name;
        
        -- PERFORMANCE TIP: Avoid LOWER() if data is already normalized
        -- BAD:  WHERE LOWER(column) = LOWER('value')
        -- GOOD: WHERE column = 'value'
        
        INSERT INTO temp_working_data (id, value, status, processed_at)
        SELECT 
            t.id,
            t.value,
            t.status,
            CURRENT_TIMESTAMP
        FROM source_table t
        WHERE t.status = 'PENDING'  -- No LOWER() needed if data is normalized
          AND t.created_at >= CURRENT_DATE - INTERVAL '30 days'
          AND t.id = p_param1;  -- Use parameters directly, avoid LOWER()
        
        GET DIAGNOSTICS v_row_count = ROW_COUNT;
        RAISE NOTICE '[%] Step 1 complete: % rows collected', 
                     c_procedure_name, v_row_count;
        
        -- Early exit if no data to process
        IF v_row_count = 0 THEN
            RAISE NOTICE '[%] No data found for processing, exiting early', 
                         c_procedure_name;
            RETURN;  -- Clean exit
        END IF;
        
        -- ====================================================================
        -- STEP 2: DATA TRANSFORMATION
        -- ====================================================================
        RAISE NOTICE '[%] Step 2: Transforming data...', c_procedure_name;
        
        -- SIMPLICITY TIP: Break complex logic into clear steps
        -- Avoid deeply nested IFs and loops ("hadouken" code)
        
        -- Calculate deltas
        INSERT INTO temp_results (source_id, target_id, delta_value)
        SELECT 
            t1.id AS source_id,
            t2.id AS target_id,
            (t2.amount - t1.amount) AS delta_value
        FROM temp_working_data t1
        INNER JOIN target_table t2 
            ON t1.id = t2.source_id  -- Use indexed columns for joins
        WHERE t2.status = 'ACTIVE'
          AND ABS(t2.amount - t1.amount) > 0.01;  -- Avoid floating point equality
        
        GET DIAGNOSTICS v_row_count = ROW_COUNT;
        RAISE NOTICE '[%] Step 2 complete: % deltas calculated', 
                     c_procedure_name, v_row_count;
        
        -- ====================================================================
        -- STEP 3: DATA PERSISTENCE
        -- ====================================================================
        RAISE NOTICE '[%] Step 3: Persisting changes...', c_procedure_name;
        
        -- PERFORMANCE TIP: Use batch operations, avoid row-by-row updates
        -- Use EXISTS for conditional logic instead of COUNT(*)
        
        -- Insert new records
        INSERT INTO final_table (source_id, target_id, delta_value, created_at)
        SELECT 
            r.source_id,
            r.target_id,
            r.delta_value,
            CURRENT_TIMESTAMP
        FROM temp_results r
        WHERE NOT EXISTS (
            SELECT 1 
            FROM final_table f
            WHERE f.source_id = r.source_id 
              AND f.target_id = r.target_id
        );
        
        GET DIAGNOSTICS v_affected_rows = ROW_COUNT;
        RAISE NOTICE '[%] Step 3 complete: % rows inserted', 
                     c_procedure_name, v_affected_rows;
        
        -- ====================================================================
        -- STEP 4: CLEANUP & FINALIZATION
        -- ====================================================================
        RAISE NOTICE '[%] Step 4: Finalizing...', c_procedure_name;
        
        -- Update status in source table
        UPDATE source_table
        SET 
            status = 'PROCESSED',
            processed_at = CURRENT_TIMESTAMP,
            processed_by = current_user
        WHERE id IN (SELECT id FROM temp_working_data);
        
        GET DIAGNOSTICS v_row_count = ROW_COUNT;
        RAISE NOTICE '[%] Step 4 complete: % rows updated', 
                     c_procedure_name, v_row_count;
        
        -- ====================================================================
        -- SUCCESS METRICS
        -- ====================================================================
        v_end_time := clock_timestamp();
        v_execution_time_ms := EXTRACT(MILLISECONDS FROM (v_end_time - v_start_time));
        
        RAISE NOTICE '[%] Execution completed successfully in % ms (affected: % rows)', 
                     c_procedure_name, v_execution_time_ms, v_affected_rows;
        
        -- Optional: Log to audit table
        -- INSERT INTO audit_log (procedure_name, status, rows_affected, execution_time_ms)
        -- VALUES (c_procedure_name, 'SUCCESS', v_affected_rows, v_execution_time_ms);
        
    EXCEPTION
        WHEN OTHERS THEN
            -- ================================================================
            -- ERROR HANDLING
            -- ================================================================
            -- CRITICAL: Proper rollback and error propagation
            ROLLBACK;
            
            -- Capture error details
            GET STACKED DIAGNOSTICS 
                v_error_state = RETURNED_SQLSTATE,
                v_error_message = MESSAGE_TEXT,
                v_error_detail = PG_EXCEPTION_DETAIL;
            
            -- Log error
            RAISE WARNING '[%] Execution failed - SQLSTATE: %, Message: %, Detail: %', 
                          c_procedure_name, v_error_state, v_error_message, v_error_detail;
            
            -- Optional: Log to audit table
            -- INSERT INTO audit_log (procedure_name, status, error_message)
            -- VALUES (c_procedure_name, 'FAILED', v_error_message);
            
            -- Re-raise with proper SQLSTATE
            RAISE EXCEPTION '[%] Execution failed: % (SQLSTATE: %)', 
                  c_procedure_name, v_error_message, v_error_state
                  USING ERRCODE = 'P0001',
                        HINT = 'Check procedure logs and input parameters',
                        DETAIL = v_error_detail;
    END;
    
    -- Note: Temp tables with ON COMMIT DROP are automatically cleaned here
    
END;
$BODY$;

-- ============================================================================
-- PERFORMANCE INDEXES - SUGGESTIONS
-- ============================================================================
-- Create indexes to optimize queries used in the procedure
-- Use CONCURRENTLY to avoid blocking production tables

-- Index for main query filter (Step 1)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_source_table_status_created
ON source_table (status, created_at, id)
WHERE status = 'PENDING';

-- Composite index for join performance (Step 2)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_target_table_lookup
ON target_table (source_id, status)
WHERE status = 'ACTIVE';

-- Index for existence check (Step 3)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_final_table_composite
ON final_table (source_id, target_id);

-- Partial index for common filter
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_source_table_unprocessed
ON source_table (id, created_at)
WHERE status = 'PENDING';

-- Analyze tables after creating indexes
ANALYZE source_table;
ANALYZE target_table;
ANALYZE final_table;

-- ============================================================================
-- GRANTS & PERMISSIONS
-- ============================================================================
-- Grant execute permission to appropriate roles
-- GRANT EXECUTE ON PROCEDURE schema_name.procedure_name TO app_role;
-- GRANT EXECUTE ON PROCEDURE schema_name.procedure_name TO monitoring_role;

-- ============================================================================
-- USAGE EXAMPLES
-- ============================================================================
/*
-- Basic execution
CALL schema_name.procedure_name('PARAM_VALUE', 100, TRUE);

-- Check execution in logs
SELECT * FROM pg_stat_activity 
WHERE query LIKE '%procedure_name%';

-- Monitor performance
SELECT 
    calls,
    total_time,
    mean_time,
    max_time
FROM pg_stat_user_functions
WHERE funcname = 'procedure_name';
*/

-- ============================================================================
-- TESTING CHECKLIST
-- ============================================================================
/*
Pre-deployment validation:

□ Syntax check passes (psql -f procedure.sql --dry-run)
□ Input validation works (null, empty, invalid values)
□ Transaction rollback works on error
□ Temp tables cleanup correctly (check pg_tables after error)
□ Performance is acceptable (<2x SQL Server baseline)
□ Indexes are used (check EXPLAIN ANALYZE)
□ Logging provides useful information
□ Error messages are clear and actionable
□ No LOWER() on indexed columns (unless necessary)
□ No "hadouken" nested code (max 2-3 levels)

Post-deployment monitoring:

□ Execution time within SLA
□ No memory leaks (temp tables)
□ No lock contention
□ Error rate < 1%
□ Audit logs capture all executions
*/

-- ============================================================================
-- MAINTENANCE NOTES
-- ============================================================================
/*
Common issues and fixes:

1. "Temp table already exists" error
   → Add defensive DROP TABLE IF EXISTS before CREATE

2. Slow performance on large datasets
   → Add indexes on WHERE/JOIN columns
   → Use partial indexes for common filters
   → Consider batching with LIMIT

3. Transaction timeout
   → Break into smaller batches
   → Use COMMIT/ROLLBACK strategically
   → Monitor long-running queries

4. LOWER() causing sequential scans
   → Remove if data is normalized
   → Create functional index: CREATE INDEX ON table (LOWER(column))

5. Complex nested logic ("hadouken")
   → Extract to separate functions
   → Use CTEs for readability
   → Flatten conditions with early returns
*/

-- ============================================================================
-- END OF TEMPLATE
-- ============================================================================
