ALTER TABLE ONLY perseus.field_map_display_type_user
    ADD CONSTRAINT field_map_display_type_user_fk_2 FOREIGN KEY (user_id) REFERENCES perseus.perseus_user(id) ON DELETE CASCADE;

