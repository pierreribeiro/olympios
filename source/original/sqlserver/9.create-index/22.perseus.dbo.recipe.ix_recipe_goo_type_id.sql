USE [perseus]
GO
            
CREATE NONCLUSTERED INDEX [ix_recipe_goo_type_id]
    ON [dbo].[recipe] ([goo_type_id] ASC)
    WITH (FILLFACTOR = 90);

