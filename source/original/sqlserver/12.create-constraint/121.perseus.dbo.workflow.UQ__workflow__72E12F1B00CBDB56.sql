USE [perseus]
GO
            
ALTER TABLE [dbo].[workflow]
ADD CONSTRAINT [UQ__workflow__72E12F1B00CBDB56] UNIQUE NONCLUSTERED ([name]);

