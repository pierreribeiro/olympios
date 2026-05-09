# Object Recipes — End-to-End Test Patterns by Database Object

This file contains complete, copy-ready recipes for testing each PostgreSQL object type. Each
recipe shows: structure tests + setup + behavior tests + edge cases + error cases.

Read only the section matching the object you're testing.

## Table of contents

1. [Tables](#1-tables)
2. [Functions](#2-functions)
3. [Procedures](#3-procedures)
4. [Triggers](#4-triggers)
5. [Views](#5-views)
6. [Materialized views](#6-materialized-views)
7. [Indexes](#7-indexes)
8. [Constraints](#8-constraints)
9. [RLS policies](#9-rls-policies)
10. [Sequences](#10-sequences)
11. [Enums and custom types](#11-enums-and-custom-types)

---

## 1. Tables

Table tests cover existence, exact column set, primary key, foreign keys, NOT NULL constraints,
UNIQUE constraints, and CHECK constraints.

```sql
-- tests/structure/test_users_table.sql
BEGIN;
SELECT plan(11);

-- ============================================================
-- SECTION 1: Structure / Existence
-- ============================================================

SELECT has_table('public', 'users', 'users table should exist');

SELECT columns_are(
    'public', 'users',
    ARRAY['id', 'email', 'name', 'active', 'created_at'],
    'users should have exactly these columns'
);

SELECT col_type_is('public', 'users', 'id', 'integer', 'id should be integer');
SELECT col_type_is('public', 'users', 'email', 'character varying(255)', 'email should be varchar(255)');
SELECT col_type_is('public', 'users', 'created_at', 'timestamp with time zone', 'created_at should be timestamptz');

-- Primary key
SELECT has_pk('public', 'users', 'users should have a primary key');
SELECT col_is_pk('public', 'users', 'id', 'id should be the primary key');

-- NOT NULL constraints
SELECT col_not_null('public', 'users', 'email', 'email should be NOT NULL');
SELECT col_not_null('public', 'users', 'created_at', 'created_at should be NOT NULL');

-- UNIQUE constraint
SELECT col_is_unique('public', 'users', 'email', 'email should be UNIQUE');

-- Default value
SELECT col_default_is('public', 'users', 'active', 'true', 'active should default to true');

SELECT * FROM finish();
ROLLBACK;
```

**Notes**
- `columns_are` enforces an exact match — extra or missing columns fail. This catches schema drift.
- For foreign keys, use `fk_ok(fk_table, fk_col, pk_table, pk_col, desc)` rather than `col_is_fk`
  alone — it verifies both sides of the relationship.
- For CHECK constraints, use `has_check` (constraint exists) plus an INSERT-based behavioral
  test (see § 8 Constraints).

---

## 2. Functions

Function tests cover existence with signature, return type, language, happy paths, NULL
handling, and error cases.

```sql
-- tests/functions/test_calculate_order_total.sql
BEGIN;
SELECT plan(10);

-- ============================================================
-- SECTION 1: Structure / Existence
-- ============================================================

SELECT has_function(
    'public', 'calculate_order_total', ARRAY['integer'],
    'calculate_order_total(integer) should exist'
);

SELECT function_returns(
    'public', 'calculate_order_total', ARRAY['integer'],
    'numeric',
    'should return numeric'
);

SELECT function_lang_is(
    'public', 'calculate_order_total', ARRAY['integer'],
    'plpgsql',
    'should be plpgsql'
);

SELECT is_normal_function(
    'public', 'calculate_order_total', ARRAY['integer'],
    'should be a function, not a procedure or aggregate'
);

-- ============================================================
-- SECTION 2: Setup test data
-- ============================================================

INSERT INTO orders (id) VALUES (1), (2), (3);
INSERT INTO order_items (order_id, quantity, unit_price) VALUES
    (1, 2, 25.00),    -- order 1: total = 50.00 (no discount)
    (2, 5, 30.00);    -- order 2: total = 150.00 → 135.00 with 10% discount

-- ============================================================
-- SECTION 3: Happy path behavior
-- ============================================================

SELECT is(
    calculate_order_total(1),
    50.00::numeric,
    'order under 100 should have no discount'
);

SELECT is(
    calculate_order_total(2),
    135.00::numeric,
    'order over 100 should have 10% discount'
);

-- ============================================================
-- SECTION 4: Edge cases
-- ============================================================

SELECT is(
    calculate_order_total(3),
    0.00::numeric,
    'order with no items should return 0'
);

SELECT is(
    calculate_order_total(NULL),
    NULL::numeric,
    'NULL order_id should return NULL'
);

-- ============================================================
-- SECTION 5: Error cases
-- ============================================================

SELECT throws_ok(
    $$SELECT calculate_order_total(-1)$$,
    'P0001',
    'order_id must be positive',
    'negative order_id should raise P0001'
);

-- ============================================================
-- SECTION 6: Cleanup
-- ============================================================

SELECT * FROM finish();
ROLLBACK;
```

**Why `function_lang_is`?** Confirms PL/pgSQL vs SQL vs PL/Python. A function silently
re-implemented in a different language is a regression.

**Why test NULL explicitly?** NULL is the #1 source of database bugs. Always verify the
function's NULL contract is what you intended.

**Why use `is_normal_function`?** Distinguishes normal functions from aggregates, window
functions, and procedures — useful when migrating from SQL Server where this distinction
is fuzzier.

---

## 3. Procedures

Procedures differ from functions: `CALL` instead of `SELECT`, no return value, possible
internal `COMMIT`/`ROLLBACK`. Test side effects, not return values.

```sql
-- tests/procedures/test_process_batch.sql
BEGIN;
SELECT plan(7);

-- ============================================================
-- SECTION 1: Structure / Existence
-- ============================================================

SELECT has_function(
    'public', 'process_batch', ARRAY['date', 'date'],
    'process_batch should exist'
);

SELECT is_procedure(
    'public', 'process_batch', ARRAY['date', 'date'],
    'process_batch should be a procedure, not a function'
);

-- ============================================================
-- SECTION 2: Setup test data
-- ============================================================

INSERT INTO raw_records (record_date, status, amount) VALUES
    ('2024-01-15', 'pending', 100.00),
    ('2024-01-20', 'pending', 200.00),
    ('2024-02-05', 'pending', 300.00);  -- outside range

-- ============================================================
-- SECTION 3: Happy path behavior
-- ============================================================

SELECT lives_ok(
    $$CALL process_batch('2024-01-01'::date, '2024-01-31'::date)$$,
    'process_batch executes without error for valid date range'
);

-- Verify side effect: correct number of records processed
SELECT is(
    (SELECT count(*)::integer FROM processed_records
     WHERE batch_start = '2024-01-01'),
    2,
    'should process exactly 2 records in January'
);

-- Verify exclusion: out-of-range records NOT processed
SELECT is(
    (SELECT count(*)::integer FROM processed_records
     WHERE batch_start = '2024-02-01'),
    0,
    'should not process February records'
);

-- ============================================================
-- SECTION 4: Edge cases
-- ============================================================

-- Empty range
SELECT lives_ok(
    $$CALL process_batch('2099-01-01'::date, '2099-01-31'::date)$$,
    'should handle empty result set without error'
);

-- ============================================================
-- SECTION 5: Error cases
-- ============================================================

SELECT throws_ok(
    $$CALL process_batch(NULL, '2024-01-31'::date)$$,
    'P0001',
    NULL,
    'NULL start_date should raise error'
);

SELECT * FROM finish();
ROLLBACK;
```

**Critical caveat**: if `process_batch` calls `COMMIT` internally, this approach BREAKS — the
procedure ends the test's outer transaction. See `references/advanced-patterns.md` § 1
"Transaction control problem" for the three workarounds (refactor, dedicated DB, run outside
transaction).

---

## 4. Triggers

Test what the trigger DOES (behavior), not HOW (internals).

```sql
-- tests/triggers/test_audit_trigger.sql
BEGIN;
SELECT plan(6);

-- ============================================================
-- SECTION 1: Structure / Existence
-- ============================================================

SELECT has_trigger(
    'public', 'products', 'trg_product_audit',
    'audit trigger should exist on products'
);

SELECT trigger_is(
    'public', 'products', 'trg_product_audit',
    'public', 'fn_log_product_changes',
    'trigger should call fn_log_product_changes'
);

-- ============================================================
-- SECTION 2: Setup test data
-- ============================================================

INSERT INTO products (id, name, price) VALUES (1, 'Widget', 9.99);

-- ============================================================
-- SECTION 3: Happy path behavior — UPDATE fires the trigger
-- ============================================================

UPDATE products SET price = 24.99 WHERE id = 1;

SELECT is(
    (SELECT count(*)::integer FROM audit_log
     WHERE table_name = 'products' AND record_id = 1),
    1,
    'UPDATE should create exactly one audit entry'
);

SELECT is(
    (SELECT old_value FROM audit_log
     WHERE table_name = 'products' AND column_name = 'price' AND record_id = 1),
    '9.99',
    'audit should log old price value'
);

-- ============================================================
-- SECTION 4: Negative behavior — INSERT does NOT fire if UPDATE-only
-- ============================================================

INSERT INTO products (id, name, price) VALUES (2, 'Gadget', 19.99);

SELECT is(
    (SELECT count(*)::integer FROM audit_log
     WHERE table_name = 'products' AND record_id = 2),
    0,
    'INSERT should not create audit entry for UPDATE-only trigger'
);

-- ============================================================
-- SECTION 5: DELETE fires the trigger
-- ============================================================

DELETE FROM products WHERE id = 1;

SELECT is(
    (SELECT count(*)::integer FROM audit_log
     WHERE table_name = 'products' AND record_id = 1 AND operation = 'DELETE'),
    1,
    'DELETE should create audit entry'
);

SELECT * FROM finish();
ROLLBACK;
```

**Pattern**: structural tests (`has_trigger`, `trigger_is`) verify wiring, behavioral tests
verify the effect. If the trigger has multiple events (INSERT, UPDATE, DELETE), test each
explicitly — including the events the trigger should NOT fire on.

---

## 5. Views

Views are tested for existence, exact column set, and result correctness under varying input.

```sql
-- tests/views/test_active_users_view.sql
BEGIN;
SELECT plan(5);

-- ============================================================
-- SECTION 1: Structure / Existence
-- ============================================================

SELECT has_view(
    'public', 'v_active_users',
    'active users view should exist'
);

SELECT columns_are(
    'public', 'v_active_users',
    ARRAY['id', 'email', 'name', 'last_login'],
    'view should expose exactly these columns'
);

-- ============================================================
-- SECTION 2: Setup test data
-- ============================================================

INSERT INTO users (id, email, name, active, last_login) VALUES
    (1, 'alice@test.com', 'Alice',  true,  '2024-01-15'),
    (2, 'bob@test.com',   'Bob',    false, '2024-01-10'),
    (3, 'carol@test.com', 'Carol',  true,  '2024-01-20');

-- ============================================================
-- SECTION 3: Happy path — view filters correctly
-- ============================================================

SELECT set_eq(
    'SELECT email FROM v_active_users',
    ARRAY['alice@test.com', 'carol@test.com'],
    'view should return only active users'
);

SELECT set_hasnt(
    'SELECT email FROM v_active_users',
    ARRAY['bob@test.com'],
    'view should not include inactive users'
);

-- ============================================================
-- SECTION 4: Edge case — empty view when no active users
-- ============================================================

UPDATE users SET active = false;

SELECT is_empty(
    'SELECT * FROM v_active_users',
    'view should be empty when no active users exist'
);

SELECT * FROM finish();
ROLLBACK;
```

**Use `set_eq` not `results_eq` for views** unless you can guarantee row order with `ORDER BY`.
Views without an explicit ordering can return rows in any order across PostgreSQL versions.

---

## 6. Materialized views

Like views, but you also need to test the post-`REFRESH` state.

```sql
BEGIN;
SELECT plan(4);

SELECT has_materialized_view('public', 'mv_daily_summary');

SELECT columns_are('public', 'mv_daily_summary',
    ARRAY['day', 'total_orders', 'total_revenue']);

-- Seed underlying data
INSERT INTO orders (created_at, amount) VALUES
    ('2024-01-15', 100.00),
    ('2024-01-15', 50.00);

-- Refresh and verify
REFRESH MATERIALIZED VIEW mv_daily_summary;

SELECT is(
    (SELECT total_orders::integer FROM mv_daily_summary WHERE day = '2024-01-15'),
    2,
    'should aggregate orders per day'
);

SELECT is(
    (SELECT total_revenue FROM mv_daily_summary WHERE day = '2024-01-15'),
    150.00::numeric,
    'should sum revenue per day'
);

SELECT * FROM finish();
ROLLBACK;
```

---

## 7. Indexes

Indexes are tested for existence, type, uniqueness, partial conditions, and (optionally) actual
performance benefit.

```sql
BEGIN;
SELECT plan(4);

SELECT has_index(
    'public', 'orders', 'idx_orders_customer_date',
    ARRAY['customer_id', 'order_date'],
    'compound index on customer_id, order_date'
);

SELECT index_is_type(
    'public', 'orders', 'idx_orders_customer_date',
    'btree',
    'should be a btree index'
);

SELECT index_is_unique(
    'public', 'users', 'users_email_key',
    'email index should be unique'
);

-- Performance check (optional, frequently flaky in CI)
SELECT performs_ok(
    $$SELECT * FROM orders WHERE customer_id = 1 AND order_date > '2024-01-01'$$,
    50,  -- milliseconds
    'compound index lookup should be under 50ms'
);

SELECT * FROM finish();
ROLLBACK;
```

`is_indexed(schema, table, column_or_array)` is a higher-level alternative — it just checks
that some index covers the given column(s) without caring about the specific index name.

---

## 8. Constraints

Test both **acceptance** (valid data passes) and **rejection** (invalid data fails). The
rejection tests are where constraints earn their keep.

```sql
-- tests/constraints/test_booking_constraints.sql
BEGIN;
SELECT plan(7);

-- ============================================================
-- SECTION 1: Structure
-- ============================================================

SELECT has_pk('public', 'bookings', 'bookings should have primary key');
SELECT col_not_null('public', 'bookings', 'room_number', 'room_number is NOT NULL');
SELECT col_not_null('public', 'bookings', 'check_in', 'check_in is NOT NULL');
SELECT has_check('public', 'bookings', 'bookings should have CHECK constraints');

-- ============================================================
-- SECTION 2: Acceptance — valid data succeeds
-- ============================================================

PREPARE valid_booking AS
    INSERT INTO bookings (room_number, check_in, check_out, guest_name)
    VALUES (310, '2024-07-01', '2024-07-05', 'Ada Lovelace');

SELECT lives_ok('valid_booking', 'valid booking should succeed');

-- ============================================================
-- SECTION 3: Rejection — overlapping dates fail (exclusion)
-- ============================================================

PREPARE overlapping AS
    INSERT INTO bookings (room_number, check_in, check_out, guest_name)
    VALUES (310, '2024-07-03', '2024-07-08', 'Grace Hopper');

SELECT throws_ok(
    'overlapping',
    '23P01',  -- exclusion_violation
    NULL,
    'overlapping booking should violate exclusion constraint'
);

-- ============================================================
-- SECTION 4: Rejection — check_out before check_in fails (CHECK)
-- ============================================================

PREPARE invalid_dates AS
    INSERT INTO bookings (room_number, check_in, check_out, guest_name)
    VALUES (311, '2024-07-05', '2024-07-01', 'Alan Turing');

SELECT throws_ok(
    'invalid_dates',
    '23514',  -- check_violation
    NULL,
    'check_out before check_in should violate CHECK constraint'
);

-- ============================================================
-- SECTION 6: Cleanup
-- ============================================================

DEALLOCATE valid_booking;
DEALLOCATE overlapping;
DEALLOCATE invalid_dates;

SELECT * FROM finish();
ROLLBACK;
```

**Always `DEALLOCATE`** prepared statements. Without it, re-running the script fails with
"prepared statement already exists". This is the #1 cause of "tests that worked yesterday and
not today" complaints.

**Pass `NULL` as the error message argument** to `throws_ok` to skip the message check —
otherwise localized PostgreSQL builds (German, Portuguese, etc.) cause spurious failures.

---

## 9. RLS policies

RLS testing requires role switching. Key insight: **blocked SELECT returns empty results
(not an error), while blocked INSERT/UPDATE/DELETE throws `42501`**.

```sql
-- tests/rls/test_post_policies.sql
BEGIN;
SELECT plan(5);

-- ============================================================
-- SECTION 1: Structure
-- ============================================================

SELECT policies_are(
    'public', 'posts',
    ARRAY['owner_select', 'owner_insert', 'owner_update'],
    'posts should have exactly these policies'
);

SELECT policy_cmd_is(
    'public', 'posts', 'owner_select',
    'select',
    'owner_select should apply to SELECT'
);

-- ============================================================
-- SECTION 2: Setup as superuser
-- ============================================================

INSERT INTO users (id, email) VALUES (1, 'alice@test.com'), (2, 'bob@test.com');
INSERT INTO posts (id, user_id, content) VALUES (1, 1, 'Alice post');

-- ============================================================
-- SECTION 3: Owner can see own post
-- ============================================================

SET ROLE app_user;
SET request.jwt.claim.sub = '1';

SELECT isnt_empty(
    $$SELECT * FROM posts WHERE user_id = 1$$,
    'Alice can see her own post'
);

-- ============================================================
-- SECTION 4: Non-owner sees nothing (NOT an error)
-- ============================================================

SET request.jwt.claim.sub = '2';

SELECT is_empty(
    $$SELECT * FROM posts WHERE user_id = 1$$,
    'Bob cannot see Alice posts (returns empty)'
);

-- ============================================================
-- SECTION 5: Non-owner INSERT throws 42501
-- ============================================================

SELECT throws_ok(
    $$INSERT INTO posts (user_id, content) VALUES (1, 'Impersonation')$$,
    '42501',
    NULL,
    'Cannot insert as another user'
);

RESET ROLE;
SELECT * FROM finish();
ROLLBACK;
```

For more advanced RLS patterns (multiple roles in one test, JWT claim simulation, policy
tenancy testing), see `references/advanced-patterns.md` § 3 "RLS testing".

---

## 10. Sequences

```sql
BEGIN;
SELECT plan(2);

SELECT has_sequence(
    'public', 'orders_id_seq',
    'orders_id_seq should exist'
);

SELECT sequence_owner_is(
    'public', 'orders_id_seq',
    'app_user',
    'orders_id_seq should be owned by app_user'
);

SELECT * FROM finish();
ROLLBACK;
```

**Avoid asserting current sequence values** — sequences advance permanently and don't roll back
with the transaction. Test ownership and existence, not state.

---

## 11. Enums and custom types

```sql
BEGIN;
SELECT plan(3);

SELECT has_enum(
    'public', 'order_status',
    'order_status enum should exist'
);

SELECT enum_has_labels(
    'public', 'order_status',
    ARRAY['pending', 'paid', 'shipped', 'cancelled'],
    'order_status should have exactly these labels'
);

-- Composite type
SELECT has_composite(
    'public', 'address',
    'address composite type should exist'
);

SELECT * FROM finish();
ROLLBACK;
```

**Note**: PostgreSQL stores enum labels in the order declared, but `enum_has_labels` is order
sensitive — labels must be in the same order they were created. If you need to add a label
later, `ALTER TYPE … ADD VALUE … BEFORE …` and update the test array accordingly.
