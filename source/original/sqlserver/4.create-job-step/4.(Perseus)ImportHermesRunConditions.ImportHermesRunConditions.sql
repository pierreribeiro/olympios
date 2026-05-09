EXEC msdb.dbo.sp_add_jobstep
    @job_name = N'(Perseus) Import Hermes Run Conditions',
    @step_name = N'Import Hermes Run Conditions',
    @step_id = 2,
    @subsystem = N'TSQL',
    @command = N'SET QUOTED_IDENTIFIER ON


-- make sure all fermentations have a primary reading
-- todo: this is barbaric bullshit, all of this should go away.
INSERT INTO fatsmurf_reading (fatsmurf_id, name)
  SELECT fs.id,
         'Primary'
    FROM fatsmurf fs
   WHERE fs.smurf_id = 22
     AND
   NOT EXISTS(
      SELECT *
        FROM fatsmurf_reading fsr
       WHERE fsr.fatsmurf_id = fs.id);

-- create tmp table @RunConditions
DECLARE @RunConditions
  TABLE (uid VARCHAR(50),
         name VARCHAR(max),
         unit_id INT,
         value VARCHAR(2048),
         updated_on DATETIME)

-- populate it with values from the hermes run condition table
INSERT INTO @RunConditions
  SELECT 'H'+CAST(r.experiment_id AS VARCHAR(25)) + '-' + CAST(r.local_id AS VARCHAR(25)),
         rmc.name,
         u.id,
         ISNULL(rco.label, rcv.value),
         rcv.updated_on
    FROM hermes.run_condition_value rcv
    JOIN hermes.run r ON r.id = rcv.run_id
    JOIN hermes.run_master_condition rmc ON rmc.id = rcv.master_condition_id
  LEFT JOIN hermes.run_condition_option rco ON rco.master_condition_id = rmc.id AND rcv.value = rco.value
  LEFT JOIN unit u ON rmc.units = u.name
UNION
  SELECT 'H'+CAST(r.experiment_id AS VARCHAR(25)) + '-'
         + CAST(r.local_id AS VARCHAR(25)),
         'Strain',
         NULL,
         r.strain,
         r.updated_on
    FROM hermes.run r
  WHERE r.strain IS NOT NULL
UNION
  SELECT 'H'+CAST(r.experiment_id AS VARCHAR(25)) + '-'
            +CAST(r.local_id AS VARCHAR(25)),
         'Yield',
         NULL,
         CAST(r.max_yield AS VARCHAR(25)),
         r.updated_on
    FROM hermes.run r
   WHERE r.max_yield IS NOT NULL
UNION
  SELECT 'H'+CAST(r.experiment_id AS VARCHAR(25)) + '-'
            +CAST(r.local_id AS VARCHAR(25)),
         'Titer',
         NULL,
         CAST(r.max_titer AS VARCHAR(25)),
         r.updated_on
    FROM hermes.run r
   WHERE r.max_titer IS NOT NULL
UNION
  SELECT 'H'+CAST(r.experiment_id AS VARCHAR(25)) + '-'
            +CAST(r.local_id AS VARCHAR(25)),
         'Productivity',
         NULL,
         CAST(r.max_productivity AS VARCHAR(25)),
         r.updated_on
    FROM hermes.run r
   WHERE r.max_productivity IS NOT NULL

-- populate "polls" with appropriate values from the run conditions if
-- polls don't already exists for these runs and run conditions
INSERT INTO poll (smurf_property_id, fatsmurf_reading_id, value)
   SELECT sp.id, fsr.id, rc.value FROM @RunConditions rc
     JOIN property p ON rc.name = p.name AND ISNULL(p.unit_id,'') = ISNULL(rc.unit_id,'')
     JOIN fatsmurf fs ON fs.uid = rc.uid
     JOIN smurf_property sp ON sp.smurf_id = fs.smurf_id AND sp.property_id = p.id
     JOIN fatsmurf_reading fsr ON fsr.fatsmurf_id = fs.id
    WHERE fsr.name = 'Primary'
      AND NOT EXISTS (
	        SELECT *
	          FROM poll p
	         WHERE p.smurf_property_id = sp.id
	           AND p.fatsmurf_reading_id = fsr.id
        )

-- now create a subset of run conditions that have been updated since the
-- last time the fatsmurf reading has been updated (denoted by added_on for now)
DECLARE @UpdatedRunConditions
  TABLE (uid VARCHAR(50),
         name VARCHAR(max),
         unit_id INT,
         value VARCHAR(250),
         updated_on DATETIME)
INSERT INTO @UpdatedRunConditions
  SELECT rc.uid, rc.name, unit_id, value, rc.updated_on
    FROM @RunConditions rc
    JOIN fatsmurf fs ON fs.uid = rc.uid
    JOIN fatsmurf_reading fsr on fsr.fatsmurf_id = fs.id
   WHERE rc.updated_on > fsr.added_on;

-- for any updated run conditions, update the associated polls if their
-- values have changed
UPDATE pl
   SET pl.value = rc.value
  FROM @UpdatedRunConditions rc
  JOIN property p ON rc.name = p.name
   AND ISNULL(p.unit_id,'') = ISNULL(rc.unit_id,'')
  JOIN fatsmurf fs ON fs.uid = rc.uid
  JOIN smurf_property sp ON sp.smurf_id = fs.smurf_id
   AND sp.property_id = p.id
  JOIN fatsmurf_reading fsr ON fsr.fatsmurf_id = fs.id
  JOIN poll pl ON pl.smurf_property_id = sp.id AND pl.fatsmurf_reading_id = fsr.id
 WHERE fsr.name = 'Primary'
   AND ISNULL(pl.value, '') != ISNULL(rc.value, '')

-- determine the set of runs which had run conditions which where updated
-- and create a set of their uids and max updated times
DECLARE @UpdatedRuns TABLE (uid VARCHAR(50),  updated_on DATETIME)
INSERT INTO @UpdatedRuns
  SELECT rc.uid, max(rc.updated_on)
    FROM @UpdatedRunConditions rc
    JOIN fatsmurf fs ON fs.uid = rc.uid
    JOIN fatsmurf_reading fsr on fsr.fatsmurf_id = fs.id
   GROUP BY rc.uid;

-- update the appropriate fatsmurf readings such that their added_on time
-- corresponds to the max updated_on of their associated run
UPDATE fsr
   SET fsr.added_on = ur.updated_on
  FROM @UpdatedRuns ur
  JOIN fatsmurf fs ON fs.uid = ur.uid
  JOIN fatsmurf_reading fsr ON fsr.fatsmurf_id = fs.id;
',
    @additional_parameters = N'',
    @cmdexec_success_code = 0,
    @on_success_action = 1,
    @on_success_step_id = 0,
    @on_fail_action = 2,
    @on_fail_step_id = 0,
    @database_name = N'perseus',
    @retry_attempts = 0,
    @retry_interval = 0,
    @os_run_priority = 0,
    @flags = 0,
    @proxy_name = N'';

