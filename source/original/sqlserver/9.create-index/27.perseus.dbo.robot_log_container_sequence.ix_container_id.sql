USE [perseus]
GO
            
CREATE NONCLUSTERED INDEX [ix_container_id]
    ON [dbo].[robot_log_container_sequence] ([container_id] ASC)
    WITH (FILLFACTOR = 100);

