CREATE TABLE perseus.permissions (
    emailaddress public.citext NOT NULL,
    permission public.citext NOT NULL,
    md5_hash text NOT NULL
);


ALTER TABLE perseus.permissions OWNER TO perseus_owner;

