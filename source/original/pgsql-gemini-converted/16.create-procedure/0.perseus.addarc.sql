CREATE PROCEDURE perseus.addarc(IN _materialuid character varying, IN _transitionuid character varying, IN _direction character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    CREATE TEMP TABLE formerdownstream (
      start_point VARCHAR(50),
      end_point VARCHAR(50),
      path VARCHAR(250),
      level INTEGER,
      PRIMARY KEY (start_point, end_point, path)
    ) ON COMMIT DROP;

    CREATE TEMP TABLE formerupstream (
      start_point VARCHAR(50),
      end_point VARCHAR(50),
      path VARCHAR(250),
      level INTEGER,
      PRIMARY KEY (start_point, end_point, path)
    ) ON COMMIT DROP;

    CREATE TEMP TABLE deltadownstream (
      start_point VARCHAR(50),
      end_point VARCHAR(50),
      path VARCHAR(250),
      level INTEGER,
      PRIMARY KEY (start_point, end_point, path)
    ) ON COMMIT DROP;

    CREATE TEMP TABLE deltaupstream (
      start_point VARCHAR(50),
      end_point VARCHAR(50),
      path VARCHAR(250),
      level INTEGER,
      PRIMARY KEY (start_point, end_point, path)
    ) ON COMMIT DROP;

    CREATE TEMP TABLE newdownstream (
      start_point VARCHAR(50),
      end_point VARCHAR(50),
      path VARCHAR(250),
      level INTEGER,
      PRIMARY KEY (start_point, end_point, path)
    ) ON COMMIT DROP;

    CREATE TEMP TABLE newupstream (
      start_point VARCHAR(50),
      end_point VARCHAR(50),
      path VARCHAR(250),
      level INTEGER,
      PRIMARY KEY (start_point, end_point, path)
    ) ON COMMIT DROP;

    INSERT INTO formerdownstream (start_point, end_point, path, level)
    SELECT start_point, end_point, path, level FROM perseus.mcgetdownstream(_materialuid);

    INSERT INTO formerupstream (start_point, end_point, path, level)
    SELECT start_point, end_point, path, level FROM perseus.mcgetupstream(_materialuid);

    IF _direction = 'PT' THEN
      INSERT INTO perseus.material_transition (material_id, transition_id) VALUES (_materialuid, _transitionuid);
    ELSE
      INSERT INTO perseus.transition_material (material_id, transition_id) VALUES (_materialuid, _transitionuid);
    END IF;

    INSERT INTO newdownstream (start_point, end_point, path, level)
    SELECT start_point, end_point, path, level FROM perseus.mcgetdownstream(_materialuid);

    INSERT INTO newupstream (start_point, end_point, path, level)
    SELECT start_point, end_point, path, level FROM perseus.mcgetupstream(_materialuid);

    INSERT INTO deltaupstream (start_point, end_point, path, level)
    SELECT n.start_point, n.end_point, n.path, n.level
    FROM newupstream AS n
    WHERE NOT EXISTS (
        SELECT 1 FROM formerupstream AS f
        WHERE f.start_point = n.start_point AND f.end_point = n.end_point AND f.path = n.path
    );

    INSERT INTO deltadownstream (start_point, end_point, path, level)
    SELECT n.start_point, n.end_point, n.path, n.level
    FROM newdownstream AS n
    WHERE NOT EXISTS (
        SELECT 1 FROM formerdownstream AS f
        WHERE f.start_point = n.start_point AND f.end_point = n.end_point AND f.path = n.path
    );

    IF NOT EXISTS (SELECT 1 FROM perseus.m_downstream WHERE start_point = _materialuid) THEN
        INSERT INTO perseus.m_downstream (start_point, end_point, path, level) VALUES (_materialuid, _materialuid, '', 0);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM perseus.m_upstream WHERE start_point = _materialuid) THEN
        INSERT INTO perseus.m_upstream (start_point, end_point, path, level) VALUES (_materialuid, _materialuid, '', 0);
    END IF;

    -- Add secondary downstream connections
    INSERT INTO perseus.m_downstream (start_point, end_point, path, level)
    SELECT
        r.end_point,
        n.end_point,
        CASE WHEN r.path LIKE '%/' AND n.path LIKE '/%' THEN r.path || r.start_point || n.path ELSE r.path || n.path END,
        r.level + n.level
    FROM deltaupstream AS r
    JOIN newdownstream AS n ON r.start_point = n.start_point
    UNION
    SELECT
        nu.end_point,
        dd.end_point,
        nu.path || dd.path,
        nu.level + dd.level
    FROM deltadownstream AS dd
    JOIN newupstream AS nu ON nu.start_point = dd.start_point;

    -- Add secondary upstream connections
    INSERT INTO perseus.m_upstream (start_point, end_point, path, level)
    SELECT
        r.end_point,
        n.end_point,
        CASE WHEN r.path LIKE '%/' AND n.path LIKE '/%' THEN r.path || r.start_point || n.path ELSE r.path || n.path END,
        r.level + n.level
    FROM deltadownstream AS r
    JOIN newupstream AS n ON r.start_point = n.start_point
    UNION
    SELECT
        nd.end_point,
        du.end_point,
        CASE WHEN nd.path LIKE '%/' AND du.path LIKE '/%' THEN nd.path || nd.start_point || du.path ELSE nd.path || du.path END,
        nd.level + du.level
    FROM deltaupstream AS du
    JOIN newdownstream AS nd ON nd.start_point = du.start_point;
  END;
$$;


ALTER PROCEDURE perseus.addarc(IN _materialuid character varying, IN _transitionuid character varying, IN _direction character varying) OWNER TO perseus_owner;

