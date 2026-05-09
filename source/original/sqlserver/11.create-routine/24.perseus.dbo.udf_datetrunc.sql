USE [perseus]
GO
            
CREATE FUNCTION [dbo].[udf_datetrunc] (@Datein datetime)
    RETURNS Datetime
    AS BEGIN
    RETURN cast(floor(cast(@Datein as float)) as datetime);
    END

