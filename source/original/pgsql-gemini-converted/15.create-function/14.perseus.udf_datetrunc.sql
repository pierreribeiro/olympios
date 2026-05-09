CREATE FUNCTION perseus.udf_datetrunc(_datein timestamp without time zone) RETURNS timestamp without time zone
    LANGUAGE sql
    AS $$
    SELECT date_trunc('day', _datein);
  $$;


ALTER FUNCTION perseus.udf_datetrunc(_datein timestamp without time zone) OWNER TO perseus_owner;

