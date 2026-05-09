USE [perseus]
GO
            
-- =============================================
-- Author:		Dolan, Chris
-- Create date: 2/27/2014
-- Description:	Get Fatsmurf for one Parent Run for a Material
-- =============================================
CREATE FUNCTION dbo.GetFermentationFatSmurf (@GooUid NVARCHAR(50))
RETURNS INT
AS
BEGIN
     DECLARE @FatsmurfID INT

     SELECT TOP 1 @FatsmurfID = fs.id
       FROM m_upstream us WITH(NOLOCK)
       JOIN transition_material tm WITH(NOLOCK) ON tm.material_id = us.end_point
       JOIN fatsmurf fs WITH(NOLOCK) ON fs.uid = tm.transition_id
      INNER JOIN (
        SELECT start_point, 
           MIN(us.level) AS first
		  FROM m_upstream us WITH(NOLOCK)
		  JOIN transition_material tm WITH(NOLOCK) ON tm.material_id = us.end_point
		  JOIN fatsmurf fs WITH(NOLOCK) ON fs.uid = tm.transition_id
		 WHERE fs.smurf_id = 22
		 GROUP BY start_point) innersmurf 
	        ON (innersmurf.first = us.level
	        AND innersmurf.start_point = us.start_point)
	  WHERE fs.smurf_id = 22
	    AND us.start_point = @GooUid

	RETURN @FatsmurfID

END

