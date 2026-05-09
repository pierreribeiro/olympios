USE [perseus]
GO
            
CREATE FUNCTION RoundDateTime (@InputDateTime DATETIME)
	RETURNS DATETIME
AS
BEGIN
	DECLARE @ReturnDateTime DATETIME
	SET @ReturnDateTime = DATEADD(MINUTE, DATEDIFF(MINUTE, 0, @InputDateTime), 0)

	RETURN @ReturnDateTime
END

