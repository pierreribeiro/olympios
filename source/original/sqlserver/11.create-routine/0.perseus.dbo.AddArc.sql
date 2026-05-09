USE [perseus]
GO
            
CREATE PROCEDURE AddArc @MaterialUid VARCHAR(50), @TransitionUid VARCHAR(50), @Direction VARCHAR(2) AS

	DECLARE @FormerDownstream TABLE (start_point VARCHAR(50), end_point VARCHAR(50), path VARCHAR(250), level INT, PRIMARY KEY (start_point, end_point, path))
	DECLARE @FormerUpstream TABLE (start_point VARCHAR(50), end_point VARCHAR(50), path VARCHAR(250), level INT, PRIMARY KEY (start_point, end_point, path))
	DECLARE @DeltaDownstream TABLE (start_point VARCHAR(50), end_point VARCHAR(50), path VARCHAR(250), level INT, PRIMARY KEY (start_point, end_point, path))
	DECLARE @DeltaUpstream TABLE (start_point VARCHAR(50), end_point VARCHAR(50), path VARCHAR(250), level INT, PRIMARY KEY (start_point, end_point, path))
	DECLARE @NewDownstream TABLE (start_point VARCHAR(50), end_point VARCHAR(50), path VARCHAR(250), level INT, PRIMARY KEY (start_point, end_point, path))
	DECLARE @NewUpstream TABLE (start_point VARCHAR(50), end_point VARCHAR(50), path VARCHAR(250), level INT, PRIMARY KEY (start_point, end_point, path))
	
	INSERT INTO @FormerDownstream (start_point, end_point, path, level)
	SELECT start_point, end_point, path, level FROM dbo.McGetDownStream(@MaterialUid)
	
	INSERT INTO @FormerUpstream (start_point, end_point, path, level)
	SELECT start_point, end_point, path, level FROM dbo.McGetUpStream(@MaterialUid)
	
	IF @Direction = 'PT'
		BEGIN
			INSERT INTO material_transition (material_id, transition_id) VALUES (@MaterialUid, @TransitionUid)
		END
	ELSE
		BEGIN
			INSERT INTO transition_material (material_id, transition_id) VALUES (@MaterialUid, @TransitionUid)
		END
	
	INSERT INTO @NewDownstream (start_point, end_point, path, level)
	SELECT start_point, end_point, path, level FROM dbo.McGetDownStream(@MaterialUid)
	
	INSERT INTO @NewUpstream (start_point, end_point, path, level)
	SELECT start_point, end_point, path, level FROM dbo.McGetUpStream(@MaterialUid)
	
	INSERT INTO @DeltaUpstream (start_point, end_point, path, level)
	SELECT start_point, end_point, path, level
	FROM @NewUpstream n
	WHERE NOT EXISTS (SELECT * FROM @FormerUpstream f WHERE f.start_point = n.start_point AND f.end_point = n.end_point AND f.path = n.path)
	
	INSERT INTO @DeltaDownstream (start_point, end_point, path, level)
	SELECT start_point, end_point, path, level
	FROM @NewDownstream n
	WHERE NOT EXISTS (SELECT * FROM @FormerDownstream f WHERE f.start_point = n.start_point AND f.end_point = n.end_point AND f.path = n.path)
	
	IF (SELECT COUNT(*) FROM m_downstream WHERE start_point = @MaterialUid) = 0
		INSERT INTO m_downstream (start_point, end_point, path, level) VALUES (@MaterialUid, @MaterialUid, '', 0)
		
	IF (SELECT COUNT(*) FROM m_upstream WHERE start_point = @MaterialUid) = 0
		INSERT INTO m_upstream (start_point, end_point, path, level) VALUES (@MaterialUid, @MaterialUid, '', 0)

	/** Add secondary downstream connections **/
	INSERT INTO m_downstream (start_point, end_point, path, level)
	SELECT r.end_point, 
	n.end_point, 
	CASE WHEN r.path LIKE '%/' AND n.path LIKE '/%' THEN r.path + r.start_point + n.path ELSE r.path + n.path END,
	r.level + n.level
	FROM @DeltaUpstream r
	JOIN @NewDownstream n ON r.start_point = n.start_point
	UNION
	SELECT nu.end_point, dd.end_point, 
	nu.path + dd.path,
	nu.level + dd.level
	FROM @DeltaDownstream dd
	JOIN @NewUpstream nu ON nu.start_point = dd.start_point
	
	/** Add secondary upstream connections **/
	INSERT INTO m_upstream (start_point, end_point, path, level)
	SELECT r.end_point, 
	n.end_point, 
	CASE WHEN r.path LIKE '%/' AND n.path LIKE '/%' THEN r.path + r.start_point + n.path ELSE r.path + n.path END,
	r.level + n.level
	FROM @DeltaDownstream r
	JOIN @NewUpstream n ON r.start_point = n.start_point
	UNION
	SELECT nd.end_point, du.end_point, 
	CASE WHEN nd.path LIKE '%/' AND du.path LIKE '/%' THEN nd.path + nd.start_point + du.path ELSE nd.path + du.path END,
	nd.level + du.level
	FROM @DeltaUpstream du
	JOIN @NewDownstream nd ON nd.start_point = du.start_point

