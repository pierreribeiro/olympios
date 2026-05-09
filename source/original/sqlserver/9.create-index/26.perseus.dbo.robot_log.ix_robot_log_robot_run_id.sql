USE [perseus]
GO
            
CREATE NONCLUSTERED INDEX [ix_robot_log_robot_run_id]
    ON [dbo].[robot_log] ([robot_run_id] ASC)
    WITH (FILLFACTOR = 90);

