USE [perseus]
GO
            
IF  EXISTS (
SELECT * FROM sys.types WHERE user_type_id = TYPE_ID(N'[dbo].[GooList]') AND  is_user_defined = 1)
DROP TYPE [dbo].[GooList];

