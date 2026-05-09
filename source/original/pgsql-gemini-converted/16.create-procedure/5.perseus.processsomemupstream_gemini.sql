CREATE PROCEDURE perseus.processsomemupstream_gemini(IN _dirty_in perseus.goolist, IN _clean_in perseus.goolist, INOUT result_set_refcursor refcursor)
    LANGUAGE plpgsql
    AS $$
  DECLARE
    _dirty perseus.goolist;
    _add_rows INTEGER;
    _rem_rows INTEGER;
    _dirty_count INTEGER;
  BEGIN
    CREATE TEMP TABLE IF NOT EXISTS "@oldupstream" (
      start_point VARCHAR(50),
      end_point VARCHAR(50),
      path VARCHAR(500),
      level INTEGER,
      PRIMARY KEY (start_point, end_point, path)
    );
    CREATE TEMP TABLE IF NOT EXISTS "@newupstream" (
      start_point VARCHAR(50),
      end_point VARCHAR(50),
      path VARCHAR(500),
      level INTEGER,
      PRIMARY KEY (start_point, end_point, path)
    );
    CREATE TEMP TABLE IF NOT EXISTS "@addupstream" (
      start_point VARCHAR(50),
      end_point VARCHAR(50),
      path VARCHAR(500),
      level INTEGER,
      PRIMARY KEY (start_point, end_point, path)
    );
    CREATE TEMP TABLE IF NOT EXISTS "@remupstream" (
      start_point VARCHAR(50),
      end_point VARCHAR(50),
      path VARCHAR(500),
      level INTEGER,
      PRIMARY KEY (start_point, end_point, path)
    );
    -- the input materials, minus any that may have already been cleaned
    -- in a previous round
    INSERT INTO perseus."@dirty"
      SELECT DISTINCT
          d.uid
        FROM
          perseus."@dirty_in" AS d
        WHERE NOT EXISTS (
          SELECT
              1
            FROM
              perseus."@clean_in" AS c
            WHERE c.uid = d.uid
        )
    ;
    /*
      -- add to the input materials any materials that are downstream of
      -- the input material(s), skipping those we already have or which are
      -- already in the clean list.  These will be processed as well and passed
      -- back to be added to the @clean collection in the caller.
      INSERT INTO @dirty
         SELECT DISTINCT start_point AS uid FROM m_upstream mu
           WHERE EXISTS (
             SELECT 1 FROM @dirty dl WHERE dl.uid = mu.end_point )
           AND NOT EXISTS (
             SELECT 1 FROM @dirty dl1 WHERE dl1.uid = mu.start_point )
           AND NOT EXISTS (
             SELECT 1 FROM @clean_in c WHERE c.uid = mu.start_point )
        */
    SELECT
        coalesce(CAST(count(*) as INTEGER), _dirty_count)
      INTO
        _dirty_count
      FROM
        perseus."@dirty"
      LIMIT 1
    ;
    IF _dirty_count > 0 THEN
      INSERT INTO "@oldupstream" (start_point, end_point, path, level)
        SELECT
            m_upstream.start_point,
            m_upstream.end_point,
            m_upstream.path,
            m_upstream.level
          FROM
            perseus.m_upstream
            JOIN perseus."@dirty" AS d ON d.uid = m_upstream.start_point
      ;
      INSERT INTO "@newupstream" (start_point, end_point, path, level)
        SELECT
            start_point,
            end_point,
            path,
            level
          FROM
            anon AS subrelation
      ;
      /** determine what, if any inserts are needed **/
      INSERT INTO "@addupstream" (start_point, end_point, path, level)
        SELECT
            n.start_point,
            n.end_point,
            n.path,
            n.level
          FROM
            "@newupstream" AS n
          WHERE NOT EXISTS (
            SELECT
                1
              FROM
                "@oldupstream" AS f
              WHERE f.start_point = n.start_point
               AND f.end_point = n.end_point
               AND f.path = n.path
          )
      ;
      /** Delete Obsolete Rows.  This (hopefully) serves to check
              for deletes before unnecessarily locking the table.
           **/
      INSERT INTO "@remupstream" (start_point, end_point, path, level)
        SELECT
            o.start_point,
            o.end_point,
            o.path,
            o.level
          FROM
            "@oldupstream" AS o
          WHERE NOT EXISTS (
            SELECT
                1
              FROM
                "@newupstream" AS n
              WHERE n.start_point = o.start_point
               AND n.end_point = o.end_point
               AND n.path = o.path
          )
      ;
      SELECT
          coalesce(CAST(count(*) as INTEGER), _add_rows)
        INTO
          _add_rows
        FROM
          "@addupstream"
        LIMIT 1
      ;
      SELECT
          coalesce(CAST(count(*) as INTEGER), _rem_rows)
        INTO
          _rem_rows
        FROM
          "@remupstream"
        LIMIT 1
      ;
      IF _add_rows > 0 THEN
        /** Insert New Rows **/
        INSERT INTO perseus.m_upstream (start_point, end_point, path, level)
          SELECT
              "@addupstream".start_point,
              "@addupstream".end_point,
              "@addupstream".path,
              "@addupstream".level
            FROM
              "@addupstream"
        ;
      END IF;
      IF _rem_rows > 0 THEN
        /** Delete Obsolete Rows **/
        DELETE FROM perseus.m_upstream WHERE m_upstream.start_point IN(
          SELECT
              uid
            FROM
              perseus."@dirty"
        )
         AND NOT EXISTS (
          SELECT
              1
            FROM
              "@newupstream" AS f
            WHERE f.start_point = m_upstream.start_point
             AND f.end_point = m_upstream.end_point
             AND f.path = m_upstream.path
        );
      END IF;
    END IF;
    -- return the list of processed start_point nodes.
    OPEN result_set_refcursor FOR SELECT
        perseus."@dirty".*
      FROM
        perseus."@dirty"
    ;
  END;
  $$;


ALTER PROCEDURE perseus.processsomemupstream_gemini(IN _dirty_in perseus.goolist, IN _clean_in perseus.goolist, INOUT result_set_refcursor refcursor) OWNER TO perseus_owner;

