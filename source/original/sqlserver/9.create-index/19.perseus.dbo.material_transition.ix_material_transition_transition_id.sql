USE [perseus]
GO
            
CREATE NONCLUSTERED INDEX [ix_material_transition_transition_id]
    ON [dbo].[material_transition] ([transition_id] ASC);

