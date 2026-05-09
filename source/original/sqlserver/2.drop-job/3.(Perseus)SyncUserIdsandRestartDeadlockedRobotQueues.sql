EXEC msdb.dbo.sp_delete_job
    @job_name = N'(Perseus) Sync User Ids and Restart Deadlocked Robot Queues',
    @delete_unused_schedule = 0;

