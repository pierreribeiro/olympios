USE [perseus]
GO
            
CREATE NONCLUSTERED INDEX [ix_fatsmurf_smurf_id]
    ON [dbo].[fatsmurf] ([smurf_id] ASC);

