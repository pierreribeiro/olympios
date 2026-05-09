USE [perseus]
GO
            
CREATE FUNCTION GetHermesRun (@HermesUid NVARCHAR(50))
    RETURNS INT
AS
BEGIN
    DECLARE @Experiment INT

    SET @Experiment = PARSENAME(REPLACE(REPLACE(@HermesUid, 'H', ''), '-', '.'), 1)

    RETURN @Experiment
END

