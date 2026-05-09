USE [perseus]
GO
            
CREATE UNIQUE NONCLUSTERED INDEX [uniq_goo_uid]
    ON [dbo].[goo] ([uid] ASC)
    WITH (FILLFACTOR = 90);

