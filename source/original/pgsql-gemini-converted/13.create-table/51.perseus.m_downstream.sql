CREATE TABLE perseus.m_downstream (
    start_point public.citext NOT NULL,
    end_point public.citext NOT NULL,
    path public.citext NOT NULL,
    level integer NOT NULL
);


ALTER TABLE perseus.m_downstream OWNER TO perseus_owner;

