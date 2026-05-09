---
paths:
  - procedures/**/*.sql
  - functions/**/*.sql
  - triggers/**/*.sql
---

# Error Handling Standards

## Exception Block Structure

```sql
BEGIN
    -- Business logic here
EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION 'Duplicate entry for %', p_identifier
            USING ERRCODE = 'P0001',
                  HINT = 'Check for existing record before insert';
    WHEN foreign_key_violation THEN
        RAISE EXCEPTION 'Referenced record not found: %', p_fk_value
            USING ERRCODE = 'P0001',
                  HINT = 'Verify parent record exists';
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            v_sqlstate = RETURNED_SQLSTATE,
            v_message  = MESSAGE_TEXT,
            v_context  = PG_EXCEPTION_CONTEXT;
        RAISE EXCEPTION 'Unexpected error in %: % (SQLSTATE: %)',
            'function_name', v_message, v_sqlstate
            USING ERRCODE = v_sqlstate,
                  HINT = v_context;
END;
```

## Rules

1. Use **specific exception names** (`unique_violation`, `foreign_key_violation`, `check_violation`) before `WHEN OTHERS`.
2. NEVER swallow errors silently (`WHEN OTHERS THEN NULL` is forbidden).
3. Always include **context** in error messages: function name, parameter values, operation state.
4. Use `USING ERRCODE`, `HINT`, `DETAIL` clauses for rich error metadata.
5. MINIMIZE exception blocks in loops — each creates a savepoint (performance overhead).
6. Use `ON CONFLICT` for upserts instead of catching `unique_violation`.

## RAISE Statement Format

```sql
-- CORRECT:
RAISE EXCEPTION 'Operation failed: % (ID: %)', v_message, p_id
    USING ERRCODE = 'P0001', HINT = 'Check input parameters';

-- WRONG (SCT pattern):
RAISE 'Error ?, severity ?, state ?';  -- Literal ? instead of %
```

## Logging Levels

| Level | When to Use |
|-------|-------------|
| `DEBUG` | Detailed diagnostic (loop iterations, intermediate values) |
| `LOG` | Operational events (procedure start/end, row counts) |
| `NOTICE` | Noteworthy but normal events (fallback path taken) |
| `WARNING` | Unexpected but recoverable (missing optional data) |
| `EXCEPTION` | Unrecoverable — terminates current transaction |

## PostgreSQL Error Code Quick Reference

| Code | Name | Trigger |
|------|------|---------|
| `23502` | not_null_violation | NULL into NOT NULL column |
| `23503` | foreign_key_violation | Non-existent FK reference |
| `23505` | unique_violation | Duplicate into UNIQUE column |
| `23514` | check_violation | CHECK constraint violated |
| `23P01` | exclusion_violation | EXCLUSION constraint violated |
| `42501` | insufficient_privilege | RLS or GRANT denial |
| `P0001` | raise_exception | Custom RAISE EXCEPTION |
| `P0002` | no_data_found | No rows for INTO STRICT |
| `P0003` | too_many_rows | Multiple rows for INTO STRICT |

## Transaction Control in Procedures

- Functions CANNOT use COMMIT/ROLLBACK.
- Procedures CAN use COMMIT/ROLLBACK only when called from top-level CALL (not from within a function).
- For testability: extract logic into a function, use procedure as thin COMMIT wrapper.
- Use SAVEPOINTs for partial rollback in complex operations.
