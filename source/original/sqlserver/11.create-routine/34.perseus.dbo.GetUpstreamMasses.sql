USE [perseus]
GO
            
CREATE FUNCTION GetUpstreamMasses (@StartPoint NVARCHAR(50)) 
RETURNS @Masses TABLE (end_point NVARCHAR(50), mass float, level INT)

AS BEGIN

	--DECLARE @StartPoint NVARCHAR(50)
	--SET @StartPoint = 'm153677'

	DECLARE @UsUid NVARCHAR(50)
	DECLARE @MassCalcId INT
	DECLARE @MassCalc TABLE (id INT IDENTITY(1,1), end_point NVARCHAR(50), mass float, path NVARCHAR(250), level INT)

	INSERT INTO @MassCalc (end_point, mass, path, level)
	SELECT us.end_point, NULLIF(g.original_mass, 0), us.path, us.level FROM GetUnProcessedUpStream(@StartPoint) us
	JOIN goo g ON g.uid = us.end_point
	AND (g.container_id IS NULL OR ISNULL(g.original_mass, 0) = 0)
	WHERE us.level > 0

	--SELECT * FROM @MassCalc

	DELETE FROM @MassCalc
	WHERE id IN (
		SELECT mc_us.id FROM @MassCalc mc_ds
		JOIN @MassCalc mc_us ON mc_us.path LIKE '%/' + mc_ds.end_point + '/%' AND mc_ds.level < mc_us.level
		WHERE mc_ds.mass IS NOT NULL
	)

	--SELECT * FROM @MassCalc

	DELETE FROM @MassCalc
	WHERE id IN (
		SELECT mc_us.id FROM @MassCalc mc_ds
		JOIN @MassCalc mc_us ON mc_us.path LIKE '%/' + mc_ds.end_point + '/%' AND mc_ds.level < mc_us.level
		WHERE mc_us.mass IS NULL
	)

	DECLARE US_CUR CURSOR FOR  
	SELECT end_point, id FROM @MassCalc
	WHERE mass IS NOT NULL

	OPEN US_CUR  
	FETCH NEXT FROM US_CUR INTO @UsUid, @MassCalcId 

	WHILE @@FETCH_STATUS = 0  
	BEGIN  
		IF (
			SELECT COUNT(*) FROM McGetDownStream(@UsUid) ds
			WHERE ds.end_point NOT IN (SELECT end_point FROM @MassCalc)
			AND ds.end_point != @StartPoint
		) > 1
		BEGIN
			DELETE FROM @MassCalc WHERE id = @MassCalcId
		END

		FETCH NEXT FROM US_CUR INTO @UsUid, @MassCalcId 
	END  

	CLOSE US_CUR  
	DEALLOCATE US_CUR 

	INSERT INTO @Masses
	SELECT end_point, mass, level FROM @MassCalc
	WHERE mass IS NOT NULL
	UNION
	SELECT mc2.end_point, mc2.mass, mc2.level FROM @MassCalc mc1
	JOIN @MassCalc mc2 ON mc2.path LIKE '%' + mc1.end_point + '%' 
	WHERE mc2.mass IS NULL
	AND mc1.mass IS NULL
	UNION
	SELECT mc1.end_point, mc1.mass, mc1.level FROM @MassCalc mc1
	WHERE mc1.mass IS NULL
	AND NOT EXISTS (
		SELECT * FROM @MassCalc mc2 
		WHERE mc2.path LIKE '%' + mc1.end_point + '%' 
	)
	UNION
	SELECT mc1.end_point, mc1.mass, mc1.level FROM @MassCalc mc1
	WHERE mc1.mass IS NULL
	AND EXISTS (
		SELECT * FROM @MassCalc mc2 
		WHERE mc2.path LIKE '%' + mc1.end_point + '%' 
		AND mc2.mass IS NULL
	)

	
	RETURN
END

