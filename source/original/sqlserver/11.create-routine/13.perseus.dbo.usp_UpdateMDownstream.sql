USE [perseus]
GO
            
CREATE PROCEDURE dbo.usp_UpdateMDownstream
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

  DECLARE @DsGooUids GooList

  BEGIN TRANSACTION
  INSERT INTO @DsGooUids
    SELECT DISTINCT uid FROM (
      SELECT TOP 500 g.uid
        FROM material_transition_material mtm
        JOIN goo g ON g.uid = mtm.start_point
       WHERE NOT EXISTS (
         SELECT * FROM m_downstream us WHERE us.start_point = mtm.start_point)
       ORDER BY g.added_on DESC
    ) d


  INSERT INTO m_downstream (start_point, end_point, path, level)
    SELECT start_point, end_point, path, level
      FROM McGetDownStreamByList(@DsGooUids)

   COMMIT
   BEGIN TRANSACTION
    -- create paths to newly created downstream items that wouldn't
    -- be caught by the above, which only creates new downstream items
    -- where the upstream doesn't exist.
    INSERT INTO m_downstream(start_point, end_point, path, level)
      SELECT TOP 500 end_point, start_point, dbo.ReversePath(path), level
        FROM m_upstream up
      WHERE NOT EXISTS (
        SELECT 1 FROM m_downstream down
        WHERE up.end_point = down.start_point
              AND up.start_point = down.end_point
              AND dbo.ReversePath(up.path) = down.path
          )

    COMMIT


END

