USE [perseus]
GO
            
CREATE NONCLUSTERED INDEX [ix_transition_material_material_id]
    ON [dbo].[transition_material] ([material_id] ASC);

