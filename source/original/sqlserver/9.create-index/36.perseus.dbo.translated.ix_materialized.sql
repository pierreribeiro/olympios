USE [perseus]
GO
            
CREATE UNIQUE CLUSTERED INDEX [ix_materialized]
    ON [dbo].[translated] ([source_material] ASC, [destination_material] ASC, [transition_id] ASC)
    WITH (FILLFACTOR = 90);

