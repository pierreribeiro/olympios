USE [perseus]
GO
            
ALTER TABLE [hermes].[run_condition]
ADD CONSTRAINT [UQ__run_cond__0BE79478308EFFF0] UNIQUE NONCLUSTERED ([condition_set_id], [master_condition_id]);

