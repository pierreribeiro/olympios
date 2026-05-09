USE [perseus]
GO
            
CREATE NONCLUSTERED INDEX [ix_fatsmurf_recipe_id]
    ON [dbo].[fatsmurf] ([smurf_id] ASC);

