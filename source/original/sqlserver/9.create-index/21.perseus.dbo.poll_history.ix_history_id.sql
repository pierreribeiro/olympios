USE [perseus]
GO
            
CREATE NONCLUSTERED INDEX [ix_history_id]
    ON [dbo].[poll_history] ([poll_id] ASC)
INCLUDE ([history_id])
    WITH (FILLFACTOR = 70);

