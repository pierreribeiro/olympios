EXEC msdb.dbo.sp_add_schedule
    @schedule_name = N'Perseus records counts',
    @enabled = 1,
    @freq_type = 4,
    @freq_interval = 1,
    @freq_subday_type = 8,
    @freq_subday_interval = 1,
    @freq_recurrence_factor = 0,
    @active_start_date = 20200529,
    @active_end_date = 99991231,
    @active_start_time = 1500,
    @active_end_time = 235959;

