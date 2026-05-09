USE [perseus]
GO
            
CREATE FUNCTION initCaps (@sInitCaps varchar(8000))
RETURNS varchar(8000)
AS
BEGIN

DECLARE @nNumSpaces int,
	@sParseString varchar(8000),
	@sParsedString varchar(8000)

SELECT @nNumSpaces = (LEN(@sInitCaps) - LEN(REPLACE(@sInitCaps, ' ', '')))+1

SELECT @sInitCaps = REPLACE(@sInitCaps, ' ', '%')

WHILE @nNumSpaces > 0
BEGIN

	IF (CHARINDEX('%', @sInitCaps) <> 0)
	BEGIN
		SELECT @sParseString = SUBSTRING(@sInitCaps, 1, CHARINDEX('%',@sInitCaps))
		SELECT @sInitCaps = SUBSTRING(@sInitCaps, (CHARINDEX('%', @sInitCaps)+1), LEN(@sInitCaps))
		SELECT @nNumSpaces = @nNumSpaces - 1

	END
	ELSE
	BEGIN
		SELECT @nNumSpaces = @nNumSpaces - 1
		SELECT @sParseString = @sInitCaps
	END

	SELECT @sParsedString = REPLACE(ISNULL(@sParsedString, '') + CASE WHEN LEN(@sParseString) = 1 THEN UPPER(@sParseString)
								ELSE UPPER(SUBSTRING(@sParseString, 1, 1)) + LOWER(SUBSTRING(@sParseString, 2, LEN(@sParseString)))
								END, '%', ' ')
END

RETURN(@sParsedString)
END

