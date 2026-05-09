# Anti-Patterns, Type Casting, and Error Codes

This file collects mistakes that cause flaky or wrong test results, plus the practical reference
tables for type casting and PostgreSQL error codes. Read when a test is failing for a
non-obvious reason or before a code review.

## Table of contents

1. [Anti-pattern catalog](#1-anti-pattern-catalog)
2. [Type casting in is() comparisons](#2-type-casting-in-is-comparisons)
3. [PostgreSQL error codes for throws_ok](#3-postgresql-error-codes-for-throws_ok)
4. [Diagnostic interpretation cheat sheet](#4-diagnostic-interpretation-cheat-sheet)

---

## 1. Anti-pattern catalog

| Anti-pattern | What it looks like | Why it's wrong | Correct approach |
|--------------|-------------------|----------------|------------------|
| **Testing PostgreSQL itself** | `SELECT is((SELECT 1+1), 2)` | Tests PostgreSQL arithmetic, not your code | Test YOUR constraints, functions, triggers |
| **Non-deterministic ordering** | `results_eq` without `ORDER BY` | Row order is undefined; tests become flaky | Always use `ORDER BY`, or prefer `set_eq` / `bag_eq` |
| **Asserting auto-generated IDs** | `is(id, 1, 'first user')` | SERIAL/IDENTITY sequences advance permanently, even after `ROLLBACK` | Test by business key (email, name), not synthetic ID |
| **PREPARE leak** | Forgetting `DEALLOCATE` | "prepared statement already exists" on second run | Always `DEALLOCATE` before `finish()` |
| **Mega-test files** | One file with 200 assertions | Hard to isolate failures, slow to debug | One file per object or concern; ≤30 assertions per file |
| **Testing implementation details** | Checking internal variable values, exact SQL strings | Breaks when implementation changes | Test inputs → outputs and side effects only |
| **Ignoring NULL** | Only testing happy paths | NULL is the #1 source of database bugs | Always test NULL parameters explicitly |
| **Brittle type assertions** | `col_type_is('users', 'name', 'varchar')` | Fails — PostgreSQL stores it as `character varying` | Use exact PostgreSQL type names: `character varying(255)` |
| **Localized error messages** | `throws_ok(sql, '23502', 'cannot be null')` | Fails on non-English PG installations | Pass `NULL` for the error message; rely on the code |
| **Hard-coded timestamps** | `is(created_at, '2024-01-15'::timestamp)` | Tests fail tomorrow | Use `NOW()`, `CURRENT_DATE`, or capture with `RETURNING` |
| **Forgetting to rollback DDL test changes** | `CREATE INDEX` with no transaction wrapper | Index leaks into the test database | Always wrap in `BEGIN`/`ROLLBACK` |
| **Mixing CREATE EXTENSION with tests** | `CREATE EXTENSION pgtap` inside the test | Tests can't be re-run | Install extensions once, outside the test file |
| **Asserting nothing** | Test file with `plan(0)` | Plan completes but nothing is verified | If you have nothing to assert, delete the file |

### 1.1 Detail: the PREPARE leak

```sql
-- BUG: this runs once, fails on second run
BEGIN;
SELECT plan(1);
PREPARE bad_insert AS INSERT INTO t VALUES (NULL);
SELECT throws_ok('bad_insert', '23502', NULL, 'NULL violates NOT NULL');
SELECT * FROM finish();
ROLLBACK;
```

Even though the transaction is rolled back, **prepared statements live at the session level,
not the transaction level**. `ROLLBACK` does NOT deallocate them. Re-running the file in the
same session causes:

```
ERROR:  prepared statement "bad_insert" already exists
```

**Fix**: always DEALLOCATE before `finish()`:

```sql
BEGIN;
SELECT plan(1);
PREPARE bad_insert AS INSERT INTO t VALUES (NULL);
SELECT throws_ok('bad_insert', '23502', NULL, 'NULL violates NOT NULL');
DEALLOCATE bad_insert;       -- ← critical
SELECT * FROM finish();
ROLLBACK;
```

Or use anonymous SQL strings (no PREPARE, no leak):

```sql
SELECT throws_ok(
    $$INSERT INTO t VALUES (NULL)$$,
    '23502', NULL,
    'NULL violates NOT NULL'
);
```

The dollar-quoted form is preferred for one-shot tests; PREPARE is only worth it when the same
statement is reused with different parameters across multiple assertions.

### 1.2 Detail: SERIAL / IDENTITY leakage

```sql
BEGIN;
SELECT plan(1);
INSERT INTO users (email) VALUES ('a@test.com') RETURNING id;
-- ROLLBACK happens, but the sequence has advanced anyway
SELECT * FROM finish();
ROLLBACK;
```

After `ROLLBACK`, the `users.id` sequence has still incremented. The next `INSERT` (in any
test or session) will get a higher ID. Tests that hard-code `is(id, 1, ...)` work the first
time and break thereafter.

**Always test by business key, never by surrogate ID**:

```sql
-- WRONG
SELECT is(id, 1, 'first user has id 1') FROM users WHERE email = 'a@test.com';

-- RIGHT
SELECT isnt_empty($$SELECT 1 FROM users WHERE email = 'a@test.com'$$, 'user was created');
```

### 1.3 Detail: localized error messages

PostgreSQL emits error messages in the locale set by `lc_messages`. The text of `not-null
violation` is `not-null violation` in English but `Verstoß gegen Not-Null-Bedingung` in
German. If a CI runner uses a non-English locale, message-based tests fail mysteriously.

**Always pass `NULL` for the message argument** to `throws_ok`:

```sql
SELECT throws_ok(
    $$INSERT INTO users (email) VALUES (NULL)$$,
    '23502',                                -- error code
    NULL,                                   -- ← skip message check
    'NULL email should violate NOT NULL'    -- description (your text, not PG's)
);
```

You only need the `errmsg` argument when testing custom `RAISE EXCEPTION` strings that you
yourself wrote (those don't get translated).

### 1.4 Detail: type-name strictness

`col_type_is` compares against PostgreSQL's internal type representation, which always uses
canonical names with full parameters:

| You wrote | What PG stores | Comparison result |
|-----------|----------------|-------------------|
| `varchar(255)` | `character varying(255)` | FAIL |
| `int` | `integer` | OK (alias resolved) |
| `int4` | `integer` | OK (alias resolved) |
| `decimal(10,2)` | `numeric(10,2)` | OK (alias resolved) |
| `timestamptz` | `timestamp with time zone` | FAIL — must use full form |
| `uuid` | `uuid` | OK |
| `text[]` | `text[]` | OK |
| `interval hour to minute` | `interval hour to minute` | OK |

If unsure, query the actual stored form:

```sql
SELECT format_type(atttypid, atttypmod) FROM pg_attribute
WHERE attrelid = 'public.users'::regclass AND attname = 'email';
```

---

## 2. Type casting in `is()` comparisons

`is()` uses `IS NOT DISTINCT FROM`, which is NULL-safe but type-strict. Mismatched types fail
even when values look equal.

### 2.1 The `count(*)` trap

`count(*)` returns `bigint`, not `integer`:

```sql
-- WRONG: bigint vs integer mismatch
SELECT is(count(*), 5, 'should have 5 rows');

-- RIGHT — cast either side
SELECT is(count(*)::integer, 5, 'should have 5 rows');
SELECT is((SELECT count(*) FROM users), 5::bigint, 'should have 5 rows');
```

### 2.2 Common cast patterns

| Data type | Cast pattern | Example |
|-----------|-------------|---------|
| Integer | `::integer` | `is(result, 42::integer, 'msg')` |
| Bigint | `::bigint` | `is(count, 1000::bigint, 'msg')` |
| Numeric | `::numeric` | `is(total, 99.95::numeric, 'msg')` |
| Text | `::text` | `is(name, 'Alice'::text, 'msg')` |
| Boolean | `::boolean` | `is(active, true, 'msg')` (no cast needed) |
| UUID | `::uuid` | `is(id, 'a0eebc99-...'::uuid, 'msg')` |
| JSONB | `::jsonb` | `is(data, '{"k":"v"}'::jsonb, 'msg')` |
| Timestamptz | `::timestamptz` | `is(created, '2024-01-01 00:00:00+00'::timestamptz, 'msg')` |
| Date | `::date` | `is(birthday, '1990-05-15'::date, 'msg')` |
| Array | `::type[]` | `is(tags, ARRAY['a','b']::text[], 'msg')` |
| Interval | `::interval` | `is(duration, '2 hours'::interval, 'msg')` |
| Domain (e.g., `email`) | `::email` | `is(addr, 'a@b.com'::email, 'msg')` |
| Composite type | `::row_type` | `is(rec, ROW(1, 'Alice')::users, 'msg')` |

### 2.3 NULL casts

When asserting NULL, cast to the expected type so pgTAP can format the diagnostic correctly:

```sql
-- Avoids "could not determine polymorphic type" error
SELECT is(get_user(999), NULL::users, 'missing user returns NULL');
```

---

## 3. PostgreSQL error codes for `throws_ok`

The most-used error codes, grouped by likelihood of appearing in your tests.

### 3.1 Constraint violations (class 23)

| Code | Name | Triggered by |
|------|------|--------------|
| `23502` | `not_null_violation` | INSERT NULL into NOT NULL column |
| `23503` | `foreign_key_violation` | INSERT with non-existent FK reference (or DELETE breaks one) |
| `23505` | `unique_violation` | INSERT duplicate into UNIQUE column |
| `23514` | `check_violation` | INSERT/UPDATE violating CHECK constraint |
| `23P01` | `exclusion_violation` | INSERT violating EXCLUDE constraint (e.g., overlapping dates) |
| `23001` | `restrict_violation` | RESTRICT action prevents UPDATE/DELETE |

### 3.2 Data and value errors (class 22)

| Code | Name | Triggered by |
|------|------|--------------|
| `22001` | `string_data_right_truncation` | String too long for column |
| `22003` | `numeric_value_out_of_range` | Number too large for type |
| `22004` | `null_value_not_allowed` | NULL where not permitted (function args) |
| `22007` | `invalid_datetime_format` | Bad date/time string |
| `22008` | `datetime_field_overflow` | Date arithmetic overflow |
| `22012` | `division_by_zero` | `x / 0` |
| `22023` | `invalid_parameter_value` | Function called with bad parameter |
| `22P02` | `invalid_text_representation` | `'abc'::integer` |

### 3.3 Authorization (class 42 except syntax)

| Code | Name | Triggered by |
|------|------|--------------|
| `42501` | `insufficient_privilege` | RLS denial, GRANT failure |
| `42P01` | `undefined_table` | Table does not exist |
| `42883` | `undefined_function` | Function does not exist |
| `42703` | `undefined_column` | Column does not exist |
| `42P02` | `undefined_parameter` | `:param` reference not bound |
| `42704` | `undefined_object` | Generic "doesn't exist" |
| `42710` | `duplicate_object` | CREATE on existing object |
| `42P07` | `duplicate_table` | CREATE TABLE on existing |

### 3.4 Custom raises (class P0)

| Code | Name | Triggered by |
|------|------|--------------|
| `P0001` | `raise_exception` | `RAISE EXCEPTION 'msg'` in PL/pgSQL (no SQLSTATE specified) |
| `P0002` | `no_data_found` | `GET DIAGNOSTICS` finds nothing |
| `P0003` | `too_many_rows` | `INTO` receives multiple rows |
| `P0004` | `assert_failure` | `ASSERT condition` fails |

For custom `RAISE`, you can specify any 5-character SQLSTATE:

```sql
RAISE EXCEPTION USING ERRCODE = 'XX001', MESSAGE = 'business rule violated';
```

The full appendix is at <https://www.postgresql.org/docs/current/errcodes-appendix.html>.

### 3.5 Standard usage pattern

```sql
SELECT throws_ok(
    $$INSERT INTO users (email) VALUES (NULL)$$,
    '23502',                              -- ← error code only
    NULL,                                 -- ← skip message (locale-safe)
    'NULL email should violate NOT NULL'  -- ← your test description
);
```

---

## 4. Diagnostic interpretation cheat sheet

When a test fails, the `# `-prefixed lines tell you why. Common patterns:

### `have:` / `want:` (from `is`)

```
not ok 5 - balance is correct
#         have: 100.00
#         want: 95.00
```

→ The function returned 100.00 but you expected 95.00. Compare types too — `100` vs `100.00`
might just be a missing `::numeric` cast.

### `caught:` / `wanted:` (from `throws_ok`)

```
not ok 7 - should reject duplicate email
#       caught: no exception
#       wanted: 23505
```

→ The function did NOT raise an exception. Either the constraint is missing, or the input
didn't actually violate it.

```
not ok 8 - should reject negative quantity
#       caught: 23502: null value in column "quantity" violates not-null constraint
#       wanted: P0001: quantity must be positive
```

→ Different error fired than expected. Your input is hitting a different validation rule first.

### `Extra records:` / `Missing records:` (from `set_eq` / `bag_eq`)

```
not ok 12 - active users
#     Extra records:
#         (1, 'duplicate@test.com')
#     Missing records:
#         (5, 'expected@test.com')
```

→ Set membership doesn't match. Extras are rows present that shouldn't be; Missing are rows
absent that should be there.

### `Results differ beginning at row N:` (from `results_eq`)

```
not ok 14
#     Results differ beginning at row 3:
#         have: (1, 'Anna')
#         want: (22, 'Betty')
```

→ Order-sensitive comparison failed at row 3. Either fix `ORDER BY`, or switch to `set_eq` if
order doesn't matter.

### Plan mismatch

```
# Looks like you planned 8 tests but ran 7
```

→ You declared `plan(8)` but only 7 assertions executed. Check for:
- An assertion inside a `CASE WHEN ... ELSE` branch that didn't fire
- An early `RETURN` or exception in a function
- A comment that accidentally commented out an assertion

```
# Looks like you planned 8 tests but ran 9
```

→ You declared too few. An assertion got duplicated, or you added one without bumping the count.

### Type mismatch in `is`

```
not ok 5 - count
#         have: 5
#         want: 5
```

Yes — they look identical. This is almost always a type mismatch. `5` (text) and `5` (integer)
print the same but `IS NOT DISTINCT FROM` says they're different. Cast both sides explicitly.

---

## 5. Pre-commit checklist

Before merging a test file, verify:

- [ ] `plan(N)` matches actual assertion count
- [ ] Every `PREPARE` has a matching `DEALLOCATE` before `finish()`
- [ ] No assertions on `SERIAL` / `IDENTITY` IDs
- [ ] `set_eq` used instead of `results_eq`, OR `results_eq` paired with explicit `ORDER BY`
- [ ] `throws_ok` calls pass `NULL` for the error message (unless testing a custom RAISE)
- [ ] At least one NULL parameter test for every function/procedure
- [ ] At least one error case (`throws_ok`) for every function/procedure
- [ ] File contains `BEGIN;` at top and `SELECT * FROM finish(); ROLLBACK;` at bottom
- [ ] File name follows `test_<schema>_<object>.sql` convention
- [ ] No CREATE EXTENSION inside the test file
- [ ] Test runs cleanly with `--shuffle` (i.e., is not order-dependent)
