CREATE TABLE perseus.recipe_project_assignment (
    project_id smallint NOT NULL,
    recipe_id integer NOT NULL,
    md5_hash text NOT NULL
);


ALTER TABLE perseus.recipe_project_assignment OWNER TO perseus_owner;

