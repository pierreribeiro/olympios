EXEC msdb.dbo.sp_add_jobstep
    @job_name = N'Persues_Tables_count',
    @step_name = N'Perseus table counts',
    @step_id = 2,
    @subsystem = N'TSQL',
    @command = N'Insert into PerseusTableAndRowCounts SELECT T.name as TableName,i.Rows as NumberOfRows, CURRENT_TIMESTAMP AS updated_on
FROM        sys.tables T
JOIN        sys.sysindexes I ON T.OBJECT_ID = I.ID
WHERE       indid IN (0,1) and T.name In ('m_upstream','goo_search_result','scraper','m_downstream')
ORDER BY    i.Rows DESC,T.name
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

