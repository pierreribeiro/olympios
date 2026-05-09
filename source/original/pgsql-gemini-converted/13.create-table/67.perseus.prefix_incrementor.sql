CREATE TABLE perseus.prefix_incrementor (
    prefix public.citext NOT NULL,
    counter integer NOT NULL
);


ALTER TABLE perseus.prefix_incrementor OWNER TO perseus_owner;

