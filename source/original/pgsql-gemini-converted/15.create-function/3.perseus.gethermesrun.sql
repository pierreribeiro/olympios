CREATE FUNCTION perseus.gethermesrun(_hermesuid character varying) RETURNS integer
    LANGUAGE plpgsql
    AS $$
    DECLARE
      _experiment INTEGER;
    BEGIN
      _experiment := CAST(CASE
        WHEN cardinality(string_to_array(replace(replace(gethermesrun._hermesuid, 'H', ''), '-', '.'), '.')) - 1 + 1 >= 1 THEN nullif((string_to_array(replace(replace(gethermesrun._hermesuid, 'H', ''), '-', '.'), '.'))[cardinality(string_to_array(replace(replace(gethermesrun._hermesuid, 'H', ''), '-', '.'), '.')) - 1 + 1], '')
        ELSE NULL
      END as INTEGER);
      RETURN _experiment;
    END;
  $$;


ALTER FUNCTION perseus.gethermesrun(_hermesuid character varying) OWNER TO perseus_owner;

