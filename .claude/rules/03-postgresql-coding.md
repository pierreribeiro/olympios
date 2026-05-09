---
paths:
  - sql/**/*.sql
  - procedures/**/*.sql
  - functions/**/*.sql
  - views/**/*.sql
  - triggers/**/*.sql
  - migrations/**/*.sql
---

# PostgreSQL Coding Standards (Constitution v2.0 Extract)

## Naming Conventions

- ALL objects: lowercase `snake_case`. No PascalCase, no camelCase, no Hungarian notation.
- Tables: plural nouns (`customers`, `order_items`).
- Views: prefix `v_` (`v_active_customers`).
- Materialized Views: prefix `mv_` (`mv_monthly_sales`).
- Temp Tables: prefix `tmp_` (`tmp_processing_batch`).
- Functions: action verb prefix (`get_customer_by_id`, `calculate_order_total`).
- Triggers: prefix `trg_` (`trg_audit_customer_changes`).
- Indexes: `table_column_suffix` (`orders_customer_id_idx`, `customers_pkey`, `customers_email_key`).
- Types: suffix `_type`, Enums: suffix `_enum`.
- Parameters: `snake_case` with trailing underscore for column-name conflicts (`customer_id_`).
- Max 63 characters. Never use `pg_` prefix.

## Data Types

- Primary keys: `BIGINT GENERATED ALWAYS AS IDENTITY` (not SERIAL).
- Strings: `TEXT` or `VARCHAR(n)` when length constraint is a business rule.
- Timestamps: `TIMESTAMPTZ` always (never `TIMESTAMP WITHOUT TIME ZONE`).
- JSON: `JSONB` (never `JSON`).
- Money: `NUMERIC(precision, scale)` (never `MONEY` type).
- Booleans: `BOOLEAN` (never integer 0/1).

## Query Standards

- NO `SELECT *` in production code. Explicit column lists only.
- `EXISTS` over `IN` for subqueries. `EXISTS` over `COUNT(*)` for existence checks.
- Always use `RETURNING` after INSERT/UPDATE/DELETE when caller needs affected data.
- Use `ON CONFLICT` for upsert operations (not exception-based INSERT-then-UPDATE).
- Prefer CTEs over temp tables for intermediate results.
- NO cursors or WHILE loops for data processing — use set-based operations (CTEs, window functions).

## Function/Procedure Standards

- Always specify volatility: `IMMUTABLE`, `STABLE`, or `VOLATILE`.
- Always specify `LANGUAGE plpgsql` (or `sql` for simple queries).
- Use `STRICT` when function should return NULL on any NULL input.
- Use `SECURITY DEFINER` only when required, with `SET search_path = public`.
- Schema-qualify all object references (`perseus.table_name`, not just `table_name`).

## Transaction Control

- Functions CANNOT use COMMIT/ROLLBACK. Procedures CAN.
- Keep transactions SHORT (< 10 minutes).
- Use SAVEPOINTs for partial rollback within complex procedures.
- For testable procedures: extract logic into a function (testable with pgTAP), use procedure as thin COMMIT wrapper.

## Performance

- Never wrap indexed columns in functions (`LOWER()`, `UPPER()`, `COALESCE()`).
- Create expression indexes if case-insensitive comparison is genuinely needed.
- Use `LIMIT 1` for existence checks, not `COUNT(*)`.
- Add `ON COMMIT DROP` to temporary tables.
- Use `ANALYZE` on temp tables with >1000 rows before complex queries.
