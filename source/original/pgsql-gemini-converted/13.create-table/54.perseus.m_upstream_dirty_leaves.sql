CREATE TABLE perseus.m_upstream_dirty_leaves (
    material_uid public.citext NOT NULL,
    md5_hash text NOT NULL
);


ALTER TABLE perseus.m_upstream_dirty_leaves OWNER TO perseus_owner;

