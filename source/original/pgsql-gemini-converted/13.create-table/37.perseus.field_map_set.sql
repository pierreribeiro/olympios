CREATE TABLE perseus.field_map_set (
    id integer NOT NULL,
    tab_group_id integer,
    display_order integer,
    name public.citext,
    color public.citext,
    size integer
);


ALTER TABLE perseus.field_map_set OWNER TO perseus_owner;

