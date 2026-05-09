# Catálogo de Tabelas SQL Server (AS-IS)
Diretório de origem:`source\\original\\sqlserver\\8. create-table`
Cada seção abaixo corresponde a um arquivo `.sql` com uma sentença `CREATE TABLE`.
As Column Names são apresentadas exatamente como definidas nos scripts (AS-IS).

---
[dbo].[Permissions]

Arquivo: 0. perseus.dbo.Permissions.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| emailAddress | nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL |
| permission | char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL |

---

[dbo].[PerseusTableAndRowCounts]

Arquivo: 1. perseus.dbo.PerseusTableAndRowCounts.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| TableName | nvarchar(128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| Rows | char(11) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| updated_on | datetime NOT NULL DEFAULT (getdate()) |

---

[dbo].[cm_unit_dimensions]

Arquivo: 10. perseus.dbo.cm_unit_dimensions.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| id | int NOT NULL |
| mass | numeric(10,2) NULL |
| length | numeric(10,2) NULL |
| time | numeric(10,2) NULL |
| electric_current | numeric(10,2) NULL |
| thermodynamic_temperature | numeric(10,2) NULL |
| amount_of_substance | numeric(10,2) NULL |
| luminous_intensity | numeric(10,2) NULL |
| default_unit_id | int NOT NULL |
| name | nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL |

---

[hermes].[run_master_condition_type]

Arquivo: 100. perseus.hermes.run_master_condition_type.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| id | int IDENTITY(1, 1) NOT NULL |
| name | varchar(max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| optional_order | int NULL |

---

[dbo].[cm_user]

Arquivo: 11. perseus.dbo.cm_user.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| user_id | int IDENTITY(1, 1) NOT NULL |
| domain_id | char(32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| is_active | bit NOT NULL |
| name | nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL |
| login | nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| email | nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| object_id | uniqueidentifier NULL |

---

[dbo].[cm_user_group]

Arquivo: 12. perseus.dbo.cm_user_group.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| user_id | int NOT NULL |
| group_id | int NOT NULL |

---

[dbo].[coa]

Arquivo: 13. perseus.dbo.coa.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| id | int IDENTITY(1, 1) NOT NULL |
| name | varchar(150) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL |
| goo_type_id | int NOT NULL |

---

[dbo].[coa_spec]

Arquivo: 14. perseus.dbo.coa_spec.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| id | int IDENTITY(1, 1) NOT NULL |
| coa_id | int NOT NULL |
| property_id | int NOT NULL |
| upper_bound | float(53) NULL |
| lower_bound | float(53) NULL |
| equal_bound | varchar(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| upper_equal_bound | float(53) NULL |
| lower_equal_bound | float(53) NULL |
| result_precision | int NULL DEFAULT ((0)) |

---

[dbo].[color]

Arquivo: 15. perseus.dbo.color.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| name | nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL |

---

[dbo].[container]

Arquivo: 16. perseus.dbo.container.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| id | int IDENTITY(1, 1) NOT NULL |
| container_type_id | int NOT NULL |
| name | varchar(128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| uid | nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL |
| mass | float(53) NULL |
| left_id | int NOT NULL DEFAULT ((1)) |
| right_id | int NOT NULL DEFAULT ((2)) |
| scope_id | nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL DEFAULT (newid()) |
| position_name | varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| position_x_coordinate | varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| position_y_coordinate | varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| depth | int NOT NULL DEFAULT ((0)) |
| created_on | datetime NULL DEFAULT (getdate()) |

---

[dbo].[container_history]

Arquivo: 17. perseus.dbo.container_history.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| id | int IDENTITY(1, 1) NOT NULL |
| history_id | int NOT NULL |
| container_id | int NOT NULL |

---

[dbo].[container_type]

Arquivo: 18. perseus.dbo.container_type.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| id | int IDENTITY(1, 1) NOT NULL |
| name | varchar(128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL |
| is_parent | int NOT NULL DEFAULT ((1)) |
| is_equipment | int NOT NULL DEFAULT ((0)) |
| is_single | int NOT NULL DEFAULT ((1)) |
| is_restricted | int NOT NULL DEFAULT ((0)) |
| is_gooable | int NOT NULL DEFAULT ((0)) |

---

[dbo].[container_type_position]

Arquivo: 19. perseus.dbo.container_type_position.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| id | int IDENTITY(1, 1) NOT NULL |
| parent_container_type_id | int NOT NULL |
| child_container_type_id | int NULL |
| position_name | varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| position_x_coordinate | varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| position_y_coordinate | varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |

---

[dbo].[Scraper]

Arquivo: 2. perseus.dbo.Scraper.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| ID | int IDENTITY(1, 1) NOT NULL |
| Timestamp | datetime NULL |
| Message | nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| FileType | char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| Filename | nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| FilenameSavedAs | nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| ReceivedFrom | nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| File | varbinary(max) NULL |
| Result | nvarchar(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| Complete | bit NULL |
| ScraperID | nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| ScrapingStartedOn | datetime NULL |
| ScrapingFinishedOn | datetime NULL |
| ScrapingStatus | nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| ScraperSendTo | nvarchar(max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| ScraperMessage | nvarchar(max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| Active | char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| ControlFileID | int NULL |
| DocumentID | nvarchar(25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |

---

[dbo].[display_layout]

Arquivo: 20. perseus.dbo.display_layout.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| id | int NOT NULL |
| name | varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL |

---

[dbo].[display_type]

Arquivo: 21. perseus.dbo.display_type.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| id | int NOT NULL |
| name | varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL |

---

[dbo].[external_goo_type]

Arquivo: 22. perseus.dbo.external_goo_type.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| id | int IDENTITY(1, 1) NOT NULL |
| goo_type_id | int NOT NULL |
| external_label | varchar(250) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL |
| manufacturer_id | int NOT NULL |

---

[dbo].[fatsmurf]

Arquivo: 23. perseus.dbo.fatsmurf.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| id | int IDENTITY(1, 1) NOT NULL |
| smurf_id | int NOT NULL |
| recycled_bottoms_id | int NULL |
| name | varchar(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| description | varchar(500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| added_on | datetime NOT NULL DEFAULT (getdate()) |
| run_on | datetime NULL |
| duration | float(53) NULL |
| added_by | int NOT NULL |
| themis_sample_id | int NULL |
| uid | nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL |
| run_complete | AS (case when [duration] IS NULL then getdate() else dateadd(minute,[duration]*(60),[run_on]) end) |
| container_id | int NULL |
| organization_id | int NULL DEFAULT ((1)) |
| workflow_step_id | int NULL |
| updated_on | datetime NULL DEFAULT (getdate()) |
| inserted_on | datetime NULL DEFAULT (getdate()) |
| triton_task_id | int NULL |

---

[dbo].[fatsmurf_attachment]

Arquivo: 24. perseus.dbo.fatsmurf_attachment.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| id | int IDENTITY(1, 1) NOT NULL |
| fatsmurf_id | int NOT NULL |
| added_on | datetime NOT NULL DEFAULT (getdate()) |
| added_by | int NOT NULL |
| description | text COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL |
| attachment_name | varchar(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| attachment_mime_type | varchar(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| attachment | image NULL |

---

[dbo].[fatsmurf_comment]

Arquivo: 25. perseus.dbo.fatsmurf_comment.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| id | int IDENTITY(1, 1) NOT NULL |
| fatsmurf_id | int NOT NULL |
| added_on | datetime NOT NULL DEFAULT (getdate()) |
| added_by | int NOT NULL |
| comment | nvarchar(max) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL |

---

[dbo].[fatsmurf_history]

Arquivo: 26. perseus.dbo.fatsmurf_history.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| id | int IDENTITY(1, 1) NOT NULL |
| history_id | int NOT NULL |
| fatsmurf_id | int NOT NULL |

---

[dbo].[fatsmurf_reading]

Arquivo: 27. perseus.dbo.fatsmurf_reading.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| id | int IDENTITY(1, 1) NOT NULL |
| name | varchar(150) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL |
| fatsmurf_id | int NOT NULL |
| added_on | datetime NOT NULL DEFAULT (getdate()) |
| added_by | int NOT NULL DEFAULT ((1)) |

---

[dbo].[feed_type]

Arquivo: 28. perseus.dbo.feed_type.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| id | int IDENTITY(1, 1) NOT NULL |
| added_by | int NOT NULL |
| updated_by_id | int NULL |
| name | varchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| description | text COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| correction_method | text COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL DEFAULT ('SIMPLE') |
| correction_factor | float(53) NOT NULL DEFAULT ((1.0)) |
| disabled | bit NOT NULL DEFAULT ((0)) |
| added_on | datetime NOT NULL DEFAULT (getdate()) |
| updated_on | datetime NULL DEFAULT (getdate()) |

---

[dbo].[field_map]

Arquivo: 29. perseus.dbo.field_map.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| id | int IDENTITY(1, 1) NOT NULL |
| field_map_block_id | int NOT NULL |
| name | varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| description | varchar(250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| display_order | int NULL |
| setter | varchar(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| lookup | varchar(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| lookup_service | varchar(250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| nullable | int NULL |
| field_map_type_id | int NOT NULL |
| database_id | varchar(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| save_sequence | int NOT NULL |
| onchange | varchar(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| field_map_set_id | int NOT NULL |

---

[dbo].[alembic_version]

Arquivo: 3. perseus.dbo.alembic_version.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| version_num | varchar(32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL |

---

[dbo].[field_map_block]

Arquivo: 30. perseus.dbo.field_map_block.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| id | int IDENTITY(1, 1) NOT NULL |
| filter | varchar(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| scope | varchar(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |

---

[dbo].[field_map_display_type]

Arquivo: 31. perseus.dbo.field_map_display_type.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| id | int IDENTITY(1, 1) NOT NULL |
| field_map_id | int NOT NULL |
| display_type_id | int NOT NULL |
| display | varchar(150) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL |
| display_layout_id | int NOT NULL DEFAULT ((1)) |
| manditory | int NOT NULL DEFAULT ((0)) |

---

[dbo].[field_map_display_type_user]

Arquivo: 32. perseus.dbo.field_map_display_type_user.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| id | int IDENTITY(1, 1) NOT NULL |
| field_map_display_type_id | int NOT NULL |
| user_id | int NOT NULL |

---

[dbo].[field_map_set]

Arquivo: 33. perseus.dbo.field_map_set.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| id | int NOT NULL |
| tab_group_id | int NULL |
| display_order | int NULL |
| name | varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| color | varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| size | int NULL |

---

[dbo].[field_map_type]

Arquivo: 34. perseus.dbo.field_map_type.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| id | int NOT NULL |
| name | varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL |

---

[dbo].[goo]

Arquivo: 35. perseus.dbo.goo.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| id | int IDENTITY(1, 1) NOT NULL |
| name | varchar(250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| description | varchar(1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| added_on | datetime NOT NULL DEFAULT (getdate()) |
| added_by | int NOT NULL |
| original_volume | float(53) NULL DEFAULT ((0)) |
| original_mass | float(53) NULL DEFAULT ((0)) |
| goo_type_id | int NOT NULL DEFAULT ((8)) |
| manufacturer_id | int NOT NULL DEFAULT ((1)) |
| received_on | date NULL |
| uid | nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL |
| project_id | smallint NULL |
| container_id | int NULL |
| workflow_step_id | int NULL |
| updated_on | datetime NULL DEFAULT (getdate()) |
| inserted_on | datetime NULL DEFAULT (getdate()) |
| triton_task_id | int NULL |
| recipe_id | int NULL |
| recipe_part_id | int NULL |
| catalog_label | varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |

---

[dbo].[goo_attachment]

Arquivo: 36. perseus.dbo.goo_attachment.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| id | int IDENTITY(1, 1) NOT NULL |
| goo_id | int NOT NULL |
| added_on | datetime NOT NULL DEFAULT (getdate()) |
| added_by | int NOT NULL |
| description | varchar(250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| attachment_name | varchar(150) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL |
| attachment_mime_type | varchar(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| attachment | image NULL |
| goo_attachment_type_id | int NULL |

---

[dbo].[goo_attachment_type]

Arquivo: 37. perseus.dbo.goo_attachment_type.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| id | int IDENTITY(1, 1) NOT NULL |
| name | varchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL |

---

[dbo].[goo_comment]

Arquivo: 38. perseus.dbo.goo_comment.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| id | int IDENTITY(1, 1) NOT NULL |
| goo_id | int NOT NULL |
| added_on | datetime NOT NULL DEFAULT (getdate()) |
| added_by | int NOT NULL |
| comment | text COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL |
| category | varchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |

---

[dbo].[goo_history]

Arquivo: 39. perseus.dbo.goo_history.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| id | int IDENTITY(1, 1) NOT NULL |
| history_id | int NOT NULL |
| goo_id | int NOT NULL |

---

[dbo].[cm_application]

Arquivo: 4. perseus.dbo.cm_application.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| application_id | int NOT NULL |
| label | varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL |
| description | varchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL |
| is_active | tinyint NOT NULL |
| application_group_id | int NULL |
| url | varchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| owner_user_id | int NULL |
| jira_id | varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |

---

[dbo].[goo_process_queue_type]

Arquivo: 40. perseus.dbo.goo_process_queue_type.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| id | int IDENTITY(1, 1) NOT NULL |
| name | varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL |

---

[dbo].[goo_type]

Arquivo: 41. perseus.dbo.goo_type.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| id | int IDENTITY(1, 1) NOT NULL |
| name | varchar(128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL |
| color | varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| left_id | int NOT NULL |
| right_id | int NOT NULL |
| scope_id | nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL |
| disabled | int NOT NULL DEFAULT ((0)) |
| casrn | varchar(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| iupac | varchar(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| depth | int NOT NULL DEFAULT ((0)) |
| abbreviation | varchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| density_kg_l | float(53) NULL |

---

[dbo].[goo_type_combine_component]

Arquivo: 42. perseus.dbo.goo_type_combine_component.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| id | int IDENTITY(1, 1) NOT NULL |
| goo_type_combine_target_id | int NOT NULL |
| goo_type_id | int NOT NULL |

---

[dbo].[goo_type_combine_target]

Arquivo: 43. perseus.dbo.goo_type_combine_target.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| id | int IDENTITY(1, 1) NOT NULL |
| goo_type_id | int NOT NULL |
| sort_order | int NOT NULL |

---

[dbo].[history]

Arquivo: 44. perseus.dbo.history.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| id | int IDENTITY(1, 1) NOT NULL |
| history_type_id | int NOT NULL |
| creator_id | int NOT NULL |
| created_on | datetime NOT NULL DEFAULT (getdate()) |

---

[dbo].[history_type]

Arquivo: 45. perseus.dbo.history_type.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| id | int IDENTITY(1, 1) NOT NULL |
| name | varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL |
| format | varchar(250) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL |

---

[dbo].[history_value]

Arquivo: 46. perseus.dbo.history_value.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| id | int IDENTITY(1, 1) NOT NULL |
| history_id | int NOT NULL |
| value | varchar(250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |

---

[dbo].[m_downstream]

Arquivo: 47. perseus.dbo.m_downstream.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| start_point | nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL |
| end_point | nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL |
| path | varchar(500) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL |
| level | int NOT NULL |

---

[dbo].[m_number]

Arquivo: 48. perseus.dbo.m_number.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| id | int IDENTITY(900000, 1) NOT NULL |

---

[dbo].[m_upstream]

Arquivo: 49. perseus.dbo.m_upstream.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| start_point | nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL |
| end_point | nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL |
| path | varchar(500) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL |
| level | int NOT NULL |

---

[dbo].[cm_application_group]

Arquivo: 5. perseus.dbo.cm_application_group.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| application_group_id | int IDENTITY(1, 1) NOT NULL |
| label | varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL |

---

[dbo].[m_upstream_dirty_leaves]

Arquivo: 50. perseus.dbo.m_upstream_dirty_leaves.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| material_uid | varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL |

---

[dbo].[manufacturer]

Arquivo: 51. perseus.dbo.manufacturer.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| id | int IDENTITY(1, 1) NOT NULL |
| name | varchar(128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL |
| location | varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| goo_prefix | varchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |

---

[dbo].[material_inventory]

Arquivo: 52. perseus.dbo.material_inventory.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| id | int IDENTITY(1, 1) NOT NULL |
| material_id | int NOT NULL |
| location_container_id | int NOT NULL |
| is_active | bit NOT NULL |
| current_volume_l | real NULL |
| current_mass_kg | real NULL |
| created_by_id | int NOT NULL |
| created_on | datetime NULL |
| updated_by_id | int NULL |
| updated_on | datetime NULL |
| allocation_container_id | int NULL |
| recipe_id | int NULL |
| comment | text COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| expiration_date | date NULL |

---

[dbo].[material_inventory_threshold]

Arquivo: 53. perseus.dbo.material_inventory_threshold.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| id | int IDENTITY(1, 1) NOT NULL |
| material_type_id | int NOT NULL |
| min_item_count | int NULL |
| max_item_count | int NULL |
| min_volume_l | float(53) NULL |
| max_volume_l | float(53) NULL |
| min_mass_kg | float(53) NULL |
| max_mass_kg | float(53) NULL |
| created_by_id | int NOT NULL |
| created_on | datetime2(7) NOT NULL DEFAULT (getdate()) |
| updated_by_id | int NULL |
| updated_on | datetime2(7) NULL |

---

[dbo].[material_inventory_threshold_notify_user]

Arquivo: 54. perseus.dbo.material_inventory_threshold_notify_user.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| threshold_id | int NOT NULL |
| user_id | int NOT NULL |

---

[dbo].[material_qc]

Arquivo: 55. perseus.dbo.material_qc.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| id | int IDENTITY(1, 1) NOT NULL |
| material_id | int NOT NULL |
| entity_type_name | text COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL |
| foreign_entity_id | int NOT NULL |
| qc_process_uid | text COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL |

---

[dbo].[material_transition]

Arquivo: 56. perseus.dbo.material_transition.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| material_id | nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL |
| transition_id | nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL |
| added_on | datetime NOT NULL DEFAULT (getdate()) |

---

[dbo].[migration]

Arquivo: 57. perseus.dbo.migration.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| id | int NOT NULL |
| description | varchar(256) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL |
| created_on | datetime NOT NULL DEFAULT (getdate()) |

---

[dbo].[perseus_user]

Arquivo: 58. perseus.dbo.perseus_user.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| id | int IDENTITY(1, 1) NOT NULL |
| name | varchar(128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL |
| domain_id | varchar(250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| login | varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| mail | varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| admin | int NOT NULL DEFAULT ((0)) |
| super | int NOT NULL DEFAULT ((0)) |
| common_id | int NULL |
| manufacturer_id | int NOT NULL DEFAULT ((1)) |

---

[dbo].[person]

Arquivo: 59. perseus.dbo.person.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| id | int NOT NULL |
| domain_id | char(32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL |
| km_session_id | char(32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| login | nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL |
| name | nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL |
| email | varchar(254) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| last_login | datetime NULL |
| is_active | bit NOT NULL DEFAULT ((1)) |

---

[dbo].[cm_group]

Arquivo: 6. perseus.dbo.cm_group.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| group_id | int IDENTITY(1, 1) NOT NULL |
| name | varchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL |
| domain_id | char(32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL |
| is_active | bit NOT NULL |
| last_modified | smalldatetime NOT NULL |

---

[dbo].[poll]

Arquivo: 60. perseus.dbo.poll.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| id | int IDENTITY(1, 1) NOT NULL |
| smurf_property_id | int NOT NULL |
| fatsmurf_reading_id | int NOT NULL |
| value | varchar(2048) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| standard_deviation | float(53) NULL |
| detection | int NULL |
| limit_of_detection | float(53) NULL |
| limit_of_quantification | float(53) NULL |
| lower_calibration_limit | float(53) NULL |
| upper_calibration_limit | float(53) NULL |
| bounds_limit | int NULL |

---

[dbo].[poll_history]

Arquivo: 61. perseus.dbo.poll_history.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| id | int IDENTITY(1, 1) NOT NULL |
| history_id | int NOT NULL |
| poll_id | int NOT NULL |

---

[dbo].[prefix_incrementor]

Arquivo: 62. perseus.dbo.prefix_incrementor.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| prefix | varchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL |
| counter | int NOT NULL |

---

[dbo].[property]

Arquivo: 63. perseus.dbo.property.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| id | int IDENTITY(1, 1) NOT NULL |
| name | varchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL |
| description | varchar(500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| unit_id | int NULL |

---

[dbo].[property_option]

Arquivo: 64. perseus.dbo.property_option.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| id | int IDENTITY(1, 1) NOT NULL |
| property_id | int NOT NULL |
| value | int NOT NULL |
| label | varchar(150) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL |
| disabled | int NOT NULL DEFAULT ((0)) |

---

[dbo].[recipe]

Arquivo: 65. perseus.dbo.recipe.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| id | int IDENTITY(1, 1) NOT NULL |
| name | varchar(200) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL |
| goo_type_id | int NOT NULL |
| description | varchar(max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| sop | varchar(max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| workflow_id | int NULL |
| added_by | int NOT NULL |
| added_on | datetime NOT NULL |
| is_preferred | bit NOT NULL DEFAULT ((0)) |
| QC | bit NOT NULL DEFAULT ((0)) |
| is_archived | bit NOT NULL DEFAULT ((0)) |
| feed_type_id | int NULL |
| stock_concentration | float(53) NULL |
| sterilization_method | varchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| inoculant_percent | float(53) NULL |
| post_inoc_volume_ml | float(53) NULL |

---

[dbo].[recipe_part]

Arquivo: 66. perseus.dbo.recipe_part.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| id | int IDENTITY(1, 1) NOT NULL |
| recipe_id | int NOT NULL |
| description | varchar(max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| goo_type_id | int NOT NULL |
| amount | float(53) NOT NULL |
| unit_id | int NOT NULL |
| workflow_step_id | int NULL |
| position | int NULL |
| part_recipe_id | int NULL |
| target_conc_in_media | float(53) NULL |
| target_post_inoc_conc | float(53) NULL |

---

[dbo].[recipe_project_assignment]

Arquivo: 67. perseus.dbo.recipe_project_assignment.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| project_id | smallint NOT NULL |
| recipe_id | int NOT NULL |

---

[dbo].[robot_log]

Arquivo: 68. perseus.dbo.robot_log.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| id | int IDENTITY(1, 1) NOT NULL |
| class_id | int NOT NULL |
| source | varchar(250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| created_on | datetime NOT NULL DEFAULT (getdate()) |
| log_text | varchar(max) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL |
| file_name | varchar(250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| robot_log_checksum | varchar(32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| started_on | datetime NULL |
| completed_on | datetime NULL |
| loaded_on | datetime NULL |
| loaded | int NOT NULL DEFAULT ((0)) |
| loadable | int NOT NULL DEFAULT ((0)) |
| robot_run_id | int NULL |
| robot_log_type_id | int NOT NULL |

---

[dbo].[robot_log_container_sequence]

Arquivo: 69. perseus.dbo.robot_log_container_sequence.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| id | int IDENTITY(1, 1) NOT NULL |
| robot_log_id | int NOT NULL |
| container_id | int NOT NULL |
| sequence_type_id | int NOT NULL |
| processed_on | datetime NULL |

---

[dbo].[cm_project]

Arquivo: 7. perseus.dbo.cm_project.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| project_id | smallint NOT NULL |
| label | varchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL |
| is_active | bit NOT NULL |
| display_order | smallint NOT NULL |
| group_id | int NULL |

---

[dbo].[robot_log_error]

Arquivo: 70. perseus.dbo.robot_log_error.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| id | int IDENTITY(1, 1) NOT NULL |
| robot_log_id | int NOT NULL |
| error_text | varchar(max) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL |

---

[dbo].[robot_log_read]

Arquivo: 71. perseus.dbo.robot_log_read.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| id | int IDENTITY(1, 1) NOT NULL |
| robot_log_id | int NOT NULL |
| source_barcode | nvarchar(25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL |
| property_id | int NOT NULL |
| value | varchar(25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| source_position | nvarchar(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| source_material_id | int NULL |

---

[dbo].[robot_log_transfer]

Arquivo: 72. perseus.dbo.robot_log_transfer.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| id | int IDENTITY(1, 1) NOT NULL |
| robot_log_id | int NOT NULL |
| source_barcode | nvarchar(25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL |
| destination_barcode | nvarchar(25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL |
| transfer_time | datetime NULL |
| transfer_volume | varchar(25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| source_position | nvarchar(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| destination_position | nvarchar(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| material_type_id | int NULL |
| source_material_id | int NULL |
| destination_material_id | int NULL |

---

[dbo].[robot_log_type]

Arquivo: 73. perseus.dbo.robot_log_type.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| id | int IDENTITY(1, 1) NOT NULL |
| name | varchar(150) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL |
| auto_process | int NOT NULL |
| destination_container_type_id | int NULL |

---

[dbo].[robot_run]

Arquivo: 74. perseus.dbo.robot_run.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| id | int IDENTITY(1, 1) NOT NULL |
| robot_id | int NULL |
| name | varchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL |
| all_qc_passed | bit NULL |
| all_themis_submitted | bit NULL |

---

[dbo].[s_number]

Arquivo: 75. perseus.dbo.s_number.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| id | int IDENTITY(1100000, 1) NOT NULL |

---

[dbo].[saved_search]

Arquivo: 76. perseus.dbo.saved_search.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| id | int IDENTITY(1, 1) NOT NULL |
| class_id | int NULL |
| name | varchar(128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL |
| added_on | datetime NOT NULL DEFAULT (getdate()) |
| added_by | int NOT NULL |
| is_private | int NOT NULL DEFAULT ((1)) |
| include_downstream | int NOT NULL DEFAULT ((0)) |
| parameter_string | varchar(2500) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL |

---

[dbo].[sequence_type]

Arquivo: 77. perseus.dbo.sequence_type.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| id | int IDENTITY(1, 1) NOT NULL |
| name | varchar(25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL |

---

[dbo].[smurf]

Arquivo: 78. perseus.dbo.smurf.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| id | int IDENTITY(1, 1) NOT NULL |
| class_id | int NOT NULL |
| name | varchar(150) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL |
| description | varchar(500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| themis_method_id | int NULL |
| disabled | int NOT NULL DEFAULT ((0)) |

---

[dbo].[smurf_goo_type]

Arquivo: 79. perseus.dbo.smurf_goo_type.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| id | int IDENTITY(1, 1) NOT NULL |
| smurf_id | int NOT NULL |
| goo_type_id | int NULL |
| is_input | int NOT NULL DEFAULT ((0)) |

---

[dbo].[cm_unit]

Arquivo: 8. perseus.dbo.cm_unit.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| id | int NOT NULL |
| description | nvarchar(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| longname | nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| dimensions_id | int NULL |
| name | nvarchar(25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| factor | numeric(20,10) NULL |
| offset | numeric(20,10) NULL |

---

[dbo].[smurf_group]

Arquivo: 80. perseus.dbo.smurf_group.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| id | int IDENTITY(1, 1) NOT NULL |
| name | varchar(150) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL |
| added_by | int NOT NULL |
| is_public | int NOT NULL DEFAULT ((0)) |

---

[dbo].[smurf_group_member]

Arquivo: 81. perseus.dbo.smurf_group_member.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| id | int IDENTITY(1, 1) NOT NULL |
| smurf_group_id | int NOT NULL |
| smurf_id | int NOT NULL |

---

[dbo].[smurf_property]

Arquivo: 82. perseus.dbo.smurf_property.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| id | int IDENTITY(1, 1) NOT NULL |
| property_id | int NOT NULL |
| sort_order | int NOT NULL DEFAULT ((99)) |
| smurf_id | int NOT NULL |
| disabled | int NOT NULL DEFAULT ((0)) |
| calculated | varchar(250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |

---

[dbo].[submission]

Arquivo: 83. perseus.dbo.submission.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| id | int IDENTITY(1, 1) NOT NULL |
| submitter_id | int NOT NULL |
| added_on | datetime NOT NULL |
| label | varchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |

---

[dbo].[submission_entry]

Arquivo: 84. perseus.dbo.submission_entry.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| id | int IDENTITY(1, 1) NOT NULL |
| assay_type_id | int NOT NULL |
| material_id | int NOT NULL |
| status | varchar(19) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL |
| priority | varchar(6) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL |
| submission_id | int NOT NULL |
| prepped_by_id | int NULL |
| themis_tray_id | int NULL |
| sample_type | varchar(7) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL |

---

[dbo].[tmp_messy_links]

Arquivo: 85. perseus.dbo.tmp_messy_links.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| source_transition | nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL |
| source_name | varchar(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| destination_transition | nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL |
| desitnation_name | varchar(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| material_id | nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL |

---

[dbo].[transition_material]

Arquivo: 86. perseus.dbo.transition_material.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| transition_id | nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL |
| material_id | nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL |

---

[dbo].[unit]

Arquivo: 87. perseus.dbo.unit.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| id | int IDENTITY(1, 1) NOT NULL |
| name | varchar(25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL |
| description | varchar(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| dimension_id | int NULL |
| factor | float(53) NULL |
| offset | float(53) NULL |

---

[dbo].[workflow]

Arquivo: 88. perseus.dbo.workflow.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| id | int IDENTITY(1, 1) NOT NULL |
| name | varchar(150) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL |
| added_on | datetime NOT NULL DEFAULT (getdate()) |
| added_by | int NOT NULL DEFAULT ((23)) |
| disabled | int NOT NULL DEFAULT ((0)) |
| manufacturer_id | int NOT NULL |
| description | varchar(1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| category | varchar(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |

---

[dbo].[workflow_attachment]

Arquivo: 89. perseus.dbo.workflow_attachment.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| id | int IDENTITY(1, 1) NOT NULL |
| workflow_id | int NOT NULL |
| added_on | datetime NOT NULL DEFAULT (getdate()) |
| added_by | int NOT NULL |
| attachment_name | varchar(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| attachment_mime_type | varchar(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| attachment | varbinary(max) NULL |

---

[dbo].[cm_unit_compare]

Arquivo: 9. perseus.dbo.cm_unit_compare.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| from_unit_id | int NOT NULL |
| to_unit_id | int NOT NULL |

---

[dbo].[workflow_section]

Arquivo: 90. perseus.dbo.workflow_section.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| id | int IDENTITY(1, 1) NOT NULL |
| workflow_id | int NOT NULL |
| name | varchar(150) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL |
| starting_step_id | int NOT NULL |

---

[dbo].[workflow_step]

Arquivo: 91. perseus.dbo.workflow_step.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| id | int IDENTITY(1, 1) NOT NULL |
| left_id | int NULL |
| right_id | int NULL |
| scope_id | int NOT NULL |
| class_id | int NOT NULL |
| name | varchar(150) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL |
| smurf_id | int NULL |
| goo_type_id | int NULL |
| property_id | int NULL |
| label | varchar(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| optional | tinyint NOT NULL DEFAULT ((0)) |
| goo_amount_unit_id | int NULL DEFAULT ((61)) |
| depth | int NULL |
| description | varchar(1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| RECIPE_FACTOR | float(53) NULL |
| parent_id | int NULL |
| child_order | int NULL |

---

[dbo].[workflow_step_type]

Arquivo: 92. perseus.dbo.workflow_step_type.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| id | int NOT NULL |
| name | varchar(150) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL |

---

[demeter].[barcodes]

Arquivo: 93. perseus.demeter.barcodes.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| id | int IDENTITY(1, 1) NOT NULL |
| barcode | varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL |
| seedvial_id | int NOT NULL |

---

[demeter].[seed_vials]

Arquivo: 94. perseus.demeter.seed_vials.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| id | int IDENTITY(1, 1) NOT NULL |
| strain | nvarchar(30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL |
| clone_id | varchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| end_date | date NULL |
| nat_plating_seedvial | nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| nat_plating_48hr_od | nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| contamination_testing_notes | nvarchar(250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| nr_to_historical | numeric(10,2) NULL |
| pa_to_historical | numeric(10,2) NULL |
| jet_to_historical | numeric(10,2) NULL |
| project | varchar(30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| growth_media | varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| antibioticos_inventory | int NULL |
| campinas_inventory | int NULL |
| tandl_inventory | int NULL |
| viability_pre_na | varchar(5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| ssod_to_historical_na | varchar(5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| uv_fene_to_historical_na | varchar(5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| nr_to_historical_na | varchar(5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| pa_to_historical_na | varchar(5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| jet_to_historical_na | varchar(5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| uv_fene_to_historical | numeric(10,2) NULL |

---

[hermes].[run]

Arquivo: 95. perseus.hermes.run.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| id | int IDENTITY(1, 1) NOT NULL |
| experiment_id | int NULL |
| local_id | int NULL |
| chart_legend | nvarchar(100) COLLATE SQL_Latin1_General_CP1_CS_AS NULL |
| description | nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| strain | nvarchar(30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL |
| resultant_material | varchar(max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| feedstock_material | nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| fermentation_type_id | int NULL |
| start_time | datetime NULL |
| induction_time | numeric(10,2) NULL |
| induction_od | numeric(10,2) NULL |
| stop_time | numeric(10,2) NULL |
| max_yield | numeric(15,5) NULL |
| max_productivity | numeric(15,5) NULL |
| max_titer | numeric(15,5) NULL |
| total_product | numeric(15,5) NULL |
| yield_calculator_state | nvarchar(4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| productivity_method | numeric(5,1) NULL |
| productivity_notes | nvarchar(400) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| peak_titer_time | numeric(10,2) NULL |
| mfcs_file | nvarchar(250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| bioreactor_label | nvarchar(30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| shaker_ids | nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| platform_ids | nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| media_batch_label | nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| overlay_batch_label | nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| last_mfcs | datetime NULL |
| mfcs_status | varchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| mfcs_status_time | datetime NULL |
| mfcs_status_message | nvarchar(400) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| created_on | datetime NULL |
| updated_on | datetime NULL |
| max_updated_on | datetime NULL |
| tank | nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| fad_cycle | int NULL |
| creator_id | int NULL |
| updator_id | int NULL |
| max_updated_by_id | int NULL |
| protocol_id | int NULL |
| mfcs_user_id | int NULL |
| seed_vial_freeze_date | datetime NULL |
| volume_recovered | numeric(15,5) NULL |
| volume_missing | numeric(15,5) NULL |
| carbon_balance_method | numeric(5,1) NULL |
| carbon_balance | numeric(6,3) NULL |
| carbon_balance_state | nvarchar(4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| carbon_balance_user_id | int NULL |
| carbon_balance_date | datetime NULL |
| seed_vial_id | int NULL |
| yield_published | bit NULL |
| yield_publisher_id | int NULL |
| yield_publish_date | datetime NULL |
| yield_range_start | numeric(10,2) NULL |
| yield_range_end | numeric(10,2) NULL |
| project_id | int NULL |
| sugar_source | nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| total_sugar | numeric(15,5) NULL |
| yield_on_sucrose | numeric(15,5) NULL |
| yield_on_trs | numeric(15,5) NULL |
| feedstock_material_barcode | varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| trigger_time | numeric(10,2) NULL |
| product_id | int NULL |
| seed_vial_barcode | varchar(max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| seed_train_barcode | varchar(max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| seed_train_material | varchar(max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| calc_source_generated_date | datetime NULL |
| overlay_id | int NULL |
| curated_interval | nvarchar(16) COLLATE SQL_Latin1_General_CP1_CS_AS NULL |
| specification_association_date | datetime NULL |
| specification_AB_result | varchar(7) COLLATE SQL_Latin1_General_CP1_CS_AS NULL |
| specification_GD_result | varchar(7) COLLATE SQL_Latin1_General_CP1_CS_AS NULL |
| mfcs_protocol_id | int NULL |
| purpose_id | int NULL |
| inoculum_amount | numeric(15,6) NULL |
| seed_vial_notes | nvarchar(1000) COLLATE SQL_Latin1_General_CP1_CS_AS NULL |
| crystal_morphology | varchar(9) COLLATE SQL_Latin1_General_CP1_CS_AS NULL |
| fermentation_stage_id | int NULL |
| tier | varchar(1) COLLATE SQL_Latin1_General_CP1_CS_AS NULL |
| seed_vial_thaw_date | date NULL |
| intended_parent_run_id | int NULL |
| scheduled_start | datetime NULL |
| scheduled_tank | nvarchar(10) COLLATE SQL_Latin1_General_CP1_CS_AS NULL |
| resin_id | int NULL |
| strain_id | int NULL |
| ambr_input_created_on | datetime NULL |
| expected_post_inoculation_volume | numeric(15,3) NULL |
| target_inoculum_amount | numeric(15,6) NULL |
| second_feedstock_material | varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| second_feedstock_material_barcode | varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |

---

[hermes].[run_condition]

Arquivo: 96. perseus.hermes.run_condition.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| id | int IDENTITY(1, 1) NOT NULL |
| default_value | numeric(11,3) NULL |
| condition_set_id | int NULL |
| master_condition_id | int NULL |

---

[hermes].[run_condition_option]

Arquivo: 97. perseus.hermes.run_condition_option.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| id | int IDENTITY(1, 1) NOT NULL |
| value | numeric(11,3) NULL |
| label | varchar(500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| master_condition_id | int NULL |

---

[hermes].[run_condition_value]

Arquivo: 98. perseus.hermes.run_condition_value.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| id | int IDENTITY(1, 1) NOT NULL |
| value | numeric(11,3) NULL |
| master_condition_id | int NULL |
| updated_on | datetime NULL |
| run_id | int NULL |

---

[hermes].[run_master_condition]

Arquivo: 99. perseus.hermes.run_master_condition.sql

| Column Name | Data Type |
|--------------|-------------------------------------------------------------------|
| id | int IDENTITY(1, 1) NOT NULL |
| name | varchar(max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| units | nvarchar(25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| description | nvarchar(250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL |
| optional_order | int NULL |
| created_on | datetime NULL |
| available_in_view | bit NULL |
| creator_id | int NULL |
| condition_type_id | int NULL |
| active | bit NULL |

---

