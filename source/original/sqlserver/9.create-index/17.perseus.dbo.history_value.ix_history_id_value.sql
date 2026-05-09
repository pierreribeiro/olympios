USE [perseus]
GO
            
CREATE NONCLUSTERED INDEX [ix_history_id_value]
    ON [dbo].[history_value] ([history_id] ASC)
    WITH (FILLFACTOR = 70);

