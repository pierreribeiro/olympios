USE [perseus]
GO
            
ALTER TABLE [dbo].[goo_type]
ADD CONSTRAINT [UQ__goo_type__72E12F1B00551192] UNIQUE NONCLUSTERED ([name]);

