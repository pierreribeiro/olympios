USE [perseus]
GO
            
CREATE PROCEDURE [dbo].[LinkUnlinkedMaterials] AS
   BEGIN

      DECLARE c CURSOR READ_ONLY FAST_FORWARD FOR
          SELECT uid 
            FROM goo 
           WHERE NOT EXISTS 
             (SELECT 1 
                FROM m_upstream
               WHERE uid = start_point)
       
       DECLARE @material_uid nvarchar(50);
       OPEN c
       FETCH NEXT FROM c INTO @material_uid
       WHILE (@@FETCH_STATUS = 0)
       BEGIN
	       BEGIN TRY 
		      INSERT INTO m_upstream (start_point, end_point, level, path) 
                  SELECT start_point, end_point, level, path FROM McGetUpStream(@material_uid)
           END TRY
		   BEGIN CATCH
		      -- ignore errors
		   END CATCH
		   FETCH NEXT FROM c INTO @material_uid
       END
       CLOSE c
       DEALLOCATE c
    END

