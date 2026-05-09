CREATE PROCEDURE perseus.processdirtytrees(IN par_dirty_in perseus.goolist[], IN par_clean_in perseus.goolist[])
    LANGUAGE plpgsql
    AS $$

-- ============================================================================
-- VARIABLE DECLARATIONS
-- ============================================================================
DECLARE
    -- Performance tracking
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
    v_execution_time_ms INTEGER;
    v_loop_start_time TIMESTAMP;
    v_duration_ms INTEGER := 0;

    -- Business logic variables
    v_dirty_count INTEGER := 0;
    v_clean_count INTEGER := 0;
    v_iterations INTEGER := 0;
    v_current_uid VARCHAR(50);

    -- Refcursor for ProcessSomeMUpstream results
    v_result_cursor refcursor;
    v_processed_uid VARCHAR(50);

    -- Error handling
    v_error_message TEXT;
    v_error_state TEXT;
    v_error_detail TEXT;

    -- Constants
    c_procedure_name CONSTANT VARCHAR(100) := 'ProcessDirtyTrees';
    c_timeout_ms CONSTANT INTEGER := 4000; -- 4-second timeout
    c_max_iterations CONSTANT INTEGER := 10000; -- Safety limit

BEGIN
    -- ========================================================================
    -- INITIALIZATION & LOGGING
    -- ========================================================================
    v_start_time := clock_timestamp();

    RAISE NOTICE '[%] Starting: Dirty count=%, Clean count=%, Timeout=%ms',
                 c_procedure_name,
                 COALESCE(array_length(par_dirty_in, 1), 0),
                 COALESCE(array_length(par_clean_in, 1), 0),
                 c_timeout_ms;

    -- ========================================================================
    -- INPUT VALIDATION (P1)
    -- ========================================================================
    IF par_dirty_in IS NULL THEN
        RAISE EXCEPTION '[%] Required parameter dirty_in is null',
                        c_procedure_name
              USING ERRCODE = 'P0001',
                    HINT = 'Provide a valid goolist array (can be empty but not null)';
    END IF;

    IF par_clean_in IS NULL THEN
        RAISE EXCEPTION '[%] Required parameter clean_in is null',
                        c_procedure_name
              USING ERRCODE = 'P0001',
                    HINT = 'Provide a valid goolist array (can be empty but not null)';
    END IF;

    -- ========================================================================
    -- MAIN TRANSACTION BLOCK (P0)
    -- ========================================================================
    BEGIN

        -- ====================================================================
        -- CREATE TEMP TABLES FOR PROCESSING (P0/P1)
        -- ====================================================================
        -- Fixed P0.3: Unsafe table creation
        -- Fixed P1: Added ON COMMIT DROP for automatic cleanup
        -- Fixed P1: Clean nomenclature (temp_dirty, temp_clean, temp_to_process)

        DROP TABLE IF EXISTS temp_dirty;
        CREATE TEMPORARY TABLE temp_dirty (
            uid VARCHAR(50) PRIMARY KEY
        ) ON COMMIT DROP;

        DROP TABLE IF EXISTS temp_clean;
        CREATE TEMPORARY TABLE temp_clean (
            uid VARCHAR(50) PRIMARY KEY
        ) ON COMMIT DROP;

        DROP TABLE IF EXISTS temp_to_process;
        CREATE TEMPORARY TABLE temp_to_process (
            uid VARCHAR(50) PRIMARY KEY
        ) ON COMMIT DROP;

        RAISE NOTICE '[%] Created 3 temp tables: temp_dirty, temp_clean, temp_to_process',
                     c_procedure_name;

        -- ====================================================================
        -- POPULATE TEMP TABLES FROM INPUT ARRAYS
        -- ====================================================================
        -- P0.1: Fixed broken PERFORM pattern with proper UNNEST

        INSERT INTO temp_dirty (uid)
        SELECT DISTINCT UNNEST(par_dirty_in);

        INSERT INTO temp_clean (uid)
        SELECT DISTINCT UNNEST(par_clean_in);

        GET DIAGNOSTICS v_dirty_count = ROW_COUNT;

        RAISE NOTICE '[%] Populated temp_dirty: % rows, temp_clean: % rows',
                     c_procedure_name,
                     (SELECT COUNT(*) FROM temp_dirty),
                     (SELECT COUNT(*) FROM temp_clean);

        -- ====================================================================
        -- WHILE LOOP: PROCESS DIRTY MATERIALS UNTIL TIMEOUT OR EXHAUSTED
        -- ====================================================================
        -- P0.4: Restored core business logic (was commented out in AWS SCT)
        -- P1: Added iteration counter and comprehensive logging
        -- P1: Removed 6× LOWER() calls for performance

        v_loop_start_time := clock_timestamp();

        SELECT COUNT(*) INTO v_dirty_count FROM temp_dirty;

        RAISE NOTICE '[%] Starting WHILE loop: dirty_count=%, timeout=%ms',
                     c_procedure_name, v_dirty_count, c_timeout_ms;

        WHILE v_dirty_count > 0
          AND v_duration_ms < c_timeout_ms
          AND v_iterations < c_max_iterations
        LOOP
            v_iterations := v_iterations + 1;

            -- ================================================================
            -- STEP 1: SELECT TOP 1 DIRTY UID FOR PROCESSING
            -- ================================================================
            DELETE FROM temp_to_process;

            SELECT uid INTO v_current_uid
            FROM temp_dirty
            LIMIT 1;

            IF v_current_uid IS NULL THEN
                RAISE NOTICE '[%] No more dirty materials (iteration %)',
                             c_procedure_name, v_iterations;
                EXIT;
            END IF;

            INSERT INTO temp_to_process (uid) VALUES (v_current_uid);

            RAISE NOTICE '[%] Iteration %: Processing UID=%, Duration=%ms',
                         c_procedure_name, v_iterations, v_current_uid, v_duration_ms;

            -- ================================================================
            -- STEP 2: CALL ProcessSomeMUpstream VIA REFCURSOR PATTERN
            -- ================================================================
            -- P0.2: CRITICAL FIX - Restored commented business logic
            -- Original T-SQL: INSERT @clean EXEC ProcessSomeMUpstream @to_process, @clean
            -- PostgreSQL: Use refcursor pattern since EXEC INSERT not supported

            BEGIN
                -- Call ProcessSomeMUpstream with refcursor
                /*
                CALL perseus.processsomemupstream(
                    (SELECT array_agg(uid) FROM temp_to_process),
                    (SELECT array_agg(uid) FROM temp_clean),
                    v_result_cursor
                );

                -- Fetch results from refcursor into temp_clean
                LOOP
                    FETCH v_result_cursor INTO v_processed_uid;
                    EXIT WHEN NOT FOUND;

                    -- Add processed UID to clean list (if not already present)
                    INSERT INTO temp_clean (uid)
                    VALUES (v_processed_uid)
                    ON CONFLICT (uid) DO NOTHING;
                END LOOP;

                CLOSE v_result_cursor;
                */

                INSERT INTO temp_clean
                SELECT uid FROM perseus.processsomemupstream(
                    (SELECT array_agg(ROW(uid)::perseus.goolist) FROM temp_to_process),
                    (SELECT array_agg(ROW(uid)::perseus.goolist) FROM temp_clean)
                );

                RAISE NOTICE '[%] ProcessSomeMUpstream completed for UID=%',
                             c_procedure_name, v_current_uid;

            EXCEPTION
                WHEN OTHERS THEN
                    GET STACKED DIAGNOSTICS
                        v_error_state = RETURNED_SQLSTATE,
                        v_error_message = MESSAGE_TEXT;

                    RAISE WARNING '[%] ProcessSomeMUpstream failed for UID=% - SQLSTATE: %, Message: %',
                                  c_procedure_name, v_current_uid, v_error_state, v_error_message;

                    -- Continue processing other materials even if one fails
                    -- This matches original T-SQL behavior
            END;

            -- ================================================================
            -- STEP 3: REMOVE PROCESSED MATERIALS FROM DIRTY LIST
            -- ================================================================
            -- P0.3: Fixed DELETE statement (removed duplicate alias 'd')
            -- P1: Removed 2× LOWER() calls

            DELETE FROM temp_dirty
            WHERE EXISTS (
                SELECT 1
                FROM temp_clean c
                WHERE c.uid = temp_dirty.uid
            );

            RAISE NOTICE '[%] Removed processed UIDs from dirty list',
                         c_procedure_name;

            -- ================================================================
            -- STEP 4: UPDATE LOOP COUNTERS
            -- ================================================================
            SELECT COUNT(*) INTO v_dirty_count FROM temp_dirty;

            v_duration_ms := EXTRACT(MILLISECONDS FROM (clock_timestamp() - v_loop_start_time))::INTEGER;

        END LOOP;

        -- ====================================================================
        -- LOOP COMPLETION SUMMARY
        -- ====================================================================
        SELECT COUNT(*) INTO v_clean_count FROM temp_clean;

        RAISE NOTICE '[%] WHILE loop completed: iterations=%, dirty_remaining=%, clean_total=%, duration=%ms',
                     c_procedure_name, v_iterations, v_dirty_count, v_clean_count, v_duration_ms;

        -- ====================================================================
        -- TIMEOUT WARNING
        -- ====================================================================
        IF v_duration_ms >= c_timeout_ms THEN
            RAISE WARNING '[%] Processing stopped due to timeout: %ms >= %ms (dirty_remaining=%)',
                          c_procedure_name, v_duration_ms, c_timeout_ms, v_dirty_count;
        END IF;

        -- ====================================================================
        -- MAX ITERATIONS WARNING (SAFETY LIMIT)
        -- ====================================================================
        IF v_iterations >= c_max_iterations THEN
            RAISE WARNING '[%] Processing stopped due to safety limit: iterations=% >= max=%',
                          c_procedure_name, v_iterations, c_max_iterations;
        END IF;

        -- ====================================================================
        -- SUCCESS METRICS
        -- ====================================================================
        v_end_time := clock_timestamp();
        v_execution_time_ms := EXTRACT(MILLISECONDS FROM (v_end_time - v_start_time))::INTEGER;

        RAISE NOTICE '[%] Execution completed successfully in % ms (iterations: %, processed: %, remaining: %)',
                     c_procedure_name,
                     v_execution_time_ms,
                     v_iterations,
                     v_clean_count - COALESCE(array_length(par_clean_in, 1), 0),
                     v_dirty_count;

    EXCEPTION
        WHEN OTHERS THEN
            -- ================================================================
            -- ERROR HANDLING (P0/P1)
            -- ================================================================
            ROLLBACK;

            GET STACKED DIAGNOSTICS
                v_error_state = RETURNED_SQLSTATE,
                v_error_message = MESSAGE_TEXT,
                v_error_detail = PG_EXCEPTION_DETAIL;

            RAISE WARNING '[%] Execution failed - SQLSTATE: %, Message: %',
                          c_procedure_name, v_error_state, v_error_message;

            RAISE EXCEPTION '[%] Failed to process dirty trees: % (SQLSTATE: %)',
                  c_procedure_name, v_error_message, v_error_state
                  USING ERRCODE = 'P0001',
                        HINT = 'Check logs for iteration details and ProcessSomeMUpstream errors',
                        DETAIL = v_error_detail;
    END;

END;
$$;


ALTER PROCEDURE perseus.processdirtytrees(IN par_dirty_in perseus.goolist[], IN par_clean_in perseus.goolist[]) OWNER TO perseus_owner;

