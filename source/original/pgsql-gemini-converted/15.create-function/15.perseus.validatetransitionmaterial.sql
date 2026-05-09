CREATE FUNCTION perseus.validatetransitionmaterial() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF (
    SELECT
        CAST(count(*) as INTEGER)
      FROM
        inserted AS ins
        JOIN perseus.transition_material AS tm ON ins.material_id = tm.material_id
      WHERE tm.transition_id <> ins.transition_id
  ) > 0 THEN
    RAISE EXCEPTION SQLSTATE 'CW100' USING MESSAGE = 'A material cannot be the output of more than 1 process.';
    RETURN new;
  END IF;
  RETURN new;
END;
$$;


ALTER FUNCTION perseus.validatetransitionmaterial() OWNER TO perseus_owner;

SET default_tablespace = '';

SET default_table_access_method = heap;

