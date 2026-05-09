CREATE TABLE perseus.migration (
    id integer NOT NULL,
    description public.citext NOT NULL,
    created_on timestamp without time zone DEFAULT LOCALTIMESTAMP NOT NULL
);


ALTER TABLE perseus.migration OWNER TO perseus_owner;

