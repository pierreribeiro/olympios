USE [perseus]
GO
            
ALTER TABLE [dbo].[field_map]
ADD CONSTRAINT [combined_field_map_FK_1] FOREIGN KEY ([field_map_block_id]) 
REFERENCES [dbo].[field_map_block] ([id]);

