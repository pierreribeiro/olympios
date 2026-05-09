# SQL Server to PostgreSQL Type Transformation Reference

**Project:** Perseus Database Migration  
**Purpose:** Quick reference for T-SQL → PL/pgSQL type transformations  
**Date:** 2026-02-11

## Standard Type Mappings

### Integer Types

| SQL Server | PostgreSQL | Notes |
|------------|-----------|-------|
| `tinyint` | `SMALLINT` | 0-255 → -32768 to 32767 |
| `smallint` | `SMALLINT` | Direct mapping |
| `int` | `INTEGER` | Direct mapping |
| `bigint` | `BIGINT` | Direct mapping |
| `bit` | `INTEGER` | 0/1/NULL → INTEGER for compatibility |

### Character Types

| SQL Server | PostgreSQL | Notes |
|------------|-----------|-------|
| `char(n)` | `CHAR(n)` | Fixed-length, space-padded |
| `nchar(n)` | `CHAR(n)` | PostgreSQL native UTF-8 support |
| `varchar(n)` | `VARCHAR(n)` | Variable-length |
| `nvarchar(n)` | `VARCHAR(n)` | PostgreSQL native UTF-8 support |
| `nvarchar(max)` | `TEXT` | Unlimited length |
| `text` | `TEXT` | Direct mapping |

### Date/Time Types

| SQL Server | PostgreSQL | Notes |
|------------|-----------|-------|
| `date` | `DATE` | Direct mapping |
| `time` | `TIME` | Direct mapping |
| `datetime` | `TIMESTAMP` | Precision to microseconds |
| `datetime2` | `TIMESTAMP` | Precision to microseconds |
| `smalldatetime` | `TIMESTAMP` | Same as datetime |
| `datetimeoffset` | `TIMESTAMP WITH TIME ZONE` | Includes timezone |

### Numeric Types

| SQL Server | PostgreSQL | Notes |
|------------|-----------|-------|
| `decimal(p,s)` | `NUMERIC(p,s)` | Exact numeric |
| `numeric(p,s)` | `NUMERIC(p,s)` | Direct mapping |
| `money` | `NUMERIC(19,4)` | Fixed precision |
| `smallmoney` | `NUMERIC(10,4)` | Fixed precision |
| `float` | `DOUBLE PRECISION` | 8-byte floating point |
| `real` | `REAL` | 4-byte floating point |

### Binary Types

| SQL Server | PostgreSQL | Notes |
|------------|-----------|-------|
| `binary(n)` | `BYTEA` | Fixed-length binary |
| `varbinary(n)` | `BYTEA` | Variable-length binary |
| `varbinary(max)` | `BYTEA` | Unlimited binary |
| `image` | `BYTEA` | Large binary object |

### Special Types

| SQL Server | PostgreSQL | Notes |
|------------|-----------|-------|
| `uniqueidentifier` | `UUID` or `VARCHAR(50)` | Use VARCHAR(50) for UID columns |
| `xml` | `XML` | Direct mapping |
| `geography` | `GEOGRAPHY` (PostGIS) | Requires PostGIS extension |
| `geometry` | `GEOMETRY` (PostGIS) | Requires PostGIS extension |
| `hierarchyid` | `LTREE` | Requires ltree extension |

## Perseus-Specific Decisions

### UID Columns (P0 Critical)

**Pattern:** `nvarchar uid` → `VARCHAR(50) uid UK`

**Affected Tables:**
- `goo.uid`
- `fatsmurf.uid`
- `container.uid`

**Rationale:**
- `VARCHAR(50)` provides sufficient length for UID strings
- `UK` (Unique Key) constraint enforces uniqueness
- Avoids UUID type for compatibility with existing string-based UIDs

### Boolean-Like Columns

**Pattern:** `bit column_name` → `INTEGER column_name`

**Examples:**
- `bit Complete` → `INTEGER Complete`
- `bit is_active` → `INTEGER is_active`
- `bit disabled` → `INTEGER disabled`

**Rationale:**
- Maintains 0/1/NULL semantics
- Compatible with existing application logic
- Avoids breaking changes in client code

### Identity Columns

**Pattern:** `IDENTITY(1,1)` → `GENERATED ALWAYS AS IDENTITY`

**NOT USED:**
- ~~`SERIAL`~~ (deprecated pattern)
- ~~`BIGSERIAL`~~ (deprecated pattern)

**Reason:** `GENERATED ALWAYS AS IDENTITY` is SQL standard and provides better control.

### Composite Primary Keys

Tables with composite PKs maintain all columns and annotations:

```sql
-- SQL Server
CREATE TABLE material_transition (
    material_id nvarchar(50) NOT NULL,
    transition_id nvarchar(50) NOT NULL,
    added_on datetime NOT NULL,
    PRIMARY KEY (material_id, transition_id)
);

-- PostgreSQL
CREATE TABLE public.material_transition (
    material_id VARCHAR(50) NOT NULL,
    transition_id VARCHAR(50) NOT NULL,
    added_on TIMESTAMP NOT NULL,
    PRIMARY KEY (material_id, transition_id)
);
```

## Edge Cases & Special Handling

### NULL vs NOT NULL

**Default:** Preserve exact NULL/NOT NULL specifications from SQL Server.

**Exception:** IDENTITY columns must be NOT NULL.

### Default Values

Transform SQL Server defaults to PostgreSQL equivalents:

| SQL Server | PostgreSQL |
|------------|-----------|
| `GETDATE()` | `CURRENT_TIMESTAMP` |
| `NEWID()` | `gen_random_uuid()` (for UUID) |
| `SYSDATETIME()` | `CLOCK_TIMESTAMP()` |
| `0` | `0` |
| `''` | `''` |

### Constraints

All FK, PK, UK, CHECK constraints must be preserved exactly:

- **PK:** Primary Key
- **FK:** Foreign Key (requires referenced table/column)
- **UK:** Unique Key
- **CHECK:** Check constraint (may require syntax updates)

## Validation Checklist

For each table transformation:

- [ ] All columns have PostgreSQL types
- [ ] Zero SQL Server types remaining (`nvarchar`, `datetime`, etc.)
- [ ] All PK, FK, UK annotations preserved
- [ ] Identity columns use `GENERATED ALWAYS AS IDENTITY`
- [ ] Default values transformed correctly
- [ ] NULL/NOT NULL specifications preserved
- [ ] Column order matches original
- [ ] Table name matches original (snake_case)

## Tools & Resources

**Validation Commands:**

```bash
# Check for SQL Server types
grep -E "(nvarchar|datetime|datetime2|smalldatetime|uniqueidentifier)" file.sql

# Check for deprecated SERIAL
grep -E "(SERIAL|BIGSERIAL)" file.sql

# Validate table count
grep -c "CREATE TABLE" file.sql

# Validate identity syntax
grep "GENERATED ALWAYS AS IDENTITY" file.sql
```

**References:**
- [PostgreSQL Data Types](https://www.postgresql.org/docs/17/datatype.html)
- [SQL Server to PostgreSQL Migration Guide](https://wiki.postgresql.org/wiki/Things_to_find_out_about_when_moving_from_Microsoft_SQL_Server_to_PostgreSQL)
- Project Constitution: `/docs/POSTGRESQL-PROGRAMMING-CONSTITUTION.md`

## Version History

- **v1.0** (2026-02-11): Initial reference based on ER diagram transformation
