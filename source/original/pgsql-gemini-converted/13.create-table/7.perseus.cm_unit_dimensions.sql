CREATE TABLE perseus.cm_unit_dimensions (
    id integer NOT NULL,
    mass numeric(10,2),
    length numeric(10,2),
    "time" numeric(10,2),
    electric_current numeric(10,2),
    thermodynamic_temperature numeric(10,2),
    amount_of_substance numeric(10,2),
    luminous_intensity numeric(10,2),
    default_unit_id integer NOT NULL,
    name public.citext NOT NULL
);


ALTER TABLE perseus.cm_unit_dimensions OWNER TO perseus_owner;

