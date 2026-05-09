USE [perseus]
GO
            
ALTER TABLE [dbo].[field_map]
ADD CONSTRAINT [combined_field_map_PK] PRIMARY KEY CLUSTERED ([id]);

