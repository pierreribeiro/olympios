USE [perseus]
GO
            
ALTER TABLE [dbo].[workflow_step]
ADD CONSTRAINT [workflow_step_unit_FK_1] FOREIGN KEY ([goo_amount_unit_id]) 
REFERENCES [dbo].[unit] ([id]);

