CREATE FUNCTION perseus.trg_fatsmurfupdatedon() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  UPDATE perseus.fatsmurf SET updated_on = localtimestamp WHERE fatsmurf.id IN(
    SELECT DISTINCT
        inserted.id
      FROM
        inserted
  );
  RETURN new;
END;
$$;


ALTER FUNCTION perseus.trg_fatsmurfupdatedon() OWNER TO perseus_owner;

