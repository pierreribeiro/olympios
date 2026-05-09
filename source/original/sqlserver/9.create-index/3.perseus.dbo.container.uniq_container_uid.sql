USE [perseus]
GO
            
CREATE UNIQUE NONCLUSTERED INDEX [uniq_container_uid]
    ON [dbo].[container] ([uid] ASC)
    WITH (FILLFACTOR = 90);

