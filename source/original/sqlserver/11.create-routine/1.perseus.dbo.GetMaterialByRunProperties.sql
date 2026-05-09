USE [perseus]
GO
            
CREATE PROC GetMaterialByRunProperties @RunId VARCHAR(25), @HourTimePoint DECIMAL(10,5)
AS
BEGIN

	DECLARE @CreatorId INT
	DECLARE @SecondTimePoint INT
	DECLARE @OriginalGoo VARCHAR(50)
	DECLARE @StartTime DATETIME
	DECLARE @TimePointGoo VARCHAR(50)
	DECLARE @MaxGooIdentifier INT
	DECLARE @MaxFsIdentifier INT
	DECLARE @Split VARCHAR(50)
	
	SET @SecondTimePoint = @HourTimePoint * 60 * 60

	SELECT 
	@CreatorId = g.added_by,
	@OriginalGoo = g.uid,
	@StartTime = r.start_time
	FROM hermes.run r
	JOIN goo g ON g.uid = r.resultant_material
	WHERE CAST(r.experiment_id AS VARCHAR(10)) + '-' + CAST(r.local_id AS VARCHAR(5)) = @RunId
	
	IF @OriginalGoo IS NOT NULL
	BEGIN

		SELECT @TimePointGoo = REPLACE(g.uid,'m','')
		FROM dbo.McGetDownStream(@OriginalGoo) d
		JOIN goo g ON d.end_point = g.uid
		WHERE g.added_on = DATEADD(SS, @SecondTimePoint, @StartTime)
		AND g.goo_type_id = 9
		
		IF @TimePointGoo IS NULL
		BEGIN
			SELECT @MaxGooIdentifier = MAX(CAST(SUBSTRING(uid, 2, 100) AS INT)) + 1 FROM goo WHERE uid LIKE 'm%'
			SELECT @MaxFsIdentifier = MAX(CAST(SUBSTRING(uid, 2, 100) AS INT)) + 1 FROM fatsmurf WHERE uid LIKE 's%'
			
			SET @TimePointGoo = 'm' + CAST(@MaxGooIdentifier AS VARCHAR(49))
			SET @Split = 's' + CAST(@MaxFsIdentifier AS VARCHAR(49))
		
			INSERT INTO goo (uid, name, original_volume, added_on, added_by, goo_type_id)
			VALUES (@TimePointGoo, 'Sample TP: ' + CAST(@HourTimePoint AS VARCHAR(10)), .00001, DATEADD(SS, @SecondTimePoint, @StartTime), @CreatorId, 9)

			INSERT INTO fatsmurf (uid, added_on, added_by, smurf_id, run_on) VALUES
			(@Split, GETDATE(), @CreatorId, 110, DATEADD(SS, @SecondTimePoint, @StartTime))
			
			EXEC MaterialToTransition @OriginalGoo, @Split
			EXEC TransitionToMaterial @Split, @TimePointGoo
			
		END
		
	END
	
	RETURN CAST(REPLACE(@TimePointGoo, 'm', '') AS INT)
END

