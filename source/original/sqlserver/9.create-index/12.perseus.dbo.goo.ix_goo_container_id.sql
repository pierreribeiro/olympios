USE [perseus]
GO
            
CREATE NONCLUSTERED INDEX [ix_goo_container_id]
    ON [dbo].[goo] ([container_id] ASC);

