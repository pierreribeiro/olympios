USE [perseus]
GO
            
CREATE FUNCTION GetUpStreamContainers(@StartPoint INT, @StartTime DATETIME, @EndTime DATETIME) 
RETURNS @Paths TABLE (start_point INT, end_point INT, neighbor INT, path VARCHAR(250), level INT)

AS BEGIN

	IF @EndTime IS NULL
		SET @EndTime = GETDATE()
	
	IF @StartTime IS NULL
		SET @StartTime = GETDATE()

	;WITH upstream
	AS
	(
		SELECT ct.child_container_id AS start_point, ct.child_container_id AS parent, ct.parent_container_id AS child, CAST('/' AS VARCHAR(255)) AS path, 1 AS level
		FROM container_relationship ct
		WHERE ct.child_container_id = @StartPoint
		AND ct.relationship_start <= @EndTime
		AND @StartTime <= ISNULL(ct.relationship_end, GETDATE())
		
		UNION ALL
	   
		SELECT r.start_point, ct.child_container_id, ct.parent_container_id, CAST(r.path + CAST(r.child AS VARCHAR(25)) + '/' AS VARCHAR(255)), r.level + 1
		FROM container_relationship ct
		JOIN upstream r ON ct.child_container_id = r.child
		WHERE ct.relationship_start <= @EndTime
		AND @StartTime <= ISNULL(ct.relationship_end, GETDATE())
	)
	
	INSERT INTO @Paths
	SELECT start_point, child AS end_point, parent, path, level FROM upstream
	
	INSERT INTO @Paths VALUES
	(@StartPoint, @StartPoint, NULL, '', 0)

	RETURN;
END

