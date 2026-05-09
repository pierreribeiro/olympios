USE [perseus]
GO
            
CREATE NONCLUSTERED INDEX [ix_recipe_part_goo_type_id]
    ON [dbo].[recipe_part] ([goo_type_id] ASC)
    WITH (FILLFACTOR = 90);

