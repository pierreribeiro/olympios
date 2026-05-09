USE [perseus]
GO
            
CREATE FUNCTION GetReadCombos (@pRobotLog INT, @RobotRun INT)

RETURNS @lResult TABLE (SourcePlate VARCHAR(50), MinRow INT, MaxRow INT, Loaded INT)
AS

BEGIN
	DECLARE 
	@SourcePlate VARCHAR(50),
	@ReadIdentifier VARCHAR(50),
	@LastSourcePlate VARCHAR(50) = '0',
	@RowNumber INT,
	@AlreadyUsed INT = 0,
	@Loaded INT
	
	DECLARE @UsedCombos TABLE (SourcePlate VARCHAR(50), ReadIdentifier VARCHAR(50))
	DECLARE @Listing TABLE (Id INT, SourcePlate VARCHAR(50), ReadIdentifier VARCHAR(50), Loaded INT)

	IF @pRobotLog IS NOT NULL
	BEGIN
		INSERT INTO @Listing
		SELECT rlr.id, source_barcode, property_id, CASE WHEN rl.loadable = 1 OR rl.loaded = 1 THEN 1 ELSE 0 END
		FROM robot_log_read rlr
		JOIN robot_log rl ON rl.id = rlr.robot_log_id
		WHERE rl.id = @pRobotLog
		AND source_barcode IS NOT NULL 
		AND LTRIM(source_barcode) != ''
		ORDER BY id
	END
	ELSE
	BEGIN
		INSERT INTO @Listing
		SELECT rlr.id, source_barcode, property_id, CASE WHEN rl.loadable = 1 OR rl.loaded = 1 THEN 1 ELSE 0 END
		FROM robot_log_read rlr
		JOIN robot_log rl ON rl.id = rlr.robot_log_id
		WHERE rl.id IN (SELECT id FROM robot_log WHERE robot_run_id = @RobotRun)
		AND source_barcode IS NOT NULL 
		AND LTRIM(source_barcode) != ''
		ORDER BY id
	END

	DECLARE CUR CURSOR FOR 
	SELECT Id, SourcePlate, ReadIdentifier, Loaded FROM @Listing 
	
	OPEN CUR

	FETCH NEXT FROM CUR INTO @RowNumber, @SourcePlate, @ReadIdentifier, @Loaded
	
	WHILE @@FETCH_STATUS = 0  
	BEGIN  
		
		SELECT @AlreadyUsed = COUNT(*) FROM @UsedCombos
		WHERE SourcePlate = @SourcePlate
		AND ISNULL(ReadIdentifier, 0) = @ReadIdentifier
		
		IF @LastSourcePlate != @SourcePlate OR @AlreadyUsed > 0
		BEGIN					
			UPDATE @lResult SET MaxRow = @RowNumber - 1
			WHERE MaxRow IS NULL
			
			DELETE FROM @UsedCombos WHERE SourcePlate = @SourcePlate
			
			INSERT INTO @lResult (SourcePlate, MinRow, Loaded)
			VALUES (@SourcePlate, @RowNumber, @Loaded)
		END	
						
		INSERT INTO @UsedCombos (SourcePlate, ReadIdentifier)
		VALUES (@SourcePlate, @ReadIdentifier)
					
		SET @LastSourcePlate = @SourcePlate
				
		FETCH NEXT FROM CUR INTO @RowNumber, @SourcePlate, @ReadIdentifier, @Loaded
	END  

	CLOSE CUR
	DEALLOCATE CUR
	
	UPDATE @lResult SET MaxRow = @RowNumber
	WHERE MaxRow IS NULL

	RETURN 
END

