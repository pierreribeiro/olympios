USE [perseus]
GO
            
ALTER TABLE [dbo].[perseus_user]
ADD CONSTRAINT [FK__perseus_u__manuf__5B3C942F] FOREIGN KEY ([manufacturer_id]) 
REFERENCES [dbo].[manufacturer] ([id]);

