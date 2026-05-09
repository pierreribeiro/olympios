EXEC msdb.dbo.sp_delete_job
    @job_name = N'Statistics updates for m_upstream(perseus_db) table',
    @delete_unused_schedule = 0;

