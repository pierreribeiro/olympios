CREATE PROCEDURE perseus.reconcilemupstream()
    LANGUAGE plpgsql
    AS $$
DECLARE
  _add_rows INTEGER;
  _rem_rows INTEGER;
  _dirty_count INTEGER;
BEGIN
  CREATE TEMP TABLE dirty (
    uid VARCHAR(50) PRIMARY KEY
  ) ON COMMIT DROP;
  CREATE TEMP TABLE oldupstream (
    start_point VARCHAR(50),
    end_point VARCHAR(50),
    path VARCHAR(500),
    "level" INT,
    PRIMARY KEY (start_point, end_point, path)
  ) ON COMMIT DROP;
  CREATE TEMP TABLE newupstream (
    start_point VARCHAR(50),
    end_point VARCHAR(50),
    path VARCHAR(500),
    "level" INT,
    PRIMARY KEY (start_point, end_point, path)
  ) ON COMMIT DROP;
  CREATE TEMP TABLE addupstream (
    start_point VARCHAR(50),
    end_point VARCHAR(50),
    path VARCHAR(500),
    "level" INT,
    PRIMARY KEY (start_point, end_point, path)
  ) ON COMMIT DROP;
  CREATE TEMP TABLE remupstream (
    start_point VARCHAR(50),
    end_point VARCHAR(50),
    path VARCHAR(500),
    "level" INT,
    PRIMARY KEY (start_point, end_point, path)
  ) ON COMMIT DROP;

  INSERT INTO dirty(uid)
  SELECT DISTINCT material_uid
  FROM perseus.m_upstream_dirty_leaves
  WHERE material_uid <> 'n/a'
  LIMIT 10;

  INSERT INTO dirty(uid)
  SELECT DISTINCT mu.start_point
  FROM perseus.m_upstream AS mu
  WHERE EXISTS (
      SELECT 1 FROM dirty AS dl WHERE dl.uid = mu.end_point
    )
    AND NOT EXISTS (
      SELECT 1 FROM dirty AS dl1 WHERE dl1.uid = mu.start_point
    )
    AND mu.start_point <> 'n/a'
  ON CONFLICT(uid) DO NOTHING;

  SELECT count(*) INTO _dirty_count
  FROM dirty;

  IF _dirty_count > 0 THEN
    DELETE FROM perseus.m_upstream_dirty_leaves
    WHERE EXISTS (
        SELECT 1 FROM dirty AS d WHERE d.uid = m_upstream_dirty_leaves.material_uid
      );

    INSERT INTO oldupstream (start_point, end_point, path, "level")
    SELECT m.start_point, m.end_point, m.path, m."level"
    FROM perseus.m_upstream m
    JOIN dirty d ON d.uid = m.start_point;

    INSERT INTO newupstream (start_point, end_point, path, "level")
    SELECT *
    FROM perseus.mcgetupstreambylist((SELECT array_agg(uid) FROM dirty));

    INSERT INTO addupstream (start_point, end_point, path, "level")
    SELECT n.start_point, n.end_point, n.path, n."level"
    FROM newupstream n
    WHERE NOT EXISTS (
        SELECT 1
        FROM oldupstream f
        WHERE f.start_point = n.start_point
          AND f.end_point = n.end_point
          AND f.path = n.path
      );

    INSERT INTO remupstream (start_point, end_point, path, "level")
    SELECT o.start_point, o.end_point, o.path, o."level"
    FROM oldupstream o
    WHERE NOT EXISTS(
        SELECT 1
        FROM newupstream n
        WHERE n.start_point = o.start_point
          AND n.end_point = o.end_point
          AND n.path = o.path
      );

    SELECT count(*) INTO _add_rows
    FROM addupstream;
    SELECT count(*) INTO _rem_rows
    FROM remupstream;

    IF _add_rows > 0 THEN
      INSERT INTO perseus.m_upstream (start_point, end_point, path, "level")
      SELECT a.start_point, a.end_point, a.path, a."level" FROM addupstream a;
    END IF;

    IF _rem_rows > 0 THEN
      DELETE FROM perseus.m_upstream
      WHERE start_point IN (SELECT uid FROM dirty)
        AND NOT EXISTS(
          SELECT 1
          FROM newupstream f
          WHERE f.start_point = m_upstream.start_point
            AND f.end_point = m_upstream.end_point
            AND f.path = m_upstream.path
        );
    END IF;
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    RAISE EXCEPTION 'Transaction rolled back in perseus.reconcilemupstream: %', SQLERRM;
END;
$$;


ALTER PROCEDURE perseus.reconcilemupstream() OWNER TO perseus_owner;

