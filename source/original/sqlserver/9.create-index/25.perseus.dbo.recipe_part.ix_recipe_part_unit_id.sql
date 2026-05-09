USE [perseus]
GO
            
CREATE NONCLUSTERED INDEX [ix_recipe_part_unit_id]
    ON [dbo].[recipe_part] ([unit_id] ASC)
    WITH (FILLFACTOR = 90);

