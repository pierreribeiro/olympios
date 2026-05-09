USE [perseus]
GO
            
CREATE FUNCTION McGetUpStream(@StartPoint VARCHAR(50)) 
RETURNS @Paths TABLE (start_point VARCHAR(50), end_point VARCHAR(50), neighbor VARCHAR(50), path VARCHAR(500), level INT)

AS BEGIN

	WITH upstream
	AS
	(
		SELECT pt.destination_material AS start_point,
		       pt.destination_material AS
		       parent,
		       pt.source_material AS child,
		       CAST('/' AS VARCHAR(500)) AS path,
		 1 AS level
		FROM translated pt WITH (NOLOCK)
		WHERE (pt.destination_material = @StartPoint OR pt.transition_id = @StartPoint)
		UNION ALL
	   
		SELECT r.start_point, pt.destination_material, pt.source_material,
		  CAST(r.path + r.child + '/' AS VARCHAR(500)), r.level + 1
		FROM translated pt WITH (NOLOCK)
		JOIN upstream r ON pt.destination_material = r.child
		WHERE pt.destination_material != pt.source_material
	)
	
	INSERT INTO @Paths
	SELECT start_point, child AS end_point, parent, path, level FROM upstream WITH (NOLOCK)
	
	INSERT INTO @Paths VALUES
	(@StartPoint, @StartPoint, NULL, '', 0)

	RETURN
END

