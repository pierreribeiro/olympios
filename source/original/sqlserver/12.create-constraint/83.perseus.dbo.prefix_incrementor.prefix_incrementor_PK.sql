USE [perseus]
GO
            
ALTER TABLE [dbo].[prefix_incrementor]
ADD CONSTRAINT [prefix_incrementor_PK] PRIMARY KEY CLUSTERED ([prefix]);

