USE [perseus]
GO
            
CREATE PROCEDURE [dbo].[ReconcileMUpstream]
AS

  DECLARE @OldUpstream TABLE(
                       start_point VARCHAR(50),
                       end_point VARCHAR(50),
                       path VARCHAR(500),
                       level INT,
                       PRIMARY KEY (start_point, end_point, path))

  DECLARE @NewUpstream TABLE(
                       start_point VARCHAR(50),
                       end_point VARCHAR(50),
                       path VARCHAR(500),
                       level INT,
                       PRIMARY KEY (start_point, end_point, path))

  DECLARE @AddUpstream TABLE(
                       start_point VARCHAR(50),
                       end_point VARCHAR(50),
                       path VARCHAR(500),
                       level INT,
                       PRIMARY KEY (start_point, end_point, path))

  DECLARE @RemUpstream TABLE (
                       start_point VARCHAR(50),
                       end_point VARCHAR(50),
                       path VARCHAR(500),
                       level INT,
                       PRIMARY KEY (start_point, end_point, path))

  -- not sure where declared, but it's what McGetUpStreamByList expects
  -- embedding the recursive query, or a call directory to the view upstream
  -- from within the proc doesn't work, for reasons are presently unclear to
  -- me -dolan 2015-08-07
  DECLARE @dirty GooList;
  DECLARE @add_rows Int;
  DECLARE @rem_rows Int;
  DECLARE @dirty_count Int;

  BEGIN TRY
    BEGIN TRANSACTION
      INSERT INTO @dirty
        SELECT DISTINCT TOP 10 material_uid AS uid FROM m_upstream_dirty_leaves
          WHERE material_uid != 'n/a'

      INSERT INTO @dirty
         SELECT DISTINCT start_point AS uid FROM m_upstream mu
           WHERE EXISTS (
             SELECT 1 FROM @dirty dl WHERE dl.uid = mu.end_point ) 
           AND NOT EXISTS (SELECT 1 FROM @dirty dl1 WHERE dl1.uid = mu.start_point )
           AND start_point != 'n/a'

      SELECT @dirty_count = COUNT(*) FROM @dirty
      IF @dirty_count > 0
      BEGIN
        DELETE FROM m_upstream_dirty_leaves WHERE EXISTS
         (SELECT 1 FROM @dirty d WHERE d.uid = m_upstream_dirty_leaves.material_uid)

        INSERT INTO @OldUpstream (start_point, end_point, path, level)
          SELECT start_point, end_point, path, level
            FROM m_upstream
            JOIN @dirty d ON d.uid = m_upstream.start_point

        INSERT INTO @NewUpstream
          SELECT start_point, end_point, path, level
            FROM dbo.McGetUpStreamByList(@dirty)

        /** determine what, if any inserts are needed **/
        INSERT INTO @AddUpstream (start_point, end_point, path, level)
          SELECT start_point, end_point, path, level
            FROM @NewUpstream n
           WHERE NOT EXISTS
          (SELECT 1 FROM @OldUpstream f
            WHERE f.start_point = n.start_point
              AND f.end_point = n.end_point
              AND f.path = n.path)

        /** Delete Obsolete Rows.  This (hopefully) serves to check
            for deletes before unnecessarily locking the table.
         **/
        INSERT INTO @RemUpstream (start_point, end_point, path, level)
          SELECT start_point, end_point, path, level
            FROM @OldUpstream o
           WHERE NOT EXISTS(
            SELECT 1 FROM @NewUpstream n
             WHERE n.start_point = o.start_point
               AND n.end_point = o.end_point
               AND n.path = o.path);

        SELECT @add_rows = COUNT(*) FROM @AddUpstream
        SELECT @rem_rows = COUNT(*) FROM @RemUpstream

        IF @add_rows > 0
        BEGIN
            /** Insert New Rows **/
            INSERT INTO m_upstream (start_point, end_point, path, level)
                SELECT start_point, end_point, path, level FROM @AddUpstream
        END

        IF @rem_rows > 0
        BEGIN
           /** Delete Obsolete Rows **/
           DELETE FROM m_upstream
             WHERE start_point IN (SELECT uid FROM @dirty)
               AND NOT EXISTS(
               SELECT 1 FROM @NewUpstream f
                WHERE f.start_point = m_upstream.start_point
                  AND f.end_point = m_upstream.end_point
                  AND f.path = m_upstream.path)
        END

      END
    COMMIT TRANSACTION
  END TRY
  BEGIN CATCH
    DECLARE @ErrorMessage NVARCHAR(MAX), @ErrorSeverity INT, @ErrorState INT
    SELECT @ErrorMessage =
        ERROR_MESSAGE() + ' Line ' + CAST(ERROR_LINE() AS NVARCHAR(5)),
        @ErrorSeverity = ERROR_SEVERITY(),
        @ErrorState = ERROR_STATE()
    ROLLBACK TRANSACTION
    RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState)
  END CATCH

