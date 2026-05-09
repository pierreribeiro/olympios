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

