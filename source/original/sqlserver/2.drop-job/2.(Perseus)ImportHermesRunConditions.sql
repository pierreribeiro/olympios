EXEC msdb.dbo.sp_delete_job
    @job_name = N'(Perseus) Import Hermes Run Conditions',
    @delete_unused_schedule = 0;

