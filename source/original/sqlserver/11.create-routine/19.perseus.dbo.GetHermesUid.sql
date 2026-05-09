USE [perseus]
GO
            
CREATE FUNCTION GetHermesUid (@ExperimentId INT, @RunId INT)
    RETURNS NVARCHAR(50)
AS
BEGIN
    DECLARE @Uid NVARCHAR(50)

    SET @Uid = 'H'+CAST(@ExperimentId AS NVARCHAR(25)) + '-' + CAST(@RunId AS NVARCHAR(25))

    RETURN @Uid
END

