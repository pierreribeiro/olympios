USE [perseus]
GO
            
CREATE NONCLUSTERED INDEX [ix_fsr_for_istd_view]
    ON [dbo].[fatsmurf_reading] ([fatsmurf_id] ASC)
INCLUDE ([id])
    WITH (FILLFACTOR = 70);

