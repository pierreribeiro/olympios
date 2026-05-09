EXEC msdb.dbo.sp_add_jobstep
    @job_name = N'(Perseus) Clean Up Old Searches',
    @step_name = N'Clear Searches',
    @step_id = 1,
    @subsystem = N'TSQL',
    @command = N'/*
Clear old searches
 */

SET DEADLOCK_PRIORITY LOW ;
GO

RETRY:                                                              /* Label Retry */

BEGIN TRY
      BEGIN TRANSACTION

          ALTER TABLE fatsmurf_search_result NOCHECK CONSTRAINT ALL
          TRUNCATE TABLE  fatsmurf_search_result
          DBCC CHECKIDENT ('fatsmurf_search_result', RESEED, 0)
          ALTER TABLE fatsmurf_search_result WITH CHECK CHECK CONSTRAINT ALL

      COMMIT TRANSACTION
END TRY

BEGIN CATCH

  ROLLBACK TRANSACTION
  IF ERROR_NUMBER() = 1205      /* Deadlock Error Number*/
	
        BEGIN           
               WAITFOR DELAY '00:00:00.05'     /* Wait for 5 ms*/
               GOTO RETRY               /* Go to Label RETRY*/
        END

END CATCH

',
    @additional_parameters = N'',
    @cmdexec_success_code = 0,
    @on_success_action = 3,
    @on_success_step_id = 0,
    @on_fail_action = 2,
    @on_fail_step_id = 0,
    @database_name = N'perseus',
    @retry_attempts = 0,
    @retry_interval = 0,
    @os_run_priority = 0,
    @flags = 0,
    @proxy_name = N'';

