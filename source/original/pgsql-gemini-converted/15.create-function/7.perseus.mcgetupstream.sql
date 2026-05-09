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

