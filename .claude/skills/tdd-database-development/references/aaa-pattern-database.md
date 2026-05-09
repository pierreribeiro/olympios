# Arrange-Act-Assert in Database Context — Pseudo-Code Reference

Read this when writing tests (RED) or evaluating tests (any role). All examples are in
**dialect-neutral pseudo-code**. Translate to your engine's syntax using the
engine-specific skill.

---

## The pattern (one paragraph)

Every test has exactly three labeled phases:

1. **Arrange** — establish prerequisites: create test schema/table, seed rows, set
   session state (role, search_path, isolation level), declare expected values.
2. **Act** — execute exactly **one** behavior: call the function/procedure, run the DML,
   fire the trigger via INSERT/UPDATE/DELETE, refresh the materialized view.
3. **Assert** — verify exactly **one** observable outcome: row count, column value,
   error code raised, side effect on another table, returned value.

It is **not** Arrange-Act-Assert-Act-Assert. A second action belongs in a separate test.

---

## Standard envelope

Wrap every test in the engine's standard isolation envelope. The pseudo-code uses
`BEGIN_TEST` / `END_TEST` to represent this — your engine skill defines the real syntax.

```
BEGIN_TEST "<descriptive_name_of_behavior>"

  -- ARRANGE -----------------------------------------------------
  -- prerequisites: schema/table existence, seed data, session state, expected values

  -- ACT ---------------------------------------------------------
  -- exactly one behavior

  -- ASSERT ------------------------------------------------------
  -- exactly one observable outcome

END_TEST   -- engine isolation: ROLLBACK / DROP SCHEMA / TRUNCATE — engine skill specifies
```

---

## AAA by database object

### 1. Table existence and column type

```
BEGIN_TEST "users table has email column of type TEXT NOT NULL"

  -- ARRANGE -----------------------------------------------------
  -- (no setup required — testing structure)

  -- ACT ---------------------------------------------------------
  -- (no action required — testing structure; the schema IS the act)

  -- ASSERT ------------------------------------------------------
  ASSERT object_exists(table='users')
  ASSERT column_exists(table='users', column='email')
  ASSERT column_type(table='users', column='email') = 'TEXT'
  ASSERT column_not_null(table='users', column='email')

END_TEST
```

> Schema-existence tests are unusual: ACT is implicit (the schema's current state is
> what's being tested). Multiple ASSERTs over the **same logical fact** (the column
> exists with these properties) are acceptable. Multiple ASSERTs over **different
> behaviors** are not — split them.

### 2. Primary / foreign key

```
BEGIN_TEST "orders.customer_id has foreign key to customers.id"

  -- ARRANGE -----------------------------------------------------
  INSERT INTO customers (id, name) VALUES (1, 'Alice')
  EXPECTED_ERROR_CODE = 'foreign_key_violation'   -- engine-neutral name

  -- ACT ---------------------------------------------------------
  -- attempt to insert an order with a non-existent customer
  TRY
    INSERT INTO orders (id, customer_id, total) VALUES (1, 999, 100)
  CATCH AS error_thrown
  END_TRY

  -- ASSERT ------------------------------------------------------
  ASSERT error_thrown.code = EXPECTED_ERROR_CODE

END_TEST
```

### 3. CHECK constraint

```
BEGIN_TEST "orders.total CHECK rejects negative values"

  -- ARRANGE -----------------------------------------------------
  INSERT INTO customers (id, name) VALUES (1, 'Alice')
  EXPECTED_ERROR_CODE = 'check_violation'

  -- ACT ---------------------------------------------------------
  TRY
    INSERT INTO orders (id, customer_id, total) VALUES (1, 1, -50)
  CATCH AS error_thrown
  END_TRY

  -- ASSERT ------------------------------------------------------
  ASSERT error_thrown.code = EXPECTED_ERROR_CODE

END_TEST
```

### 4. Function — happy path

```
BEGIN_TEST "calculate_order_total returns sum of line items"

  -- ARRANGE -----------------------------------------------------
  INSERT INTO orders (id) VALUES (1)
  INSERT INTO line_items (order_id, price, quantity) VALUES
    (1, 10, 2),   -- 20
    (1,  5, 4)    --  20
  EXPECTED_TOTAL = 40

  -- ACT ---------------------------------------------------------
  actual_total = CALL calculate_order_total(order_id => 1)

  -- ASSERT ------------------------------------------------------
  ASSERT actual_total = EXPECTED_TOTAL

END_TEST
```

### 5. Function — degenerate case (write this FIRST per baby steps)

```
BEGIN_TEST "calculate_order_total returns 0 for an order with no line items"

  -- ARRANGE -----------------------------------------------------
  INSERT INTO orders (id) VALUES (1)
  EXPECTED_TOTAL = 0

  -- ACT ---------------------------------------------------------
  actual_total = CALL calculate_order_total(order_id => 1)

  -- ASSERT ------------------------------------------------------
  ASSERT actual_total = EXPECTED_TOTAL

END_TEST
```

### 6. Function — error case

```
BEGIN_TEST "calculate_order_total raises for unknown order_id"

  -- ARRANGE -----------------------------------------------------
  EXPECTED_ERROR_CODE = 'no_data_found'

  -- ACT ---------------------------------------------------------
  TRY
    CALL calculate_order_total(order_id => 9999)
  CATCH AS error_thrown
  END_TRY

  -- ASSERT ------------------------------------------------------
  ASSERT error_thrown.code = EXPECTED_ERROR_CODE

END_TEST
```

### 7. Procedure — side effect on another table

```
BEGIN_TEST "place_order procedure inserts a row into orders"

  -- ARRANGE -----------------------------------------------------
  INSERT INTO customers (id, name) VALUES (1, 'Alice')
  rows_before = COUNT(*) FROM orders

  -- ACT ---------------------------------------------------------
  CALL place_order(customer_id => 1, total => 100)

  -- ASSERT ------------------------------------------------------
  rows_after = COUNT(*) FROM orders
  ASSERT rows_after = rows_before + 1
  ASSERT EXISTS(SELECT 1 FROM orders WHERE customer_id = 1 AND total = 100)

END_TEST
```

> The two ASSERT lines verify the **same** logical outcome (one new order with the
> expected fields). That is one observable behavior, not two. If you find yourself
> asserting on a *different* outcome — e.g., audit_log was also written — that is a
> separate test.

### 8. Trigger — fires on UPDATE

```
BEGIN_TEST "users_audit trigger inserts a row into audit_log on UPDATE of email"

  -- ARRANGE -----------------------------------------------------
  INSERT INTO users (id, email) VALUES (1, 'alice@old.example')
  audit_rows_before = COUNT(*) FROM audit_log WHERE table_name = 'users' AND row_id = 1

  -- ACT ---------------------------------------------------------
  UPDATE users SET email = 'alice@new.example' WHERE id = 1

  -- ASSERT ------------------------------------------------------
  audit_rows_after = COUNT(*) FROM audit_log WHERE table_name = 'users' AND row_id = 1
  ASSERT audit_rows_after = audit_rows_before + 1
  ASSERT EXISTS(
    SELECT 1 FROM audit_log
     WHERE table_name = 'users' AND row_id = 1
       AND old_value = 'alice@old.example'
       AND new_value = 'alice@new.example'
  )

END_TEST
```

### 9. Trigger — does NOT fire on excluded events

```
BEGIN_TEST "users_audit trigger does NOT fire on INSERT"

  -- ARRANGE -----------------------------------------------------
  audit_rows_before = COUNT(*) FROM audit_log

  -- ACT ---------------------------------------------------------
  INSERT INTO users (id, email) VALUES (1, 'alice@example.com')

  -- ASSERT ------------------------------------------------------
  audit_rows_after = COUNT(*) FROM audit_log
  ASSERT audit_rows_after = audit_rows_before

END_TEST
```

### 10. View — returns expected rows

```
BEGIN_TEST "v_active_users excludes soft-deleted rows"

  -- ARRANGE -----------------------------------------------------
  INSERT INTO users (id, email, deleted_at) VALUES
    (1, 'alice@example.com', NULL),
    (2, 'bob@example.com',   NOW())   -- soft-deleted

  -- ACT ---------------------------------------------------------
  result_set = SELECT id FROM v_active_users ORDER BY id

  -- ASSERT ------------------------------------------------------
  ASSERT result_set = [(1)]

END_TEST
```

### 11. RLS / row-level security

```
BEGIN_TEST "posts policy: a user sees only their own rows"

  -- ARRANGE -----------------------------------------------------
  INSERT INTO posts (id, owner_id, body) VALUES
    (1, 100, 'alice post'),
    (2, 200, 'bob post')

  -- ACT ---------------------------------------------------------
  -- switch to alice's identity (engine skill specifies HOW to switch role)
  SET_SESSION_USER('alice', user_id=100)
  result_set = SELECT id FROM posts ORDER BY id

  -- ASSERT ------------------------------------------------------
  ASSERT result_set = [(1)]   -- only alice's row visible

END_TEST
```

> RLS tests must explicitly note: most engines bypass RLS for superusers. The engine
> skill tells you how to ensure the test runs as a non-superuser role.

### 12. RLS — write blocked by policy

```
BEGIN_TEST "posts policy: a user cannot UPDATE another user's row"

  -- ARRANGE -----------------------------------------------------
  INSERT INTO posts (id, owner_id, body) VALUES (2, 200, 'bob post')
  EXPECTED_ERROR_CODE = 'insufficient_privilege'

  -- ACT ---------------------------------------------------------
  SET_SESSION_USER('alice', user_id=100)
  TRY
    UPDATE posts SET body = 'hacked' WHERE id = 2
  CATCH AS error_thrown
  END_TRY

  -- ASSERT ------------------------------------------------------
  ASSERT error_thrown.code = EXPECTED_ERROR_CODE

END_TEST
```

### 13. Index — exists with expected columns

```
BEGIN_TEST "idx_orders_customer_date exists on orders(customer_id, order_date)"

  -- ARRANGE -----------------------------------------------------
  -- (no setup required)

  -- ACT ---------------------------------------------------------
  -- (implicit — schema's current state)

  -- ASSERT ------------------------------------------------------
  ASSERT index_exists(table='orders', name='idx_orders_customer_date')
  ASSERT index_columns(table='orders', name='idx_orders_customer_date')
       = ['customer_id', 'order_date']

END_TEST
```

### 14. Migration equivalence (old vs. new schema)

```
BEGIN_TEST "migration v42 preserves all rows from users table"

  -- ARRANGE -----------------------------------------------------
  -- snapshot pre-migration row IDs (assume migration runner already executed)
  pre_ids  = SELECT id FROM users_pre_migration ORDER BY id
  post_ids = SELECT id FROM users              ORDER BY id

  -- ACT ---------------------------------------------------------
  -- (migration is the act, already executed by the harness)

  -- ASSERT ------------------------------------------------------
  ASSERT pre_ids = post_ids

END_TEST
```

---

## Anti-pattern: Arrange-Act-Assert-Act-Assert

```
-- ❌ WRONG: two acts, two assertions in one test
BEGIN_TEST "place_order works AND audit_log is written"

  -- ARRANGE
  INSERT INTO customers (id) VALUES (1)

  -- ACT 1
  CALL place_order(1, 100)

  -- ASSERT 1
  ASSERT EXISTS(SELECT 1 FROM orders WHERE customer_id = 1)

  -- ACT 2  ← second behavior — split into a separate test
  CALL audit_recent_orders()

  -- ASSERT 2
  ASSERT EXISTS(SELECT 1 FROM audit_log WHERE event = 'recent_orders')

END_TEST
```

Split into two tests, each testing one behavior.

---

## Anti-pattern: implementation-coupled assertion

```
-- ❌ WRONG: tests that the function uses a CTE
ASSERT function_body_contains(name='calculate_order_total', text='WITH cte AS')

-- ✅ RIGHT: tests behavior
actual_total = CALL calculate_order_total(order_id => 1)
ASSERT actual_total = EXPECTED_TOTAL
```

The first form makes the test brittle — any refactor that moves logic out of a CTE
breaks the test even though behavior is unchanged. Test what the function **does**, not
how it does it. Exception: when the implementation choice IS the requirement
(e.g., a performance test asserting an index is used).

---

## Anti-pattern: shared mutable state across tests

```
-- ❌ WRONG: test depends on side-effects of a previous test
BEGIN_TEST "test_2_assumes_test_1_inserted_a_row"
  result = SELECT count(*) FROM users
  ASSERT result = 1   -- relies on test_1 having run
END_TEST
```

Each test must Arrange its own state. The engine isolation envelope (transactional
rollback, ephemeral schema) makes this safe.

---

## Quick checklist before submitting a test

- [ ] Test name describes the behavior, not a number.
- [ ] Three labeled sections: ARRANGE, ACT, ASSERT.
- [ ] Exactly **one** action in ACT.
- [ ] Exactly **one** logical outcome in ASSERT (one or more lines, but one outcome).
- [ ] No implementation-coupled assertions.
- [ ] No reliance on previous tests' state.
- [ ] Wrapped in the engine isolation envelope (`BEGIN_TEST` / `END_TEST` equivalent).
- [ ] Test name does not contain "and" — if it does, split.
- [ ] Test currently **fails** (RED requirement) — and fails for the right reason.

---

## See also

- `role-red-test-writer.md` — the role that writes these tests
- `database-patterns.md` — what good behavior to test for
- `database-anti-patterns.md` — behaviors NOT to bake into tests
- `engine-skill-discovery.md` — how to translate `BEGIN_TEST`/`ASSERT` to your engine
