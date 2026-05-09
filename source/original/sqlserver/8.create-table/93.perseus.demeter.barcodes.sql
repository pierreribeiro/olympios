USE [perseus]
GO
            
CREATE TABLE [demeter].[barcodes](
[id] int IDENTITY(1, 1) NOT NULL,
[barcode] varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[seedvial_id] int NOT NULL
)
ON [PRIMARY];

