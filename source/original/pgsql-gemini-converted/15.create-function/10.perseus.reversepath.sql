CREATE FUNCTION perseus.reversepath(_source character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
    DECLARE
      _dest VARCHAR;
    BEGIN
      _dest := '';
      IF length(rtrim(reversepath._source)) > 0 THEN
        -- chop off initial / (indexed by 1)
        reversepath._source := substr(reversepath._source, 2, length(rtrim(reversepath._source)));
        WHILE length(rtrim(reversepath._source)) > 0 LOOP
          _dest := substr(reversepath._source, 0, CAST(CAST(strpos(reversepath._source, '/') as BIGINT) as INTEGER)) || '/' || _dest;
          reversepath._source := substr(reversepath._source, CAST(strpos(reversepath._source, '/') + CAST(1 as BIGINT) as INTEGER), length(rtrim(reversepath._source)));
        END LOOP;
        _dest := '/' || _dest;
      END IF;
      RETURN _dest;
    END;
  $$;


ALTER FUNCTION perseus.reversepath(_source character varying) OWNER TO perseus_owner;

