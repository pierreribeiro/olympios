EXEC msdb.dbo.sp_delete_job
    @job_name = N'Persues_Tables_count',
    @delete_unused_schedule = 0;

