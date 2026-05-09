USE [perseus]
GO
            
CREATE UNIQUE NONCLUSTERED INDEX [uix_unit_name]
    ON [dbo].[unit] ([name] ASC);

