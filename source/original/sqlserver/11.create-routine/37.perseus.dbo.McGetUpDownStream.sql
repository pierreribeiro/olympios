USE [perseus]
GO
            
CREATE   FUNCTION [dbo].[McGetUpDownStream](@StartPoint VARCHAR(50)) 
RETURNS @Paths TABLE (start_point VARCHAR(50), end_point VARCHAR(50), neighbor VARCHAR(50), path VARCHAR(500), level INT)

AS BEGIN

	INSERT INTO @Paths
	SELECT * FROM dbo.McGetUpstream(@StartPoint)
	
	INSERT INTO @Paths
	SELECT * FROM dbo.McGetDownstream(@StartPoint)
	
	DELETE FROM @Paths WHERE end_point = @StartPoint
	
	INSERT INTO @Paths VALUES
	(@StartPoint, @StartPoint, NULL, '', 0)

	RETURN;
END

