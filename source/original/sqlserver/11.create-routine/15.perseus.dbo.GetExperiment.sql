USE [perseus]
GO
            
CREATE FUNCTION GetExperiment (@HermesUid NVARCHAR(50))
    RETURNS INT
AS
BEGIN
    DECLARE @Experiment INT

    SET @Experiment = PARSENAME(REPLACE(REPLACE(@HermesUid, 'H', ''), '-', '.'), 2)

    RETURN @Experiment
END

