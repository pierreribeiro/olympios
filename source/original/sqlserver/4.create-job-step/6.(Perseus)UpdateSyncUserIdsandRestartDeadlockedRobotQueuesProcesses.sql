EXEC msdb.dbo.sp_add_jobstep
    @job_name = N'(Perseus) Sync User Ids and Restart Deadlocked Robot Queues',
    @step_name = N'Update User Ids and Restart Deadlocked Robot Processes',
    @step_id = 2,
    @subsystem = N'TSQL',
    @command = N'/*
  (Perseus) Background Processing

Runs every 5 minutes.

Synchronizes perseus user ids with common user ids 
Restarts deadlocked logs.

*/
UPDATE pu
   SET pu.common_id = cmu.user_id
  FROM perseus_user pu
  JOIN cm_user cmu ON pu.domain_id = cmu.domain_id

DELETE FROM robot_log_error
 WHERE error_text LIKE '%deadlocked%'',
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

