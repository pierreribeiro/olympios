EXEC msdb.dbo.sp_add_job
    @job_name = N'(Perseus) reconcile mupstream',
    @enabled = 1,
    @description = N'Job Enable/Disable upon primary node',
    @start_step_id = 1,
    @category_name = N'Application Background Processing',
    @notify_level_eventlog = 0,
    @notify_level_email = 0,
    @notify_level_netsend = 0,
    @notify_level_page = 0,
    @delete_level = 0;

