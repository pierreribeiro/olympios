EXEC msdb.dbo.sp_delete_job
    @job_name = N'(Perseus) reconcile mupstream',
    @delete_unused_schedule = 0;

