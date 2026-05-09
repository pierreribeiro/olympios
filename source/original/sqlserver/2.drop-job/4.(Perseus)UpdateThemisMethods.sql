EXEC msdb.dbo.sp_delete_job
    @job_name = N'(Perseus) Update Themis Methods',
    @delete_unused_schedule = 0;

