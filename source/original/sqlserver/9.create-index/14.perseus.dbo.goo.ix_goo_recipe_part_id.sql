USE [perseus]
GO
            
CREATE NONCLUSTERED INDEX [ix_goo_recipe_part_id]
    ON [dbo].[goo] ([recipe_part_id] ASC);

