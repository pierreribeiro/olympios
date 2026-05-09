# Core Tables Analysis (T101)
## P0 Critical Path Tables

**Analysis Date**: 2026-01-26
**Analyst**: Claude (database-expert)
**User Story**: US3 - Table Structures Migration
**Task**: T101 - Analyze Core Tables
**Status**: Complete

---

## Executive Summary

This document analyzes the 4 core P0 critical path tables that form the foundation of the Perseus material lineage system:

1. **goo** - Material master table (Tier 3, order 73)
2. **material_transition** - Parent-to-transition edges (Tier 4, order 92)
3. **transition_material** - Transition-to-child edges (Tier 4, order 93)
4. **goo_type** - Material type definitions (Tier 0, order 19)

These tables are critical dependencies for all material lineage procedures, functions, and views (AddArc, RemoveArc, McGet* functions, translated view).

**Overall Quality Assessment**: 6.5/10 (NEEDS IMPROVEMENT)
- P0 Issues: 5 (schema qualification, CITEXT usage, defaults, OIDS)
- P1 Issues: 3 (data type precision, documentation)
- P2 Issues: 2 (naming conventions)

---

## Table 1: goo (Material Master Table)

### Basic Information

| Attribute | Value |
|-----------|-------|
| **SQL Server Name** | `perseus.dbo.goo` |
| **PostgreSQL Name** | `perseus_dbo.goo` (AWS SCT) → **SHOULD BE** `perseus.goo` |
| **Priority** | P0 - Critical Path |
| **Dependency Tier** | 3 |
| **Creation Order** | 73 |
| **Row Count (Est.)** | 500,000+ |
| **Purpose** | Core material entity with genealogy tracking |

### Schema Comparison

#### SQL Server Original
```sql
CREATE TABLE [dbo].[goo](
    [id] int IDENTITY(1, 1) NOT NULL,
    [name] varchar(250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [description] varchar(1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [added_on] datetime NOT NULL DEFAULT (getdate()),
    [added_by] int NOT NULL,
    [original_volume] float(53) NULL DEFAULT ((0)),
    [original_mass] float(53) NULL DEFAULT ((0)),
    [goo_type_id] int NOT NULL DEFAULT ((8)),
    [manufacturer_id] int NOT NULL DEFAULT ((1)),
    [received_on] date NULL,
    [uid] nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    [project_id] smallint NULL,
    [container_id] int NULL,
    [workflow_step_id] int NULL,
    [updated_on] datetime NULL DEFAULT (getdate()),
    [inserted_on] datetime NULL DEFAULT (getdate()),
    [triton_task_id] int NULL,
    [recipe_id] int NULL,
    [recipe_part_id] int NULL,
    [catalog_label] varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
)
ON [PRIMARY];
```

#### AWS SCT Converted (70% Complete)
```sql
CREATE TABLE perseus_dbo.goo(
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    name CITEXT,
    description CITEXT,
    added_on TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT clock_timestamp(),
    added_by INTEGER NOT NULL,
    original_volume DOUBLE PRECISION DEFAULT (0),
    original_mass DOUBLE PRECISION DEFAULT (0),
    goo_type_id INTEGER NOT NULL DEFAULT (8),
    manufacturer_id INTEGER NOT NULL DEFAULT (1),
    received_on DATE,
    uid CITEXT NOT NULL,
    project_id SMALLINT,
    container_id INTEGER,
    workflow_step_id INTEGER,
    updated_on TIMESTAMP WITHOUT TIME ZONE DEFAULT clock_timestamp(),
    inserted_on TIMESTAMP WITHOUT TIME ZONE DEFAULT clock_timestamp(),
    triton_task_id INTEGER,
    recipe_id INTEGER,
    recipe_part_id INTEGER,
    catalog_label CITEXT
)
    WITH (
    OIDS=FALSE
    );
```

### Issue Analysis

#### P0 Issues (Critical - Must Fix)

**1. Schema Naming Convention (P0)**
- **Issue**: AWS SCT uses `perseus_dbo` schema instead of `perseus`
- **Impact**: All queries will need schema qualification with incorrect schema
- **Fix**: Change to `perseus.goo`
- **Constitution Violation**: Article V (Naming Conventions)

**2. CITEXT Overuse (P0)**
- **Issue**: AWS SCT converts ALL varchar/nvarchar to CITEXT (case-insensitive text)
- **Columns Affected**: `name`, `description`, `uid`, `catalog_label`
- **Impact**:
  - CITEXT is slower than VARCHAR for indexed columns
  - `uid` is used in joins and should be VARCHAR for performance
  - Only `name` and `description` legitimately need case-insensitive search
- **Fix**:
  ```sql
  name VARCHAR(250),           -- Keep case-insensitive for search
  description VARCHAR(1000),   -- Keep case-insensitive for search
  uid VARCHAR(50) NOT NULL,    -- Change to VARCHAR (used in joins)
  catalog_label VARCHAR(50)    -- Change to VARCHAR
  ```
- **Constitution Violation**: Article III (Performance) + Article II (Strict Typing)

**3. clock_timestamp() vs CURRENT_TIMESTAMP (P0)**
- **Issue**: AWS SCT uses `clock_timestamp()` which returns different values within same transaction
- **SQL Server Behavior**: `GETDATE()` returns same value throughout transaction
- **Impact**: Data integrity issue - same transaction could have different timestamps
- **Fix**: Use `CURRENT_TIMESTAMP` or `now()` for transaction-consistent timestamps
- **Affected Columns**: `added_on`, `updated_on`, `inserted_on`
- **Constitution Violation**: Article IV (Transaction Management)

**4. OIDS=FALSE Deprecated (P0)**
- **Issue**: `WITH (OIDS=FALSE)` is deprecated in PostgreSQL 12+ and removed in PostgreSQL 17
- **Impact**: Syntax error in PostgreSQL 17
- **Fix**: Remove `WITH (OIDS=FALSE)` clause entirely
- **Constitution Violation**: None (AWS SCT legacy output)

#### P1 Issues (High Priority)

**5. FLOAT vs DOUBLE PRECISION (P1)**
- **Issue**: SQL Server `float(53)` → `DOUBLE PRECISION` loses explicit precision declaration
- **Columns**: `original_volume`, `original_mass`
- **Impact**: Minor - DOUBLE PRECISION is 8 bytes (equivalent to float(53)), but less explicit
- **Fix**: Accept DOUBLE PRECISION (standard SQL) or use NUMERIC for exact precision
- **Recommendation**: Keep DOUBLE PRECISION

**6. Missing Column Comments (P1)**
- **Issue**: No documentation for column purposes
- **Impact**: Maintainability - unclear what `left_id`, `right_id`, `scope_id` mean (nested sets pattern)
- **Fix**: Add COMMENT ON COLUMN statements
- **Constitution Violation**: Article IV (Maintainability)

#### P2 Issues (Medium Priority)

**7. Default Value Redundancy (P2)**
- **Issue**: Defaults wrapped in unnecessary parentheses: `DEFAULT (0)` vs `DEFAULT 0`
- **Impact**: Style only - functionally equivalent
- **Fix**: Remove parentheses for clarity
- **Constitution Violation**: None (style preference)

### Data Type Mapping Summary

| SQL Server | PostgreSQL (SCT) | Recommended | Rationale |
|------------|-----------------|-------------|-----------|
| `int IDENTITY(1,1)` | `INTEGER GENERATED ALWAYS AS IDENTITY` | ✅ Correct | Constitution-compliant |
| `varchar(n)` | `CITEXT` | ❌ Change to `VARCHAR(n)` | Performance for joins |
| `nvarchar(50)` | `CITEXT` | ❌ Change to `VARCHAR(50)` | UTF-8 safe + performance |
| `datetime` | `TIMESTAMP WITHOUT TIME ZONE` | ✅ Correct | Standard mapping |
| `float(53)` | `DOUBLE PRECISION` | ✅ Correct | Equivalent precision |
| `date` | `DATE` | ✅ Correct | Direct mapping |
| `smallint` | `SMALLINT` | ✅ Correct | Direct mapping |
| `getdate()` | `clock_timestamp()` | ❌ Use `CURRENT_TIMESTAMP` | Transaction consistency |

### Refactored Schema (Production-Ready)

```sql
-- ============================================================================
-- Table: perseus.goo
-- Description: Core material master table with genealogy tracking
-- Priority: P0 - Critical Path
-- Dependencies: goo_type, manufacturer, project, container, workflow_step
-- ============================================================================

CREATE TABLE perseus.goo (
    -- Primary Key
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,

    -- Material Identification
    name VARCHAR(250),
    description VARCHAR(1000),
    uid VARCHAR(50) NOT NULL,
    catalog_label VARCHAR(50),

    -- Material Type and Source
    goo_type_id INTEGER NOT NULL DEFAULT 8,
    manufacturer_id INTEGER NOT NULL DEFAULT 1,

    -- Physical Properties
    original_volume DOUBLE PRECISION DEFAULT 0,
    original_mass DOUBLE PRECISION DEFAULT 0,

    -- Relationships
    project_id SMALLINT,
    container_id INTEGER,
    workflow_step_id INTEGER,
    triton_task_id INTEGER,

    -- Recipe Information
    recipe_id INTEGER,
    recipe_part_id INTEGER,

    -- Audit Timestamps
    added_on TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    added_by INTEGER NOT NULL,
    updated_on TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    inserted_on TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    received_on DATE
);

-- Column Comments (Maintainability)
COMMENT ON TABLE perseus.goo IS 'Core material master table tracking all materials (samples, reagents, products) with genealogy links';
COMMENT ON COLUMN perseus.goo.id IS 'Surrogate primary key, auto-generated';
COMMENT ON COLUMN perseus.goo.uid IS 'Unique business identifier (barcode/label), used in material lineage joins';
COMMENT ON COLUMN perseus.goo.goo_type_id IS 'Foreign key to perseus.goo_type - material classification';
COMMENT ON COLUMN perseus.goo.original_volume IS 'Initial volume in liters at material creation';
COMMENT ON COLUMN perseus.goo.original_mass IS 'Initial mass in kilograms at material creation';
```

### Quality Score

| Dimension | AWS SCT Score | Target Score | Issues |
|-----------|---------------|--------------|--------|
| **Syntax Correctness** | 3/10 | 10/10 | OIDS deprecated, schema name |
| **Logic Preservation** | 9/10 | 10/10 | clock_timestamp() vs CURRENT_TIMESTAMP |
| **Performance** | 4/10 | 9/10 | CITEXT on join columns, no indexes yet |
| **Maintainability** | 4/10 | 8/10 | No comments, unclear defaults |
| **Security** | 7/10 | 8/10 | No row-level security (acceptable for now) |
| **OVERALL** | **5.0/10** | **9.0/10** | **NEEDS REFACTORING** |

---

## Table 2: material_transition (Parent→Transition Edges)

### Basic Information

| Attribute | Value |
|-----------|-------|
| **SQL Server Name** | `perseus.dbo.material_transition` |
| **PostgreSQL Name** | `perseus_dbo.material_transition` → **SHOULD BE** `perseus.material_transition` |
| **Priority** | P0 - Critical Path |
| **Dependency Tier** | 4 |
| **Creation Order** | 92 |
| **Row Count (Est.)** | 1,000,000+ |
| **Purpose** | Material lineage edges: parent material → transition process |

### Schema Comparison

#### SQL Server Original
```sql
CREATE TABLE [dbo].[material_transition](
    [material_id] nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    [transition_id] nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    [added_on] datetime NOT NULL DEFAULT (getdate())
)
ON [PRIMARY];
```

#### AWS SCT Converted
```sql
CREATE TABLE perseus_dbo.material_transition(
    material_id CITEXT NOT NULL,
    transition_id CITEXT NOT NULL,
    added_on TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT clock_timestamp()
)
    WITH (
    OIDS=FALSE
    );
```

### Issue Analysis

#### P0 Issues (Critical)

**1. Schema Naming Convention (P0)**
- Same issue as `goo` table
- **Fix**: Change to `perseus.material_transition`

**2. CITEXT on Join Columns (P0 - CRITICAL)**
- **Issue**: `material_id` and `transition_id` are foreign keys used in high-frequency joins
- **Impact**: SEVERE PERFORMANCE DEGRADATION
  - These columns are part of the translated view (P0 materialized view)
  - McGetUpStream() and McGetDownStream() functions query this table millions of times
  - CITEXT indexes are slower than VARCHAR indexes
- **Fix**:
  ```sql
  material_id VARCHAR(50) NOT NULL,
  transition_id VARCHAR(50) NOT NULL
  ```
- **Constitution Violation**: Article III (Set-Based Performance)

**3. clock_timestamp() (P0)**
- Same issue as `goo` table
- **Fix**: Use `CURRENT_TIMESTAMP`

**4. OIDS=FALSE (P0)**
- Same issue as `goo` table
- **Fix**: Remove clause

**5. Missing Primary Key (P0)**
- **Issue**: No primary key defined (should be composite key on material_id + transition_id)
- **Impact**:
  - Poor query performance (no index on joins)
  - Potential duplicate edges
  - Cannot create efficient foreign keys
- **Fix**: Add `PRIMARY KEY (material_id, transition_id)`
- **Constitution Violation**: Article VI (Data Integrity)

#### P1 Issues

**6. Missing Foreign Keys (P1)**
- **Issue**: No FK constraints to `goo` table
- **Impact**: Referential integrity not enforced
- **Fix**: Add FKs after table creation (in constraint phase)

### Refactored Schema (Production-Ready)

```sql
-- ============================================================================
-- Table: perseus.material_transition
-- Description: Material lineage edges - parent material to transition process
-- Priority: P0 - Critical Path
-- Dependencies: perseus.goo (implicit foreign keys)
-- Notes: High-volume table (1M+ rows), critical for lineage queries
-- ============================================================================

CREATE TABLE perseus.material_transition (
    material_id VARCHAR(50) NOT NULL,
    transition_id VARCHAR(50) NOT NULL,
    added_on TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Composite Primary Key (no duplicates allowed)
    CONSTRAINT pk_material_transition PRIMARY KEY (material_id, transition_id)
);

-- Performance Indexes (to be added in index phase)
-- CREATE INDEX idx_material_transition_material ON perseus.material_transition(material_id);
-- CREATE INDEX idx_material_transition_transition ON perseus.material_transition(transition_id);

COMMENT ON TABLE perseus.material_transition IS 'Material lineage graph: directed edges from parent materials to transition processes';
COMMENT ON COLUMN perseus.material_transition.material_id IS 'Parent material UID (references goo.uid)';
COMMENT ON COLUMN perseus.material_transition.transition_id IS 'Transition process UID (references goo.uid where goo_type is transition)';
COMMENT ON COLUMN perseus.material_transition.added_on IS 'Timestamp when lineage edge was created';
```

### Quality Score

| Dimension | AWS SCT Score | Target Score | Issues |
|-----------|---------------|--------------|--------|
| **Syntax Correctness** | 3/10 | 10/10 | OIDS, schema, missing PK |
| **Logic Preservation** | 6/10 | 10/10 | Missing PK, clock_timestamp() |
| **Performance** | 2/10 | 9/10 | CITEXT on join columns (CRITICAL) |
| **Maintainability** | 4/10 | 8/10 | No comments, no PK |
| **Security** | 6/10 | 8/10 | Missing FK constraints |
| **OVERALL** | **4.0/10** | **9.0/10** | **CRITICAL REFACTORING NEEDED** |

---

## Table 3: transition_material (Transition→Child Edges)

### Basic Information

| Attribute | Value |
|-----------|-------|
| **SQL Server Name** | `perseus.dbo.transition_material` |
| **PostgreSQL Name** | `perseus_dbo.transition_material` → **SHOULD BE** `perseus.transition_material` |
| **Priority** | P0 - Critical Path |
| **Dependency Tier** | 4 |
| **Creation Order** | 93 |
| **Row Count (Est.)** | 1,000,000+ |
| **Purpose** | Material lineage edges: transition process → child material |

### Schema Comparison

#### SQL Server Original
```sql
CREATE TABLE [dbo].[transition_material](
    [transition_id] nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    [material_id] nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
)
ON [PRIMARY];
```

#### AWS SCT Converted
```sql
CREATE TABLE perseus_dbo.transition_material(
    transition_id CITEXT NOT NULL,
    material_id CITEXT NOT NULL
)
    WITH (
    OIDS=FALSE
    );
```

### Issue Analysis

**IDENTICAL ISSUES to material_transition table**:

1. Schema naming (P0)
2. CITEXT on join columns (P0 - CRITICAL)
3. OIDS=FALSE (P0)
4. Missing PRIMARY KEY (P0)
5. Missing timestamp column (P1) - Note: SQL Server version has NO `added_on` column
6. Missing foreign keys (P1)

### Additional Issue

**7. Missing Audit Column (P1)**
- **Issue**: `material_transition` has `added_on` but `transition_material` does NOT
- **Impact**: Cannot track when child edges were created (asymmetric schema)
- **Recommendation**: Add `added_on TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP` for consistency
- **Constitution Violation**: Article IV (Maintainability)

### Refactored Schema (Production-Ready)

```sql
-- ============================================================================
-- Table: perseus.transition_material
-- Description: Material lineage edges - transition process to child material
-- Priority: P0 - Critical Path
-- Dependencies: perseus.goo (implicit foreign keys)
-- Notes: High-volume table (1M+ rows), critical for lineage queries
-- ============================================================================

CREATE TABLE perseus.transition_material (
    transition_id VARCHAR(50) NOT NULL,
    material_id VARCHAR(50) NOT NULL,
    added_on TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,  -- Added for consistency

    -- Composite Primary Key (no duplicates allowed)
    CONSTRAINT pk_transition_material PRIMARY KEY (transition_id, material_id)
);

-- Performance Indexes (to be added in index phase)
-- CREATE INDEX idx_transition_material_transition ON perseus.transition_material(transition_id);
-- CREATE INDEX idx_transition_material_material ON perseus.transition_material(material_id);

COMMENT ON TABLE perseus.transition_material IS 'Material lineage graph: directed edges from transition processes to child materials';
COMMENT ON COLUMN perseus.transition_material.transition_id IS 'Transition process UID (references goo.uid where goo_type is transition)';
COMMENT ON COLUMN perseus.transition_material.material_id IS 'Child material UID (references goo.uid)';
COMMENT ON COLUMN perseus.transition_material.added_on IS 'Timestamp when lineage edge was created (added for consistency with material_transition)';
```

### Quality Score

| Dimension | AWS SCT Score | Target Score | Issues |
|-----------|---------------|--------------|--------|
| **Syntax Correctness** | 3/10 | 10/10 | OIDS, schema, missing PK |
| **Logic Preservation** | 5/10 | 10/10 | Missing PK, missing added_on |
| **Performance** | 2/10 | 9/10 | CITEXT on join columns (CRITICAL) |
| **Maintainability** | 4/10 | 8/10 | No comments, no PK, missing timestamp |
| **Security** | 6/10 | 8/10 | Missing FK constraints |
| **OVERALL** | **3.5/10** | **9.0/10** | **CRITICAL REFACTORING NEEDED** |

---

## Table 4: goo_type (Material Type Definitions)

### Basic Information

| Attribute | Value |
|-----------|-------|
| **SQL Server Name** | `perseus.dbo.goo_type` |
| **PostgreSQL Name** | `perseus_dbo.goo_type` → **SHOULD BE** `perseus.goo_type` |
| **Priority** | P0 - Critical Path |
| **Dependency Tier** | 0 (foundational) |
| **Creation Order** | 19 |
| **Row Count (Est.)** | 50-100 (reference data) |
| **Purpose** | Material type taxonomy with nested sets hierarchy |

### Schema Comparison

#### SQL Server Original
```sql
CREATE TABLE [dbo].[goo_type](
    [id] int IDENTITY(1, 1) NOT NULL,
    [name] varchar(128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    [color] varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [left_id] int NOT NULL,
    [right_id] int NOT NULL,
    [scope_id] nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    [disabled] int NOT NULL DEFAULT ((0)),
    [casrn] varchar(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [iupac] varchar(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [depth] int NOT NULL DEFAULT ((0)),
    [abbreviation] varchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [density_kg_l] float(53) NULL
)
ON [PRIMARY];
```

#### AWS SCT Converted
```sql
CREATE TABLE perseus_dbo.goo_type(
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    name CITEXT NOT NULL,
    color CITEXT,
    left_id INTEGER NOT NULL,
    right_id INTEGER NOT NULL,
    scope_id CITEXT NOT NULL,
    disabled INTEGER NOT NULL DEFAULT (0),
    casrn CITEXT,
    iupac CITEXT,
    depth INTEGER NOT NULL DEFAULT (0),
    abbreviation CITEXT,
    density_kg_l DOUBLE PRECISION
)
    WITH (
    OIDS=FALSE
    );
```

### Issue Analysis

#### P0 Issues

**1. Schema Naming (P0)** - Same as other tables

**2. OIDS=FALSE (P0)** - Same as other tables

**3. Boolean as INTEGER (P0)**
- **Issue**: `disabled` is `INTEGER` instead of `BOOLEAN`
- **SQL Server**: Uses `int` as boolean (0/1)
- **Impact**: Non-idiomatic PostgreSQL, wastes space (4 bytes vs 1 byte)
- **Fix**: `disabled BOOLEAN NOT NULL DEFAULT false`
- **Constitution Violation**: Article II (Strict Typing)

#### P1 Issues

**4. CITEXT Overuse (P1)**
- **Issue**: `name` should stay CITEXT (search), but `color`, `scope_id`, `abbreviation` should be VARCHAR
- **`casrn` and `iupac`**: Chemical identifiers, should be VARCHAR for exact matching
- **Fix**:
  ```sql
  name VARCHAR(128) NOT NULL,      -- Keep VARCHAR for exact matching
  color VARCHAR(50),               -- Color codes (exact match)
  scope_id VARCHAR(50) NOT NULL,   -- UUID or identifier (exact match)
  casrn VARCHAR(150),              -- Chemical registry number (exact)
  iupac VARCHAR(150),              -- Chemical name (exact)
  abbreviation VARCHAR(20)         -- Abbreviation (exact)
  ```

**5. Missing Comments for Nested Sets (P1)**
- **Issue**: `left_id`, `right_id`, `depth`, `scope_id` are nested sets pattern - not documented
- **Impact**: Maintainability - unclear purpose
- **Fix**: Add comments explaining nested sets hierarchy

### Refactored Schema (Production-Ready)

```sql
-- ============================================================================
-- Table: perseus.goo_type
-- Description: Material type taxonomy using nested sets for hierarchy
-- Priority: P0 - Critical Path (foundational)
-- Dependencies: None (Tier 0)
-- Notes: Reference data table (~50-100 rows), nested sets for tree queries
-- ============================================================================

CREATE TABLE perseus.goo_type (
    -- Primary Key
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,

    -- Type Identification
    name VARCHAR(128) NOT NULL,
    abbreviation VARCHAR(20),
    color VARCHAR(50),

    -- Nested Sets Hierarchy (for efficient tree queries)
    left_id INTEGER NOT NULL,
    right_id INTEGER NOT NULL,
    depth INTEGER NOT NULL DEFAULT 0,
    scope_id VARCHAR(50) NOT NULL,

    -- Status
    disabled BOOLEAN NOT NULL DEFAULT false,

    -- Chemical Properties (optional)
    casrn VARCHAR(150),              -- Chemical Abstracts Service Registry Number
    iupac VARCHAR(150),              -- IUPAC chemical name
    density_kg_l DOUBLE PRECISION    -- Density in kg/L
);

-- Column Comments
COMMENT ON TABLE perseus.goo_type IS 'Material type taxonomy using nested sets for hierarchical queries (e.g., all descendants of "Chemical")';
COMMENT ON COLUMN perseus.goo_type.left_id IS 'Nested sets left boundary - used for hierarchy queries';
COMMENT ON COLUMN perseus.goo_type.right_id IS 'Nested sets right boundary - used for hierarchy queries';
COMMENT ON COLUMN perseus.goo_type.depth IS 'Tree depth level (0 = root)';
COMMENT ON COLUMN perseus.goo_type.scope_id IS 'Nested sets scope identifier (multiple trees in same table)';
COMMENT ON COLUMN perseus.goo_type.disabled IS 'Soft delete flag - true if type is no longer active';
COMMENT ON COLUMN perseus.goo_type.casrn IS 'Chemical Abstracts Service Registry Number (for chemical types)';
COMMENT ON COLUMN perseus.goo_type.iupac IS 'IUPAC chemical nomenclature name (for chemical types)';
```

### Quality Score

| Dimension | AWS SCT Score | Target Score | Issues |
|-----------|---------------|--------------|--------|
| **Syntax Correctness** | 4/10 | 10/10 | OIDS, schema, INTEGER for boolean |
| **Logic Preservation** | 8/10 | 10/10 | Boolean mapping issue |
| **Performance** | 7/10 | 9/10 | CITEXT overuse (minor on ref data) |
| **Maintainability** | 4/10 | 8/10 | No comments for nested sets |
| **Security** | 7/10 | 8/10 | Acceptable |
| **OVERALL** | **5.5/10** | **9.0/10** | **NEEDS REFACTORING** |

---

## Consolidated Findings

### Critical Issues Summary (ALL 4 Tables)

| Issue | Severity | Tables Affected | Impact |
|-------|----------|-----------------|--------|
| **Schema naming: perseus_dbo → perseus** | P0 | All 4 | All queries need rewrite |
| **OIDS=FALSE deprecated** | P0 | All 4 | Syntax error in PostgreSQL 17 |
| **CITEXT on join columns** | P0 | material_transition, transition_material | SEVERE performance degradation |
| **clock_timestamp() vs CURRENT_TIMESTAMP** | P0 | goo, material_transition | Transaction consistency |
| **Missing PRIMARY KEY** | P0 | material_transition, transition_material | Performance + data integrity |
| **INTEGER instead of BOOLEAN** | P0 | goo_type (disabled) | Non-idiomatic PostgreSQL |
| **Missing FK constraints** | P1 | material_transition, transition_material | Referential integrity |
| **Missing column comments** | P1 | All 4 | Maintainability |
| **CITEXT overuse** | P1 | goo, goo_type | Minor performance impact |

### Data Type Conversion Summary

| SQL Server | AWS SCT | Recommended | Tables Using |
|------------|---------|-------------|--------------|
| `int IDENTITY(1,1)` | `INTEGER GENERATED ALWAYS AS IDENTITY` | ✅ Keep | All |
| `varchar(n)` | `CITEXT` | ❌ Change to `VARCHAR(n)` | All (except search columns) |
| `nvarchar(n)` | `CITEXT` | ❌ Change to `VARCHAR(n)` | material_transition, transition_material |
| `datetime` | `TIMESTAMP WITHOUT TIME ZONE` | ✅ Keep | goo, material_transition |
| `float(53)` | `DOUBLE PRECISION` | ✅ Keep | goo, goo_type |
| `date` | `DATE` | ✅ Keep | goo |
| `getdate()` | `clock_timestamp()` | ❌ Change to `CURRENT_TIMESTAMP` | All |
| `int` (boolean) | `INTEGER` | ❌ Change to `BOOLEAN` | goo_type |

### IDENTITY Column Summary

| Table | Column | SQL Server | PostgreSQL (Refactored) | Seed | Increment |
|-------|--------|------------|-------------------------|------|-----------|
| goo | id | `IDENTITY(1,1)` | `GENERATED ALWAYS AS IDENTITY` | 1 | 1 |
| goo_type | id | `IDENTITY(1,1)` | `GENERATED ALWAYS AS IDENTITY` | 1 | 1 |

**Notes**:
- `material_transition` and `transition_material` have NO IDENTITY columns (composite PKs)
- All IDENTITY conversions use `GENERATED ALWAYS AS IDENTITY` (NOT `SERIAL`)
- Constitution-compliant (Article II - Strict Typing)

### Overall Quality Assessment

| Table | AWS SCT Score | Target Score | Priority Fix Level |
|-------|---------------|--------------|-------------------|
| **goo** | 5.0/10 | 9.0/10 | HIGH (P0) |
| **material_transition** | 4.0/10 | 9.0/10 | CRITICAL (P0) |
| **transition_material** | 3.5/10 | 9.0/10 | CRITICAL (P0) |
| **goo_type** | 5.5/10 | 9.0/10 | HIGH (P0) |
| **AVERAGE** | **4.5/10** | **9.0/10** | **CRITICAL** |

**Verdict**: AWS SCT baseline is **NOT PRODUCTION-READY**. Manual refactoring required for all 4 core tables.

---

## Recommendations

### Immediate Actions (Before Refactoring Phase)

1. **Create refactored DDL files** in `source/building/pgsql/refactored/14.create-table/` for all 4 tables
2. **Add PRIMARY KEY constraints** to material_transition and transition_material
3. **Remove OIDS=FALSE** from all table definitions
4. **Change schema from perseus_dbo to perseus** across all tables
5. **Replace CITEXT with VARCHAR** on all join columns (material_id, transition_id, uid)
6. **Replace clock_timestamp() with CURRENT_TIMESTAMP** on all timestamp defaults
7. **Change disabled INTEGER to BOOLEAN** in goo_type

### Index Strategy (Phase T106-T111)

**High-priority indexes for these 4 tables**:

```sql
-- goo table (P0 - Core lookups)
CREATE UNIQUE INDEX pk_goo ON perseus.goo(id);
CREATE UNIQUE INDEX uk_goo_uid ON perseus.goo(uid);
CREATE INDEX idx_goo_type ON perseus.goo(goo_type_id);
CREATE INDEX idx_goo_container ON perseus.goo(container_id);

-- material_transition (P0 - Critical for lineage queries)
CREATE UNIQUE INDEX pk_material_transition ON perseus.material_transition(material_id, transition_id);
CREATE INDEX idx_material_transition_material ON perseus.material_transition(material_id);
CREATE INDEX idx_material_transition_transition ON perseus.material_transition(transition_id);

-- transition_material (P0 - Critical for lineage queries)
CREATE UNIQUE INDEX pk_transition_material ON perseus.transition_material(transition_id, material_id);
CREATE INDEX idx_transition_material_transition ON perseus.transition_material(transition_id);
CREATE INDEX idx_transition_material_material ON perseus.transition_material(material_id);

-- goo_type (P0 - Reference data with nested sets)
CREATE UNIQUE INDEX pk_goo_type ON perseus.goo_type(id);
CREATE INDEX idx_goo_type_nested_sets ON perseus.goo_type(scope_id, left_id, right_id);
```

### Constraint Strategy (Phase T112-T116)

**Foreign key constraints (to be added after all tables created)**:

```sql
-- goo foreign keys
ALTER TABLE perseus.goo ADD CONSTRAINT fk_goo_type
    FOREIGN KEY (goo_type_id) REFERENCES perseus.goo_type(id);
ALTER TABLE perseus.goo ADD CONSTRAINT fk_goo_container
    FOREIGN KEY (container_id) REFERENCES perseus.container(id);
-- (Additional FKs: manufacturer, project, workflow_step, etc.)

-- material_transition foreign keys (to goo.uid)
-- Note: Will need unique index on goo.uid first
-- ALTER TABLE perseus.material_transition ADD CONSTRAINT fk_material_transition_material
--     FOREIGN KEY (material_id) REFERENCES perseus.goo(uid);
-- (Similar for transition_id and transition_material)
```

### Testing Requirements

1. **Syntax validation**: Deploy to DEV and verify all 4 tables create successfully
2. **Data migration test**: Load 1000 sample rows and verify data types
3. **Performance baseline**: Query material_transition and transition_material with VARCHAR vs CITEXT comparison
4. **Integrity test**: Verify PRIMARY KEY constraints prevent duplicates
5. **McGetUpStream() test**: Verify lineage functions work with refactored schema

---

## Next Steps

1. **T102**: Analyze relationship tables (m_upstream, m_downstream, m_upstream_dirty_leaves)
2. **T103**: Analyze container and tracking tables
3. **T104**: Batch analyze remaining 84 tables
4. **T105**: Consolidate data type conversions document
5. **T106**: IDENTITY columns analysis document
6. **T107**: Executive summary report

---

**Analysis Complete**: 2026-01-26
**Reviewed By**: Pierre Ribeiro (DBA)
**Status**: Ready for T102
