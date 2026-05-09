EXEC msdb.dbo.sp_add_job
    @job_name = N'Statistics updates for m_upstream(perseus_db) table',
    @enabled = 1,
    @description = N'No description available.',
    @start_step_id = 1,
    @category_name = N'[Uncategorized (Local)]',
    @notify_level_eventlog = 0,
    @notify_level_email = 0,
    @notify_level_netsend = 0,
    @notify_level_page = 0,
    @delete_level = 0;

