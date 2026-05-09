EXEC msdb.dbo.sp_add_jobstep
    @job_name = N'(Perseus) reconcile mupstream',
    @step_name = N'reconcile some trees',
    @step_id = 2,
    @subsystem = N'TSQL',
    @command = N'exec perseus.dbo.ProcessDirtyTrees
',
    @additional_parameters = N'',
    @cmdexec_success_code = 0,
    @on_success_action = 1,
    @on_success_step_id = 0,
    @on_fail_action = 2,
    @on_fail_step_id = 0,
    @database_name = N'master',
    @retry_attempts = 0,
    @retry_interval = 0,
    @os_run_priority = 0,
    @flags = 0,
    @proxy_name = N'';

