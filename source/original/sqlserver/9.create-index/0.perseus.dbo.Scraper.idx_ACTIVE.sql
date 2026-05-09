USE [perseus]
GO
            
CREATE NONCLUSTERED INDEX [idx_ACTIVE]
    ON [dbo].[Scraper] ([Active] ASC);

