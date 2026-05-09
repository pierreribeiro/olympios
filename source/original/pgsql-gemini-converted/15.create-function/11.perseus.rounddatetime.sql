CREATE FUNCTION perseus.rounddatetime(_inputdatetime timestamp without time zone) RETURNS timestamp without time zone
    LANGUAGE plpgsql
    AS $$
    DECLARE
      _returndatetime TIMESTAMP;
    BEGIN
      _returndatetime := timestamp '1900-01-01' + interval '0 SECONDS' + interval '1 M' * (EXTRACT(EPOCH from rounddatetime._inputdatetime - timestamp '1900-01-01' + interval '0 SECONDS') / 60);
      RETURN _returndatetime;
    END;
  $$;


ALTER FUNCTION perseus.rounddatetime(_inputdatetime timestamp without time zone) OWNER TO perseus_owner;

