USE [perseus]
GO
            
-- DROP PROCEDURE [dbo].[ProcessDirtyTrees]
CREATE PROCEDURE [dbo].[ProcessDirtyTrees]
AS


  -- not sure where declared, but it's what McGetUpStreamByList expects
  -- embedding the recursive query, or a call directory to the view upstream
  -- from within the proc doesn't work, for reasons are presently unclear to
  -- me -dolan 2015-08-07
  DECLARE @dirty GooList
  DECLARE @to_process GooList
  DECLARE @clean GooList
  DECLARE @add_rows Int
  DECLARE @rem_rows Int
  DECLARE @dirty_count Int
  DECLARE @start_time datetime
  DECLARE @duration Int
  DECLARE @current Varchar(100)

  BEGIN TRY
    BEGIN TRANSACTION
      SELECT @start_time = GETDATE()
      INSERT INTO @dirty
        SELECT distinct material_uid AS uid FROM m_upstream_dirty_leaves

      INSERT INTO @clean VALUES ('n/a')

      SELECT @dirty_count = COUNT(*) FROM @dirty;
      SELECT @duration = 0
      WHILE (@dirty_count > 0 AND @duration < 4000)
      BEGIN
        INSERT INTO @to_process
          SELECT DISTINCT TOP 1 * FROM @dirty
        
		SET @current = (SELECT TOP 1 * FROM @dirty)
        INSERT @clean EXEC ProcessSomeMUpstream @to_process, @clean
        DELETE d FROM @dirty d WHERE EXISTS (
          SELECT 1 FROM @clean c WHERE c.uid=d.uid )
        SELECT @dirty_count = COUNT(*) FROM @dirty;
        SELECT @duration = DATEDIFF(ms, @start_time, GETDATE())
      END

      DELETE d FROM m_upstream_dirty_leaves d WHERE EXISTS (
        SELECT 1 FROM @clean c WHERE c.uid = d.material_uid )
    COMMIT TRANSACTION
  END TRY
  BEGIN CATCH
    DECLARE @ErrorMessage NVARCHAR(MAX), @ErrorSeverity INT, @ErrorState INT
    SELECT @ErrorMessage =
        ERROR_MESSAGE() + ' Line ' + CAST(ERROR_LINE() AS NVARCHAR(5)) + '.  Possible culprint: ' + @current,
        @ErrorSeverity = ERROR_SEVERITY(),
        @ErrorState = ERROR_STATE()
    ROLLBACK TRANSACTION
    RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState)
  END CATCH

