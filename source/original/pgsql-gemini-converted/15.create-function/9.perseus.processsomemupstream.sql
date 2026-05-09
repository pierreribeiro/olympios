CREATE FUNCTION perseus.processsomemupstream(par_dirty_in perseus.goolist[], par_clean_in perseus.goolist[]) RETURNS TABLE(uid character varying)
    LANGUAGE plpgsql
    AS $$
DECLARE
    -- Procedure identification
    c_procedure_name CONSTANT VARCHAR(50) := 'processsomemupstream';

    -- Counters
    v_dirty_count INTEGER := 0;
    v_add_rows INTEGER := 0;
    v_rem_rows INTEGER := 0;

    -- Error handling
    v_error_state TEXT;
    v_error_message TEXT;
    v_error_detail TEXT;

    -- Performance tracking
    v_start_time TIMESTAMP;
    v_execution_time INTERVAL;
BEGIN
    -- Performance tracking
    v_start_time := clock_timestamp();

    RAISE NOTICE '[%] ============================================================', c_procedure_name;
    RAISE NOTICE '[%] Starting execution at %', c_procedure_name, v_start_time;
    RAISE NOTICE '[%] Parameters: dirty_in=% materials, clean_in=% materials',
                 c_procedure_name,
                 COALESCE(array_length(par_dirty_in, 1), 0),
                 COALESCE(array_length(par_clean_in, 1), 0);

    -- ========================================================================
    -- STEP 1: Defensive cleanup of any leftover temp tables
    -- ========================================================================
    RAISE NOTICE '[%] Step 1: Defensive cleanup...', c_procedure_name;

    DROP TABLE IF EXISTS temp_var_dirty;
    DROP TABLE IF EXISTS temp_par_dirty_in;
    DROP TABLE IF EXISTS temp_par_clean_in;
    DROP TABLE IF EXISTS old_upstream;
    DROP TABLE IF EXISTS new_upstream;
    DROP TABLE IF EXISTS add_upstream;
    DROP TABLE IF EXISTS rem_upstream;

    -- ========================================================================
    -- STEP 2: Create temporary tables with ON COMMIT DROP
    -- ========================================================================
    RAISE NOTICE '[%] Step 2: Creating temp tables...', c_procedure_name;

    -- Temp table for input parameter expansion (dirty)
    CREATE TEMPORARY TABLE temp_par_dirty_in (
        uid VARCHAR(255) NOT NULL
    ) ON COMMIT DROP;

    -- Temp table for input parameter expansion (clean)
    CREATE TEMPORARY TABLE temp_par_clean_in (
        uid VARCHAR(255) NOT NULL
    ) ON COMMIT DROP;

    -- Temp table for filtered dirty materials (dirty minus clean)
    CREATE TEMPORARY TABLE temp_var_dirty (
        uid VARCHAR(255) NOT NULL,
        PRIMARY KEY (uid)
    ) ON COMMIT DROP;

    -- Temp table for old upstream relationships
    CREATE TEMPORARY TABLE old_upstream (
        start_point VARCHAR(50) NOT NULL,
        end_point VARCHAR(50) NOT NULL,
        path VARCHAR(500) NOT NULL,
        level INTEGER NOT NULL,
        PRIMARY KEY (start_point, end_point, path)
    ) ON COMMIT DROP;

    -- Temp table for new upstream relationships
    CREATE TEMPORARY TABLE new_upstream (
        start_point VARCHAR(50) NOT NULL,
        end_point VARCHAR(50) NOT NULL,
        path VARCHAR(500) NOT NULL,
        level INTEGER NOT NULL,
        PRIMARY KEY (start_point, end_point, path)
    ) ON COMMIT DROP;

    -- Temp table for relationships to add
    CREATE TEMPORARY TABLE add_upstream (
        start_point VARCHAR(50) NOT NULL,
        end_point VARCHAR(50) NOT NULL,
        path VARCHAR(500) NOT NULL,
        level INTEGER NOT NULL,
        PRIMARY KEY (start_point, end_point, path)
    ) ON COMMIT DROP;

    -- Temp table for relationships to remove
    CREATE TEMPORARY TABLE rem_upstream (
        start_point VARCHAR(50) NOT NULL,
        end_point VARCHAR(50) NOT NULL,
        path VARCHAR(500) NOT NULL,
        level INTEGER NOT NULL,
        PRIMARY KEY (start_point, end_point, path)
    ) ON COMMIT DROP;

    -- ========================================================================
    -- STEP 3: Expand input parameters into temp tables
    -- ========================================================================
    RAISE NOTICE '[%] Step 3: Expanding input parameters...', c_procedure_name;

    -- Expand dirty_in array
    INSERT INTO temp_par_dirty_in (uid)
    SELECT UNNEST(par_dirty_in);

    -- Expand clean_in array
    INSERT INTO temp_par_clean_in (uid)
    SELECT UNNEST(par_clean_in);

    RAISE NOTICE '[%] Expanded: % dirty materials, % clean materials',
                 c_procedure_name,
                 (SELECT COUNT(*) FROM temp_par_dirty_in),
                 (SELECT COUNT(*) FROM temp_par_clean_in);

    -- ========================================================================
    -- STEP 4: Filter dirty materials (dirty_in minus clean_in)
    -- ========================================================================
    RAISE NOTICE '[%] Step 4: Filtering dirty materials (excluding clean)...', c_procedure_name;

    -- The input materials, minus any that may have already been cleaned
    -- in a previous round
    INSERT INTO temp_var_dirty (uid)
    SELECT DISTINCT d.uid
    FROM temp_par_dirty_in d
    WHERE NOT EXISTS (
        SELECT 1
        FROM temp_par_clean_in c
        WHERE c.uid = d.uid  -- Direct comparison (no LOWER())
    );

    SELECT COUNT(*) INTO v_dirty_count FROM temp_var_dirty;

    RAISE NOTICE '[%] Filtered result: % materials to process (% excluded by clean list)',
                 c_procedure_name,
                 v_dirty_count,
                 (SELECT COUNT(*) FROM temp_par_dirty_in) - v_dirty_count;

    -- ========================================================================
    -- STEP 5: Early exit if no materials to process
    -- ========================================================================
    IF v_dirty_count = 0 THEN
        RAISE NOTICE '[%] Early exit: No materials to process', c_procedure_name;
        RAISE NOTICE '[%] Execution completed in %',
                     c_procedure_name,
                     (clock_timestamp() - v_start_time);
        RAISE NOTICE '[%] ============================================================', c_procedure_name;
        RETURN;  -- Return empty result set
    END IF;

    -- ========================================================================
    -- TRANSACTION BEGIN: Atomic delta calculation and application
    -- ========================================================================
    BEGIN
        -- ====================================================================
        -- STEP 6: Load old upstream relationships for dirty materials
        -- ====================================================================
        RAISE NOTICE '[%] Step 6: Loading old upstream relationships...', c_procedure_name;

        INSERT INTO old_upstream (start_point, end_point, path, level)
        SELECT
            m.start_point,
            m.end_point,
            m.path,
            m.level
        FROM perseus.m_upstream m
        JOIN temp_var_dirty d ON d.uid = m.start_point;  -- Direct join (no LOWER())

        RAISE NOTICE '[%] Loaded % old upstream relationships',
                     c_procedure_name,
                     (SELECT COUNT(*) FROM old_upstream);

        -- ====================================================================
        -- STEP 7: Calculate new upstream relationships
        -- ====================================================================
        RAISE NOTICE '[%] Step 7: Calculating new upstream relationships...', c_procedure_name;

        INSERT INTO new_upstream (start_point, end_point, path, level)
        SELECT
            start_point,
            end_point,
            path,
            level
        FROM perseus.mcgetupstreambylist(ARRAY(SELECT ROW(g.uid)::perseus.goolist FROM temp_var_dirty g));

        RAISE NOTICE '[%] Calculated % new upstream relationships',
                     c_procedure_name,
                     (SELECT COUNT(*) FROM new_upstream);

        -- ====================================================================
        -- STEP 8: Calculate delta - relationships to ADD
        -- ====================================================================
        RAISE NOTICE '[%] Step 8: Calculating delta (ADD operations)...', c_procedure_name;

        -- Determine what, if any, inserts are needed
        INSERT INTO add_upstream (start_point, end_point, path, level)
        SELECT
            n.start_point,
            n.end_point,
            n.path,
            n.level
        FROM new_upstream n
        WHERE NOT EXISTS (
            SELECT 1
            FROM old_upstream o
            WHERE o.start_point = n.start_point    -- Direct comparison (no LOWER())
              AND o.end_point = n.end_point        -- Direct comparison (no LOWER())
              AND o.path = n.path                  -- Direct comparison (no LOWER())
        );

        SELECT COUNT(*) INTO v_add_rows FROM add_upstream;
        RAISE NOTICE '[%] Delta ADD: % relationships to insert', c_procedure_name, v_add_rows;

        -- ====================================================================
        -- STEP 9: Calculate delta - relationships to REMOVE
        -- ====================================================================
        RAISE NOTICE '[%] Step 9: Calculating delta (REMOVE operations)...', c_procedure_name;

        -- Delete obsolete rows. This (hopefully) serves to check
        -- for deletes before unnecessarily locking the table.
        INSERT INTO rem_upstream (start_point, end_point, path, level)
        SELECT
            o.start_point,
            o.end_point,
            o.path,
            o.level
        FROM old_upstream o
        WHERE NOT EXISTS (
            SELECT 1
            FROM new_upstream n
            WHERE n.start_point = o.start_point    -- Direct comparison (no LOWER())
              AND n.end_point = o.end_point        -- Direct comparison (no LOWER())
              AND n.path = o.path                  -- Direct comparison (no LOWER())
        );

        SELECT COUNT(*) INTO v_rem_rows FROM rem_upstream;
        RAISE NOTICE '[%] Delta REMOVE: % relationships to delete', c_procedure_name, v_rem_rows;

        -- ====================================================================
        -- STEP 10: Apply delta - INSERT new relationships
        -- ====================================================================
        IF v_add_rows > 0 THEN
            RAISE NOTICE '[%] Step 10: Applying delta (INSERT % relationships)...',
                         c_procedure_name, v_add_rows;

            INSERT INTO perseus.m_upstream (start_point, end_point, path, level)
            SELECT
                start_point,
                end_point,
                path,
                level
            FROM add_upstream;

            RAISE NOTICE '[%] INSERT complete: % relationships added',
                         c_procedure_name, v_add_rows;
        ELSE
            RAISE NOTICE '[%] Step 10: Skipped (no relationships to add)', c_procedure_name;
        END IF;

        -- ====================================================================
        -- STEP 11: Apply delta - DELETE obsolete relationships
        -- ====================================================================
        IF v_rem_rows > 0 THEN
            RAISE NOTICE '[%] Step 11: Applying delta (DELETE % relationships)...',
                         c_procedure_name, v_rem_rows;

            DELETE FROM perseus.m_upstream m
            WHERE m.start_point IN (SELECT uid FROM temp_var_dirty)
              AND NOT EXISTS (
                  SELECT 1
                  FROM new_upstream n
                  WHERE n.start_point = m.start_point    -- Direct comparison (no LOWER())
                    AND n.end_point = m.end_point        -- Direct comparison (no LOWER())
                    AND n.path = m.path                  -- Direct comparison (no LOWER())
              );

            RAISE NOTICE '[%] DELETE complete: % relationships removed',
                         c_procedure_name, v_rem_rows;
        ELSE
            RAISE NOTICE '[%] Step 11: Skipped (no relationships to remove)', c_procedure_name;
        END IF;

        -- ====================================================================
        -- SUCCESS: Transaction committed
        -- ====================================================================
        v_execution_time := clock_timestamp() - v_start_time;

        RAISE NOTICE '[%] ============================================================', c_procedure_name;
        RAISE NOTICE '[%] SUCCESS: Processed % materials in %',
                     c_procedure_name, v_dirty_count, v_execution_time;
        RAISE NOTICE '[%] Delta summary: +% inserts, -% deletes',
                     c_procedure_name, v_add_rows, v_rem_rows;
        RAISE NOTICE '[%] ============================================================', c_procedure_name;

    EXCEPTION
        WHEN OTHERS THEN
            -- Rollback transaction on any error
            ROLLBACK;

            -- Capture detailed error information
            GET STACKED DIAGNOSTICS
                v_error_state = RETURNED_SQLSTATE,
                v_error_message = MESSAGE_TEXT,
                v_error_detail = PG_EXCEPTION_DETAIL;

            -- Log error with full context
            RAISE EXCEPTION '[%] Execution failed: % (SQLSTATE: %, Detail: %)',
                  c_procedure_name,
                  v_error_message,
                  v_error_state,
                  COALESCE(v_error_detail, 'N/A')
                  USING ERRCODE = 'P0001';
    END;
    -- TRANSACTION END

    -- ========================================================================
    -- STEP 12: Return list of processed materials
    -- ========================================================================
    RETURN QUERY
    SELECT t.uid
    FROM temp_var_dirty t
    ORDER BY t.uid;
    /*
    OPEN result_set_refcursor FOR SELECT
        t.uid
      FROM temp_var_dirty t
      ORDER BY t.uid;
    */
    -- Temp tables automatically cleaned up via ON COMMIT DROP

END;
$$;


ALTER FUNCTION perseus.processsomemupstream(par_dirty_in perseus.goolist[], par_clean_in perseus.goolist[]) OWNER TO perseus_owner;

