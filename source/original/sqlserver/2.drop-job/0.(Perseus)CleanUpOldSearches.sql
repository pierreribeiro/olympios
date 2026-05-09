EXEC msdb.dbo.sp_delete_job
    @job_name = N'(Perseus) Clean Up Old Searches',
    @delete_unused_schedule = 0;

