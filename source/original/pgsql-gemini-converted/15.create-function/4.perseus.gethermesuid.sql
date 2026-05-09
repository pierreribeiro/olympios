CREATE FUNCTION perseus.gethermesuid(_experimentid integer, _runid integer) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
    DECLARE
      _uid VARCHAR(50);
    BEGIN
      _uid := 'H' || gethermesuid._experimentid || '-' || gethermesuid._runid;
      RETURN _uid;
    END;
  $$;


ALTER FUNCTION perseus.gethermesuid(_experimentid integer, _runid integer) OWNER TO perseus_owner;

