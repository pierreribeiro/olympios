CREATE PROCEDURE perseus.usp_updatemdownstream()
    LANGUAGE plpgsql
    AS $$
BEGIN
    WITH dsg_uids AS (
      SELECT
          g.uid
        FROM
          perseus.material_transition_material AS mtm
          JOIN perseus.goo AS g ON g.uid = mtm.start_point
        WHERE NOT EXISTS (
          SELECT
              1
            FROM
              perseus.m_downstream AS us
            WHERE us.start_point = mtm.start_point
        )
        ORDER BY
          g.added_on DESC
        LIMIT 500
    )
    INSERT INTO perseus.m_downstream (start_point, end_point, path, level)
      SELECT
          f.start_point,
          f.end_point,
          f.path,
          f.level
        FROM
          perseus.mcgetdownstreambylist((
            SELECT
                array_agg(dsg_uids.uid)
              FROM
                dsg_uids
          )) AS f;

    COMMIT;

    INSERT INTO perseus.m_downstream (start_point, end_point, path, level)
      SELECT
          up.end_point,
          up.start_point,
          perseus.reversepath(up.path),
          up.level
        FROM
          perseus.m_upstream AS up
        WHERE NOT EXISTS (
          SELECT
              1
            FROM
              perseus.m_downstream AS down
            WHERE up.end_point = down.start_point
             AND up.start_point = down.end_point
             AND perseus.reversepath(up.path) = down.path
        )
        LIMIT 500;

    COMMIT;
  END;
$$;


ALTER PROCEDURE perseus.usp_updatemdownstream() OWNER TO perseus_owner;

