USE [perseus]
GO
            
IF  EXISTS (
SELECT * FROM [sys].[schemas] AS [schms]
WHERE [schms].[name] not in ('dbo','sys','INFORMATION_SCHEMA','guest')
AND schema_id < 16000
AND [schms].[name] = 'demeter')
DROP SCHEMA  [demeter];

