---
paths:
  - tests/**/*.sql
  - test/**/*.sql
  - procedures/**/*.sql
  - functions/**/*.sql
  - views/**/*.sql
  - triggers/**/*.sql
---

# Anti-Patterns: What NOT To Do

## Testing Anti-Patterns

| NEVER Do This | Do This Instead |
|---------------|-----------------|
| `SELECT is((SELECT 1+1), 2)` — testing PostgreSQL arithmetic | Test YOUR constraints, functions, triggers |
| `results_eq()` without `ORDER BY` | Always `ORDER BY`, or use `set_eq()`/`bag_eq()` |
| `SELECT is(id, 1, 'first user')` — asserting auto-IDs | Test by business key (email, name) |
| Forget to `DEALLOCATE` prepared statements | Always `DEALLOCATE` before `finish()` |
| One file with 200+ assertions | One file per object; max 30 assertions |
| Check internal variable values | Test inputs → outputs and side effects only |
| Only test happy paths | Always test NULL, empty, boundary, error cases |
| Mock everything with stubs | Mock external dependencies only |
| `col_type_is('users', 'name', 'varchar')` | Use exact PG type: `character varying(255)` |

## Coding Anti-Patterns

| NEVER Do This | Do This Instead |
|---------------|-----------------|
| `SELECT *` in production code | Explicit column lists |
| `LOWER(indexed_column)` in WHERE | Expression index or citext type |
| `COUNT(*) > 0` for existence | `EXISTS (SELECT 1 ...)` |
| `IN (SELECT ...)` with large subquery | `EXISTS (SELECT 1 ... WHERE ...)` |
| Cursor/WHILE loop for data processing | Set-based: CTEs, window functions |
| `WHEN OTHERS THEN NULL;` — swallowing errors | Specific exception types + RAISE |
| `SERIAL` for primary keys | `BIGINT GENERATED ALWAYS AS IDENTITY` |
| Temp tables without `ON COMMIT DROP` | Always add `ON COMMIT DROP` |
| `TIMESTAMP` without timezone | Always `TIMESTAMPTZ` |
| Implicit type conversions | Explicit `::type` casts |

## Perseus-Specific Anti-Patterns

| NEVER Do This | Do This Instead |
|---------------|-----------------|
| Deploy AWS SCT output without testing | Always test with pgTAP first (100% P0 failure rate) |
| Assume twin procedures get identical SCT treatment | Test each independently |
| Accept `LOWER()` additions without analysis | Verify if data actually has mixed case |
| Leave orphaned ROLLBACK without BEGIN | Add explicit BEGIN...EXCEPTION...END block |
| Keep literal `?` in RAISE statements | Replace with `%` format specifiers |
