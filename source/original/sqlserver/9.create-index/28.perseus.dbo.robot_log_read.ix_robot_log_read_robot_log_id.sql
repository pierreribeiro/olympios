USE [perseus]
GO
            
CREATE NONCLUSTERED INDEX [ix_robot_log_read_robot_log_id]
    ON [dbo].[robot_log_read] ([robot_log_id] ASC)
    WITH (FILLFACTOR = 90);

