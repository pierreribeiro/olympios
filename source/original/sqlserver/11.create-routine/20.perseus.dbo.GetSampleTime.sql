USE [perseus]
GO
            
/*
 A faster version of sample time for perseus.
 Uses a recursive query to find the first parent that is a result of a fermentation.
 That's considered the "Sample".
 */

-- DROP FUNCTION [dbo].[GetSampleTime]
CREATE FUNCTION [dbo].[GetSampleTime](@StartPoint VARCHAR(50))
RETURNS VARCHAR(50)

AS BEGIN

  DECLARE @fermentation_uid VARCHAR(50);
  DECLARE @material_uid VARCHAR(50);
  DECLARE @sample_uid VARCHAR(50);
  DECLARE @result FLOAT;

  WITH upstream
  AS
  (
    SELECT mtm.source_uid,
           mtm.destination_uid,
           mtm.transition_uid,
           fs.smurf_id AS transition_type_id,
           1 AS level
      FROM dbo.vw_material_transition_material_up mtm
      JOIN fatsmurf fs ON fs.uid = mtm.transition_uid
       AND fs.smurf_id IN (110,111,22,365)
     WHERE mtm.destination_uid = @StartPoint

    UNION ALL

    SELECT mtm.source_uid,
           mtm.destination_uid,
           mtm.transition_uid,
           fs.smurf_id AS transition_type_id,
           r.level + 1
      FROM dbo.vw_material_transition_material_up mtm
      JOIN fatsmurf fs ON fs.uid = mtm.transition_uid
      JOIN upstream r ON r.source_uid = mtm.destination_uid
       AND fs.smurf_id IN (110,111,22,365)
  )
  SELECT TOP(1) @fermentation_uid = transition_uid,
                @material_uid = destination_uid
    FROM upstream WHERE transition_type_id = 22 ORDER BY level ASC;

  WITH upstream
  AS
  (
    SELECT mtm.source_uid,
           mtm.destination_uid,
           mtm.transition_uid,
           fs.smurf_id AS transition_type_id,
           1 AS level
      FROM dbo.vw_material_transition_material_up mtm
      JOIN fatsmurf fs ON fs.uid = mtm.transition_uid
       AND fs.smurf_id IN (110,111,365)
     WHERE mtm.destination_uid = @StartPoint

    UNION ALL

    SELECT mtm.source_uid,
           mtm.destination_uid,
           mtm.transition_uid,
           fs.smurf_id AS transition_type_id,
           r.level + 1
      FROM dbo.vw_material_transition_material_up mtm
      JOIN fatsmurf fs ON fs.uid = mtm.transition_uid
      JOIN upstream r ON r.source_uid = mtm.destination_uid
       AND fs.smurf_id IN (110,111,365)
  )
  SELECT TOP(1) @sample_uid = transition_uid
    FROM upstream WHERE transition_type_id = 365 ORDER BY level ASC;

  IF @sample_uid IS NOT NULL
  BEGIN
    SELECT @result = CAST(DATEDIFF(HOUR,
    ( SELECT transition.run_on FROM fatsmurf transition
           WHERE uid=@fermentation_uid),
        ( SELECT transition.run_on FROM fatsmurf transition
       WHERE uid=@sample_uid)
     ) AS FLOAT)
      FROM goo material
     WHERE material.uid = @material_uid
  END
  ELSE
  BEGIN
    SELECT @result = CAST(DATEDIFF(HOUR, (
          SELECT transition.run_on FROM fatsmurf transition
           WHERE uid=@fermentation_uid),
          material.added_on) AS FLOAT)
      FROM goo material
     WHERE material.uid = @material_uid
   END


   RETURN @result;
END

