CREATE TABLE perseus.cm_application (
    application_id integer NOT NULL,
    label public.citext NOT NULL,
    description public.citext NOT NULL,
    is_active smallint NOT NULL,
    application_group_id integer,
    url public.citext,
    owner_user_id integer,
    jira_id public.citext
);


ALTER TABLE perseus.cm_application OWNER TO perseus_owner;

