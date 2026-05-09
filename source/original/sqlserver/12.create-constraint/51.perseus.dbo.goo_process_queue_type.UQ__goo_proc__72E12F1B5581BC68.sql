USE [perseus]
GO
            
ALTER TABLE [dbo].[goo_process_queue_type]
ADD CONSTRAINT [UQ__goo_proc__72E12F1B5581BC68] UNIQUE NONCLUSTERED ([name]);

