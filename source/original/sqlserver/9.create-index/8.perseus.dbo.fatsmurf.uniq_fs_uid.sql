USE [perseus]
GO
            
CREATE UNIQUE NONCLUSTERED INDEX [uniq_fs_uid]
    ON [dbo].[fatsmurf] ([uid] ASC)
    WITH (FILLFACTOR = 70);

