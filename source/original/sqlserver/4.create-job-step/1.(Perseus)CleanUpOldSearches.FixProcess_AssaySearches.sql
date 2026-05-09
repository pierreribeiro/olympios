EXEC msdb.dbo.sp_add_jobstep
    @job_name = N'(Perseus) Clean Up Old Searches',
    @step_name = N'Fix Process/Assay Searches',
    @step_id = 2,
    @subsystem = N'TSQL',
    @command = N'
/*
Fix Process/Assay Searches
 */


SET DEADLOCK_PRIORITY LOW ;
GO

RETRY:                                                                                          /*Label Retry*/

BEGIN TRY
BEGIN TRANSACTION
  DELETE FROM fatsmurf_search_result WHERE fatsmurf_search_id IN (1,2)

  WAITFOR DELAY '00:00:10' 

  INSERT INTO fatsmurf_search_result (fatsmurf_search_id, fatsmurf_id, added_on)
  SELECT s.class_id, fs.id, fs.added_on
    FROM smurf s WITH (NOLOCK)
    JOIN fatsmurf fs WITH (NOLOCK) ON fs.smurf_id = s.id

COMMIT TRANSACTION
END TRY

BEGIN CATCH

       ROLLBACK TRANSACTION
       IF ERROR_NUMBER() = 1205                                          /* Deadlock Error Number*/
	BEGIN
		WAITFOR DELAY '00:00:00.05'     /* Wait for 5 ms*/
		GOTO  RETRY                                   /* Go to Label RETRY*/
                     END
END CATCH

',
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

