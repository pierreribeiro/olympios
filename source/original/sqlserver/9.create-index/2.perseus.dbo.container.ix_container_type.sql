USE [perseus]
GO
            
CREATE NONCLUSTERED INDEX [ix_container_type]
    ON [dbo].[container] ([container_type_id] ASC)
INCLUDE ([id], [mass])
    WITH (FILLFACTOR = 70);

