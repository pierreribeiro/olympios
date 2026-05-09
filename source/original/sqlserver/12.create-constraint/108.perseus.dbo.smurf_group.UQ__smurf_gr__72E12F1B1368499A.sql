USE [perseus]
GO
            
ALTER TABLE [dbo].[smurf_group]
ADD CONSTRAINT [UQ__smurf_gr__72E12F1B1368499A] UNIQUE NONCLUSTERED ([name]);

