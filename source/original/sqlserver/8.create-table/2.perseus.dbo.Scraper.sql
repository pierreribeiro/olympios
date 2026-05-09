USE [perseus]
GO
            
CREATE TABLE [dbo].[Scraper](
[ID] int IDENTITY(1, 1) NOT NULL,
[Timestamp] datetime NULL,
[Message] nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FileType] char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Filename] nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FilenameSavedAs] nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ReceivedFrom] nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[File] varbinary(max) NULL,
[Result] nvarchar(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Complete] bit NULL,
[ScraperID] nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ScrapingStartedOn] datetime NULL,
[ScrapingFinishedOn] datetime NULL,
[ScrapingStatus] nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ScraperSendTo] nvarchar(max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ScraperMessage] nvarchar(max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Active] char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ControlFileID] int NULL,
[DocumentID] nvarchar(25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
)
ON [PRIMARY] TEXTIMAGE_ON [PRIMARY];

