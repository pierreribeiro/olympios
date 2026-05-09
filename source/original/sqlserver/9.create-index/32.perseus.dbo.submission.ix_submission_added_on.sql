USE [perseus]
GO
            
CREATE NONCLUSTERED INDEX [ix_submission_added_on]
    ON [dbo].[submission] ([added_on] ASC)
    WITH (FILLFACTOR = 90);

