USE [perseus]
GO
            
CREATE PROCEDURE dbo.usp_UpdateMUpstream
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @UsGooUids GooList

	INSERT INTO @UsGooUids
    SELECT DISTINCT uid FROM (
        SELECT TOP 10000 g.uid
        FROM material_transition_material mtm
        JOIN goo g ON g.uid = mtm.end_point
        WHERE NOT EXISTS (
            SELECT * FROM m_upstream us WHERE us.start_point = mtm.end_point
        )
        ORDER BY g.added_on DESC
    ) d
    UNION (
        SELECT DISTINCT TOP 10000 uid
        FROM goo
        WHERE NOT EXISTS (
            SELECT 1 FROM m_upstream WHERE uid = start_point
        )
     )

     INSERT INTO m_upstream (start_point, end_point, path, level)
      SELECT start_point, end_point, path, level FROM McGetUpStreamByList(@UsGooUids)

  END

