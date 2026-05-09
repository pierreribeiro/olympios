USE [perseus]
GO
            
CREATE NONCLUSTERED INDEX [ix_fatsmurf_id]
    ON [dbo].[fatsmurf_history] ([fatsmurf_id] ASC)
    WITH (FILLFACTOR = 70);

