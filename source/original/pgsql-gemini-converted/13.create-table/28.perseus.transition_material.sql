CREATE TABLE perseus.transition_material (
    transition_id public.citext NOT NULL,
    material_id public.citext NOT NULL
);


ALTER TABLE perseus.transition_material OWNER TO perseus_owner;

