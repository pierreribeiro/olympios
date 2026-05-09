USE [perseus]
GO
            
ALTER TABLE [dbo].[cm_unit_compare]
ADD CONSTRAINT [PK_cm_unit_compare] PRIMARY KEY CLUSTERED ([from_unit_id], [to_unit_id]);

