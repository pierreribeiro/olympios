EXEC msdb.dbo.sp_add_jobstep
    @job_name = N'Statistics updates for m_upstream(perseus_db) table',
    @step_name = N'Statistics updates on m_upstream table',
    @step_id = 2,
    @subsystem = N'TSQL',
    @command = N'use perseus
Update STATISTICS dbo.m_upstream with fullscan',
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

