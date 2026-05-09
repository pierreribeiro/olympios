USE [perseus]
GO
            
ALTER TABLE [dbo].[perseus_user]
ADD CONSTRAINT [FK__perseus_u__manuf__6001494C] FOREIGN KEY ([manufacturer_id]) 
REFERENCES [dbo].[manufacturer] ([id]);

