--
-- PostgreSQL database dump
--

\restrict vCks0JuvW2V6DyjHMzfPTQWMiClchfW4Pdog8ZKJdN6udnOqfabakK1rCoIHOFR

-- Dumped from database version 17.7
-- Dumped by pg_dump version 18.2

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: perseus; Type: SCHEMA; Schema: -; Owner: perseus_owner
--

CREATE SCHEMA perseus;


ALTER SCHEMA perseus OWNER TO perseus_owner;

--
-- Name: goolist; Type: TYPE; Schema: perseus; Owner: perseus_owner
--

CREATE TYPE perseus.goolist AS (
	uid character varying(50)
);


ALTER TYPE perseus.goolist OWNER TO perseus_owner;

--
-- Name: addarc(character varying, character varying, character varying); Type: PROCEDURE; Schema: perseus; Owner: perseus_owner
--

CREATE PROCEDURE perseus.addarc(IN _materialuid character varying, IN _transitionuid character varying, IN _direction character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    CREATE TEMP TABLE formerdownstream (
      start_point VARCHAR(50),
      end_point VARCHAR(50),
      path VARCHAR(250),
      level INTEGER,
      PRIMARY KEY (start_point, end_point, path)
    ) ON COMMIT DROP;

    CREATE TEMP TABLE formerupstream (
      start_point VARCHAR(50),
      end_point VARCHAR(50),
      path VARCHAR(250),
      level INTEGER,
      PRIMARY KEY (start_point, end_point, path)
    ) ON COMMIT DROP;

    CREATE TEMP TABLE deltadownstream (
      start_point VARCHAR(50),
      end_point VARCHAR(50),
      path VARCHAR(250),
      level INTEGER,
      PRIMARY KEY (start_point, end_point, path)
    ) ON COMMIT DROP;

    CREATE TEMP TABLE deltaupstream (
      start_point VARCHAR(50),
      end_point VARCHAR(50),
      path VARCHAR(250),
      level INTEGER,
      PRIMARY KEY (start_point, end_point, path)
    ) ON COMMIT DROP;

    CREATE TEMP TABLE newdownstream (
      start_point VARCHAR(50),
      end_point VARCHAR(50),
      path VARCHAR(250),
      level INTEGER,
      PRIMARY KEY (start_point, end_point, path)
    ) ON COMMIT DROP;

    CREATE TEMP TABLE newupstream (
      start_point VARCHAR(50),
      end_point VARCHAR(50),
      path VARCHAR(250),
      level INTEGER,
      PRIMARY KEY (start_point, end_point, path)
    ) ON COMMIT DROP;

    INSERT INTO formerdownstream (start_point, end_point, path, level)
    SELECT start_point, end_point, path, level FROM perseus.mcgetdownstream(_materialuid);

    INSERT INTO formerupstream (start_point, end_point, path, level)
    SELECT start_point, end_point, path, level FROM perseus.mcgetupstream(_materialuid);

    IF _direction = 'PT' THEN
      INSERT INTO perseus.material_transition (material_id, transition_id) VALUES (_materialuid, _transitionuid);
    ELSE
      INSERT INTO perseus.transition_material (material_id, transition_id) VALUES (_materialuid, _transitionuid);
    END IF;

    INSERT INTO newdownstream (start_point, end_point, path, level)
    SELECT start_point, end_point, path, level FROM perseus.mcgetdownstream(_materialuid);

    INSERT INTO newupstream (start_point, end_point, path, level)
    SELECT start_point, end_point, path, level FROM perseus.mcgetupstream(_materialuid);

    INSERT INTO deltaupstream (start_point, end_point, path, level)
    SELECT n.start_point, n.end_point, n.path, n.level
    FROM newupstream AS n
    WHERE NOT EXISTS (
        SELECT 1 FROM formerupstream AS f
        WHERE f.start_point = n.start_point AND f.end_point = n.end_point AND f.path = n.path
    );

    INSERT INTO deltadownstream (start_point, end_point, path, level)
    SELECT n.start_point, n.end_point, n.path, n.level
    FROM newdownstream AS n
    WHERE NOT EXISTS (
        SELECT 1 FROM formerdownstream AS f
        WHERE f.start_point = n.start_point AND f.end_point = n.end_point AND f.path = n.path
    );

    IF NOT EXISTS (SELECT 1 FROM perseus.m_downstream WHERE start_point = _materialuid) THEN
        INSERT INTO perseus.m_downstream (start_point, end_point, path, level) VALUES (_materialuid, _materialuid, '', 0);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM perseus.m_upstream WHERE start_point = _materialuid) THEN
        INSERT INTO perseus.m_upstream (start_point, end_point, path, level) VALUES (_materialuid, _materialuid, '', 0);
    END IF;

    -- Add secondary downstream connections
    INSERT INTO perseus.m_downstream (start_point, end_point, path, level)
    SELECT
        r.end_point,
        n.end_point,
        CASE WHEN r.path LIKE '%/' AND n.path LIKE '/%' THEN r.path || r.start_point || n.path ELSE r.path || n.path END,
        r.level + n.level
    FROM deltaupstream AS r
    JOIN newdownstream AS n ON r.start_point = n.start_point
    UNION
    SELECT
        nu.end_point,
        dd.end_point,
        nu.path || dd.path,
        nu.level + dd.level
    FROM deltadownstream AS dd
    JOIN newupstream AS nu ON nu.start_point = dd.start_point;

    -- Add secondary upstream connections
    INSERT INTO perseus.m_upstream (start_point, end_point, path, level)
    SELECT
        r.end_point,
        n.end_point,
        CASE WHEN r.path LIKE '%/' AND n.path LIKE '/%' THEN r.path || r.start_point || n.path ELSE r.path || n.path END,
        r.level + n.level
    FROM deltadownstream AS r
    JOIN newupstream AS n ON r.start_point = n.start_point
    UNION
    SELECT
        nd.end_point,
        du.end_point,
        CASE WHEN nd.path LIKE '%/' AND du.path LIKE '/%' THEN nd.path || nd.start_point || du.path ELSE nd.path || du.path END,
        nd.level + du.level
    FROM deltaupstream AS du
    JOIN newdownstream AS nd ON nd.start_point = du.start_point;
  END;
$$;


ALTER PROCEDURE perseus.addarc(IN _materialuid character varying, IN _transitionuid character varying, IN _direction character varying) OWNER TO perseus_owner;

--
-- Name: fn_diagramobjects(); Type: FUNCTION; Schema: perseus; Owner: perseus_owner
--

CREATE FUNCTION perseus.fn_diagramobjects() RETURNS integer
    LANGUAGE plpgsql
    AS $$
    DECLARE
      _id_upgraddiagrams INTEGER;
      _id_sysdiagrams INTEGER;
      _id_helpdiagrams INTEGER;
      _id_helpdiagramdefinition INTEGER;
      _id_creatediagram INTEGER;
      _id_renamediagram INTEGER;
      _id_alterdiagram INTEGER;
      _id_dropdiagram INTEGER;
      _installedobjects INTEGER;
    BEGIN
      SELECT
          coalesce(0, _installedobjects)
        INTO
          _installedobjects
        LIMIT 1
      ;
      SELECT
          coalesce(to_regclass('dbo.sp_upgraddiagrams')::oid, _id_upgraddiagrams),
          coalesce(to_regclass('dbo.sysdiagrams')::oid, _id_sysdiagrams),
          coalesce(to_regclass('dbo.sp_helpdiagrams')::oid, _id_helpdiagrams),
          coalesce(to_regclass('dbo.sp_helpdiagramdefinition')::oid, _id_helpdiagramdefinition),
          coalesce(to_regclass('dbo.sp_creatediagram')::oid, _id_creatediagram),
          coalesce(to_regclass('dbo.sp_renamediagram')::oid, _id_renamediagram),
          coalesce(to_regclass('dbo.sp_alterdiagram')::oid, _id_alterdiagram),
          coalesce(to_regclass('dbo.sp_dropdiagram')::oid, _id_dropdiagram)
        INTO
          _id_upgraddiagrams, _id_sysdiagrams, _id_helpdiagrams, _id_helpdiagramdefinition, _id_creatediagram, _id_renamediagram, _id_alterdiagram, _id_dropdiagram
        LIMIT 1
      ;
      IF _id_upgraddiagrams IS NOT NULL THEN
        SELECT
            coalesce(_installedobjects + 1, _installedobjects)
          INTO
            _installedobjects
          LIMIT 1
        ;
      END IF;
      IF _id_sysdiagrams IS NOT NULL THEN
        SELECT
            coalesce(_installedobjects + 2, _installedobjects)
          INTO
            _installedobjects
          LIMIT 1
        ;
      END IF;
      IF _id_helpdiagrams IS NOT NULL THEN
        SELECT
            coalesce(_installedobjects + 4, _installedobjects)
          INTO
            _installedobjects
          LIMIT 1
        ;
      END IF;
      IF _id_helpdiagramdefinition IS NOT NULL THEN
        SELECT
            coalesce(_installedobjects + 8, _installedobjects)
          INTO
            _installedobjects
          LIMIT 1
        ;
      END IF;
      IF _id_creatediagram IS NOT NULL THEN
        SELECT
            coalesce(_installedobjects + 16, _installedobjects)
          INTO
            _installedobjects
          LIMIT 1
        ;
      END IF;
      IF _id_renamediagram IS NOT NULL THEN
        SELECT
            coalesce(_installedobjects + 32, _installedobjects)
          INTO
            _installedobjects
          LIMIT 1
        ;
      END IF;
      IF _id_alterdiagram IS NOT NULL THEN
        SELECT
            coalesce(_installedobjects + 64, _installedobjects)
          INTO
            _installedobjects
          LIMIT 1
        ;
      END IF;
      IF _id_dropdiagram IS NOT NULL THEN
        SELECT
            coalesce(_installedobjects + 128, _installedobjects)
          INTO
            _installedobjects
          LIMIT 1
        ;
      END IF;
      RETURN _installedobjects;
    END;
  $$;


ALTER FUNCTION perseus.fn_diagramobjects() OWNER TO perseus_owner;

--
-- Name: getexperiment(character varying); Type: FUNCTION; Schema: perseus; Owner: perseus_owner
--

CREATE FUNCTION perseus.getexperiment(_hermesuid character varying) RETURNS integer
    LANGUAGE plpgsql
    AS $$
    DECLARE
      _experiment INTEGER;
    BEGIN
      _experiment := CAST(CASE
        WHEN cardinality(string_to_array(replace(replace(getexperiment._hermesuid, 'H', ''), '-', '.'), '.')) - 2 + 1 >= 1 THEN nullif((string_to_array(replace(replace(getexperiment._hermesuid, 'H', ''), '-', '.'), '.'))[cardinality(string_to_array(replace(replace(getexperiment._hermesuid, 'H', ''), '-', '.'), '.')) - 2 + 1], '')
        ELSE NULL
      END as INTEGER);
      RETURN _experiment;
    END;
  $$;


ALTER FUNCTION perseus.getexperiment(_hermesuid character varying) OWNER TO perseus_owner;

--
-- Name: gethermesexperiment(character varying); Type: FUNCTION; Schema: perseus; Owner: perseus_owner
--

CREATE FUNCTION perseus.gethermesexperiment(_hermesuid character varying) RETURNS integer
    LANGUAGE plpgsql
    AS $$
    DECLARE
      _experiment INTEGER;
    BEGIN
      _experiment := CAST(CASE
        WHEN cardinality(string_to_array(replace(replace(gethermesexperiment._hermesuid, 'H', ''), '-', '.'), '.')) - 2 + 1 >= 1 THEN nullif((string_to_array(replace(replace(gethermesexperiment._hermesuid, 'H', ''), '-', '.'), '.'))[cardinality(string_to_array(replace(replace(gethermesexperiment._hermesuid, 'H', ''), '-', '.'), '.')) - 2 + 1], '')
        ELSE NULL
      END as INTEGER);
      RETURN _experiment;
    END;
  $$;


ALTER FUNCTION perseus.gethermesexperiment(_hermesuid character varying) OWNER TO perseus_owner;

--
-- Name: gethermesrun(character varying); Type: FUNCTION; Schema: perseus; Owner: perseus_owner
--

CREATE FUNCTION perseus.gethermesrun(_hermesuid character varying) RETURNS integer
    LANGUAGE plpgsql
    AS $$
    DECLARE
      _experiment INTEGER;
    BEGIN
      _experiment := CAST(CASE
        WHEN cardinality(string_to_array(replace(replace(gethermesrun._hermesuid, 'H', ''), '-', '.'), '.')) - 1 + 1 >= 1 THEN nullif((string_to_array(replace(replace(gethermesrun._hermesuid, 'H', ''), '-', '.'), '.'))[cardinality(string_to_array(replace(replace(gethermesrun._hermesuid, 'H', ''), '-', '.'), '.')) - 1 + 1], '')
        ELSE NULL
      END as INTEGER);
      RETURN _experiment;
    END;
  $$;


ALTER FUNCTION perseus.gethermesrun(_hermesuid character varying) OWNER TO perseus_owner;

--
-- Name: gethermesuid(integer, integer); Type: FUNCTION; Schema: perseus; Owner: perseus_owner
--

CREATE FUNCTION perseus.gethermesuid(_experimentid integer, _runid integer) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
    DECLARE
      _uid VARCHAR(50);
    BEGIN
      _uid := 'H' || gethermesuid._experimentid || '-' || gethermesuid._runid;
      RETURN _uid;
    END;
  $$;


ALTER FUNCTION perseus.gethermesuid(_experimentid integer, _runid integer) OWNER TO perseus_owner;

--
-- Name: getmaterialbyrunproperties(character varying, numeric, integer); Type: PROCEDURE; Schema: perseus; Owner: perseus_owner
--

CREATE PROCEDURE perseus.getmaterialbyrunproperties(IN _runid character varying, IN _hourtimepoint numeric, INOUT return_value integer)
    LANGUAGE plpgsql
    AS $$
  DECLARE
    _creatorid INTEGER;
    _secondtimepoint INTEGER;
    _originalgoo VARCHAR(50);
    _starttime TIMESTAMP;
    _timepointgoo VARCHAR(50);
    _maxgooidentifier INTEGER;
    _maxfsidentifier INTEGER;
    _split VARCHAR(50);
  BEGIN
    _secondtimepoint := _hourtimepoint * 60 * 60;

    SELECT
        g.added_by,
        g.uid,
        r.start_time
      INTO
        _creatorid, _originalgoo, _starttime
      FROM
        hermes.run AS r
        JOIN perseus.goo AS g ON g.uid = r.resultant_material
      WHERE r.experiment_id::TEXT || '-' || r.local_id::TEXT = _runid;

    IF _originalgoo IS NOT NULL THEN
      SELECT
          replace(g.uid, 'm', '')
        INTO
          _timepointgoo
        FROM
          perseus.mcgetdownstream(_originalgoo) AS d
          JOIN perseus.goo AS g ON d.end_point = g.uid
        WHERE g.added_on = _starttime + (_secondtimepoint * interval '1 second')
         AND g.goo_type_id = 9;

      IF _timepointgoo IS NULL THEN
        SELECT
            COALESCE(max(CAST(substr(uid, 2, 100) AS INTEGER)), 0) + 1
          INTO
            _maxgooidentifier
          FROM
            perseus.goo
          WHERE uid LIKE 'm%';

        SELECT
            COALESCE(max(CAST(substr(uid, 2, 100) AS INTEGER)), 0) + 1
          INTO
            _maxfsidentifier
          FROM
            perseus.fatsmurf
          WHERE uid LIKE 's%';

        _timepointgoo := 'm' || _maxgooidentifier;
        _split := 's' || _maxfsidentifier;

        INSERT INTO perseus.goo (uid, name, original_volume, added_on, added_by, goo_type_id)
          VALUES (_timepointgoo, 'Sample TP: ' || _hourtimepoint, 0.00001, _starttime + (_secondtimepoint * interval '1 second'), _creatorid, 9);

        INSERT INTO perseus.fatsmurf (uid, added_on, added_by, smurf_id, run_on)
          VALUES (_split, localtimestamp, _creatorid, 110, _starttime + (_secondtimepoint * interval '1 second'));

        CALL perseus.materialtotransition(_originalgoo, _split);
        CALL perseus.transitiontomaterial(_split, _timepointgoo);
      END IF;
    END IF;

    return_value := CAST(replace(_timepointgoo, 'm', '') AS INTEGER);
    RETURN;
  END;
  $$;


ALTER PROCEDURE perseus.getmaterialbyrunproperties(IN _runid character varying, IN _hourtimepoint numeric, INOUT return_value integer) OWNER TO perseus_owner;

--
-- Name: linkunlinkedmaterials(); Type: PROCEDURE; Schema: perseus; Owner: perseus_owner
--

CREATE PROCEDURE perseus.linkunlinkedmaterials()
    LANGUAGE plpgsql
    AS $$
DECLARE
  rec record;
BEGIN
  FOR rec IN
    SELECT
        g.uid
      FROM
        perseus.goo AS g
      WHERE
        NOT EXISTS (
          SELECT
              1
            FROM
              perseus.m_upstream AS mu
            WHERE
              g.uid = mu.start_point
        )
  LOOP
    BEGIN
      INSERT INTO perseus.m_upstream (start_point, end_point, level, path)
        SELECT
            f.start_point,
            f.end_point,
            f.level,
            f.path
          FROM
            perseus.mcgetupstream(rec.uid) AS f;
    EXCEPTION
      WHEN OTHERS THEN
        -- ignore errors and continue to the next material
    END;
  END LOOP;
END;
$$;


ALTER PROCEDURE perseus.linkunlinkedmaterials() OWNER TO perseus_owner;

--
-- Name: materialtotransition(character varying, character varying); Type: PROCEDURE; Schema: perseus; Owner: perseus_owner
--

CREATE PROCEDURE perseus.materialtotransition(IN _materialuid character varying, IN _transitionuid character varying)
    LANGUAGE plpgsql
    AS $$
  BEGIN
    INSERT INTO perseus.material_transition (material_id, transition_id)
      VALUES (materialtotransition._materialuid, materialtotransition._transitionuid)
    ;
  END;
  $$;


ALTER PROCEDURE perseus.materialtotransition(IN _materialuid character varying, IN _transitionuid character varying) OWNER TO perseus_owner;

--
-- Name: mcgetdownstream(perseus.goolist); Type: FUNCTION; Schema: perseus; Owner: perseus_owner
--

CREATE FUNCTION perseus.mcgetdownstream(p_starting_point perseus.goolist) RETURNS TABLE(start_point character varying, end_point character varying, neighbor character varying, path character varying, level integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
	WITH RECURSIVE downstream
	AS (
		SELECT 
            CAST(pt.source_material AS VARCHAR(50)) AS start_point, 
            CAST(pt.source_material AS VARCHAR(50)) AS parent, 
            CAST(pt.destination_material AS VARCHAR(50)) AS child, 
            CAST('/' AS VARCHAR(500)) AS path, 
            1 AS level
		FROM perseus.translated pt
		WHERE (pt.source_material = p_starting_point.uid::VARCHAR(50) 
            OR pt.transition_id = p_starting_point.uid::VARCHAR(50))

		UNION ALL
	   
		SELECT 
            r.start_point, 
            CAST(pt.source_material AS VARCHAR(50)) AS parent, 
            CAST(pt.destination_material AS VARCHAR(50)) AS child, 
            CAST(r.path || r.child || '/' AS VARCHAR(500)) AS path, 
            r.level + 1 AS level
		FROM perseus.translated pt
		    JOIN downstream r ON pt.source_material = r.child
		WHERE pt.source_material != pt.destination_material
	)
	SELECT d.start_point, d.child AS end_point, d.parent, d.path, d.level
    FROM downstream d
    UNION
	SELECT 
        p_starting_point.uid::VARCHAR(50) AS start_point, 
        p_starting_point.uid::VARCHAR(50) AS end_point, 
        NULL AS parent, '' AS path, 0 AS level; 

END

$$;


ALTER FUNCTION perseus.mcgetdownstream(p_starting_point perseus.goolist) OWNER TO perseus_owner;

--
-- Name: mcgetdownstreambylist(perseus.goolist[]); Type: FUNCTION; Schema: perseus; Owner: perseus_owner
--

CREATE FUNCTION perseus.mcgetdownstreambylist(p_starting_point perseus.goolist[]) RETURNS TABLE(start_point character varying, end_point character varying, neighbor character varying, path character varying, level integer)
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
	SELECT goo.uid
	FROM UNNEST(p_starting_point) AS goo;

    RETURN QUERY
	WITH RECURSIVE downstream
	AS (
		SELECT 
            CAST(pt.source_material AS VARCHAR(50)) AS start_point, 
            CAST(pt.source_material AS VARCHAR(50)) AS parent, 
            CAST(pt.destination_material AS VARCHAR(50)) AS child, 
            CAST('/' AS VARCHAR(500)) AS path, 
            1 AS level
		FROM perseus.translated pt
            JOIN v_starting_point sp ON pt.source_material = sp.uid

		UNION ALL
	   
		SELECT 
            r.start_point, 
            CAST(pt.source_material AS VARCHAR(50)) AS parent, 
            CAST(pt.destination_material AS VARCHAR(50)) AS child, 
            CAST(r.path || r.child || '/' AS VARCHAR(500)) AS path, 
            r.level + 1 AS level
		FROM perseus.translated pt
		    JOIN downstream r ON pt.source_material = r.child
		WHERE pt.source_material != pt.destination_material
	)
	SELECT d.start_point, d.child AS end_point, d.parent, d.path, d.level
    FROM downstream d
    UNION
	SELECT 
		CAST(sp.uid AS VARCHAR(50)) AS start_point, 
		CAST(sp.uid AS VARCHAR(50)) AS end_point, 
		CAST(NULL AS VARCHAR(50)) AS parent, 
		CAST('' AS VARCHAR(500)) AS path, 
		CAST(0 AS INT) AS level
    FROM v_starting_point sp
    WHERE EXISTS (SELECT 1 FROM perseus.goo WHERE sp.uid = goo.uid); 

END; 

$$;


ALTER FUNCTION perseus.mcgetdownstreambylist(p_starting_point perseus.goolist[]) OWNER TO perseus_owner;

--
-- Name: mcgetupstream(perseus.goolist); Type: FUNCTION; Schema: perseus; Owner: perseus_owner
--

CREATE FUNCTION perseus.mcgetupstream(p_starting_point perseus.goolist) RETURNS TABLE(start_point character varying, end_point character varying, neighbor character varying, path character varying, level integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
	RETURN QUERY
	WITH RECURSIVE upstream 
	AS ( 
		SELECT 
			CAST(pt.destination_material AS VARCHAR(50)) AS start_point,
			CAST(pt.destination_material AS VARCHAR(50)) AS parent,
			CAST(pt.source_material AS VARCHAR(50)) AS child,
			CAST('/' AS VARCHAR(500)) AS path,
			1 AS level
		FROM perseus.translated pt 
		WHERE (pt.destination_material = p_starting_point.uid::VARCHAR(50) 
			OR pt.transition_id = p_starting_point.uid::VARCHAR(50))

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
		p_starting_point.uid::VARCHAR(50) AS start_point, 
		p_starting_point.uid::VARCHAR(50) AS end_point, 
		NULL AS parent, '' AS path, 0 AS LEVEL;

END
$$;


ALTER FUNCTION perseus.mcgetupstream(p_starting_point perseus.goolist) OWNER TO perseus_owner;

--
-- Name: mcgetupstreambylist(perseus.goolist[]); Type: FUNCTION; Schema: perseus; Owner: perseus_owner
--

CREATE FUNCTION perseus.mcgetupstreambylist(p_starting_point perseus.goolist[]) RETURNS TABLE(start_point character varying, end_point character varying, neighbor character varying, path character varying, level integer)
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

END
$$;


ALTER FUNCTION perseus.mcgetupstreambylist(p_starting_point perseus.goolist[]) OWNER TO perseus_owner;

--
-- Name: processdirtytrees(perseus.goolist[], perseus.goolist[]); Type: PROCEDURE; Schema: perseus; Owner: perseus_owner
--

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

--
-- Name: processsomemupstream(perseus.goolist[], perseus.goolist[]); Type: FUNCTION; Schema: perseus; Owner: perseus_owner
--

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

--
-- Name: processsomemupstream_gemini(perseus.goolist, perseus.goolist, refcursor); Type: PROCEDURE; Schema: perseus; Owner: perseus_owner
--

CREATE PROCEDURE perseus.processsomemupstream_gemini(IN _dirty_in perseus.goolist, IN _clean_in perseus.goolist, INOUT result_set_refcursor refcursor)
    LANGUAGE plpgsql
    AS $$
  DECLARE
    _dirty perseus.goolist;
    _add_rows INTEGER;
    _rem_rows INTEGER;
    _dirty_count INTEGER;
  BEGIN
    CREATE TEMP TABLE IF NOT EXISTS "@oldupstream" (
      start_point VARCHAR(50),
      end_point VARCHAR(50),
      path VARCHAR(500),
      level INTEGER,
      PRIMARY KEY (start_point, end_point, path)
    );
    CREATE TEMP TABLE IF NOT EXISTS "@newupstream" (
      start_point VARCHAR(50),
      end_point VARCHAR(50),
      path VARCHAR(500),
      level INTEGER,
      PRIMARY KEY (start_point, end_point, path)
    );
    CREATE TEMP TABLE IF NOT EXISTS "@addupstream" (
      start_point VARCHAR(50),
      end_point VARCHAR(50),
      path VARCHAR(500),
      level INTEGER,
      PRIMARY KEY (start_point, end_point, path)
    );
    CREATE TEMP TABLE IF NOT EXISTS "@remupstream" (
      start_point VARCHAR(50),
      end_point VARCHAR(50),
      path VARCHAR(500),
      level INTEGER,
      PRIMARY KEY (start_point, end_point, path)
    );
    -- the input materials, minus any that may have already been cleaned
    -- in a previous round
    INSERT INTO perseus."@dirty"
      SELECT DISTINCT
          d.uid
        FROM
          perseus."@dirty_in" AS d
        WHERE NOT EXISTS (
          SELECT
              1
            FROM
              perseus."@clean_in" AS c
            WHERE c.uid = d.uid
        )
    ;
    /*
      -- add to the input materials any materials that are downstream of
      -- the input material(s), skipping those we already have or which are
      -- already in the clean list.  These will be processed as well and passed
      -- back to be added to the @clean collection in the caller.
      INSERT INTO @dirty
         SELECT DISTINCT start_point AS uid FROM m_upstream mu
           WHERE EXISTS (
             SELECT 1 FROM @dirty dl WHERE dl.uid = mu.end_point )
           AND NOT EXISTS (
             SELECT 1 FROM @dirty dl1 WHERE dl1.uid = mu.start_point )
           AND NOT EXISTS (
             SELECT 1 FROM @clean_in c WHERE c.uid = mu.start_point )
        */
    SELECT
        coalesce(CAST(count(*) as INTEGER), _dirty_count)
      INTO
        _dirty_count
      FROM
        perseus."@dirty"
      LIMIT 1
    ;
    IF _dirty_count > 0 THEN
      INSERT INTO "@oldupstream" (start_point, end_point, path, level)
        SELECT
            m_upstream.start_point,
            m_upstream.end_point,
            m_upstream.path,
            m_upstream.level
          FROM
            perseus.m_upstream
            JOIN perseus."@dirty" AS d ON d.uid = m_upstream.start_point
      ;
      INSERT INTO "@newupstream" (start_point, end_point, path, level)
        SELECT
            start_point,
            end_point,
            path,
            level
          FROM
            anon AS subrelation
      ;
      /** determine what, if any inserts are needed **/
      INSERT INTO "@addupstream" (start_point, end_point, path, level)
        SELECT
            n.start_point,
            n.end_point,
            n.path,
            n.level
          FROM
            "@newupstream" AS n
          WHERE NOT EXISTS (
            SELECT
                1
              FROM
                "@oldupstream" AS f
              WHERE f.start_point = n.start_point
               AND f.end_point = n.end_point
               AND f.path = n.path
          )
      ;
      /** Delete Obsolete Rows.  This (hopefully) serves to check
              for deletes before unnecessarily locking the table.
           **/
      INSERT INTO "@remupstream" (start_point, end_point, path, level)
        SELECT
            o.start_point,
            o.end_point,
            o.path,
            o.level
          FROM
            "@oldupstream" AS o
          WHERE NOT EXISTS (
            SELECT
                1
              FROM
                "@newupstream" AS n
              WHERE n.start_point = o.start_point
               AND n.end_point = o.end_point
               AND n.path = o.path
          )
      ;
      SELECT
          coalesce(CAST(count(*) as INTEGER), _add_rows)
        INTO
          _add_rows
        FROM
          "@addupstream"
        LIMIT 1
      ;
      SELECT
          coalesce(CAST(count(*) as INTEGER), _rem_rows)
        INTO
          _rem_rows
        FROM
          "@remupstream"
        LIMIT 1
      ;
      IF _add_rows > 0 THEN
        /** Insert New Rows **/
        INSERT INTO perseus.m_upstream (start_point, end_point, path, level)
          SELECT
              "@addupstream".start_point,
              "@addupstream".end_point,
              "@addupstream".path,
              "@addupstream".level
            FROM
              "@addupstream"
        ;
      END IF;
      IF _rem_rows > 0 THEN
        /** Delete Obsolete Rows **/
        DELETE FROM perseus.m_upstream WHERE m_upstream.start_point IN(
          SELECT
              uid
            FROM
              perseus."@dirty"
        )
         AND NOT EXISTS (
          SELECT
              1
            FROM
              "@newupstream" AS f
            WHERE f.start_point = m_upstream.start_point
             AND f.end_point = m_upstream.end_point
             AND f.path = m_upstream.path
        );
      END IF;
    END IF;
    -- return the list of processed start_point nodes.
    OPEN result_set_refcursor FOR SELECT
        perseus."@dirty".*
      FROM
        perseus."@dirty"
    ;
  END;
  $$;


ALTER PROCEDURE perseus.processsomemupstream_gemini(IN _dirty_in perseus.goolist, IN _clean_in perseus.goolist, INOUT result_set_refcursor refcursor) OWNER TO perseus_owner;

--
-- Name: reconcilemupstream(); Type: PROCEDURE; Schema: perseus; Owner: perseus_owner
--

CREATE PROCEDURE perseus.reconcilemupstream()
    LANGUAGE plpgsql
    AS $$
DECLARE
  _add_rows INTEGER;
  _rem_rows INTEGER;
  _dirty_count INTEGER;
BEGIN
  CREATE TEMP TABLE dirty (
    uid VARCHAR(50) PRIMARY KEY
  ) ON COMMIT DROP;
  CREATE TEMP TABLE oldupstream (
    start_point VARCHAR(50),
    end_point VARCHAR(50),
    path VARCHAR(500),
    "level" INT,
    PRIMARY KEY (start_point, end_point, path)
  ) ON COMMIT DROP;
  CREATE TEMP TABLE newupstream (
    start_point VARCHAR(50),
    end_point VARCHAR(50),
    path VARCHAR(500),
    "level" INT,
    PRIMARY KEY (start_point, end_point, path)
  ) ON COMMIT DROP;
  CREATE TEMP TABLE addupstream (
    start_point VARCHAR(50),
    end_point VARCHAR(50),
    path VARCHAR(500),
    "level" INT,
    PRIMARY KEY (start_point, end_point, path)
  ) ON COMMIT DROP;
  CREATE TEMP TABLE remupstream (
    start_point VARCHAR(50),
    end_point VARCHAR(50),
    path VARCHAR(500),
    "level" INT,
    PRIMARY KEY (start_point, end_point, path)
  ) ON COMMIT DROP;

  INSERT INTO dirty(uid)
  SELECT DISTINCT material_uid
  FROM perseus.m_upstream_dirty_leaves
  WHERE material_uid <> 'n/a'
  LIMIT 10;

  INSERT INTO dirty(uid)
  SELECT DISTINCT mu.start_point
  FROM perseus.m_upstream AS mu
  WHERE EXISTS (
      SELECT 1 FROM dirty AS dl WHERE dl.uid = mu.end_point
    )
    AND NOT EXISTS (
      SELECT 1 FROM dirty AS dl1 WHERE dl1.uid = mu.start_point
    )
    AND mu.start_point <> 'n/a'
  ON CONFLICT(uid) DO NOTHING;

  SELECT count(*) INTO _dirty_count
  FROM dirty;

  IF _dirty_count > 0 THEN
    DELETE FROM perseus.m_upstream_dirty_leaves
    WHERE EXISTS (
        SELECT 1 FROM dirty AS d WHERE d.uid = m_upstream_dirty_leaves.material_uid
      );

    INSERT INTO oldupstream (start_point, end_point, path, "level")
    SELECT m.start_point, m.end_point, m.path, m."level"
    FROM perseus.m_upstream m
    JOIN dirty d ON d.uid = m.start_point;

    INSERT INTO newupstream (start_point, end_point, path, "level")
    SELECT *
    FROM perseus.mcgetupstreambylist((SELECT array_agg(uid) FROM dirty));

    INSERT INTO addupstream (start_point, end_point, path, "level")
    SELECT n.start_point, n.end_point, n.path, n."level"
    FROM newupstream n
    WHERE NOT EXISTS (
        SELECT 1
        FROM oldupstream f
        WHERE f.start_point = n.start_point
          AND f.end_point = n.end_point
          AND f.path = n.path
      );

    INSERT INTO remupstream (start_point, end_point, path, "level")
    SELECT o.start_point, o.end_point, o.path, o."level"
    FROM oldupstream o
    WHERE NOT EXISTS(
        SELECT 1
        FROM newupstream n
        WHERE n.start_point = o.start_point
          AND n.end_point = o.end_point
          AND n.path = o.path
      );

    SELECT count(*) INTO _add_rows
    FROM addupstream;
    SELECT count(*) INTO _rem_rows
    FROM remupstream;

    IF _add_rows > 0 THEN
      INSERT INTO perseus.m_upstream (start_point, end_point, path, "level")
      SELECT a.start_point, a.end_point, a.path, a."level" FROM addupstream a;
    END IF;

    IF _rem_rows > 0 THEN
      DELETE FROM perseus.m_upstream
      WHERE start_point IN (SELECT uid FROM dirty)
        AND NOT EXISTS(
          SELECT 1
          FROM newupstream f
          WHERE f.start_point = m_upstream.start_point
            AND f.end_point = m_upstream.end_point
            AND f.path = m_upstream.path
        );
    END IF;
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    RAISE EXCEPTION 'Transaction rolled back in perseus.reconcilemupstream: %', SQLERRM;
END;
$$;


ALTER PROCEDURE perseus.reconcilemupstream() OWNER TO perseus_owner;

--
-- Name: removearc(character varying, character varying, character varying); Type: PROCEDURE; Schema: perseus; Owner: perseus_owner
--

CREATE PROCEDURE perseus.removearc(IN _materialuid character varying, IN _transitionuid character varying, IN _direction character varying)
    LANGUAGE plpgsql
    AS $$
  BEGIN
    /**
    	DECLARE @FormerDownstream TABLE (start_point VARCHAR(50), end_point VARCHAR(50), path VARCHAR(250), PRIMARY KEY (start_point, end_point, path))
    	DECLARE @FormerUpstream TABLE (start_point VARCHAR(50), end_point VARCHAR(50), path VARCHAR(250), PRIMARY KEY (start_point, end_point, path))
    	DECLARE @DeltaDownstream TABLE (start_point VARCHAR(50), end_point VARCHAR(50), path VARCHAR(250), PRIMARY KEY (start_point, end_point, path))
    	DECLARE @DeltaUpstream TABLE (start_point VARCHAR(50), end_point VARCHAR(50), path VARCHAR(250), PRIMARY KEY (start_point, end_point, path))
    	DECLARE @NewDownstream TABLE (start_point VARCHAR(50), end_point VARCHAR(50), path VARCHAR(250), PRIMARY KEY (start_point, end_point, path))
    	DECLARE @NewUpstream TABLE (start_point VARCHAR(50), end_point VARCHAR(50), path VARCHAR(250), PRIMARY KEY (start_point, end_point, path))
    	
    	INSERT INTO @FormerDownstream (start_point, end_point, path)
    	SELECT start_point, end_point, path FROM dbo.McGetDownStream(@MaterialUid)
    	INSERT INTO @FormerUpstream (start_point, end_point, path)
    	SELECT start_point, end_point, path FROM dbo.McGetUpStream(@MaterialUid)
    	**/
    IF removearc._direction = 'PT' THEN
      DELETE FROM perseus.material_transition WHERE material_transition.material_id = removearc._materialuid
       AND material_transition.transition_id = removearc._transitionuid;
    ELSE
      DELETE FROM perseus.transition_material WHERE transition_material.material_id = removearc._materialuid
       AND transition_material.transition_id = removearc._transitionuid;
    END IF;
  END;
  $$;


ALTER PROCEDURE perseus.removearc(IN _materialuid character varying, IN _transitionuid character varying, IN _direction character varying) OWNER TO perseus_owner;

--
-- Name: reversepath(character varying); Type: FUNCTION; Schema: perseus; Owner: perseus_owner
--

CREATE FUNCTION perseus.reversepath(_source character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
    DECLARE
      _dest VARCHAR;
    BEGIN
      _dest := '';
      IF length(rtrim(reversepath._source)) > 0 THEN
        -- chop off initial / (indexed by 1)
        reversepath._source := substr(reversepath._source, 2, length(rtrim(reversepath._source)));
        WHILE length(rtrim(reversepath._source)) > 0 LOOP
          _dest := substr(reversepath._source, 0, CAST(CAST(strpos(reversepath._source, '/') as BIGINT) as INTEGER)) || '/' || _dest;
          reversepath._source := substr(reversepath._source, CAST(strpos(reversepath._source, '/') + CAST(1 as BIGINT) as INTEGER), length(rtrim(reversepath._source)));
        END LOOP;
        _dest := '/' || _dest;
      END IF;
      RETURN _dest;
    END;
  $$;


ALTER FUNCTION perseus.reversepath(_source character varying) OWNER TO perseus_owner;

--
-- Name: rounddatetime(timestamp without time zone); Type: FUNCTION; Schema: perseus; Owner: perseus_owner
--

CREATE FUNCTION perseus.rounddatetime(_inputdatetime timestamp without time zone) RETURNS timestamp without time zone
    LANGUAGE plpgsql
    AS $$
    DECLARE
      _returndatetime TIMESTAMP;
    BEGIN
      _returndatetime := timestamp '1900-01-01' + interval '0 SECONDS' + interval '1 M' * (EXTRACT(EPOCH from rounddatetime._inputdatetime - timestamp '1900-01-01' + interval '0 SECONDS') / 60);
      RETURN _returndatetime;
    END;
  $$;


ALTER FUNCTION perseus.rounddatetime(_inputdatetime timestamp without time zone) OWNER TO perseus_owner;

--
-- Name: sp_move_node(integer, integer); Type: PROCEDURE; Schema: perseus; Owner: perseus_owner
--

CREATE PROCEDURE perseus.sp_move_node(IN _myid integer, IN _parentid integer)
    LANGUAGE plpgsql
    AS $$
  DECLARE
    _myformerscope VARCHAR(100);
    _myformerleft INTEGER;
    _myformerright INTEGER;
    _myparentscope VARCHAR(100);
    _myparentleft INTEGER;
  BEGIN
    SELECT
        tree_scope_key,
        tree_left_key
      INTO
        _myparentscope, _myparentleft
      FROM
        perseus.goo
      WHERE id = _parentid;

    SELECT
        tree_scope_key,
        tree_left_key,
        tree_right_key
      INTO
        _myformerscope, _myformerleft, _myformerright
      FROM
        perseus.goo
      WHERE id = _myid;

    UPDATE perseus.goo
    SET tree_left_key = tree_left_key + (_myformerright - _myformerleft) + 1
    WHERE tree_left_key > _myparentleft
    AND tree_scope_key = _myparentscope;

    UPDATE perseus.goo
    SET tree_right_key = tree_right_key + (_myformerright - _myformerleft) + 1
    WHERE tree_right_key > _myparentleft
    AND tree_scope_key = _myparentscope;

    UPDATE perseus.goo
    SET tree_scope_key = _myparentscope,
        tree_left_key = _myparentleft + (tree_left_key - _myformerleft) + 1,
        tree_right_key = _myparentleft + (tree_right_key - _myformerleft) + 1
    WHERE tree_scope_key = _myformerscope
    AND tree_left_key >= _myformerleft
    AND tree_right_key <= _myformerright;

    UPDATE perseus.goo
    SET tree_left_key = tree_left_key - (_myformerright - _myformerleft) - 1
    WHERE tree_left_key > _myformerright
    AND tree_scope_key = _myformerscope;

    UPDATE perseus.goo
    SET tree_right_key = tree_right_key - (_myformerright - _myformerleft) - 1
    WHERE tree_right_key > _myformerright
    AND tree_scope_key = _myformerscope;

  END;
  $$;


ALTER PROCEDURE perseus.sp_move_node(IN _myid integer, IN _parentid integer) OWNER TO perseus_owner;

--
-- Name: transitiontomaterial(character varying, character varying); Type: PROCEDURE; Schema: perseus; Owner: perseus_owner
--

CREATE PROCEDURE perseus.transitiontomaterial(IN _transitionuid character varying, IN _materialuid character varying)
    LANGUAGE plpgsql
    AS $$
  BEGIN
    INSERT INTO perseus.transition_material (material_id, transition_id)
      VALUES (transitiontomaterial._materialuid, transitiontomaterial._transitionuid)
    ;
  END;
  $$;


ALTER PROCEDURE perseus.transitiontomaterial(IN _transitionuid character varying, IN _materialuid character varying) OWNER TO perseus_owner;

--
-- Name: trg_fatsmurfupdatedon(); Type: FUNCTION; Schema: perseus; Owner: perseus_owner
--

CREATE FUNCTION perseus.trg_fatsmurfupdatedon() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  UPDATE perseus.fatsmurf SET updated_on = localtimestamp WHERE fatsmurf.id IN(
    SELECT DISTINCT
        inserted.id
      FROM
        inserted
  );
  RETURN new;
END;
$$;


ALTER FUNCTION perseus.trg_fatsmurfupdatedon() OWNER TO perseus_owner;

--
-- Name: trg_gooupdatedon(); Type: FUNCTION; Schema: perseus; Owner: perseus_owner
--

CREATE FUNCTION perseus.trg_gooupdatedon() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  UPDATE perseus.goo SET updated_on = localtimestamp WHERE goo.id IN(
    SELECT DISTINCT
        inserted.id
      FROM
        inserted
  );
  RETURN new;
END;
$$;


ALTER FUNCTION perseus.trg_gooupdatedon() OWNER TO perseus_owner;

--
-- Name: udf_datetrunc(timestamp without time zone); Type: FUNCTION; Schema: perseus; Owner: perseus_owner
--

CREATE FUNCTION perseus.udf_datetrunc(_datein timestamp without time zone) RETURNS timestamp without time zone
    LANGUAGE sql
    AS $$
    SELECT date_trunc('day', _datein);
  $$;


ALTER FUNCTION perseus.udf_datetrunc(_datein timestamp without time zone) OWNER TO perseus_owner;

--
-- Name: usp_updatemdownstream(); Type: PROCEDURE; Schema: perseus; Owner: perseus_owner
--

CREATE PROCEDURE perseus.usp_updatemdownstream()
    LANGUAGE plpgsql
    AS $$
BEGIN
    WITH dsg_uids AS (
      SELECT
          g.uid
        FROM
          perseus.material_transition_material AS mtm
          JOIN perseus.goo AS g ON g.uid = mtm.start_point
        WHERE NOT EXISTS (
          SELECT
              1
            FROM
              perseus.m_downstream AS us
            WHERE us.start_point = mtm.start_point
        )
        ORDER BY
          g.added_on DESC
        LIMIT 500
    )
    INSERT INTO perseus.m_downstream (start_point, end_point, path, level)
      SELECT
          f.start_point,
          f.end_point,
          f.path,
          f.level
        FROM
          perseus.mcgetdownstreambylist((
            SELECT
                array_agg(dsg_uids.uid)
              FROM
                dsg_uids
          )) AS f;

    COMMIT;

    INSERT INTO perseus.m_downstream (start_point, end_point, path, level)
      SELECT
          up.end_point,
          up.start_point,
          perseus.reversepath(up.path),
          up.level
        FROM
          perseus.m_upstream AS up
        WHERE NOT EXISTS (
          SELECT
              1
            FROM
              perseus.m_downstream AS down
            WHERE up.end_point = down.start_point
             AND up.start_point = down.end_point
             AND perseus.reversepath(up.path) = down.path
        )
        LIMIT 500;

    COMMIT;
  END;
$$;


ALTER PROCEDURE perseus.usp_updatemdownstream() OWNER TO perseus_owner;

--
-- Name: usp_updatemupstream(); Type: PROCEDURE; Schema: perseus; Owner: perseus_owner
--

CREATE PROCEDURE perseus.usp_updatemupstream()
    LANGUAGE plpgsql
    AS $$
  BEGIN
    WITH us_goo_uids AS (
      SELECT DISTINCT
        d.uid
      FROM (
        SELECT
          g.uid
        FROM
          perseus.material_transition_material AS mtm
          JOIN perseus.goo AS g
            ON g.uid = mtm.end_point
        WHERE
          NOT EXISTS (
            SELECT
              1
            FROM
              perseus.m_upstream AS us
            WHERE
              us.start_point = mtm.end_point
          )
        ORDER BY
          g.added_on DESC NULLS LAST
        LIMIT 10000
      ) AS d
      UNION
      SELECT DISTINCT
        goo.uid
      FROM
        perseus.goo
      WHERE
        NOT EXISTS (
          SELECT
            1
          FROM
            perseus.m_upstream
          WHERE
            goo.uid = m_upstream.start_point
        )
      LIMIT 10000
    )
    INSERT INTO perseus.m_upstream (start_point, end_point, path, level)
    SELECT
      f.start_point,
      f.end_point,
      f.path,
      f.level
    FROM
      perseus.mcgetupstreambylist (ARRAY(
        SELECT
          uid
        FROM
          us_goo_uids
      )) AS f (start_point, end_point, path, level);
  END;
  $$;


ALTER PROCEDURE perseus.usp_updatemupstream() OWNER TO perseus_owner;

--
-- Name: validatetransitionmaterial(); Type: FUNCTION; Schema: perseus; Owner: perseus_owner
--

CREATE FUNCTION perseus.validatetransitionmaterial() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF (
    SELECT
        CAST(count(*) as INTEGER)
      FROM
        inserted AS ins
        JOIN perseus.transition_material AS tm ON ins.material_id = tm.material_id
      WHERE tm.transition_id <> ins.transition_id
  ) > 0 THEN
    RAISE EXCEPTION SQLSTATE 'CW100' USING MESSAGE = 'A material cannot be the output of more than 1 process.';
    RETURN new;
  END IF;
  RETURN new;
END;
$$;


ALTER FUNCTION perseus.validatetransitionmaterial() OWNER TO perseus_owner;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: alembic_version; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.alembic_version (
    version_num character varying(32) NOT NULL
);


ALTER TABLE perseus.alembic_version OWNER TO perseus_owner;

--
-- Name: cm_application; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.cm_application (
    application_id integer NOT NULL,
    label public.citext NOT NULL,
    description public.citext NOT NULL,
    is_active smallint NOT NULL,
    application_group_id integer,
    url public.citext,
    owner_user_id integer,
    jira_id public.citext
);


ALTER TABLE perseus.cm_application OWNER TO perseus_owner;

--
-- Name: cm_application_group; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.cm_application_group (
    application_group_id integer NOT NULL,
    label public.citext NOT NULL
);


ALTER TABLE perseus.cm_application_group OWNER TO perseus_owner;

--
-- Name: cm_application_group_application_group_id_seq; Type: SEQUENCE; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE perseus.cm_application_group ALTER COLUMN application_group_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME perseus.cm_application_group_application_group_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: cm_group; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.cm_group (
    group_id integer NOT NULL,
    name public.citext NOT NULL,
    domain_id public.citext NOT NULL,
    is_active boolean NOT NULL,
    last_modified timestamp without time zone NOT NULL
);


ALTER TABLE perseus.cm_group OWNER TO perseus_owner;

--
-- Name: cm_group_group_id_seq; Type: SEQUENCE; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE perseus.cm_group ALTER COLUMN group_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME perseus.cm_group_group_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: cm_project; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.cm_project (
    project_id smallint NOT NULL,
    label public.citext NOT NULL,
    is_active boolean NOT NULL,
    display_order smallint NOT NULL,
    group_id integer
);


ALTER TABLE perseus.cm_project OWNER TO perseus_owner;

--
-- Name: cm_unit; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.cm_unit (
    id integer NOT NULL,
    description public.citext,
    longname public.citext,
    dimensions_id integer,
    name public.citext,
    factor numeric(20,10),
    "offset" numeric(20,10)
);


ALTER TABLE perseus.cm_unit OWNER TO perseus_owner;

--
-- Name: cm_unit_compare; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.cm_unit_compare (
    from_unit_id integer NOT NULL,
    to_unit_id integer NOT NULL
);


ALTER TABLE perseus.cm_unit_compare OWNER TO perseus_owner;

--
-- Name: cm_unit_dimensions; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.cm_unit_dimensions (
    id integer NOT NULL,
    mass numeric(10,2),
    length numeric(10,2),
    "time" numeric(10,2),
    electric_current numeric(10,2),
    thermodynamic_temperature numeric(10,2),
    amount_of_substance numeric(10,2),
    luminous_intensity numeric(10,2),
    default_unit_id integer NOT NULL,
    name public.citext NOT NULL
);


ALTER TABLE perseus.cm_unit_dimensions OWNER TO perseus_owner;

--
-- Name: cm_user; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.cm_user (
    user_id integer NOT NULL,
    domain_id public.citext,
    is_active boolean NOT NULL,
    name public.citext NOT NULL,
    login public.citext,
    email public.citext,
    object_id uuid
);


ALTER TABLE perseus.cm_user OWNER TO perseus_owner;

--
-- Name: cm_user_group; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.cm_user_group (
    user_id integer NOT NULL,
    group_id integer NOT NULL
);


ALTER TABLE perseus.cm_user_group OWNER TO perseus_owner;

--
-- Name: cm_user_user_id_seq; Type: SEQUENCE; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE perseus.cm_user ALTER COLUMN user_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME perseus.cm_user_user_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: coa; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.coa (
    id integer NOT NULL,
    name public.citext NOT NULL,
    goo_type_id integer NOT NULL
);


ALTER TABLE perseus.coa OWNER TO perseus_owner;

--
-- Name: coa_id_seq; Type: SEQUENCE; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE perseus.coa ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME perseus.coa_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: coa_spec; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.coa_spec (
    id integer NOT NULL,
    coa_id integer NOT NULL,
    property_id integer NOT NULL,
    upper_bound double precision,
    lower_bound double precision,
    equal_bound public.citext,
    upper_equal_bound double precision,
    lower_equal_bound double precision,
    result_precision integer DEFAULT 0
);


ALTER TABLE perseus.coa_spec OWNER TO perseus_owner;

--
-- Name: coa_spec_id_seq; Type: SEQUENCE; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE perseus.coa_spec ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME perseus.coa_spec_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: color; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.color (
    name public.citext NOT NULL
);


ALTER TABLE perseus.color OWNER TO perseus_owner;

--
-- Name: property; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.property (
    id integer NOT NULL,
    name public.citext NOT NULL,
    description public.citext,
    unit_id integer
);


ALTER TABLE perseus.property OWNER TO perseus_owner;

--
-- Name: property_option; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.property_option (
    id integer NOT NULL,
    property_id integer NOT NULL,
    value integer NOT NULL,
    label public.citext NOT NULL,
    disabled integer DEFAULT 0 NOT NULL
);


ALTER TABLE perseus.property_option OWNER TO perseus_owner;

--
-- Name: smurf; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.smurf (
    id integer NOT NULL,
    class_id integer NOT NULL,
    name public.citext NOT NULL,
    description public.citext,
    themis_method_id integer,
    disabled boolean DEFAULT false NOT NULL
);


ALTER TABLE perseus.smurf OWNER TO perseus_owner;

--
-- Name: smurf_property; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.smurf_property (
    id integer NOT NULL,
    property_id integer NOT NULL,
    sort_order integer DEFAULT 99 NOT NULL,
    smurf_id integer NOT NULL,
    disabled boolean DEFAULT false NOT NULL,
    calculated public.citext
);


ALTER TABLE perseus.smurf_property OWNER TO perseus_owner;

--
-- Name: unit; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.unit (
    id integer NOT NULL,
    name public.citext NOT NULL,
    description public.citext,
    dimension_id integer,
    factor double precision,
    "offset" double precision
);


ALTER TABLE perseus.unit OWNER TO perseus_owner;

--
-- Name: combined_sp_field_map; Type: VIEW; Schema: perseus; Owner: perseus_owner
--

CREATE VIEW perseus.combined_sp_field_map AS
 SELECT (sp.id + 20000) AS id,
    (sp.smurf_id + 1000) AS field_map_block_id,
    ((p.name)::text ||
        CASE
            WHEN (u.name IS NOT NULL) THEN ((' ('::text || (u.name)::text) || ')'::text)
            ELSE ''::text
        END) AS name,
    NULL::character varying(50) AS description,
    sp.sort_order AS display_order,
    (('setPollValueBySpid('::text || sp.id) || ', ?)'::text) AS setter,
        CASE
            WHEN (po.property_id IS NULL) THEN (NULL::character varying)::text
            ELSE (('PropertyPeer::getLookupByPropertyId('::text || po.property_id) || ')'::text)
        END AS lookup,
    NULL::character varying(50) AS lookup_service,
    1 AS nullable,
        CASE
            WHEN (po.property_id IS NOT NULL) THEN 12
            ELSE 10
        END AS field_map_type_id,
    NULL::character varying(50) AS database_id,
    1 AS save_sequence,
    NULL::character varying(50) AS onchange,
        CASE
            WHEN (s.class_id = 2) THEN 9
            ELSE 12
        END AS field_map_set_id
   FROM ((((perseus.smurf_property sp
     JOIN perseus.smurf s ON ((sp.smurf_id = s.id)))
     JOIN perseus.property p ON ((sp.property_id = p.id)))
     LEFT JOIN perseus.unit u ON ((u.id = p.unit_id)))
     LEFT JOIN perseus.property_option po ON ((po.property_id = p.id)))
UNION
 SELECT (sp_0.id + 30000) AS id,
    (sp_0.smurf_id + 2000) AS field_map_block_id,
    ((p_0.name)::text ||
        CASE
            WHEN (u_0.name IS NOT NULL) THEN ((' ('::text || (u_0.name)::text) || ')'::text)
            ELSE ''::text
        END) AS name,
    NULL::character varying(50) AS description,
    sp_0.sort_order AS display_order,
    NULL::text AS setter,
    NULL::text AS lookup,
    NULL::character varying(50) AS lookup_service,
    1 AS nullable,
        CASE
            WHEN (po_0.property_id IS NOT NULL) THEN 12
            ELSE 10
        END AS field_map_type_id,
    NULL::character varying(50) AS database_id,
    2 AS save_sequence,
    NULL::character varying(50) AS onchange,
        CASE
            WHEN (s_0.class_id = 2) THEN 9
            ELSE 12
        END AS field_map_set_id
   FROM ((((perseus.smurf_property sp_0
     JOIN perseus.smurf s_0 ON ((sp_0.smurf_id = s_0.id)))
     JOIN perseus.property p_0 ON ((sp_0.property_id = p_0.id)))
     LEFT JOIN perseus.unit u_0 ON ((u_0.id = p_0.unit_id)))
     LEFT JOIN perseus.property_option po_0 ON ((po_0.property_id = p_0.id)))
UNION
 SELECT (sp_1.id + 40000) AS id,
    (sp_1.smurf_id + 3000) AS field_map_block_id,
    ((p_1.name)::text ||
        CASE
            WHEN (u_1.name IS NOT NULL) THEN ((' ('::text || (u_1.name)::text) || ')'::text)
            ELSE ''::text
        END) AS name,
    NULL::character varying(50) AS description,
    sp_1.sort_order AS display_order,
    (('setPollValueBySpid('::text || sp_1.id) || ', ?)'::text) AS setter,
        CASE
            WHEN (po_1.property_id IS NULL) THEN (NULL::character varying)::text
            ELSE (('PropertyPeer::getLookupByPropertyId('::text || po_1.property_id) || ')'::text)
        END AS lookup,
    NULL::character varying(50) AS lookup_service,
    1 AS nullable,
        CASE
            WHEN (po_1.property_id IS NOT NULL) THEN 12
            ELSE 10
        END AS field_map_type_id,
    NULL::character varying(50) AS database_id,
    2 AS save_sequence,
    NULL::character varying(50) AS onchange,
        CASE
            WHEN (s_1.class_id = 2) THEN 9
            ELSE 12
        END AS field_map_set_id
   FROM ((((perseus.smurf_property sp_1
     JOIN perseus.smurf s_1 ON ((sp_1.smurf_id = s_1.id)))
     JOIN perseus.property p_1 ON ((sp_1.property_id = p_1.id)))
     LEFT JOIN perseus.unit u_1 ON ((u_1.id = p_1.unit_id)))
     LEFT JOIN perseus.property_option po_1 ON ((po_1.property_id = p_1.id)));


ALTER VIEW perseus.combined_sp_field_map OWNER TO perseus_owner;

--
-- Name: field_map; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.field_map (
    id integer NOT NULL,
    field_map_block_id integer NOT NULL,
    name public.citext,
    description public.citext,
    display_order integer,
    setter public.citext,
    lookup public.citext,
    lookup_service public.citext,
    nullable integer,
    field_map_type_id integer NOT NULL,
    database_id public.citext,
    save_sequence integer NOT NULL,
    onchange public.citext,
    field_map_set_id integer NOT NULL
);


ALTER TABLE perseus.field_map OWNER TO perseus_owner;

--
-- Name: combined_field_map; Type: VIEW; Schema: perseus; Owner: perseus_owner
--

CREATE VIEW perseus.combined_field_map AS
 SELECT field_map.id,
    field_map.field_map_block_id,
    field_map.name,
    field_map.description,
    field_map.display_order,
    field_map.setter,
    field_map.lookup,
    field_map.lookup_service,
    field_map.nullable,
    field_map.field_map_type_id,
    field_map.database_id,
    field_map.save_sequence,
    field_map.onchange,
    field_map.field_map_set_id
   FROM perseus.field_map
UNION
 SELECT combined_sp_field_map.id,
    combined_sp_field_map.field_map_block_id,
    combined_sp_field_map.name,
    combined_sp_field_map.description,
    combined_sp_field_map.display_order,
    combined_sp_field_map.setter,
    combined_sp_field_map.lookup,
    combined_sp_field_map.lookup_service,
    combined_sp_field_map.nullable,
    combined_sp_field_map.field_map_type_id,
    combined_sp_field_map.database_id,
    combined_sp_field_map.save_sequence,
    combined_sp_field_map.onchange,
    combined_sp_field_map.field_map_set_id
   FROM perseus.combined_sp_field_map;


ALTER VIEW perseus.combined_field_map OWNER TO perseus_owner;

--
-- Name: field_map_block; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.field_map_block (
    id integer NOT NULL,
    filter public.citext,
    scope public.citext
);


ALTER TABLE perseus.field_map_block OWNER TO perseus_owner;

--
-- Name: combined_field_map_block; Type: VIEW; Schema: perseus; Owner: perseus_owner
--

CREATE VIEW perseus.combined_field_map_block AS
 SELECT field_map_block.id,
    field_map_block.filter,
    field_map_block.scope
   FROM perseus.field_map_block
UNION
 SELECT (smurf.id + 1000) AS id,
    (('isSmurf('::text || smurf.id) || ')'::text) AS filter,
    'FatSmurfReading'::character varying AS scope
   FROM perseus.smurf
UNION
 SELECT (smurf_0.id + 2000) AS id,
    (('isSmurf('::text || smurf_0.id) || ')'::text) AS filter,
    'FatSmurf'::character varying AS scope
   FROM perseus.smurf smurf_0
UNION
 SELECT (smurf_1.id + 3000) AS id,
    (('isSmurfWithOneReading('::text || smurf_1.id) || ')'::text) AS filter,
    'FatSmurf'::character varying AS scope
   FROM perseus.smurf smurf_1;


ALTER VIEW perseus.combined_field_map_block OWNER TO perseus_owner;

--
-- Name: display_layout; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.display_layout (
    id integer NOT NULL,
    name public.citext NOT NULL
);


ALTER TABLE perseus.display_layout OWNER TO perseus_owner;

--
-- Name: combined_sp_field_map_display_type; Type: VIEW; Schema: perseus; Owner: perseus_owner
--

CREATE VIEW perseus.combined_sp_field_map_display_type AS
 SELECT ((sp.id + 10000) + dl.id) AS id,
    (sp.id + 20000) AS field_map_id,
    dl.id AS display_type_id,
    (('getPollValueBySmurfPropertyId('::text || sp.id) || ')'::text) AS display,
    5 AS display_layout_id,
    0 AS manditory
   FROM ((perseus.smurf_property sp
     JOIN perseus.smurf s ON ((s.id = sp.smurf_id)))
     JOIN perseus.property p ON ((p.id = sp.property_id))),
    perseus.display_layout dl
  WHERE ((sp.disabled = false) AND (dl.id = 1))
UNION
 SELECT ((sp_0.id + 20000) + dl_0.id) AS id,
    (sp_0.id + 20000) AS field_map_id,
    dl_0.id AS display_type_id,
    (('getPollValueBySmurfPropertyId('::text || sp_0.id) || ')'::text) AS display,
    7 AS display_layout_id,
    0 AS manditory
   FROM ((perseus.smurf_property sp_0
     JOIN perseus.smurf s_0 ON ((s_0.id = sp_0.smurf_id)))
     JOIN perseus.property p_0 ON ((p_0.id = sp_0.property_id))),
    perseus.display_layout dl_0
  WHERE ((sp_0.disabled = false) AND (dl_0.id = 7))
UNION
 SELECT ((sp_1.id + 30000) + dl_1.id) AS id,
    (sp_1.id + 30000) AS field_map_id,
    dl_1.id AS display_type_id,
    (('getPollValueStringBySmurfPropertyId('::text || sp_1.id) || ')'::text) AS display,
    7 AS display_layout_id,
    0 AS manditory
   FROM ((perseus.smurf_property sp_1
     JOIN perseus.smurf s_1 ON ((s_1.id = sp_1.smurf_id)))
     JOIN perseus.property p_1 ON ((p_1.id = sp_1.property_id))),
    perseus.display_layout dl_1
  WHERE ((sp_1.disabled = false) AND (dl_1.id = 3))
UNION
 SELECT ((sp_2.id + 40000) + dl_2.id) AS id,
    (sp_2.id + 30000) AS field_map_id,
    dl_2.id AS display_type_id,
    (('getPollValueStringBySmurfPropertyId('::text || sp_2.id) || ')'::text) AS display,
    7 AS display_layout_id,
    0 AS manditory
   FROM ((perseus.smurf_property sp_2
     JOIN perseus.smurf s_2 ON ((s_2.id = sp_2.smurf_id)))
     JOIN perseus.property p_2 ON ((p_2.id = sp_2.property_id))),
    perseus.display_layout dl_2
  WHERE ((sp_2.disabled = false) AND (dl_2.id = 6))
UNION
 SELECT ((sp_3.id + 50000) + dl_3.id) AS id,
    (sp_3.id + 40000) AS field_map_id,
    dl_3.id AS display_type_id,
    (('getPollValueBySmurfPropertyId('::text || sp_3.id) || ')'::text) AS display,
    5 AS display_layout_id,
    0 AS manditory
   FROM ((perseus.smurf_property sp_3
     JOIN perseus.smurf s_3 ON ((s_3.id = sp_3.smurf_id)))
     JOIN perseus.property p_3 ON ((p_3.id = sp_3.property_id))),
    perseus.display_layout dl_3
  WHERE ((sp_3.disabled = false) AND (dl_3.id = 1));


ALTER VIEW perseus.combined_sp_field_map_display_type OWNER TO perseus_owner;

--
-- Name: field_map_display_type; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.field_map_display_type (
    id integer NOT NULL,
    field_map_id integer NOT NULL,
    display_type_id integer NOT NULL,
    display public.citext NOT NULL,
    display_layout_id integer DEFAULT 1 NOT NULL,
    manditory integer DEFAULT 0 NOT NULL
);


ALTER TABLE perseus.field_map_display_type OWNER TO perseus_owner;

--
-- Name: combined_field_map_display_type; Type: VIEW; Schema: perseus; Owner: perseus_owner
--

CREATE VIEW perseus.combined_field_map_display_type AS
 SELECT field_map_display_type.id,
    field_map_display_type.field_map_id,
    field_map_display_type.display_type_id,
    field_map_display_type.display,
    field_map_display_type.display_layout_id,
    field_map_display_type.manditory
   FROM perseus.field_map_display_type
UNION
 SELECT combined_sp_field_map_display_type.id,
    combined_sp_field_map_display_type.field_map_id,
    combined_sp_field_map_display_type.display_type_id,
    combined_sp_field_map_display_type.display,
    combined_sp_field_map_display_type.display_layout_id,
    combined_sp_field_map_display_type.manditory
   FROM perseus.combined_sp_field_map_display_type;


ALTER VIEW perseus.combined_field_map_display_type OWNER TO perseus_owner;

--
-- Name: container; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.container (
    id integer NOT NULL,
    container_type_id integer NOT NULL,
    name public.citext,
    uid public.citext NOT NULL,
    mass double precision,
    left_id integer DEFAULT 1 NOT NULL,
    right_id integer DEFAULT 2 NOT NULL,
    scope_id public.citext DEFAULT (gen_random_uuid())::character varying(50) NOT NULL,
    position_name public.citext,
    position_x_coordinate public.citext,
    position_y_coordinate public.citext,
    depth integer DEFAULT 0 NOT NULL,
    created_on timestamp without time zone DEFAULT LOCALTIMESTAMP
);


ALTER TABLE perseus.container OWNER TO perseus_owner;

--
-- Name: container_history; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.container_history (
    id integer NOT NULL,
    history_id integer NOT NULL,
    container_id integer NOT NULL
);


ALTER TABLE perseus.container_history OWNER TO perseus_owner;

--
-- Name: container_history_id_seq; Type: SEQUENCE; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE perseus.container_history ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME perseus.container_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: container_id_seq; Type: SEQUENCE; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE perseus.container ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME perseus.container_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: container_type; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.container_type (
    id integer NOT NULL,
    name public.citext NOT NULL,
    is_parent boolean DEFAULT false NOT NULL,
    is_equipment boolean DEFAULT false NOT NULL,
    is_single boolean DEFAULT false NOT NULL,
    is_restricted boolean DEFAULT false NOT NULL,
    is_gooable boolean DEFAULT false NOT NULL
);


ALTER TABLE perseus.container_type OWNER TO perseus_owner;

--
-- Name: container_type_id_seq; Type: SEQUENCE; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE perseus.container_type ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME perseus.container_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: container_type_position; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.container_type_position (
    id integer NOT NULL,
    parent_container_type_id integer NOT NULL,
    child_container_type_id integer,
    position_name public.citext,
    position_x_coordinate public.citext,
    position_y_coordinate public.citext
);


ALTER TABLE perseus.container_type_position OWNER TO perseus_owner;

--
-- Name: container_type_position_id_seq; Type: SEQUENCE; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE perseus.container_type_position ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME perseus.container_type_position_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: display_type; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.display_type (
    id integer NOT NULL,
    name public.citext NOT NULL
);


ALTER TABLE perseus.display_type OWNER TO perseus_owner;

--
-- Name: material_transition; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.material_transition (
    material_id public.citext NOT NULL,
    transition_id public.citext NOT NULL,
    added_on timestamp without time zone DEFAULT LOCALTIMESTAMP NOT NULL
);


ALTER TABLE perseus.material_transition OWNER TO perseus_owner;

--
-- Name: transition_material; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.transition_material (
    transition_id public.citext NOT NULL,
    material_id public.citext NOT NULL
);


ALTER TABLE perseus.transition_material OWNER TO perseus_owner;

--
-- Name: translated; Type: VIEW; Schema: perseus; Owner: perseus_owner
--

CREATE VIEW perseus.translated AS
 SELECT mt.material_id AS source_material,
    tm.material_id AS destination_material,
    mt.transition_id
   FROM (perseus.material_transition mt
     JOIN perseus.transition_material tm ON (((tm.transition_id)::text = (mt.transition_id)::text)));


ALTER VIEW perseus.translated OWNER TO perseus_owner;

--
-- Name: downstream; Type: VIEW; Schema: perseus; Owner: perseus_owner
--

CREATE VIEW perseus.downstream AS
 WITH RECURSIVE downstream AS (
         SELECT pt.source_material AS start_point,
            pt.source_material AS parent,
            pt.destination_material AS child,
            '/'::text AS path,
            1 AS level
           FROM perseus.translated pt
        UNION ALL
         SELECT r.start_point,
            pt_0.source_material,
            pt_0.destination_material,
            ((r.path || (r.child)::text) || '/'::text),
            (r.level + 1)
           FROM (perseus.translated pt_0
             JOIN downstream r ON (((pt_0.source_material)::text = (r.child)::text)))
          WHERE ((pt_0.source_material)::text <> (pt_0.destination_material)::text)
        )
 SELECT start_point,
    child AS end_point,
    path,
    level
   FROM downstream;


ALTER VIEW perseus.downstream OWNER TO perseus_owner;

--
-- Name: external_goo_type; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.external_goo_type (
    id integer NOT NULL,
    goo_type_id integer NOT NULL,
    external_label public.citext NOT NULL,
    manufacturer_id integer NOT NULL
);


ALTER TABLE perseus.external_goo_type OWNER TO perseus_owner;

--
-- Name: external_goo_type_id_seq; Type: SEQUENCE; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE perseus.external_goo_type ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME perseus.external_goo_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: fatsmurf; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.fatsmurf (
    id integer NOT NULL,
    smurf_id integer NOT NULL,
    recycled_bottoms_id integer,
    name public.citext,
    description public.citext,
    added_on timestamp without time zone DEFAULT LOCALTIMESTAMP NOT NULL,
    run_on timestamp without time zone,
    duration double precision,
    added_by integer NOT NULL,
    themis_sample_id integer,
    uid public.citext NOT NULL,
    run_complete timestamp without time zone,
    container_id integer,
    organization_id integer DEFAULT 1,
    workflow_step_id integer,
    updated_on timestamp without time zone DEFAULT LOCALTIMESTAMP,
    inserted_on timestamp without time zone DEFAULT LOCALTIMESTAMP,
    triton_task_id integer
);


ALTER TABLE perseus.fatsmurf OWNER TO perseus_owner;

--
-- Name: fatsmurf_attachment; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.fatsmurf_attachment (
    id integer NOT NULL,
    fatsmurf_id integer NOT NULL,
    added_on timestamp without time zone DEFAULT LOCALTIMESTAMP NOT NULL,
    added_by integer NOT NULL,
    description public.citext NOT NULL,
    attachment_name public.citext,
    attachment_mime_type public.citext,
    attachment bytea
);


ALTER TABLE perseus.fatsmurf_attachment OWNER TO perseus_owner;

--
-- Name: fatsmurf_attachment_id_seq; Type: SEQUENCE; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE perseus.fatsmurf_attachment ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME perseus.fatsmurf_attachment_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: fatsmurf_comment; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.fatsmurf_comment (
    id integer NOT NULL,
    fatsmurf_id integer NOT NULL,
    added_on timestamp without time zone DEFAULT LOCALTIMESTAMP NOT NULL,
    added_by integer NOT NULL,
    comment public.citext NOT NULL
);


ALTER TABLE perseus.fatsmurf_comment OWNER TO perseus_owner;

--
-- Name: fatsmurf_comment_id_seq; Type: SEQUENCE; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE perseus.fatsmurf_comment ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME perseus.fatsmurf_comment_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: fatsmurf_history; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.fatsmurf_history (
    id integer NOT NULL,
    history_id integer NOT NULL,
    fatsmurf_id integer NOT NULL
);


ALTER TABLE perseus.fatsmurf_history OWNER TO perseus_owner;

--
-- Name: fatsmurf_history_id_seq; Type: SEQUENCE; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE perseus.fatsmurf_history ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME perseus.fatsmurf_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: fatsmurf_id_seq; Type: SEQUENCE; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE perseus.fatsmurf ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME perseus.fatsmurf_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: fatsmurf_reading; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.fatsmurf_reading (
    id integer NOT NULL,
    name public.citext NOT NULL,
    fatsmurf_id integer NOT NULL,
    added_on timestamp without time zone DEFAULT LOCALTIMESTAMP NOT NULL,
    added_by integer DEFAULT 1 NOT NULL
);


ALTER TABLE perseus.fatsmurf_reading OWNER TO perseus_owner;

--
-- Name: fatsmurf_reading_id_seq; Type: SEQUENCE; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE perseus.fatsmurf_reading ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME perseus.fatsmurf_reading_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: feed_type; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.feed_type (
    id integer NOT NULL,
    added_by integer NOT NULL,
    updated_by_id integer,
    name public.citext,
    description public.citext,
    correction_method public.citext DEFAULT 'SIMPLE'::character varying NOT NULL,
    correction_factor double precision DEFAULT 1.0 NOT NULL,
    disabled boolean DEFAULT (0)::boolean NOT NULL,
    added_on timestamp without time zone DEFAULT LOCALTIMESTAMP NOT NULL,
    updated_on timestamp without time zone DEFAULT LOCALTIMESTAMP
);


ALTER TABLE perseus.feed_type OWNER TO perseus_owner;

--
-- Name: feed_type_id_seq; Type: SEQUENCE; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE perseus.feed_type ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME perseus.feed_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: field_map_block_id_seq; Type: SEQUENCE; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE perseus.field_map_block ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME perseus.field_map_block_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: field_map_display_type_id_seq; Type: SEQUENCE; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE perseus.field_map_display_type ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME perseus.field_map_display_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: field_map_display_type_user; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.field_map_display_type_user (
    id integer NOT NULL,
    field_map_display_type_id integer NOT NULL,
    user_id integer NOT NULL
);


ALTER TABLE perseus.field_map_display_type_user OWNER TO perseus_owner;

--
-- Name: field_map_display_type_user_id_seq; Type: SEQUENCE; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE perseus.field_map_display_type_user ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME perseus.field_map_display_type_user_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: field_map_id_seq; Type: SEQUENCE; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE perseus.field_map ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME perseus.field_map_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: field_map_set; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.field_map_set (
    id integer NOT NULL,
    tab_group_id integer,
    display_order integer,
    name public.citext,
    color public.citext,
    size integer
);


ALTER TABLE perseus.field_map_set OWNER TO perseus_owner;

--
-- Name: field_map_type; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.field_map_type (
    id integer NOT NULL,
    name public.citext NOT NULL
);


ALTER TABLE perseus.field_map_type OWNER TO perseus_owner;

--
-- Name: goo; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.goo (
    id integer NOT NULL,
    name public.citext,
    description public.citext,
    added_on timestamp without time zone DEFAULT LOCALTIMESTAMP NOT NULL,
    added_by integer NOT NULL,
    original_volume double precision DEFAULT 0,
    original_mass double precision DEFAULT 0,
    goo_type_id integer DEFAULT 8 NOT NULL,
    manufacturer_id integer DEFAULT 1 NOT NULL,
    received_on date,
    uid public.citext NOT NULL,
    project_id smallint,
    container_id integer,
    workflow_step_id integer,
    updated_on timestamp without time zone DEFAULT LOCALTIMESTAMP,
    inserted_on timestamp without time zone DEFAULT LOCALTIMESTAMP,
    triton_task_id integer,
    recipe_id integer,
    recipe_part_id integer,
    catalog_label public.citext
);


ALTER TABLE perseus.goo OWNER TO perseus_owner;

--
-- Name: goo_attachment; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.goo_attachment (
    id integer NOT NULL,
    goo_id integer NOT NULL,
    added_on timestamp without time zone DEFAULT LOCALTIMESTAMP NOT NULL,
    added_by integer NOT NULL,
    description public.citext,
    attachment_name public.citext NOT NULL,
    attachment_mime_type public.citext,
    attachment bytea,
    goo_attachment_type_id integer
);


ALTER TABLE perseus.goo_attachment OWNER TO perseus_owner;

--
-- Name: goo_attachment_id_seq; Type: SEQUENCE; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE perseus.goo_attachment ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME perseus.goo_attachment_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: goo_attachment_type; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.goo_attachment_type (
    id integer NOT NULL,
    name public.citext NOT NULL
);


ALTER TABLE perseus.goo_attachment_type OWNER TO perseus_owner;

--
-- Name: goo_attachment_type_id_seq; Type: SEQUENCE; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE perseus.goo_attachment_type ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME perseus.goo_attachment_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: goo_comment; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.goo_comment (
    id integer NOT NULL,
    goo_id integer NOT NULL,
    added_on timestamp without time zone DEFAULT LOCALTIMESTAMP NOT NULL,
    added_by integer NOT NULL,
    comment public.citext NOT NULL,
    category public.citext
);


ALTER TABLE perseus.goo_comment OWNER TO perseus_owner;

--
-- Name: goo_comment_id_seq; Type: SEQUENCE; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE perseus.goo_comment ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME perseus.goo_comment_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: goo_history; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.goo_history (
    id integer NOT NULL,
    history_id integer NOT NULL,
    goo_id integer NOT NULL
);


ALTER TABLE perseus.goo_history OWNER TO perseus_owner;

--
-- Name: goo_history_id_seq; Type: SEQUENCE; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE perseus.goo_history ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME perseus.goo_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: goo_id_seq; Type: SEQUENCE; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE perseus.goo ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME perseus.goo_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: goo_process_queue_type; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.goo_process_queue_type (
    id integer NOT NULL,
    name public.citext NOT NULL
);


ALTER TABLE perseus.goo_process_queue_type OWNER TO perseus_owner;

--
-- Name: goo_process_queue_type_id_seq; Type: SEQUENCE; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE perseus.goo_process_queue_type ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME perseus.goo_process_queue_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: goo_type; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.goo_type (
    id integer NOT NULL,
    name public.citext NOT NULL,
    color public.citext,
    left_id integer NOT NULL,
    right_id integer NOT NULL,
    scope_id public.citext NOT NULL,
    disabled integer DEFAULT 0 NOT NULL,
    casrn public.citext,
    iupac public.citext,
    depth integer DEFAULT 0 NOT NULL,
    abbreviation public.citext,
    density_kg_l double precision
);


ALTER TABLE perseus.goo_type OWNER TO perseus_owner;

--
-- Name: goo_type_combine_component; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.goo_type_combine_component (
    id integer NOT NULL,
    goo_type_combine_target_id integer NOT NULL,
    goo_type_id integer NOT NULL
);


ALTER TABLE perseus.goo_type_combine_component OWNER TO perseus_owner;

--
-- Name: goo_type_combine_component_id_seq; Type: SEQUENCE; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE perseus.goo_type_combine_component ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME perseus.goo_type_combine_component_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: goo_type_combine_target; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.goo_type_combine_target (
    id integer NOT NULL,
    goo_type_id integer NOT NULL,
    sort_order integer NOT NULL
);


ALTER TABLE perseus.goo_type_combine_target OWNER TO perseus_owner;

--
-- Name: goo_type_combine_target_id_seq; Type: SEQUENCE; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE perseus.goo_type_combine_target ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME perseus.goo_type_combine_target_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: goo_type_id_seq; Type: SEQUENCE; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE perseus.goo_type ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME perseus.goo_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: hermes_run; Type: VIEW; Schema: perseus; Owner: perseus_owner
--

CREATE VIEW perseus.hermes_run AS
 SELECT r.experiment_id,
    r.local_id AS run_id,
    r.description,
    r.created_on,
    r.strain,
    r.max_yield AS yield,
    r.max_titer AS titer,
    rg.id AS result_goo_id,
    ig.id AS feedstock_goo_id,
    c.id AS container_id,
    r.start_time AS run_on,
    r.stop_time AS duration
   FROM (((hermes.run r
     LEFT JOIN perseus.goo rg ON ((('m'::text || rg.id) = (r.resultant_material)::text)))
     LEFT JOIN perseus.goo ig ON ((('m'::text || ig.id) = (r.feedstock_material)::text)))
     LEFT JOIN perseus.container c ON (((c.uid)::text = (r.tank)::text)))
  WHERE ((((COALESCE(r.feedstock_material, ''::character varying))::text <> ''::text) OR ((COALESCE(r.resultant_material, ''::character varying))::text <> ''::text)) AND ((COALESCE(r.feedstock_material, ''::character varying))::text <> (COALESCE(r.resultant_material, ''::character varying))::text));


ALTER VIEW perseus.hermes_run OWNER TO perseus_owner;

--
-- Name: history; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.history (
    id integer NOT NULL,
    history_type_id integer NOT NULL,
    creator_id integer NOT NULL,
    created_on timestamp without time zone DEFAULT LOCALTIMESTAMP NOT NULL
);


ALTER TABLE perseus.history OWNER TO perseus_owner;

--
-- Name: history_id_seq; Type: SEQUENCE; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE perseus.history ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME perseus.history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: history_type; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.history_type (
    id integer NOT NULL,
    name public.citext NOT NULL,
    format public.citext NOT NULL
);


ALTER TABLE perseus.history_type OWNER TO perseus_owner;

--
-- Name: history_type_id_seq; Type: SEQUENCE; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE perseus.history_type ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME perseus.history_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: history_value; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.history_value (
    id integer NOT NULL,
    history_id integer NOT NULL,
    value public.citext
);


ALTER TABLE perseus.history_value OWNER TO perseus_owner;

--
-- Name: history_value_id_seq; Type: SEQUENCE; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE perseus.history_value ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME perseus.history_value_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: m_downstream; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.m_downstream (
    start_point public.citext NOT NULL,
    end_point public.citext NOT NULL,
    path public.citext NOT NULL,
    level integer NOT NULL
);


ALTER TABLE perseus.m_downstream OWNER TO perseus_owner;

--
-- Name: m_number; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.m_number (
    id integer NOT NULL,
    md5_hash text NOT NULL
);


ALTER TABLE perseus.m_number OWNER TO perseus_owner;

--
-- Name: m_number_id_seq; Type: SEQUENCE; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE perseus.m_number ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME perseus.m_number_id_seq
    START WITH 900000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: m_upstream; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.m_upstream (
    start_point public.citext NOT NULL,
    end_point public.citext NOT NULL,
    path public.citext NOT NULL,
    level integer NOT NULL
);


ALTER TABLE perseus.m_upstream OWNER TO perseus_owner;

--
-- Name: m_upstream_dirty_leaves; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.m_upstream_dirty_leaves (
    material_uid public.citext NOT NULL,
    md5_hash text NOT NULL
);


ALTER TABLE perseus.m_upstream_dirty_leaves OWNER TO perseus_owner;

--
-- Name: manufacturer; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.manufacturer (
    id integer NOT NULL,
    name public.citext NOT NULL,
    location public.citext,
    goo_prefix public.citext
);


ALTER TABLE perseus.manufacturer OWNER TO perseus_owner;

--
-- Name: manufacturer_id_seq; Type: SEQUENCE; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE perseus.manufacturer ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME perseus.manufacturer_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: material_inventory; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.material_inventory (
    id integer NOT NULL,
    material_id integer NOT NULL,
    location_container_id integer NOT NULL,
    is_active boolean NOT NULL,
    current_volume_l real,
    current_mass_kg real,
    created_by_id integer NOT NULL,
    created_on timestamp without time zone,
    updated_by_id integer,
    updated_on timestamp without time zone,
    allocation_container_id integer,
    recipe_id integer,
    comment public.citext,
    expiration_date date,
    inventory_type_id integer NOT NULL
);


ALTER TABLE perseus.material_inventory OWNER TO perseus_owner;

--
-- Name: material_inventory_id_seq; Type: SEQUENCE; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE perseus.material_inventory ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME perseus.material_inventory_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: material_inventory_threshold; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.material_inventory_threshold (
    id integer NOT NULL,
    material_type_id integer NOT NULL,
    min_item_count integer,
    max_item_count integer,
    min_volume_l double precision,
    max_volume_l double precision,
    min_mass_kg double precision,
    max_mass_kg double precision,
    created_by_id integer NOT NULL,
    created_on timestamp without time zone DEFAULT LOCALTIMESTAMP NOT NULL,
    updated_by_id integer,
    updated_on timestamp without time zone,
    inventory_type_id integer NOT NULL
);


ALTER TABLE perseus.material_inventory_threshold OWNER TO perseus_owner;

--
-- Name: material_inventory_threshold_id_seq; Type: SEQUENCE; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE perseus.material_inventory_threshold ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME perseus.material_inventory_threshold_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: material_inventory_threshold_notify_user; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.material_inventory_threshold_notify_user (
    threshold_id integer NOT NULL,
    user_id integer NOT NULL
);


ALTER TABLE perseus.material_inventory_threshold_notify_user OWNER TO perseus_owner;

--
-- Name: material_inventory_type; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.material_inventory_type (
    id integer NOT NULL,
    name public.citext NOT NULL,
    description public.citext,
    is_active boolean DEFAULT true NOT NULL
);


ALTER TABLE perseus.material_inventory_type OWNER TO perseus_owner;

--
-- Name: material_inventory_type_id_seq; Type: SEQUENCE; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE perseus.material_inventory_type ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME perseus.material_inventory_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: material_qc; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.material_qc (
    id integer NOT NULL,
    material_id integer NOT NULL,
    entity_type_name public.citext NOT NULL,
    foreign_entity_id integer NOT NULL,
    qc_process_uid public.citext NOT NULL
);


ALTER TABLE perseus.material_qc OWNER TO perseus_owner;

--
-- Name: material_qc_id_seq; Type: SEQUENCE; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE perseus.material_qc ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME perseus.material_qc_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: material_transition_material; Type: VIEW; Schema: perseus; Owner: perseus_owner
--

CREATE VIEW perseus.material_transition_material AS
 SELECT source_material AS start_point,
    transition_id,
    destination_material AS end_point
   FROM perseus.translated;


ALTER VIEW perseus.material_transition_material OWNER TO perseus_owner;

--
-- Name: migration; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.migration (
    id integer NOT NULL,
    description public.citext NOT NULL,
    created_on timestamp without time zone DEFAULT LOCALTIMESTAMP NOT NULL
);


ALTER TABLE perseus.migration OWNER TO perseus_owner;

--
-- Name: permissions; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.permissions (
    emailaddress public.citext NOT NULL,
    permission public.citext NOT NULL,
    md5_hash text NOT NULL
);


ALTER TABLE perseus.permissions OWNER TO perseus_owner;

--
-- Name: perseus_user; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.perseus_user (
    id integer NOT NULL,
    name public.citext NOT NULL,
    domain_id public.citext,
    login public.citext,
    mail public.citext,
    admin boolean DEFAULT false NOT NULL,
    super boolean DEFAULT false NOT NULL,
    common_id integer,
    manufacturer_id integer DEFAULT 1 NOT NULL
);


ALTER TABLE perseus.perseus_user OWNER TO perseus_owner;

--
-- Name: perseus_user_id_seq; Type: SEQUENCE; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE perseus.perseus_user ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME perseus.perseus_user_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: person; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.person (
    id integer NOT NULL,
    domain_id public.citext NOT NULL,
    km_session_id public.citext,
    login public.citext NOT NULL,
    name public.citext NOT NULL,
    email public.citext,
    last_login timestamp without time zone,
    is_active boolean DEFAULT (1)::boolean NOT NULL
);


ALTER TABLE perseus.person OWNER TO perseus_owner;

--
-- Name: poll; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.poll (
    id integer NOT NULL,
    smurf_property_id integer NOT NULL,
    fatsmurf_reading_id integer NOT NULL,
    value public.citext,
    standard_deviation double precision,
    detection integer,
    limit_of_detection double precision,
    limit_of_quantification double precision,
    lower_calibration_limit double precision,
    upper_calibration_limit double precision,
    bounds_limit integer
);


ALTER TABLE perseus.poll OWNER TO perseus_owner;

--
-- Name: poll_history; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.poll_history (
    id integer NOT NULL,
    history_id integer NOT NULL,
    poll_id integer NOT NULL
);


ALTER TABLE perseus.poll_history OWNER TO perseus_owner;

--
-- Name: poll_history_id_seq; Type: SEQUENCE; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE perseus.poll_history ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME perseus.poll_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: poll_id_seq; Type: SEQUENCE; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE perseus.poll ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME perseus.poll_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: prefix_incrementor; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.prefix_incrementor (
    prefix public.citext NOT NULL,
    counter integer NOT NULL
);


ALTER TABLE perseus.prefix_incrementor OWNER TO perseus_owner;

--
-- Name: property_id_seq; Type: SEQUENCE; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE perseus.property ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME perseus.property_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: property_option_id_seq; Type: SEQUENCE; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE perseus.property_option ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME perseus.property_option_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: recipe; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.recipe (
    id integer NOT NULL,
    name public.citext NOT NULL,
    goo_type_id integer NOT NULL,
    description public.citext,
    sop public.citext,
    workflow_id integer,
    added_by integer NOT NULL,
    added_on timestamp without time zone NOT NULL,
    is_preferred boolean DEFAULT (0)::boolean NOT NULL,
    qc boolean DEFAULT (0)::boolean NOT NULL,
    is_archived boolean DEFAULT (0)::boolean NOT NULL,
    feed_type_id integer,
    stock_concentration double precision,
    sterilization_method public.citext,
    inoculant_percent double precision,
    post_inoc_volume_ml double precision
);


ALTER TABLE perseus.recipe OWNER TO perseus_owner;

--
-- Name: recipe_id_seq; Type: SEQUENCE; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE perseus.recipe ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME perseus.recipe_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: recipe_part; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.recipe_part (
    id integer NOT NULL,
    recipe_id integer NOT NULL,
    description public.citext,
    goo_type_id integer NOT NULL,
    amount double precision NOT NULL,
    unit_id integer NOT NULL,
    workflow_step_id integer,
    "position" integer,
    part_recipe_id integer,
    target_conc_in_media double precision,
    target_post_inoc_conc double precision
);


ALTER TABLE perseus.recipe_part OWNER TO perseus_owner;

--
-- Name: recipe_part_id_seq; Type: SEQUENCE; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE perseus.recipe_part ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME perseus.recipe_part_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: recipe_project_assignment; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.recipe_project_assignment (
    project_id smallint NOT NULL,
    recipe_id integer NOT NULL,
    md5_hash text NOT NULL
);


ALTER TABLE perseus.recipe_project_assignment OWNER TO perseus_owner;

--
-- Name: robot_log; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.robot_log (
    id integer NOT NULL,
    class_id integer NOT NULL,
    source public.citext,
    created_on timestamp without time zone DEFAULT LOCALTIMESTAMP NOT NULL,
    log_text public.citext NOT NULL,
    file_name public.citext,
    robot_log_checksum public.citext,
    started_on timestamp without time zone,
    completed_on timestamp without time zone,
    loaded_on timestamp without time zone,
    loaded integer DEFAULT 0 NOT NULL,
    loadable integer DEFAULT 0 NOT NULL,
    robot_run_id integer,
    robot_log_type_id integer NOT NULL
);


ALTER TABLE perseus.robot_log OWNER TO perseus_owner;

--
-- Name: robot_log_container_sequence; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.robot_log_container_sequence (
    id integer NOT NULL,
    robot_log_id integer NOT NULL,
    container_id integer NOT NULL,
    sequence_type_id integer NOT NULL,
    processed_on timestamp without time zone
);


ALTER TABLE perseus.robot_log_container_sequence OWNER TO perseus_owner;

--
-- Name: robot_log_container_sequence_id_seq; Type: SEQUENCE; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE perseus.robot_log_container_sequence ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME perseus.robot_log_container_sequence_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: robot_log_error; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.robot_log_error (
    id integer NOT NULL,
    robot_log_id integer NOT NULL,
    error_text public.citext NOT NULL
);


ALTER TABLE perseus.robot_log_error OWNER TO perseus_owner;

--
-- Name: robot_log_error_id_seq; Type: SEQUENCE; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE perseus.robot_log_error ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME perseus.robot_log_error_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: robot_log_id_seq; Type: SEQUENCE; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE perseus.robot_log ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME perseus.robot_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: robot_log_read; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.robot_log_read (
    id integer NOT NULL,
    robot_log_id integer NOT NULL,
    source_barcode public.citext NOT NULL,
    property_id integer NOT NULL,
    value public.citext,
    source_position public.citext,
    source_material_id integer
);


ALTER TABLE perseus.robot_log_read OWNER TO perseus_owner;

--
-- Name: robot_log_read_id_seq; Type: SEQUENCE; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE perseus.robot_log_read ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME perseus.robot_log_read_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: robot_log_transfer; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.robot_log_transfer (
    id integer NOT NULL,
    robot_log_id integer NOT NULL,
    source_barcode public.citext NOT NULL,
    destination_barcode public.citext NOT NULL,
    transfer_time timestamp without time zone,
    transfer_volume public.citext,
    source_position public.citext,
    destination_position public.citext,
    material_type_id integer,
    source_material_id integer,
    destination_material_id integer
);


ALTER TABLE perseus.robot_log_transfer OWNER TO perseus_owner;

--
-- Name: robot_log_transfer_id_seq; Type: SEQUENCE; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE perseus.robot_log_transfer ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME perseus.robot_log_transfer_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: robot_log_type; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.robot_log_type (
    id integer NOT NULL,
    name public.citext NOT NULL,
    auto_process integer NOT NULL,
    destination_container_type_id integer
);


ALTER TABLE perseus.robot_log_type OWNER TO perseus_owner;

--
-- Name: robot_log_type_id_seq; Type: SEQUENCE; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE perseus.robot_log_type ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME perseus.robot_log_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: robot_run; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.robot_run (
    id integer NOT NULL,
    robot_id integer,
    name public.citext NOT NULL,
    all_qc_passed boolean,
    all_themis_submitted boolean
);


ALTER TABLE perseus.robot_run OWNER TO perseus_owner;

--
-- Name: robot_run_id_seq; Type: SEQUENCE; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE perseus.robot_run ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME perseus.robot_run_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: s_number; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.s_number (
    id integer NOT NULL,
    md5_hash text NOT NULL
);


ALTER TABLE perseus.s_number OWNER TO perseus_owner;

--
-- Name: s_number_id_seq; Type: SEQUENCE; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE perseus.s_number ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME perseus.s_number_id_seq
    START WITH 1100000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: saved_search; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.saved_search (
    id integer NOT NULL,
    class_id integer,
    name public.citext NOT NULL,
    added_on timestamp without time zone DEFAULT LOCALTIMESTAMP NOT NULL,
    added_by integer NOT NULL,
    is_private integer DEFAULT 1 NOT NULL,
    include_downstream integer DEFAULT 0 NOT NULL,
    parameter_string public.citext NOT NULL
);


ALTER TABLE perseus.saved_search OWNER TO perseus_owner;

--
-- Name: saved_search_id_seq; Type: SEQUENCE; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE perseus.saved_search ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME perseus.saved_search_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: scraper; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.scraper (
    id integer NOT NULL,
    "timestamp" timestamp without time zone,
    message public.citext,
    filetype public.citext,
    filename public.citext,
    filenamesavedas public.citext,
    receivedfrom public.citext,
    file bytea,
    result public.citext,
    complete boolean,
    scraperid public.citext,
    scrapingstartedon timestamp without time zone,
    scrapingfinishedon timestamp without time zone,
    scrapingstatus public.citext,
    scrapersendto public.citext,
    scrapermessage public.citext,
    active public.citext,
    controlfileid integer,
    documentid public.citext
);


ALTER TABLE perseus.scraper OWNER TO perseus_owner;

--
-- Name: scraper_id_seq; Type: SEQUENCE; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE perseus.scraper ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME perseus.scraper_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: sequence_type; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.sequence_type (
    id integer NOT NULL,
    name public.citext NOT NULL
);


ALTER TABLE perseus.sequence_type OWNER TO perseus_owner;

--
-- Name: sequence_type_id_seq; Type: SEQUENCE; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE perseus.sequence_type ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME perseus.sequence_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: smurf_goo_type; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.smurf_goo_type (
    id integer NOT NULL,
    smurf_id integer NOT NULL,
    goo_type_id integer,
    is_input boolean DEFAULT false NOT NULL
);


ALTER TABLE perseus.smurf_goo_type OWNER TO perseus_owner;

--
-- Name: smurf_goo_type_id_seq; Type: SEQUENCE; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE perseus.smurf_goo_type ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME perseus.smurf_goo_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: smurf_group; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.smurf_group (
    id integer NOT NULL,
    name public.citext NOT NULL,
    added_by integer NOT NULL,
    is_public boolean DEFAULT false NOT NULL
);


ALTER TABLE perseus.smurf_group OWNER TO perseus_owner;

--
-- Name: smurf_group_id_seq; Type: SEQUENCE; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE perseus.smurf_group ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME perseus.smurf_group_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: smurf_group_member; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.smurf_group_member (
    id integer NOT NULL,
    smurf_group_id integer NOT NULL,
    smurf_id integer NOT NULL
);


ALTER TABLE perseus.smurf_group_member OWNER TO perseus_owner;

--
-- Name: smurf_group_member_id_seq; Type: SEQUENCE; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE perseus.smurf_group_member ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME perseus.smurf_group_member_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: smurf_id_seq; Type: SEQUENCE; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE perseus.smurf ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME perseus.smurf_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: smurf_property_id_seq; Type: SEQUENCE; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE perseus.smurf_property ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME perseus.smurf_property_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: submission; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.submission (
    id integer NOT NULL,
    submitter_id integer NOT NULL,
    added_on timestamp without time zone NOT NULL,
    label public.citext
);


ALTER TABLE perseus.submission OWNER TO perseus_owner;

--
-- Name: submission_entry; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.submission_entry (
    id integer NOT NULL,
    assay_type_id integer NOT NULL,
    material_id integer NOT NULL,
    status character varying(19) NOT NULL,
    priority character varying(6) NOT NULL,
    submission_id integer NOT NULL,
    prepped_by_id integer,
    themis_tray_id integer,
    sample_type character varying(7) NOT NULL,
    CONSTRAINT ck__submissio__prior__7b3ee7aa CHECK ((((priority)::text = 'normal'::text) OR ((priority)::text = 'urgent'::text))),
    CONSTRAINT ck__submissio__sampl__4814495f CHECK ((((sample_type)::text = 'overlay'::text) OR ((sample_type)::text = 'broth'::text) OR ((sample_type)::text = 'pellet'::text) OR ((sample_type)::text = 'none'::text))),
    CONSTRAINT ck__submissio__statu__7a4ac371 CHECK ((((status)::text = 'prepped'::text) OR ((status)::text = 'submitted_to_themis'::text) OR ((status)::text = 'prepping'::text) OR ((status)::text = 'error'::text) OR ((status)::text = 'to_be_prepped'::text) OR ((status)::text = 'rejected'::text)))
);


ALTER TABLE perseus.submission_entry OWNER TO perseus_owner;

--
-- Name: submission_entry_id_seq; Type: SEQUENCE; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE perseus.submission_entry ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME perseus.submission_entry_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: submission_id_seq; Type: SEQUENCE; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE perseus.submission ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME perseus.submission_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: tmp_messy_links; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.tmp_messy_links (
    source_transition public.citext NOT NULL,
    source_name public.citext,
    destination_transition public.citext NOT NULL,
    desitnation_name public.citext,
    material_id public.citext NOT NULL,
    md5_hash text NOT NULL
);


ALTER TABLE perseus.tmp_messy_links OWNER TO perseus_owner;

--
-- Name: unit_id_seq; Type: SEQUENCE; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE perseus.unit ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME perseus.unit_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: upstream; Type: VIEW; Schema: perseus; Owner: perseus_owner
--

CREATE VIEW perseus.upstream AS
 WITH RECURSIVE upstream AS (
         SELECT pt.destination_material AS start_point,
            pt.destination_material AS parent,
            pt.source_material AS child,
            '/'::text AS path,
            1 AS level
           FROM perseus.translated pt
        UNION ALL
         SELECT r.start_point,
            pt_0.destination_material,
            pt_0.source_material,
            ((r.path || (r.child)::text) || '/'::text),
            (r.level + 1)
           FROM (perseus.translated pt_0
             JOIN upstream r ON (((pt_0.destination_material)::text = (r.child)::text)))
          WHERE ((pt_0.destination_material)::text <> (pt_0.source_material)::text)
        )
 SELECT start_point,
    child AS end_point,
    path,
    level
   FROM upstream;


ALTER VIEW perseus.upstream OWNER TO perseus_owner;

--
-- Name: vw_process_upstream; Type: VIEW; Schema: perseus; Owner: perseus_owner
--

CREATE VIEW perseus.vw_process_upstream AS
 SELECT tm.transition_id AS source_process,
    mt.transition_id AS destination_process,
    fs.smurf_id AS source_process_type,
    fs2.smurf_id AS destination_process_type,
    mt.material_id AS connecting_material
   FROM (((perseus.material_transition mt
     JOIN perseus.transition_material tm ON (((tm.material_id)::text = (mt.material_id)::text)))
     JOIN perseus.fatsmurf fs ON (((mt.transition_id)::text = (fs.uid)::text)))
     JOIN perseus.fatsmurf fs2 ON (((tm.transition_id)::text = (fs2.uid)::text)));


ALTER VIEW perseus.vw_process_upstream OWNER TO perseus_owner;

--
-- Name: vw_fermentation_upstream; Type: VIEW; Schema: perseus; Owner: perseus_owner
--

CREATE VIEW perseus.vw_fermentation_upstream AS
 WITH RECURSIVE upstream AS (
         SELECT pt.destination_process AS start_point,
            pt.destination_process AS parent,
            pt.destination_process_type AS process_type,
            pt.source_process AS child,
            ('/'::text || (pt.destination_process)::text) AS path,
            1 AS level
           FROM perseus.vw_process_upstream pt
          WHERE (pt.source_process_type = 22)
        UNION ALL
         SELECT r.start_point,
            pt_0.destination_process,
            pt_0.destination_process_type AS process_type,
            pt_0.source_process,
                CASE
                    WHEN (pt_0.destination_process_type = 22) THEN ((r.path || '/'::text) || (pt_0.source_process)::text)
                    ELSE r.path
                END AS path,
                CASE
                    WHEN (pt_0.destination_process_type = 22) THEN (r.level + 1)
                    ELSE r.level
                END AS level
           FROM (perseus.vw_process_upstream pt_0
             JOIN upstream r ON (((pt_0.destination_process)::text = (r.child)::text)))
          WHERE ((pt_0.destination_process)::text <> (pt_0.source_process)::text)
        )
 SELECT start_point,
    child AS end_point,
    path,
    level
   FROM upstream
  WHERE (process_type = 22);


ALTER VIEW perseus.vw_fermentation_upstream OWNER TO perseus_owner;

--
-- Name: vw_lot; Type: VIEW; Schema: perseus; Owner: perseus_owner
--

CREATE VIEW perseus.vw_lot AS
 SELECT m.id,
    m.uid,
    m.name,
    m.description,
    m.goo_type_id AS material_type_id,
    p.id AS process_id,
    p.uid AS process_uid,
    p.name AS process_name,
    p.description AS process_description,
    p.smurf_id AS process_type_id,
    p.run_on,
    p.duration,
        CASE
            WHEN (p.container_id IS NOT NULL) THEN p.container_id
            ELSE m.container_id
        END AS container_id,
    m.original_volume,
    m.original_mass,
    m.triton_task_id,
    m.recipe_id,
    m.recipe_part_id,
        CASE
            WHEN (m.manufacturer_id IS NULL) THEN p.organization_id
            ELSE m.manufacturer_id
        END AS manufacturer_id,
    p.themis_sample_id,
    m.catalog_label,
    m.added_on AS created_on,
    m.added_by AS created_by_id
   FROM ((perseus.goo m
     LEFT JOIN perseus.transition_material tm ON (((tm.material_id)::text = (m.uid)::text)))
     LEFT JOIN perseus.fatsmurf p ON (((tm.transition_id)::text = (p.uid)::text)));


ALTER VIEW perseus.vw_lot OWNER TO perseus_owner;

--
-- Name: vw_lot_edge; Type: VIEW; Schema: perseus; Owner: perseus_owner
--

CREATE VIEW perseus.vw_lot_edge AS
 SELECT sl.id AS src_lot_id,
    dl.id AS dst_lot_id,
    mt.added_on AS created_on
   FROM ((perseus.material_transition mt
     JOIN perseus.vw_lot sl ON (((sl.uid)::text = (mt.material_id)::text)))
     JOIN perseus.vw_lot dl ON (((dl.process_uid)::text = (mt.transition_id)::text)));


ALTER VIEW perseus.vw_lot_edge OWNER TO perseus_owner;

--
-- Name: vw_lot_path; Type: VIEW; Schema: perseus; Owner: perseus_owner
--

CREATE VIEW perseus.vw_lot_path AS
 SELECT sl.id AS src_lot_id,
    dl.id AS dst_lot_id,
    mu.path,
    mu.level AS length
   FROM ((perseus.m_upstream mu
     JOIN perseus.vw_lot sl ON (((sl.uid)::text = (mu.end_point)::text)))
     JOIN perseus.vw_lot dl ON (((dl.uid)::text = (mu.start_point)::text)));


ALTER VIEW perseus.vw_lot_path OWNER TO perseus_owner;

--
-- Name: vw_material_transition_material_up; Type: VIEW; Schema: perseus; Owner: perseus_owner
--

CREATE VIEW perseus.vw_material_transition_material_up AS
 SELECT mt.material_id AS source_uid,
    tm.material_id AS destination_uid,
    tm.transition_id AS transition_uid
   FROM (perseus.transition_material tm
     LEFT JOIN perseus.material_transition mt ON (((tm.transition_id)::text = (mt.transition_id)::text)));


ALTER VIEW perseus.vw_material_transition_material_up OWNER TO perseus_owner;

--
-- Name: vw_recipe_prep; Type: VIEW; Schema: perseus; Owner: perseus_owner
--

CREATE VIEW perseus.vw_recipe_prep AS
 SELECT id,
    name,
    material_type_id,
    container_id,
    recipe_id,
    triton_task_id,
    original_volume AS volume_l,
    original_mass AS mass_kg,
    created_on,
    created_by_id
   FROM perseus.vw_lot prep
  WHERE ((recipe_id IS NOT NULL) AND (process_type_id = 207));


ALTER VIEW perseus.vw_recipe_prep OWNER TO perseus_owner;

--
-- Name: vw_recipe_prep_part; Type: VIEW; Schema: perseus; Owner: perseus_owner
--

CREATE VIEW perseus.vw_recipe_prep_part AS
 SELECT split.id,
    r.id AS recipe_id,
    rp.id AS recipe_part_id,
    prep.id AS prep_id,
    rp.goo_type_id AS expected_material_type_id,
    split.material_type_id AS actual_material_type_id,
    src.id AS source_lot_id,
    split.original_volume AS volume_l,
    split.original_mass AS mass_kg,
    split.created_on,
    split.created_by_id
   FROM ((((((perseus.vw_lot split
     JOIN perseus.vw_lot_edge split_to_prep ON ((split_to_prep.src_lot_id = split.id)))
     JOIN perseus.vw_lot prep ON ((prep.id = split_to_prep.dst_lot_id)))
     JOIN perseus.vw_lot_edge src_to_split ON ((src_to_split.dst_lot_id = split.id)))
     JOIN perseus.vw_lot src ON ((src.id = src_to_split.src_lot_id)))
     JOIN perseus.recipe r ON ((r.id = prep.recipe_id)))
     JOIN perseus.recipe_part rp ON (((rp.id = split.recipe_part_id) AND (r.id = rp.recipe_id))))
  WHERE ((split.recipe_part_id IS NOT NULL) AND (prep.recipe_id IS NOT NULL) AND (split.process_type_id = 110) AND (prep.process_type_id = 207));


ALTER VIEW perseus.vw_recipe_prep_part OWNER TO perseus_owner;

--
-- Name: vw_tom_perseus_sample_prep_materials; Type: VIEW; Schema: perseus; Owner: perseus_owner
--

CREATE VIEW perseus.vw_tom_perseus_sample_prep_materials AS
 SELECT ds.end_point AS material_id
   FROM (perseus.goo g
     JOIN perseus.m_downstream ds ON (((ds.start_point)::text = (g.uid)::text)))
  WHERE (g.goo_type_id = ANY (ARRAY[40, 62]))
UNION
 SELECT g_0.uid AS material_id
   FROM perseus.goo g_0
  WHERE (g_0.goo_type_id = ANY (ARRAY[40, 62]));


ALTER VIEW perseus.vw_tom_perseus_sample_prep_materials OWNER TO perseus_owner;

--
-- Name: workflow; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.workflow (
    id integer NOT NULL,
    name public.citext NOT NULL,
    added_on timestamp without time zone DEFAULT LOCALTIMESTAMP NOT NULL,
    added_by integer DEFAULT 23 NOT NULL,
    disabled integer DEFAULT 0 NOT NULL,
    manufacturer_id integer NOT NULL,
    description public.citext,
    category public.citext
);


ALTER TABLE perseus.workflow OWNER TO perseus_owner;

--
-- Name: workflow_attachment; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.workflow_attachment (
    id integer NOT NULL,
    workflow_id integer NOT NULL,
    added_on timestamp without time zone DEFAULT LOCALTIMESTAMP NOT NULL,
    added_by integer NOT NULL,
    attachment_name public.citext,
    attachment_mime_type public.citext,
    attachment bytea
);


ALTER TABLE perseus.workflow_attachment OWNER TO perseus_owner;

--
-- Name: workflow_attachment_id_seq; Type: SEQUENCE; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE perseus.workflow_attachment ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME perseus.workflow_attachment_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: workflow_id_seq; Type: SEQUENCE; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE perseus.workflow ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME perseus.workflow_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: workflow_section; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.workflow_section (
    id integer NOT NULL,
    workflow_id integer NOT NULL,
    name public.citext NOT NULL,
    starting_step_id integer NOT NULL
);


ALTER TABLE perseus.workflow_section OWNER TO perseus_owner;

--
-- Name: workflow_section_id_seq; Type: SEQUENCE; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE perseus.workflow_section ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME perseus.workflow_section_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: workflow_step; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.workflow_step (
    id integer NOT NULL,
    left_id integer,
    right_id integer,
    scope_id integer NOT NULL,
    class_id integer NOT NULL,
    name public.citext NOT NULL,
    smurf_id integer,
    goo_type_id integer,
    property_id integer,
    label public.citext,
    optional boolean DEFAULT false NOT NULL,
    goo_amount_unit_id integer DEFAULT 61,
    depth integer,
    description public.citext,
    recipe_factor double precision,
    parent_id integer,
    child_order integer
);


ALTER TABLE perseus.workflow_step OWNER TO perseus_owner;

--
-- Name: workflow_step_id_seq; Type: SEQUENCE; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE perseus.workflow_step ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME perseus.workflow_step_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: workflow_step_type; Type: TABLE; Schema: perseus; Owner: perseus_owner
--

CREATE TABLE perseus.workflow_step_type (
    id integer NOT NULL,
    name public.citext NOT NULL
);


ALTER TABLE perseus.workflow_step_type OWNER TO perseus_owner;

--
-- Name: alembic_version alembic_version_pkc; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.alembic_version
    ADD CONSTRAINT alembic_version_pkc PRIMARY KEY (version_num);


--
-- Name: coa coa_pk; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.coa
    ADD CONSTRAINT coa_pk PRIMARY KEY (id);


--
-- Name: coa_spec coa_spec_pk; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.coa_spec
    ADD CONSTRAINT coa_spec_pk PRIMARY KEY (id);


--
-- Name: field_map_display_type combined_field_map_display_type_pk; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.field_map_display_type
    ADD CONSTRAINT combined_field_map_display_type_pk PRIMARY KEY (id);


--
-- Name: field_map combined_field_map_pk; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.field_map
    ADD CONSTRAINT combined_field_map_pk PRIMARY KEY (id);


--
-- Name: container_history container_history_pk; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.container_history
    ADD CONSTRAINT container_history_pk PRIMARY KEY (id);


--
-- Name: container container_pk; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.container
    ADD CONSTRAINT container_pk PRIMARY KEY (id);


--
-- Name: container_type container_type_pk; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.container_type
    ADD CONSTRAINT container_type_pk PRIMARY KEY (id);


--
-- Name: container_type_position container_type_position_pk; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.container_type_position
    ADD CONSTRAINT container_type_position_pk PRIMARY KEY (id);


--
-- Name: display_layout display_layout_pk; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.display_layout
    ADD CONSTRAINT display_layout_pk PRIMARY KEY (id);


--
-- Name: display_type display_type_pk; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.display_type
    ADD CONSTRAINT display_type_pk PRIMARY KEY (id);


--
-- Name: external_goo_type external_goo_type_pk; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.external_goo_type
    ADD CONSTRAINT external_goo_type_pk PRIMARY KEY (id);


--
-- Name: fatsmurf_attachment fatsmurf_attachment_pk; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.fatsmurf_attachment
    ADD CONSTRAINT fatsmurf_attachment_pk PRIMARY KEY (id);


--
-- Name: fatsmurf_comment fatsmurf_comment_pk; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.fatsmurf_comment
    ADD CONSTRAINT fatsmurf_comment_pk PRIMARY KEY (id);


--
-- Name: fatsmurf_history fatsmurf_history_pk; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.fatsmurf_history
    ADD CONSTRAINT fatsmurf_history_pk PRIMARY KEY (id);


--
-- Name: fatsmurf fatsmurf_pk; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.fatsmurf
    ADD CONSTRAINT fatsmurf_pk PRIMARY KEY (id);


--
-- Name: fatsmurf_reading fatsmurf_reading_pk; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.fatsmurf_reading
    ADD CONSTRAINT fatsmurf_reading_pk PRIMARY KEY (id);


--
-- Name: field_map_block field_map_block_pk; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.field_map_block
    ADD CONSTRAINT field_map_block_pk PRIMARY KEY (id);


--
-- Name: field_map_display_type_user field_map_display_type_user_pk; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.field_map_display_type_user
    ADD CONSTRAINT field_map_display_type_user_pk PRIMARY KEY (id);


--
-- Name: field_map_set field_map_set_pk; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.field_map_set
    ADD CONSTRAINT field_map_set_pk PRIMARY KEY (id);


--
-- Name: field_map_type field_map_type_pk; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.field_map_type
    ADD CONSTRAINT field_map_type_pk PRIMARY KEY (id);


--
-- Name: goo_attachment goo_attachment_pk; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.goo_attachment
    ADD CONSTRAINT goo_attachment_pk PRIMARY KEY (id);


--
-- Name: goo_attachment_type goo_attachment_type_pk; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.goo_attachment_type
    ADD CONSTRAINT goo_attachment_type_pk PRIMARY KEY (id);


--
-- Name: goo_comment goo_comment_pk; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.goo_comment
    ADD CONSTRAINT goo_comment_pk PRIMARY KEY (id);


--
-- Name: goo_history goo_history_pk; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.goo_history
    ADD CONSTRAINT goo_history_pk PRIMARY KEY (id);


--
-- Name: goo goo_pk; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.goo
    ADD CONSTRAINT goo_pk PRIMARY KEY (id);


--
-- Name: goo_process_queue_type goo_process_queue_type_pk; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.goo_process_queue_type
    ADD CONSTRAINT goo_process_queue_type_pk PRIMARY KEY (id);


--
-- Name: goo_type_combine_component goo_type_combine_component_pk; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.goo_type_combine_component
    ADD CONSTRAINT goo_type_combine_component_pk PRIMARY KEY (id);


--
-- Name: goo_type_combine_target goo_type_combine_target_pk; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.goo_type_combine_target
    ADD CONSTRAINT goo_type_combine_target_pk PRIMARY KEY (id);


--
-- Name: goo_type goo_type_pk; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.goo_type
    ADD CONSTRAINT goo_type_pk PRIMARY KEY (id);


--
-- Name: history history_pk; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.history
    ADD CONSTRAINT history_pk PRIMARY KEY (id);


--
-- Name: history_type history_type_pk; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.history_type
    ADD CONSTRAINT history_type_pk PRIMARY KEY (id);


--
-- Name: history_value history_value_pk; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.history_value
    ADD CONSTRAINT history_value_pk PRIMARY KEY (id);


--
-- Name: m_downstream m_downstream_pk; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.m_downstream
    ADD CONSTRAINT m_downstream_pk PRIMARY KEY (start_point, end_point, path);


--
-- Name: m_upstream m_upstream_pk; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.m_upstream
    ADD CONSTRAINT m_upstream_pk PRIMARY KEY (start_point, end_point, path);


--
-- Name: manufacturer manufacturer_pk; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.manufacturer
    ADD CONSTRAINT manufacturer_pk PRIMARY KEY (id);


--
-- Name: m_number perseus_m_number_pk_md5_hash; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.m_number
    ADD CONSTRAINT perseus_m_number_pk_md5_hash PRIMARY KEY (md5_hash);


--
-- Name: m_upstream_dirty_leaves perseus_m_upstream_dirty_leaves_pk_md5_hash; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.m_upstream_dirty_leaves
    ADD CONSTRAINT perseus_m_upstream_dirty_leaves_pk_md5_hash PRIMARY KEY (md5_hash);


--
-- Name: permissions perseus_permissions_pk_md5_hash; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.permissions
    ADD CONSTRAINT perseus_permissions_pk_md5_hash PRIMARY KEY (md5_hash);


--
-- Name: recipe_project_assignment perseus_recipe_project_assignment_pk_md5_hash; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.recipe_project_assignment
    ADD CONSTRAINT perseus_recipe_project_assignment_pk_md5_hash PRIMARY KEY (md5_hash);


--
-- Name: s_number perseus_s_number_pk_md5_hash; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.s_number
    ADD CONSTRAINT perseus_s_number_pk_md5_hash PRIMARY KEY (md5_hash);


--
-- Name: tmp_messy_links perseus_tmp_messy_links_pk_md5_hash; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.tmp_messy_links
    ADD CONSTRAINT perseus_tmp_messy_links_pk_md5_hash PRIMARY KEY (md5_hash);


--
-- Name: perseus_user perseus_user_pk; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.perseus_user
    ADD CONSTRAINT perseus_user_pk PRIMARY KEY (id);


--
-- Name: feed_type pk__feed_typ__3213e83f16787987; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.feed_type
    ADD CONSTRAINT pk__feed_typ__3213e83f16787987 PRIMARY KEY (id);


--
-- Name: material_inventory pk__material__3213e83f77f9310a; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.material_inventory
    ADD CONSTRAINT pk__material__3213e83f77f9310a PRIMARY KEY (id);


--
-- Name: material_inventory_type pk__material__3213e83fbd077e43; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.material_inventory_type
    ADD CONSTRAINT pk__material__3213e83fbd077e43 PRIMARY KEY (id);


--
-- Name: material_qc pk__material__3213e83fe6b39cc1; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.material_qc
    ADD CONSTRAINT pk__material__3213e83fe6b39cc1 PRIMARY KEY (id);


--
-- Name: material_inventory_threshold pk__material__3213e83ff1f867f5; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.material_inventory_threshold
    ADD CONSTRAINT pk__material__3213e83ff1f867f5 PRIMARY KEY (id);


--
-- Name: material_transition pk__material__78fcfd7e69fee97b; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.material_transition
    ADD CONSTRAINT pk__material__78fcfd7e69fee97b PRIMARY KEY (material_id, transition_id);


--
-- Name: migration pk__migratio__3213e83f2405ca25; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.migration
    ADD CONSTRAINT pk__migratio__3213e83f2405ca25 PRIMARY KEY (id);


--
-- Name: person pk__person__3213e83f19aff6df; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.person
    ADD CONSTRAINT pk__person__3213e83f19aff6df PRIMARY KEY (id);


--
-- Name: recipe pk__recipe__3213e83f5d093d57; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.recipe
    ADD CONSTRAINT pk__recipe__3213e83f5d093d57 PRIMARY KEY (id);


--
-- Name: recipe_part pk__recipe_p__3213e83f696f143c; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.recipe_part
    ADD CONSTRAINT pk__recipe_p__3213e83f696f143c PRIMARY KEY (id);


--
-- Name: scraper pk__scraper__3214ec274c308081; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.scraper
    ADD CONSTRAINT pk__scraper__3214ec274c308081 PRIMARY KEY (id);


--
-- Name: submission pk__submissi__3213e83f71b57d70; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.submission
    ADD CONSTRAINT pk__submissi__3213e83f71b57d70 PRIMARY KEY (id);


--
-- Name: submission_entry pk__submissi__3213e83f767a328d; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.submission_entry
    ADD CONSTRAINT pk__submissi__3213e83f767a328d PRIMARY KEY (id);


--
-- Name: transition_material pk__transiti__a691e4b26dcf7a5f; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.transition_material
    ADD CONSTRAINT pk__transiti__a691e4b26dcf7a5f PRIMARY KEY (transition_id, material_id);


--
-- Name: cm_application pk_cm_application; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.cm_application
    ADD CONSTRAINT pk_cm_application PRIMARY KEY (application_id);


--
-- Name: cm_application_group pk_cm_application_group; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.cm_application_group
    ADD CONSTRAINT pk_cm_application_group PRIMARY KEY (application_group_id);


--
-- Name: cm_unit pk_cm_unit_1; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.cm_unit
    ADD CONSTRAINT pk_cm_unit_1 PRIMARY KEY (id);


--
-- Name: cm_unit_compare pk_cm_unit_compare; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.cm_unit_compare
    ADD CONSTRAINT pk_cm_unit_compare PRIMARY KEY (from_unit_id, to_unit_id);


--
-- Name: cm_unit_dimensions pk_cm_unit_dimensions; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.cm_unit_dimensions
    ADD CONSTRAINT pk_cm_unit_dimensions PRIMARY KEY (id);


--
-- Name: cm_user_group pk_cm_user_group; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.cm_user_group
    ADD CONSTRAINT pk_cm_user_group PRIMARY KEY (user_id, group_id);


--
-- Name: color pk_color; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.color
    ADD CONSTRAINT pk_color PRIMARY KEY (name);


--
-- Name: cm_group pk_group; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.cm_group
    ADD CONSTRAINT pk_group PRIMARY KEY (group_id);


--
-- Name: material_inventory_threshold_notify_user pk_material_inventory_threshold_notify_user; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.material_inventory_threshold_notify_user
    ADD CONSTRAINT pk_material_inventory_threshold_notify_user PRIMARY KEY (threshold_id, user_id);


--
-- Name: cm_project pk_project; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.cm_project
    ADD CONSTRAINT pk_project PRIMARY KEY (project_id);


--
-- Name: cm_user pk_user; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.cm_user
    ADD CONSTRAINT pk_user PRIMARY KEY (user_id);


--
-- Name: poll_history poll_history_pk; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.poll_history
    ADD CONSTRAINT poll_history_pk PRIMARY KEY (id);


--
-- Name: poll poll_pk; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.poll
    ADD CONSTRAINT poll_pk PRIMARY KEY (id);


--
-- Name: prefix_incrementor prefix_incrementor_pk; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.prefix_incrementor
    ADD CONSTRAINT prefix_incrementor_pk PRIMARY KEY (prefix);


--
-- Name: property_option property_option_pk; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.property_option
    ADD CONSTRAINT property_option_pk PRIMARY KEY (id);


--
-- Name: property property_pk; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.property
    ADD CONSTRAINT property_pk PRIMARY KEY (id);


--
-- Name: robot_log_container_sequence robot_log_container_sequence_pk; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.robot_log_container_sequence
    ADD CONSTRAINT robot_log_container_sequence_pk PRIMARY KEY (id);


--
-- Name: robot_log_error robot_log_error_pk; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.robot_log_error
    ADD CONSTRAINT robot_log_error_pk PRIMARY KEY (id);


--
-- Name: robot_log robot_log_pk; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.robot_log
    ADD CONSTRAINT robot_log_pk PRIMARY KEY (id);


--
-- Name: robot_log_read robot_log_read_pk; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.robot_log_read
    ADD CONSTRAINT robot_log_read_pk PRIMARY KEY (id);


--
-- Name: robot_log_transfer robot_log_transfer_pk; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.robot_log_transfer
    ADD CONSTRAINT robot_log_transfer_pk PRIMARY KEY (id);


--
-- Name: robot_log_type robot_log_type_pk; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.robot_log_type
    ADD CONSTRAINT robot_log_type_pk PRIMARY KEY (id);


--
-- Name: robot_run robot_run_pk; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.robot_run
    ADD CONSTRAINT robot_run_pk PRIMARY KEY (id);


--
-- Name: saved_search saved_search_pk; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.saved_search
    ADD CONSTRAINT saved_search_pk PRIMARY KEY (id);


--
-- Name: sequence_type sequence_type_pk; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.sequence_type
    ADD CONSTRAINT sequence_type_pk PRIMARY KEY (id);


--
-- Name: smurf_goo_type smurf_goo_type_pk; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.smurf_goo_type
    ADD CONSTRAINT smurf_goo_type_pk PRIMARY KEY (id);


--
-- Name: smurf_group_member smurf_group_member_pk; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.smurf_group_member
    ADD CONSTRAINT smurf_group_member_pk PRIMARY KEY (id);


--
-- Name: smurf_group smurf_group_pk; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.smurf_group
    ADD CONSTRAINT smurf_group_pk PRIMARY KEY (id);


--
-- Name: smurf smurf_pk; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.smurf
    ADD CONSTRAINT smurf_pk PRIMARY KEY (id);


--
-- Name: smurf_property smurf_property_pk; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.smurf_property
    ADD CONSTRAINT smurf_property_pk PRIMARY KEY (id);


--
-- Name: field_map_block uniq_fmb; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.field_map_block
    ADD CONSTRAINT uniq_fmb UNIQUE (filter, scope);


--
-- Name: unit unit_pk; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.unit
    ADD CONSTRAINT unit_pk PRIMARY KEY (id);


--
-- Name: coa uq__coa__a045441b2653caa4; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.coa
    ADD CONSTRAINT uq__coa__a045441b2653caa4 UNIQUE (name, goo_type_id);


--
-- Name: coa_spec uq__coa_spec__175eaf262c0ca3fa; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.coa_spec
    ADD CONSTRAINT uq__coa_spec__175eaf262c0ca3fa UNIQUE (coa_id, property_id);


--
-- Name: container_type_position uq__containe__32b36f0e29f6a937; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.container_type_position
    ADD CONSTRAINT uq__containe__32b36f0e29f6a937 UNIQUE (parent_container_type_id, position_name);


--
-- Name: container_type uq__containe__72e12f1b0ea330e9; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.container_type
    ADD CONSTRAINT uq__containe__72e12f1b0ea330e9 UNIQUE (name);


--
-- Name: display_type uq__display___72e12f1b1dfc19c0; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.display_type
    ADD CONSTRAINT uq__display___72e12f1b1dfc19c0 UNIQUE (name);


--
-- Name: display_layout uq__display___72e12f1b22c0cedd; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.display_layout
    ADD CONSTRAINT uq__display___72e12f1b22c0cedd UNIQUE (name);


--
-- Name: external_goo_type uq__external__3b82af230b9fd468; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.external_goo_type
    ADD CONSTRAINT uq__external__3b82af230b9fd468 UNIQUE (external_label, manufacturer_id);


--
-- Name: fatsmurf_reading uq__fatsmurf__0bc798795afc9d0d; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.fatsmurf_reading
    ADD CONSTRAINT uq__fatsmurf__0bc798795afc9d0d UNIQUE (name, fatsmurf_id);


--
-- Name: field_map_display_type_user uq__field_ma__49e1a26338b00ffc; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.field_map_display_type_user
    ADD CONSTRAINT uq__field_ma__49e1a26338b00ffc UNIQUE (user_id, field_map_display_type_id);


--
-- Name: field_map_type uq__field_ma__72e12f1b278583fa; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.field_map_type
    ADD CONSTRAINT uq__field_ma__72e12f1b278583fa UNIQUE (name);


--
-- Name: field_map_display_type uq__field_ma__f9589110301ac9fb; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.field_map_display_type
    ADD CONSTRAINT uq__field_ma__f9589110301ac9fb UNIQUE (field_map_id, display_type_id);


--
-- Name: goo_attachment_type uq__goo_atta__72e12f1b7a5d7005; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.goo_attachment_type
    ADD CONSTRAINT uq__goo_atta__72e12f1b7a5d7005 UNIQUE (name);


--
-- Name: goo_process_queue_type uq__goo_proc__72e12f1b5581bc68; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.goo_process_queue_type
    ADD CONSTRAINT uq__goo_proc__72e12f1b5581bc68 UNIQUE (name);


--
-- Name: goo_type_combine_component uq__goo_type__1a28c1a56fc0b158; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.goo_type_combine_component
    ADD CONSTRAINT uq__goo_type__1a28c1a56fc0b158 UNIQUE (goo_type_combine_target_id, goo_type_id);


--
-- Name: goo_type uq__goo_type__72a9f59b39237a9a; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.goo_type
    ADD CONSTRAINT uq__goo_type__72a9f59b39237a9a UNIQUE (left_id, right_id, scope_id);


--
-- Name: goo_type uq__goo_type__72e12f1b00551192; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.goo_type
    ADD CONSTRAINT uq__goo_type__72e12f1b00551192 UNIQUE (name);


--
-- Name: history_type uq__history___72e12f1b19b8e995; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.history_type
    ADD CONSTRAINT uq__history___72e12f1b19b8e995 UNIQUE (name);


--
-- Name: manufacturer uq__manufact__106262313de82fb7; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.manufacturer
    ADD CONSTRAINT uq__manufact__106262313de82fb7 UNIQUE (name, location);


--
-- Name: material_inventory uq__material__6bfe1d29c2c4ddab; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.material_inventory
    ADD CONSTRAINT uq__material__6bfe1d29c2c4ddab UNIQUE (material_id);


--
-- Name: material_inventory_type uq__material__72e12f1b3704ca3e; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.material_inventory_type
    ADD CONSTRAINT uq__material__72e12f1b3704ca3e UNIQUE (name);


--
-- Name: perseus_user uq__perseus___7838f2720519c6af; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.perseus_user
    ADD CONSTRAINT uq__perseus___7838f2720519c6af UNIQUE (login);


--
-- Name: perseus_user uq__perseus___e72bc76707f6335a; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.perseus_user
    ADD CONSTRAINT uq__perseus___e72bc76707f6335a UNIQUE (domain_id);


--
-- Name: poll uq__poll__2edadb146383c8ba; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.poll
    ADD CONSTRAINT uq__poll__2edadb146383c8ba UNIQUE (fatsmurf_reading_id, smurf_property_id);


--
-- Name: property uq__property__1fdbdaa62a4b4b5e; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.property
    ADD CONSTRAINT uq__property__1fdbdaa62a4b4b5e UNIQUE (name, unit_id);


--
-- Name: property_option uq__property__57d99bb95267570c; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.property_option
    ADD CONSTRAINT uq__property__57d99bb95267570c UNIQUE (property_id, label);


--
-- Name: property_option uq__property__d7501ac15543c3b7; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.property_option
    ADD CONSTRAINT uq__property__d7501ac15543c3b7 UNIQUE (property_id, value);


--
-- Name: recipe uq__recipe__72e12f1b5fe5aa02; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.recipe
    ADD CONSTRAINT uq__recipe__72e12f1b5fe5aa02 UNIQUE (name);


--
-- Name: recipe uq__recipe__72e12f1b62c216ad; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.recipe
    ADD CONSTRAINT uq__recipe__72e12f1b62c216ad UNIQUE (name);


--
-- Name: robot_log_type uq__robot_lo__72e12f1b1956f871; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.robot_log_type
    ADD CONSTRAINT uq__robot_lo__72e12f1b1956f871 UNIQUE (name);


--
-- Name: robot_log_container_sequence uq__robot_lo__acca81e32e521557; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.robot_log_container_sequence
    ADD CONSTRAINT uq__robot_lo__acca81e32e521557 UNIQUE (robot_log_id, container_id, sequence_type_id);


--
-- Name: saved_search uq__saved_se__a00062956a30c649; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.saved_search
    ADD CONSTRAINT uq__saved_se__a00062956a30c649 UNIQUE (name, added_by);


--
-- Name: smurf uq__smurf__72e12f1b300424b4; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.smurf
    ADD CONSTRAINT uq__smurf__72e12f1b300424b4 UNIQUE (name);


--
-- Name: smurf_group_member uq__smurf_gr__327439fa182cfeb7; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.smurf_group_member
    ADD CONSTRAINT uq__smurf_gr__327439fa182cfeb7 UNIQUE (smurf_group_id, smurf_id);


--
-- Name: smurf_group uq__smurf_gr__72e12f1b1368499a; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.smurf_group
    ADD CONSTRAINT uq__smurf_gr__72e12f1b1368499a UNIQUE (name);


--
-- Name: smurf_property uq__smurf_pr__92833c0b5be2a6f2; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.smurf_property
    ADD CONSTRAINT uq__smurf_pr__92833c0b5be2a6f2 UNIQUE (property_id, smurf_id);


--
-- Name: workflow uq__workflow__72e12f1b00cbdb56; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.workflow
    ADD CONSTRAINT uq__workflow__72e12f1b00cbdb56 UNIQUE (name);


--
-- Name: workflow_step_type uq__workflow__72e12f1b0b20e345; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.workflow_step_type
    ADD CONSTRAINT uq__workflow__72e12f1b0b20e345 UNIQUE (name);


--
-- Name: workflow_section uq__workflow__7533c67705909073; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.workflow_section
    ADD CONSTRAINT uq__workflow__7533c67705909073 UNIQUE (workflow_id, starting_step_id);


--
-- Name: workflow_section uq__workflow__d3897980086cfd1e; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.workflow_section
    ADD CONSTRAINT uq__workflow__d3897980086cfd1e UNIQUE (workflow_id, name);


--
-- Name: material_inventory_threshold uq_material_inventory_threshold_material_type_inventory_type; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.material_inventory_threshold
    ADD CONSTRAINT uq_material_inventory_threshold_material_type_inventory_type UNIQUE (material_type_id, inventory_type_id);


--
-- Name: person uq_person_domain_id; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.person
    ADD CONSTRAINT uq_person_domain_id UNIQUE (domain_id);


--
-- Name: workflow_attachment workflow_attachment_pk; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.workflow_attachment
    ADD CONSTRAINT workflow_attachment_pk PRIMARY KEY (id);


--
-- Name: workflow workflow_pk; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.workflow
    ADD CONSTRAINT workflow_pk PRIMARY KEY (id);


--
-- Name: workflow_section workflow_section_pk; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.workflow_section
    ADD CONSTRAINT workflow_section_pk PRIMARY KEY (id);


--
-- Name: workflow_step workflow_step_pk; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.workflow_step
    ADD CONSTRAINT workflow_step_pk PRIMARY KEY (id);


--
-- Name: workflow_step_type workflow_step_type_pk; Type: CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.workflow_step_type
    ADD CONSTRAINT workflow_step_type_pk PRIMARY KEY (id);


--
-- Name: idx_active; Type: INDEX; Schema: perseus; Owner: perseus_owner
--

CREATE INDEX idx_active ON perseus.scraper USING btree (active);


--
-- Name: ix_container_id; Type: INDEX; Schema: perseus; Owner: perseus_owner
--

CREATE INDEX ix_container_id ON perseus.robot_log_container_sequence USING btree (container_id);


--
-- Name: ix_container_scope_id_left_id_right_id_depth; Type: INDEX; Schema: perseus; Owner: perseus_owner
--

CREATE INDEX ix_container_scope_id_left_id_right_id_depth ON perseus.container USING btree (scope_id, left_id, right_id, depth);


--
-- Name: ix_container_type; Type: INDEX; Schema: perseus; Owner: perseus_owner
--

CREATE INDEX ix_container_type ON perseus.container USING btree (container_type_id) INCLUDE (id, mass);


--
-- Name: ix_fatsmurf_container_id; Type: INDEX; Schema: perseus; Owner: perseus_owner
--

CREATE INDEX ix_fatsmurf_container_id ON perseus.fatsmurf USING btree (container_id);


--
-- Name: ix_fatsmurf_id; Type: INDEX; Schema: perseus; Owner: perseus_owner
--

CREATE INDEX ix_fatsmurf_id ON perseus.fatsmurf_history USING btree (fatsmurf_id);


--
-- Name: ix_fatsmurf_recipe_id; Type: INDEX; Schema: perseus; Owner: perseus_owner
--

CREATE INDEX ix_fatsmurf_recipe_id ON perseus.fatsmurf USING btree (smurf_id);


--
-- Name: ix_fatsmurf_smurf_id; Type: INDEX; Schema: perseus; Owner: perseus_owner
--

CREATE INDEX ix_fatsmurf_smurf_id ON perseus.fatsmurf USING btree (smurf_id);


--
-- Name: ix_fsr_for_istd_view; Type: INDEX; Schema: perseus; Owner: perseus_owner
--

CREATE INDEX ix_fsr_for_istd_view ON perseus.fatsmurf_reading USING btree (fatsmurf_id) INCLUDE (id);


--
-- Name: ix_goo_added_on; Type: INDEX; Schema: perseus; Owner: perseus_owner
--

CREATE INDEX ix_goo_added_on ON perseus.goo USING btree (added_on) INCLUDE (uid, container_id);


--
-- Name: ix_goo_container_id; Type: INDEX; Schema: perseus; Owner: perseus_owner
--

CREATE INDEX ix_goo_container_id ON perseus.goo USING btree (container_id);


--
-- Name: ix_goo_id; Type: INDEX; Schema: perseus; Owner: perseus_owner
--

CREATE INDEX ix_goo_id ON perseus.goo_history USING btree (goo_id);


--
-- Name: ix_goo_recipe_id; Type: INDEX; Schema: perseus; Owner: perseus_owner
--

CREATE INDEX ix_goo_recipe_id ON perseus.goo USING btree (recipe_id);


--
-- Name: ix_goo_recipe_part_id; Type: INDEX; Schema: perseus; Owner: perseus_owner
--

CREATE INDEX ix_goo_recipe_part_id ON perseus.goo USING btree (recipe_part_id);


--
-- Name: ix_history_id; Type: INDEX; Schema: perseus; Owner: perseus_owner
--

CREATE INDEX ix_history_id ON perseus.poll_history USING btree (poll_id) INCLUDE (history_id);


--
-- Name: ix_history_id_value; Type: INDEX; Schema: perseus; Owner: perseus_owner
--

CREATE INDEX ix_history_id_value ON perseus.history_value USING btree (history_id);


--
-- Name: ix_material_inventory_inventory_type_id; Type: INDEX; Schema: perseus; Owner: perseus_owner
--

CREATE INDEX ix_material_inventory_inventory_type_id ON perseus.material_inventory USING btree (inventory_type_id);


--
-- Name: ix_material_inventory_threshold_inventory_type_id; Type: INDEX; Schema: perseus; Owner: perseus_owner
--

CREATE INDEX ix_material_inventory_threshold_inventory_type_id ON perseus.material_inventory_threshold USING btree (inventory_type_id);


--
-- Name: ix_material_inventory_threshold_material_type_id; Type: INDEX; Schema: perseus; Owner: perseus_owner
--

CREATE INDEX ix_material_inventory_threshold_material_type_id ON perseus.material_inventory_threshold USING btree (material_type_id);


--
-- Name: ix_material_transition_transition_id; Type: INDEX; Schema: perseus; Owner: perseus_owner
--

CREATE INDEX ix_material_transition_transition_id ON perseus.material_transition USING btree (transition_id);


--
-- Name: ix_person_km_session_id; Type: INDEX; Schema: perseus; Owner: perseus_owner
--

CREATE INDEX ix_person_km_session_id ON perseus.person USING btree (km_session_id);


--
-- Name: ix_recipe_goo_type_id; Type: INDEX; Schema: perseus; Owner: perseus_owner
--

CREATE INDEX ix_recipe_goo_type_id ON perseus.recipe USING btree (goo_type_id);


--
-- Name: ix_recipe_part_goo_type_id; Type: INDEX; Schema: perseus; Owner: perseus_owner
--

CREATE INDEX ix_recipe_part_goo_type_id ON perseus.recipe_part USING btree (goo_type_id);


--
-- Name: ix_recipe_part_recipe_id; Type: INDEX; Schema: perseus; Owner: perseus_owner
--

CREATE INDEX ix_recipe_part_recipe_id ON perseus.recipe_part USING btree (recipe_id);


--
-- Name: ix_recipe_part_unit_id; Type: INDEX; Schema: perseus; Owner: perseus_owner
--

CREATE INDEX ix_recipe_part_unit_id ON perseus.recipe_part USING btree (unit_id);


--
-- Name: ix_robot_log_read_robot_log_id; Type: INDEX; Schema: perseus; Owner: perseus_owner
--

CREATE INDEX ix_robot_log_read_robot_log_id ON perseus.robot_log_read USING btree (robot_log_id);


--
-- Name: ix_robot_log_robot_run_id; Type: INDEX; Schema: perseus; Owner: perseus_owner
--

CREATE INDEX ix_robot_log_robot_run_id ON perseus.robot_log USING btree (robot_run_id);


--
-- Name: ix_robot_log_transfer_robot_log_id; Type: INDEX; Schema: perseus; Owner: perseus_owner
--

CREATE INDEX ix_robot_log_transfer_robot_log_id ON perseus.robot_log_transfer USING btree (robot_log_id);


--
-- Name: ix_submission_added_on; Type: INDEX; Schema: perseus; Owner: perseus_owner
--

CREATE INDEX ix_submission_added_on ON perseus.submission USING btree (added_on);


--
-- Name: ix_themis_sample_id; Type: INDEX; Schema: perseus; Owner: perseus_owner
--

CREATE INDEX ix_themis_sample_id ON perseus.fatsmurf USING btree (themis_sample_id);


--
-- Name: ix_transition_material_material_id; Type: INDEX; Schema: perseus; Owner: perseus_owner
--

CREATE INDEX ix_transition_material_material_id ON perseus.transition_material USING btree (material_id);


--
-- Name: uix_unit_name; Type: INDEX; Schema: perseus; Owner: perseus_owner
--

CREATE UNIQUE INDEX uix_unit_name ON perseus.unit USING btree (name);


--
-- Name: uniq_container_uid; Type: INDEX; Schema: perseus; Owner: perseus_owner
--

CREATE UNIQUE INDEX uniq_container_uid ON perseus.container USING btree (uid);


--
-- Name: uniq_fs_uid; Type: INDEX; Schema: perseus; Owner: perseus_owner
--

CREATE UNIQUE INDEX uniq_fs_uid ON perseus.fatsmurf USING btree (uid);


--
-- Name: uniq_goo_uid; Type: INDEX; Schema: perseus; Owner: perseus_owner
--

CREATE UNIQUE INDEX uniq_goo_uid ON perseus.goo USING btree (uid);


--
-- Name: uniq_index; Type: INDEX; Schema: perseus; Owner: perseus_owner
--

CREATE UNIQUE INDEX uniq_index ON perseus.smurf_goo_type USING btree (smurf_id, goo_type_id, is_input);


--
-- Name: uniq_run_name; Type: INDEX; Schema: perseus; Owner: perseus_owner
--

CREATE UNIQUE INDEX uniq_run_name ON perseus.robot_run USING btree (name);


--
-- Name: uniq_starting_step; Type: INDEX; Schema: perseus; Owner: perseus_owner
--

CREATE UNIQUE INDEX uniq_starting_step ON perseus.workflow_section USING btree (starting_step_id);


--
-- Name: fatsmurf trg_fatsmurfupdatedon; Type: TRIGGER; Schema: perseus; Owner: perseus_owner
--

CREATE TRIGGER trg_fatsmurfupdatedon AFTER UPDATE ON perseus.fatsmurf REFERENCING NEW TABLE AS inserted FOR EACH STATEMENT EXECUTE FUNCTION perseus.trg_fatsmurfupdatedon();


--
-- Name: goo trg_gooupdatedon; Type: TRIGGER; Schema: perseus; Owner: perseus_owner
--

CREATE TRIGGER trg_gooupdatedon AFTER UPDATE ON perseus.goo REFERENCING NEW TABLE AS inserted FOR EACH STATEMENT EXECUTE FUNCTION perseus.trg_gooupdatedon();


--
-- Name: transition_material validatetransitionmaterial; Type: TRIGGER; Schema: perseus; Owner: perseus_owner
--

CREATE TRIGGER validatetransitionmaterial AFTER INSERT ON perseus.transition_material REFERENCING NEW TABLE AS inserted FOR EACH STATEMENT EXECUTE FUNCTION perseus.validatetransitionmaterial();


--
-- Name: coa coa_fk_1; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.coa
    ADD CONSTRAINT coa_fk_1 FOREIGN KEY (goo_type_id) REFERENCES perseus.goo_type(id);


--
-- Name: coa_spec coa_spec_fk_1; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.coa_spec
    ADD CONSTRAINT coa_spec_fk_1 FOREIGN KEY (coa_id) REFERENCES perseus.coa(id);


--
-- Name: coa_spec coa_spec_fk_2; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.coa_spec
    ADD CONSTRAINT coa_spec_fk_2 FOREIGN KEY (property_id) REFERENCES perseus.property(id);


--
-- Name: field_map_display_type combined_field_map_display_type_fk_1; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.field_map_display_type
    ADD CONSTRAINT combined_field_map_display_type_fk_1 FOREIGN KEY (field_map_id) REFERENCES perseus.field_map(id) ON DELETE CASCADE;


--
-- Name: field_map_display_type combined_field_map_display_type_fk_2; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.field_map_display_type
    ADD CONSTRAINT combined_field_map_display_type_fk_2 FOREIGN KEY (display_type_id) REFERENCES perseus.display_type(id) ON DELETE CASCADE;


--
-- Name: field_map_display_type combined_field_map_display_type_fk_3; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.field_map_display_type
    ADD CONSTRAINT combined_field_map_display_type_fk_3 FOREIGN KEY (display_layout_id) REFERENCES perseus.display_layout(id) ON DELETE CASCADE;


--
-- Name: field_map combined_field_map_fk_1; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.field_map
    ADD CONSTRAINT combined_field_map_fk_1 FOREIGN KEY (field_map_block_id) REFERENCES perseus.field_map_block(id);


--
-- Name: field_map combined_field_map_fk_2; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.field_map
    ADD CONSTRAINT combined_field_map_fk_2 FOREIGN KEY (field_map_type_id) REFERENCES perseus.field_map_type(id);


--
-- Name: container container_fk_1; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.container
    ADD CONSTRAINT container_fk_1 FOREIGN KEY (container_type_id) REFERENCES perseus.container_type(id);


--
-- Name: container_history container_history_fk_1; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.container_history
    ADD CONSTRAINT container_history_fk_1 FOREIGN KEY (history_id) REFERENCES perseus.history(id) ON DELETE CASCADE;


--
-- Name: container_history container_history_fk_2; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.container_history
    ADD CONSTRAINT container_history_fk_2 FOREIGN KEY (container_id) REFERENCES perseus.container(id) ON DELETE CASCADE;


--
-- Name: goo container_id_fk_1; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.goo
    ADD CONSTRAINT container_id_fk_1 FOREIGN KEY (container_id) REFERENCES perseus.container(id) ON DELETE SET NULL;


--
-- Name: container_type_position container_type_position_fk_1; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.container_type_position
    ADD CONSTRAINT container_type_position_fk_1 FOREIGN KEY (parent_container_type_id) REFERENCES perseus.container_type(id);


--
-- Name: container_type_position container_type_position_fk_2; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.container_type_position
    ADD CONSTRAINT container_type_position_fk_2 FOREIGN KEY (child_container_type_id) REFERENCES perseus.container_type(id);


--
-- Name: fatsmurf_reading creator_fk_1; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.fatsmurf_reading
    ADD CONSTRAINT creator_fk_1 FOREIGN KEY (added_by) REFERENCES perseus.perseus_user(id);


--
-- Name: external_goo_type external_goo_type_fk_1; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.external_goo_type
    ADD CONSTRAINT external_goo_type_fk_1 FOREIGN KEY (goo_type_id) REFERENCES perseus.goo_type(id);


--
-- Name: external_goo_type external_goo_type_fk_2; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.external_goo_type
    ADD CONSTRAINT external_goo_type_fk_2 FOREIGN KEY (manufacturer_id) REFERENCES perseus.manufacturer(id);


--
-- Name: fatsmurf_attachment fatsmurf_attachment_fk_1; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.fatsmurf_attachment
    ADD CONSTRAINT fatsmurf_attachment_fk_1 FOREIGN KEY (added_by) REFERENCES perseus.perseus_user(id);


--
-- Name: fatsmurf_attachment fatsmurf_attachment_fk_2; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.fatsmurf_attachment
    ADD CONSTRAINT fatsmurf_attachment_fk_2 FOREIGN KEY (fatsmurf_id) REFERENCES perseus.fatsmurf(id) ON DELETE CASCADE;


--
-- Name: fatsmurf_comment fatsmurf_comment_fk_1; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.fatsmurf_comment
    ADD CONSTRAINT fatsmurf_comment_fk_1 FOREIGN KEY (added_by) REFERENCES perseus.perseus_user(id);


--
-- Name: fatsmurf_comment fatsmurf_comment_fk_2; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.fatsmurf_comment
    ADD CONSTRAINT fatsmurf_comment_fk_2 FOREIGN KEY (fatsmurf_id) REFERENCES perseus.fatsmurf(id) ON DELETE CASCADE;


--
-- Name: fatsmurf_history fatsmurf_history_fk_1; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.fatsmurf_history
    ADD CONSTRAINT fatsmurf_history_fk_1 FOREIGN KEY (history_id) REFERENCES perseus.history(id) ON DELETE CASCADE;


--
-- Name: fatsmurf_history fatsmurf_history_fk_2; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.fatsmurf_history
    ADD CONSTRAINT fatsmurf_history_fk_2 FOREIGN KEY (fatsmurf_id) REFERENCES perseus.fatsmurf(id) ON DELETE CASCADE;


--
-- Name: fatsmurf_reading fatsmurf_reading_fk_1; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.fatsmurf_reading
    ADD CONSTRAINT fatsmurf_reading_fk_1 FOREIGN KEY (fatsmurf_id) REFERENCES perseus.fatsmurf(id) ON DELETE CASCADE;


--
-- Name: field_map_display_type_user field_map_display_type_user_fk_2; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.field_map_display_type_user
    ADD CONSTRAINT field_map_display_type_user_fk_2 FOREIGN KEY (user_id) REFERENCES perseus.perseus_user(id) ON DELETE CASCADE;


--
-- Name: field_map field_map_field_map_set_fk_1; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.field_map
    ADD CONSTRAINT field_map_field_map_set_fk_1 FOREIGN KEY (field_map_set_id) REFERENCES perseus.field_map_set(id);


--
-- Name: feed_type fk__feed_type__creat__5f28586b; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.feed_type
    ADD CONSTRAINT fk__feed_type__creat__5f28586b FOREIGN KEY (added_by) REFERENCES perseus.perseus_user(id);


--
-- Name: feed_type fk__feed_type__updat__601c7ca4; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.feed_type
    ADD CONSTRAINT fk__feed_type__updat__601c7ca4 FOREIGN KEY (updated_by_id) REFERENCES perseus.perseus_user(id);


--
-- Name: material_inventory fk__material___alloc__1642b7d4; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.material_inventory
    ADD CONSTRAINT fk__material___alloc__1642b7d4 FOREIGN KEY (allocation_container_id) REFERENCES perseus.container(id);


--
-- Name: material_inventory fk__material___creat__1a1348b8; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.material_inventory
    ADD CONSTRAINT fk__material___creat__1a1348b8 FOREIGN KEY (created_by_id) REFERENCES perseus.perseus_user(id);


--
-- Name: material_inventory fk__material___locat__191f247f; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.material_inventory
    ADD CONSTRAINT fk__material___locat__191f247f FOREIGN KEY (location_container_id) REFERENCES perseus.container(id);


--
-- Name: material_inventory fk__material___mater__182b0046; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.material_inventory
    ADD CONSTRAINT fk__material___mater__182b0046 FOREIGN KEY (material_id) REFERENCES perseus.goo(id);


--
-- Name: material_qc fk__material___mater__5b988a00; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.material_qc
    ADD CONSTRAINT fk__material___mater__5b988a00 FOREIGN KEY (material_id) REFERENCES perseus.goo(id);


--
-- Name: material_inventory fk__material___recip__1736dc0d; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.material_inventory
    ADD CONSTRAINT fk__material___recip__1736dc0d FOREIGN KEY (recipe_id) REFERENCES perseus.recipe(id);


--
-- Name: material_inventory fk__material___updat__1b076cf1; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.material_inventory
    ADD CONSTRAINT fk__material___updat__1b076cf1 FOREIGN KEY (updated_by_id) REFERENCES perseus.perseus_user(id);


--
-- Name: perseus_user fk__perseus_u__manuf__5b3c942f; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.perseus_user
    ADD CONSTRAINT fk__perseus_u__manuf__5b3c942f FOREIGN KEY (manufacturer_id) REFERENCES perseus.manufacturer(id);


--
-- Name: perseus_user fk__perseus_u__manuf__5e1900da; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.perseus_user
    ADD CONSTRAINT fk__perseus_u__manuf__5e1900da FOREIGN KEY (manufacturer_id) REFERENCES perseus.manufacturer(id);


--
-- Name: perseus_user fk__perseus_u__manuf__6001494c; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.perseus_user
    ADD CONSTRAINT fk__perseus_u__manuf__6001494c FOREIGN KEY (manufacturer_id) REFERENCES perseus.manufacturer(id);


--
-- Name: recipe fk__recipe__added_by__659e8358; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.recipe
    ADD CONSTRAINT fk__recipe__added_by__659e8358 FOREIGN KEY (added_by) REFERENCES perseus.perseus_user(id);


--
-- Name: recipe fk__recipe__feed_typ__471bc4b0; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.recipe
    ADD CONSTRAINT fk__recipe__feed_typ__471bc4b0 FOREIGN KEY (feed_type_id) REFERENCES perseus.feed_type(id);


--
-- Name: recipe fk__recipe__goo_type__6692a791; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.recipe
    ADD CONSTRAINT fk__recipe__goo_type__6692a791 FOREIGN KEY (goo_type_id) REFERENCES perseus.goo_type(id);


--
-- Name: recipe fk__recipe__workflow__64aa5f1f; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.recipe
    ADD CONSTRAINT fk__recipe__workflow__64aa5f1f FOREIGN KEY (workflow_id) REFERENCES perseus.workflow(id);


--
-- Name: recipe_part fk__recipe_pa__goo_t__6e33c959; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.recipe_part
    ADD CONSTRAINT fk__recipe_pa__goo_t__6e33c959 FOREIGN KEY (goo_type_id) REFERENCES perseus.goo_type(id);


--
-- Name: recipe_part fk__recipe_pa__part___083eb140; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.recipe_part
    ADD CONSTRAINT fk__recipe_pa__part___083eb140 FOREIGN KEY (part_recipe_id) REFERENCES perseus.recipe(id);


--
-- Name: recipe_part fk__recipe_pa__recip__6d3fa520; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.recipe_part
    ADD CONSTRAINT fk__recipe_pa__recip__6d3fa520 FOREIGN KEY (recipe_id) REFERENCES perseus.recipe(id);


--
-- Name: recipe_part fk__recipe_pa__unit___6b575cae; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.recipe_part
    ADD CONSTRAINT fk__recipe_pa__unit___6b575cae FOREIGN KEY (unit_id) REFERENCES perseus.unit(id);


--
-- Name: recipe_part fk__recipe_pa__workf__6c4b80e7; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.recipe_part
    ADD CONSTRAINT fk__recipe_pa__workf__6c4b80e7 FOREIGN KEY (workflow_step_id) REFERENCES perseus.workflow_step(id);


--
-- Name: recipe_project_assignment fk__recipe_pr__recip__0d5f605d; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.recipe_project_assignment
    ADD CONSTRAINT fk__recipe_pr__recip__0d5f605d FOREIGN KEY (recipe_id) REFERENCES perseus.recipe(id);


--
-- Name: robot_log fk__robot_log__robot__01bf6602; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.robot_log
    ADD CONSTRAINT fk__robot_log__robot__01bf6602 FOREIGN KEY (robot_log_type_id) REFERENCES perseus.robot_log_type(id);


--
-- Name: submission_entry fk__submissio__assay__78627aff; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.submission_entry
    ADD CONSTRAINT fk__submissio__assay__78627aff FOREIGN KEY (assay_type_id) REFERENCES perseus.smurf(id);


--
-- Name: submission_entry fk__submissio__mater__79569f38; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.submission_entry
    ADD CONSTRAINT fk__submissio__mater__79569f38 FOREIGN KEY (material_id) REFERENCES perseus.goo(id);


--
-- Name: submission_entry fk__submissio__prepp__7d27301c; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.submission_entry
    ADD CONSTRAINT fk__submissio__prepp__7d27301c FOREIGN KEY (prepped_by_id) REFERENCES perseus.perseus_user(id);


--
-- Name: submission fk__submissio__submi__739dc5e2; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.submission
    ADD CONSTRAINT fk__submissio__submi__739dc5e2 FOREIGN KEY (submitter_id) REFERENCES perseus.perseus_user(id);


--
-- Name: submission_entry fk__submissio__submi__7c330be3; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.submission_entry
    ADD CONSTRAINT fk__submissio__submi__7c330be3 FOREIGN KEY (submission_id) REFERENCES perseus.submission(id);


--
-- Name: fatsmurf fk_fatsmurf_smurf_id; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.fatsmurf
    ADD CONSTRAINT fk_fatsmurf_smurf_id FOREIGN KEY (smurf_id) REFERENCES perseus.smurf(id);


--
-- Name: fatsmurf fk_fatsmurf_workflow_step; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.fatsmurf
    ADD CONSTRAINT fk_fatsmurf_workflow_step FOREIGN KEY (workflow_step_id) REFERENCES perseus.workflow_step(id) ON DELETE SET NULL;


--
-- Name: goo fk_goo_recipe; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.goo
    ADD CONSTRAINT fk_goo_recipe FOREIGN KEY (recipe_id) REFERENCES perseus.recipe(id);


--
-- Name: goo fk_goo_recipe_part; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.goo
    ADD CONSTRAINT fk_goo_recipe_part FOREIGN KEY (recipe_part_id) REFERENCES perseus.recipe_part(id);


--
-- Name: goo fk_goo_workflow_step; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.goo
    ADD CONSTRAINT fk_goo_workflow_step FOREIGN KEY (workflow_step_id) REFERENCES perseus.workflow_step(id) ON DELETE SET NULL;


--
-- Name: material_inventory fk_material_inventory_inventory_type_id; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.material_inventory
    ADD CONSTRAINT fk_material_inventory_inventory_type_id FOREIGN KEY (inventory_type_id) REFERENCES perseus.material_inventory_type(id);


--
-- Name: material_inventory_threshold fk_material_inventory_threshold_created_by; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.material_inventory_threshold
    ADD CONSTRAINT fk_material_inventory_threshold_created_by FOREIGN KEY (created_by_id) REFERENCES perseus.perseus_user(id);


--
-- Name: material_inventory_threshold fk_material_inventory_threshold_inventory_type_id; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.material_inventory_threshold
    ADD CONSTRAINT fk_material_inventory_threshold_inventory_type_id FOREIGN KEY (inventory_type_id) REFERENCES perseus.material_inventory_type(id);


--
-- Name: material_inventory_threshold fk_material_inventory_threshold_material_type; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.material_inventory_threshold
    ADD CONSTRAINT fk_material_inventory_threshold_material_type FOREIGN KEY (material_type_id) REFERENCES perseus.goo_type(id);


--
-- Name: material_inventory_threshold fk_material_inventory_threshold_updated_by; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.material_inventory_threshold
    ADD CONSTRAINT fk_material_inventory_threshold_updated_by FOREIGN KEY (updated_by_id) REFERENCES perseus.perseus_user(id);


--
-- Name: material_transition fk_material_transition_fatsmurf; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.material_transition
    ADD CONSTRAINT fk_material_transition_fatsmurf FOREIGN KEY (transition_id) REFERENCES perseus.fatsmurf(uid) ON DELETE CASCADE;


--
-- Name: material_inventory_threshold_notify_user fk_mit_notify_user_threshold; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.material_inventory_threshold_notify_user
    ADD CONSTRAINT fk_mit_notify_user_threshold FOREIGN KEY (threshold_id) REFERENCES perseus.material_inventory_threshold(id) ON DELETE CASCADE;


--
-- Name: material_inventory_threshold_notify_user fk_mit_notify_user_user; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.material_inventory_threshold_notify_user
    ADD CONSTRAINT fk_mit_notify_user_user FOREIGN KEY (user_id) REFERENCES perseus.perseus_user(id);


--
-- Name: robot_log_read fk_robot_log_read_source_material_id; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.robot_log_read
    ADD CONSTRAINT fk_robot_log_read_source_material_id FOREIGN KEY (source_material_id) REFERENCES perseus.goo(id);


--
-- Name: robot_log_transfer fk_robot_log_transfer_destination_material_id; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.robot_log_transfer
    ADD CONSTRAINT fk_robot_log_transfer_destination_material_id FOREIGN KEY (destination_material_id) REFERENCES perseus.goo(id);


--
-- Name: robot_log_transfer fk_robot_log_transfer_source_material_id; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.robot_log_transfer
    ADD CONSTRAINT fk_robot_log_transfer_source_material_id FOREIGN KEY (source_material_id) REFERENCES perseus.goo(id);


--
-- Name: transition_material fk_transition_material_fatsmurf; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.transition_material
    ADD CONSTRAINT fk_transition_material_fatsmurf FOREIGN KEY (transition_id) REFERENCES perseus.fatsmurf(uid) ON DELETE CASCADE;


--
-- Name: transition_material fk_transition_material_goo; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.transition_material
    ADD CONSTRAINT fk_transition_material_goo FOREIGN KEY (material_id) REFERENCES perseus.goo(uid) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: workflow_step fk_workflow_step_goo_type; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.workflow_step
    ADD CONSTRAINT fk_workflow_step_goo_type FOREIGN KEY (goo_type_id) REFERENCES perseus.goo_type(id);


--
-- Name: workflow_step fk_workflow_step_property; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.workflow_step
    ADD CONSTRAINT fk_workflow_step_property FOREIGN KEY (property_id) REFERENCES perseus.property(id);


--
-- Name: workflow_step fk_workflow_step_smurf; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.workflow_step
    ADD CONSTRAINT fk_workflow_step_smurf FOREIGN KEY (smurf_id) REFERENCES perseus.smurf(id);


--
-- Name: workflow_step fk_workflow_step_workflow; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.workflow_step
    ADD CONSTRAINT fk_workflow_step_workflow FOREIGN KEY (scope_id) REFERENCES perseus.workflow(id) ON DELETE CASCADE;


--
-- Name: fatsmurf fs_container_id_fk_1; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.fatsmurf
    ADD CONSTRAINT fs_container_id_fk_1 FOREIGN KEY (container_id) REFERENCES perseus.container(id) ON DELETE SET NULL;


--
-- Name: fatsmurf fs_organization_fk_1; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.fatsmurf
    ADD CONSTRAINT fs_organization_fk_1 FOREIGN KEY (organization_id) REFERENCES perseus.manufacturer(id);


--
-- Name: goo_attachment goo_attachment_fk_1; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.goo_attachment
    ADD CONSTRAINT goo_attachment_fk_1 FOREIGN KEY (added_by) REFERENCES perseus.perseus_user(id);


--
-- Name: goo_attachment goo_attachment_fk_2; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.goo_attachment
    ADD CONSTRAINT goo_attachment_fk_2 FOREIGN KEY (goo_id) REFERENCES perseus.goo(id) ON DELETE CASCADE;


--
-- Name: goo_attachment goo_attachment_fk_3; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.goo_attachment
    ADD CONSTRAINT goo_attachment_fk_3 FOREIGN KEY (goo_attachment_type_id) REFERENCES perseus.goo_attachment_type(id);


--
-- Name: goo_comment goo_comment_fk_1; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.goo_comment
    ADD CONSTRAINT goo_comment_fk_1 FOREIGN KEY (added_by) REFERENCES perseus.perseus_user(id);


--
-- Name: goo_comment goo_comment_fk_2; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.goo_comment
    ADD CONSTRAINT goo_comment_fk_2 FOREIGN KEY (goo_id) REFERENCES perseus.goo(id) ON DELETE CASCADE;


--
-- Name: goo goo_fk_1; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.goo
    ADD CONSTRAINT goo_fk_1 FOREIGN KEY (goo_type_id) REFERENCES perseus.goo_type(id);


--
-- Name: goo goo_fk_4; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.goo
    ADD CONSTRAINT goo_fk_4 FOREIGN KEY (added_by) REFERENCES perseus.perseus_user(id);


--
-- Name: goo_history goo_history_fk_1; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.goo_history
    ADD CONSTRAINT goo_history_fk_1 FOREIGN KEY (history_id) REFERENCES perseus.history(id) ON DELETE CASCADE;


--
-- Name: goo_history goo_history_fk_2; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.goo_history
    ADD CONSTRAINT goo_history_fk_2 FOREIGN KEY (goo_id) REFERENCES perseus.goo(id) ON DELETE CASCADE;


--
-- Name: goo_type_combine_component goo_type_combine_component_fk_1; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.goo_type_combine_component
    ADD CONSTRAINT goo_type_combine_component_fk_1 FOREIGN KEY (goo_type_id) REFERENCES perseus.goo_type(id);


--
-- Name: goo_type_combine_component goo_type_combine_component_fk_2; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.goo_type_combine_component
    ADD CONSTRAINT goo_type_combine_component_fk_2 FOREIGN KEY (goo_type_combine_target_id) REFERENCES perseus.goo_type_combine_target(id) ON DELETE CASCADE;


--
-- Name: goo_type_combine_target goo_type_combine_target_fk_1; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.goo_type_combine_target
    ADD CONSTRAINT goo_type_combine_target_fk_1 FOREIGN KEY (goo_type_id) REFERENCES perseus.goo_type(id);


--
-- Name: history history_fk_1; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.history
    ADD CONSTRAINT history_fk_1 FOREIGN KEY (creator_id) REFERENCES perseus.perseus_user(id);


--
-- Name: history history_fk_2; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.history
    ADD CONSTRAINT history_fk_2 FOREIGN KEY (history_type_id) REFERENCES perseus.history_type(id);


--
-- Name: history_value history_value_fk_1; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.history_value
    ADD CONSTRAINT history_value_fk_1 FOREIGN KEY (history_id) REFERENCES perseus.history(id) ON DELETE CASCADE;


--
-- Name: goo manufacturer_fk_1; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.goo
    ADD CONSTRAINT manufacturer_fk_1 FOREIGN KEY (manufacturer_id) REFERENCES perseus.manufacturer(id);


--
-- Name: poll poll_fatsmurf_reading_fk_1; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.poll
    ADD CONSTRAINT poll_fatsmurf_reading_fk_1 FOREIGN KEY (fatsmurf_reading_id) REFERENCES perseus.fatsmurf_reading(id) ON DELETE CASCADE;


--
-- Name: poll_history poll_history_fk_1; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.poll_history
    ADD CONSTRAINT poll_history_fk_1 FOREIGN KEY (history_id) REFERENCES perseus.history(id) ON DELETE CASCADE;


--
-- Name: poll_history poll_history_fk_2; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.poll_history
    ADD CONSTRAINT poll_history_fk_2 FOREIGN KEY (poll_id) REFERENCES perseus.poll(id) ON DELETE CASCADE;


--
-- Name: poll poll_smurf_property_fk_1; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.poll
    ADD CONSTRAINT poll_smurf_property_fk_1 FOREIGN KEY (smurf_property_id) REFERENCES perseus.smurf_property(id);


--
-- Name: property property_fk_1; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.property
    ADD CONSTRAINT property_fk_1 FOREIGN KEY (unit_id) REFERENCES perseus.unit(id);


--
-- Name: property_option property_option_fk_1; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.property_option
    ADD CONSTRAINT property_option_fk_1 FOREIGN KEY (property_id) REFERENCES perseus.property(id);


--
-- Name: robot_log_container_sequence robot_log_container_sequence_fk_1; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.robot_log_container_sequence
    ADD CONSTRAINT robot_log_container_sequence_fk_1 FOREIGN KEY (sequence_type_id) REFERENCES perseus.sequence_type(id) ON DELETE CASCADE;


--
-- Name: robot_log_container_sequence robot_log_container_sequence_fk_2; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.robot_log_container_sequence
    ADD CONSTRAINT robot_log_container_sequence_fk_2 FOREIGN KEY (container_id) REFERENCES perseus.container(id) ON DELETE CASCADE;


--
-- Name: robot_log_container_sequence robot_log_container_sequence_fk_3; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.robot_log_container_sequence
    ADD CONSTRAINT robot_log_container_sequence_fk_3 FOREIGN KEY (robot_log_id) REFERENCES perseus.robot_log(id) ON DELETE CASCADE;


--
-- Name: robot_log_error robot_log_error_fk_1; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.robot_log_error
    ADD CONSTRAINT robot_log_error_fk_1 FOREIGN KEY (robot_log_id) REFERENCES perseus.robot_log(id) ON DELETE CASCADE;


--
-- Name: robot_log robot_log_fk_1; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.robot_log
    ADD CONSTRAINT robot_log_fk_1 FOREIGN KEY (robot_run_id) REFERENCES perseus.robot_run(id);


--
-- Name: robot_log_read robot_log_read_fk_1; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.robot_log_read
    ADD CONSTRAINT robot_log_read_fk_1 FOREIGN KEY (robot_log_id) REFERENCES perseus.robot_log(id) ON DELETE CASCADE;


--
-- Name: robot_log_read robot_log_read_fk_2; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.robot_log_read
    ADD CONSTRAINT robot_log_read_fk_2 FOREIGN KEY (property_id) REFERENCES perseus.property(id) ON DELETE CASCADE;


--
-- Name: robot_log_transfer robot_log_transfer_fk_1; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.robot_log_transfer
    ADD CONSTRAINT robot_log_transfer_fk_1 FOREIGN KEY (robot_log_id) REFERENCES perseus.robot_log(id) ON DELETE CASCADE;


--
-- Name: robot_log_type robot_log_type_fk_1; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.robot_log_type
    ADD CONSTRAINT robot_log_type_fk_1 FOREIGN KEY (destination_container_type_id) REFERENCES perseus.container_type(id);


--
-- Name: robot_run robot_run_fk_2; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.robot_run
    ADD CONSTRAINT robot_run_fk_2 FOREIGN KEY (robot_id) REFERENCES perseus.container(id);


--
-- Name: saved_search saved_search_fk_1; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.saved_search
    ADD CONSTRAINT saved_search_fk_1 FOREIGN KEY (added_by) REFERENCES perseus.perseus_user(id);


--
-- Name: smurf_group sg_creator_fk_1; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.smurf_group
    ADD CONSTRAINT sg_creator_fk_1 FOREIGN KEY (added_by) REFERENCES perseus.perseus_user(id);


--
-- Name: smurf_goo_type smurf_goo_type_fk_1; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.smurf_goo_type
    ADD CONSTRAINT smurf_goo_type_fk_1 FOREIGN KEY (smurf_id) REFERENCES perseus.smurf(id);


--
-- Name: smurf_goo_type smurf_goo_type_fk_2; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.smurf_goo_type
    ADD CONSTRAINT smurf_goo_type_fk_2 FOREIGN KEY (goo_type_id) REFERENCES perseus.goo_type(id) ON DELETE CASCADE;


--
-- Name: smurf_group_member smurf_group_member_fk_1; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.smurf_group_member
    ADD CONSTRAINT smurf_group_member_fk_1 FOREIGN KEY (smurf_id) REFERENCES perseus.smurf(id) ON DELETE CASCADE;


--
-- Name: smurf_group_member smurf_group_member_fk_2; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.smurf_group_member
    ADD CONSTRAINT smurf_group_member_fk_2 FOREIGN KEY (smurf_group_id) REFERENCES perseus.smurf_group(id) ON DELETE CASCADE;


--
-- Name: smurf_property smurf_property_fk_1; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.smurf_property
    ADD CONSTRAINT smurf_property_fk_1 FOREIGN KEY (property_id) REFERENCES perseus.property(id) ON DELETE CASCADE;


--
-- Name: smurf_property smurf_property_fk_2; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.smurf_property
    ADD CONSTRAINT smurf_property_fk_2 FOREIGN KEY (smurf_id) REFERENCES perseus.smurf(id) ON DELETE CASCADE;


--
-- Name: workflow_attachment workflow_attachment_fk_1; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.workflow_attachment
    ADD CONSTRAINT workflow_attachment_fk_1 FOREIGN KEY (added_by) REFERENCES perseus.perseus_user(id);


--
-- Name: workflow_attachment workflow_attachment_fk_2; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.workflow_attachment
    ADD CONSTRAINT workflow_attachment_fk_2 FOREIGN KEY (workflow_id) REFERENCES perseus.workflow(id) ON DELETE CASCADE;


--
-- Name: workflow workflow_creator_fk_1; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.workflow
    ADD CONSTRAINT workflow_creator_fk_1 FOREIGN KEY (added_by) REFERENCES perseus.perseus_user(id);


--
-- Name: workflow workflow_manufacturer_id_fk_1; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.workflow
    ADD CONSTRAINT workflow_manufacturer_id_fk_1 FOREIGN KEY (manufacturer_id) REFERENCES perseus.manufacturer(id);


--
-- Name: workflow_section workflow_section_fk_1; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.workflow_section
    ADD CONSTRAINT workflow_section_fk_1 FOREIGN KEY (workflow_id) REFERENCES perseus.workflow(id) ON DELETE CASCADE;


--
-- Name: workflow_section workflow_step_start_fk_1; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.workflow_section
    ADD CONSTRAINT workflow_step_start_fk_1 FOREIGN KEY (starting_step_id) REFERENCES perseus.workflow_step(id);


--
-- Name: workflow_step workflow_step_unit_fk_1; Type: FK CONSTRAINT; Schema: perseus; Owner: perseus_owner
--

ALTER TABLE ONLY perseus.workflow_step
    ADD CONSTRAINT workflow_step_unit_fk_1 FOREIGN KEY (goo_amount_unit_id) REFERENCES perseus.unit(id);


--
-- Name: SCHEMA perseus; Type: ACL; Schema: -; Owner: perseus_owner
--

GRANT USAGE ON SCHEMA perseus TO perseus_read;
GRANT USAGE ON SCHEMA perseus TO perseus_user;
GRANT ALL ON SCHEMA perseus TO perseus_admin;


--
-- Name: PROCEDURE addarc(IN _materialuid character varying, IN _transitionuid character varying, IN _direction character varying); Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT ALL ON PROCEDURE perseus.addarc(IN _materialuid character varying, IN _transitionuid character varying, IN _direction character varying) TO perseus_read;
GRANT ALL ON PROCEDURE perseus.addarc(IN _materialuid character varying, IN _transitionuid character varying, IN _direction character varying) TO perseus_user;
GRANT ALL ON PROCEDURE perseus.addarc(IN _materialuid character varying, IN _transitionuid character varying, IN _direction character varying) TO perseus_admin;


--
-- Name: FUNCTION fn_diagramobjects(); Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT ALL ON FUNCTION perseus.fn_diagramobjects() TO perseus_admin;
GRANT ALL ON FUNCTION perseus.fn_diagramobjects() TO perseus_read;
GRANT ALL ON FUNCTION perseus.fn_diagramobjects() TO perseus_user;


--
-- Name: FUNCTION getexperiment(_hermesuid character varying); Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT ALL ON FUNCTION perseus.getexperiment(_hermesuid character varying) TO perseus_admin;
GRANT ALL ON FUNCTION perseus.getexperiment(_hermesuid character varying) TO perseus_read;
GRANT ALL ON FUNCTION perseus.getexperiment(_hermesuid character varying) TO perseus_user;


--
-- Name: FUNCTION gethermesexperiment(_hermesuid character varying); Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT ALL ON FUNCTION perseus.gethermesexperiment(_hermesuid character varying) TO perseus_admin;
GRANT ALL ON FUNCTION perseus.gethermesexperiment(_hermesuid character varying) TO perseus_read;
GRANT ALL ON FUNCTION perseus.gethermesexperiment(_hermesuid character varying) TO perseus_user;


--
-- Name: FUNCTION gethermesrun(_hermesuid character varying); Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT ALL ON FUNCTION perseus.gethermesrun(_hermesuid character varying) TO perseus_admin;
GRANT ALL ON FUNCTION perseus.gethermesrun(_hermesuid character varying) TO perseus_read;
GRANT ALL ON FUNCTION perseus.gethermesrun(_hermesuid character varying) TO perseus_user;


--
-- Name: FUNCTION gethermesuid(_experimentid integer, _runid integer); Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT ALL ON FUNCTION perseus.gethermesuid(_experimentid integer, _runid integer) TO perseus_admin;
GRANT ALL ON FUNCTION perseus.gethermesuid(_experimentid integer, _runid integer) TO perseus_read;
GRANT ALL ON FUNCTION perseus.gethermesuid(_experimentid integer, _runid integer) TO perseus_user;


--
-- Name: PROCEDURE getmaterialbyrunproperties(IN _runid character varying, IN _hourtimepoint numeric, INOUT return_value integer); Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT ALL ON PROCEDURE perseus.getmaterialbyrunproperties(IN _runid character varying, IN _hourtimepoint numeric, INOUT return_value integer) TO perseus_read;
GRANT ALL ON PROCEDURE perseus.getmaterialbyrunproperties(IN _runid character varying, IN _hourtimepoint numeric, INOUT return_value integer) TO perseus_user;
GRANT ALL ON PROCEDURE perseus.getmaterialbyrunproperties(IN _runid character varying, IN _hourtimepoint numeric, INOUT return_value integer) TO perseus_admin;


--
-- Name: PROCEDURE linkunlinkedmaterials(); Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT ALL ON PROCEDURE perseus.linkunlinkedmaterials() TO perseus_read;
GRANT ALL ON PROCEDURE perseus.linkunlinkedmaterials() TO perseus_user;
GRANT ALL ON PROCEDURE perseus.linkunlinkedmaterials() TO perseus_admin;


--
-- Name: PROCEDURE materialtotransition(IN _materialuid character varying, IN _transitionuid character varying); Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT ALL ON PROCEDURE perseus.materialtotransition(IN _materialuid character varying, IN _transitionuid character varying) TO perseus_read;
GRANT ALL ON PROCEDURE perseus.materialtotransition(IN _materialuid character varying, IN _transitionuid character varying) TO perseus_user;
GRANT ALL ON PROCEDURE perseus.materialtotransition(IN _materialuid character varying, IN _transitionuid character varying) TO perseus_admin;


--
-- Name: FUNCTION mcgetdownstream(p_starting_point perseus.goolist); Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT ALL ON FUNCTION perseus.mcgetdownstream(p_starting_point perseus.goolist) TO perseus_read;
GRANT ALL ON FUNCTION perseus.mcgetdownstream(p_starting_point perseus.goolist) TO perseus_user;
GRANT ALL ON FUNCTION perseus.mcgetdownstream(p_starting_point perseus.goolist) TO perseus_admin;


--
-- Name: FUNCTION mcgetdownstreambylist(p_starting_point perseus.goolist[]); Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT ALL ON FUNCTION perseus.mcgetdownstreambylist(p_starting_point perseus.goolist[]) TO perseus_read;
GRANT ALL ON FUNCTION perseus.mcgetdownstreambylist(p_starting_point perseus.goolist[]) TO perseus_user;
GRANT ALL ON FUNCTION perseus.mcgetdownstreambylist(p_starting_point perseus.goolist[]) TO perseus_admin;


--
-- Name: FUNCTION mcgetupstream(p_starting_point perseus.goolist); Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT ALL ON FUNCTION perseus.mcgetupstream(p_starting_point perseus.goolist) TO perseus_read;
GRANT ALL ON FUNCTION perseus.mcgetupstream(p_starting_point perseus.goolist) TO perseus_user;
GRANT ALL ON FUNCTION perseus.mcgetupstream(p_starting_point perseus.goolist) TO perseus_admin;


--
-- Name: FUNCTION mcgetupstreambylist(p_starting_point perseus.goolist[]); Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT ALL ON FUNCTION perseus.mcgetupstreambylist(p_starting_point perseus.goolist[]) TO perseus_read;
GRANT ALL ON FUNCTION perseus.mcgetupstreambylist(p_starting_point perseus.goolist[]) TO perseus_user;
GRANT ALL ON FUNCTION perseus.mcgetupstreambylist(p_starting_point perseus.goolist[]) TO perseus_admin;


--
-- Name: PROCEDURE processdirtytrees(IN par_dirty_in perseus.goolist[], IN par_clean_in perseus.goolist[]); Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT ALL ON PROCEDURE perseus.processdirtytrees(IN par_dirty_in perseus.goolist[], IN par_clean_in perseus.goolist[]) TO perseus_read;
GRANT ALL ON PROCEDURE perseus.processdirtytrees(IN par_dirty_in perseus.goolist[], IN par_clean_in perseus.goolist[]) TO perseus_user;
GRANT ALL ON PROCEDURE perseus.processdirtytrees(IN par_dirty_in perseus.goolist[], IN par_clean_in perseus.goolist[]) TO perseus_admin;


--
-- Name: FUNCTION processsomemupstream(par_dirty_in perseus.goolist[], par_clean_in perseus.goolist[]); Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT ALL ON FUNCTION perseus.processsomemupstream(par_dirty_in perseus.goolist[], par_clean_in perseus.goolist[]) TO perseus_read;
GRANT ALL ON FUNCTION perseus.processsomemupstream(par_dirty_in perseus.goolist[], par_clean_in perseus.goolist[]) TO perseus_user;
GRANT ALL ON FUNCTION perseus.processsomemupstream(par_dirty_in perseus.goolist[], par_clean_in perseus.goolist[]) TO perseus_admin;


--
-- Name: PROCEDURE processsomemupstream_gemini(IN _dirty_in perseus.goolist, IN _clean_in perseus.goolist, INOUT result_set_refcursor refcursor); Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT ALL ON PROCEDURE perseus.processsomemupstream_gemini(IN _dirty_in perseus.goolist, IN _clean_in perseus.goolist, INOUT result_set_refcursor refcursor) TO perseus_read;
GRANT ALL ON PROCEDURE perseus.processsomemupstream_gemini(IN _dirty_in perseus.goolist, IN _clean_in perseus.goolist, INOUT result_set_refcursor refcursor) TO perseus_user;
GRANT ALL ON PROCEDURE perseus.processsomemupstream_gemini(IN _dirty_in perseus.goolist, IN _clean_in perseus.goolist, INOUT result_set_refcursor refcursor) TO perseus_admin;


--
-- Name: PROCEDURE reconcilemupstream(); Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT ALL ON PROCEDURE perseus.reconcilemupstream() TO perseus_read;
GRANT ALL ON PROCEDURE perseus.reconcilemupstream() TO perseus_user;
GRANT ALL ON PROCEDURE perseus.reconcilemupstream() TO perseus_admin;


--
-- Name: PROCEDURE removearc(IN _materialuid character varying, IN _transitionuid character varying, IN _direction character varying); Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT ALL ON PROCEDURE perseus.removearc(IN _materialuid character varying, IN _transitionuid character varying, IN _direction character varying) TO perseus_read;
GRANT ALL ON PROCEDURE perseus.removearc(IN _materialuid character varying, IN _transitionuid character varying, IN _direction character varying) TO perseus_user;
GRANT ALL ON PROCEDURE perseus.removearc(IN _materialuid character varying, IN _transitionuid character varying, IN _direction character varying) TO perseus_admin;


--
-- Name: FUNCTION reversepath(_source character varying); Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT ALL ON FUNCTION perseus.reversepath(_source character varying) TO perseus_admin;
GRANT ALL ON FUNCTION perseus.reversepath(_source character varying) TO perseus_read;
GRANT ALL ON FUNCTION perseus.reversepath(_source character varying) TO perseus_user;


--
-- Name: FUNCTION rounddatetime(_inputdatetime timestamp without time zone); Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT ALL ON FUNCTION perseus.rounddatetime(_inputdatetime timestamp without time zone) TO perseus_admin;
GRANT ALL ON FUNCTION perseus.rounddatetime(_inputdatetime timestamp without time zone) TO perseus_read;
GRANT ALL ON FUNCTION perseus.rounddatetime(_inputdatetime timestamp without time zone) TO perseus_user;


--
-- Name: PROCEDURE sp_move_node(IN _myid integer, IN _parentid integer); Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT ALL ON PROCEDURE perseus.sp_move_node(IN _myid integer, IN _parentid integer) TO perseus_read;
GRANT ALL ON PROCEDURE perseus.sp_move_node(IN _myid integer, IN _parentid integer) TO perseus_user;
GRANT ALL ON PROCEDURE perseus.sp_move_node(IN _myid integer, IN _parentid integer) TO perseus_admin;


--
-- Name: PROCEDURE transitiontomaterial(IN _transitionuid character varying, IN _materialuid character varying); Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT ALL ON PROCEDURE perseus.transitiontomaterial(IN _transitionuid character varying, IN _materialuid character varying) TO perseus_read;
GRANT ALL ON PROCEDURE perseus.transitiontomaterial(IN _transitionuid character varying, IN _materialuid character varying) TO perseus_user;
GRANT ALL ON PROCEDURE perseus.transitiontomaterial(IN _transitionuid character varying, IN _materialuid character varying) TO perseus_admin;


--
-- Name: FUNCTION trg_fatsmurfupdatedon(); Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT ALL ON FUNCTION perseus.trg_fatsmurfupdatedon() TO perseus_admin;
GRANT ALL ON FUNCTION perseus.trg_fatsmurfupdatedon() TO perseus_read;
GRANT ALL ON FUNCTION perseus.trg_fatsmurfupdatedon() TO perseus_user;


--
-- Name: FUNCTION trg_gooupdatedon(); Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT ALL ON FUNCTION perseus.trg_gooupdatedon() TO perseus_admin;
GRANT ALL ON FUNCTION perseus.trg_gooupdatedon() TO perseus_read;
GRANT ALL ON FUNCTION perseus.trg_gooupdatedon() TO perseus_user;


--
-- Name: FUNCTION udf_datetrunc(_datein timestamp without time zone); Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT ALL ON FUNCTION perseus.udf_datetrunc(_datein timestamp without time zone) TO perseus_admin;
GRANT ALL ON FUNCTION perseus.udf_datetrunc(_datein timestamp without time zone) TO perseus_read;
GRANT ALL ON FUNCTION perseus.udf_datetrunc(_datein timestamp without time zone) TO perseus_user;


--
-- Name: PROCEDURE usp_updatemdownstream(); Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT ALL ON PROCEDURE perseus.usp_updatemdownstream() TO perseus_read;
GRANT ALL ON PROCEDURE perseus.usp_updatemdownstream() TO perseus_user;
GRANT ALL ON PROCEDURE perseus.usp_updatemdownstream() TO perseus_admin;


--
-- Name: PROCEDURE usp_updatemupstream(); Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT ALL ON PROCEDURE perseus.usp_updatemupstream() TO perseus_read;
GRANT ALL ON PROCEDURE perseus.usp_updatemupstream() TO perseus_user;
GRANT ALL ON PROCEDURE perseus.usp_updatemupstream() TO perseus_admin;


--
-- Name: FUNCTION validatetransitionmaterial(); Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT ALL ON FUNCTION perseus.validatetransitionmaterial() TO perseus_admin;
GRANT ALL ON FUNCTION perseus.validatetransitionmaterial() TO perseus_read;
GRANT ALL ON FUNCTION perseus.validatetransitionmaterial() TO perseus_user;


--
-- Name: TABLE alembic_version; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.alembic_version TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.alembic_version TO perseus_user;
GRANT ALL ON TABLE perseus.alembic_version TO perseus_admin;


--
-- Name: TABLE cm_application; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.cm_application TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.cm_application TO perseus_user;
GRANT ALL ON TABLE perseus.cm_application TO perseus_admin;


--
-- Name: TABLE cm_application_group; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.cm_application_group TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.cm_application_group TO perseus_user;
GRANT ALL ON TABLE perseus.cm_application_group TO perseus_admin;


--
-- Name: SEQUENCE cm_application_group_application_group_id_seq; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON SEQUENCE perseus.cm_application_group_application_group_id_seq TO perseus_read;
GRANT ALL ON SEQUENCE perseus.cm_application_group_application_group_id_seq TO perseus_user;
GRANT ALL ON SEQUENCE perseus.cm_application_group_application_group_id_seq TO perseus_admin;


--
-- Name: TABLE cm_group; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.cm_group TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.cm_group TO perseus_user;
GRANT ALL ON TABLE perseus.cm_group TO perseus_admin;


--
-- Name: SEQUENCE cm_group_group_id_seq; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON SEQUENCE perseus.cm_group_group_id_seq TO perseus_read;
GRANT ALL ON SEQUENCE perseus.cm_group_group_id_seq TO perseus_user;
GRANT ALL ON SEQUENCE perseus.cm_group_group_id_seq TO perseus_admin;


--
-- Name: TABLE cm_project; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.cm_project TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.cm_project TO perseus_user;
GRANT ALL ON TABLE perseus.cm_project TO perseus_admin;


--
-- Name: TABLE cm_unit; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.cm_unit TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.cm_unit TO perseus_user;
GRANT ALL ON TABLE perseus.cm_unit TO perseus_admin;


--
-- Name: TABLE cm_unit_compare; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.cm_unit_compare TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.cm_unit_compare TO perseus_user;
GRANT ALL ON TABLE perseus.cm_unit_compare TO perseus_admin;


--
-- Name: TABLE cm_unit_dimensions; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.cm_unit_dimensions TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.cm_unit_dimensions TO perseus_user;
GRANT ALL ON TABLE perseus.cm_unit_dimensions TO perseus_admin;


--
-- Name: TABLE cm_user; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.cm_user TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.cm_user TO perseus_user;
GRANT ALL ON TABLE perseus.cm_user TO perseus_admin;


--
-- Name: TABLE cm_user_group; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.cm_user_group TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.cm_user_group TO perseus_user;
GRANT ALL ON TABLE perseus.cm_user_group TO perseus_admin;


--
-- Name: SEQUENCE cm_user_user_id_seq; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON SEQUENCE perseus.cm_user_user_id_seq TO perseus_read;
GRANT ALL ON SEQUENCE perseus.cm_user_user_id_seq TO perseus_user;
GRANT ALL ON SEQUENCE perseus.cm_user_user_id_seq TO perseus_admin;


--
-- Name: TABLE coa; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.coa TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.coa TO perseus_user;
GRANT ALL ON TABLE perseus.coa TO perseus_admin;


--
-- Name: SEQUENCE coa_id_seq; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON SEQUENCE perseus.coa_id_seq TO perseus_read;
GRANT ALL ON SEQUENCE perseus.coa_id_seq TO perseus_user;
GRANT ALL ON SEQUENCE perseus.coa_id_seq TO perseus_admin;


--
-- Name: TABLE coa_spec; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.coa_spec TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.coa_spec TO perseus_user;
GRANT ALL ON TABLE perseus.coa_spec TO perseus_admin;


--
-- Name: SEQUENCE coa_spec_id_seq; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON SEQUENCE perseus.coa_spec_id_seq TO perseus_read;
GRANT ALL ON SEQUENCE perseus.coa_spec_id_seq TO perseus_user;
GRANT ALL ON SEQUENCE perseus.coa_spec_id_seq TO perseus_admin;


--
-- Name: TABLE color; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.color TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.color TO perseus_user;
GRANT ALL ON TABLE perseus.color TO perseus_admin;


--
-- Name: TABLE property; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.property TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.property TO perseus_user;
GRANT ALL ON TABLE perseus.property TO perseus_admin;


--
-- Name: TABLE property_option; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.property_option TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.property_option TO perseus_user;
GRANT ALL ON TABLE perseus.property_option TO perseus_admin;


--
-- Name: TABLE smurf; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.smurf TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.smurf TO perseus_user;
GRANT ALL ON TABLE perseus.smurf TO perseus_admin;


--
-- Name: TABLE smurf_property; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.smurf_property TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.smurf_property TO perseus_user;
GRANT ALL ON TABLE perseus.smurf_property TO perseus_admin;


--
-- Name: TABLE unit; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.unit TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.unit TO perseus_user;
GRANT ALL ON TABLE perseus.unit TO perseus_admin;


--
-- Name: TABLE combined_sp_field_map; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.combined_sp_field_map TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.combined_sp_field_map TO perseus_user;
GRANT ALL ON TABLE perseus.combined_sp_field_map TO perseus_admin;


--
-- Name: TABLE field_map; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.field_map TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.field_map TO perseus_user;
GRANT ALL ON TABLE perseus.field_map TO perseus_admin;


--
-- Name: TABLE combined_field_map; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.combined_field_map TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.combined_field_map TO perseus_user;
GRANT ALL ON TABLE perseus.combined_field_map TO perseus_admin;


--
-- Name: TABLE field_map_block; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.field_map_block TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.field_map_block TO perseus_user;
GRANT ALL ON TABLE perseus.field_map_block TO perseus_admin;


--
-- Name: TABLE combined_field_map_block; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.combined_field_map_block TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.combined_field_map_block TO perseus_user;
GRANT ALL ON TABLE perseus.combined_field_map_block TO perseus_admin;


--
-- Name: TABLE display_layout; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.display_layout TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.display_layout TO perseus_user;
GRANT ALL ON TABLE perseus.display_layout TO perseus_admin;


--
-- Name: TABLE combined_sp_field_map_display_type; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.combined_sp_field_map_display_type TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.combined_sp_field_map_display_type TO perseus_user;
GRANT ALL ON TABLE perseus.combined_sp_field_map_display_type TO perseus_admin;


--
-- Name: TABLE field_map_display_type; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.field_map_display_type TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.field_map_display_type TO perseus_user;
GRANT ALL ON TABLE perseus.field_map_display_type TO perseus_admin;


--
-- Name: TABLE combined_field_map_display_type; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.combined_field_map_display_type TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.combined_field_map_display_type TO perseus_user;
GRANT ALL ON TABLE perseus.combined_field_map_display_type TO perseus_admin;


--
-- Name: TABLE container; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.container TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.container TO perseus_user;
GRANT ALL ON TABLE perseus.container TO perseus_admin;


--
-- Name: TABLE container_history; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.container_history TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.container_history TO perseus_user;
GRANT ALL ON TABLE perseus.container_history TO perseus_admin;


--
-- Name: SEQUENCE container_history_id_seq; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON SEQUENCE perseus.container_history_id_seq TO perseus_read;
GRANT ALL ON SEQUENCE perseus.container_history_id_seq TO perseus_user;
GRANT ALL ON SEQUENCE perseus.container_history_id_seq TO perseus_admin;


--
-- Name: SEQUENCE container_id_seq; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON SEQUENCE perseus.container_id_seq TO perseus_read;
GRANT ALL ON SEQUENCE perseus.container_id_seq TO perseus_user;
GRANT ALL ON SEQUENCE perseus.container_id_seq TO perseus_admin;


--
-- Name: TABLE container_type; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.container_type TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.container_type TO perseus_user;
GRANT ALL ON TABLE perseus.container_type TO perseus_admin;


--
-- Name: SEQUENCE container_type_id_seq; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON SEQUENCE perseus.container_type_id_seq TO perseus_read;
GRANT ALL ON SEQUENCE perseus.container_type_id_seq TO perseus_user;
GRANT ALL ON SEQUENCE perseus.container_type_id_seq TO perseus_admin;


--
-- Name: TABLE container_type_position; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.container_type_position TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.container_type_position TO perseus_user;
GRANT ALL ON TABLE perseus.container_type_position TO perseus_admin;


--
-- Name: SEQUENCE container_type_position_id_seq; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON SEQUENCE perseus.container_type_position_id_seq TO perseus_read;
GRANT ALL ON SEQUENCE perseus.container_type_position_id_seq TO perseus_user;
GRANT ALL ON SEQUENCE perseus.container_type_position_id_seq TO perseus_admin;


--
-- Name: TABLE display_type; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.display_type TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.display_type TO perseus_user;
GRANT ALL ON TABLE perseus.display_type TO perseus_admin;


--
-- Name: TABLE material_transition; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.material_transition TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.material_transition TO perseus_user;
GRANT ALL ON TABLE perseus.material_transition TO perseus_admin;


--
-- Name: TABLE transition_material; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.transition_material TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.transition_material TO perseus_user;
GRANT ALL ON TABLE perseus.transition_material TO perseus_admin;


--
-- Name: TABLE translated; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.translated TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.translated TO perseus_user;
GRANT ALL ON TABLE perseus.translated TO perseus_admin;


--
-- Name: TABLE downstream; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.downstream TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.downstream TO perseus_user;
GRANT ALL ON TABLE perseus.downstream TO perseus_admin;


--
-- Name: TABLE external_goo_type; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.external_goo_type TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.external_goo_type TO perseus_user;
GRANT ALL ON TABLE perseus.external_goo_type TO perseus_admin;


--
-- Name: SEQUENCE external_goo_type_id_seq; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON SEQUENCE perseus.external_goo_type_id_seq TO perseus_read;
GRANT ALL ON SEQUENCE perseus.external_goo_type_id_seq TO perseus_user;
GRANT ALL ON SEQUENCE perseus.external_goo_type_id_seq TO perseus_admin;


--
-- Name: TABLE fatsmurf; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.fatsmurf TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.fatsmurf TO perseus_user;
GRANT ALL ON TABLE perseus.fatsmurf TO perseus_admin;


--
-- Name: TABLE fatsmurf_attachment; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.fatsmurf_attachment TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.fatsmurf_attachment TO perseus_user;
GRANT ALL ON TABLE perseus.fatsmurf_attachment TO perseus_admin;


--
-- Name: SEQUENCE fatsmurf_attachment_id_seq; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON SEQUENCE perseus.fatsmurf_attachment_id_seq TO perseus_read;
GRANT ALL ON SEQUENCE perseus.fatsmurf_attachment_id_seq TO perseus_user;
GRANT ALL ON SEQUENCE perseus.fatsmurf_attachment_id_seq TO perseus_admin;


--
-- Name: TABLE fatsmurf_comment; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.fatsmurf_comment TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.fatsmurf_comment TO perseus_user;
GRANT ALL ON TABLE perseus.fatsmurf_comment TO perseus_admin;


--
-- Name: SEQUENCE fatsmurf_comment_id_seq; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON SEQUENCE perseus.fatsmurf_comment_id_seq TO perseus_read;
GRANT ALL ON SEQUENCE perseus.fatsmurf_comment_id_seq TO perseus_user;
GRANT ALL ON SEQUENCE perseus.fatsmurf_comment_id_seq TO perseus_admin;


--
-- Name: TABLE fatsmurf_history; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.fatsmurf_history TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.fatsmurf_history TO perseus_user;
GRANT ALL ON TABLE perseus.fatsmurf_history TO perseus_admin;


--
-- Name: SEQUENCE fatsmurf_history_id_seq; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON SEQUENCE perseus.fatsmurf_history_id_seq TO perseus_read;
GRANT ALL ON SEQUENCE perseus.fatsmurf_history_id_seq TO perseus_user;
GRANT ALL ON SEQUENCE perseus.fatsmurf_history_id_seq TO perseus_admin;


--
-- Name: SEQUENCE fatsmurf_id_seq; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON SEQUENCE perseus.fatsmurf_id_seq TO perseus_read;
GRANT ALL ON SEQUENCE perseus.fatsmurf_id_seq TO perseus_user;
GRANT ALL ON SEQUENCE perseus.fatsmurf_id_seq TO perseus_admin;


--
-- Name: TABLE fatsmurf_reading; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.fatsmurf_reading TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.fatsmurf_reading TO perseus_user;
GRANT ALL ON TABLE perseus.fatsmurf_reading TO perseus_admin;


--
-- Name: SEQUENCE fatsmurf_reading_id_seq; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON SEQUENCE perseus.fatsmurf_reading_id_seq TO perseus_read;
GRANT ALL ON SEQUENCE perseus.fatsmurf_reading_id_seq TO perseus_user;
GRANT ALL ON SEQUENCE perseus.fatsmurf_reading_id_seq TO perseus_admin;


--
-- Name: TABLE feed_type; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.feed_type TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.feed_type TO perseus_user;
GRANT ALL ON TABLE perseus.feed_type TO perseus_admin;


--
-- Name: SEQUENCE feed_type_id_seq; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON SEQUENCE perseus.feed_type_id_seq TO perseus_read;
GRANT ALL ON SEQUENCE perseus.feed_type_id_seq TO perseus_user;
GRANT ALL ON SEQUENCE perseus.feed_type_id_seq TO perseus_admin;


--
-- Name: SEQUENCE field_map_block_id_seq; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON SEQUENCE perseus.field_map_block_id_seq TO perseus_read;
GRANT ALL ON SEQUENCE perseus.field_map_block_id_seq TO perseus_user;
GRANT ALL ON SEQUENCE perseus.field_map_block_id_seq TO perseus_admin;


--
-- Name: SEQUENCE field_map_display_type_id_seq; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON SEQUENCE perseus.field_map_display_type_id_seq TO perseus_read;
GRANT ALL ON SEQUENCE perseus.field_map_display_type_id_seq TO perseus_user;
GRANT ALL ON SEQUENCE perseus.field_map_display_type_id_seq TO perseus_admin;


--
-- Name: TABLE field_map_display_type_user; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.field_map_display_type_user TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.field_map_display_type_user TO perseus_user;
GRANT ALL ON TABLE perseus.field_map_display_type_user TO perseus_admin;


--
-- Name: SEQUENCE field_map_display_type_user_id_seq; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON SEQUENCE perseus.field_map_display_type_user_id_seq TO perseus_read;
GRANT ALL ON SEQUENCE perseus.field_map_display_type_user_id_seq TO perseus_user;
GRANT ALL ON SEQUENCE perseus.field_map_display_type_user_id_seq TO perseus_admin;


--
-- Name: SEQUENCE field_map_id_seq; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON SEQUENCE perseus.field_map_id_seq TO perseus_read;
GRANT ALL ON SEQUENCE perseus.field_map_id_seq TO perseus_user;
GRANT ALL ON SEQUENCE perseus.field_map_id_seq TO perseus_admin;


--
-- Name: TABLE field_map_set; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.field_map_set TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.field_map_set TO perseus_user;
GRANT ALL ON TABLE perseus.field_map_set TO perseus_admin;


--
-- Name: TABLE field_map_type; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.field_map_type TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.field_map_type TO perseus_user;
GRANT ALL ON TABLE perseus.field_map_type TO perseus_admin;


--
-- Name: TABLE goo; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.goo TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.goo TO perseus_user;
GRANT ALL ON TABLE perseus.goo TO perseus_admin;


--
-- Name: TABLE goo_attachment; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.goo_attachment TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.goo_attachment TO perseus_user;
GRANT ALL ON TABLE perseus.goo_attachment TO perseus_admin;


--
-- Name: SEQUENCE goo_attachment_id_seq; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON SEQUENCE perseus.goo_attachment_id_seq TO perseus_read;
GRANT ALL ON SEQUENCE perseus.goo_attachment_id_seq TO perseus_user;
GRANT ALL ON SEQUENCE perseus.goo_attachment_id_seq TO perseus_admin;


--
-- Name: TABLE goo_attachment_type; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.goo_attachment_type TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.goo_attachment_type TO perseus_user;
GRANT ALL ON TABLE perseus.goo_attachment_type TO perseus_admin;


--
-- Name: SEQUENCE goo_attachment_type_id_seq; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON SEQUENCE perseus.goo_attachment_type_id_seq TO perseus_read;
GRANT ALL ON SEQUENCE perseus.goo_attachment_type_id_seq TO perseus_user;
GRANT ALL ON SEQUENCE perseus.goo_attachment_type_id_seq TO perseus_admin;


--
-- Name: TABLE goo_comment; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.goo_comment TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.goo_comment TO perseus_user;
GRANT ALL ON TABLE perseus.goo_comment TO perseus_admin;


--
-- Name: SEQUENCE goo_comment_id_seq; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON SEQUENCE perseus.goo_comment_id_seq TO perseus_read;
GRANT ALL ON SEQUENCE perseus.goo_comment_id_seq TO perseus_user;
GRANT ALL ON SEQUENCE perseus.goo_comment_id_seq TO perseus_admin;


--
-- Name: TABLE goo_history; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.goo_history TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.goo_history TO perseus_user;
GRANT ALL ON TABLE perseus.goo_history TO perseus_admin;


--
-- Name: SEQUENCE goo_history_id_seq; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON SEQUENCE perseus.goo_history_id_seq TO perseus_read;
GRANT ALL ON SEQUENCE perseus.goo_history_id_seq TO perseus_user;
GRANT ALL ON SEQUENCE perseus.goo_history_id_seq TO perseus_admin;


--
-- Name: SEQUENCE goo_id_seq; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON SEQUENCE perseus.goo_id_seq TO perseus_read;
GRANT ALL ON SEQUENCE perseus.goo_id_seq TO perseus_user;
GRANT ALL ON SEQUENCE perseus.goo_id_seq TO perseus_admin;


--
-- Name: TABLE goo_process_queue_type; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.goo_process_queue_type TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.goo_process_queue_type TO perseus_user;
GRANT ALL ON TABLE perseus.goo_process_queue_type TO perseus_admin;


--
-- Name: SEQUENCE goo_process_queue_type_id_seq; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON SEQUENCE perseus.goo_process_queue_type_id_seq TO perseus_read;
GRANT ALL ON SEQUENCE perseus.goo_process_queue_type_id_seq TO perseus_user;
GRANT ALL ON SEQUENCE perseus.goo_process_queue_type_id_seq TO perseus_admin;


--
-- Name: TABLE goo_type; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.goo_type TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.goo_type TO perseus_user;
GRANT ALL ON TABLE perseus.goo_type TO perseus_admin;


--
-- Name: TABLE goo_type_combine_component; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.goo_type_combine_component TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.goo_type_combine_component TO perseus_user;
GRANT ALL ON TABLE perseus.goo_type_combine_component TO perseus_admin;


--
-- Name: SEQUENCE goo_type_combine_component_id_seq; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON SEQUENCE perseus.goo_type_combine_component_id_seq TO perseus_read;
GRANT ALL ON SEQUENCE perseus.goo_type_combine_component_id_seq TO perseus_user;
GRANT ALL ON SEQUENCE perseus.goo_type_combine_component_id_seq TO perseus_admin;


--
-- Name: TABLE goo_type_combine_target; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.goo_type_combine_target TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.goo_type_combine_target TO perseus_user;
GRANT ALL ON TABLE perseus.goo_type_combine_target TO perseus_admin;


--
-- Name: SEQUENCE goo_type_combine_target_id_seq; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON SEQUENCE perseus.goo_type_combine_target_id_seq TO perseus_read;
GRANT ALL ON SEQUENCE perseus.goo_type_combine_target_id_seq TO perseus_user;
GRANT ALL ON SEQUENCE perseus.goo_type_combine_target_id_seq TO perseus_admin;


--
-- Name: SEQUENCE goo_type_id_seq; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON SEQUENCE perseus.goo_type_id_seq TO perseus_read;
GRANT ALL ON SEQUENCE perseus.goo_type_id_seq TO perseus_user;
GRANT ALL ON SEQUENCE perseus.goo_type_id_seq TO perseus_admin;


--
-- Name: TABLE hermes_run; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.hermes_run TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.hermes_run TO perseus_user;
GRANT ALL ON TABLE perseus.hermes_run TO perseus_admin;


--
-- Name: TABLE history; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.history TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.history TO perseus_user;
GRANT ALL ON TABLE perseus.history TO perseus_admin;


--
-- Name: SEQUENCE history_id_seq; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON SEQUENCE perseus.history_id_seq TO perseus_read;
GRANT ALL ON SEQUENCE perseus.history_id_seq TO perseus_user;
GRANT ALL ON SEQUENCE perseus.history_id_seq TO perseus_admin;


--
-- Name: TABLE history_type; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.history_type TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.history_type TO perseus_user;
GRANT ALL ON TABLE perseus.history_type TO perseus_admin;


--
-- Name: SEQUENCE history_type_id_seq; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON SEQUENCE perseus.history_type_id_seq TO perseus_read;
GRANT ALL ON SEQUENCE perseus.history_type_id_seq TO perseus_user;
GRANT ALL ON SEQUENCE perseus.history_type_id_seq TO perseus_admin;


--
-- Name: TABLE history_value; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.history_value TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.history_value TO perseus_user;
GRANT ALL ON TABLE perseus.history_value TO perseus_admin;


--
-- Name: SEQUENCE history_value_id_seq; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON SEQUENCE perseus.history_value_id_seq TO perseus_read;
GRANT ALL ON SEQUENCE perseus.history_value_id_seq TO perseus_user;
GRANT ALL ON SEQUENCE perseus.history_value_id_seq TO perseus_admin;


--
-- Name: TABLE m_downstream; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.m_downstream TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.m_downstream TO perseus_user;
GRANT ALL ON TABLE perseus.m_downstream TO perseus_admin;


--
-- Name: TABLE m_number; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.m_number TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.m_number TO perseus_user;
GRANT ALL ON TABLE perseus.m_number TO perseus_admin;


--
-- Name: SEQUENCE m_number_id_seq; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON SEQUENCE perseus.m_number_id_seq TO perseus_read;
GRANT ALL ON SEQUENCE perseus.m_number_id_seq TO perseus_user;
GRANT ALL ON SEQUENCE perseus.m_number_id_seq TO perseus_admin;


--
-- Name: TABLE m_upstream; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.m_upstream TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.m_upstream TO perseus_user;
GRANT ALL ON TABLE perseus.m_upstream TO perseus_admin;


--
-- Name: TABLE m_upstream_dirty_leaves; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.m_upstream_dirty_leaves TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.m_upstream_dirty_leaves TO perseus_user;
GRANT ALL ON TABLE perseus.m_upstream_dirty_leaves TO perseus_admin;


--
-- Name: TABLE manufacturer; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.manufacturer TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.manufacturer TO perseus_user;
GRANT ALL ON TABLE perseus.manufacturer TO perseus_admin;


--
-- Name: SEQUENCE manufacturer_id_seq; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON SEQUENCE perseus.manufacturer_id_seq TO perseus_read;
GRANT ALL ON SEQUENCE perseus.manufacturer_id_seq TO perseus_user;
GRANT ALL ON SEQUENCE perseus.manufacturer_id_seq TO perseus_admin;


--
-- Name: TABLE material_inventory; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.material_inventory TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.material_inventory TO perseus_user;
GRANT ALL ON TABLE perseus.material_inventory TO perseus_admin;


--
-- Name: SEQUENCE material_inventory_id_seq; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON SEQUENCE perseus.material_inventory_id_seq TO perseus_read;
GRANT ALL ON SEQUENCE perseus.material_inventory_id_seq TO perseus_user;
GRANT ALL ON SEQUENCE perseus.material_inventory_id_seq TO perseus_admin;


--
-- Name: TABLE material_inventory_threshold; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.material_inventory_threshold TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.material_inventory_threshold TO perseus_user;
GRANT ALL ON TABLE perseus.material_inventory_threshold TO perseus_admin;


--
-- Name: SEQUENCE material_inventory_threshold_id_seq; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON SEQUENCE perseus.material_inventory_threshold_id_seq TO perseus_read;
GRANT ALL ON SEQUENCE perseus.material_inventory_threshold_id_seq TO perseus_user;
GRANT ALL ON SEQUENCE perseus.material_inventory_threshold_id_seq TO perseus_admin;


--
-- Name: TABLE material_inventory_threshold_notify_user; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.material_inventory_threshold_notify_user TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.material_inventory_threshold_notify_user TO perseus_user;
GRANT ALL ON TABLE perseus.material_inventory_threshold_notify_user TO perseus_admin;


--
-- Name: TABLE material_inventory_type; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.material_inventory_type TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.material_inventory_type TO perseus_user;
GRANT ALL ON TABLE perseus.material_inventory_type TO perseus_admin;


--
-- Name: SEQUENCE material_inventory_type_id_seq; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON SEQUENCE perseus.material_inventory_type_id_seq TO perseus_read;
GRANT ALL ON SEQUENCE perseus.material_inventory_type_id_seq TO perseus_user;
GRANT ALL ON SEQUENCE perseus.material_inventory_type_id_seq TO perseus_admin;


--
-- Name: TABLE material_qc; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.material_qc TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.material_qc TO perseus_user;
GRANT ALL ON TABLE perseus.material_qc TO perseus_admin;


--
-- Name: SEQUENCE material_qc_id_seq; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON SEQUENCE perseus.material_qc_id_seq TO perseus_read;
GRANT ALL ON SEQUENCE perseus.material_qc_id_seq TO perseus_user;
GRANT ALL ON SEQUENCE perseus.material_qc_id_seq TO perseus_admin;


--
-- Name: TABLE material_transition_material; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.material_transition_material TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.material_transition_material TO perseus_user;
GRANT ALL ON TABLE perseus.material_transition_material TO perseus_admin;


--
-- Name: TABLE migration; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.migration TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.migration TO perseus_user;
GRANT ALL ON TABLE perseus.migration TO perseus_admin;


--
-- Name: TABLE permissions; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.permissions TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.permissions TO perseus_user;
GRANT ALL ON TABLE perseus.permissions TO perseus_admin;


--
-- Name: TABLE perseus_user; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.perseus_user TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.perseus_user TO perseus_user;
GRANT ALL ON TABLE perseus.perseus_user TO perseus_admin;


--
-- Name: SEQUENCE perseus_user_id_seq; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON SEQUENCE perseus.perseus_user_id_seq TO perseus_read;
GRANT ALL ON SEQUENCE perseus.perseus_user_id_seq TO perseus_user;
GRANT ALL ON SEQUENCE perseus.perseus_user_id_seq TO perseus_admin;


--
-- Name: TABLE person; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.person TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.person TO perseus_user;
GRANT ALL ON TABLE perseus.person TO perseus_admin;


--
-- Name: TABLE poll; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.poll TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.poll TO perseus_user;
GRANT ALL ON TABLE perseus.poll TO perseus_admin;


--
-- Name: TABLE poll_history; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.poll_history TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.poll_history TO perseus_user;
GRANT ALL ON TABLE perseus.poll_history TO perseus_admin;


--
-- Name: SEQUENCE poll_history_id_seq; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON SEQUENCE perseus.poll_history_id_seq TO perseus_read;
GRANT ALL ON SEQUENCE perseus.poll_history_id_seq TO perseus_user;
GRANT ALL ON SEQUENCE perseus.poll_history_id_seq TO perseus_admin;


--
-- Name: SEQUENCE poll_id_seq; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON SEQUENCE perseus.poll_id_seq TO perseus_read;
GRANT ALL ON SEQUENCE perseus.poll_id_seq TO perseus_user;
GRANT ALL ON SEQUENCE perseus.poll_id_seq TO perseus_admin;


--
-- Name: TABLE prefix_incrementor; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.prefix_incrementor TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.prefix_incrementor TO perseus_user;
GRANT ALL ON TABLE perseus.prefix_incrementor TO perseus_admin;


--
-- Name: SEQUENCE property_id_seq; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON SEQUENCE perseus.property_id_seq TO perseus_read;
GRANT ALL ON SEQUENCE perseus.property_id_seq TO perseus_user;
GRANT ALL ON SEQUENCE perseus.property_id_seq TO perseus_admin;


--
-- Name: SEQUENCE property_option_id_seq; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON SEQUENCE perseus.property_option_id_seq TO perseus_read;
GRANT ALL ON SEQUENCE perseus.property_option_id_seq TO perseus_user;
GRANT ALL ON SEQUENCE perseus.property_option_id_seq TO perseus_admin;


--
-- Name: TABLE recipe; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.recipe TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.recipe TO perseus_user;
GRANT ALL ON TABLE perseus.recipe TO perseus_admin;


--
-- Name: SEQUENCE recipe_id_seq; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON SEQUENCE perseus.recipe_id_seq TO perseus_read;
GRANT ALL ON SEQUENCE perseus.recipe_id_seq TO perseus_user;
GRANT ALL ON SEQUENCE perseus.recipe_id_seq TO perseus_admin;


--
-- Name: TABLE recipe_part; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.recipe_part TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.recipe_part TO perseus_user;
GRANT ALL ON TABLE perseus.recipe_part TO perseus_admin;


--
-- Name: SEQUENCE recipe_part_id_seq; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON SEQUENCE perseus.recipe_part_id_seq TO perseus_read;
GRANT ALL ON SEQUENCE perseus.recipe_part_id_seq TO perseus_user;
GRANT ALL ON SEQUENCE perseus.recipe_part_id_seq TO perseus_admin;


--
-- Name: TABLE recipe_project_assignment; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.recipe_project_assignment TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.recipe_project_assignment TO perseus_user;
GRANT ALL ON TABLE perseus.recipe_project_assignment TO perseus_admin;


--
-- Name: TABLE robot_log; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.robot_log TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.robot_log TO perseus_user;
GRANT ALL ON TABLE perseus.robot_log TO perseus_admin;


--
-- Name: TABLE robot_log_container_sequence; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.robot_log_container_sequence TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.robot_log_container_sequence TO perseus_user;
GRANT ALL ON TABLE perseus.robot_log_container_sequence TO perseus_admin;


--
-- Name: SEQUENCE robot_log_container_sequence_id_seq; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON SEQUENCE perseus.robot_log_container_sequence_id_seq TO perseus_read;
GRANT ALL ON SEQUENCE perseus.robot_log_container_sequence_id_seq TO perseus_user;
GRANT ALL ON SEQUENCE perseus.robot_log_container_sequence_id_seq TO perseus_admin;


--
-- Name: TABLE robot_log_error; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.robot_log_error TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.robot_log_error TO perseus_user;
GRANT ALL ON TABLE perseus.robot_log_error TO perseus_admin;


--
-- Name: SEQUENCE robot_log_error_id_seq; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON SEQUENCE perseus.robot_log_error_id_seq TO perseus_read;
GRANT ALL ON SEQUENCE perseus.robot_log_error_id_seq TO perseus_user;
GRANT ALL ON SEQUENCE perseus.robot_log_error_id_seq TO perseus_admin;


--
-- Name: SEQUENCE robot_log_id_seq; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON SEQUENCE perseus.robot_log_id_seq TO perseus_read;
GRANT ALL ON SEQUENCE perseus.robot_log_id_seq TO perseus_user;
GRANT ALL ON SEQUENCE perseus.robot_log_id_seq TO perseus_admin;


--
-- Name: TABLE robot_log_read; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.robot_log_read TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.robot_log_read TO perseus_user;
GRANT ALL ON TABLE perseus.robot_log_read TO perseus_admin;


--
-- Name: SEQUENCE robot_log_read_id_seq; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON SEQUENCE perseus.robot_log_read_id_seq TO perseus_read;
GRANT ALL ON SEQUENCE perseus.robot_log_read_id_seq TO perseus_user;
GRANT ALL ON SEQUENCE perseus.robot_log_read_id_seq TO perseus_admin;


--
-- Name: TABLE robot_log_transfer; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.robot_log_transfer TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.robot_log_transfer TO perseus_user;
GRANT ALL ON TABLE perseus.robot_log_transfer TO perseus_admin;


--
-- Name: SEQUENCE robot_log_transfer_id_seq; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON SEQUENCE perseus.robot_log_transfer_id_seq TO perseus_read;
GRANT ALL ON SEQUENCE perseus.robot_log_transfer_id_seq TO perseus_user;
GRANT ALL ON SEQUENCE perseus.robot_log_transfer_id_seq TO perseus_admin;


--
-- Name: TABLE robot_log_type; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.robot_log_type TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.robot_log_type TO perseus_user;
GRANT ALL ON TABLE perseus.robot_log_type TO perseus_admin;


--
-- Name: SEQUENCE robot_log_type_id_seq; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON SEQUENCE perseus.robot_log_type_id_seq TO perseus_read;
GRANT ALL ON SEQUENCE perseus.robot_log_type_id_seq TO perseus_user;
GRANT ALL ON SEQUENCE perseus.robot_log_type_id_seq TO perseus_admin;


--
-- Name: TABLE robot_run; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.robot_run TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.robot_run TO perseus_user;
GRANT ALL ON TABLE perseus.robot_run TO perseus_admin;


--
-- Name: SEQUENCE robot_run_id_seq; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON SEQUENCE perseus.robot_run_id_seq TO perseus_read;
GRANT ALL ON SEQUENCE perseus.robot_run_id_seq TO perseus_user;
GRANT ALL ON SEQUENCE perseus.robot_run_id_seq TO perseus_admin;


--
-- Name: TABLE s_number; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.s_number TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.s_number TO perseus_user;
GRANT ALL ON TABLE perseus.s_number TO perseus_admin;


--
-- Name: SEQUENCE s_number_id_seq; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON SEQUENCE perseus.s_number_id_seq TO perseus_read;
GRANT ALL ON SEQUENCE perseus.s_number_id_seq TO perseus_user;
GRANT ALL ON SEQUENCE perseus.s_number_id_seq TO perseus_admin;


--
-- Name: TABLE saved_search; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.saved_search TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.saved_search TO perseus_user;
GRANT ALL ON TABLE perseus.saved_search TO perseus_admin;


--
-- Name: SEQUENCE saved_search_id_seq; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON SEQUENCE perseus.saved_search_id_seq TO perseus_read;
GRANT ALL ON SEQUENCE perseus.saved_search_id_seq TO perseus_user;
GRANT ALL ON SEQUENCE perseus.saved_search_id_seq TO perseus_admin;


--
-- Name: TABLE scraper; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.scraper TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.scraper TO perseus_user;
GRANT ALL ON TABLE perseus.scraper TO perseus_admin;


--
-- Name: SEQUENCE scraper_id_seq; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON SEQUENCE perseus.scraper_id_seq TO perseus_read;
GRANT ALL ON SEQUENCE perseus.scraper_id_seq TO perseus_user;
GRANT ALL ON SEQUENCE perseus.scraper_id_seq TO perseus_admin;


--
-- Name: TABLE sequence_type; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.sequence_type TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.sequence_type TO perseus_user;
GRANT ALL ON TABLE perseus.sequence_type TO perseus_admin;


--
-- Name: SEQUENCE sequence_type_id_seq; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON SEQUENCE perseus.sequence_type_id_seq TO perseus_read;
GRANT ALL ON SEQUENCE perseus.sequence_type_id_seq TO perseus_user;
GRANT ALL ON SEQUENCE perseus.sequence_type_id_seq TO perseus_admin;


--
-- Name: TABLE smurf_goo_type; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.smurf_goo_type TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.smurf_goo_type TO perseus_user;
GRANT ALL ON TABLE perseus.smurf_goo_type TO perseus_admin;


--
-- Name: SEQUENCE smurf_goo_type_id_seq; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON SEQUENCE perseus.smurf_goo_type_id_seq TO perseus_read;
GRANT ALL ON SEQUENCE perseus.smurf_goo_type_id_seq TO perseus_user;
GRANT ALL ON SEQUENCE perseus.smurf_goo_type_id_seq TO perseus_admin;


--
-- Name: TABLE smurf_group; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.smurf_group TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.smurf_group TO perseus_user;
GRANT ALL ON TABLE perseus.smurf_group TO perseus_admin;


--
-- Name: SEQUENCE smurf_group_id_seq; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON SEQUENCE perseus.smurf_group_id_seq TO perseus_read;
GRANT ALL ON SEQUENCE perseus.smurf_group_id_seq TO perseus_user;
GRANT ALL ON SEQUENCE perseus.smurf_group_id_seq TO perseus_admin;


--
-- Name: TABLE smurf_group_member; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.smurf_group_member TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.smurf_group_member TO perseus_user;
GRANT ALL ON TABLE perseus.smurf_group_member TO perseus_admin;


--
-- Name: SEQUENCE smurf_group_member_id_seq; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON SEQUENCE perseus.smurf_group_member_id_seq TO perseus_read;
GRANT ALL ON SEQUENCE perseus.smurf_group_member_id_seq TO perseus_user;
GRANT ALL ON SEQUENCE perseus.smurf_group_member_id_seq TO perseus_admin;


--
-- Name: SEQUENCE smurf_id_seq; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON SEQUENCE perseus.smurf_id_seq TO perseus_read;
GRANT ALL ON SEQUENCE perseus.smurf_id_seq TO perseus_user;
GRANT ALL ON SEQUENCE perseus.smurf_id_seq TO perseus_admin;


--
-- Name: SEQUENCE smurf_property_id_seq; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON SEQUENCE perseus.smurf_property_id_seq TO perseus_read;
GRANT ALL ON SEQUENCE perseus.smurf_property_id_seq TO perseus_user;
GRANT ALL ON SEQUENCE perseus.smurf_property_id_seq TO perseus_admin;


--
-- Name: TABLE submission; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.submission TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.submission TO perseus_user;
GRANT ALL ON TABLE perseus.submission TO perseus_admin;


--
-- Name: TABLE submission_entry; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.submission_entry TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.submission_entry TO perseus_user;
GRANT ALL ON TABLE perseus.submission_entry TO perseus_admin;


--
-- Name: SEQUENCE submission_entry_id_seq; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON SEQUENCE perseus.submission_entry_id_seq TO perseus_read;
GRANT ALL ON SEQUENCE perseus.submission_entry_id_seq TO perseus_user;
GRANT ALL ON SEQUENCE perseus.submission_entry_id_seq TO perseus_admin;


--
-- Name: SEQUENCE submission_id_seq; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON SEQUENCE perseus.submission_id_seq TO perseus_read;
GRANT ALL ON SEQUENCE perseus.submission_id_seq TO perseus_user;
GRANT ALL ON SEQUENCE perseus.submission_id_seq TO perseus_admin;


--
-- Name: TABLE tmp_messy_links; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.tmp_messy_links TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.tmp_messy_links TO perseus_user;
GRANT ALL ON TABLE perseus.tmp_messy_links TO perseus_admin;


--
-- Name: SEQUENCE unit_id_seq; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON SEQUENCE perseus.unit_id_seq TO perseus_read;
GRANT ALL ON SEQUENCE perseus.unit_id_seq TO perseus_user;
GRANT ALL ON SEQUENCE perseus.unit_id_seq TO perseus_admin;


--
-- Name: TABLE upstream; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.upstream TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.upstream TO perseus_user;
GRANT ALL ON TABLE perseus.upstream TO perseus_admin;


--
-- Name: TABLE vw_process_upstream; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.vw_process_upstream TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.vw_process_upstream TO perseus_user;
GRANT ALL ON TABLE perseus.vw_process_upstream TO perseus_admin;


--
-- Name: TABLE vw_fermentation_upstream; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.vw_fermentation_upstream TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.vw_fermentation_upstream TO perseus_user;
GRANT ALL ON TABLE perseus.vw_fermentation_upstream TO perseus_admin;


--
-- Name: TABLE vw_lot; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.vw_lot TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.vw_lot TO perseus_user;
GRANT ALL ON TABLE perseus.vw_lot TO perseus_admin;


--
-- Name: TABLE vw_lot_edge; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.vw_lot_edge TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.vw_lot_edge TO perseus_user;
GRANT ALL ON TABLE perseus.vw_lot_edge TO perseus_admin;


--
-- Name: TABLE vw_lot_path; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.vw_lot_path TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.vw_lot_path TO perseus_user;
GRANT ALL ON TABLE perseus.vw_lot_path TO perseus_admin;


--
-- Name: TABLE vw_material_transition_material_up; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.vw_material_transition_material_up TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.vw_material_transition_material_up TO perseus_user;
GRANT ALL ON TABLE perseus.vw_material_transition_material_up TO perseus_admin;


--
-- Name: TABLE vw_recipe_prep; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.vw_recipe_prep TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.vw_recipe_prep TO perseus_user;
GRANT ALL ON TABLE perseus.vw_recipe_prep TO perseus_admin;


--
-- Name: TABLE vw_recipe_prep_part; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.vw_recipe_prep_part TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.vw_recipe_prep_part TO perseus_user;
GRANT ALL ON TABLE perseus.vw_recipe_prep_part TO perseus_admin;


--
-- Name: TABLE vw_tom_perseus_sample_prep_materials; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.vw_tom_perseus_sample_prep_materials TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.vw_tom_perseus_sample_prep_materials TO perseus_user;
GRANT ALL ON TABLE perseus.vw_tom_perseus_sample_prep_materials TO perseus_admin;


--
-- Name: TABLE workflow; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.workflow TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.workflow TO perseus_user;
GRANT ALL ON TABLE perseus.workflow TO perseus_admin;


--
-- Name: TABLE workflow_attachment; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.workflow_attachment TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.workflow_attachment TO perseus_user;
GRANT ALL ON TABLE perseus.workflow_attachment TO perseus_admin;


--
-- Name: SEQUENCE workflow_attachment_id_seq; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON SEQUENCE perseus.workflow_attachment_id_seq TO perseus_read;
GRANT ALL ON SEQUENCE perseus.workflow_attachment_id_seq TO perseus_user;
GRANT ALL ON SEQUENCE perseus.workflow_attachment_id_seq TO perseus_admin;


--
-- Name: SEQUENCE workflow_id_seq; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON SEQUENCE perseus.workflow_id_seq TO perseus_read;
GRANT ALL ON SEQUENCE perseus.workflow_id_seq TO perseus_user;
GRANT ALL ON SEQUENCE perseus.workflow_id_seq TO perseus_admin;


--
-- Name: TABLE workflow_section; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.workflow_section TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.workflow_section TO perseus_user;
GRANT ALL ON TABLE perseus.workflow_section TO perseus_admin;


--
-- Name: SEQUENCE workflow_section_id_seq; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON SEQUENCE perseus.workflow_section_id_seq TO perseus_read;
GRANT ALL ON SEQUENCE perseus.workflow_section_id_seq TO perseus_user;
GRANT ALL ON SEQUENCE perseus.workflow_section_id_seq TO perseus_admin;


--
-- Name: TABLE workflow_step; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.workflow_step TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.workflow_step TO perseus_user;
GRANT ALL ON TABLE perseus.workflow_step TO perseus_admin;


--
-- Name: SEQUENCE workflow_step_id_seq; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON SEQUENCE perseus.workflow_step_id_seq TO perseus_read;
GRANT ALL ON SEQUENCE perseus.workflow_step_id_seq TO perseus_user;
GRANT ALL ON SEQUENCE perseus.workflow_step_id_seq TO perseus_admin;


--
-- Name: TABLE workflow_step_type; Type: ACL; Schema: perseus; Owner: perseus_owner
--

GRANT SELECT ON TABLE perseus.workflow_step_type TO perseus_read;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE perseus.workflow_step_type TO perseus_user;
GRANT ALL ON TABLE perseus.workflow_step_type TO perseus_admin;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: perseus; Owner: perseus_owner
--

ALTER DEFAULT PRIVILEGES FOR ROLE perseus_owner IN SCHEMA perseus GRANT ALL ON SEQUENCES TO perseus_user;


--
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: perseus; Owner: perseus_owner
--

ALTER DEFAULT PRIVILEGES FOR ROLE perseus_owner IN SCHEMA perseus GRANT ALL ON FUNCTIONS TO perseus_read;
ALTER DEFAULT PRIVILEGES FOR ROLE perseus_owner IN SCHEMA perseus GRANT ALL ON FUNCTIONS TO perseus_user;
ALTER DEFAULT PRIVILEGES FOR ROLE perseus_owner IN SCHEMA perseus GRANT ALL ON FUNCTIONS TO perseus_admin;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: perseus; Owner: perseus_owner
--

ALTER DEFAULT PRIVILEGES FOR ROLE perseus_owner IN SCHEMA perseus GRANT SELECT ON TABLES TO perseus_read;
ALTER DEFAULT PRIVILEGES FOR ROLE perseus_owner IN SCHEMA perseus GRANT SELECT,INSERT,DELETE,UPDATE ON TABLES TO perseus_user;
ALTER DEFAULT PRIVILEGES FOR ROLE perseus_owner IN SCHEMA perseus GRANT ALL ON TABLES TO perseus_admin;


--
-- PostgreSQL database dump complete
--

\unrestrict vCks0JuvW2V6DyjHMzfPTQWMiClchfW4Pdog8ZKJdN6udnOqfabakK1rCoIHOFR

