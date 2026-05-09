USE [perseus]
GO
            
CREATE NONCLUSTERED INDEX [IX_themis_sample_id]
    ON [dbo].[fatsmurf] ([themis_sample_id] ASC)
    WITH (FILLFACTOR = 90);

