CREATE PROCEDURE perseus.removearc(IN _materialuid character varying, IN _transitionuid character varying, IN _direction character varying)
    LANGUAGE plpgsql
    AS $$
  BEGIN
    /**
    	DECLARE @FormerDownstream TABLE (start_point VARCHAR(50), end_point VARCHAR(50), path VARCHAR(250), PRIMARY KEY (start_point, end_point, path))
    	DECLARE @FormerUpstream TABLE (start_point VARCHAR(50), end_point VARCHAR(50), path VARCHAR(250), PRIMARY KEY (start_point, end_point, path))
    	DECLARE @DeltaDownstream TABLE (start_point VARCHAR(50), end_point VARCHAR(50), path VARCHAR(250), PRIMARY KEY (start_point, end_point, path))
    	DECLARE @DeltaUpstream TABLE (start_point VARCHAR(50), end_point VARCHAR(50), path VARCHAR(250), PRIMARY KEY (start_point, end_point, path))
    	DECLARE @NewDownstream TABLE (start_point VARCHAR(50), end_point VARCHAR(50), path VARCHAR(250), PRIMARY KEY (start_point, end_point, path))
    	DECLARE @NewUpstream TABLE (start_point VARCHAR(50), end_point VARCHAR(50), path VARCHAR(250), PRIMARY KEY (start_point, end_point, path))
    	
    	INSERT INTO @FormerDownstream (start_point, end_point, path)
    	SELECT start_point, end_point, path FROM dbo.McGetDownStream(@MaterialUid)
    	INSERT INTO @FormerUpstream (start_point, end_point, path)
    	SELECT start_point, end_point, path FROM dbo.McGetUpStream(@MaterialUid)
    	**/
    IF removearc._direction = 'PT' THEN
      DELETE FROM perseus.material_transition WHERE material_transition.material_id = removearc._materialuid
       AND material_transition.transition_id = removearc._transitionuid;
    ELSE
      DELETE FROM perseus.transition_material WHERE transition_material.material_id = removearc._materialuid
       AND transition_material.transition_id = removearc._transitionuid;
    END IF;
  END;
  $$;


ALTER PROCEDURE perseus.removearc(IN _materialuid character varying, IN _transitionuid character varying, IN _direction character varying) OWNER TO perseus_owner;

