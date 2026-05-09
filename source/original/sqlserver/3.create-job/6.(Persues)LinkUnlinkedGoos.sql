EXEC msdb.dbo.sp_add_job
    @job_name = N'(Persues) Link Unlinked Goos',
    @enabled = 1,
    @description = N'Job Enable/Disable upon primary node',
    @start_step_id = 1,
    @category_name = N'[Uncategorized (Local)]',
    @notify_level_eventlog = 0,
    @notify_level_email = 2,
    @notify_level_netsend = 0,
    @notify_level_page = 0,
    @notify_email_operator_name = N'Perseus Log Watchers',
    @delete_level = 0;

