CREATE TABLE perseus.tmp_messy_links (
    source_transition public.citext NOT NULL,
    source_name public.citext,
    destination_transition public.citext NOT NULL,
    desitnation_name public.citext,
    material_id public.citext NOT NULL,
    md5_hash text NOT NULL
);


ALTER TABLE perseus.tmp_messy_links OWNER TO perseus_owner;

