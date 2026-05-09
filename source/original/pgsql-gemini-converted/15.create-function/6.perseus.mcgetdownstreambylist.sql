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

