USE [perseus]
GO
            
CREATE FUNCTION GetUnProcessedUpStream(@StartPoint VARCHAR(50)) 
RETURNS @Paths TABLE (start_point VARCHAR(50), end_point VARCHAR(50), neighbor VARCHAR(50), path VARCHAR(250), level INT)

AS BEGIN

	WITH upstream
	AS
	(
		SELECT pt.destination_material AS start_point, pt.destination_material AS parent, pt.source_material AS child, CAST('/' AS VARCHAR(255)) AS path, 1 AS level
		FROM translated pt
		JOIN fatsmurf fs ON fs.uid = pt.transition_id
		WHERE (pt.destination_material = @StartPoint OR pt.transition_id = @StartPoint)
		AND fs.smurf_id IN (110,111)
		UNION ALL
	   
		SELECT r.start_point, pt.destination_material, pt.source_material, CAST(r.path + r.child + '/' AS VARCHAR(255)), r.level + 1
		FROM translated pt
		JOIN fatsmurf fs ON fs.uid = pt.transition_id
		JOIN upstream r ON pt.destination_material = r.child
		WHERE pt.destination_material != pt.source_material
		AND fs.smurf_id IN (110,111)
	)
	
	INSERT INTO @Paths
	SELECT start_point, child AS end_point, parent, path, level FROM upstream
	
	INSERT INTO @Paths VALUES
	(@StartPoint, @StartPoint, NULL, '', 0)

	RETURN
END

