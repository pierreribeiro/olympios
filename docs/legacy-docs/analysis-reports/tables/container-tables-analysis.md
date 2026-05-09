# Container and Tracking Tables Analysis (T103)
## Physical Container Management System

**Analysis Date**: 2026-01-26
**Analyst**: Claude (database-expert)
**User Story**: US3 - Table Structures Migration
**Task**: T103 - Analyze Container and Tracking Tables
**Status**: Complete

---

## Executive Summary

This document analyzes the 4 container management tables that track physical containers, their types, hierarchies, and positions:

1. **container** - Physical container instances (Tier 0, order 16)
2. **container_type** - Container type definitions (Tier 0, order 18)
3. **container_history** - Container state change history (order 70)
4. **container_type_position** - Container hierarchy positions (order 71)

These tables support the physical inventory management system, tracking:
- Plates, tubes, wells, racks, freezers
- Parent-child container hierarchies (e.g., well → plate → rack → freezer)
- Nested sets for efficient hierarchy queries
- Positional layouts (X/Y coordinates for robotic systems)

**Overall Quality Assessment**: 5.5/10 (NEEDS IMPROVEMENT)
- P0 Issues: 5 (schema naming, OIDS, CITEXT overuse, NEWID() function, missing PKs)
- P1 Issues: 4 (boolean as INTEGER, missing FKs, coordinate data types)
- P2 Issues: 2 (missing comments, nested sets documentation)

---

## Table 1: container (Physical Container Instances)

### Basic Information

| Attribute | Value |
|-----------|-------|
| **SQL Server Name** | `perseus.dbo.container` |
| **PostgreSQL Name** | `perseus_dbo.container` → **SHOULD BE** `perseus.container` |
| **Priority** | P1 - High Priority |
| **Dependency Tier** | 0 (references container_type) |
| **Creation Order** | 16 |
| **Row Count (Est.)** | 50,000-100,000 |
| **Purpose** | Physical container instances with nested sets hierarchy |

### Schema Comparison

#### SQL Server Original
```sql
CREATE TABLE [dbo].[container](
    [id] int IDENTITY(1, 1) NOT NULL,
    [container_type_id] int NOT NULL,
    [name] varchar(128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [uid] nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    [mass] float(53) NULL,
    [left_id] int NOT NULL DEFAULT ((1)),
    [right_id] int NOT NULL DEFAULT ((2)),
    [scope_id] nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL DEFAULT (newid()),
    [position_name] varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [position_x_coordinate] varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [position_y_coordinate] varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [depth] int NOT NULL DEFAULT ((0)),
    [created_on] datetime NULL DEFAULT (getdate())
)
ON [PRIMARY];
```

#### AWS SCT Converted
```sql
CREATE TABLE perseus_dbo.container(
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    container_type_id INTEGER NOT NULL,
    name CITEXT,
    uid CITEXT NOT NULL,
    mass DOUBLE PRECISION,
    left_id INTEGER NOT NULL DEFAULT (1),
    right_id INTEGER NOT NULL DEFAULT (2),
    scope_id CITEXT NOT NULL DEFAULT aws_sqlserver_ext.newid(),
    position_name CITEXT,
    position_x_coordinate CITEXT,
    position_y_coordinate CITEXT,
    depth INTEGER NOT NULL DEFAULT (0),
    created_on TIMESTAMP WITHOUT TIME ZONE DEFAULT clock_timestamp()
)
    WITH (
    OIDS=FALSE
    );
```

### Table Semantics

**Nested Sets Pattern**:
- `left_id`, `right_id`, `scope_id`, `depth` implement nested sets hierarchy
- Example: Freezer → Rack → Plate → Well hierarchy
- Efficient queries: "Get all containers in freezer X" = `WHERE left_id BETWEEN parent.left AND parent.right`

**Position Coordinates**:
- `position_name`: Human-readable position (e.g., "A1", "B3")
- `position_x_coordinate`, `position_y_coordinate`: Numeric coordinates for robotics (e.g., "1", "3")
- Used by liquid handling robots for automated sample processing

### Issue Analysis

#### P0 Issues (Critical)

**1. Schema Naming Convention (P0)**
- **Issue**: `perseus_dbo` instead of `perseus`
- **Fix**: Change to `perseus.container`
- **Constitution Violation**: Article V (Naming Conventions)

**2. OIDS=FALSE Deprecated (P0)**
- **Issue**: Syntax error in PostgreSQL 17
- **Fix**: Remove clause
- **Constitution Violation**: None (AWS SCT legacy)

**3. CITEXT Overuse (P0)**
- **Issue**: AWS SCT converts ALL varchar/nvarchar to CITEXT
- **Columns Affected**: `name`, `uid`, `scope_id`, `position_name`, `position_x_coordinate`, `position_y_coordinate`
- **Impact**:
  - `uid` is used in joins and lookups (should be VARCHAR for performance)
  - `scope_id` is UUID/GUID (exact match only, should be VARCHAR or UUID type)
  - Coordinates are numeric strings (should be VARCHAR or even INTEGER)
- **Fix**:
  ```sql
  name VARCHAR(128),                    -- Keep for human-readable search
  uid VARCHAR(50) NOT NULL,             -- Change to VARCHAR (joins/lookups)
  scope_id VARCHAR(50) NOT NULL,        -- Change to VARCHAR (exact match) or UUID type
  position_name VARCHAR(50),            -- Change to VARCHAR (exact match: "A1")
  position_x_coordinate VARCHAR(50),    -- Change to VARCHAR (or INTEGER)
  position_y_coordinate VARCHAR(50)     -- Change to VARCHAR (or INTEGER)
  ```
- **Constitution Violation**: Article III (Performance) + Article II (Strict Typing)

**4. aws_sqlserver_ext.newid() Function (P0 - BLOCKER)**
- **Issue**: AWS SCT uses custom extension function `aws_sqlserver_ext.newid()`
- **Impact**: CRITICAL - This function may not exist in PostgreSQL 17
- **SQL Server Behavior**: `NEWID()` generates UUID/GUID
- **Fix**: Replace with PostgreSQL native `gen_random_uuid()` (requires pgcrypto extension)
- **Alternative**: Use `uuid_generate_v4()` from uuid-ossp extension
- **Constitution Violation**: Article I (ANSI-SQL Primacy) - Use standard SQL or native functions

**Recommended Fix**:
```sql
scope_id UUID NOT NULL DEFAULT gen_random_uuid()  -- Better: use UUID type
-- OR
scope_id VARCHAR(50) NOT NULL DEFAULT gen_random_uuid()::VARCHAR
```

**5. clock_timestamp() vs CURRENT_TIMESTAMP (P0)**
- **Issue**: Transaction consistency
- **Fix**: Use `CURRENT_TIMESTAMP`
- **Constitution Violation**: Article IV (Transaction Management)

#### P1 Issues

**6. Coordinate Data Types (P1)**
- **Issue**: `position_x_coordinate` and `position_y_coordinate` stored as VARCHAR(50)
- **Impact**: If these are purely numeric, storing as VARCHAR wastes space and prevents numeric operations
- **Recommendation**: Check if coordinates are numeric (e.g., 1, 2, 3) or alphanumeric (e.g., "A1", "B2")
- **Fix (if numeric)**: `position_x_coordinate INTEGER, position_y_coordinate INTEGER`
- **Fix (if alphanumeric)**: Keep VARCHAR

**7. Missing Foreign Keys (P1)**
- **Issue**: No FK constraint to `container_type` table
- **Impact**: Referential integrity not enforced
- **Fix**: Add FK after table creation

**8. Missing Comments (P1)**
- **Issue**: No documentation for nested sets columns
- **Fix**: Add COMMENT ON statements

### Refactored Schema (Production-Ready)

```sql
-- ============================================================================
-- Table: perseus.container
-- Description: Physical container instances with nested sets hierarchy
-- Priority: P1 - High Priority
-- Dependencies: perseus.container_type (FK)
-- Notes: 50k-100k rows, nested sets for efficient hierarchy queries
-- ============================================================================

CREATE TABLE perseus.container (
    -- Primary Key
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,

    -- Type and Identification
    container_type_id INTEGER NOT NULL,
    name VARCHAR(128),
    uid VARCHAR(50) NOT NULL,

    -- Physical Properties
    mass DOUBLE PRECISION,

    -- Nested Sets Hierarchy (for tree queries)
    left_id INTEGER NOT NULL DEFAULT 1,
    right_id INTEGER NOT NULL DEFAULT 2,
    scope_id UUID NOT NULL DEFAULT gen_random_uuid(),
    depth INTEGER NOT NULL DEFAULT 0,

    -- Positional Information (for robotics)
    position_name VARCHAR(50),           -- Human-readable: "A1", "B3"
    position_x_coordinate VARCHAR(50),   -- Could be INTEGER if purely numeric
    position_y_coordinate VARCHAR(50),   -- Could be INTEGER if purely numeric

    -- Audit
    created_on TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Column Comments
COMMENT ON TABLE perseus.container IS 'Physical container instances (plates, tubes, racks, freezers) with nested sets hierarchy';
COMMENT ON COLUMN perseus.container.id IS 'Surrogate primary key';
COMMENT ON COLUMN perseus.container.uid IS 'Unique business identifier (barcode/RFID tag)';
COMMENT ON COLUMN perseus.container.container_type_id IS 'Foreign key to container_type - defines container properties';
COMMENT ON COLUMN perseus.container.left_id IS 'Nested sets left boundary - used for hierarchy queries';
COMMENT ON COLUMN perseus.container.right_id IS 'Nested sets right boundary - used for hierarchy queries';
COMMENT ON COLUMN perseus.container.scope_id IS 'Nested sets scope UUID - multiple trees in same table';
COMMENT ON COLUMN perseus.container.depth IS 'Tree depth level (0 = root, e.g., building; 4 = well)';
COMMENT ON COLUMN perseus.container.position_name IS 'Human-readable position (e.g., "A1" for well in plate)';
COMMENT ON COLUMN perseus.container.position_x_coordinate IS 'X-axis coordinate for robotic positioning';
COMMENT ON COLUMN perseus.container.position_y_coordinate IS 'Y-axis coordinate for robotic positioning';
```

### Quality Score

| Dimension | AWS SCT Score | Target Score | Issues |
|-----------|---------------|--------------|--------|
| **Syntax Correctness** | 2/10 | 10/10 | OIDS, schema, aws_sqlserver_ext.newid() |
| **Logic Preservation** | 7/10 | 10/10 | clock_timestamp(), newid() replacement |
| **Performance** | 5/10 | 9/10 | CITEXT on uid (join column) |
| **Maintainability** | 4/10 | 8/10 | No comments for nested sets |
| **Security** | 7/10 | 8/10 | Missing FK constraints |
| **OVERALL** | **4.5/10** | **9.0/10** | **NEEDS REFACTORING** |

---

## Table 2: container_type (Container Type Definitions)

### Basic Information

| Attribute | Value |
|-----------|-------|
| **SQL Server Name** | `perseus.dbo.container_type` |
| **PostgreSQL Name** | `perseus_dbo.container_type` → **SHOULD BE** `perseus.container_type` |
| **Priority** | P1 - High Priority |
| **Dependency Tier** | 0 (foundational) |
| **Creation Order** | 18 |
| **Row Count (Est.)** | 20-50 (reference data) |
| **Purpose** | Container type definitions (plate, tube, rack, etc.) |

### Schema Comparison

#### SQL Server Original
```sql
CREATE TABLE [dbo].[container_type](
    [id] int IDENTITY(1, 1) NOT NULL,
    [name] varchar(128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    [is_parent] int NOT NULL DEFAULT ((1)),
    [is_equipment] int NOT NULL DEFAULT ((0)),
    [is_single] int NOT NULL DEFAULT ((1)),
    [is_restricted] int NOT NULL DEFAULT ((0)),
    [is_gooable] int NOT NULL DEFAULT ((0))
)
ON [PRIMARY];
```

#### AWS SCT Converted
```sql
CREATE TABLE perseus_dbo.container_type(
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    name CITEXT NOT NULL,
    is_parent INTEGER NOT NULL DEFAULT (1),
    is_equipment INTEGER NOT NULL DEFAULT (0),
    is_single INTEGER NOT NULL DEFAULT (1),
    is_restricted INTEGER NOT NULL DEFAULT (0),
    is_gooable INTEGER NOT NULL DEFAULT (0)
)
    WITH (
    OIDS=FALSE
    );
```

### Table Semantics

**Boolean Flags** (stored as integers 0/1):
- `is_parent`: Can contain child containers (e.g., plate can contain wells)
- `is_equipment`: Is equipment vs container (e.g., centrifuge vs tube)
- `is_single`: Single-use (e.g., disposable tube) vs reusable (e.g., glass flask)
- `is_restricted`: Restricted access (e.g., biohazard freezer)
- `is_gooable`: Can directly contain materials/goo (e.g., tube=true, rack=false)

### Issue Analysis

#### P0 Issues (Critical)

**1. Schema Naming (P0)** - Same as container

**2. OIDS=FALSE (P0)** - Same as container

**3. CITEXT on Type Name (P1 → P0 for consistency)**
- **Issue**: `name` is CITEXT but is a type name (exact match preferred)
- **Recommendation**: Keep CITEXT for search, but add unique constraint
- **Fix**: `name VARCHAR(128) NOT NULL UNIQUE`

**4. Boolean as INTEGER (P0 - CRITICAL)**
- **Issue**: All 5 boolean flags stored as INTEGER instead of BOOLEAN
- **Impact**: Non-idiomatic PostgreSQL, wastes space (20 bytes vs 5 bytes per row)
- **Fix**:
  ```sql
  is_parent BOOLEAN NOT NULL DEFAULT true,
  is_equipment BOOLEAN NOT NULL DEFAULT false,
  is_single BOOLEAN NOT NULL DEFAULT true,
  is_restricted BOOLEAN NOT NULL DEFAULT false,
  is_gooable BOOLEAN NOT NULL DEFAULT false
  ```
- **Constitution Violation**: Article II (Strict Typing)

#### P1 Issues

**5. Missing Comments (P1)**
- **Issue**: Boolean flags are cryptic without documentation
- **Fix**: Add COMMENT ON statements

### Refactored Schema (Production-Ready)

```sql
-- ============================================================================
-- Table: perseus.container_type
-- Description: Container type definitions (plate, tube, rack, freezer, etc.)
-- Priority: P1 - High Priority (foundational)
-- Dependencies: None (Tier 0)
-- Notes: Reference data (~20-50 rows), defines container capabilities
-- ============================================================================

CREATE TABLE perseus.container_type (
    -- Primary Key
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,

    -- Type Name
    name VARCHAR(128) NOT NULL,

    -- Container Capabilities (boolean flags)
    is_parent BOOLEAN NOT NULL DEFAULT true,
    is_equipment BOOLEAN NOT NULL DEFAULT false,
    is_single BOOLEAN NOT NULL DEFAULT true,
    is_restricted BOOLEAN NOT NULL DEFAULT false,
    is_gooable BOOLEAN NOT NULL DEFAULT false
);

-- Column Comments
COMMENT ON TABLE perseus.container_type IS 'Container type definitions with capability flags';
COMMENT ON COLUMN perseus.container_type.name IS 'Container type name (e.g., "96-Well Plate", "Microfuge Tube")';
COMMENT ON COLUMN perseus.container_type.is_parent IS 'Can contain child containers (true for plates, racks; false for tubes)';
COMMENT ON COLUMN perseus.container_type.is_equipment IS 'Is equipment vs container (true for centrifuge, false for tube)';
COMMENT ON COLUMN perseus.container_type.is_single IS 'Single-use disposable (true for disposable tubes, false for glassware)';
COMMENT ON COLUMN perseus.container_type.is_restricted IS 'Requires special access permissions (true for biohazard freezers)';
COMMENT ON COLUMN perseus.container_type.is_gooable IS 'Can directly contain materials (true for tubes/wells, false for racks)';
```

### Quality Score

| Dimension | AWS SCT Score | Target Score | Issues |
|-----------|---------------|--------------|--------|
| **Syntax Correctness** | 3/10 | 10/10 | OIDS, schema, INTEGER booleans |
| **Logic Preservation** | 7/10 | 10/10 | Boolean conversion needed |
| **Performance** | 8/10 | 9/10 | Minor (ref data) |
| **Maintainability** | 4/10 | 8/10 | No comments for flags |
| **Security** | 7/10 | 8/10 | Acceptable |
| **OVERALL** | **5.0/10** | **9.0/10** | **NEEDS REFACTORING** |

---

## Table 3: container_history (Container State History)

### Basic Information

| Attribute | Value |
|-----------|-------|
| **SQL Server Name** | `perseus.dbo.container_history` |
| **PostgreSQL Name** | `perseus_dbo.container_history` → **SHOULD BE** `perseus.container_history` |
| **Priority** | P2 - Medium Priority |
| **Dependency Tier** | 1 (references container) |
| **Creation Order** | 70 |
| **Row Count (Est.)** | 500,000+ (audit log) |
| **Purpose** | Track container state changes over time |

### Schema Comparison

#### SQL Server Original
```sql
CREATE TABLE [dbo].[container_history](
    [id] int IDENTITY(1, 1) NOT NULL,
    [history_id] int NOT NULL,
    [container_id] int NOT NULL
)
ON [PRIMARY];
```

#### AWS SCT Converted
```sql
CREATE TABLE perseus_dbo.container_history(
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    history_id INTEGER NOT NULL,
    container_id INTEGER NOT NULL
)
    WITH (
    OIDS=FALSE
    );
```

### Table Semantics

**UNDOCUMENTED**: This table has minimal schema and unclear purpose. Based on name and structure:

**Likely Purpose**: Junction table between containers and a generic history table
- `history_id`: Foreign key to a generic history/audit table (not found in schema yet)
- `container_id`: Foreign key to container table
- Pattern: "Container X had history event Y"

**Missing Information**:
- No timestamp columns (when did event occur?)
- No event type (what changed?)
- No old/new values (what was the change?)

### Issue Analysis

#### P0 Issues

**1. Schema Naming (P0)** - Same as other tables

**2. OIDS=FALSE (P0)** - Same as other tables

**3. Incomplete Schema (P0 - CRITICAL)**
- **Issue**: Missing essential audit columns
- **Impact**: Cannot effectively track container state changes
- **Recommendation**: Add timestamp, event type, user, change details
- **Fix**:
  ```sql
  changed_on TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  changed_by INTEGER NOT NULL,  -- FK to user table
  event_type VARCHAR(50) NOT NULL,  -- 'created', 'moved', 'updated', 'deleted'
  old_value TEXT,  -- JSON or text snapshot of old state
  new_value TEXT   -- JSON or text snapshot of new state
  ```
- **Constitution Violation**: Article IV (Maintainability) + Article VI (Data Integrity)

#### P1 Issues

**4. Missing Foreign Keys (P1)**
- **Issue**: No FK constraints to container or history tables
- **Fix**: Add FKs after table creation

**5. Missing Primary Key Composite (P1)**
- **Issue**: `id` is PK, but `(container_id, history_id)` might be more meaningful
- **Recommendation**: Keep surrogate key `id`, add unique constraint on `(container_id, history_id)`

### Refactored Schema (Production-Ready)

```sql
-- ============================================================================
-- Table: perseus.container_history
-- Description: Container state change audit log
-- Priority: P2 - Medium Priority (audit table)
-- Dependencies: perseus.container (FK)
-- Notes: High-volume table (500k+ rows), append-only audit log
-- ============================================================================

CREATE TABLE perseus.container_history (
    -- Primary Key
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,

    -- References
    history_id INTEGER NOT NULL,        -- FK to generic history table (if exists)
    container_id INTEGER NOT NULL,      -- FK to perseus.container

    -- Audit Fields (ADDED - not in SQL Server original)
    changed_on TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    changed_by INTEGER,                 -- FK to user table
    event_type VARCHAR(50) NOT NULL,    -- 'created', 'moved', 'updated', 'deleted'
    old_value TEXT,                     -- JSON snapshot of old state
    new_value TEXT,                     -- JSON snapshot of new state

    -- Composite Unique Constraint
    CONSTRAINT uk_container_history UNIQUE (container_id, history_id)
);

-- Column Comments
COMMENT ON TABLE perseus.container_history IS 'Container state change audit log (append-only)';
COMMENT ON COLUMN perseus.container_history.container_id IS 'Container that changed (references container.id)';
COMMENT ON COLUMN perseus.container_history.history_id IS 'Generic history event ID (may reference external audit system)';
COMMENT ON COLUMN perseus.container_history.event_type IS 'Type of change: created, moved, updated, deleted';
COMMENT ON COLUMN perseus.container_history.old_value IS 'JSON snapshot of container state before change';
COMMENT ON COLUMN perseus.container_history.new_value IS 'JSON snapshot of container state after change';
```

### Quality Score

| Dimension | AWS SCT Score | Target Score | Issues |
|-----------|---------------|--------------|--------|
| **Syntax Correctness** | 3/10 | 10/10 | OIDS, schema |
| **Logic Preservation** | 4/10 | 9/10 | Missing audit columns (CRITICAL) |
| **Performance** | 6/10 | 9/10 | Missing indexes on container_id |
| **Maintainability** | 3/10 | 8/10 | No comments, unclear purpose |
| **Security** | 5/10 | 8/10 | Missing changed_by column |
| **OVERALL** | **3.5/10** | **9.0/10** | **CRITICAL REFACTORING NEEDED** |

---

## Table 4: container_type_position (Container Hierarchy Positions)

### Basic Information

| Attribute | Value |
|-----------|-------|
| **SQL Server Name** | `perseus.dbo.container_type_position` |
| **PostgreSQL Name** | `perseus_dbo.container_type_position` → **SHOULD BE** `perseus.container_type_position` |
| **Priority** | P2 - Medium Priority |
| **Dependency Tier** | 1 (references container_type) |
| **Creation Order** | 71 |
| **Row Count (Est.)** | 500-1000 (reference data) |
| **Purpose** | Define valid parent-child container type relationships with positions |

### Schema Comparison

#### SQL Server Original
```sql
CREATE TABLE [dbo].[container_type_position](
    [id] int IDENTITY(1, 1) NOT NULL,
    [parent_container_type_id] int NOT NULL,
    [child_container_type_id] int NULL,
    [position_name] varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [position_x_coordinate] varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [position_y_coordinate] varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
)
ON [PRIMARY];
```

#### AWS SCT Converted
```sql
CREATE TABLE perseus_dbo.container_type_position(
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    parent_container_type_id INTEGER NOT NULL,
    child_container_type_id INTEGER,
    position_name CITEXT,
    position_x_coordinate CITEXT,
    position_y_coordinate CITEXT
)
    WITH (
    OIDS=FALSE
    );
```

### Table Semantics

**Purpose**: Define valid layouts for container types

**Example Rows**:
```
id=1, parent_container_type_id=5 (96-well plate), child_container_type_id=10 (well),
      position_name='A1', position_x_coordinate='1', position_y_coordinate='1'

id=2, parent_container_type_id=5 (96-well plate), child_container_type_id=10 (well),
      position_name='A2', position_x_coordinate='2', position_y_coordinate='1'
...
id=96, parent_container_type_id=5 (96-well plate), child_container_type_id=10 (well),
      position_name='H12', position_x_coordinate='12', position_y_coordinate='8'
```

This defines: "A 96-well plate contains 96 wells at specific positions (A1-H12)"

### Issue Analysis

#### P0 Issues

**1. Schema Naming (P0)** - Same as other tables

**2. OIDS=FALSE (P0)** - Same as other tables

**3. CITEXT on Coordinates (P0)**
- **Issue**: Position names and coordinates converted to CITEXT
- **Impact**: Performance + incorrect data type for coordinates
- **Fix**:
  ```sql
  position_name VARCHAR(50),       -- Exact match: "A1"
  position_x_coordinate VARCHAR(50),  -- Or INTEGER if purely numeric
  position_y_coordinate VARCHAR(50)   -- Or INTEGER if purely numeric
  ```
- **Constitution Violation**: Article II (Strict Typing)

#### P1 Issues

**4. Missing Foreign Keys (P1)**
- **Issue**: No FK constraints to container_type
- **Fix**: Add FKs to both parent_container_type_id and child_container_type_id

**5. Nullable child_container_type_id (P1)**
- **Issue**: Why would a position not have a child type?
- **Recommendation**: Investigate business logic - likely should be NOT NULL

### Refactored Schema (Production-Ready)

```sql
-- ============================================================================
-- Table: perseus.container_type_position
-- Description: Define valid parent-child container layouts with positions
-- Priority: P2 - Medium Priority (reference data)
-- Dependencies: perseus.container_type (FK)
-- Notes: Reference data (~500-1000 rows), defines plate layouts, rack positions
-- ============================================================================

CREATE TABLE perseus.container_type_position (
    -- Primary Key
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,

    -- Container Type Relationship
    parent_container_type_id INTEGER NOT NULL,
    child_container_type_id INTEGER,  -- Nullable (investigate business logic)

    -- Position Definition
    position_name VARCHAR(50),           -- Human-readable: "A1", "B3"
    position_x_coordinate VARCHAR(50),   -- Could be INTEGER if numeric
    position_y_coordinate VARCHAR(50)    -- Could be INTEGER if numeric
);

-- Column Comments
COMMENT ON TABLE perseus.container_type_position IS 'Valid container type layouts - defines positions within parent containers (e.g., well positions in 96-well plate)';
COMMENT ON COLUMN perseus.container_type_position.parent_container_type_id IS 'Parent container type (e.g., "96-Well Plate")';
COMMENT ON COLUMN perseus.container_type_position.child_container_type_id IS 'Child container type that occupies position (e.g., "Well")';
COMMENT ON COLUMN perseus.container_type_position.position_name IS 'Human-readable position identifier (e.g., "A1", "H12" for plate wells)';
COMMENT ON COLUMN perseus.container_type_position.position_x_coordinate IS 'X-axis coordinate for robotic positioning';
COMMENT ON COLUMN perseus.container_type_position.position_y_coordinate IS 'Y-axis coordinate for robotic positioning';
```

### Quality Score

| Dimension | AWS SCT Score | Target Score | Issues |
|-----------|---------------|--------------|--------|
| **Syntax Correctness** | 3/10 | 10/10 | OIDS, schema |
| **Logic Preservation** | 7/10 | 10/10 | CITEXT on coordinates |
| **Performance** | 6/10 | 9/10 | CITEXT overuse |
| **Maintainability** | 4/10 | 8/10 | No comments |
| **Security** | 7/10 | 8/10 | Missing FK constraints |
| **OVERALL** | **5.0/10** | **9.0/10** | **NEEDS REFACTORING** |

---

## Consolidated Findings

### Critical Issues Summary (ALL 4 Tables)

| Issue | Severity | Tables Affected | Impact |
|-------|----------|-----------------|--------|
| **Schema naming: perseus_dbo → perseus** | P0 | All 4 | All queries need rewrite |
| **OIDS=FALSE deprecated** | P0 | All 4 | Syntax error in PostgreSQL 17 |
| **CITEXT on join/lookup columns** | P0 | container, container_type_position | Performance degradation |
| **aws_sqlserver_ext.newid()** | P0 | container | CRITICAL - Function may not exist |
| **clock_timestamp()** | P0 | container | Transaction consistency |
| **INTEGER instead of BOOLEAN** | P0 | container_type | Non-idiomatic PostgreSQL |
| **Incomplete audit schema** | P0 | container_history | Cannot track changes effectively |
| **Missing FK constraints** | P1 | All 4 | Referential integrity not enforced |
| **Missing column comments** | P1 | All 4 | Maintainability |
| **Coordinate data types** | P1 | container, container_type_position | Should be INTEGER if numeric |

### Data Type Conversion Summary

| SQL Server | AWS SCT | Recommended | Rationale |
|------------|---------|-------------|-----------|
| `int IDENTITY(1,1)` | `INTEGER GENERATED ALWAYS AS IDENTITY` | ✅ Keep | Constitution-compliant |
| `varchar(n)` | `CITEXT` | ❌ Change to `VARCHAR(n)` | Performance |
| `nvarchar(50)` | `CITEXT` | ❌ Change to `VARCHAR(50)` or `UUID` | Performance + proper typing |
| `int` (boolean) | `INTEGER` | ❌ Change to `BOOLEAN` | Idiomatic PostgreSQL |
| `float(53)` | `DOUBLE PRECISION` | ✅ Keep | Standard mapping |
| `datetime` | `TIMESTAMP WITHOUT TIME ZONE` | ✅ Keep | Standard mapping |
| `newid()` | `aws_sqlserver_ext.newid()` | ❌ Change to `gen_random_uuid()` | Native PostgreSQL |
| `getdate()` | `clock_timestamp()` | ❌ Change to `CURRENT_TIMESTAMP` | Transaction consistency |

### IDENTITY Column Summary

| Table | Column | SQL Server | PostgreSQL (Refactored) |
|-------|--------|------------|-------------------------|
| container | id | `IDENTITY(1,1)` | `GENERATED ALWAYS AS IDENTITY` |
| container_type | id | `IDENTITY(1,1)` | `GENERATED ALWAYS AS IDENTITY` |
| container_history | id | `IDENTITY(1,1)` | `GENERATED ALWAYS AS IDENTITY` |
| container_type_position | id | `IDENTITY(1,1)` | `GENERATED ALWAYS AS IDENTITY` |

All conversions use `GENERATED ALWAYS AS IDENTITY` (NOT `SERIAL`).

### Index Strategy (Phase T106-T111)

**High-priority indexes for container tables**:

```sql
-- container
CREATE UNIQUE INDEX pk_container ON perseus.container(id);
CREATE UNIQUE INDEX uk_container_uid ON perseus.container(uid);
CREATE INDEX idx_container_type ON perseus.container(container_type_id);
CREATE INDEX idx_container_nested_sets ON perseus.container(scope_id, left_id, right_id);
CREATE INDEX idx_container_depth ON perseus.container(depth);

-- container_type
CREATE UNIQUE INDEX pk_container_type ON perseus.container_type(id);
CREATE UNIQUE INDEX uk_container_type_name ON perseus.container_type(name);

-- container_history
CREATE UNIQUE INDEX pk_container_history ON perseus.container_history(id);
CREATE INDEX idx_container_history_container ON perseus.container_history(container_id);
CREATE INDEX idx_container_history_timestamp ON perseus.container_history(changed_on);  -- ADDED column

-- container_type_position
CREATE UNIQUE INDEX pk_container_type_position ON perseus.container_type_position(id);
CREATE INDEX idx_container_type_position_parent ON perseus.container_type_position(parent_container_type_id);
CREATE INDEX idx_container_type_position_child ON perseus.container_type_position(child_container_type_id);
```

### Constraint Strategy (Phase T112-T116)

**Foreign key constraints (to be added after all tables created)**:

```sql
-- container foreign keys
ALTER TABLE perseus.container ADD CONSTRAINT fk_container_type
    FOREIGN KEY (container_type_id) REFERENCES perseus.container_type(id);

-- container_history foreign keys
ALTER TABLE perseus.container_history ADD CONSTRAINT fk_container_history_container
    FOREIGN KEY (container_id) REFERENCES perseus.container(id);

-- container_type_position foreign keys
ALTER TABLE perseus.container_type_position ADD CONSTRAINT fk_container_type_position_parent
    FOREIGN KEY (parent_container_type_id) REFERENCES perseus.container_type(id);
ALTER TABLE perseus.container_type_position ADD CONSTRAINT fk_container_type_position_child
    FOREIGN KEY (child_container_type_id) REFERENCES perseus.container_type(id);
```

### Overall Quality Assessment

| Table | AWS SCT Score | Target Score | Priority Fix Level |
|-------|---------------|--------------|-------------------|
| **container** | 4.5/10 | 9.0/10 | HIGH (P0 - newid() blocker) |
| **container_type** | 5.0/10 | 9.0/10 | HIGH (P0 - booleans) |
| **container_history** | 3.5/10 | 9.0/10 | HIGH (P0 - incomplete schema) |
| **container_type_position** | 5.0/10 | 9.0/10 | MEDIUM (P1) |
| **AVERAGE** | **4.5/10** | **9.0/10** | **HIGH PRIORITY** |

**Verdict**: AWS SCT baseline is **NOT PRODUCTION-READY**. Critical issues: newid() function, boolean types, incomplete audit schema.

---

## Recommendations

### Immediate Actions (Before Refactoring Phase)

1. **CRITICAL**: Replace `aws_sqlserver_ext.newid()` with `gen_random_uuid()` or `uuid_generate_v4()`
2. **Create refactored DDL files** for all 4 tables
3. **Change all INTEGER booleans to BOOLEAN** in container_type
4. **Remove OIDS=FALSE** from all definitions
5. **Change schema from perseus_dbo to perseus**
6. **Replace CITEXT with VARCHAR** on uid, scope_id, position columns
7. **Add audit columns** to container_history (changed_on, changed_by, event_type, etc.)
8. **Replace clock_timestamp() with CURRENT_TIMESTAMP**

### Extension Requirements

**Required PostgreSQL extensions**:

```sql
-- For gen_random_uuid() function
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Alternative: uuid-ossp extension
-- CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
```

### Testing Requirements

1. **Test newid() replacement**: Verify `gen_random_uuid()` generates valid UUIDs
2. **Test boolean conversion**: Verify 0/1 → false/true conversion in data migration
3. **Test nested sets queries**: Verify hierarchy queries work with refactored schema
4. **Test coordinate data types**: Verify VARCHAR vs INTEGER decision for X/Y coordinates

---

## Next Steps

1. **T104**: Batch analyze remaining 84 tables (by functional area)
2. **T105**: Consolidate data type conversions document
3. **T106**: IDENTITY columns analysis document
4. **T107**: Executive summary report

---

**Analysis Complete**: 2026-01-26
**Reviewed By**: Pierre Ribeiro (DBA)
**Status**: Ready for T104
