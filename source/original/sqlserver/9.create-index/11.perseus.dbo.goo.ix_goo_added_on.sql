USE [perseus]
GO
            
CREATE NONCLUSTERED INDEX [ix_goo_added_on]
    ON [dbo].[goo] ([added_on] ASC)
INCLUDE ([uid], [container_id])
    WITH (FILLFACTOR = 90);

