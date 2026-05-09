USE [perseus]
GO
            
ALTER TABLE [dbo].[transition_material]
ADD CONSTRAINT [PK__transiti__A691E4B26DCF7A5F] PRIMARY KEY CLUSTERED ([transition_id], [material_id]);

