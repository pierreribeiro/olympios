# Advanced Patterns

This file covers patterns that don't fit the standard `BEGIN`/`assertions`/`ROLLBACK` shape.
Read only if you face one of these specific situations.

## Table of contents

1. [Transaction control problem (procedures with COMMIT/ROLLBACK)](#1-transaction-control-problem)
2. [Testing temporary tables](#2-testing-temporary-tables)
3. [RLS testing with role switching](#3-rls-testing-with-role-switching)
4. [Mocking via transactional DDL](#4-mocking-via-transactional-ddl)
5. [Testing SECURITY DEFINER functions](#5-testing-security-definer-functions)
6. [Testing dynamic SQL (EXECUTE)](#6-testing-dynamic-sql)
7. [Migration equivalence (SQL Server / Oracle → PostgreSQL)](#7-migration-equivalence)
8. [Testing partitioned tables](#8-testing-partitioned-tables)
9. [Cross-version conditional tests](#9-cross-version-conditional-tests)

---

## 1. Transaction control problem

**The problem**: pgTAP tests wrap in `BEGIN`/`ROLLBACK`. If a procedure calls `COMMIT` internally,
it ends the test's outer transaction. The test's final `ROLLBACK` then has nothing to undo —
test data leaks into the database.

You'll see this happen with procedures used for batch ETL, autonomous logging, or anything that
explicitly controls transactions.

There are three workarounds, in order of preference.

### Strategy 1 — Refactor to avoid internal COMMIT (preferred)

Convert the procedure to use SAVEPOINTs, or extract the logic into a function (functions can't
COMMIT) and let the procedure be a thin wrapper:

```sql
-- Function contains all testable logic — no COMMIT
CREATE FUNCTION fn_process_batch_logic(p_start date, p_end date)
RETURNS integer LANGUAGE plpgsql AS $$
DECLARE
    v_count integer;
BEGIN
    -- business logic
    UPDATE raw_records SET status = 'processed'
    WHERE record_date BETWEEN p_start AND p_end;
    GET DIAGNOSTICS v_count = ROW_COUNT;
    RETURN v_count;
END;
$$;

-- Procedure is a thin wrapper for transaction control
CREATE PROCEDURE process_batch(p_start date, p_end date) LANGUAGE plpgsql AS $$
BEGIN
    PERFORM fn_process_batch_logic(p_start, p_end);
    COMMIT;
END;
$$;
```

Now you test `fn_process_batch_logic()` — the function — with normal pgTAP. The procedure is a
thin wrapper that doesn't need unit testing; integration tests cover it.

**This is almost always the right answer.** Procedures with internal COMMIT are usually that
way for two reasons: (a) they want to chunk work into separate transactions, or (b) they were
auto-converted from SQL Server. Both can be addressed by extracting logic into a function.

### Strategy 2 — Dedicated test database

For procedures that genuinely need internal COMMIT (chunked batch processing, streaming ETL),
use a disposable test database:

```bash
#!/bin/bash
# test_with_commit.sh
set -e
createdb test_batch
psql -d test_batch -c "CREATE EXTENSION pgtap;"
psql -d test_batch -f schema.sql
psql -d test_batch -f seed_test_data.sql
psql -d test_batch -c "CALL process_batch('2024-01-01', '2024-01-31')"
pg_prove -d test_batch tests/integration/verify_batch_results.sql
dropdb test_batch
```

The test file (`tests/integration/verify_batch_results.sql`) checks the final state after the
procedure has run:

```sql
BEGIN;
SELECT plan(3);
SELECT is(
    (SELECT count(*)::integer FROM processed_records),
    150, 'should process 150 records'
);
SELECT is(
    (SELECT sum(amount)::numeric FROM processed_records),
    50000.00::numeric, 'total amount should be 50,000'
);
SELECT * FROM finish();
ROLLBACK;
```

### Strategy 3 — Run the procedure outside the test transaction

Skip the BEGIN/ROLLBACK around the procedure call, then verify in a separate test block. You
must clean up manually because nothing rolls back:

```sql
-- Step 1: Setup data (no transaction wrapper)
INSERT INTO raw_records (record_date, status, amount) VALUES
    ('2024-01-15', 'pending', 100.00),
    ('2024-01-20', 'pending', 200.00);

-- Step 2: Run procedure (no transaction wrapper)
CALL process_batch('2024-01-01', '2024-01-31');

-- Step 3: Verify with pgTAP
BEGIN;
SELECT plan(2);
SELECT is(
    (SELECT count(*)::integer FROM processed_records
     WHERE batch_start = '2024-01-01'),
    2, 'should process exactly 2 records'
);
SELECT is(
    (SELECT count(*)::integer FROM raw_records WHERE status = 'pending'),
    0, 'all pending records should now be processed'
);
SELECT * FROM finish();
ROLLBACK;

-- Step 4: Manual cleanup
DELETE FROM processed_records WHERE batch_start = '2024-01-01';
DELETE FROM raw_records WHERE record_date BETWEEN '2024-01-01' AND '2024-01-31';
```

Strategy 3 is fragile — if any step fails, the database is left dirty. Prefer Strategy 1 or 2.

---

## 2. Testing temporary tables

Temporary tables are session-local and are NOT rolled back by `ROLLBACK` (they're dropped at
session end or on `ON COMMIT DROP`).

```sql
BEGIN;
SELECT plan(3);

-- Procedure that internally creates a temp table
SELECT lives_ok(
    $$CALL build_staging_data(100)$$,
    'procedure with temp tables executes without error'
);

-- Verify the temp table was created
SELECT is(
    (SELECT count(*)::integer FROM pg_catalog.pg_class
     WHERE relname = 'tmp_staging' AND relpersistence = 't'),
    1, 'temp table should exist after procedure call'
);

-- Verify temp table contents
SELECT is(
    (SELECT count(*)::integer FROM tmp_staging),
    100, 'temp table should have 100 rows'
);

SELECT * FROM finish();
ROLLBACK;
-- Note: the temp table persists until session end. ROLLBACK doesn't drop it.
```

If the procedure creates the temp table with `ON COMMIT DROP`, the temp table disappears at
ROLLBACK. In that case, verify within the transaction (before ROLLBACK), as shown above.

For stronger isolation, drop the temp table explicitly at the end of the test:

```sql
DROP TABLE IF EXISTS tmp_staging;
SELECT * FROM finish();
ROLLBACK;
```

This way subsequent tests in the same session start clean.

---

## 3. RLS testing with role switching

RLS testing requires switching identity within the test. Two key insights:

1. **Blocked SELECT returns empty results, not an error.** Test with `is_empty` /
   `isnt_empty`, never `throws_ok`.
2. **Blocked INSERT/UPDATE/DELETE throws `42501` (`insufficient_privilege`).**

### Setup: roles and policies

```sql
CREATE ROLE app_user;                                -- role apps connect as
CREATE TABLE posts (
    id serial PRIMARY KEY,
    user_id integer NOT NULL,
    content text
);
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;

CREATE POLICY owner_select ON posts FOR SELECT TO app_user
    USING (user_id = current_setting('app.current_user_id')::integer);

CREATE POLICY owner_insert ON posts FOR INSERT TO app_user
    WITH CHECK (user_id = current_setting('app.current_user_id')::integer);
```

### Test pattern

```sql
BEGIN;
SELECT plan(5);

-- Structure
SELECT policies_are('public', 'posts',
    ARRAY['owner_select', 'owner_insert'],
    'posts has expected policies');
SELECT policy_cmd_is('public', 'posts', 'owner_select', 'select');

-- Seed as superuser
INSERT INTO posts (id, user_id, content) VALUES (1, 1, 'Alice post');
INSERT INTO posts (id, user_id, content) VALUES (2, 2, 'Bob post');

-- Switch to alice
SET ROLE app_user;
SET app.current_user_id = '1';

SELECT isnt_empty(
    $$SELECT * FROM posts WHERE id = 1$$,
    'Alice can see her own post'
);

-- Switch to bob (still as app_user, just changing the GUC)
SET app.current_user_id = '2';

SELECT is_empty(
    $$SELECT * FROM posts WHERE id = 1$$,
    'Bob cannot see Alice posts (returns empty, not error)'
);

SELECT throws_ok(
    $$INSERT INTO posts (user_id, content) VALUES (1, 'Impersonation')$$,
    '42501', NULL,
    'Cannot insert as another user'
);

RESET ROLE;
SELECT * FROM finish();
ROLLBACK;
```

### Multi-role test pattern

When testing several roles in the same file, use `SET LOCAL` to make role/GUC changes
transaction-scoped (they revert at ROLLBACK):

```sql
BEGIN;
SELECT plan(2);

-- Test 1: as alice
SET LOCAL ROLE app_user;
SET LOCAL app.current_user_id = '1';
SELECT isnt_empty($$SELECT * FROM posts WHERE user_id = 1$$, 'Alice sees own');

-- Test 2: as bob (same transaction)
SET LOCAL app.current_user_id = '2';
SELECT is_empty($$SELECT * FROM posts WHERE user_id = 1$$, 'Bob does not see Alice');

SELECT * FROM finish();
ROLLBACK;
```

`SET LOCAL` keeps the change within the transaction; you don't need explicit `RESET ROLE` at
the end.

### Common RLS pitfalls

- **Forgetting `ENABLE ROW LEVEL SECURITY`**: policies exist but aren't enforced. Test for
  this with `is_indexed` / direct `pg_class` queries, or just write a deliberate negative
  test that should fail without RLS.
- **Superuser bypass**: superusers bypass RLS entirely. The seed phase is fine as superuser,
  but verification MUST happen as the restricted role.
- **`USING` vs `WITH CHECK`**: `USING` filters reads, `WITH CHECK` validates writes. Test
  both — they can have different conditions.

---

## 4. Mocking via transactional DDL

PostgreSQL allows `CREATE OR REPLACE FUNCTION` inside a transaction, which means you can
swap a function definition for a test, then ROLLBACK to restore the original.

```sql
BEGIN;
SELECT plan(1);

-- Original get_exchange_rate() does an HTTP call. Replace it with a deterministic mock.
CREATE OR REPLACE FUNCTION get_exchange_rate(currency text)
RETURNS numeric AS $$
BEGIN
    RETURN CASE currency WHEN 'EUR' THEN 1.25 WHEN 'GBP' THEN 1.50 ELSE 1.00 END;
END;
$$ LANGUAGE plpgsql;

-- Now test the dependent function
SELECT is(
    convert_price(100, 'EUR'),
    125.00::numeric,
    'price conversion should use exchange rate'
);

SELECT * FROM finish();
ROLLBACK;
-- ROLLBACK restores the original get_exchange_rate(). Other tests are unaffected.
```

This works for any DDL: `CREATE OR REPLACE FUNCTION`, `CREATE TABLE`, `ALTER TABLE`, etc.
It's one of the most powerful PostgreSQL features for testing — production databases like
Oracle and SQL Server (until very recently) couldn't do this.

**Caveats**:

- `CREATE OR REPLACE` works only when the new signature matches the old one. To change the
  signature, drop and re-create — but then the original is GONE after ROLLBACK only if the
  drop was inside the transaction.
- Some DDL is not transactional in older PostgreSQL versions. From PG 9.1 onward, almost all
  DDL is fully transactional, including CREATE TYPE, CREATE EXTENSION, etc.

---

## 5. Testing SECURITY DEFINER functions

`SECURITY DEFINER` functions run with the privileges of the function OWNER, not the caller.
The test must verify (a) the function exists with the right security context and (b) an
unprivileged role can use it without being able to access the underlying data directly.

```sql
BEGIN;
SELECT plan(3);

-- Verify the function is SECURITY DEFINER
SELECT is_definer(
    'public', 'secure_lookup', ARRAY['integer'],
    'secure_lookup should be SECURITY DEFINER'
);

-- Switch to unprivileged role
SET ROLE app_readonly;

-- Function call works for unprivileged user
SELECT lives_ok(
    $$SELECT secure_lookup(1)$$,
    'unprivileged user can call the SECURITY DEFINER function'
);

-- Direct table access blocked
SELECT throws_ok(
    $$SELECT * FROM sensitive_data$$,
    '42501', NULL,
    'unprivileged user cannot access table directly'
);

RESET ROLE;
SELECT * FROM finish();
ROLLBACK;
```

This pattern is the canonical way to expose narrow, audited access to sensitive tables —
unprivileged roles call only the function, never the table.

---

## 6. Testing dynamic SQL

Functions/procedures that build SQL with `EXECUTE` are tested the same way as regular
functions — focus on observable behavior, not the constructed SQL string. Always include an
SQL injection regression test:

```sql
BEGIN;
SELECT plan(2);

-- Function builds and executes dynamic SQL
SELECT is(
    dynamic_count('users', 'active = true'),
    3::bigint,
    'dynamic count should return correct result'
);

-- SQL injection should fail (the where_clause is not properly quoted, e.g.)
SELECT throws_ok(
    $$SELECT dynamic_count('users; DROP TABLE users; --', 'true')$$,
    NULL, NULL,
    'SQL injection attempt should fail'
);

SELECT * FROM finish();
ROLLBACK;
```

If the function uses `format()` with `%I` for identifiers and `%L` for literals, injection
attempts should fail with `42P01` (undefined_table) or similar — the malformed identifier
becomes the table name, not a separate statement.

---

## 7. Migration equivalence

When migrating from SQL Server, Oracle, or another database to PostgreSQL, write tests that
verify the migrated procedure produces the same results as the source. Source the expected
values from documented runs of the original procedure.

```sql
BEGIN;
SELECT plan(8);

-- Structure: verify migrated procedure exists with right signature
SELECT has_function('perseus', 'reconcile_m_upstream',
    ARRAY['integer', 'varchar'], 'migrated procedure should exist');
SELECT is_procedure('perseus', 'reconcile_m_upstream',
    ARRAY['integer', 'varchar']);

-- Seed: replicate the SQL Server test dataset exactly
INSERT INTO perseus.m_upstream (material_id, parent_id, status) VALUES
    (1, 100, 'Active'),
    (2, 100, 'Inactive'),
    (3, NULL, 'Active');

-- Execute migrated procedure
SELECT lives_ok(
    $$CALL perseus.reconcile_m_upstream(100, 'RECON_001')$$,
    'migrated procedure executes without error'
);

-- Verify same output as SQL Server reference run
SELECT is(
    (SELECT count(*)::integer FROM perseus.reconciliation_log
     WHERE batch_id = 'RECON_001'),
    2, 'should produce same row count as SQL Server (2)'
);

SELECT is(
    (SELECT status FROM perseus.m_upstream WHERE material_id = 2),
    'Reconciled',
    'inactive material marked Reconciled (matching SQL Server)'
);

-- Regression: SQL Server RAISERROR → PG RAISE EXCEPTION
SELECT throws_ok(
    $$CALL perseus.reconcile_m_upstream(NULL, 'NULL_001')$$,
    'P0001', NULL,
    'NULL material_id raises P0001 (was RAISERROR in SQL Server)'
);

-- Regression: empty input handled gracefully
SELECT lives_ok(
    $$CALL perseus.reconcile_m_upstream(999, 'EMPTY_001')$$,
    'procedure handles empty dataset without error'
);

-- Regression: no LOWER() abuse (perf issue from auto-conversion)
SELECT isnt_empty(
    $$SELECT 1 FROM pg_catalog.pg_proc
      WHERE proname = 'reconcile_m_upstream'
      AND prosrc NOT ILIKE '%lower(%'$$,
    'procedure does not use LOWER() (P1 perf issue)'
);

SELECT * FROM finish();
ROLLBACK;
```

The last assertion (`prosrc NOT ILIKE '%lower(%'`) is a regression test for a known issue
where AWS Schema Conversion Tool auto-inserts `LOWER()` on case-sensitive comparisons,
defeating index usage. Tailor these regression checks to whichever migration tool was used.

---

## 8. Testing partitioned tables

Partition support requires PostgreSQL 10+. Use the version-conditional pattern from § 9.

```sql
BEGIN;
SELECT plan(4);

-- Parent table is partitioned
SELECT is_partitioned('public', 'mylog', 'mylog should be partitioned');

-- Partitions exist
SELECT partitions_are(
    'public', 'mylog',
    ARRAY['mylog_2024', 'mylog_2025'],
    'mylog should have these partitions'
);

-- Each partition is a partition OF the parent
SELECT is_partition_of('public', 'mylog_2024', 'public', 'mylog');

-- Routing: insert into parent → row appears in correct partition
INSERT INTO mylog (event_date, message) VALUES ('2024-06-15', 'test');

SELECT is(
    (SELECT count(*)::integer FROM mylog_2024
     WHERE event_date = '2024-06-15'),
    1, 'row routed to mylog_2024'
);

SELECT * FROM finish();
ROLLBACK;
```

For partition pruning verification, use `EXPLAIN` separately — pgTAP does not directly inspect
query plans.

---

## 9. Cross-version conditional tests

Use the `skip` pattern when an assertion only makes sense on certain PostgreSQL versions:

```sql
BEGIN;
SELECT plan(3);

-- Always: works on all versions
SELECT has_table('public', 'users');

-- PG 10+ only: partition support
SELECT CASE WHEN current_setting('server_version_num')::int < 100000
    THEN skip('partition support requires PG 10+', 1)
    ELSE is_partitioned('public', 'mylog')
    END;

-- PG 11+ only: stored procedures
SELECT CASE WHEN current_setting('server_version_num')::int < 110000
    THEN skip('stored procedures require PG 11+', 1)
    ELSE is_procedure('public', 'process_batch', ARRAY['date', 'date'])
    END;

SELECT * FROM finish();
ROLLBACK;
```

For multiple assertions inside one branch, wrap with `collect_tap`:

```sql
SELECT CASE WHEN current_setting('server_version_num')::int >= 130000
    THEN collect_tap(
        is_indexed('public', 'orders', 'order_date'),
        index_is_type('public', 'orders', 'idx_orders_date', 'btree')
    )
    ELSE skip('PG 13+ feature', 2)
    END;
```

---

## 10. Tip: combine patterns sparingly

Each pattern in this file solves a specific problem. Don't pre-emptively reach for them.
Most schema and function tests should be standard `BEGIN`/`assertions`/`ROLLBACK` files
following `references/object-recipes.md`. Use these advanced patterns only when the standard
recipe genuinely doesn't fit your situation — for example, a procedure with internal COMMIT
that you can't refactor, or RLS policies that need to be exercised from multiple roles.
