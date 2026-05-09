CREATE TABLE perseus.m_upstream (
    start_point public.citext NOT NULL,
    end_point public.citext NOT NULL,
    path public.citext NOT NULL,
    level integer NOT NULL
);


ALTER TABLE perseus.m_upstream OWNER TO perseus_owner;

