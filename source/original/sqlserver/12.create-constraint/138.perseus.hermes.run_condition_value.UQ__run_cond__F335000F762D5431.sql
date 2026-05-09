USE [perseus]
GO
            
ALTER TABLE [hermes].[run_condition_value]
ADD CONSTRAINT [UQ__run_cond__F335000F762D5431] UNIQUE NONCLUSTERED ([run_id], [master_condition_id]);

