CREATE PROCEDURE perseus.linkunlinkedmaterials()
    LANGUAGE plpgsql
    AS $$
DECLARE
  rec record;
BEGIN
  FOR rec IN
    SELECT
        g.uid
      FROM
        perseus.goo AS g
      WHERE
        NOT EXISTS (
          SELECT
              1
            FROM
              perseus.m_upstream AS mu
            WHERE
              g.uid = mu.start_point
        )
  LOOP
    BEGIN
      INSERT INTO perseus.m_upstream (start_point, end_point, level, path)
        SELECT
            f.start_point,
            f.end_point,
            f.level,
            f.path
          FROM
            perseus.mcgetupstream(rec.uid) AS f;
    EXCEPTION
      WHEN OTHERS THEN
        -- ignore errors and continue to the next material
    END;
  END LOOP;
END;
$$;


ALTER PROCEDURE perseus.linkunlinkedmaterials() OWNER TO perseus_owner;

