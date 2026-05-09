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

