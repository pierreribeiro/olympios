CREATE TABLE perseus.cm_unit (
    id integer NOT NULL,
    description public.citext,
    longname public.citext,
    dimensions_id integer,
    name public.citext,
    factor numeric(20,10),
    "offset" numeric(20,10)
);


ALTER TABLE perseus.cm_unit OWNER TO perseus_owner;

