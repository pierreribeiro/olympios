# Perseus Data Dictionary - Objetos e Dependências

## Document Control

| Campo | Valor |
|---|---|
| Gerado em | 2026-04-10 12:49 UTC |
| Modelo de referência | `perseus-data-dictionary.md` |
| Tabelas catalogadas | 93 |
| Colunas catalogadas | 556 |
| PK catalogadas | 93 |
| UK (constraints) catalogadas | 42 |
| UK (índices únicos) catalogadas | 7 |
| FK catalogadas | 125 |

## Visão geral por nível de dependência

| Tier | Quantidade de tabelas |
|---|---|
| 0 | 38 |
| 1 | 10 |
| 2 | 14 |
| 3 | 8 |
| 4 | 6 |
| 5 | 6 |
| 6 | 10 |
| 7 | 1 |

## Catálogo por tier de dependência

## Tier 0 (38 tabelas)

### perseus.alembic_version

**Arquivo fonte**: `13.create-table/0.perseus.alembic_version.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `version_num` | `character varying(32)` | `—` | NO | PK |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `alembic_version_pkc`: (`version_num`)
- **Unique keys**: nenhuma além da PK.

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - Nenhuma FK como filho.

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - Nenhuma tabela filha referenciando esta tabela.

---

### perseus.cm_application

**Arquivo fonte**: `13.create-table/1.perseus.cm_application.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `application_id` | `integer` | `—` | NO | PK |
| `label` | `public.citext` | `—` | NO | — |
| `description` | `public.citext` | `—` | NO | — |
| `is_active` | `smallint` | `—` | NO | — |
| `application_group_id` | `integer` | `—` | YES | — |
| `url` | `public.citext` | `—` | YES | — |
| `owner_user_id` | `integer` | `—` | YES | — |
| `jira_id` | `public.citext` | `—` | YES | — |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `pk_cm_application`: (`application_id`)
- **Unique keys**: nenhuma além da PK.

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - Nenhuma FK como filho.

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - Nenhuma tabela filha referenciando esta tabela.

---

### perseus.cm_application_group

**Arquivo fonte**: `13.create-table/2.perseus.cm_application_group.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `application_group_id` | `integer` | `IDENTITY` | NO | PK |
| `label` | `public.citext` | `—` | NO | — |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `pk_cm_application_group`: (`application_group_id`)
- **Unique keys**: nenhuma além da PK.

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - Nenhuma FK como filho.

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - Nenhuma tabela filha referenciando esta tabela.

---

### perseus.cm_group

**Arquivo fonte**: `13.create-table/3.perseus.cm_group.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `group_id` | `integer` | `IDENTITY` | NO | PK |
| `name` | `public.citext` | `—` | NO | — |
| `domain_id` | `public.citext` | `—` | NO | — |
| `is_active` | `boolean` | `—` | NO | — |
| `last_modified` | `timestamp without time zone` | `—` | NO | — |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `pk_group`: (`group_id`)
- **Unique keys**: nenhuma além da PK.

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - Nenhuma FK como filho.

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - Nenhuma tabela filha referenciando esta tabela.

---

### perseus.cm_project

**Arquivo fonte**: `13.create-table/4.perseus.cm_project.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `project_id` | `smallint` | `—` | NO | PK |
| `label` | `public.citext` | `—` | NO | — |
| `is_active` | `boolean` | `—` | NO | — |
| `display_order` | `smallint` | `—` | NO | — |
| `group_id` | `integer` | `—` | YES | — |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `pk_project`: (`project_id`)
- **Unique keys**: nenhuma além da PK.

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - Nenhuma FK como filho.

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - Nenhuma tabela filha referenciando esta tabela.

---

### perseus.cm_unit

**Arquivo fonte**: `13.create-table/5.perseus.cm_unit.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `id` | `integer` | `—` | NO | PK |
| `description` | `public.citext` | `—` | YES | — |
| `longname` | `public.citext` | `—` | YES | — |
| `dimensions_id` | `integer` | `—` | YES | — |
| `name` | `public.citext` | `—` | YES | — |
| `factor` | `numeric(20,10)` | `—` | YES | — |
| `offset` | `numeric(20,10)` | `—` | YES | — |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `pk_cm_unit_1`: (`id`)
- **Unique keys**: nenhuma além da PK.

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - Nenhuma FK como filho.

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - Nenhuma tabela filha referenciando esta tabela.

---

### perseus.cm_unit_compare

**Arquivo fonte**: `13.create-table/6.perseus.cm_unit_compare.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `from_unit_id` | `integer` | `—` | NO | PK |
| `to_unit_id` | `integer` | `—` | NO | PK |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `pk_cm_unit_compare`: (`from_unit_id`, `to_unit_id`)
- **Unique keys**: nenhuma além da PK.

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - Nenhuma FK como filho.

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - Nenhuma tabela filha referenciando esta tabela.

---

### perseus.cm_unit_dimensions

**Arquivo fonte**: `13.create-table/7.perseus.cm_unit_dimensions.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `id` | `integer` | `—` | NO | PK |
| `mass` | `numeric(10,2)` | `—` | YES | — |
| `length` | `numeric(10,2)` | `—` | YES | — |
| `time` | `numeric(10,2)` | `—` | YES | — |
| `electric_current` | `numeric(10,2)` | `—` | YES | — |
| `thermodynamic_temperature` | `numeric(10,2)` | `—` | YES | — |
| `amount_of_substance` | `numeric(10,2)` | `—` | YES | — |
| `luminous_intensity` | `numeric(10,2)` | `—` | YES | — |
| `default_unit_id` | `integer` | `—` | NO | — |
| `name` | `public.citext` | `—` | NO | — |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `pk_cm_unit_dimensions`: (`id`)
- **Unique keys**: nenhuma além da PK.

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - Nenhuma FK como filho.

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - Nenhuma tabela filha referenciando esta tabela.

---

### perseus.cm_user

**Arquivo fonte**: `13.create-table/8.perseus.cm_user.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `user_id` | `integer` | `IDENTITY` | NO | PK |
| `domain_id` | `public.citext` | `—` | YES | — |
| `is_active` | `boolean` | `—` | NO | — |
| `name` | `public.citext` | `—` | NO | — |
| `login` | `public.citext` | `—` | YES | — |
| `email` | `public.citext` | `—` | YES | — |
| `object_id` | `uuid` | `—` | YES | — |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `pk_user`: (`user_id`)
- **Unique keys**: nenhuma além da PK.

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - Nenhuma FK como filho.

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - Nenhuma tabela filha referenciando esta tabela.

---

### perseus.cm_user_group

**Arquivo fonte**: `13.create-table/9.perseus.cm_user_group.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `user_id` | `integer` | `—` | NO | PK |
| `group_id` | `integer` | `—` | NO | PK |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `pk_cm_user_group`: (`user_id`, `group_id`)
- **Unique keys**: nenhuma além da PK.

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - Nenhuma FK como filho.

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - Nenhuma tabela filha referenciando esta tabela.

---

### perseus.color

**Arquivo fonte**: `13.create-table/12.perseus.color.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `name` | `public.citext` | `—` | NO | PK |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `pk_color`: (`name`)
- **Unique keys**: nenhuma além da PK.

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - Nenhuma FK como filho.

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - Nenhuma tabela filha referenciando esta tabela.

---

### perseus.container_type

**Arquivo fonte**: `13.create-table/24.perseus.container_type.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `id` | `integer` | `IDENTITY` | NO | PK |
| `name` | `public.citext` | `—` | NO | UK |
| `is_parent` | `boolean` | `false` | NO | — |
| `is_equipment` | `boolean` | `false` | NO | — |
| `is_single` | `boolean` | `false` | NO | — |
| `is_restricted` | `boolean` | `false` | NO | — |
| `is_gooable` | `boolean` | `false` | NO | — |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `container_type_pk`: (`id`)
- **UNIQUE CONSTRAINT** `uq__containe__72e12f1b0ea330e9`: (`name`)

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - Nenhuma FK como filho.

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - `container_fk_1`: Pai `perseus.container_type` (`id`) <- Filho `perseus.container` (`container_type_id`) | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `container_type_position_fk_1`: Pai `perseus.container_type` (`id`) <- Filho `perseus.container_type_position` (`parent_container_type_id`) | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `container_type_position_fk_2`: Pai `perseus.container_type` (`id`) <- Filho `perseus.container_type_position` (`child_container_type_id`) | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `robot_log_type_fk_1`: Pai `perseus.container_type` (`id`) <- Filho `perseus.robot_log_type` (`destination_container_type_id`) | ON UPDATE NO ACTION | ON DELETE NO ACTION

---

### perseus.display_layout

**Arquivo fonte**: `13.create-table/20.perseus.display_layout.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `id` | `integer` | `—` | NO | PK |
| `name` | `public.citext` | `—` | NO | UK |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `display_layout_pk`: (`id`)
- **UNIQUE CONSTRAINT** `uq__display___72e12f1b22c0cedd`: (`name`)

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - Nenhuma FK como filho.

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - `combined_field_map_display_type_fk_3`: Pai `perseus.display_layout` (`id`) <- Filho `perseus.field_map_display_type` (`display_layout_id`) | ON UPDATE NO ACTION | ON DELETE CASCADE

---

### perseus.display_type

**Arquivo fonte**: `13.create-table/26.perseus.display_type.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `id` | `integer` | `—` | NO | PK |
| `name` | `public.citext` | `—` | NO | UK |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `display_type_pk`: (`id`)
- **UNIQUE CONSTRAINT** `uq__display___72e12f1b1dfc19c0`: (`name`)

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - Nenhuma FK como filho.

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - `combined_field_map_display_type_fk_2`: Pai `perseus.display_type` (`id`) <- Filho `perseus.field_map_display_type` (`display_type_id`) | ON UPDATE NO ACTION | ON DELETE CASCADE

---

### perseus.field_map_block

**Arquivo fonte**: `13.create-table/19.perseus.field_map_block.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `id` | `integer` | `IDENTITY` | NO | PK |
| `filter` | `public.citext` | `—` | YES | UK |
| `scope` | `public.citext` | `—` | YES | UK |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `field_map_block_pk`: (`id`)
- **UNIQUE CONSTRAINT** `uniq_fmb`: (`filter`, `scope`)

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - Nenhuma FK como filho.

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - `combined_field_map_fk_1`: Pai `perseus.field_map_block` (`id`) <- Filho `perseus.field_map` (`field_map_block_id`) | ON UPDATE NO ACTION | ON DELETE NO ACTION

---

### perseus.field_map_set

**Arquivo fonte**: `13.create-table/37.perseus.field_map_set.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `id` | `integer` | `—` | NO | PK |
| `tab_group_id` | `integer` | `—` | YES | — |
| `display_order` | `integer` | `—` | YES | — |
| `name` | `public.citext` | `—` | YES | — |
| `color` | `public.citext` | `—` | YES | — |
| `size` | `integer` | `—` | YES | — |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `field_map_set_pk`: (`id`)
- **Unique keys**: nenhuma além da PK.

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - Nenhuma FK como filho.

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - `field_map_field_map_set_fk_1`: Pai `perseus.field_map_set` (`id`) <- Filho `perseus.field_map` (`field_map_set_id`) | ON UPDATE NO ACTION | ON DELETE NO ACTION

---

### perseus.field_map_type

**Arquivo fonte**: `13.create-table/38.perseus.field_map_type.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `id` | `integer` | `—` | NO | PK |
| `name` | `public.citext` | `—` | NO | UK |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `field_map_type_pk`: (`id`)
- **UNIQUE CONSTRAINT** `uq__field_ma__72e12f1b278583fa`: (`name`)

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - Nenhuma FK como filho.

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - `combined_field_map_fk_2`: Pai `perseus.field_map_type` (`id`) <- Filho `perseus.field_map` (`field_map_type_id`) | ON UPDATE NO ACTION | ON DELETE NO ACTION

---

### perseus.goo_attachment_type

**Arquivo fonte**: `13.create-table/41.perseus.goo_attachment_type.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `id` | `integer` | `IDENTITY` | NO | PK |
| `name` | `public.citext` | `—` | NO | UK |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `goo_attachment_type_pk`: (`id`)
- **UNIQUE CONSTRAINT** `uq__goo_atta__72e12f1b7a5d7005`: (`name`)

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - Nenhuma FK como filho.

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - `goo_attachment_fk_3`: Pai `perseus.goo_attachment_type` (`id`) <- Filho `perseus.goo_attachment` (`goo_attachment_type_id`) | ON UPDATE NO ACTION | ON DELETE NO ACTION

---

### perseus.goo_process_queue_type

**Arquivo fonte**: `13.create-table/44.perseus.goo_process_queue_type.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `id` | `integer` | `IDENTITY` | NO | PK |
| `name` | `public.citext` | `—` | NO | UK |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `goo_process_queue_type_pk`: (`id`)
- **UNIQUE CONSTRAINT** `uq__goo_proc__72e12f1b5581bc68`: (`name`)

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - Nenhuma FK como filho.

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - Nenhuma tabela filha referenciando esta tabela.

---

### perseus.goo_type

**Arquivo fonte**: `13.create-table/45.perseus.goo_type.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `id` | `integer` | `IDENTITY` | NO | PK |
| `name` | `public.citext` | `—` | NO | UK |
| `color` | `public.citext` | `—` | YES | — |
| `left_id` | `integer` | `—` | NO | UK |
| `right_id` | `integer` | `—` | NO | UK |
| `scope_id` | `public.citext` | `—` | NO | UK |
| `disabled` | `integer` | `0` | NO | — |
| `casrn` | `public.citext` | `—` | YES | — |
| `iupac` | `public.citext` | `—` | YES | — |
| `depth` | `integer` | `0` | NO | — |
| `abbreviation` | `public.citext` | `—` | YES | — |
| `density_kg_l` | `double precision` | `—` | YES | — |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `goo_type_pk`: (`id`)
- **UNIQUE CONSTRAINT** `uq__goo_type__72a9f59b39237a9a`: (`left_id`, `right_id`, `scope_id`)
- **UNIQUE CONSTRAINT** `uq__goo_type__72e12f1b00551192`: (`name`)

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - Nenhuma FK como filho.

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - `coa_fk_1`: Pai `perseus.goo_type` (`id`) <- Filho `perseus.coa` (`goo_type_id`) | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `external_goo_type_fk_1`: Pai `perseus.goo_type` (`id`) <- Filho `perseus.external_goo_type` (`goo_type_id`) | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `goo_fk_1`: Pai `perseus.goo_type` (`id`) <- Filho `perseus.goo` (`goo_type_id`) | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `goo_type_combine_component_fk_1`: Pai `perseus.goo_type` (`id`) <- Filho `perseus.goo_type_combine_component` (`goo_type_id`) | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `goo_type_combine_target_fk_1`: Pai `perseus.goo_type` (`id`) <- Filho `perseus.goo_type_combine_target` (`goo_type_id`) | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `fk_material_inventory_threshold_material_type`: Pai `perseus.goo_type` (`id`) <- Filho `perseus.material_inventory_threshold` (`material_type_id`) | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `fk__recipe__goo_type__6692a791`: Pai `perseus.goo_type` (`id`) <- Filho `perseus.recipe` (`goo_type_id`) | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `fk__recipe_pa__goo_t__6e33c959`: Pai `perseus.goo_type` (`id`) <- Filho `perseus.recipe_part` (`goo_type_id`) | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `smurf_goo_type_fk_2`: Pai `perseus.goo_type` (`id`) <- Filho `perseus.smurf_goo_type` (`goo_type_id`) | ON UPDATE NO ACTION | ON DELETE CASCADE
  - `fk_workflow_step_goo_type`: Pai `perseus.goo_type` (`id`) <- Filho `perseus.workflow_step` (`goo_type_id`) | ON UPDATE NO ACTION | ON DELETE NO ACTION

---

### perseus.history_type

**Arquivo fonte**: `13.create-table/49.perseus.history_type.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `id` | `integer` | `IDENTITY` | NO | PK |
| `name` | `public.citext` | `—` | NO | UK |
| `format` | `public.citext` | `—` | NO | — |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `history_type_pk`: (`id`)
- **UNIQUE CONSTRAINT** `uq__history___72e12f1b19b8e995`: (`name`)

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - Nenhuma FK como filho.

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - `history_fk_2`: Pai `perseus.history_type` (`id`) <- Filho `perseus.history` (`history_type_id`) | ON UPDATE NO ACTION | ON DELETE NO ACTION

---

### perseus.m_downstream

**Arquivo fonte**: `13.create-table/51.perseus.m_downstream.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `start_point` | `public.citext` | `—` | NO | PK |
| `end_point` | `public.citext` | `—` | NO | PK |
| `path` | `public.citext` | `—` | NO | PK |
| `level` | `integer` | `—` | NO | — |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `m_downstream_pk`: (`start_point`, `end_point`, `path`)
- **Unique keys**: nenhuma além da PK.

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - Nenhuma FK como filho.

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - Nenhuma tabela filha referenciando esta tabela.

---

### perseus.m_number

**Arquivo fonte**: `13.create-table/52.perseus.m_number.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `id` | `integer` | `IDENTITY` | NO | — |
| `md5_hash` | `text` | `—` | NO | PK |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `perseus_m_number_pk_md5_hash`: (`md5_hash`)
- **Unique keys**: nenhuma além da PK.

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - Nenhuma FK como filho.

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - Nenhuma tabela filha referenciando esta tabela.

---

### perseus.m_upstream

**Arquivo fonte**: `13.create-table/53.perseus.m_upstream.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `start_point` | `public.citext` | `—` | NO | PK |
| `end_point` | `public.citext` | `—` | NO | PK |
| `path` | `public.citext` | `—` | NO | PK |
| `level` | `integer` | `—` | NO | — |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `m_upstream_pk`: (`start_point`, `end_point`, `path`)
- **Unique keys**: nenhuma além da PK.

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - Nenhuma FK como filho.

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - Nenhuma tabela filha referenciando esta tabela.

---

### perseus.m_upstream_dirty_leaves

**Arquivo fonte**: `13.create-table/54.perseus.m_upstream_dirty_leaves.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `material_uid` | `public.citext` | `—` | NO | — |
| `md5_hash` | `text` | `—` | NO | PK |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `perseus_m_upstream_dirty_leaves_pk_md5_hash`: (`md5_hash`)
- **Unique keys**: nenhuma além da PK.

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - Nenhuma FK como filho.

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - Nenhuma tabela filha referenciando esta tabela.

---

### perseus.manufacturer

**Arquivo fonte**: `13.create-table/55.perseus.manufacturer.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `id` | `integer` | `IDENTITY` | NO | PK |
| `name` | `public.citext` | `—` | NO | UK |
| `location` | `public.citext` | `—` | YES | UK |
| `goo_prefix` | `public.citext` | `—` | YES | — |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `manufacturer_pk`: (`id`)
- **UNIQUE CONSTRAINT** `uq__manufact__106262313de82fb7`: (`name`, `location`)

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - Nenhuma FK como filho.

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - `external_goo_type_fk_2`: Pai `perseus.manufacturer` (`id`) <- Filho `perseus.external_goo_type` (`manufacturer_id`) | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `fs_organization_fk_1`: Pai `perseus.manufacturer` (`id`) <- Filho `perseus.fatsmurf` (`organization_id`) | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `manufacturer_fk_1`: Pai `perseus.manufacturer` (`id`) <- Filho `perseus.goo` (`manufacturer_id`) | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `fk__perseus_u__manuf__5b3c942f`: Pai `perseus.manufacturer` (`id`) <- Filho `perseus.perseus_user` (`manufacturer_id`) | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `fk__perseus_u__manuf__5e1900da`: Pai `perseus.manufacturer` (`id`) <- Filho `perseus.perseus_user` (`manufacturer_id`) | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `fk__perseus_u__manuf__6001494c`: Pai `perseus.manufacturer` (`id`) <- Filho `perseus.perseus_user` (`manufacturer_id`) | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `workflow_manufacturer_id_fk_1`: Pai `perseus.manufacturer` (`id`) <- Filho `perseus.workflow` (`manufacturer_id`) | ON UPDATE NO ACTION | ON DELETE NO ACTION

---

### perseus.material_inventory_type

**Arquivo fonte**: `13.create-table/59.perseus.material_inventory_type.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `id` | `integer` | `IDENTITY` | NO | PK |
| `name` | `public.citext` | `—` | NO | UK |
| `description` | `public.citext` | `—` | YES | — |
| `is_active` | `boolean` | `true` | NO | — |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `pk__material__3213e83fbd077e43`: (`id`)
- **UNIQUE CONSTRAINT** `uq__material__72e12f1b3704ca3e`: (`name`)

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - Nenhuma FK como filho.

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - `fk_material_inventory_inventory_type_id`: Pai `perseus.material_inventory_type` (`id`) <- Filho `perseus.material_inventory` (`inventory_type_id`) | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `fk_material_inventory_threshold_inventory_type_id`: Pai `perseus.material_inventory_type` (`id`) <- Filho `perseus.material_inventory_threshold` (`inventory_type_id`) | ON UPDATE NO ACTION | ON DELETE NO ACTION

---

### perseus.migration

**Arquivo fonte**: `13.create-table/61.perseus.migration.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `id` | `integer` | `—` | NO | PK |
| `description` | `public.citext` | `—` | NO | — |
| `created_on` | `timestamp without time zone` | `LOCALTIMESTAMP` | NO | — |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `pk__migratio__3213e83f2405ca25`: (`id`)
- **Unique keys**: nenhuma além da PK.

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - Nenhuma FK como filho.

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - Nenhuma tabela filha referenciando esta tabela.

---

### perseus.permissions

**Arquivo fonte**: `13.create-table/62.perseus.permissions.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `emailaddress` | `public.citext` | `—` | NO | — |
| `permission` | `public.citext` | `—` | NO | — |
| `md5_hash` | `text` | `—` | NO | PK |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `perseus_permissions_pk_md5_hash`: (`md5_hash`)
- **Unique keys**: nenhuma além da PK.

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - Nenhuma FK como filho.

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - Nenhuma tabela filha referenciando esta tabela.

---

### perseus.person

**Arquivo fonte**: `13.create-table/64.perseus.person.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `id` | `integer` | `—` | NO | PK |
| `domain_id` | `public.citext` | `—` | NO | UK |
| `km_session_id` | `public.citext` | `—` | YES | — |
| `login` | `public.citext` | `—` | NO | — |
| `name` | `public.citext` | `—` | NO | — |
| `email` | `public.citext` | `—` | YES | — |
| `last_login` | `timestamp without time zone` | `—` | YES | — |
| `is_active` | `boolean` | `(1)::boolean` | NO | — |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `pk__person__3213e83f19aff6df`: (`id`)
- **UNIQUE CONSTRAINT** `uq_person_domain_id`: (`domain_id`)

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - Nenhuma FK como filho.

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - Nenhuma tabela filha referenciando esta tabela.

---

### perseus.prefix_incrementor

**Arquivo fonte**: `13.create-table/67.perseus.prefix_incrementor.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `prefix` | `public.citext` | `—` | NO | PK |
| `counter` | `integer` | `—` | NO | — |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `prefix_incrementor_pk`: (`prefix`)
- **Unique keys**: nenhuma além da PK.

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - Nenhuma FK como filho.

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - Nenhuma tabela filha referenciando esta tabela.

---

### perseus.s_number

**Arquivo fonte**: `13.create-table/78.perseus.s_number.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `id` | `integer` | `IDENTITY` | NO | — |
| `md5_hash` | `text` | `—` | NO | PK |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `perseus_s_number_pk_md5_hash`: (`md5_hash`)
- **Unique keys**: nenhuma além da PK.

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - Nenhuma FK como filho.

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - Nenhuma tabela filha referenciando esta tabela.

---

### perseus.scraper

**Arquivo fonte**: `13.create-table/80.perseus.scraper.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `id` | `integer` | `IDENTITY` | NO | PK |
| `timestamp` | `timestamp without time zone` | `—` | YES | — |
| `message` | `public.citext` | `—` | YES | — |
| `filetype` | `public.citext` | `—` | YES | — |
| `filename` | `public.citext` | `—` | YES | — |
| `filenamesavedas` | `public.citext` | `—` | YES | — |
| `receivedfrom` | `public.citext` | `—` | YES | — |
| `file` | `bytea` | `—` | YES | — |
| `result` | `public.citext` | `—` | YES | — |
| `complete` | `boolean` | `—` | YES | — |
| `scraperid` | `public.citext` | `—` | YES | — |
| `scrapingstartedon` | `timestamp without time zone` | `—` | YES | — |
| `scrapingfinishedon` | `timestamp without time zone` | `—` | YES | — |
| `scrapingstatus` | `public.citext` | `—` | YES | — |
| `scrapersendto` | `public.citext` | `—` | YES | — |
| `scrapermessage` | `public.citext` | `—` | YES | — |
| `active` | `public.citext` | `—` | YES | — |
| `controlfileid` | `integer` | `—` | YES | — |
| `documentid` | `public.citext` | `—` | YES | — |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `pk__scraper__3214ec274c308081`: (`id`)
- **Unique keys**: nenhuma além da PK.

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - Nenhuma FK como filho.

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - Nenhuma tabela filha referenciando esta tabela.

---

### perseus.sequence_type

**Arquivo fonte**: `13.create-table/81.perseus.sequence_type.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `id` | `integer` | `IDENTITY` | NO | PK |
| `name` | `public.citext` | `—` | NO | — |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `sequence_type_pk`: (`id`)
- **Unique keys**: nenhuma além da PK.

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - Nenhuma FK como filho.

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - `robot_log_container_sequence_fk_1`: Pai `perseus.sequence_type` (`id`) <- Filho `perseus.robot_log_container_sequence` (`sequence_type_id`) | ON UPDATE NO ACTION | ON DELETE CASCADE

---

### perseus.smurf

**Arquivo fonte**: `13.create-table/15.perseus.smurf.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `id` | `integer` | `IDENTITY` | NO | PK |
| `class_id` | `integer` | `—` | NO | — |
| `name` | `public.citext` | `—` | NO | UK |
| `description` | `public.citext` | `—` | YES | — |
| `themis_method_id` | `integer` | `—` | YES | — |
| `disabled` | `boolean` | `false` | NO | — |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `smurf_pk`: (`id`)
- **UNIQUE CONSTRAINT** `uq__smurf__72e12f1b300424b4`: (`name`)

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - Nenhuma FK como filho.

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - `fk_fatsmurf_smurf_id`: Pai `perseus.smurf` (`id`) <- Filho `perseus.fatsmurf` (`smurf_id`) | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `smurf_goo_type_fk_1`: Pai `perseus.smurf` (`id`) <- Filho `perseus.smurf_goo_type` (`smurf_id`) | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `smurf_group_member_fk_1`: Pai `perseus.smurf` (`id`) <- Filho `perseus.smurf_group_member` (`smurf_id`) | ON UPDATE NO ACTION | ON DELETE CASCADE
  - `smurf_property_fk_2`: Pai `perseus.smurf` (`id`) <- Filho `perseus.smurf_property` (`smurf_id`) | ON UPDATE NO ACTION | ON DELETE CASCADE
  - `fk__submissio__assay__78627aff`: Pai `perseus.smurf` (`id`) <- Filho `perseus.submission_entry` (`assay_type_id`) | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `fk_workflow_step_smurf`: Pai `perseus.smurf` (`id`) <- Filho `perseus.workflow_step` (`smurf_id`) | ON UPDATE NO ACTION | ON DELETE NO ACTION

---

### perseus.tmp_messy_links

**Arquivo fonte**: `13.create-table/87.perseus.tmp_messy_links.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `source_transition` | `public.citext` | `—` | NO | — |
| `source_name` | `public.citext` | `—` | YES | — |
| `destination_transition` | `public.citext` | `—` | NO | — |
| `desitnation_name` | `public.citext` | `—` | YES | — |
| `material_id` | `public.citext` | `—` | NO | — |
| `md5_hash` | `text` | `—` | NO | PK |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `perseus_tmp_messy_links_pk_md5_hash`: (`md5_hash`)
- **Unique keys**: nenhuma além da PK.

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - Nenhuma FK como filho.

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - Nenhuma tabela filha referenciando esta tabela.

---

### perseus.unit

**Arquivo fonte**: `13.create-table/17.perseus.unit.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `id` | `integer` | `IDENTITY` | NO | PK |
| `name` | `public.citext` | `—` | NO | UK |
| `description` | `public.citext` | `—` | YES | — |
| `dimension_id` | `integer` | `—` | YES | — |
| `factor` | `double precision` | `—` | YES | — |
| `offset` | `double precision` | `—` | YES | — |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `unit_pk`: (`id`)
- **UNIQUE INDEX** `uix_unit_name`: (`name`)

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - Nenhuma FK como filho.

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - `property_fk_1`: Pai `perseus.unit` (`id`) <- Filho `perseus.property` (`unit_id`) | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `fk__recipe_pa__unit___6b575cae`: Pai `perseus.unit` (`id`) <- Filho `perseus.recipe_part` (`unit_id`) | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `workflow_step_unit_fk_1`: Pai `perseus.unit` (`id`) <- Filho `perseus.workflow_step` (`goo_amount_unit_id`) | ON UPDATE NO ACTION | ON DELETE NO ACTION

---

### perseus.workflow_step_type

**Arquivo fonte**: `13.create-table/92.perseus.workflow_step_type.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `id` | `integer` | `—` | NO | PK |
| `name` | `public.citext` | `—` | NO | UK |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `workflow_step_type_pk`: (`id`)
- **UNIQUE CONSTRAINT** `uq__workflow__72e12f1b0b20e345`: (`name`)

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - Nenhuma FK como filho.

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - Nenhuma tabela filha referenciando esta tabela.

---

## Tier 1 (10 tabelas)

### perseus.coa

**Arquivo fonte**: `13.create-table/10.perseus.coa.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `id` | `integer` | `IDENTITY` | NO | PK |
| `name` | `public.citext` | `—` | NO | UK |
| `goo_type_id` | `integer` | `—` | NO | UK, FK |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `coa_pk`: (`id`)
- **UNIQUE CONSTRAINT** `uq__coa__a045441b2653caa4`: (`name`, `goo_type_id`)

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - `coa_fk_1`: Filho `perseus.coa` (`goo_type_id`) -> Pai `perseus.goo_type` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE NO ACTION

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - `coa_spec_fk_1`: Pai `perseus.coa` (`id`) <- Filho `perseus.coa_spec` (`coa_id`) | ON UPDATE NO ACTION | ON DELETE NO ACTION

---

### perseus.container

**Arquivo fonte**: `13.create-table/22.perseus.container.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `id` | `integer` | `IDENTITY` | NO | PK |
| `container_type_id` | `integer` | `—` | NO | FK |
| `name` | `public.citext` | `—` | YES | — |
| `uid` | `public.citext` | `—` | NO | UK |
| `mass` | `double precision` | `—` | YES | — |
| `left_id` | `integer` | `1` | NO | — |
| `right_id` | `integer` | `2` | NO | — |
| `scope_id` | `public.citext` | `(gen_random_uuid())::character varying(50)` | NO | — |
| `position_name` | `public.citext` | `—` | YES | — |
| `position_x_coordinate` | `public.citext` | `—` | YES | — |
| `position_y_coordinate` | `public.citext` | `—` | YES | — |
| `depth` | `integer` | `0` | NO | — |
| `created_on` | `timestamp without time zone` | `LOCALTIMESTAMP` | YES | — |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `container_pk`: (`id`)
- **UNIQUE INDEX** `uniq_container_uid`: (`uid`)

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - `container_fk_1`: Filho `perseus.container` (`container_type_id`) -> Pai `perseus.container_type` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE NO ACTION

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - `container_history_fk_2`: Pai `perseus.container` (`id`) <- Filho `perseus.container_history` (`container_id`) | ON UPDATE NO ACTION | ON DELETE CASCADE
  - `fs_container_id_fk_1`: Pai `perseus.container` (`id`) <- Filho `perseus.fatsmurf` (`container_id`) | ON UPDATE NO ACTION | ON DELETE SET NULL
  - `container_id_fk_1`: Pai `perseus.container` (`id`) <- Filho `perseus.goo` (`container_id`) | ON UPDATE NO ACTION | ON DELETE SET NULL
  - `fk__material___alloc__1642b7d4`: Pai `perseus.container` (`id`) <- Filho `perseus.material_inventory` (`allocation_container_id`) | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `fk__material___locat__191f247f`: Pai `perseus.container` (`id`) <- Filho `perseus.material_inventory` (`location_container_id`) | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `robot_log_container_sequence_fk_2`: Pai `perseus.container` (`id`) <- Filho `perseus.robot_log_container_sequence` (`container_id`) | ON UPDATE NO ACTION | ON DELETE CASCADE
  - `robot_run_fk_2`: Pai `perseus.container` (`id`) <- Filho `perseus.robot_run` (`robot_id`) | ON UPDATE NO ACTION | ON DELETE NO ACTION

---

### perseus.container_type_position

**Arquivo fonte**: `13.create-table/25.perseus.container_type_position.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `id` | `integer` | `IDENTITY` | NO | PK |
| `parent_container_type_id` | `integer` | `—` | NO | UK, FK |
| `child_container_type_id` | `integer` | `—` | YES | FK |
| `position_name` | `public.citext` | `—` | YES | UK |
| `position_x_coordinate` | `public.citext` | `—` | YES | — |
| `position_y_coordinate` | `public.citext` | `—` | YES | — |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `container_type_position_pk`: (`id`)
- **UNIQUE CONSTRAINT** `uq__containe__32b36f0e29f6a937`: (`parent_container_type_id`, `position_name`)

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - `container_type_position_fk_1`: Filho `perseus.container_type_position` (`parent_container_type_id`) -> Pai `perseus.container_type` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `container_type_position_fk_2`: Filho `perseus.container_type_position` (`child_container_type_id`) -> Pai `perseus.container_type` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE NO ACTION

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - Nenhuma tabela filha referenciando esta tabela.

---

### perseus.external_goo_type

**Arquivo fonte**: `13.create-table/29.perseus.external_goo_type.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `id` | `integer` | `IDENTITY` | NO | PK |
| `goo_type_id` | `integer` | `—` | NO | FK |
| `external_label` | `public.citext` | `—` | NO | UK |
| `manufacturer_id` | `integer` | `—` | NO | UK, FK |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `external_goo_type_pk`: (`id`)
- **UNIQUE CONSTRAINT** `uq__external__3b82af230b9fd468`: (`external_label`, `manufacturer_id`)

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - `external_goo_type_fk_1`: Filho `perseus.external_goo_type` (`goo_type_id`) -> Pai `perseus.goo_type` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `external_goo_type_fk_2`: Filho `perseus.external_goo_type` (`manufacturer_id`) -> Pai `perseus.manufacturer` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE NO ACTION

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - Nenhuma tabela filha referenciando esta tabela.

---

### perseus.field_map

**Arquivo fonte**: `13.create-table/18.perseus.field_map.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `id` | `integer` | `IDENTITY` | NO | PK |
| `field_map_block_id` | `integer` | `—` | NO | FK |
| `name` | `public.citext` | `—` | YES | — |
| `description` | `public.citext` | `—` | YES | — |
| `display_order` | `integer` | `—` | YES | — |
| `setter` | `public.citext` | `—` | YES | — |
| `lookup` | `public.citext` | `—` | YES | — |
| `lookup_service` | `public.citext` | `—` | YES | — |
| `nullable` | `integer` | `—` | YES | — |
| `field_map_type_id` | `integer` | `—` | NO | FK |
| `database_id` | `public.citext` | `—` | YES | — |
| `save_sequence` | `integer` | `—` | NO | — |
| `onchange` | `public.citext` | `—` | YES | — |
| `field_map_set_id` | `integer` | `—` | NO | FK |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `combined_field_map_pk`: (`id`)
- **Unique keys**: nenhuma além da PK.

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - `combined_field_map_fk_1`: Filho `perseus.field_map` (`field_map_block_id`) -> Pai `perseus.field_map_block` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `combined_field_map_fk_2`: Filho `perseus.field_map` (`field_map_type_id`) -> Pai `perseus.field_map_type` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `field_map_field_map_set_fk_1`: Filho `perseus.field_map` (`field_map_set_id`) -> Pai `perseus.field_map_set` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE NO ACTION

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - `combined_field_map_display_type_fk_1`: Pai `perseus.field_map` (`id`) <- Filho `perseus.field_map_display_type` (`field_map_id`) | ON UPDATE NO ACTION | ON DELETE CASCADE

---

### perseus.goo_type_combine_target

**Arquivo fonte**: `13.create-table/47.perseus.goo_type_combine_target.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `id` | `integer` | `IDENTITY` | NO | PK |
| `goo_type_id` | `integer` | `—` | NO | FK |
| `sort_order` | `integer` | `—` | NO | — |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `goo_type_combine_target_pk`: (`id`)
- **Unique keys**: nenhuma além da PK.

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - `goo_type_combine_target_fk_1`: Filho `perseus.goo_type_combine_target` (`goo_type_id`) -> Pai `perseus.goo_type` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE NO ACTION

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - `goo_type_combine_component_fk_2`: Pai `perseus.goo_type_combine_target` (`id`) <- Filho `perseus.goo_type_combine_component` (`goo_type_combine_target_id`) | ON UPDATE NO ACTION | ON DELETE CASCADE

---

### perseus.perseus_user

**Arquivo fonte**: `13.create-table/63.perseus.perseus_user.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `id` | `integer` | `IDENTITY` | NO | PK |
| `name` | `public.citext` | `—` | NO | — |
| `domain_id` | `public.citext` | `—` | YES | UK |
| `login` | `public.citext` | `—` | YES | UK |
| `mail` | `public.citext` | `—` | YES | — |
| `admin` | `boolean` | `false` | NO | — |
| `super` | `boolean` | `false` | NO | — |
| `common_id` | `integer` | `—` | YES | — |
| `manufacturer_id` | `integer` | `1` | NO | FK |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `perseus_user_pk`: (`id`)
- **UNIQUE CONSTRAINT** `uq__perseus___7838f2720519c6af`: (`login`)
- **UNIQUE CONSTRAINT** `uq__perseus___e72bc76707f6335a`: (`domain_id`)

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - `fk__perseus_u__manuf__5b3c942f`: Filho `perseus.perseus_user` (`manufacturer_id`) -> Pai `perseus.manufacturer` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `fk__perseus_u__manuf__5e1900da`: Filho `perseus.perseus_user` (`manufacturer_id`) -> Pai `perseus.manufacturer` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `fk__perseus_u__manuf__6001494c`: Filho `perseus.perseus_user` (`manufacturer_id`) -> Pai `perseus.manufacturer` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE NO ACTION

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - `fatsmurf_attachment_fk_1`: Pai `perseus.perseus_user` (`id`) <- Filho `perseus.fatsmurf_attachment` (`added_by`) | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `fatsmurf_comment_fk_1`: Pai `perseus.perseus_user` (`id`) <- Filho `perseus.fatsmurf_comment` (`added_by`) | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `creator_fk_1`: Pai `perseus.perseus_user` (`id`) <- Filho `perseus.fatsmurf_reading` (`added_by`) | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `fk__feed_type__creat__5f28586b`: Pai `perseus.perseus_user` (`id`) <- Filho `perseus.feed_type` (`added_by`) | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `fk__feed_type__updat__601c7ca4`: Pai `perseus.perseus_user` (`id`) <- Filho `perseus.feed_type` (`updated_by_id`) | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `field_map_display_type_user_fk_2`: Pai `perseus.perseus_user` (`id`) <- Filho `perseus.field_map_display_type_user` (`user_id`) | ON UPDATE NO ACTION | ON DELETE CASCADE
  - `goo_fk_4`: Pai `perseus.perseus_user` (`id`) <- Filho `perseus.goo` (`added_by`) | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `goo_attachment_fk_1`: Pai `perseus.perseus_user` (`id`) <- Filho `perseus.goo_attachment` (`added_by`) | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `goo_comment_fk_1`: Pai `perseus.perseus_user` (`id`) <- Filho `perseus.goo_comment` (`added_by`) | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `history_fk_1`: Pai `perseus.perseus_user` (`id`) <- Filho `perseus.history` (`creator_id`) | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `fk__material___creat__1a1348b8`: Pai `perseus.perseus_user` (`id`) <- Filho `perseus.material_inventory` (`created_by_id`) | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `fk__material___updat__1b076cf1`: Pai `perseus.perseus_user` (`id`) <- Filho `perseus.material_inventory` (`updated_by_id`) | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `fk_material_inventory_threshold_created_by`: Pai `perseus.perseus_user` (`id`) <- Filho `perseus.material_inventory_threshold` (`created_by_id`) | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `fk_material_inventory_threshold_updated_by`: Pai `perseus.perseus_user` (`id`) <- Filho `perseus.material_inventory_threshold` (`updated_by_id`) | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `fk_mit_notify_user_user`: Pai `perseus.perseus_user` (`id`) <- Filho `perseus.material_inventory_threshold_notify_user` (`user_id`) | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `fk__recipe__added_by__659e8358`: Pai `perseus.perseus_user` (`id`) <- Filho `perseus.recipe` (`added_by`) | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `saved_search_fk_1`: Pai `perseus.perseus_user` (`id`) <- Filho `perseus.saved_search` (`added_by`) | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `sg_creator_fk_1`: Pai `perseus.perseus_user` (`id`) <- Filho `perseus.smurf_group` (`added_by`) | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `fk__submissio__submi__739dc5e2`: Pai `perseus.perseus_user` (`id`) <- Filho `perseus.submission` (`submitter_id`) | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `fk__submissio__prepp__7d27301c`: Pai `perseus.perseus_user` (`id`) <- Filho `perseus.submission_entry` (`prepped_by_id`) | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `workflow_creator_fk_1`: Pai `perseus.perseus_user` (`id`) <- Filho `perseus.workflow` (`added_by`) | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `workflow_attachment_fk_1`: Pai `perseus.perseus_user` (`id`) <- Filho `perseus.workflow_attachment` (`added_by`) | ON UPDATE NO ACTION | ON DELETE NO ACTION

---

### perseus.property

**Arquivo fonte**: `13.create-table/13.perseus.property.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `id` | `integer` | `IDENTITY` | NO | PK |
| `name` | `public.citext` | `—` | NO | UK |
| `description` | `public.citext` | `—` | YES | — |
| `unit_id` | `integer` | `—` | YES | UK, FK |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `property_pk`: (`id`)
- **UNIQUE CONSTRAINT** `uq__property__1fdbdaa62a4b4b5e`: (`name`, `unit_id`)

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - `property_fk_1`: Filho `perseus.property` (`unit_id`) -> Pai `perseus.unit` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE NO ACTION

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - `coa_spec_fk_2`: Pai `perseus.property` (`id`) <- Filho `perseus.coa_spec` (`property_id`) | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `property_option_fk_1`: Pai `perseus.property` (`id`) <- Filho `perseus.property_option` (`property_id`) | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `robot_log_read_fk_2`: Pai `perseus.property` (`id`) <- Filho `perseus.robot_log_read` (`property_id`) | ON UPDATE NO ACTION | ON DELETE CASCADE
  - `smurf_property_fk_1`: Pai `perseus.property` (`id`) <- Filho `perseus.smurf_property` (`property_id`) | ON UPDATE NO ACTION | ON DELETE CASCADE
  - `fk_workflow_step_property`: Pai `perseus.property` (`id`) <- Filho `perseus.workflow_step` (`property_id`) | ON UPDATE NO ACTION | ON DELETE NO ACTION

---

### perseus.robot_log_type

**Arquivo fonte**: `13.create-table/76.perseus.robot_log_type.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `id` | `integer` | `IDENTITY` | NO | PK |
| `name` | `public.citext` | `—` | NO | UK |
| `auto_process` | `integer` | `—` | NO | — |
| `destination_container_type_id` | `integer` | `—` | YES | FK |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `robot_log_type_pk`: (`id`)
- **UNIQUE CONSTRAINT** `uq__robot_lo__72e12f1b1956f871`: (`name`)

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - `robot_log_type_fk_1`: Filho `perseus.robot_log_type` (`destination_container_type_id`) -> Pai `perseus.container_type` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE NO ACTION

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - `fk__robot_log__robot__01bf6602`: Pai `perseus.robot_log_type` (`id`) <- Filho `perseus.robot_log` (`robot_log_type_id`) | ON UPDATE NO ACTION | ON DELETE NO ACTION

---

### perseus.smurf_goo_type

**Arquivo fonte**: `13.create-table/82.perseus.smurf_goo_type.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `id` | `integer` | `IDENTITY` | NO | PK |
| `smurf_id` | `integer` | `—` | NO | UK, FK |
| `goo_type_id` | `integer` | `—` | YES | UK, FK |
| `is_input` | `boolean` | `false` | NO | UK |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `smurf_goo_type_pk`: (`id`)
- **UNIQUE INDEX** `uniq_index`: (`smurf_id`, `goo_type_id`, `is_input`)

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - `smurf_goo_type_fk_1`: Filho `perseus.smurf_goo_type` (`smurf_id`) -> Pai `perseus.smurf` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `smurf_goo_type_fk_2`: Filho `perseus.smurf_goo_type` (`goo_type_id`) -> Pai `perseus.goo_type` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE CASCADE

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - Nenhuma tabela filha referenciando esta tabela.

---

## Tier 2 (14 tabelas)

### perseus.coa_spec

**Arquivo fonte**: `13.create-table/11.perseus.coa_spec.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `id` | `integer` | `IDENTITY` | NO | PK |
| `coa_id` | `integer` | `—` | NO | UK, FK |
| `property_id` | `integer` | `—` | NO | UK, FK |
| `upper_bound` | `double precision` | `—` | YES | — |
| `lower_bound` | `double precision` | `—` | YES | — |
| `equal_bound` | `public.citext` | `—` | YES | — |
| `upper_equal_bound` | `double precision` | `—` | YES | — |
| `lower_equal_bound` | `double precision` | `—` | YES | — |
| `result_precision` | `integer` | `0` | YES | — |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `coa_spec_pk`: (`id`)
- **UNIQUE CONSTRAINT** `uq__coa_spec__175eaf262c0ca3fa`: (`coa_id`, `property_id`)

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - `coa_spec_fk_1`: Filho `perseus.coa_spec` (`coa_id`) -> Pai `perseus.coa` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `coa_spec_fk_2`: Filho `perseus.coa_spec` (`property_id`) -> Pai `perseus.property` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE NO ACTION

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - Nenhuma tabela filha referenciando esta tabela.

---

### perseus.feed_type

**Arquivo fonte**: `13.create-table/35.perseus.feed_type.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `id` | `integer` | `IDENTITY` | NO | PK |
| `added_by` | `integer` | `—` | NO | FK |
| `updated_by_id` | `integer` | `—` | YES | FK |
| `name` | `public.citext` | `—` | YES | — |
| `description` | `public.citext` | `—` | YES | — |
| `correction_method` | `public.citext` | `'SIMPLE'::character varying` | NO | — |
| `correction_factor` | `double precision` | `1.0` | NO | — |
| `disabled` | `boolean` | `(0)::boolean` | NO | — |
| `added_on` | `timestamp without time zone` | `LOCALTIMESTAMP` | NO | — |
| `updated_on` | `timestamp without time zone` | `LOCALTIMESTAMP` | YES | — |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `pk__feed_typ__3213e83f16787987`: (`id`)
- **Unique keys**: nenhuma além da PK.

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - `fk__feed_type__creat__5f28586b`: Filho `perseus.feed_type` (`added_by`) -> Pai `perseus.perseus_user` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `fk__feed_type__updat__601c7ca4`: Filho `perseus.feed_type` (`updated_by_id`) -> Pai `perseus.perseus_user` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE NO ACTION

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - `fk__recipe__feed_typ__471bc4b0`: Pai `perseus.feed_type` (`id`) <- Filho `perseus.recipe` (`feed_type_id`) | ON UPDATE NO ACTION | ON DELETE NO ACTION

---

### perseus.field_map_display_type

**Arquivo fonte**: `13.create-table/21.perseus.field_map_display_type.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `id` | `integer` | `IDENTITY` | NO | PK |
| `field_map_id` | `integer` | `—` | NO | UK, FK |
| `display_type_id` | `integer` | `—` | NO | UK, FK |
| `display` | `public.citext` | `—` | NO | — |
| `display_layout_id` | `integer` | `1` | NO | FK |
| `manditory` | `integer` | `0` | NO | — |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `combined_field_map_display_type_pk`: (`id`)
- **UNIQUE CONSTRAINT** `uq__field_ma__f9589110301ac9fb`: (`field_map_id`, `display_type_id`)

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - `combined_field_map_display_type_fk_1`: Filho `perseus.field_map_display_type` (`field_map_id`) -> Pai `perseus.field_map` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE CASCADE
  - `combined_field_map_display_type_fk_2`: Filho `perseus.field_map_display_type` (`display_type_id`) -> Pai `perseus.display_type` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE CASCADE
  - `combined_field_map_display_type_fk_3`: Filho `perseus.field_map_display_type` (`display_layout_id`) -> Pai `perseus.display_layout` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE CASCADE

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - Nenhuma tabela filha referenciando esta tabela.

---

### perseus.field_map_display_type_user

**Arquivo fonte**: `13.create-table/36.perseus.field_map_display_type_user.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `id` | `integer` | `IDENTITY` | NO | PK |
| `field_map_display_type_id` | `integer` | `—` | NO | UK |
| `user_id` | `integer` | `—` | NO | UK, FK |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `field_map_display_type_user_pk`: (`id`)
- **UNIQUE CONSTRAINT** `uq__field_ma__49e1a26338b00ffc`: (`user_id`, `field_map_display_type_id`)

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - `field_map_display_type_user_fk_2`: Filho `perseus.field_map_display_type_user` (`user_id`) -> Pai `perseus.perseus_user` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE CASCADE

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - Nenhuma tabela filha referenciando esta tabela.

---

### perseus.goo_type_combine_component

**Arquivo fonte**: `13.create-table/46.perseus.goo_type_combine_component.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `id` | `integer` | `IDENTITY` | NO | PK |
| `goo_type_combine_target_id` | `integer` | `—` | NO | UK, FK |
| `goo_type_id` | `integer` | `—` | NO | UK, FK |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `goo_type_combine_component_pk`: (`id`)
- **UNIQUE CONSTRAINT** `uq__goo_type__1a28c1a56fc0b158`: (`goo_type_combine_target_id`, `goo_type_id`)

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - `goo_type_combine_component_fk_1`: Filho `perseus.goo_type_combine_component` (`goo_type_id`) -> Pai `perseus.goo_type` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `goo_type_combine_component_fk_2`: Filho `perseus.goo_type_combine_component` (`goo_type_combine_target_id`) -> Pai `perseus.goo_type_combine_target` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE CASCADE

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - Nenhuma tabela filha referenciando esta tabela.

---

### perseus.history

**Arquivo fonte**: `13.create-table/48.perseus.history.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `id` | `integer` | `IDENTITY` | NO | PK |
| `history_type_id` | `integer` | `—` | NO | FK |
| `creator_id` | `integer` | `—` | NO | FK |
| `created_on` | `timestamp without time zone` | `LOCALTIMESTAMP` | NO | — |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `history_pk`: (`id`)
- **Unique keys**: nenhuma além da PK.

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - `history_fk_1`: Filho `perseus.history` (`creator_id`) -> Pai `perseus.perseus_user` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `history_fk_2`: Filho `perseus.history` (`history_type_id`) -> Pai `perseus.history_type` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE NO ACTION

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - `container_history_fk_1`: Pai `perseus.history` (`id`) <- Filho `perseus.container_history` (`history_id`) | ON UPDATE NO ACTION | ON DELETE CASCADE
  - `fatsmurf_history_fk_1`: Pai `perseus.history` (`id`) <- Filho `perseus.fatsmurf_history` (`history_id`) | ON UPDATE NO ACTION | ON DELETE CASCADE
  - `goo_history_fk_1`: Pai `perseus.history` (`id`) <- Filho `perseus.goo_history` (`history_id`) | ON UPDATE NO ACTION | ON DELETE CASCADE
  - `history_value_fk_1`: Pai `perseus.history` (`id`) <- Filho `perseus.history_value` (`history_id`) | ON UPDATE NO ACTION | ON DELETE CASCADE
  - `poll_history_fk_1`: Pai `perseus.history` (`id`) <- Filho `perseus.poll_history` (`history_id`) | ON UPDATE NO ACTION | ON DELETE CASCADE

---

### perseus.material_inventory_threshold

**Arquivo fonte**: `13.create-table/57.perseus.material_inventory_threshold.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `id` | `integer` | `IDENTITY` | NO | PK |
| `material_type_id` | `integer` | `—` | NO | UK, FK |
| `min_item_count` | `integer` | `—` | YES | — |
| `max_item_count` | `integer` | `—` | YES | — |
| `min_volume_l` | `double precision` | `—` | YES | — |
| `max_volume_l` | `double precision` | `—` | YES | — |
| `min_mass_kg` | `double precision` | `—` | YES | — |
| `max_mass_kg` | `double precision` | `—` | YES | — |
| `created_by_id` | `integer` | `—` | NO | FK |
| `created_on` | `timestamp without time zone` | `LOCALTIMESTAMP` | NO | — |
| `updated_by_id` | `integer` | `—` | YES | FK |
| `updated_on` | `timestamp without time zone` | `—` | YES | — |
| `inventory_type_id` | `integer` | `—` | NO | UK, FK |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `pk__material__3213e83ff1f867f5`: (`id`)
- **UNIQUE CONSTRAINT** `uq_material_inventory_threshold_material_type_inventory_type`: (`material_type_id`, `inventory_type_id`)

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - `fk_material_inventory_threshold_created_by`: Filho `perseus.material_inventory_threshold` (`created_by_id`) -> Pai `perseus.perseus_user` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `fk_material_inventory_threshold_inventory_type_id`: Filho `perseus.material_inventory_threshold` (`inventory_type_id`) -> Pai `perseus.material_inventory_type` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `fk_material_inventory_threshold_material_type`: Filho `perseus.material_inventory_threshold` (`material_type_id`) -> Pai `perseus.goo_type` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `fk_material_inventory_threshold_updated_by`: Filho `perseus.material_inventory_threshold` (`updated_by_id`) -> Pai `perseus.perseus_user` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE NO ACTION

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - `fk_mit_notify_user_threshold`: Pai `perseus.material_inventory_threshold` (`id`) <- Filho `perseus.material_inventory_threshold_notify_user` (`threshold_id`) | ON UPDATE NO ACTION | ON DELETE CASCADE

---

### perseus.property_option

**Arquivo fonte**: `13.create-table/14.perseus.property_option.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `id` | `integer` | `IDENTITY` | NO | PK |
| `property_id` | `integer` | `—` | NO | UK, FK |
| `value` | `integer` | `—` | NO | UK |
| `label` | `public.citext` | `—` | NO | UK |
| `disabled` | `integer` | `0` | NO | — |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `property_option_pk`: (`id`)
- **UNIQUE CONSTRAINT** `uq__property__57d99bb95267570c`: (`property_id`, `label`)
- **UNIQUE CONSTRAINT** `uq__property__d7501ac15543c3b7`: (`property_id`, `value`)

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - `property_option_fk_1`: Filho `perseus.property_option` (`property_id`) -> Pai `perseus.property` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE NO ACTION

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - Nenhuma tabela filha referenciando esta tabela.

---

### perseus.robot_run

**Arquivo fonte**: `13.create-table/77.perseus.robot_run.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `id` | `integer` | `IDENTITY` | NO | PK |
| `robot_id` | `integer` | `—` | YES | FK |
| `name` | `public.citext` | `—` | NO | UK |
| `all_qc_passed` | `boolean` | `—` | YES | — |
| `all_themis_submitted` | `boolean` | `—` | YES | — |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `robot_run_pk`: (`id`)
- **UNIQUE INDEX** `uniq_run_name`: (`name`)

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - `robot_run_fk_2`: Filho `perseus.robot_run` (`robot_id`) -> Pai `perseus.container` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE NO ACTION

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - `robot_log_fk_1`: Pai `perseus.robot_run` (`id`) <- Filho `perseus.robot_log` (`robot_run_id`) | ON UPDATE NO ACTION | ON DELETE NO ACTION

---

### perseus.saved_search

**Arquivo fonte**: `13.create-table/79.perseus.saved_search.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `id` | `integer` | `IDENTITY` | NO | PK |
| `class_id` | `integer` | `—` | YES | — |
| `name` | `public.citext` | `—` | NO | UK |
| `added_on` | `timestamp without time zone` | `LOCALTIMESTAMP` | NO | — |
| `added_by` | `integer` | `—` | NO | UK, FK |
| `is_private` | `integer` | `1` | NO | — |
| `include_downstream` | `integer` | `0` | NO | — |
| `parameter_string` | `public.citext` | `—` | NO | — |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `saved_search_pk`: (`id`)
- **UNIQUE CONSTRAINT** `uq__saved_se__a00062956a30c649`: (`name`, `added_by`)

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - `saved_search_fk_1`: Filho `perseus.saved_search` (`added_by`) -> Pai `perseus.perseus_user` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE NO ACTION

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - Nenhuma tabela filha referenciando esta tabela.

---

### perseus.smurf_group

**Arquivo fonte**: `13.create-table/83.perseus.smurf_group.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `id` | `integer` | `IDENTITY` | NO | PK |
| `name` | `public.citext` | `—` | NO | UK |
| `added_by` | `integer` | `—` | NO | FK |
| `is_public` | `boolean` | `false` | NO | — |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `smurf_group_pk`: (`id`)
- **UNIQUE CONSTRAINT** `uq__smurf_gr__72e12f1b1368499a`: (`name`)

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - `sg_creator_fk_1`: Filho `perseus.smurf_group` (`added_by`) -> Pai `perseus.perseus_user` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE NO ACTION

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - `smurf_group_member_fk_2`: Pai `perseus.smurf_group` (`id`) <- Filho `perseus.smurf_group_member` (`smurf_group_id`) | ON UPDATE NO ACTION | ON DELETE CASCADE

---

### perseus.smurf_property

**Arquivo fonte**: `13.create-table/16.perseus.smurf_property.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `id` | `integer` | `IDENTITY` | NO | PK |
| `property_id` | `integer` | `—` | NO | UK, FK |
| `sort_order` | `integer` | `99` | NO | — |
| `smurf_id` | `integer` | `—` | NO | UK, FK |
| `disabled` | `boolean` | `false` | NO | — |
| `calculated` | `public.citext` | `—` | YES | — |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `smurf_property_pk`: (`id`)
- **UNIQUE CONSTRAINT** `uq__smurf_pr__92833c0b5be2a6f2`: (`property_id`, `smurf_id`)

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - `smurf_property_fk_1`: Filho `perseus.smurf_property` (`property_id`) -> Pai `perseus.property` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE CASCADE
  - `smurf_property_fk_2`: Filho `perseus.smurf_property` (`smurf_id`) -> Pai `perseus.smurf` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE CASCADE

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - `poll_smurf_property_fk_1`: Pai `perseus.smurf_property` (`id`) <- Filho `perseus.poll` (`smurf_property_id`) | ON UPDATE NO ACTION | ON DELETE NO ACTION

---

### perseus.submission

**Arquivo fonte**: `13.create-table/85.perseus.submission.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `id` | `integer` | `IDENTITY` | NO | PK |
| `submitter_id` | `integer` | `—` | NO | FK |
| `added_on` | `timestamp without time zone` | `—` | NO | — |
| `label` | `public.citext` | `—` | YES | — |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `pk__submissi__3213e83f71b57d70`: (`id`)
- **Unique keys**: nenhuma além da PK.

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - `fk__submissio__submi__739dc5e2`: Filho `perseus.submission` (`submitter_id`) -> Pai `perseus.perseus_user` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE NO ACTION

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - `fk__submissio__submi__7c330be3`: Pai `perseus.submission` (`id`) <- Filho `perseus.submission_entry` (`submission_id`) | ON UPDATE NO ACTION | ON DELETE NO ACTION

---

### perseus.workflow

**Arquivo fonte**: `13.create-table/88.perseus.workflow.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `id` | `integer` | `IDENTITY` | NO | PK |
| `name` | `public.citext` | `—` | NO | UK |
| `added_on` | `timestamp without time zone` | `LOCALTIMESTAMP` | NO | — |
| `added_by` | `integer` | `23` | NO | FK |
| `disabled` | `integer` | `0` | NO | — |
| `manufacturer_id` | `integer` | `—` | NO | FK |
| `description` | `public.citext` | `—` | YES | — |
| `category` | `public.citext` | `—` | YES | — |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `workflow_pk`: (`id`)
- **UNIQUE CONSTRAINT** `uq__workflow__72e12f1b00cbdb56`: (`name`)

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - `workflow_creator_fk_1`: Filho `perseus.workflow` (`added_by`) -> Pai `perseus.perseus_user` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `workflow_manufacturer_id_fk_1`: Filho `perseus.workflow` (`manufacturer_id`) -> Pai `perseus.manufacturer` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE NO ACTION

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - `fk__recipe__workflow__64aa5f1f`: Pai `perseus.workflow` (`id`) <- Filho `perseus.recipe` (`workflow_id`) | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `workflow_attachment_fk_2`: Pai `perseus.workflow` (`id`) <- Filho `perseus.workflow_attachment` (`workflow_id`) | ON UPDATE NO ACTION | ON DELETE CASCADE
  - `workflow_section_fk_1`: Pai `perseus.workflow` (`id`) <- Filho `perseus.workflow_section` (`workflow_id`) | ON UPDATE NO ACTION | ON DELETE CASCADE
  - `fk_workflow_step_workflow`: Pai `perseus.workflow` (`id`) <- Filho `perseus.workflow_step` (`scope_id`) | ON UPDATE NO ACTION | ON DELETE CASCADE

---

## Tier 3 (8 tabelas)

### perseus.container_history

**Arquivo fonte**: `13.create-table/23.perseus.container_history.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `id` | `integer` | `IDENTITY` | NO | PK |
| `history_id` | `integer` | `—` | NO | FK |
| `container_id` | `integer` | `—` | NO | FK |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `container_history_pk`: (`id`)
- **Unique keys**: nenhuma além da PK.

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - `container_history_fk_1`: Filho `perseus.container_history` (`history_id`) -> Pai `perseus.history` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE CASCADE
  - `container_history_fk_2`: Filho `perseus.container_history` (`container_id`) -> Pai `perseus.container` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE CASCADE

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - Nenhuma tabela filha referenciando esta tabela.

---

### perseus.history_value

**Arquivo fonte**: `13.create-table/50.perseus.history_value.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `id` | `integer` | `IDENTITY` | NO | PK |
| `history_id` | `integer` | `—` | NO | FK |
| `value` | `public.citext` | `—` | YES | — |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `history_value_pk`: (`id`)
- **Unique keys**: nenhuma além da PK.

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - `history_value_fk_1`: Filho `perseus.history_value` (`history_id`) -> Pai `perseus.history` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE CASCADE

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - Nenhuma tabela filha referenciando esta tabela.

---

### perseus.material_inventory_threshold_notify_user

**Arquivo fonte**: `13.create-table/58.perseus.material_inventory_threshold_notify_user.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `threshold_id` | `integer` | `—` | NO | PK, FK |
| `user_id` | `integer` | `—` | NO | PK, FK |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `pk_material_inventory_threshold_notify_user`: (`threshold_id`, `user_id`)
- **Unique keys**: nenhuma além da PK.

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - `fk_mit_notify_user_threshold`: Filho `perseus.material_inventory_threshold_notify_user` (`threshold_id`) -> Pai `perseus.material_inventory_threshold` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE CASCADE
  - `fk_mit_notify_user_user`: Filho `perseus.material_inventory_threshold_notify_user` (`user_id`) -> Pai `perseus.perseus_user` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE NO ACTION

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - Nenhuma tabela filha referenciando esta tabela.

---

### perseus.recipe

**Arquivo fonte**: `13.create-table/68.perseus.recipe.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `id` | `integer` | `IDENTITY` | NO | PK |
| `name` | `public.citext` | `—` | NO | UK |
| `goo_type_id` | `integer` | `—` | NO | FK |
| `description` | `public.citext` | `—` | YES | — |
| `sop` | `public.citext` | `—` | YES | — |
| `workflow_id` | `integer` | `—` | YES | FK |
| `added_by` | `integer` | `—` | NO | FK |
| `added_on` | `timestamp without time zone` | `—` | NO | — |
| `is_preferred` | `boolean` | `(0)::boolean` | NO | — |
| `qc` | `boolean` | `(0)::boolean` | NO | — |
| `is_archived` | `boolean` | `(0)::boolean` | NO | — |
| `feed_type_id` | `integer` | `—` | YES | FK |
| `stock_concentration` | `double precision` | `—` | YES | — |
| `sterilization_method` | `public.citext` | `—` | YES | — |
| `inoculant_percent` | `double precision` | `—` | YES | — |
| `post_inoc_volume_ml` | `double precision` | `—` | YES | — |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `pk__recipe__3213e83f5d093d57`: (`id`)
- **UNIQUE CONSTRAINT** `uq__recipe__72e12f1b5fe5aa02`: (`name`)
- **UNIQUE CONSTRAINT** `uq__recipe__72e12f1b62c216ad`: (`name`)

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - `fk__recipe__added_by__659e8358`: Filho `perseus.recipe` (`added_by`) -> Pai `perseus.perseus_user` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `fk__recipe__feed_typ__471bc4b0`: Filho `perseus.recipe` (`feed_type_id`) -> Pai `perseus.feed_type` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `fk__recipe__goo_type__6692a791`: Filho `perseus.recipe` (`goo_type_id`) -> Pai `perseus.goo_type` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `fk__recipe__workflow__64aa5f1f`: Filho `perseus.recipe` (`workflow_id`) -> Pai `perseus.workflow` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE NO ACTION

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - `fk_goo_recipe`: Pai `perseus.recipe` (`id`) <- Filho `perseus.goo` (`recipe_id`) | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `fk__material___recip__1736dc0d`: Pai `perseus.recipe` (`id`) <- Filho `perseus.material_inventory` (`recipe_id`) | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `fk__recipe_pa__part___083eb140`: Pai `perseus.recipe` (`id`) <- Filho `perseus.recipe_part` (`part_recipe_id`) | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `fk__recipe_pa__recip__6d3fa520`: Pai `perseus.recipe` (`id`) <- Filho `perseus.recipe_part` (`recipe_id`) | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `fk__recipe_pr__recip__0d5f605d`: Pai `perseus.recipe` (`id`) <- Filho `perseus.recipe_project_assignment` (`recipe_id`) | ON UPDATE NO ACTION | ON DELETE NO ACTION

---

### perseus.robot_log

**Arquivo fonte**: `13.create-table/71.perseus.robot_log.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `id` | `integer` | `IDENTITY` | NO | PK |
| `class_id` | `integer` | `—` | NO | — |
| `source` | `public.citext` | `—` | YES | — |
| `created_on` | `timestamp without time zone` | `LOCALTIMESTAMP` | NO | — |
| `log_text` | `public.citext` | `—` | NO | — |
| `file_name` | `public.citext` | `—` | YES | — |
| `robot_log_checksum` | `public.citext` | `—` | YES | — |
| `started_on` | `timestamp without time zone` | `—` | YES | — |
| `completed_on` | `timestamp without time zone` | `—` | YES | — |
| `loaded_on` | `timestamp without time zone` | `—` | YES | — |
| `loaded` | `integer` | `0` | NO | — |
| `loadable` | `integer` | `0` | NO | — |
| `robot_run_id` | `integer` | `—` | YES | FK |
| `robot_log_type_id` | `integer` | `—` | NO | FK |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `robot_log_pk`: (`id`)
- **Unique keys**: nenhuma além da PK.

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - `fk__robot_log__robot__01bf6602`: Filho `perseus.robot_log` (`robot_log_type_id`) -> Pai `perseus.robot_log_type` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `robot_log_fk_1`: Filho `perseus.robot_log` (`robot_run_id`) -> Pai `perseus.robot_run` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE NO ACTION

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - `robot_log_container_sequence_fk_3`: Pai `perseus.robot_log` (`id`) <- Filho `perseus.robot_log_container_sequence` (`robot_log_id`) | ON UPDATE NO ACTION | ON DELETE CASCADE
  - `robot_log_error_fk_1`: Pai `perseus.robot_log` (`id`) <- Filho `perseus.robot_log_error` (`robot_log_id`) | ON UPDATE NO ACTION | ON DELETE CASCADE
  - `robot_log_read_fk_1`: Pai `perseus.robot_log` (`id`) <- Filho `perseus.robot_log_read` (`robot_log_id`) | ON UPDATE NO ACTION | ON DELETE CASCADE
  - `robot_log_transfer_fk_1`: Pai `perseus.robot_log` (`id`) <- Filho `perseus.robot_log_transfer` (`robot_log_id`) | ON UPDATE NO ACTION | ON DELETE CASCADE

---

### perseus.smurf_group_member

**Arquivo fonte**: `13.create-table/84.perseus.smurf_group_member.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `id` | `integer` | `IDENTITY` | NO | PK |
| `smurf_group_id` | `integer` | `—` | NO | UK, FK |
| `smurf_id` | `integer` | `—` | NO | UK, FK |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `smurf_group_member_pk`: (`id`)
- **UNIQUE CONSTRAINT** `uq__smurf_gr__327439fa182cfeb7`: (`smurf_group_id`, `smurf_id`)

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - `smurf_group_member_fk_1`: Filho `perseus.smurf_group_member` (`smurf_id`) -> Pai `perseus.smurf` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE CASCADE
  - `smurf_group_member_fk_2`: Filho `perseus.smurf_group_member` (`smurf_group_id`) -> Pai `perseus.smurf_group` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE CASCADE

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - Nenhuma tabela filha referenciando esta tabela.

---

### perseus.workflow_attachment

**Arquivo fonte**: `13.create-table/89.perseus.workflow_attachment.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `id` | `integer` | `IDENTITY` | NO | PK |
| `workflow_id` | `integer` | `—` | NO | FK |
| `added_on` | `timestamp without time zone` | `LOCALTIMESTAMP` | NO | — |
| `added_by` | `integer` | `—` | NO | FK |
| `attachment_name` | `public.citext` | `—` | YES | — |
| `attachment_mime_type` | `public.citext` | `—` | YES | — |
| `attachment` | `bytea` | `—` | YES | — |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `workflow_attachment_pk`: (`id`)
- **Unique keys**: nenhuma além da PK.

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - `workflow_attachment_fk_1`: Filho `perseus.workflow_attachment` (`added_by`) -> Pai `perseus.perseus_user` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `workflow_attachment_fk_2`: Filho `perseus.workflow_attachment` (`workflow_id`) -> Pai `perseus.workflow` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE CASCADE

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - Nenhuma tabela filha referenciando esta tabela.

---

### perseus.workflow_step

**Arquivo fonte**: `13.create-table/91.perseus.workflow_step.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `id` | `integer` | `IDENTITY` | NO | PK |
| `left_id` | `integer` | `—` | YES | — |
| `right_id` | `integer` | `—` | YES | — |
| `scope_id` | `integer` | `—` | NO | FK |
| `class_id` | `integer` | `—` | NO | — |
| `name` | `public.citext` | `—` | NO | — |
| `smurf_id` | `integer` | `—` | YES | FK |
| `goo_type_id` | `integer` | `—` | YES | FK |
| `property_id` | `integer` | `—` | YES | FK |
| `label` | `public.citext` | `—` | YES | — |
| `optional` | `boolean` | `false` | NO | — |
| `goo_amount_unit_id` | `integer` | `61` | YES | FK |
| `depth` | `integer` | `—` | YES | — |
| `description` | `public.citext` | `—` | YES | — |
| `recipe_factor` | `double precision` | `—` | YES | — |
| `parent_id` | `integer` | `—` | YES | — |
| `child_order` | `integer` | `—` | YES | — |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `workflow_step_pk`: (`id`)
- **Unique keys**: nenhuma além da PK.

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - `fk_workflow_step_goo_type`: Filho `perseus.workflow_step` (`goo_type_id`) -> Pai `perseus.goo_type` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `fk_workflow_step_property`: Filho `perseus.workflow_step` (`property_id`) -> Pai `perseus.property` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `fk_workflow_step_smurf`: Filho `perseus.workflow_step` (`smurf_id`) -> Pai `perseus.smurf` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `fk_workflow_step_workflow`: Filho `perseus.workflow_step` (`scope_id`) -> Pai `perseus.workflow` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE CASCADE
  - `workflow_step_unit_fk_1`: Filho `perseus.workflow_step` (`goo_amount_unit_id`) -> Pai `perseus.unit` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE NO ACTION

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - `fk_fatsmurf_workflow_step`: Pai `perseus.workflow_step` (`id`) <- Filho `perseus.fatsmurf` (`workflow_step_id`) | ON UPDATE NO ACTION | ON DELETE SET NULL
  - `fk_goo_workflow_step`: Pai `perseus.workflow_step` (`id`) <- Filho `perseus.goo` (`workflow_step_id`) | ON UPDATE NO ACTION | ON DELETE SET NULL
  - `fk__recipe_pa__workf__6c4b80e7`: Pai `perseus.workflow_step` (`id`) <- Filho `perseus.recipe_part` (`workflow_step_id`) | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `workflow_step_start_fk_1`: Pai `perseus.workflow_step` (`id`) <- Filho `perseus.workflow_section` (`starting_step_id`) | ON UPDATE NO ACTION | ON DELETE NO ACTION

---

## Tier 4 (6 tabelas)

### perseus.fatsmurf

**Arquivo fonte**: `13.create-table/30.perseus.fatsmurf.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `id` | `integer` | `IDENTITY` | NO | PK |
| `smurf_id` | `integer` | `—` | NO | FK |
| `recycled_bottoms_id` | `integer` | `—` | YES | — |
| `name` | `public.citext` | `—` | YES | — |
| `description` | `public.citext` | `—` | YES | — |
| `added_on` | `timestamp without time zone` | `LOCALTIMESTAMP` | NO | — |
| `run_on` | `timestamp without time zone` | `—` | YES | — |
| `duration` | `double precision` | `—` | YES | — |
| `added_by` | `integer` | `—` | NO | — |
| `themis_sample_id` | `integer` | `—` | YES | — |
| `uid` | `public.citext` | `—` | NO | UK |
| `run_complete` | `timestamp without time zone` | `—` | YES | — |
| `container_id` | `integer` | `—` | YES | FK |
| `organization_id` | `integer` | `1` | YES | FK |
| `workflow_step_id` | `integer` | `—` | YES | FK |
| `updated_on` | `timestamp without time zone` | `LOCALTIMESTAMP` | YES | — |
| `inserted_on` | `timestamp without time zone` | `LOCALTIMESTAMP` | YES | — |
| `triton_task_id` | `integer` | `—` | YES | — |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `fatsmurf_pk`: (`id`)
- **UNIQUE INDEX** `uniq_fs_uid`: (`uid`)

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - `fk_fatsmurf_smurf_id`: Filho `perseus.fatsmurf` (`smurf_id`) -> Pai `perseus.smurf` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `fk_fatsmurf_workflow_step`: Filho `perseus.fatsmurf` (`workflow_step_id`) -> Pai `perseus.workflow_step` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE SET NULL
  - `fs_container_id_fk_1`: Filho `perseus.fatsmurf` (`container_id`) -> Pai `perseus.container` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE SET NULL
  - `fs_organization_fk_1`: Filho `perseus.fatsmurf` (`organization_id`) -> Pai `perseus.manufacturer` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE NO ACTION

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - `fatsmurf_attachment_fk_2`: Pai `perseus.fatsmurf` (`id`) <- Filho `perseus.fatsmurf_attachment` (`fatsmurf_id`) | ON UPDATE NO ACTION | ON DELETE CASCADE
  - `fatsmurf_comment_fk_2`: Pai `perseus.fatsmurf` (`id`) <- Filho `perseus.fatsmurf_comment` (`fatsmurf_id`) | ON UPDATE NO ACTION | ON DELETE CASCADE
  - `fatsmurf_history_fk_2`: Pai `perseus.fatsmurf` (`id`) <- Filho `perseus.fatsmurf_history` (`fatsmurf_id`) | ON UPDATE NO ACTION | ON DELETE CASCADE
  - `fatsmurf_reading_fk_1`: Pai `perseus.fatsmurf` (`id`) <- Filho `perseus.fatsmurf_reading` (`fatsmurf_id`) | ON UPDATE NO ACTION | ON DELETE CASCADE
  - `fk_material_transition_fatsmurf`: Pai `perseus.fatsmurf` (`uid`) <- Filho `perseus.material_transition` (`transition_id`) | ON UPDATE NO ACTION | ON DELETE CASCADE
  - `fk_transition_material_fatsmurf`: Pai `perseus.fatsmurf` (`uid`) <- Filho `perseus.transition_material` (`transition_id`) | ON UPDATE NO ACTION | ON DELETE CASCADE

---

### perseus.recipe_part

**Arquivo fonte**: `13.create-table/69.perseus.recipe_part.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `id` | `integer` | `IDENTITY` | NO | PK |
| `recipe_id` | `integer` | `—` | NO | FK |
| `description` | `public.citext` | `—` | YES | — |
| `goo_type_id` | `integer` | `—` | NO | FK |
| `amount` | `double precision` | `—` | NO | — |
| `unit_id` | `integer` | `—` | NO | FK |
| `workflow_step_id` | `integer` | `—` | YES | FK |
| `position` | `integer` | `—` | YES | — |
| `part_recipe_id` | `integer` | `—` | YES | FK |
| `target_conc_in_media` | `double precision` | `—` | YES | — |
| `target_post_inoc_conc` | `double precision` | `—` | YES | — |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `pk__recipe_p__3213e83f696f143c`: (`id`)
- **Unique keys**: nenhuma além da PK.

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - `fk__recipe_pa__goo_t__6e33c959`: Filho `perseus.recipe_part` (`goo_type_id`) -> Pai `perseus.goo_type` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `fk__recipe_pa__part___083eb140`: Filho `perseus.recipe_part` (`part_recipe_id`) -> Pai `perseus.recipe` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `fk__recipe_pa__recip__6d3fa520`: Filho `perseus.recipe_part` (`recipe_id`) -> Pai `perseus.recipe` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `fk__recipe_pa__unit___6b575cae`: Filho `perseus.recipe_part` (`unit_id`) -> Pai `perseus.unit` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `fk__recipe_pa__workf__6c4b80e7`: Filho `perseus.recipe_part` (`workflow_step_id`) -> Pai `perseus.workflow_step` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE NO ACTION

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - `fk_goo_recipe_part`: Pai `perseus.recipe_part` (`id`) <- Filho `perseus.goo` (`recipe_part_id`) | ON UPDATE NO ACTION | ON DELETE NO ACTION

---

### perseus.recipe_project_assignment

**Arquivo fonte**: `13.create-table/70.perseus.recipe_project_assignment.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `project_id` | `smallint` | `—` | NO | — |
| `recipe_id` | `integer` | `—` | NO | FK |
| `md5_hash` | `text` | `—` | NO | PK |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `perseus_recipe_project_assignment_pk_md5_hash`: (`md5_hash`)
- **Unique keys**: nenhuma além da PK.

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - `fk__recipe_pr__recip__0d5f605d`: Filho `perseus.recipe_project_assignment` (`recipe_id`) -> Pai `perseus.recipe` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE NO ACTION

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - Nenhuma tabela filha referenciando esta tabela.

---

### perseus.robot_log_container_sequence

**Arquivo fonte**: `13.create-table/72.perseus.robot_log_container_sequence.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `id` | `integer` | `IDENTITY` | NO | PK |
| `robot_log_id` | `integer` | `—` | NO | UK, FK |
| `container_id` | `integer` | `—` | NO | UK, FK |
| `sequence_type_id` | `integer` | `—` | NO | UK, FK |
| `processed_on` | `timestamp without time zone` | `—` | YES | — |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `robot_log_container_sequence_pk`: (`id`)
- **UNIQUE CONSTRAINT** `uq__robot_lo__acca81e32e521557`: (`robot_log_id`, `container_id`, `sequence_type_id`)

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - `robot_log_container_sequence_fk_1`: Filho `perseus.robot_log_container_sequence` (`sequence_type_id`) -> Pai `perseus.sequence_type` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE CASCADE
  - `robot_log_container_sequence_fk_2`: Filho `perseus.robot_log_container_sequence` (`container_id`) -> Pai `perseus.container` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE CASCADE
  - `robot_log_container_sequence_fk_3`: Filho `perseus.robot_log_container_sequence` (`robot_log_id`) -> Pai `perseus.robot_log` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE CASCADE

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - Nenhuma tabela filha referenciando esta tabela.

---

### perseus.robot_log_error

**Arquivo fonte**: `13.create-table/73.perseus.robot_log_error.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `id` | `integer` | `IDENTITY` | NO | PK |
| `robot_log_id` | `integer` | `—` | NO | FK |
| `error_text` | `public.citext` | `—` | NO | — |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `robot_log_error_pk`: (`id`)
- **Unique keys**: nenhuma além da PK.

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - `robot_log_error_fk_1`: Filho `perseus.robot_log_error` (`robot_log_id`) -> Pai `perseus.robot_log` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE CASCADE

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - Nenhuma tabela filha referenciando esta tabela.

---

### perseus.workflow_section

**Arquivo fonte**: `13.create-table/90.perseus.workflow_section.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `id` | `integer` | `IDENTITY` | NO | PK |
| `workflow_id` | `integer` | `—` | NO | UK, FK |
| `name` | `public.citext` | `—` | NO | UK |
| `starting_step_id` | `integer` | `—` | NO | UK, FK |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `workflow_section_pk`: (`id`)
- **UNIQUE CONSTRAINT** `uq__workflow__7533c67705909073`: (`workflow_id`, `starting_step_id`)
- **UNIQUE CONSTRAINT** `uq__workflow__d3897980086cfd1e`: (`workflow_id`, `name`)
- **UNIQUE INDEX** `uniq_starting_step`: (`starting_step_id`)

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - `workflow_section_fk_1`: Filho `perseus.workflow_section` (`workflow_id`) -> Pai `perseus.workflow` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE CASCADE
  - `workflow_step_start_fk_1`: Filho `perseus.workflow_section` (`starting_step_id`) -> Pai `perseus.workflow_step` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE NO ACTION

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - Nenhuma tabela filha referenciando esta tabela.

---

## Tier 5 (6 tabelas)

### perseus.fatsmurf_attachment

**Arquivo fonte**: `13.create-table/31.perseus.fatsmurf_attachment.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `id` | `integer` | `IDENTITY` | NO | PK |
| `fatsmurf_id` | `integer` | `—` | NO | FK |
| `added_on` | `timestamp without time zone` | `LOCALTIMESTAMP` | NO | — |
| `added_by` | `integer` | `—` | NO | FK |
| `description` | `public.citext` | `—` | NO | — |
| `attachment_name` | `public.citext` | `—` | YES | — |
| `attachment_mime_type` | `public.citext` | `—` | YES | — |
| `attachment` | `bytea` | `—` | YES | — |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `fatsmurf_attachment_pk`: (`id`)
- **Unique keys**: nenhuma além da PK.

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - `fatsmurf_attachment_fk_1`: Filho `perseus.fatsmurf_attachment` (`added_by`) -> Pai `perseus.perseus_user` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `fatsmurf_attachment_fk_2`: Filho `perseus.fatsmurf_attachment` (`fatsmurf_id`) -> Pai `perseus.fatsmurf` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE CASCADE

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - Nenhuma tabela filha referenciando esta tabela.

---

### perseus.fatsmurf_comment

**Arquivo fonte**: `13.create-table/32.perseus.fatsmurf_comment.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `id` | `integer` | `IDENTITY` | NO | PK |
| `fatsmurf_id` | `integer` | `—` | NO | FK |
| `added_on` | `timestamp without time zone` | `LOCALTIMESTAMP` | NO | — |
| `added_by` | `integer` | `—` | NO | FK |
| `comment` | `public.citext` | `—` | NO | — |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `fatsmurf_comment_pk`: (`id`)
- **Unique keys**: nenhuma além da PK.

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - `fatsmurf_comment_fk_1`: Filho `perseus.fatsmurf_comment` (`added_by`) -> Pai `perseus.perseus_user` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `fatsmurf_comment_fk_2`: Filho `perseus.fatsmurf_comment` (`fatsmurf_id`) -> Pai `perseus.fatsmurf` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE CASCADE

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - Nenhuma tabela filha referenciando esta tabela.

---

### perseus.fatsmurf_history

**Arquivo fonte**: `13.create-table/33.perseus.fatsmurf_history.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `id` | `integer` | `IDENTITY` | NO | PK |
| `history_id` | `integer` | `—` | NO | FK |
| `fatsmurf_id` | `integer` | `—` | NO | FK |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `fatsmurf_history_pk`: (`id`)
- **Unique keys**: nenhuma além da PK.

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - `fatsmurf_history_fk_1`: Filho `perseus.fatsmurf_history` (`history_id`) -> Pai `perseus.history` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE CASCADE
  - `fatsmurf_history_fk_2`: Filho `perseus.fatsmurf_history` (`fatsmurf_id`) -> Pai `perseus.fatsmurf` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE CASCADE

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - Nenhuma tabela filha referenciando esta tabela.

---

### perseus.fatsmurf_reading

**Arquivo fonte**: `13.create-table/34.perseus.fatsmurf_reading.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `id` | `integer` | `IDENTITY` | NO | PK |
| `name` | `public.citext` | `—` | NO | UK |
| `fatsmurf_id` | `integer` | `—` | NO | UK, FK |
| `added_on` | `timestamp without time zone` | `LOCALTIMESTAMP` | NO | — |
| `added_by` | `integer` | `1` | NO | FK |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `fatsmurf_reading_pk`: (`id`)
- **UNIQUE CONSTRAINT** `uq__fatsmurf__0bc798795afc9d0d`: (`name`, `fatsmurf_id`)

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - `creator_fk_1`: Filho `perseus.fatsmurf_reading` (`added_by`) -> Pai `perseus.perseus_user` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `fatsmurf_reading_fk_1`: Filho `perseus.fatsmurf_reading` (`fatsmurf_id`) -> Pai `perseus.fatsmurf` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE CASCADE

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - `poll_fatsmurf_reading_fk_1`: Pai `perseus.fatsmurf_reading` (`id`) <- Filho `perseus.poll` (`fatsmurf_reading_id`) | ON UPDATE NO ACTION | ON DELETE CASCADE

---

### perseus.goo

**Arquivo fonte**: `13.create-table/39.perseus.goo.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `id` | `integer` | `IDENTITY` | NO | PK |
| `name` | `public.citext` | `—` | YES | — |
| `description` | `public.citext` | `—` | YES | — |
| `added_on` | `timestamp without time zone` | `LOCALTIMESTAMP` | NO | — |
| `added_by` | `integer` | `—` | NO | FK |
| `original_volume` | `double precision` | `0` | YES | — |
| `original_mass` | `double precision` | `0` | YES | — |
| `goo_type_id` | `integer` | `8` | NO | FK |
| `manufacturer_id` | `integer` | `1` | NO | FK |
| `received_on` | `date` | `—` | YES | — |
| `uid` | `public.citext` | `—` | NO | UK |
| `project_id` | `smallint` | `—` | YES | — |
| `container_id` | `integer` | `—` | YES | FK |
| `workflow_step_id` | `integer` | `—` | YES | FK |
| `updated_on` | `timestamp without time zone` | `LOCALTIMESTAMP` | YES | — |
| `inserted_on` | `timestamp without time zone` | `LOCALTIMESTAMP` | YES | — |
| `triton_task_id` | `integer` | `—` | YES | — |
| `recipe_id` | `integer` | `—` | YES | FK |
| `recipe_part_id` | `integer` | `—` | YES | FK |
| `catalog_label` | `public.citext` | `—` | YES | — |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `goo_pk`: (`id`)
- **UNIQUE INDEX** `uniq_goo_uid`: (`uid`)

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - `container_id_fk_1`: Filho `perseus.goo` (`container_id`) -> Pai `perseus.container` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE SET NULL
  - `fk_goo_recipe`: Filho `perseus.goo` (`recipe_id`) -> Pai `perseus.recipe` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `fk_goo_recipe_part`: Filho `perseus.goo` (`recipe_part_id`) -> Pai `perseus.recipe_part` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `fk_goo_workflow_step`: Filho `perseus.goo` (`workflow_step_id`) -> Pai `perseus.workflow_step` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE SET NULL
  - `goo_fk_1`: Filho `perseus.goo` (`goo_type_id`) -> Pai `perseus.goo_type` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `goo_fk_4`: Filho `perseus.goo` (`added_by`) -> Pai `perseus.perseus_user` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `manufacturer_fk_1`: Filho `perseus.goo` (`manufacturer_id`) -> Pai `perseus.manufacturer` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE NO ACTION

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - `goo_attachment_fk_2`: Pai `perseus.goo` (`id`) <- Filho `perseus.goo_attachment` (`goo_id`) | ON UPDATE NO ACTION | ON DELETE CASCADE
  - `goo_comment_fk_2`: Pai `perseus.goo` (`id`) <- Filho `perseus.goo_comment` (`goo_id`) | ON UPDATE NO ACTION | ON DELETE CASCADE
  - `goo_history_fk_2`: Pai `perseus.goo` (`id`) <- Filho `perseus.goo_history` (`goo_id`) | ON UPDATE NO ACTION | ON DELETE CASCADE
  - `fk__material___mater__182b0046`: Pai `perseus.goo` (`id`) <- Filho `perseus.material_inventory` (`material_id`) | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `fk__material___mater__5b988a00`: Pai `perseus.goo` (`id`) <- Filho `perseus.material_qc` (`material_id`) | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `fk_robot_log_read_source_material_id`: Pai `perseus.goo` (`id`) <- Filho `perseus.robot_log_read` (`source_material_id`) | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `fk_robot_log_transfer_destination_material_id`: Pai `perseus.goo` (`id`) <- Filho `perseus.robot_log_transfer` (`destination_material_id`) | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `fk_robot_log_transfer_source_material_id`: Pai `perseus.goo` (`id`) <- Filho `perseus.robot_log_transfer` (`source_material_id`) | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `fk__submissio__mater__79569f38`: Pai `perseus.goo` (`id`) <- Filho `perseus.submission_entry` (`material_id`) | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `fk_transition_material_goo`: Pai `perseus.goo` (`uid`) <- Filho `perseus.transition_material` (`material_id`) | ON UPDATE CASCADE | ON DELETE CASCADE

---

### perseus.material_transition

**Arquivo fonte**: `13.create-table/27.perseus.material_transition.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `material_id` | `public.citext` | `—` | NO | PK |
| `transition_id` | `public.citext` | `—` | NO | PK, FK |
| `added_on` | `timestamp without time zone` | `LOCALTIMESTAMP` | NO | — |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `pk__material__78fcfd7e69fee97b`: (`material_id`, `transition_id`)
- **Unique keys**: nenhuma além da PK.

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - `fk_material_transition_fatsmurf`: Filho `perseus.material_transition` (`transition_id`) -> Pai `perseus.fatsmurf` (`uid`) | chave pai: **UK** | ON UPDATE NO ACTION | ON DELETE CASCADE

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - Nenhuma tabela filha referenciando esta tabela.

---

## Tier 6 (10 tabelas)

### perseus.goo_attachment

**Arquivo fonte**: `13.create-table/40.perseus.goo_attachment.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `id` | `integer` | `IDENTITY` | NO | PK |
| `goo_id` | `integer` | `—` | NO | FK |
| `added_on` | `timestamp without time zone` | `LOCALTIMESTAMP` | NO | — |
| `added_by` | `integer` | `—` | NO | FK |
| `description` | `public.citext` | `—` | YES | — |
| `attachment_name` | `public.citext` | `—` | NO | — |
| `attachment_mime_type` | `public.citext` | `—` | YES | — |
| `attachment` | `bytea` | `—` | YES | — |
| `goo_attachment_type_id` | `integer` | `—` | YES | FK |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `goo_attachment_pk`: (`id`)
- **Unique keys**: nenhuma além da PK.

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - `goo_attachment_fk_1`: Filho `perseus.goo_attachment` (`added_by`) -> Pai `perseus.perseus_user` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `goo_attachment_fk_2`: Filho `perseus.goo_attachment` (`goo_id`) -> Pai `perseus.goo` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE CASCADE
  - `goo_attachment_fk_3`: Filho `perseus.goo_attachment` (`goo_attachment_type_id`) -> Pai `perseus.goo_attachment_type` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE NO ACTION

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - Nenhuma tabela filha referenciando esta tabela.

---

### perseus.goo_comment

**Arquivo fonte**: `13.create-table/42.perseus.goo_comment.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `id` | `integer` | `IDENTITY` | NO | PK |
| `goo_id` | `integer` | `—` | NO | FK |
| `added_on` | `timestamp without time zone` | `LOCALTIMESTAMP` | NO | — |
| `added_by` | `integer` | `—` | NO | FK |
| `comment` | `public.citext` | `—` | NO | — |
| `category` | `public.citext` | `—` | YES | — |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `goo_comment_pk`: (`id`)
- **Unique keys**: nenhuma além da PK.

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - `goo_comment_fk_1`: Filho `perseus.goo_comment` (`added_by`) -> Pai `perseus.perseus_user` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `goo_comment_fk_2`: Filho `perseus.goo_comment` (`goo_id`) -> Pai `perseus.goo` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE CASCADE

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - Nenhuma tabela filha referenciando esta tabela.

---

### perseus.goo_history

**Arquivo fonte**: `13.create-table/43.perseus.goo_history.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `id` | `integer` | `IDENTITY` | NO | PK |
| `history_id` | `integer` | `—` | NO | FK |
| `goo_id` | `integer` | `—` | NO | FK |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `goo_history_pk`: (`id`)
- **Unique keys**: nenhuma além da PK.

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - `goo_history_fk_1`: Filho `perseus.goo_history` (`history_id`) -> Pai `perseus.history` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE CASCADE
  - `goo_history_fk_2`: Filho `perseus.goo_history` (`goo_id`) -> Pai `perseus.goo` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE CASCADE

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - Nenhuma tabela filha referenciando esta tabela.

---

### perseus.material_inventory

**Arquivo fonte**: `13.create-table/56.perseus.material_inventory.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `id` | `integer` | `IDENTITY` | NO | PK |
| `material_id` | `integer` | `—` | NO | UK, FK |
| `location_container_id` | `integer` | `—` | NO | FK |
| `is_active` | `boolean` | `—` | NO | — |
| `current_volume_l` | `real` | `—` | YES | — |
| `current_mass_kg` | `real` | `—` | YES | — |
| `created_by_id` | `integer` | `—` | NO | FK |
| `created_on` | `timestamp without time zone` | `—` | YES | — |
| `updated_by_id` | `integer` | `—` | YES | FK |
| `updated_on` | `timestamp without time zone` | `—` | YES | — |
| `allocation_container_id` | `integer` | `—` | YES | FK |
| `recipe_id` | `integer` | `—` | YES | FK |
| `comment` | `public.citext` | `—` | YES | — |
| `expiration_date` | `date` | `—` | YES | — |
| `inventory_type_id` | `integer` | `—` | NO | FK |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `pk__material__3213e83f77f9310a`: (`id`)
- **UNIQUE CONSTRAINT** `uq__material__6bfe1d29c2c4ddab`: (`material_id`)

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - `fk__material___alloc__1642b7d4`: Filho `perseus.material_inventory` (`allocation_container_id`) -> Pai `perseus.container` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `fk__material___creat__1a1348b8`: Filho `perseus.material_inventory` (`created_by_id`) -> Pai `perseus.perseus_user` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `fk__material___locat__191f247f`: Filho `perseus.material_inventory` (`location_container_id`) -> Pai `perseus.container` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `fk__material___mater__182b0046`: Filho `perseus.material_inventory` (`material_id`) -> Pai `perseus.goo` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `fk__material___recip__1736dc0d`: Filho `perseus.material_inventory` (`recipe_id`) -> Pai `perseus.recipe` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `fk__material___updat__1b076cf1`: Filho `perseus.material_inventory` (`updated_by_id`) -> Pai `perseus.perseus_user` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `fk_material_inventory_inventory_type_id`: Filho `perseus.material_inventory` (`inventory_type_id`) -> Pai `perseus.material_inventory_type` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE NO ACTION

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - Nenhuma tabela filha referenciando esta tabela.

---

### perseus.material_qc

**Arquivo fonte**: `13.create-table/60.perseus.material_qc.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `id` | `integer` | `IDENTITY` | NO | PK |
| `material_id` | `integer` | `—` | NO | FK |
| `entity_type_name` | `public.citext` | `—` | NO | — |
| `foreign_entity_id` | `integer` | `—` | NO | — |
| `qc_process_uid` | `public.citext` | `—` | NO | — |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `pk__material__3213e83fe6b39cc1`: (`id`)
- **Unique keys**: nenhuma além da PK.

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - `fk__material___mater__5b988a00`: Filho `perseus.material_qc` (`material_id`) -> Pai `perseus.goo` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE NO ACTION

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - Nenhuma tabela filha referenciando esta tabela.

---

### perseus.poll

**Arquivo fonte**: `13.create-table/65.perseus.poll.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `id` | `integer` | `IDENTITY` | NO | PK |
| `smurf_property_id` | `integer` | `—` | NO | UK, FK |
| `fatsmurf_reading_id` | `integer` | `—` | NO | UK, FK |
| `value` | `public.citext` | `—` | YES | — |
| `standard_deviation` | `double precision` | `—` | YES | — |
| `detection` | `integer` | `—` | YES | — |
| `limit_of_detection` | `double precision` | `—` | YES | — |
| `limit_of_quantification` | `double precision` | `—` | YES | — |
| `lower_calibration_limit` | `double precision` | `—` | YES | — |
| `upper_calibration_limit` | `double precision` | `—` | YES | — |
| `bounds_limit` | `integer` | `—` | YES | — |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `poll_pk`: (`id`)
- **UNIQUE CONSTRAINT** `uq__poll__2edadb146383c8ba`: (`fatsmurf_reading_id`, `smurf_property_id`)

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - `poll_fatsmurf_reading_fk_1`: Filho `perseus.poll` (`fatsmurf_reading_id`) -> Pai `perseus.fatsmurf_reading` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE CASCADE
  - `poll_smurf_property_fk_1`: Filho `perseus.poll` (`smurf_property_id`) -> Pai `perseus.smurf_property` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE NO ACTION

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - `poll_history_fk_2`: Pai `perseus.poll` (`id`) <- Filho `perseus.poll_history` (`poll_id`) | ON UPDATE NO ACTION | ON DELETE CASCADE

---

### perseus.robot_log_read

**Arquivo fonte**: `13.create-table/74.perseus.robot_log_read.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `id` | `integer` | `IDENTITY` | NO | PK |
| `robot_log_id` | `integer` | `—` | NO | FK |
| `source_barcode` | `public.citext` | `—` | NO | — |
| `property_id` | `integer` | `—` | NO | FK |
| `value` | `public.citext` | `—` | YES | — |
| `source_position` | `public.citext` | `—` | YES | — |
| `source_material_id` | `integer` | `—` | YES | FK |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `robot_log_read_pk`: (`id`)
- **Unique keys**: nenhuma além da PK.

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - `fk_robot_log_read_source_material_id`: Filho `perseus.robot_log_read` (`source_material_id`) -> Pai `perseus.goo` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `robot_log_read_fk_1`: Filho `perseus.robot_log_read` (`robot_log_id`) -> Pai `perseus.robot_log` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE CASCADE
  - `robot_log_read_fk_2`: Filho `perseus.robot_log_read` (`property_id`) -> Pai `perseus.property` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE CASCADE

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - Nenhuma tabela filha referenciando esta tabela.

---

### perseus.robot_log_transfer

**Arquivo fonte**: `13.create-table/75.perseus.robot_log_transfer.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `id` | `integer` | `IDENTITY` | NO | PK |
| `robot_log_id` | `integer` | `—` | NO | FK |
| `source_barcode` | `public.citext` | `—` | NO | — |
| `destination_barcode` | `public.citext` | `—` | NO | — |
| `transfer_time` | `timestamp without time zone` | `—` | YES | — |
| `transfer_volume` | `public.citext` | `—` | YES | — |
| `source_position` | `public.citext` | `—` | YES | — |
| `destination_position` | `public.citext` | `—` | YES | — |
| `material_type_id` | `integer` | `—` | YES | — |
| `source_material_id` | `integer` | `—` | YES | FK |
| `destination_material_id` | `integer` | `—` | YES | FK |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `robot_log_transfer_pk`: (`id`)
- **Unique keys**: nenhuma além da PK.

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - `fk_robot_log_transfer_destination_material_id`: Filho `perseus.robot_log_transfer` (`destination_material_id`) -> Pai `perseus.goo` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `fk_robot_log_transfer_source_material_id`: Filho `perseus.robot_log_transfer` (`source_material_id`) -> Pai `perseus.goo` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `robot_log_transfer_fk_1`: Filho `perseus.robot_log_transfer` (`robot_log_id`) -> Pai `perseus.robot_log` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE CASCADE

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - Nenhuma tabela filha referenciando esta tabela.

---

### perseus.submission_entry

**Arquivo fonte**: `13.create-table/86.perseus.submission_entry.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `id` | `integer` | `IDENTITY` | NO | PK |
| `assay_type_id` | `integer` | `—` | NO | FK |
| `material_id` | `integer` | `—` | NO | FK |
| `status` | `character varying(19)` | `—` | NO | — |
| `priority` | `character varying(6)` | `—` | NO | — |
| `submission_id` | `integer` | `—` | NO | FK |
| `prepped_by_id` | `integer` | `—` | YES | FK |
| `themis_tray_id` | `integer` | `—` | YES | — |
| `sample_type` | `character varying(7)` | `—` | NO | — |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `pk__submissi__3213e83f767a328d`: (`id`)
- **Unique keys**: nenhuma além da PK.

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - `fk__submissio__assay__78627aff`: Filho `perseus.submission_entry` (`assay_type_id`) -> Pai `perseus.smurf` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `fk__submissio__mater__79569f38`: Filho `perseus.submission_entry` (`material_id`) -> Pai `perseus.goo` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `fk__submissio__prepp__7d27301c`: Filho `perseus.submission_entry` (`prepped_by_id`) -> Pai `perseus.perseus_user` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE NO ACTION
  - `fk__submissio__submi__7c330be3`: Filho `perseus.submission_entry` (`submission_id`) -> Pai `perseus.submission` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE NO ACTION

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - Nenhuma tabela filha referenciando esta tabela.

---

### perseus.transition_material

**Arquivo fonte**: `13.create-table/28.perseus.transition_material.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `transition_id` | `public.citext` | `—` | NO | PK, FK |
| `material_id` | `public.citext` | `—` | NO | PK, FK |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `pk__transiti__a691e4b26dcf7a5f`: (`transition_id`, `material_id`)
- **Unique keys**: nenhuma além da PK.

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - `fk_transition_material_fatsmurf`: Filho `perseus.transition_material` (`transition_id`) -> Pai `perseus.fatsmurf` (`uid`) | chave pai: **UK** | ON UPDATE NO ACTION | ON DELETE CASCADE
  - `fk_transition_material_goo`: Filho `perseus.transition_material` (`material_id`) -> Pai `perseus.goo` (`uid`) | chave pai: **UK** | ON UPDATE CASCADE | ON DELETE CASCADE

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - Nenhuma tabela filha referenciando esta tabela.

---

## Tier 7 (1 tabelas)

### perseus.poll_history

**Arquivo fonte**: `13.create-table/66.perseus.poll_history.sql`

#### 1) Descrição de colunas

| Coluna | Data type | Default data | Nullable | Tipo de chave |
|---|---|---|---|---|
| `id` | `integer` | `IDENTITY` | NO | PK |
| `history_id` | `integer` | `—` | NO | FK |
| `poll_id` | `integer` | `—` | NO | FK |

#### 2) Primary e Unique keys (agrupado por tabela)

- **PK** `poll_history_pk`: (`id`)
- **Unique keys**: nenhuma além da PK.

#### 3) Foreign keys e relação de dependência Pai/Filho

- **Como Filho (FK desta tabela para tabela Pai)**
  - `poll_history_fk_1`: Filho `perseus.poll_history` (`history_id`) -> Pai `perseus.history` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE CASCADE
  - `poll_history_fk_2`: Filho `perseus.poll_history` (`poll_id`) -> Pai `perseus.poll` (`id`) | chave pai: **PK** | ON UPDATE NO ACTION | ON DELETE CASCADE

- **Como Pai (tabelas Filhas que dependem desta tabela)**
  - Nenhuma tabela filha referenciando esta tabela.

---

## Apêndice A - Resumo PK/UK por tabela

### perseus.alembic_version
- PK: `alembic_version_pkc` (version_num)
- UK: —

### perseus.cm_application
- PK: `pk_cm_application` (application_id)
- UK: —

### perseus.cm_application_group
- PK: `pk_cm_application_group` (application_group_id)
- UK: —

### perseus.cm_group
- PK: `pk_group` (group_id)
- UK: —

### perseus.cm_project
- PK: `pk_project` (project_id)
- UK: —

### perseus.cm_unit
- PK: `pk_cm_unit_1` (id)
- UK: —

### perseus.cm_unit_compare
- PK: `pk_cm_unit_compare` (from_unit_id, to_unit_id)
- UK: —

### perseus.cm_unit_dimensions
- PK: `pk_cm_unit_dimensions` (id)
- UK: —

### perseus.cm_user
- PK: `pk_user` (user_id)
- UK: —

### perseus.cm_user_group
- PK: `pk_cm_user_group` (user_id, group_id)
- UK: —

### perseus.coa
- PK: `coa_pk` (id)
- UNIQUE CONSTRAINT: `uq__coa__a045441b2653caa4` (name, goo_type_id)

### perseus.coa_spec
- PK: `coa_spec_pk` (id)
- UNIQUE CONSTRAINT: `uq__coa_spec__175eaf262c0ca3fa` (coa_id, property_id)

### perseus.color
- PK: `pk_color` (name)
- UK: —

### perseus.container
- PK: `container_pk` (id)
- UNIQUE INDEX: `uniq_container_uid` (uid)

### perseus.container_history
- PK: `container_history_pk` (id)
- UK: —

### perseus.container_type
- PK: `container_type_pk` (id)
- UNIQUE CONSTRAINT: `uq__containe__72e12f1b0ea330e9` (name)

### perseus.container_type_position
- PK: `container_type_position_pk` (id)
- UNIQUE CONSTRAINT: `uq__containe__32b36f0e29f6a937` (parent_container_type_id, position_name)

### perseus.display_layout
- PK: `display_layout_pk` (id)
- UNIQUE CONSTRAINT: `uq__display___72e12f1b22c0cedd` (name)

### perseus.display_type
- PK: `display_type_pk` (id)
- UNIQUE CONSTRAINT: `uq__display___72e12f1b1dfc19c0` (name)

### perseus.external_goo_type
- PK: `external_goo_type_pk` (id)
- UNIQUE CONSTRAINT: `uq__external__3b82af230b9fd468` (external_label, manufacturer_id)

### perseus.fatsmurf
- PK: `fatsmurf_pk` (id)
- UNIQUE INDEX: `uniq_fs_uid` (uid)

### perseus.fatsmurf_attachment
- PK: `fatsmurf_attachment_pk` (id)
- UK: —

### perseus.fatsmurf_comment
- PK: `fatsmurf_comment_pk` (id)
- UK: —

### perseus.fatsmurf_history
- PK: `fatsmurf_history_pk` (id)
- UK: —

### perseus.fatsmurf_reading
- PK: `fatsmurf_reading_pk` (id)
- UNIQUE CONSTRAINT: `uq__fatsmurf__0bc798795afc9d0d` (name, fatsmurf_id)

### perseus.feed_type
- PK: `pk__feed_typ__3213e83f16787987` (id)
- UK: —

### perseus.field_map
- PK: `combined_field_map_pk` (id)
- UK: —

### perseus.field_map_block
- PK: `field_map_block_pk` (id)
- UNIQUE CONSTRAINT: `uniq_fmb` (filter, scope)

### perseus.field_map_display_type
- PK: `combined_field_map_display_type_pk` (id)
- UNIQUE CONSTRAINT: `uq__field_ma__f9589110301ac9fb` (field_map_id, display_type_id)

### perseus.field_map_display_type_user
- PK: `field_map_display_type_user_pk` (id)
- UNIQUE CONSTRAINT: `uq__field_ma__49e1a26338b00ffc` (user_id, field_map_display_type_id)

### perseus.field_map_set
- PK: `field_map_set_pk` (id)
- UK: —

### perseus.field_map_type
- PK: `field_map_type_pk` (id)
- UNIQUE CONSTRAINT: `uq__field_ma__72e12f1b278583fa` (name)

### perseus.goo
- PK: `goo_pk` (id)
- UNIQUE INDEX: `uniq_goo_uid` (uid)

### perseus.goo_attachment
- PK: `goo_attachment_pk` (id)
- UK: —

### perseus.goo_attachment_type
- PK: `goo_attachment_type_pk` (id)
- UNIQUE CONSTRAINT: `uq__goo_atta__72e12f1b7a5d7005` (name)

### perseus.goo_comment
- PK: `goo_comment_pk` (id)
- UK: —

### perseus.goo_history
- PK: `goo_history_pk` (id)
- UK: —

### perseus.goo_process_queue_type
- PK: `goo_process_queue_type_pk` (id)
- UNIQUE CONSTRAINT: `uq__goo_proc__72e12f1b5581bc68` (name)

### perseus.goo_type
- PK: `goo_type_pk` (id)
- UNIQUE CONSTRAINT: `uq__goo_type__72a9f59b39237a9a` (left_id, right_id, scope_id)
- UNIQUE CONSTRAINT: `uq__goo_type__72e12f1b00551192` (name)

### perseus.goo_type_combine_component
- PK: `goo_type_combine_component_pk` (id)
- UNIQUE CONSTRAINT: `uq__goo_type__1a28c1a56fc0b158` (goo_type_combine_target_id, goo_type_id)

### perseus.goo_type_combine_target
- PK: `goo_type_combine_target_pk` (id)
- UK: —

### perseus.history
- PK: `history_pk` (id)
- UK: —

### perseus.history_type
- PK: `history_type_pk` (id)
- UNIQUE CONSTRAINT: `uq__history___72e12f1b19b8e995` (name)

### perseus.history_value
- PK: `history_value_pk` (id)
- UK: —

### perseus.m_downstream
- PK: `m_downstream_pk` (start_point, end_point, path)
- UK: —

### perseus.m_number
- PK: `perseus_m_number_pk_md5_hash` (md5_hash)
- UK: —

### perseus.m_upstream
- PK: `m_upstream_pk` (start_point, end_point, path)
- UK: —

### perseus.m_upstream_dirty_leaves
- PK: `perseus_m_upstream_dirty_leaves_pk_md5_hash` (md5_hash)
- UK: —

### perseus.manufacturer
- PK: `manufacturer_pk` (id)
- UNIQUE CONSTRAINT: `uq__manufact__106262313de82fb7` (name, location)

### perseus.material_inventory
- PK: `pk__material__3213e83f77f9310a` (id)
- UNIQUE CONSTRAINT: `uq__material__6bfe1d29c2c4ddab` (material_id)

### perseus.material_inventory_threshold
- PK: `pk__material__3213e83ff1f867f5` (id)
- UNIQUE CONSTRAINT: `uq_material_inventory_threshold_material_type_inventory_type` (material_type_id, inventory_type_id)

### perseus.material_inventory_threshold_notify_user
- PK: `pk_material_inventory_threshold_notify_user` (threshold_id, user_id)
- UK: —

### perseus.material_inventory_type
- PK: `pk__material__3213e83fbd077e43` (id)
- UNIQUE CONSTRAINT: `uq__material__72e12f1b3704ca3e` (name)

### perseus.material_qc
- PK: `pk__material__3213e83fe6b39cc1` (id)
- UK: —

### perseus.material_transition
- PK: `pk__material__78fcfd7e69fee97b` (material_id, transition_id)
- UK: —

### perseus.migration
- PK: `pk__migratio__3213e83f2405ca25` (id)
- UK: —

### perseus.permissions
- PK: `perseus_permissions_pk_md5_hash` (md5_hash)
- UK: —

### perseus.perseus_user
- PK: `perseus_user_pk` (id)
- UNIQUE CONSTRAINT: `uq__perseus___7838f2720519c6af` (login)
- UNIQUE CONSTRAINT: `uq__perseus___e72bc76707f6335a` (domain_id)

### perseus.person
- PK: `pk__person__3213e83f19aff6df` (id)
- UNIQUE CONSTRAINT: `uq_person_domain_id` (domain_id)

### perseus.poll
- PK: `poll_pk` (id)
- UNIQUE CONSTRAINT: `uq__poll__2edadb146383c8ba` (fatsmurf_reading_id, smurf_property_id)

### perseus.poll_history
- PK: `poll_history_pk` (id)
- UK: —

### perseus.prefix_incrementor
- PK: `prefix_incrementor_pk` (prefix)
- UK: —

### perseus.property
- PK: `property_pk` (id)
- UNIQUE CONSTRAINT: `uq__property__1fdbdaa62a4b4b5e` (name, unit_id)

### perseus.property_option
- PK: `property_option_pk` (id)
- UNIQUE CONSTRAINT: `uq__property__57d99bb95267570c` (property_id, label)
- UNIQUE CONSTRAINT: `uq__property__d7501ac15543c3b7` (property_id, value)

### perseus.recipe
- PK: `pk__recipe__3213e83f5d093d57` (id)
- UNIQUE CONSTRAINT: `uq__recipe__72e12f1b5fe5aa02` (name)
- UNIQUE CONSTRAINT: `uq__recipe__72e12f1b62c216ad` (name)

### perseus.recipe_part
- PK: `pk__recipe_p__3213e83f696f143c` (id)
- UK: —

### perseus.recipe_project_assignment
- PK: `perseus_recipe_project_assignment_pk_md5_hash` (md5_hash)
- UK: —

### perseus.robot_log
- PK: `robot_log_pk` (id)
- UK: —

### perseus.robot_log_container_sequence
- PK: `robot_log_container_sequence_pk` (id)
- UNIQUE CONSTRAINT: `uq__robot_lo__acca81e32e521557` (robot_log_id, container_id, sequence_type_id)

### perseus.robot_log_error
- PK: `robot_log_error_pk` (id)
- UK: —

### perseus.robot_log_read
- PK: `robot_log_read_pk` (id)
- UK: —

### perseus.robot_log_transfer
- PK: `robot_log_transfer_pk` (id)
- UK: —

### perseus.robot_log_type
- PK: `robot_log_type_pk` (id)
- UNIQUE CONSTRAINT: `uq__robot_lo__72e12f1b1956f871` (name)

### perseus.robot_run
- PK: `robot_run_pk` (id)
- UNIQUE INDEX: `uniq_run_name` (name)

### perseus.s_number
- PK: `perseus_s_number_pk_md5_hash` (md5_hash)
- UK: —

### perseus.saved_search
- PK: `saved_search_pk` (id)
- UNIQUE CONSTRAINT: `uq__saved_se__a00062956a30c649` (name, added_by)

### perseus.scraper
- PK: `pk__scraper__3214ec274c308081` (id)
- UK: —

### perseus.sequence_type
- PK: `sequence_type_pk` (id)
- UK: —

### perseus.smurf
- PK: `smurf_pk` (id)
- UNIQUE CONSTRAINT: `uq__smurf__72e12f1b300424b4` (name)

### perseus.smurf_goo_type
- PK: `smurf_goo_type_pk` (id)
- UNIQUE INDEX: `uniq_index` (smurf_id, goo_type_id, is_input)

### perseus.smurf_group
- PK: `smurf_group_pk` (id)
- UNIQUE CONSTRAINT: `uq__smurf_gr__72e12f1b1368499a` (name)

### perseus.smurf_group_member
- PK: `smurf_group_member_pk` (id)
- UNIQUE CONSTRAINT: `uq__smurf_gr__327439fa182cfeb7` (smurf_group_id, smurf_id)

### perseus.smurf_property
- PK: `smurf_property_pk` (id)
- UNIQUE CONSTRAINT: `uq__smurf_pr__92833c0b5be2a6f2` (property_id, smurf_id)

### perseus.submission
- PK: `pk__submissi__3213e83f71b57d70` (id)
- UK: —

### perseus.submission_entry
- PK: `pk__submissi__3213e83f767a328d` (id)
- UK: —

### perseus.tmp_messy_links
- PK: `perseus_tmp_messy_links_pk_md5_hash` (md5_hash)
- UK: —

### perseus.transition_material
- PK: `pk__transiti__a691e4b26dcf7a5f` (transition_id, material_id)
- UK: —

### perseus.unit
- PK: `unit_pk` (id)
- UNIQUE INDEX: `uix_unit_name` (name)

### perseus.workflow
- PK: `workflow_pk` (id)
- UNIQUE CONSTRAINT: `uq__workflow__72e12f1b00cbdb56` (name)

### perseus.workflow_attachment
- PK: `workflow_attachment_pk` (id)
- UK: —

### perseus.workflow_section
- PK: `workflow_section_pk` (id)
- UNIQUE CONSTRAINT: `uq__workflow__7533c67705909073` (workflow_id, starting_step_id)
- UNIQUE CONSTRAINT: `uq__workflow__d3897980086cfd1e` (workflow_id, name)
- UNIQUE INDEX: `uniq_starting_step` (starting_step_id)

### perseus.workflow_step
- PK: `workflow_step_pk` (id)
- UK: —

### perseus.workflow_step_type
- PK: `workflow_step_type_pk` (id)
- UNIQUE CONSTRAINT: `uq__workflow__72e12f1b0b20e345` (name)

## Apêndice B - Resumo de FKs por tabela filha

### perseus.coa
- `coa_fk_1`: (goo_type_id) -> perseus.goo_type (id) | ON UPDATE NO ACTION | ON DELETE NO ACTION

### perseus.coa_spec
- `coa_spec_fk_1`: (coa_id) -> perseus.coa (id) | ON UPDATE NO ACTION | ON DELETE NO ACTION
- `coa_spec_fk_2`: (property_id) -> perseus.property (id) | ON UPDATE NO ACTION | ON DELETE NO ACTION

### perseus.container
- `container_fk_1`: (container_type_id) -> perseus.container_type (id) | ON UPDATE NO ACTION | ON DELETE NO ACTION

### perseus.container_history
- `container_history_fk_1`: (history_id) -> perseus.history (id) | ON UPDATE NO ACTION | ON DELETE CASCADE
- `container_history_fk_2`: (container_id) -> perseus.container (id) | ON UPDATE NO ACTION | ON DELETE CASCADE

### perseus.container_type_position
- `container_type_position_fk_1`: (parent_container_type_id) -> perseus.container_type (id) | ON UPDATE NO ACTION | ON DELETE NO ACTION
- `container_type_position_fk_2`: (child_container_type_id) -> perseus.container_type (id) | ON UPDATE NO ACTION | ON DELETE NO ACTION

### perseus.external_goo_type
- `external_goo_type_fk_1`: (goo_type_id) -> perseus.goo_type (id) | ON UPDATE NO ACTION | ON DELETE NO ACTION
- `external_goo_type_fk_2`: (manufacturer_id) -> perseus.manufacturer (id) | ON UPDATE NO ACTION | ON DELETE NO ACTION

### perseus.fatsmurf
- `fk_fatsmurf_smurf_id`: (smurf_id) -> perseus.smurf (id) | ON UPDATE NO ACTION | ON DELETE NO ACTION
- `fk_fatsmurf_workflow_step`: (workflow_step_id) -> perseus.workflow_step (id) | ON UPDATE NO ACTION | ON DELETE SET NULL
- `fs_container_id_fk_1`: (container_id) -> perseus.container (id) | ON UPDATE NO ACTION | ON DELETE SET NULL
- `fs_organization_fk_1`: (organization_id) -> perseus.manufacturer (id) | ON UPDATE NO ACTION | ON DELETE NO ACTION

### perseus.fatsmurf_attachment
- `fatsmurf_attachment_fk_1`: (added_by) -> perseus.perseus_user (id) | ON UPDATE NO ACTION | ON DELETE NO ACTION
- `fatsmurf_attachment_fk_2`: (fatsmurf_id) -> perseus.fatsmurf (id) | ON UPDATE NO ACTION | ON DELETE CASCADE

### perseus.fatsmurf_comment
- `fatsmurf_comment_fk_1`: (added_by) -> perseus.perseus_user (id) | ON UPDATE NO ACTION | ON DELETE NO ACTION
- `fatsmurf_comment_fk_2`: (fatsmurf_id) -> perseus.fatsmurf (id) | ON UPDATE NO ACTION | ON DELETE CASCADE

### perseus.fatsmurf_history
- `fatsmurf_history_fk_1`: (history_id) -> perseus.history (id) | ON UPDATE NO ACTION | ON DELETE CASCADE
- `fatsmurf_history_fk_2`: (fatsmurf_id) -> perseus.fatsmurf (id) | ON UPDATE NO ACTION | ON DELETE CASCADE

### perseus.fatsmurf_reading
- `creator_fk_1`: (added_by) -> perseus.perseus_user (id) | ON UPDATE NO ACTION | ON DELETE NO ACTION
- `fatsmurf_reading_fk_1`: (fatsmurf_id) -> perseus.fatsmurf (id) | ON UPDATE NO ACTION | ON DELETE CASCADE

### perseus.feed_type
- `fk__feed_type__creat__5f28586b`: (added_by) -> perseus.perseus_user (id) | ON UPDATE NO ACTION | ON DELETE NO ACTION
- `fk__feed_type__updat__601c7ca4`: (updated_by_id) -> perseus.perseus_user (id) | ON UPDATE NO ACTION | ON DELETE NO ACTION

### perseus.field_map
- `combined_field_map_fk_1`: (field_map_block_id) -> perseus.field_map_block (id) | ON UPDATE NO ACTION | ON DELETE NO ACTION
- `combined_field_map_fk_2`: (field_map_type_id) -> perseus.field_map_type (id) | ON UPDATE NO ACTION | ON DELETE NO ACTION
- `field_map_field_map_set_fk_1`: (field_map_set_id) -> perseus.field_map_set (id) | ON UPDATE NO ACTION | ON DELETE NO ACTION

### perseus.field_map_display_type
- `combined_field_map_display_type_fk_1`: (field_map_id) -> perseus.field_map (id) | ON UPDATE NO ACTION | ON DELETE CASCADE
- `combined_field_map_display_type_fk_2`: (display_type_id) -> perseus.display_type (id) | ON UPDATE NO ACTION | ON DELETE CASCADE
- `combined_field_map_display_type_fk_3`: (display_layout_id) -> perseus.display_layout (id) | ON UPDATE NO ACTION | ON DELETE CASCADE

### perseus.field_map_display_type_user
- `field_map_display_type_user_fk_2`: (user_id) -> perseus.perseus_user (id) | ON UPDATE NO ACTION | ON DELETE CASCADE

### perseus.goo
- `container_id_fk_1`: (container_id) -> perseus.container (id) | ON UPDATE NO ACTION | ON DELETE SET NULL
- `fk_goo_recipe`: (recipe_id) -> perseus.recipe (id) | ON UPDATE NO ACTION | ON DELETE NO ACTION
- `fk_goo_recipe_part`: (recipe_part_id) -> perseus.recipe_part (id) | ON UPDATE NO ACTION | ON DELETE NO ACTION
- `fk_goo_workflow_step`: (workflow_step_id) -> perseus.workflow_step (id) | ON UPDATE NO ACTION | ON DELETE SET NULL
- `goo_fk_1`: (goo_type_id) -> perseus.goo_type (id) | ON UPDATE NO ACTION | ON DELETE NO ACTION
- `goo_fk_4`: (added_by) -> perseus.perseus_user (id) | ON UPDATE NO ACTION | ON DELETE NO ACTION
- `manufacturer_fk_1`: (manufacturer_id) -> perseus.manufacturer (id) | ON UPDATE NO ACTION | ON DELETE NO ACTION

### perseus.goo_attachment
- `goo_attachment_fk_1`: (added_by) -> perseus.perseus_user (id) | ON UPDATE NO ACTION | ON DELETE NO ACTION
- `goo_attachment_fk_2`: (goo_id) -> perseus.goo (id) | ON UPDATE NO ACTION | ON DELETE CASCADE
- `goo_attachment_fk_3`: (goo_attachment_type_id) -> perseus.goo_attachment_type (id) | ON UPDATE NO ACTION | ON DELETE NO ACTION

### perseus.goo_comment
- `goo_comment_fk_1`: (added_by) -> perseus.perseus_user (id) | ON UPDATE NO ACTION | ON DELETE NO ACTION
- `goo_comment_fk_2`: (goo_id) -> perseus.goo (id) | ON UPDATE NO ACTION | ON DELETE CASCADE

### perseus.goo_history
- `goo_history_fk_1`: (history_id) -> perseus.history (id) | ON UPDATE NO ACTION | ON DELETE CASCADE
- `goo_history_fk_2`: (goo_id) -> perseus.goo (id) | ON UPDATE NO ACTION | ON DELETE CASCADE

### perseus.goo_type_combine_component
- `goo_type_combine_component_fk_1`: (goo_type_id) -> perseus.goo_type (id) | ON UPDATE NO ACTION | ON DELETE NO ACTION
- `goo_type_combine_component_fk_2`: (goo_type_combine_target_id) -> perseus.goo_type_combine_target (id) | ON UPDATE NO ACTION | ON DELETE CASCADE

### perseus.goo_type_combine_target
- `goo_type_combine_target_fk_1`: (goo_type_id) -> perseus.goo_type (id) | ON UPDATE NO ACTION | ON DELETE NO ACTION

### perseus.history
- `history_fk_1`: (creator_id) -> perseus.perseus_user (id) | ON UPDATE NO ACTION | ON DELETE NO ACTION
- `history_fk_2`: (history_type_id) -> perseus.history_type (id) | ON UPDATE NO ACTION | ON DELETE NO ACTION

### perseus.history_value
- `history_value_fk_1`: (history_id) -> perseus.history (id) | ON UPDATE NO ACTION | ON DELETE CASCADE

### perseus.material_inventory
- `fk__material___alloc__1642b7d4`: (allocation_container_id) -> perseus.container (id) | ON UPDATE NO ACTION | ON DELETE NO ACTION
- `fk__material___creat__1a1348b8`: (created_by_id) -> perseus.perseus_user (id) | ON UPDATE NO ACTION | ON DELETE NO ACTION
- `fk__material___locat__191f247f`: (location_container_id) -> perseus.container (id) | ON UPDATE NO ACTION | ON DELETE NO ACTION
- `fk__material___mater__182b0046`: (material_id) -> perseus.goo (id) | ON UPDATE NO ACTION | ON DELETE NO ACTION
- `fk__material___recip__1736dc0d`: (recipe_id) -> perseus.recipe (id) | ON UPDATE NO ACTION | ON DELETE NO ACTION
- `fk__material___updat__1b076cf1`: (updated_by_id) -> perseus.perseus_user (id) | ON UPDATE NO ACTION | ON DELETE NO ACTION
- `fk_material_inventory_inventory_type_id`: (inventory_type_id) -> perseus.material_inventory_type (id) | ON UPDATE NO ACTION | ON DELETE NO ACTION

### perseus.material_inventory_threshold
- `fk_material_inventory_threshold_created_by`: (created_by_id) -> perseus.perseus_user (id) | ON UPDATE NO ACTION | ON DELETE NO ACTION
- `fk_material_inventory_threshold_inventory_type_id`: (inventory_type_id) -> perseus.material_inventory_type (id) | ON UPDATE NO ACTION | ON DELETE NO ACTION
- `fk_material_inventory_threshold_material_type`: (material_type_id) -> perseus.goo_type (id) | ON UPDATE NO ACTION | ON DELETE NO ACTION
- `fk_material_inventory_threshold_updated_by`: (updated_by_id) -> perseus.perseus_user (id) | ON UPDATE NO ACTION | ON DELETE NO ACTION

### perseus.material_inventory_threshold_notify_user
- `fk_mit_notify_user_threshold`: (threshold_id) -> perseus.material_inventory_threshold (id) | ON UPDATE NO ACTION | ON DELETE CASCADE
- `fk_mit_notify_user_user`: (user_id) -> perseus.perseus_user (id) | ON UPDATE NO ACTION | ON DELETE NO ACTION

### perseus.material_qc
- `fk__material___mater__5b988a00`: (material_id) -> perseus.goo (id) | ON UPDATE NO ACTION | ON DELETE NO ACTION

### perseus.material_transition
- `fk_material_transition_fatsmurf`: (transition_id) -> perseus.fatsmurf (uid) | ON UPDATE NO ACTION | ON DELETE CASCADE

### perseus.perseus_user
- `fk__perseus_u__manuf__5b3c942f`: (manufacturer_id) -> perseus.manufacturer (id) | ON UPDATE NO ACTION | ON DELETE NO ACTION
- `fk__perseus_u__manuf__5e1900da`: (manufacturer_id) -> perseus.manufacturer (id) | ON UPDATE NO ACTION | ON DELETE NO ACTION
- `fk__perseus_u__manuf__6001494c`: (manufacturer_id) -> perseus.manufacturer (id) | ON UPDATE NO ACTION | ON DELETE NO ACTION

### perseus.poll
- `poll_fatsmurf_reading_fk_1`: (fatsmurf_reading_id) -> perseus.fatsmurf_reading (id) | ON UPDATE NO ACTION | ON DELETE CASCADE
- `poll_smurf_property_fk_1`: (smurf_property_id) -> perseus.smurf_property (id) | ON UPDATE NO ACTION | ON DELETE NO ACTION

### perseus.poll_history
- `poll_history_fk_1`: (history_id) -> perseus.history (id) | ON UPDATE NO ACTION | ON DELETE CASCADE
- `poll_history_fk_2`: (poll_id) -> perseus.poll (id) | ON UPDATE NO ACTION | ON DELETE CASCADE

### perseus.property
- `property_fk_1`: (unit_id) -> perseus.unit (id) | ON UPDATE NO ACTION | ON DELETE NO ACTION

### perseus.property_option
- `property_option_fk_1`: (property_id) -> perseus.property (id) | ON UPDATE NO ACTION | ON DELETE NO ACTION

### perseus.recipe
- `fk__recipe__added_by__659e8358`: (added_by) -> perseus.perseus_user (id) | ON UPDATE NO ACTION | ON DELETE NO ACTION
- `fk__recipe__feed_typ__471bc4b0`: (feed_type_id) -> perseus.feed_type (id) | ON UPDATE NO ACTION | ON DELETE NO ACTION
- `fk__recipe__goo_type__6692a791`: (goo_type_id) -> perseus.goo_type (id) | ON UPDATE NO ACTION | ON DELETE NO ACTION
- `fk__recipe__workflow__64aa5f1f`: (workflow_id) -> perseus.workflow (id) | ON UPDATE NO ACTION | ON DELETE NO ACTION

### perseus.recipe_part
- `fk__recipe_pa__goo_t__6e33c959`: (goo_type_id) -> perseus.goo_type (id) | ON UPDATE NO ACTION | ON DELETE NO ACTION
- `fk__recipe_pa__part___083eb140`: (part_recipe_id) -> perseus.recipe (id) | ON UPDATE NO ACTION | ON DELETE NO ACTION
- `fk__recipe_pa__recip__6d3fa520`: (recipe_id) -> perseus.recipe (id) | ON UPDATE NO ACTION | ON DELETE NO ACTION
- `fk__recipe_pa__unit___6b575cae`: (unit_id) -> perseus.unit (id) | ON UPDATE NO ACTION | ON DELETE NO ACTION
- `fk__recipe_pa__workf__6c4b80e7`: (workflow_step_id) -> perseus.workflow_step (id) | ON UPDATE NO ACTION | ON DELETE NO ACTION

### perseus.recipe_project_assignment
- `fk__recipe_pr__recip__0d5f605d`: (recipe_id) -> perseus.recipe (id) | ON UPDATE NO ACTION | ON DELETE NO ACTION

### perseus.robot_log
- `fk__robot_log__robot__01bf6602`: (robot_log_type_id) -> perseus.robot_log_type (id) | ON UPDATE NO ACTION | ON DELETE NO ACTION
- `robot_log_fk_1`: (robot_run_id) -> perseus.robot_run (id) | ON UPDATE NO ACTION | ON DELETE NO ACTION

### perseus.robot_log_container_sequence
- `robot_log_container_sequence_fk_1`: (sequence_type_id) -> perseus.sequence_type (id) | ON UPDATE NO ACTION | ON DELETE CASCADE
- `robot_log_container_sequence_fk_2`: (container_id) -> perseus.container (id) | ON UPDATE NO ACTION | ON DELETE CASCADE
- `robot_log_container_sequence_fk_3`: (robot_log_id) -> perseus.robot_log (id) | ON UPDATE NO ACTION | ON DELETE CASCADE

### perseus.robot_log_error
- `robot_log_error_fk_1`: (robot_log_id) -> perseus.robot_log (id) | ON UPDATE NO ACTION | ON DELETE CASCADE

### perseus.robot_log_read
- `fk_robot_log_read_source_material_id`: (source_material_id) -> perseus.goo (id) | ON UPDATE NO ACTION | ON DELETE NO ACTION
- `robot_log_read_fk_1`: (robot_log_id) -> perseus.robot_log (id) | ON UPDATE NO ACTION | ON DELETE CASCADE
- `robot_log_read_fk_2`: (property_id) -> perseus.property (id) | ON UPDATE NO ACTION | ON DELETE CASCADE

### perseus.robot_log_transfer
- `fk_robot_log_transfer_destination_material_id`: (destination_material_id) -> perseus.goo (id) | ON UPDATE NO ACTION | ON DELETE NO ACTION
- `fk_robot_log_transfer_source_material_id`: (source_material_id) -> perseus.goo (id) | ON UPDATE NO ACTION | ON DELETE NO ACTION
- `robot_log_transfer_fk_1`: (robot_log_id) -> perseus.robot_log (id) | ON UPDATE NO ACTION | ON DELETE CASCADE

### perseus.robot_log_type
- `robot_log_type_fk_1`: (destination_container_type_id) -> perseus.container_type (id) | ON UPDATE NO ACTION | ON DELETE NO ACTION

### perseus.robot_run
- `robot_run_fk_2`: (robot_id) -> perseus.container (id) | ON UPDATE NO ACTION | ON DELETE NO ACTION

### perseus.saved_search
- `saved_search_fk_1`: (added_by) -> perseus.perseus_user (id) | ON UPDATE NO ACTION | ON DELETE NO ACTION

### perseus.smurf_goo_type
- `smurf_goo_type_fk_1`: (smurf_id) -> perseus.smurf (id) | ON UPDATE NO ACTION | ON DELETE NO ACTION
- `smurf_goo_type_fk_2`: (goo_type_id) -> perseus.goo_type (id) | ON UPDATE NO ACTION | ON DELETE CASCADE

### perseus.smurf_group
- `sg_creator_fk_1`: (added_by) -> perseus.perseus_user (id) | ON UPDATE NO ACTION | ON DELETE NO ACTION

### perseus.smurf_group_member
- `smurf_group_member_fk_1`: (smurf_id) -> perseus.smurf (id) | ON UPDATE NO ACTION | ON DELETE CASCADE
- `smurf_group_member_fk_2`: (smurf_group_id) -> perseus.smurf_group (id) | ON UPDATE NO ACTION | ON DELETE CASCADE

### perseus.smurf_property
- `smurf_property_fk_1`: (property_id) -> perseus.property (id) | ON UPDATE NO ACTION | ON DELETE CASCADE
- `smurf_property_fk_2`: (smurf_id) -> perseus.smurf (id) | ON UPDATE NO ACTION | ON DELETE CASCADE

### perseus.submission
- `fk__submissio__submi__739dc5e2`: (submitter_id) -> perseus.perseus_user (id) | ON UPDATE NO ACTION | ON DELETE NO ACTION

### perseus.submission_entry
- `fk__submissio__assay__78627aff`: (assay_type_id) -> perseus.smurf (id) | ON UPDATE NO ACTION | ON DELETE NO ACTION
- `fk__submissio__mater__79569f38`: (material_id) -> perseus.goo (id) | ON UPDATE NO ACTION | ON DELETE NO ACTION
- `fk__submissio__prepp__7d27301c`: (prepped_by_id) -> perseus.perseus_user (id) | ON UPDATE NO ACTION | ON DELETE NO ACTION
- `fk__submissio__submi__7c330be3`: (submission_id) -> perseus.submission (id) | ON UPDATE NO ACTION | ON DELETE NO ACTION

### perseus.transition_material
- `fk_transition_material_fatsmurf`: (transition_id) -> perseus.fatsmurf (uid) | ON UPDATE NO ACTION | ON DELETE CASCADE
- `fk_transition_material_goo`: (material_id) -> perseus.goo (uid) | ON UPDATE CASCADE | ON DELETE CASCADE

### perseus.workflow
- `workflow_creator_fk_1`: (added_by) -> perseus.perseus_user (id) | ON UPDATE NO ACTION | ON DELETE NO ACTION
- `workflow_manufacturer_id_fk_1`: (manufacturer_id) -> perseus.manufacturer (id) | ON UPDATE NO ACTION | ON DELETE NO ACTION

### perseus.workflow_attachment
- `workflow_attachment_fk_1`: (added_by) -> perseus.perseus_user (id) | ON UPDATE NO ACTION | ON DELETE NO ACTION
- `workflow_attachment_fk_2`: (workflow_id) -> perseus.workflow (id) | ON UPDATE NO ACTION | ON DELETE CASCADE

### perseus.workflow_section
- `workflow_section_fk_1`: (workflow_id) -> perseus.workflow (id) | ON UPDATE NO ACTION | ON DELETE CASCADE
- `workflow_step_start_fk_1`: (starting_step_id) -> perseus.workflow_step (id) | ON UPDATE NO ACTION | ON DELETE NO ACTION

### perseus.workflow_step
- `fk_workflow_step_goo_type`: (goo_type_id) -> perseus.goo_type (id) | ON UPDATE NO ACTION | ON DELETE NO ACTION
- `fk_workflow_step_property`: (property_id) -> perseus.property (id) | ON UPDATE NO ACTION | ON DELETE NO ACTION
- `fk_workflow_step_smurf`: (smurf_id) -> perseus.smurf (id) | ON UPDATE NO ACTION | ON DELETE NO ACTION
- `fk_workflow_step_workflow`: (scope_id) -> perseus.workflow (id) | ON UPDATE NO ACTION | ON DELETE CASCADE
- `workflow_step_unit_fk_1`: (goo_amount_unit_id) -> perseus.unit (id) | ON UPDATE NO ACTION | ON DELETE NO ACTION
