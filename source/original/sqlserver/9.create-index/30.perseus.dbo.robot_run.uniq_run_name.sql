USE [perseus]
GO
            
CREATE UNIQUE NONCLUSTERED INDEX [uniq_run_name]
    ON [dbo].[robot_run] ([name] ASC)
    WITH (FILLFACTOR = 70);

