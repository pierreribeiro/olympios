USE [perseus]
GO
            
CREATE NONCLUSTERED INDEX [ix_recipe_part_recipe_id]
    ON [dbo].[recipe_part] ([recipe_id] ASC)
    WITH (FILLFACTOR = 90);

