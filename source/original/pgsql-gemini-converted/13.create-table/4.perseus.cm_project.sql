CREATE TABLE perseus.cm_project (
    project_id smallint NOT NULL,
    label public.citext NOT NULL,
    is_active boolean NOT NULL,
    display_order smallint NOT NULL,
    group_id integer
);


ALTER TABLE perseus.cm_project OWNER TO perseus_owner;

