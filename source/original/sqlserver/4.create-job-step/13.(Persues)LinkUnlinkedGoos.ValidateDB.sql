EXEC msdb.dbo.sp_add_jobstep
    @job_name = N'(Persues) Link Unlinked Goos',
    @step_name = N'Validate DB',
    @step_id = 1,
    @subsystem = N'TSQL',
    @command = N'IF (SELECT TOP 1
        
	UPPER(ars.role_desc)
    
	FROM sys.dm_hadr_availability_replica_states ars
    
	INNER JOIN sys.availability_groups ag
 ON ars.group_id = ag.group_id

	WHERE ag.name = 'SEApps'
 AND ars.is_local = 1) <> 'PRIMARY'

BEGIN
    
	;THROW 51000, 'This is not the Primary Server', 1;

END',
    @additional_parameters = N'',
    @cmdexec_success_code = 0,
    @on_success_action = 3,
    @on_success_step_id = 0,
    @on_fail_action = 1,
    @on_fail_step_id = 0,
    @database_name = N'master',
    @retry_attempts = 0,
    @retry_interval = 0,
    @os_run_priority = 0,
    @flags = 0,
    @proxy_name = N'';

