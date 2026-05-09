USE [perseus]
GO
            
IF  EXISTS (
SELECT * FROM sys.objects WHERE object_id = OBJECT_ID (N'[dbo].[goo_type_combine_component]') AND 
type = N'U')
DROP TABLE [dbo].[goo_type_combine_component];

