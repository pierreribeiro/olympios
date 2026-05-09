---
paths:
  - procedures/**/*.sql
  - procedures/corrected/**/*.sql
  - procedures/aws-sct-converted/**/*.sql
---

# SQL Server → PostgreSQL Migration Patterns

## AWS SCT Output: NEVER Trust, ALWAYS Verify

AWS SCT produces ~70% correct output. The remaining 30% contains P0-level issues in 100% of procedures analyzed. Common failure patterns (by occurrence rate):

### P0 Failures (100% occurrence — fix before ANY deployment)

1. **Broken Transaction Control**: SCT comments out `BEGIN TRAN`/`COMMIT TRAN` but leaves orphaned `ROLLBACK` in exception handlers. Fix: Add explicit `BEGIN...EXCEPTION...END` block inside procedure, or extract logic to function.

2. **Illegal ROLLBACK in Exception Handlers**: `ROLLBACK` without matching `BEGIN` causes runtime error. Fix: Wrap business logic in `BEGIN...EXCEPTION WHEN OTHERS THEN ROLLBACK; RAISE;...END;`

3. **Broken RAISE Statements**: SCT generates `RAISE 'Error ?, severity ?, state ?'` with literal `?` instead of `%` placeholders. Fix: `RAISE EXCEPTION 'Message: %, State: %', var_msg, var_state USING ERRCODE = 'P0001';`

4. **Temp Table Initialization**: SCT converts `@table_variables` to temp tables but omits `ON COMMIT DROP`. Fix: Add `ON COMMIT DROP` to all `CREATE TEMPORARY TABLE` statements.

### P1 Failures (High — fix before production)

5. **Excessive LOWER()**: SCT adds `LOWER()` to ALL string comparisons (~13× per procedure). Impact: ~39% performance degradation on indexed columns. Fix: Remove `LOWER()` where data is already normalized; use `citext` type or expression indexes only when genuinely needed.

6. **Commented-Out Business Logic**: SCT sometimes comments out core logic blocks with warning annotations. Fix: Review ALL commented sections — they may contain critical business rules.

### Name Conversion Rules

```
SQL Server (PascalCase)     →  PostgreSQL (snake_case)
GetMaterialByRunProperties  →  get_material_by_run_properties
sp_MoveNode                 →  move_node (drop sp_ prefix)
fn_CalculateTotal           →  calculate_total (drop fn_ prefix)
tbl_Customers               →  customers (drop tbl_ prefix)
vw_ActiveOrders             →  v_active_orders (standardize v_ prefix)
```

Algorithm: Remove Hungarian prefix → insert `_` before uppercase → lowercase all → apply standard PostgreSQL prefix.

## Equivalence Testing

For every migrated procedure, write pgTAP tests that verify:
1. **Structure**: has_function, is_procedure, parameter types match specification.
2. **Known Inputs → Expected Outputs**: Use test datasets executed against SQL Server to establish expected values, then assert PostgreSQL produces identical results.
3. **Error Behavior**: SQL Server `RAISERROR` → PostgreSQL `RAISE EXCEPTION` with `ERRCODE = 'P0001'`.
4. **Regression Guards**: Test for known SCT failure patterns (no orphaned ROLLBACK, no LOWER() on indexed columns, no literal `?` in RAISE).

## Size Increase ≠ Complexity Increase

AWS SCT inflates file sizes primarily with warning comments. Actual code growth is typically small (e.g., 215% file growth but only 22% real code growth). Do not be alarmed by large file size increases.
