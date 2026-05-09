USE [perseus]
GO
            
CREATE FUNCTION GetTransferCombos (@pRobotLog INT, @pRobotRun INT)

RETURNS @lResult TABLE (SourcePlate VARCHAR(50), DestinationPlate VARCHAR(50), MinRow INT, MaxRow INT, Loaded INT)
AS

BEGIN
	DECLARE 
	@SourcePlate VARCHAR(50),
	@DestinationPlate VARCHAR(50),
	@LastSourcePlate VARCHAR(50) = '0',
	@LastDestinationPlate VARCHAR(50) = '0',
	@RowNumber INT,
	@Loaded INT,
	@AlreadyUsed INT = 0
	
	DECLARE @UsedCombos TABLE (SourcePlate VARCHAR(50), DestinationPlate VARCHAR(50))
	DECLARE @Listing TABLE (Id INT, SourcePlate VARCHAR(50), DestinationPlate VARCHAR(50), Loaded INT)

	IF @pRobotLog IS NOT NULL
	BEGIN
		INSERT INTO @Listing
		SELECT rlt.id, source_barcode, destination_barcode, CASE WHEN rl.loadable = 1 OR rl.loaded = 1 THEN 1 ELSE 0 END
		FROM robot_log_transfer rlt
		JOIN robot_log rl ON rl.id = rlt.robot_log_id
		WHERE rl.id = @pRobotLog
		AND source_barcode IS NOT NULL 
		AND destination_barcode IS NOT NULL
		AND LTRIM(source_barcode) != ''
		AND LTRIM(destination_barcode) != ''
		ORDER BY id
	END
	ELSE
	BEGIN
		INSERT INTO @Listing
		SELECT rlt.id, source_barcode, destination_barcode, CASE WHEN rl.loadable = 1 OR rl.loaded = 1 THEN 1 ELSE 0 END
		FROM robot_log_transfer rlt
		JOIN robot_log rl ON rl.id = rlt.robot_log_id
		WHERE rl.id IN (SELECT id FROM robot_log WHERE robot_run_id = @pRobotRun)
		AND source_barcode IS NOT NULL 
		AND destination_barcode IS NOT NULL
		AND LTRIM(source_barcode) != ''
		AND LTRIM(destination_barcode) != ''
		ORDER BY id
	END
	
	DECLARE CUR CURSOR FOR 
	SELECT Id, SourcePlate, DestinationPlate, Loaded FROM @Listing 

	OPEN CUR

	FETCH NEXT FROM CUR INTO @RowNumber, @SourcePlate, @DestinationPlate, @Loaded
	
	WHILE @@FETCH_STATUS = 0  
	BEGIN  
	
		SELECT @AlreadyUsed = COUNT(*) FROM @UsedCombos
		WHERE SourcePlate = @SourcePlate
		AND DestinationPlate = @DestinationPlate
		
		IF @LastSourcePlate != @SourcePlate OR @LastDestinationPlate != @DestinationPlate OR @AlreadyUsed > 0
		BEGIN					
			UPDATE @lResult SET MaxRow = @RowNumber - 1
			WHERE MaxRow IS NULL
			
			DELETE FROM @UsedCombos WHERE SourcePlate = @SourcePlate AND DestinationPlate = @DestinationPlate
			
			INSERT INTO @lResult (SourcePlate, DestinationPlate, MinRow, Loaded)
			VALUES (@SourcePlate, @DestinationPlate, @RowNumber, @Loaded)
		END	
						
		INSERT INTO @UsedCombos (SourcePlate, DestinationPlate)
		VALUES (@SourcePlate, @DestinationPlate)
					
		SET @LastSourcePlate = @SourcePlate
		SET @LastDestinationPlate = @DestinationPlate
				
		FETCH NEXT FROM CUR INTO @RowNumber, @SourcePlate, @DestinationPlate, @Loaded
	END  

	CLOSE CUR
	DEALLOCATE CUR
	
	UPDATE @lResult SET MaxRow = @RowNumber
	WHERE MaxRow IS NULL

	RETURN 
END

