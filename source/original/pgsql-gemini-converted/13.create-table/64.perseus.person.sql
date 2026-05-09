CREATE TABLE perseus.person (
    id integer NOT NULL,
    domain_id public.citext NOT NULL,
    km_session_id public.citext,
    login public.citext NOT NULL,
    name public.citext NOT NULL,
    email public.citext,
    last_login timestamp without time zone,
    is_active boolean DEFAULT (1)::boolean NOT NULL
);


ALTER TABLE perseus.person OWNER TO perseus_owner;

