USE [perseus]
GO
            
CREATE NONCLUSTERED INDEX [ix_fatsmurf_container_id]
    ON [dbo].[fatsmurf] ([container_id] ASC)
    WITH (FILLFACTOR = 90);

