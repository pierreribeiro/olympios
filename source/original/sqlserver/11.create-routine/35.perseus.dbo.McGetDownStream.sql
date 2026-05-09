USE [perseus]
GO
            
CREATE  FUNCTION [dbo].[McGetDownStream](@StartPoint VARCHAR(50)) 
RETURNS @Paths TABLE (start_point VARCHAR(50), end_point VARCHAR(50), neighbor VARCHAR(50), path VARCHAR(500), level INT)

AS BEGIN

	WITH downstream
	AS
	(
		SELECT pt.source_material AS start_point, pt.source_material AS parent, pt.destination_material AS child, CAST('/' AS VARCHAR(500)) AS path, 1 AS level
		FROM translated pt
		WHERE (pt.source_material = @StartPoint OR pt.transition_id = @StartPoint)
		UNION ALL
	   
		SELECT r.start_point, pt.source_material, pt.destination_material, CAST(r.path + r.child + '/' AS VARCHAR(500)), r.level + 1
		FROM translated pt
		JOIN downstream r ON pt.source_material = r.child
		WHERE pt.source_material != pt.destination_material
	)
	
	INSERT INTO @Paths
	SELECT start_point, child AS end_point, parent, path, level FROM downstream
	
	INSERT INTO @Paths VALUES
	(@StartPoint, @StartPoint, NULL, '', 0)

	RETURN
END

--SELECT * FROM McGetDownStream('m5963')

