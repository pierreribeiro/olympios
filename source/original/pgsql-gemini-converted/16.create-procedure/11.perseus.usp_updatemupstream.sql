CREATE PROCEDURE perseus.usp_updatemupstream()
    LANGUAGE plpgsql
    AS $$
  BEGIN
    WITH us_goo_uids AS (
      SELECT DISTINCT
        d.uid
      FROM (
        SELECT
          g.uid
        FROM
          perseus.material_transition_material AS mtm
          JOIN perseus.goo AS g
            ON g.uid = mtm.end_point
        WHERE
          NOT EXISTS (
            SELECT
              1
            FROM
              perseus.m_upstream AS us
            WHERE
              us.start_point = mtm.end_point
          )
        ORDER BY
          g.added_on DESC NULLS LAST
        LIMIT 10000
      ) AS d
      UNION
      SELECT DISTINCT
        goo.uid
      FROM
        perseus.goo
      WHERE
        NOT EXISTS (
          SELECT
            1
          FROM
            perseus.m_upstream
          WHERE
            goo.uid = m_upstream.start_point
        )
      LIMIT 10000
    )
    INSERT INTO perseus.m_upstream (start_point, end_point, path, level)
    SELECT
      f.start_point,
      f.end_point,
      f.path,
      f.level
    FROM
      perseus.mcgetupstreambylist (ARRAY(
        SELECT
          uid
        FROM
          us_goo_uids
      )) AS f (start_point, end_point, path, level);
  END;
  $$;


ALTER PROCEDURE perseus.usp_updatemupstream() OWNER TO perseus_owner;

