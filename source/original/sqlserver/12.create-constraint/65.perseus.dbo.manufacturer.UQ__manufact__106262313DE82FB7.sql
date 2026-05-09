USE [perseus]
GO
            
ALTER TABLE [dbo].[manufacturer]
ADD CONSTRAINT [UQ__manufact__106262313DE82FB7] UNIQUE NONCLUSTERED ([name], [location]);

