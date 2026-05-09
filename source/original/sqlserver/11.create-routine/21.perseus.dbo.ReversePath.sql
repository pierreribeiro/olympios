USE [perseus]
GO
            
-- =============================================
-- Author:		Dolan
-- Create date: 7/14/2014
-- Description:	Given a path of format /uid/uid2/uid3/
--              reverse to /uid3/uid2/uid/.
--				Used to reverse mirror the m_ustream
--              table in m_downstream.
-- =============================================
CREATE FUNCTION dbo.ReversePath
(
    @source VARCHAR(MAX)
)
RETURNS VARCHAR(MAX)
AS
BEGIN
   DECLARE @dest varchar(MAX)
   SET @dest = ''
   IF LEN(@source) > 0
   BEGIN 
     -- chop off initial / (indexed by 1)
     SET @source = SUBSTRING(@source,2,LEN(@source))     
     WHILE LEN(@source) > 0
     BEGIN
       SET @dest = SUBSTRING(@source,0,CHARINDEX('/', @source)) + '/' + @dest
       SET @source = SUBSTRING(@source,CHARINDEX('/', @source)+1,LEN(@source))
     END
	 SET @dest = '/' + @dest
   END
   RETURN @dest
END

