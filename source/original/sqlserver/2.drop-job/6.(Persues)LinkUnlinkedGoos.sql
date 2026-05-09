EXEC msdb.dbo.sp_delete_job
    @job_name = N'(Persues) Link Unlinked Goos',
    @delete_unused_schedule = 0;

