USE [perseus]
GO
            
CREATE NONCLUSTERED INDEX [ix_goo_recipe_id]
    ON [dbo].[goo] ([recipe_id] ASC)
    WITH (FILLFACTOR = 90);

