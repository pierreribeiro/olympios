EXEC msdb.dbo.sp_add_jobstep
    @job_name = N'(Persues) Link Unlinked Goos',
    @step_name = N'Run The Stored Procedure',
    @step_id = 2,
    @subsystem = N'TSQL',
    @command = N'   BEGIN

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
    END',
    @additional_parameters = N'',
    @cmdexec_success_code = 0,
    @on_success_action = 1,
    @on_success_step_id = 0,
    @on_fail_action = 2,
    @on_fail_step_id = 0,
    @database_name = N'perseus',
    @retry_attempts = 0,
    @retry_interval = 0,
    @os_run_priority = 0,
    @flags = 0,
    @proxy_name = N'';

