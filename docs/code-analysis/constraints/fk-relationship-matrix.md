# Foreign Key Relationship Matrix - Perseus Database Migration

## Overview

This document provides a comprehensive matrix of all 124 foreign key constraints in the Perseus database migration. All FKs are extracted from the topological sort analysis and listed in alphabetical order by child table.

**Analysis Date:** 2026-02-10
**Total FK Constraints:** 124
**Named FK Constraints:** 99
**Unnamed FK Constraints:** 25
**Duplicate FK Constraints:** 3 (perseus_user.manufacturer_id)

---

## FK Constraint Statistics

| Metric | Count |
|--------|-------|
| Total FK Constraints | 124 |
| ON DELETE CASCADE | 40 |
| ON DELETE SET NULL | 4 |
| ON DELETE NO ACTION | 80 |
| ON UPDATE CASCADE | 2 |
| ON UPDATE NO ACTION | 122 |
| Named FK Constraints | 99 |
| Unnamed FK Constraints (NULL) | 25 |
| Duplicate FK Constraints | 3 |

---

## Complete FK Relationship Matrix

### A-C Tables

| Child Table | FK Name | Child Column(s) | Parent Table | Parent Column(s) | ON DELETE | ON UPDATE |
|-------------|---------|-----------------|--------------|------------------|-----------|-----------|
| **coa** | coa_FK_1 | goo_type_id | goo_type | id | NO ACTION | NO ACTION |
| **coa_spec** | coa_spec_FK_1 | coa_id | coa | id | NO ACTION | NO ACTION |
| **coa_spec** | coa_spec_FK_2 | property_id | property | id | NO ACTION | NO ACTION |
| **container** | container_FK_1 | container_type_id | container_type | id | NO ACTION | NO ACTION |
| **container_history** | container_history_FK_1 | history_id | history | id | CASCADE | NO ACTION |
| **container_history** | container_history_FK_2 | container_id | container | id | CASCADE | NO ACTION |
| **container_type_position** | container_type_position_FK_1 | parent_container_type_id | container_type | id | NO ACTION | NO ACTION |
| **container_type_position** | container_type_position_FK_2 | child_container_type_id | container_type | id | NO ACTION | NO ACTION |

### E-F Tables

| Child Table | FK Name | Child Column(s) | Parent Table | Parent Column(s) | ON DELETE | ON UPDATE |
|-------------|---------|-----------------|--------------|------------------|-----------|-----------|
| **external_goo_type** | external_goo_type_FK_1 | goo_type_id | goo_type | id | NO ACTION | NO ACTION |
| **external_goo_type** | external_goo_type_FK_2 | manufacturer_id | manufacturer | id | NO ACTION | NO ACTION |
| **fatsmurf** | FK_fatsmurf_workflow_step | workflow_step_id | workflow_step | id | SET NULL | NO ACTION |
| **fatsmurf** | fk_fatsmurf_smurf_id | smurf_id | smurf | id | NO ACTION | NO ACTION |
| **fatsmurf** | fs_container_id_FK_1 | container_id | container | id | SET NULL | NO ACTION |
| **fatsmurf** | fs_organization_FK_1 | organization_id | manufacturer | id | NO ACTION | NO ACTION |
| **fatsmurf_attachment** | fatsmurf_attachment_FK_1 | added_by | perseus_user | id | NO ACTION | NO ACTION |
| **fatsmurf_attachment** | fatsmurf_attachment_FK_2 | fatsmurf_id | fatsmurf | id | CASCADE | NO ACTION |
| **fatsmurf_comment** | fatsmurf_comment_FK_1 | added_by | perseus_user | id | NO ACTION | NO ACTION |
| **fatsmurf_comment** | fatsmurf_comment_FK_2 | fatsmurf_id | fatsmurf | id | CASCADE | NO ACTION |
| **fatsmurf_history** | fatsmurf_history_FK_1 | history_id | history | id | CASCADE | NO ACTION |
| **fatsmurf_history** | fatsmurf_history_FK_2 | fatsmurf_id | fatsmurf | id | CASCADE | NO ACTION |
| **fatsmurf_reading** | creator_FK_1 | added_by | perseus_user | id | NO ACTION | NO ACTION |
| **fatsmurf_reading** | fatsmurf_reading_FK_1 | fatsmurf_id | fatsmurf | id | CASCADE | NO ACTION |
| **feed_type** | (unnamed) | added_by | perseus_user | id | NO ACTION | NO ACTION |
| **feed_type** | (unnamed) | updated_by_id | perseus_user | id | NO ACTION | NO ACTION |
| **field_map** | combined_field_map_FK_1 | field_map_block_id | field_map_block | id | NO ACTION | NO ACTION |
| **field_map** | combined_field_map_FK_2 | field_map_type_id | field_map_type | id | NO ACTION | NO ACTION |
| **field_map** | field_map_field_map_set_FK_1 | field_map_set_id | field_map_set | id | NO ACTION | NO ACTION |
| **field_map_display_type** | combined_field_map_display_type_FK_1 | field_map_id | field_map | id | CASCADE | NO ACTION |
| **field_map_display_type** | combined_field_map_display_type_FK_2 | display_type_id | display_type | id | CASCADE | NO ACTION |
| **field_map_display_type** | combined_field_map_display_type_FK_3 | display_layout_id | display_layout | id | CASCADE | NO ACTION |
| **field_map_display_type_user** | field_map_display_type_user_FK_2 | user_id | perseus_user | id | CASCADE | NO ACTION |

### G Tables

| Child Table | FK Name | Child Column(s) | Parent Table | Parent Column(s) | ON DELETE | ON UPDATE |
|-------------|---------|-----------------|--------------|------------------|-----------|-----------|
| **goo** | FK_goo_workflow_step | workflow_step_id | workflow_step | id | SET NULL | NO ACTION |
| **goo** | container_id_FK_1 | container_id | container | id | SET NULL | NO ACTION |
| **goo** | fk_goo_recipe | recipe_id | recipe | id | NO ACTION | NO ACTION |
| **goo** | fk_goo_recipe_part | recipe_part_id | recipe_part | id | NO ACTION | NO ACTION |
| **goo** | goo_FK_1 | goo_type_id | goo_type | id | NO ACTION | NO ACTION |
| **goo** | goo_FK_4 | added_by | perseus_user | id | NO ACTION | NO ACTION |
| **goo** | manufacturer_FK_1 | manufacturer_id | manufacturer | id | NO ACTION | NO ACTION |
| **goo_attachment** | goo_attachment_FK_1 | added_by | perseus_user | id | NO ACTION | NO ACTION |
| **goo_attachment** | goo_attachment_FK_2 | goo_id | goo | id | CASCADE | NO ACTION |
| **goo_attachment** | goo_attachment_FK_3 | goo_attachment_type_id | goo_attachment_type | id | NO ACTION | NO ACTION |
| **goo_comment** | goo_comment_FK_1 | added_by | perseus_user | id | NO ACTION | NO ACTION |
| **goo_comment** | goo_comment_FK_2 | goo_id | goo | id | CASCADE | NO ACTION |
| **goo_history** | goo_history_FK_1 | history_id | history | id | CASCADE | NO ACTION |
| **goo_history** | goo_history_FK_2 | goo_id | goo | id | CASCADE | NO ACTION |
| **goo_type_combine_component** | goo_type_combine_component_FK_1 | goo_type_id | goo_type | id | NO ACTION | NO ACTION |
| **goo_type_combine_component** | goo_type_combine_component_FK_2 | goo_type_combine_target_id | goo_type_combine_target | id | CASCADE | NO ACTION |
| **goo_type_combine_target** | goo_type_combine_target_FK_1 | goo_type_id | goo_type | id | NO ACTION | NO ACTION |

### H Tables

| Child Table | FK Name | Child Column(s) | Parent Table | Parent Column(s) | ON DELETE | ON UPDATE |
|-------------|---------|-----------------|--------------|------------------|-----------|-----------|
| **history** | history_FK_1 | creator_id | perseus_user | id | NO ACTION | NO ACTION |
| **history** | history_FK_2 | history_type_id | history_type | id | NO ACTION | NO ACTION |
| **history_value** | history_value_FK_1 | history_id | history | id | CASCADE | NO ACTION |

### M Tables

| Child Table | FK Name | Child Column(s) | Parent Table | Parent Column(s) | ON DELETE | ON UPDATE |
|-------------|---------|-----------------|--------------|------------------|-----------|-----------|
| **material_inventory** | (unnamed) | allocation_container_id | container | id | NO ACTION | NO ACTION |
| **material_inventory** | (unnamed) | created_by_id | perseus_user | id | NO ACTION | NO ACTION |
| **material_inventory** | (unnamed) | location_container_id | container | id | NO ACTION | NO ACTION |
| **material_inventory** | (unnamed) | material_id | goo | id | NO ACTION | NO ACTION |
| **material_inventory** | (unnamed) | recipe_id | recipe | id | NO ACTION | NO ACTION |
| **material_inventory** | (unnamed) | updated_by_id | perseus_user | id | NO ACTION | NO ACTION |
| **material_inventory_threshold** | FK_material_inventory_threshold_created_by | created_by_id | perseus_user | id | NO ACTION | NO ACTION |
| **material_inventory_threshold** | FK_material_inventory_threshold_material_type | material_type_id | goo_type | id | NO ACTION | NO ACTION |
| **material_inventory_threshold** | FK_material_inventory_threshold_updated_by | updated_by_id | perseus_user | id | NO ACTION | NO ACTION |
| **material_inventory_threshold_notify_user** | FK_mit_notify_user_threshold | threshold_id | material_inventory_threshold | id | CASCADE | NO ACTION |
| **material_inventory_threshold_notify_user** | FK_mit_notify_user_user | user_id | perseus_user | id | NO ACTION | NO ACTION |
| **material_qc** | (unnamed) | material_id | goo | id | NO ACTION | NO ACTION |
| **material_transition** | FK_material_transition_fatsmurf | transition_id | fatsmurf | uid | CASCADE | NO ACTION |
| **material_transition** | FK_material_transition_goo | material_id | goo | uid | CASCADE | **CASCADE** |

### P Tables

| Child Table | FK Name | Child Column(s) | Parent Table | Parent Column(s) | ON DELETE | ON UPDATE |
|-------------|---------|-----------------|--------------|------------------|-----------|-----------|
| **perseus_user** | FK__perseus_u__manuf__5B3C942F | manufacturer_id | manufacturer | id | NO ACTION | NO ACTION |
| **perseus_user** | FK__perseus_u__manuf__5E1900DA | manufacturer_id | manufacturer | id | NO ACTION | NO ACTION |
| **perseus_user** | FK__perseus_u__manuf__6001494C | manufacturer_id | manufacturer | id | NO ACTION | NO ACTION |
| **poll** | poll_fatsmurf_reading_FK_1 | fatsmurf_reading_id | fatsmurf_reading | id | CASCADE | NO ACTION |
| **poll** | poll_smurf_property_FK_1 | smurf_property_id | smurf_property | id | NO ACTION | NO ACTION |
| **poll_history** | poll_history_FK_1 | history_id | history | id | CASCADE | NO ACTION |
| **poll_history** | poll_history_FK_2 | poll_id | poll | id | CASCADE | NO ACTION |
| **property** | property_FK_1 | unit_id | unit | id | NO ACTION | NO ACTION |
| **property_option** | property_option_FK_1 | property_id | property | id | NO ACTION | NO ACTION |

### R Tables

| Child Table | FK Name | Child Column(s) | Parent Table | Parent Column(s) | ON DELETE | ON UPDATE |
|-------------|---------|-----------------|--------------|------------------|-----------|-----------|
| **recipe** | (unnamed) | added_by | perseus_user | id | NO ACTION | NO ACTION |
| **recipe** | (unnamed) | feed_type_id | feed_type | id | NO ACTION | NO ACTION |
| **recipe** | (unnamed) | goo_type_id | goo_type | id | NO ACTION | NO ACTION |
| **recipe** | (unnamed) | workflow_id | workflow | id | NO ACTION | NO ACTION |
| **recipe_part** | (unnamed) | goo_type_id | goo_type | id | NO ACTION | NO ACTION |
| **recipe_part** | (unnamed) | part_recipe_id | recipe | id | NO ACTION | NO ACTION |
| **recipe_part** | (unnamed) | recipe_id | recipe | id | NO ACTION | NO ACTION |
| **recipe_part** | (unnamed) | unit_id | unit | id | NO ACTION | NO ACTION |
| **recipe_part** | (unnamed) | workflow_step_id | workflow_step | id | NO ACTION | NO ACTION |
| **recipe_project_assignment** | (unnamed) | recipe_id | recipe | id | NO ACTION | NO ACTION |
| **robot_log** | (unnamed) | robot_log_type_id | robot_log_type | id | NO ACTION | NO ACTION |
| **robot_log** | robot_log_FK_1 | robot_run_id | robot_run | id | NO ACTION | NO ACTION |
| **robot_log_container_sequence** | robot_log_container_sequence_FK_1 | sequence_type_id | sequence_type | id | CASCADE | NO ACTION |
| **robot_log_container_sequence** | robot_log_container_sequence_FK_2 | container_id | container | id | CASCADE | NO ACTION |
| **robot_log_container_sequence** | robot_log_container_sequence_FK_3 | robot_log_id | robot_log | id | CASCADE | NO ACTION |
| **robot_log_error** | robot_log_error_FK_1 | robot_log_id | robot_log | id | CASCADE | NO ACTION |
| **robot_log_read** | FK_robot_log_read_source_material_id | source_material_id | goo | id | NO ACTION | NO ACTION |
| **robot_log_read** | robot_log_read_FK_1 | robot_log_id | robot_log | id | CASCADE | NO ACTION |
| **robot_log_read** | robot_log_read_FK_2 | property_id | property | id | CASCADE | NO ACTION |
| **robot_log_transfer** | FK_robot_log_transfer_destination_material_id | destination_material_id | goo | id | NO ACTION | NO ACTION |
| **robot_log_transfer** | FK_robot_log_transfer_source_material_id | source_material_id | goo | id | NO ACTION | NO ACTION |
| **robot_log_transfer** | robot_log_transfer_FK_1 | robot_log_id | robot_log | id | CASCADE | NO ACTION |
| **robot_log_type** | robot_log_type_FK_1 | destination_container_type_id | container_type | id | NO ACTION | NO ACTION |
| **robot_run** | robot_run_FK_2 | robot_id | container | id | NO ACTION | NO ACTION |

### S Tables

| Child Table | FK Name | Child Column(s) | Parent Table | Parent Column(s) | ON DELETE | ON UPDATE |
|-------------|---------|-----------------|--------------|------------------|-----------|-----------|
| **saved_search** | saved_search_FK_1 | added_by | perseus_user | id | NO ACTION | NO ACTION |
| **smurf_goo_type** | smurf_goo_type_FK_1 | smurf_id | smurf | id | NO ACTION | NO ACTION |
| **smurf_goo_type** | smurf_goo_type_FK_2 | goo_type_id | goo_type | id | CASCADE | NO ACTION |
| **smurf_group** | sg_creator_FK_1 | added_by | perseus_user | id | NO ACTION | NO ACTION |
| **smurf_group_member** | smurf_group_member_FK_1 | smurf_id | smurf | id | CASCADE | NO ACTION |
| **smurf_group_member** | smurf_group_member_FK_2 | smurf_group_id | smurf_group | id | CASCADE | NO ACTION |
| **smurf_property** | smurf_property_FK_1 | property_id | property | id | CASCADE | NO ACTION |
| **smurf_property** | smurf_property_FK_2 | smurf_id | smurf | id | CASCADE | NO ACTION |
| **submission** | (unnamed) | submitter_id | perseus_user | id | NO ACTION | NO ACTION |
| **submission_entry** | (unnamed) | assay_type_id | smurf | id | NO ACTION | NO ACTION |
| **submission_entry** | (unnamed) | material_id | goo | id | NO ACTION | NO ACTION |
| **submission_entry** | (unnamed) | prepped_by_id | perseus_user | id | NO ACTION | NO ACTION |
| **submission_entry** | (unnamed) | submission_id | submission | id | NO ACTION | NO ACTION |

### T-W Tables

| Child Table | FK Name | Child Column(s) | Parent Table | Parent Column(s) | ON DELETE | ON UPDATE |
|-------------|---------|-----------------|--------------|------------------|-----------|-----------|
| **transition_material** | FK_transition_material_fatsmurf | transition_id | fatsmurf | uid | CASCADE | NO ACTION |
| **transition_material** | FK_transition_material_goo | material_id | goo | uid | CASCADE | **CASCADE** |
| **workflow** | workflow_creator_FK_1 | added_by | perseus_user | id | NO ACTION | NO ACTION |
| **workflow** | workflow_manufacturer_id_FK_1 | manufacturer_id | manufacturer | id | NO ACTION | NO ACTION |
| **workflow_attachment** | workflow_attachment_FK_1 | added_by | perseus_user | id | NO ACTION | NO ACTION |
| **workflow_attachment** | workflow_attachment_FK_2 | workflow_id | workflow | id | CASCADE | NO ACTION |
| **workflow_section** | workflow_section_FK_1 | workflow_id | workflow | id | CASCADE | NO ACTION |
| **workflow_section** | workflow_step_start_FK_1 | starting_step_id | workflow_step | id | NO ACTION | NO ACTION |
| **workflow_step** | FK_workflow_step_goo_type | goo_type_id | goo_type | id | NO ACTION | NO ACTION |
| **workflow_step** | FK_workflow_step_property | property_id | property | id | NO ACTION | NO ACTION |
| **workflow_step** | FK_workflow_step_smurf | smurf_id | smurf | id | NO ACTION | NO ACTION |
| **workflow_step** | FK_workflow_step_workflow | scope_id | workflow | id | CASCADE | NO ACTION |
| **workflow_step** | workflow_step_unit_FK_1 | goo_amount_unit_id | unit | id | NO ACTION | NO ACTION |

---

## Special FK Constraint Types

### ON DELETE CASCADE (40 constraints)

Tables where parent deletion CASCADE deletes to child:

| Parent Table | Child Table(s) | Count |
|--------------|----------------|-------|
| container | robot_log_container_sequence | 1 |
| display_layout | field_map_display_type | 1 |
| display_type | field_map_display_type | 1 |
| **fatsmurf (uid)** | material_transition, transition_material | 2 |
| fatsmurf | fatsmurf_attachment, fatsmurf_comment, fatsmurf_history, fatsmurf_reading | 4 |
| fatsmurf_reading | poll | 1 |
| field_map | field_map_display_type | 1 |
| **goo (uid)** | material_transition, transition_material | 2 |
| goo | goo_attachment, goo_comment, goo_history | 3 |
| goo_type | smurf_goo_type | 1 |
| goo_type_combine_target | goo_type_combine_component | 1 |
| history | container_history, fatsmurf_history, goo_history, history_value, poll_history | 5 |
| material_inventory_threshold | material_inventory_threshold_notify_user | 1 |
| perseus_user | field_map_display_type_user | 1 |
| poll | poll_history | 1 |
| property | robot_log_read, smurf_property | 2 |
| robot_log | robot_log_container_sequence, robot_log_error, robot_log_read, robot_log_transfer | 4 |
| sequence_type | robot_log_container_sequence | 1 |
| smurf | smurf_group_member, smurf_property | 2 |
| smurf_group | smurf_group_member | 1 |
| workflow | workflow_attachment, workflow_section, workflow_step | 3 |

### ON DELETE SET NULL (4 constraints)

| Parent Table | Child Table | Child Column |
|--------------|-------------|--------------|
| container | fatsmurf | container_id |
| container | goo | container_id |
| workflow_step | fatsmurf | workflow_step_id |
| workflow_step | goo | workflow_step_id |

### ON UPDATE CASCADE (2 constraints - UNIQUE)

**CRITICAL**: These are the ONLY two constraints with ON UPDATE CASCADE in the entire database.

| Parent Table | Child Table | FK Constraint | Parent Column | Child Column |
|--------------|-------------|---------------|---------------|--------------|
| goo (uid) | material_transition | FK_material_transition_goo | uid | material_id |
| goo (uid) | transition_material | FK_transition_material_goo | uid | material_id |

**Note**: These are UID-based (nvarchar) foreign keys, not integer-based.

---

## Unnamed FK Constraints (25 total)

These FK constraints have NULL fk_name in the metadata and will receive PostgreSQL auto-generated names:

| # | Child Table | Child Column | Parent Table | Parent Column |
|---|-------------|--------------|--------------|---------------|
| 1 | feed_type | added_by | perseus_user | id |
| 2 | feed_type | updated_by_id | perseus_user | id |
| 3 | material_inventory | allocation_container_id | container | id |
| 4 | material_inventory | created_by_id | perseus_user | id |
| 5 | material_inventory | location_container_id | container | id |
| 6 | material_inventory | material_id | goo | id |
| 7 | material_inventory | recipe_id | recipe | id |
| 8 | material_inventory | updated_by_id | perseus_user | id |
| 9 | material_qc | material_id | goo | id |
| 10 | recipe | added_by | perseus_user | id |
| 11 | recipe | feed_type_id | feed_type | id |
| 12 | recipe | goo_type_id | goo_type | id |
| 13 | recipe | workflow_id | workflow | id |
| 14 | recipe_part | goo_type_id | goo_type | id |
| 15 | recipe_part | part_recipe_id | recipe | id |
| 16 | recipe_part | recipe_id | recipe | id |
| 17 | recipe_part | unit_id | unit | id |
| 18 | recipe_part | workflow_step_id | workflow_step | id |
| 19 | recipe_project_assignment | recipe_id | recipe | id |
| 20 | robot_log | robot_log_type_id | robot_log_type | id |
| 21 | submission | submitter_id | perseus_user | id |
| 22 | submission_entry | assay_type_id | smurf | id |
| 23 | submission_entry | material_id | goo | id |
| 24 | submission_entry | prepped_by_id | perseus_user | id |
| 25 | submission_entry | submission_id | submission | id |

---

## Duplicate FK Constraints (3 constraints to SAME column)

**CRITICAL ISSUE**: perseus_user table has 3 DUPLICATE foreign key constraints to manufacturer.id.

| Child Table | Column | Parent Table | Parent Column | Constraint Names |
|-------------|--------|--------------|---------------|------------------|
| perseus_user | manufacturer_id | manufacturer | id | FK__perseus_u__manuf__5B3C942F |
| perseus_user | manufacturer_id | manufacturer | id | FK__perseus_u__manuf__5E1900DA |
| perseus_user | manufacturer_id | manufacturer | id | FK__perseus_u__manuf__6001494C |

**Resolution**: PostgreSQL will reject duplicate FK definitions. Create only ONE FK constraint:
```sql
ALTER TABLE dbo.perseus_user
ADD CONSTRAINT fk_perseus_user_manufacturer
FOREIGN KEY (manufacturer_id)
REFERENCES dbo.manufacturer(id)
ON DELETE NO ACTION
ON UPDATE NO ACTION;
```

---

## UID-Based Foreign Keys (Non-Integer)

These FK constraints reference `uid` columns (nvarchar) instead of integer `id` columns:

| Child Table | Child Column | Parent Table | Parent Column | Data Type | ON DELETE | ON UPDATE |
|-------------|--------------|--------------|---------------|-----------|-----------|-----------|
| material_transition | material_id | goo | uid | nvarchar(50) | CASCADE | **CASCADE** |
| material_transition | transition_id | fatsmurf | uid | nvarchar(50) | CASCADE | NO ACTION |
| transition_material | material_id | goo | uid | nvarchar(50) | CASCADE | **CASCADE** |
| transition_material | transition_id | fatsmurf | uid | nvarchar(50) | CASCADE | NO ACTION |

**PostgreSQL Migration Notes**:
1. Convert `nvarchar(50)` to `VARCHAR(50)` or `TEXT`
2. Ensure proper indexes on `goo.uid` and `fatsmurf.uid`
3. These are the ONLY constraints with ON UPDATE CASCADE
4. Critical for material lineage tracking (P0 tables)

---

## FK Constraints by Parent Table

Summary of how many child tables reference each parent:

| Parent Table | FK Count | Child Tables |
|--------------|----------|--------------|
| perseus_user | 24 | feed_type (×2), fatsmurf_attachment, fatsmurf_comment, fatsmurf_reading, field_map_display_type_user, goo, goo_attachment, goo_comment, history, material_inventory (×2), material_inventory_threshold (×2), material_inventory_threshold_notify_user, recipe, saved_search, smurf_group, submission, submission_entry, workflow, workflow_attachment |
| goo | 14 | goo_attachment, goo_comment, goo_history, material_inventory, material_qc, material_transition, robot_log_read, robot_log_transfer (×2), submission_entry, transition_material |
| container | 9 | container_history, fatsmurf, goo, material_inventory (×2), robot_log_container_sequence, robot_run |
| goo_type | 9 | coa, external_goo_type, goo, goo_type_combine_component, goo_type_combine_target, material_inventory_threshold, recipe, recipe_part, smurf_goo_type, workflow_step |
| fatsmurf | 8 | fatsmurf_attachment, fatsmurf_comment, fatsmurf_history, fatsmurf_reading, material_transition, transition_material |
| workflow | 6 | recipe, workflow_attachment, workflow_section, workflow_step |
| recipe | 6 | goo, material_inventory, recipe_part (×2), recipe_project_assignment |
| robot_log | 5 | robot_log_container_sequence, robot_log_error, robot_log_read, robot_log_transfer |
| history | 5 | container_history, fatsmurf_history, goo_history, history_value, poll_history |

---

## Document Metadata

| Field | Value |
|-------|-------|
| Version | 2.0 (Corrected) |
| Created | 2026-02-10 |
| Total FK Constraints | 124 |
| Named FK Constraints | 99 |
| Unnamed FK Constraints | 25 |
| Duplicate FK Constraints | 3 (same column) |
| ON DELETE CASCADE | 40 |
| ON DELETE SET NULL | 4 |
| ON UPDATE CASCADE | 2 (UID-based only) |
| Tables with FKs | 64 |
| Tables Referenced by FKs | 37 |
