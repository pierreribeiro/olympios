USE [perseus]
GO
            
CREATE NONCLUSTERED INDEX [ix_goo_id]
    ON [dbo].[goo_history] ([goo_id] ASC)
    WITH (FILLFACTOR = 70);

