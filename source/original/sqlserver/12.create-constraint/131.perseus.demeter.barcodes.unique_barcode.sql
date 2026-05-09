USE [perseus]
GO
            
ALTER TABLE [demeter].[barcodes]
ADD CONSTRAINT [unique_barcode] UNIQUE NONCLUSTERED ([barcode]);

