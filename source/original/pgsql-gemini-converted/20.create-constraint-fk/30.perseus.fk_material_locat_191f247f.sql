ALTER TABLE ONLY perseus.material_inventory
    ADD CONSTRAINT fk__material___locat__191f247f FOREIGN KEY (location_container_id) REFERENCES perseus.container(id);

