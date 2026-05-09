CREATE FUNCTION perseus.trg_gooupdatedon() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  UPDATE perseus.goo SET updated_on = localtimestamp WHERE goo.id IN(
    SELECT DISTINCT
        inserted.id
      FROM
        inserted
  );
  RETURN new;
END;
$$;


ALTER FUNCTION perseus.trg_gooupdatedon() OWNER TO perseus_owner;

