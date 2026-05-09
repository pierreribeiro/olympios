---
paths:
  - tests/**/*.sql
  - test/**/*.sql
---

# pgTAP Testing Rules

## Test File Structure (Mandatory)

Every test file MUST follow this skeleton:

```sql
BEGIN;
SELECT plan(N);        -- Always explicit count, NEVER no_plan()
-- ... assertions ...
SELECT * FROM finish();
ROLLBACK;
```

## File Organization

- One file per object or concern. Maximum 30 assertions per file.
- Naming: `test_[schema_]object_name.sql`
- Sections in order: Structure → Setup Data → Happy Path → Edge Cases → Error Cases → Cleanup.

## Assertion Rules

- Always cast values explicitly: `42::integer`, `99.95::numeric`, `'text'::text`.
- Always use `ORDER BY` with `results_eq()`. Prefer `set_eq()` when order is irrelevant.
- Never assert auto-generated IDs (SERIAL/IDENTITY sequences survive ROLLBACK).
- Always `DEALLOCATE` prepared statements before `finish()`.
- Use `$$dollar quoting$$` for SQL strings inside assertions (avoids single-quote escaping).

## Minimum Test Coverage Per Object Type

- **Function**: has_function, function_returns, function_lang_is, happy path is(), NULL is(), throws_ok()
- **Procedure**: has_function + is_procedure, lives_ok('CALL ...'), verify side effects, throws_ok()
- **Trigger**: has_trigger, trigger_is (function name), verify behavioral effect after DML
- **View**: has_view, columns_are, set_eq for results, is_empty with no qualifying data
- **Table**: has_table, columns_are, col_type_is, col_not_null, has_pk, fk_ok, has_check
- **Index**: has_index, index_is_type, index_is_unique (if applicable)

## Testing Procedures (CALL syntax)

```sql
-- Wrap CALL in lives_ok for execution test
SELECT lives_ok(
    $$CALL schema.procedure_name(param1, param2)$$,
    'procedure executes without error'
);
-- Then verify side effects with is(), set_eq(), results_eq()
```

## Testing Error Cases

```sql
-- Use PostgreSQL error codes (NOT error messages — messages are locale-dependent)
SELECT throws_ok(sql, 'SQLSTATE_CODE', NULL, 'description');
```

**Common error codes**: 23502 (not_null_violation), 23503 (fk_violation), 23505 (unique_violation), 23514 (check_violation), 42501 (insufficient_privilege), P0001 (raise_exception).

## NULL Testing (Mandatory for EVERY function/procedure)

Always include at least one NULL parameter test. NULL is the #1 source of database bugs.

## Performance Testing

`performs_ok()` has PL/pgSQL overhead (~20-30ms). Use it as a smoke test for slow queries (seconds), not for microsecond precision.
