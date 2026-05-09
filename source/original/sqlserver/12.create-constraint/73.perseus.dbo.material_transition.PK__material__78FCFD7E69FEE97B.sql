USE [perseus]
GO
            
ALTER TABLE [dbo].[material_transition]
ADD CONSTRAINT [PK__material__78FCFD7E69FEE97B] PRIMARY KEY CLUSTERED ([material_id], [transition_id]);

