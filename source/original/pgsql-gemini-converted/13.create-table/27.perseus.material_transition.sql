CREATE TABLE perseus.material_transition (
    material_id public.citext NOT NULL,
    transition_id public.citext NOT NULL,
    added_on timestamp without time zone DEFAULT LOCALTIMESTAMP NOT NULL
);


ALTER TABLE perseus.material_transition OWNER TO perseus_owner;

