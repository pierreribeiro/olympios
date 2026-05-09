EXEC msdb.dbo.sp_delete_job
    @job_name = N'(Perseus) Import Common Users',
    @delete_unused_schedule = 0;

