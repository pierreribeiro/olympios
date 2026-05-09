# TDD for PostgreSQL with pgTAP: A Practical Implementation Guide

**Version:** 2.0.0
**Created:** 2026-03-26
**Author:** Pierre Ribeiro + Claude (Desktop)
**Companion to:** Test-Driven Development: A Complete Methodology Reference
**Target audience:** AI coding agents (Claude Code, Claude Desktop), DBAs, developers
**PostgreSQL compatibility:** 16, 17, 18

---

## 1. Document purpose and scope

This document is the **practical implementation companion** ("How to do") to the *Test-Driven Development: A Complete Methodology Reference* ("What and why"). While the methodology reference establishes TDD principles, the Red-Green-Refactor cycle, and domain-specific theory, this guide provides the concrete tools, patterns, and workflows needed to apply TDD to PostgreSQL database development using the pgTAP testing framework.

### 1.1 What this document enables

This document is designed as a **foundational knowledge source** from which the following artifacts can be derived:

- **Claude Code skills** — Extract sections 4, 5, and 9 into a structured `SKILL.md` with trigger patterns, decision trees, and code templates.
- **Claude rules / CLAUDE.md directives** — Extract section 6 (anti-patterns) and section 8 (AI agent workflow) into enforceable rules with violation detection.
- **Agent personas** — Extract sections 5 and 8 into a TDD Test Engineer persona with defined boundaries, decision-making frameworks, and interaction patterns.
- **CI/CD pipeline configurations** — Extract section 10 into ready-to-use GitHub Actions and Docker Compose files.
- **Test generation templates** — Extract section 9 into parameterized templates that agents can fill per object type.

### 1.2 Relationship to TDD Methodology Reference

| Concern | Methodology Reference | This Guide |
|---------|----------------------|------------|
| What is TDD? | Defines Red-Green-Refactor cycle, three laws, misconceptions | Assumes understanding; applies cycle to PostgreSQL objects |
| Why TDD? | Evidence base, productivity data, cultural arguments | Assumes buy-in; focuses on execution |
| AI agent integration | TDAD paper findings, prompting paradox, subagent architecture theory | Concrete pgTAP workflows, TAP output parsing, decision matrices |
| Database TDD | Brief overview of pgTAP and tSQLt capabilities | Complete pgTAP assertion reference, object-type walkthroughs, advanced patterns |
| Migration context | Not covered | SQL Server → PostgreSQL equivalence testing patterns |

**Rule: Always read the Methodology Reference first for foundational understanding. Use this guide for execution.**

---

## 2. pgTAP framework overview

pgTAP is a unit testing framework for PostgreSQL that provides **over 180 TAP-compliant assertion functions**. Tests run inside the database engine itself, verifying schema structure, function behavior, trigger effects, constraint enforcement, RLS policies, and data transformations.

### 2.1 Core mechanics

Every pgTAP test follows this structure:

```sql
BEGIN;                          -- 1. Start transaction (isolation boundary)
SELECT plan(N);                 -- 2. Declare how many assertions will run
-- ... assertions go here ...   -- 3. Test assertions
SELECT * FROM finish();         -- 4. Verify plan count matches actual count
ROLLBACK;                       -- 5. Undo ALL changes (clean slate)
```

**Why transactions matter:** The `BEGIN`/`ROLLBACK` wrapper guarantees complete test isolation. No test can pollute the database for subsequent tests. Every INSERT, UPDATE, DELETE, CREATE, and ALTER performed during the test is undone.

**Critical limitation:** PostgreSQL procedures that use internal `COMMIT` or `ROLLBACK` statements **cannot be tested inside this wrapper** because the procedure's COMMIT ends the test's outer transaction. See section 7.1 for strategies to handle this.

### 2.2 Plan management

| Function | When to use | Behavior |
|----------|-------------|----------|
| `plan(N)` | You know exact test count | Reports error if actual count differs from N |
| `no_plan()` | Dynamic test generation | No count validation; must call `finish()` |
| `finish()` | Always | Reports plan vs actual discrepancy; use `finish(true)` to throw exception on mismatch |

**Rule for AI agents:** Always use `plan(N)` with an explicit count. It catches accidentally skipped or duplicated assertions. Only use `no_plan()` when generating tests dynamically from query results.

### 2.3 Installation

**Debian/Ubuntu (fastest):**
```bash
sudo apt-get install postgresql-17-pgtap    # PG17
sudo apt-get install postgresql-16-pgtap    # PG16
```

**From source (any platform):**
```bash
wget https://api.pgxn.org/dist/pgtap/1.3.3/pgtap-1.3.3.zip
unzip pgtap-1.3.3.zip && cd pgtap-1.3.3
make && make install && make installcheck
cpan TAP::Parser::SourceHandler::pgTAP      # pg_prove
```

**Enable in database:**
```sql
CREATE EXTENSION IF NOT EXISTS pgtap;
-- Or in a specific schema:
CREATE EXTENSION pgtap SCHEMA tap;
```

### 2.4 Docker test environment

Recommended two-container pattern:

```yaml
# docker-compose.test.yml
services:
  postgres:
    image: postgres:17-alpine
    environment:
      POSTGRES_PASSWORD: pgtap
      POSTGRES_DB: testdb
    command: postgres -c fsync=off -c full_page_writes=off
    healthcheck:
      test: pg_isready -U postgres
      interval: 5s
      retries: 5
    volumes:
      - ./init:/docker-entrypoint-initdb.d

  tests:
    build:
      context: .
      dockerfile: Dockerfile.test
    environment:
      PGPASSWORD: pgtap
    command: >-
      pg_prove -U postgres -h postgres -d testdb
      --verbose --ext .sql -r /tests/
    depends_on:
      postgres:
        condition: service_healthy
    volumes:
      - ./tests/:/tests/:z
```

**`init/00-extensions.sql`** (auto-runs on container start):
```sql
CREATE EXTENSION IF NOT EXISTS pgtap;
```

**Run:** `docker compose -f docker-compose.test.yml up --abort-on-container-exit --exit-code-from tests`

**Performance tip:** Disabling `fsync` and `full_page_writes` in test containers speeds execution significantly. Test data is ephemeral — no durability risk.

---

## 3. pg_prove: the test runner

`pg_prove` is the command-line harness that discovers, executes, and reports pgTAP tests. It wraps `psql` and produces TAP output.

### 3.1 Essential commands

```bash
# Run all tests recursively
pg_prove -d mydb -U postgres -r tests/

# Verbose (show each assertion line)
pg_prove -d mydb -U postgres -v tests/

# Run specific files
pg_prove -d mydb tests/01-schema.sql tests/02-functions.sql

# Parallel execution (4 jobs)
pg_prove -d mydb -j 4 -r tests/

# Random order (detect test pollution)
pg_prove -d mydb --shuffle -r tests/

# Show only failures
pg_prove -d mydb --failures -r tests/

# xUnit-style test functions
pg_prove -d mydb --runtests --schema test_schema

# Custom file extension
pg_prove -d mydb --ext .sql -r tests/
```

### 3.2 Key flags

| Flag | Purpose |
|------|---------|
| `-d` | Database name |
| `-U` | Username |
| `-h` / `-p` | Host / port |
| `-r` | Recurse into subdirectories |
| `-v` | Verbose output |
| `-j N` | Parallel jobs |
| `--ext` | File extension (default `.pg`) |
| `-R` / `--runtests` | Run xUnit test functions |
| `-s` / `--schema` | Schema for xUnit functions |
| `--shuffle` | Random execution order |
| `--state` | State tracking (`failed`, `save`, `hot`) |
| `-t` | Show elapsed time per test |

### 3.3 Interpreting TAP output

**Passing test:**
```
ok 1 - users table should exist
```

**Failing test:**
```
not ok 3 - email should be NOT NULL
#     Failed test 3: "email should be NOT NULL"
#     Column users.email allows NULL
```

**Failing `is()` with diagnostic:**
```
not ok 5 - function returns correct total
#     Failed test 5: "function returns correct total"
#         have: 54.95
#         want: 55.00
```

**Failing `throws_ok()` with diagnostic:**
```
not ok 7 - should raise error for negative quantity
#     Failed test 7: "should raise error for negative quantity"
#       caught: no exception
#       wanted: P0001
```

**Summary output:**
```
Files=5, Tests=42, 2 wallclock secs
Result: PASS
```

**AI agent rule:** Parse TAP output line-by-line. Lines starting with `ok` are passes. Lines starting with `not ok` are failures. Lines starting with `#` are diagnostics that explain WHY a failure occurred. The `have:` / `want:` diagnostic pair is the most actionable — it tells you exactly what the actual value was versus what was expected.

---

## 4. The TDD workflow for database objects

### 4.1 The Red-Green-Refactor cycle applied to PostgreSQL

The cycle is identical to the methodology reference. What changes is the test infrastructure:

**RED — Write a failing test:**
- Create a `.sql` test file with pgTAP assertions
- Assertions describe desired structure and behavior
- Run with `pg_prove` — ALL tests must fail
- If any test passes, the test is not testing new behavior

**GREEN — Minimal implementation:**
- Write the minimum DDL/DML to make tests pass
- Do NOT add columns, indexes, or features not covered by tests
- Run `pg_prove` — ALL tests must pass
- If any test fails, fix the implementation, not the test

**REFACTOR — Improve while green:**
- Add performance optimizations (indexes, query rewrites)
- Improve naming, comments, error messages
- Run `pg_prove` after EACH change
- If any test breaks, the refactor introduced a regression — revert

### 4.2 What to test vs what NOT to test

**Test your code** — constraints you defined, functions you wrote, triggers you built, policies you configured, views you created.

**Do NOT test PostgreSQL** — that INSERT works, that SELECT returns data, that arithmetic is correct. PostgreSQL's own regression suite covers this.

**Decision framework:**

| Question | If YES → | If NO → |
|----------|----------|---------|
| Did I write this code? | Test it | Don't test it |
| Does this enforce a business rule? | Test it | Consider skipping |
| Could a migration break this? | Test it | Lower priority |
| Is this a PostgreSQL built-in? | Don't test it | N/A |

### 4.3 Test coverage strategy per object type

| Object Type | Minimum Test Set | Priority |
|-------------|-----------------|----------|
| **Table** | Existence, columns_are, PK, NOT NULL constraints, FK relationships, UNIQUE constraints, CHECK constraints | P0 |
| **Function** | Existence, signature (params + return type), language, happy path result, NULL handling, error cases (throws_ok) | P0 |
| **Procedure** | Existence, is_procedure, happy path side effects, error cases, parameter validation | P0 |
| **Trigger** | Existence, trigger_is (correct function), behavioral effect (data changes) | P1 |
| **View** | Existence, columns_are, result correctness (results_eq/set_eq) | P1 |
| **Index** | Existence, type (btree/gin/gist), uniqueness, partial condition | P2 |
| **RLS Policy** | policies_are, policy_cmd_is, role-based access verification | P1 |
| **Materialized View** | Existence, columns_are, post-refresh correctness | P2 |
| **Type/Enum** | Existence, has_enum/has_type, enum_has_labels | P2 |
| **Extension** | extensions_are (exact set) | P2 |
| **Schema** | schemas_are (exact set) | P2 |
| **Permissions** | table_privs_are, function_privs_are, schema_privs_are | P1 |

---

## 5. Testing each object type: complete walkthroughs

### 5.1 Testing functions (end-to-end walkthrough)

This walkthrough demonstrates the complete TDD cycle for creating a function from scratch.

**Requirement:** Create a function `calculate_order_total(order_id integer)` that returns the total price of all items in an order, applying a 10% discount if the total exceeds 100.

**STEP 1: RED — Write the failing test**

```sql
-- tests/functions/test_calculate_order_total.sql
BEGIN;
SELECT plan(10);

-- ============================================
-- STRUCTURE TESTS
-- ============================================

-- S1: Function exists
SELECT has_function(
    'public', 'calculate_order_total', ARRAY['integer'],
    'calculate_order_total(integer) should exist'
);

-- S2: Returns correct type
SELECT function_returns(
    'public', 'calculate_order_total', ARRAY['integer'],
    'numeric', 'should return numeric'
);

-- S3: Written in PL/pgSQL
SELECT function_lang_is(
    'public', 'calculate_order_total', ARRAY['integer'],
    'plpgsql', 'should be plpgsql'
);

-- S4: Is a normal function, not a procedure
SELECT is_normal_function(
    'public', 'calculate_order_total', ARRAY['integer'],
    'should be a function not a procedure'
);

-- ============================================
-- SETUP TEST DATA
-- ============================================

-- Create minimal test tables (rolled back after test)
CREATE TABLE test_orders (id integer PRIMARY KEY);
CREATE TABLE test_order_items (
    order_id integer REFERENCES test_orders(id),
    quantity integer NOT NULL,
    unit_price numeric(10,2) NOT NULL
);

INSERT INTO test_orders VALUES (1), (2), (3);
INSERT INTO test_order_items VALUES
    (1, 2, 25.00),   -- order 1: total = 50.00 (no discount)
    (1, 1, 0.00),    -- order 1: zero-price item
    (2, 5, 30.00),   -- order 2: total = 150.00 (discount applies → 135.00)
    (2, 2, 0.00);    -- order 2: zero-price item

-- ============================================
-- BEHAVIOR TESTS: HAPPY PATH
-- ============================================

-- B1: Small order (no discount)
SELECT is(
    calculate_order_total(1),
    50.00::numeric,
    'order under 100 should have no discount'
);

-- B2: Large order (10% discount)
SELECT is(
    calculate_order_total(2),
    135.00::numeric,
    'order over 100 should have 10% discount'
);

-- ============================================
-- BEHAVIOR TESTS: EDGE CASES
-- ============================================

-- E1: Order with no items
SELECT is(
    calculate_order_total(3),
    0.00::numeric,
    'order with no items should return 0'
);

-- E2: Non-existent order
SELECT is(
    calculate_order_total(999),
    0.00::numeric,
    'non-existent order should return 0'
);

-- E3: NULL parameter
SELECT is(
    calculate_order_total(NULL),
    NULL::numeric,
    'NULL order_id should return NULL'
);

-- E4: Negative order ID raises error
SELECT throws_ok(
    $$SELECT calculate_order_total(-1)$$,
    'P0001',
    'order_id must be positive',
    'negative order_id should raise error'
);

-- ============================================
-- CLEANUP
-- ============================================
SELECT * FROM finish();
ROLLBACK;
```

Run: `pg_prove -d testdb -v tests/functions/test_calculate_order_total.sql` — all 10 tests fail. This is correct.

**STEP 2: GREEN — Minimal implementation**

```sql
CREATE OR REPLACE FUNCTION calculate_order_total(p_order_id integer)
RETURNS numeric
LANGUAGE plpgsql
AS $$
DECLARE
    v_total numeric;
BEGIN
    IF p_order_id IS NULL THEN
        RETURN NULL;
    END IF;

    IF p_order_id < 0 THEN
        RAISE EXCEPTION 'order_id must be positive';
    END IF;

    SELECT COALESCE(SUM(quantity * unit_price), 0)
    INTO v_total
    FROM test_order_items
    WHERE order_id = p_order_id;

    IF v_total > 100 THEN
        v_total := v_total * 0.90;
    END IF;

    RETURN v_total;
END;
$$;
```

Run tests — all 10 pass. **Do not add anything not covered by tests.**

**STEP 3: REFACTOR — Improve while green**

Replace `test_order_items` with actual production table name, add IMMUTABLE/STABLE volatility hints, add comments. Run tests after each change.

### 5.2 Testing procedures

PostgreSQL procedures differ from functions in critical ways:

| Aspect | Function | Procedure |
|--------|----------|-----------|
| Invocation | `SELECT func()` | `CALL proc()` |
| Return value | Returns data | No return value (side effects only) |
| Transaction control | Cannot COMMIT/ROLLBACK | Can COMMIT/ROLLBACK (but see 7.1) |
| pgTAP assertion | `is(func(), expected)` | `lives_ok('CALL proc()')` + verify side effects |

**Testing procedure side effects:**

```sql
-- tests/procedures/test_process_batch.sql
BEGIN;
SELECT plan(6);

-- ============================================
-- STRUCTURE TESTS
-- ============================================
SELECT has_function('public', 'process_batch',
    ARRAY['date', 'date'],
    'process_batch procedure should exist');

SELECT is_procedure('public', 'process_batch',
    ARRAY['date', 'date'],
    'should be a procedure, not a function');

-- ============================================
-- SETUP TEST DATA
-- ============================================
-- Seed raw records
INSERT INTO raw_records (record_date, status, amount)
VALUES
    ('2024-01-15', 'pending', 100.00),
    ('2024-01-20', 'pending', 200.00),
    ('2024-02-05', 'pending', 300.00);  -- Outside range

-- ============================================
-- BEHAVIOR TESTS
-- ============================================

-- B1: Procedure executes without error
SELECT lives_ok(
    $$CALL process_batch('2024-01-01'::date, '2024-01-31'::date)$$,
    'process_batch executes without error for valid date range'
);

-- B2: Verify correct records were processed (side effect)
SELECT is(
    (SELECT count(*)::integer FROM processed_records
     WHERE batch_start = '2024-01-01'),
    2,
    'should process exactly 2 records in January'
);

-- B3: Verify records outside range were NOT processed
SELECT is(
    (SELECT count(*)::integer FROM processed_records
     WHERE batch_start = '2024-02-01'),
    0,
    'should not process February records'
);

-- B4: Error case — NULL parameters
SELECT throws_ok(
    $$CALL process_batch(NULL, '2024-01-31'::date)$$,
    'P0001',
    NULL,
    'NULL start_date should raise error'
);

SELECT * FROM finish();
ROLLBACK;
```

### 5.3 Testing triggers

Test **behavior** (what the trigger does), not **internals** (how it does it).

```sql
-- tests/triggers/test_audit_trigger.sql
BEGIN;
SELECT plan(6);

-- ============================================
-- STRUCTURE TESTS
-- ============================================
SELECT has_trigger('products', 'trg_product_audit',
    'audit trigger should exist on products');
SELECT trigger_is('products', 'trg_product_audit',
    'fn_log_product_changes',
    'trigger should call fn_log_product_changes');

-- ============================================
-- BEHAVIOR TESTS
-- ============================================

-- Seed data
INSERT INTO products (id, name, price) VALUES (1, 'Widget', 9.99);

-- B1: UPDATE fires trigger
UPDATE products SET price = 24.99 WHERE id = 1;
SELECT is(
    (SELECT count(*)::integer FROM audit_log WHERE table_name = 'products'),
    1, 'UPDATE should create exactly one audit entry'
);

-- B2: Verify logged values
SELECT is(
    (SELECT old_value FROM audit_log
     WHERE table_name = 'products' AND column_name = 'price'),
    '9.99',
    'audit should log old price value'
);

-- B3: INSERT does not fire (if trigger is UPDATE-only)
INSERT INTO products (id, name, price) VALUES (2, 'Gadget', 19.99);
SELECT is(
    (SELECT count(*)::integer FROM audit_log WHERE table_name = 'products'),
    1, 'INSERT should not create audit entry for UPDATE-only trigger'
);

-- B4: DELETE fires trigger
DELETE FROM products WHERE id = 1;
SELECT is(
    (SELECT count(*)::integer FROM audit_log
     WHERE table_name = 'products' AND operation = 'DELETE'),
    1, 'DELETE should create audit entry'
);

SELECT * FROM finish();
ROLLBACK;
```

### 5.4 Testing views

```sql
-- tests/views/test_active_users_view.sql
BEGIN;
SELECT plan(5);

-- ============================================
-- STRUCTURE TESTS
-- ============================================
SELECT has_view('public', 'v_active_users',
    'active users view should exist');
SELECT columns_are('public', 'v_active_users',
    ARRAY['id', 'email', 'name', 'last_login'],
    'view should expose exactly these columns');

-- ============================================
-- BEHAVIOR TESTS
-- ============================================

-- Seed data
INSERT INTO users (id, email, name, active, last_login) VALUES
    (1, 'alice@test.com', 'Alice', true, '2024-01-15'),
    (2, 'bob@test.com', 'Bob', false, '2024-01-10'),
    (3, 'carol@test.com', 'Carol', true, '2024-01-20');

-- B1: View filters correctly (only active users)
SELECT set_eq(
    'SELECT email FROM v_active_users',
    ARRAY['alice@test.com', 'carol@test.com'],
    'view should return only active users'
);

-- B2: Inactive users excluded
SELECT set_hasnt(
    'SELECT email FROM v_active_users',
    ARRAY['bob@test.com'],
    'view should not include inactive users'
);

-- B3: Empty when no active users
UPDATE users SET active = false;
SELECT is_empty(
    'SELECT * FROM v_active_users',
    'view should be empty when no active users exist'
);

SELECT * FROM finish();
ROLLBACK;
```

### 5.5 Testing constraints

Test both **acceptance** (valid data passes) and **rejection** (invalid data fails):

```sql
-- tests/constraints/test_booking_constraints.sql
BEGIN;
SELECT plan(7);

-- Structure tests
SELECT has_pk('bookings', 'bookings should have primary key');
SELECT col_not_null('bookings', 'room_number', 'room_number is NOT NULL');
SELECT col_not_null('bookings', 'check_in', 'check_in is NOT NULL');
SELECT has_check('bookings', 'bookings should have CHECK constraints');

-- Acceptance: valid data succeeds
PREPARE valid_booking AS INSERT INTO bookings
    (room_number, check_in, check_out, guest_name)
    VALUES (310, '2024-07-01', '2024-07-05', 'Ada Lovelace');
SELECT lives_ok('valid_booking', 'valid booking should succeed');

-- Rejection: overlapping dates fail (exclusion constraint)
PREPARE overlapping AS INSERT INTO bookings
    (room_number, check_in, check_out, guest_name)
    VALUES (310, '2024-07-03', '2024-07-08', 'Grace Hopper');
SELECT throws_ok('overlapping',
    '23P01', NULL,
    'overlapping booking should violate exclusion constraint');

-- Rejection: check_out before check_in fails
PREPARE invalid_dates AS INSERT INTO bookings
    (room_number, check_in, check_out, guest_name)
    VALUES (311, '2024-07-05', '2024-07-01', 'Alan Turing');
SELECT throws_ok('invalid_dates',
    '23514', NULL,
    'check_out before check_in should violate CHECK constraint');

DEALLOCATE valid_booking;
DEALLOCATE overlapping;
DEALLOCATE invalid_dates;
SELECT * FROM finish();
ROLLBACK;
```

### 5.6 Testing RLS policies

RLS testing requires role switching. Key insight: blocked SELECT returns **empty results** (not errors), while blocked INSERT/UPDATE/DELETE **throws errors**.

```sql
-- tests/rls/test_post_policies.sql
BEGIN;
SELECT plan(5);

-- Structure
SELECT policies_are('posts',
    ARRAY['owner_select', 'owner_insert', 'owner_update']);
SELECT policy_cmd_is('posts', 'owner_select', 'select');

-- Seed as superuser
INSERT INTO users (id, email) VALUES (1, 'alice@test.com'), (2, 'bob@test.com');
INSERT INTO posts (id, user_id, content) VALUES (1, 1, 'Alice post');

-- Test as alice
SET ROLE app_user;
SET request.jwt.claim.sub = '1';

SELECT isnt_empty(
    $$SELECT * FROM posts WHERE user_id = 1$$,
    'Alice can see her own post'
);

-- Test as bob
SET request.jwt.claim.sub = '2';

SELECT is_empty(
    $$SELECT * FROM posts WHERE user_id = 1$$,
    'Bob cannot see Alice posts'
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

---

## 6. Common anti-patterns and misconceptions

### 6.1 Anti-pattern catalog

| Anti-Pattern | What It Looks Like | Why It's Wrong | Correct Approach |
|--------------|-------------------|----------------|------------------|
| **Testing PostgreSQL** | `SELECT is((SELECT 1+1), 2)` | Tests PostgreSQL arithmetic, not your code | Test YOUR constraints, functions, triggers |
| **Non-deterministic ordering** | `results_eq()` without `ORDER BY` | Row order is arbitrary; tests become flaky | Always use `ORDER BY`, or prefer `set_eq()`/`bag_eq()` |
| **Asserting auto-generated IDs** | `SELECT is(id, 1, 'first user')` | SERIAL/IDENTITY sequences advance permanently, even after ROLLBACK | Test by business key (email, name), not synthetic ID |
| **PREPARE leak** | Forgetting to `DEALLOCATE` | "prepared statement already exists" on re-run | Always `DEALLOCATE` before `finish()` |
| **Mega-test files** | One file with 200 assertions | Hard to isolate failures, slow to debug | One file per object or per concern; 10-30 assertions max |
| **Testing implementation details** | Checking internal variable values | Breaks when implementation changes; behavior unchanged | Test inputs → outputs and side effects only |
| **Ignoring NULL handling** | Only testing happy paths | NULL is the #1 source of database bugs | Always test NULL parameters explicitly |
| **Over-mocking** | Replacing everything with stubs | Tests pass but code fails in production | Mock external dependencies only; test with real tables when possible |
| **Brittle type assertions** | `col_type_is('users', 'name', 'varchar')` | Fails because PostgreSQL reports `character varying` | Use exact PostgreSQL type names: `character varying(255)` |

### 6.2 Type casting rules for assertions

pgTAP's `is()` uses `IS NOT DISTINCT FROM` for comparison (NULL-safe), but types must match:

```sql
-- WRONG: integer vs bigint mismatch
SELECT is(count(*), 5, 'should have 5 rows');    -- count() returns bigint

-- RIGHT: explicit cast
SELECT is(count(*)::integer, 5, 'should have 5 rows');
-- OR:
SELECT is((SELECT count(*) FROM users), 5::bigint, 'should have 5 rows');
```

**Common casting patterns:**

| Data Type | Cast Pattern | Example |
|-----------|-------------|---------|
| Integer | `::integer` | `is(result, 42::integer, 'msg')` |
| Numeric | `::numeric` | `is(total, 99.95::numeric, 'msg')` |
| Text | `::text` | `is(name, 'Alice'::text, 'msg')` |
| Boolean | `::boolean` | `is(active, true::boolean, 'msg')` |
| UUID | `::uuid` | `is(id, 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'::uuid, 'msg')` |
| JSONB | `::jsonb` | `is(data, '{"key": "val"}'::jsonb, 'msg')` |
| Timestamp | `::timestamptz` | `is(created, '2024-01-01 00:00:00+00'::timestamptz, 'msg')` |
| Array | `::type[]` | `is(tags, ARRAY['a','b']::text[], 'msg')` |
| Interval | `::interval` | `is(duration, '2 hours'::interval, 'msg')` |

### 6.3 PostgreSQL error codes quick reference

Essential codes for `throws_ok()`:

| Code | Name | Common Trigger |
|------|------|----------------|
| `23502` | not_null_violation | INSERT NULL into NOT NULL column |
| `23503` | foreign_key_violation | INSERT with non-existent FK reference |
| `23505` | unique_violation | INSERT duplicate into UNIQUE column |
| `23514` | check_violation | INSERT violating CHECK constraint |
| `23P01` | exclusion_violation | INSERT violating EXCLUSION constraint |
| `22004` | null_value_not_allowed | NULL where not permitted |
| `22012` | division_by_zero | Division by zero |
| `42501` | insufficient_privilege | RLS or GRANT denial |
| `42P01` | undefined_table | Table does not exist |
| `42883` | undefined_function | Function does not exist |
| `P0001` | raise_exception | Custom RAISE EXCEPTION in PL/pgSQL |
| `P0002` | no_data_found | GET DIAGNOSTICS with no result |
| `P0003` | too_many_rows | INTO with multiple rows |

**Usage pattern:**
```sql
SELECT throws_ok(
    $$INSERT INTO users (email) VALUES (NULL)$$,
    '23502',                               -- error code
    NULL,                                  -- NULL = don't check message (avoids localization issues)
    'NULL email should violate NOT NULL'   -- test description
);
```

---

## 7. Advanced patterns

### 7.1 The transaction control problem (procedures with COMMIT/ROLLBACK)

**The problem:** pgTAP tests wrap in `BEGIN`/`ROLLBACK`. If a procedure calls `COMMIT` internally, it ends the test's outer transaction. The test's final `ROLLBACK` then has nothing to undo — test data leaks into the database.

**Strategy 1: Refactor to avoid internal COMMIT (preferred)**

Convert the procedure to use SAVEPOINTs instead of COMMIT, or extract the logic into a function (which cannot use COMMIT) and have the procedure be a thin wrapper:

```sql
-- Function contains all testable logic (no COMMIT)
CREATE FUNCTION fn_process_batch_logic(p_start date, p_end date)
RETURNS integer AS $$
    -- Business logic here
$$ LANGUAGE plpgsql;

-- Procedure is a thin wrapper with transaction control
CREATE PROCEDURE process_batch(p_start date, p_end date) AS $$
BEGIN
    PERFORM fn_process_batch_logic(p_start, p_end);
    COMMIT;
END;
$$ LANGUAGE plpgsql;
```

Test `fn_process_batch_logic()` (the function) with normal pgTAP. The procedure is a thin wrapper that doesn't need unit testing — integration tests cover it.

**Strategy 2: Dedicated test database with teardown**

For procedures that genuinely need internal COMMIT (batch processing, ETL), use a dedicated test database that is rebuilt between tests:

```bash
#!/bin/bash
# test_with_commit.sh
createdb test_batch
psql -d test_batch -f schema.sql
psql -d test_batch -f seed_test_data.sql
psql -d test_batch -c "CALL process_batch('2024-01-01', '2024-01-31')"
# Now verify results (outside a transaction)
pg_prove -d test_batch tests/integration/verify_batch_results.sql
dropdb test_batch
```

**Strategy 3: Test the procedure outside BEGIN/ROLLBACK**

Run the CALL outside the test transaction, then verify results in a separate test block that does use pgTAP:

```sql
-- Step 1: Run procedure (no wrapping transaction)
CALL process_batch('2024-01-01', '2024-01-31');

-- Step 2: Verify results with pgTAP
BEGIN;
SELECT plan(3);
SELECT is(
    (SELECT count(*)::integer FROM processed_records),
    150, 'should process 150 records'
);
-- ... more assertions ...
SELECT * FROM finish();
ROLLBACK;

-- Step 3: Manual cleanup
DELETE FROM processed_records WHERE batch_start = '2024-01-01';
```

### 7.2 Testing procedures with temporary tables

Temporary tables exist for the session duration and are invisible to other sessions. They are NOT rolled back by `ROLLBACK` (they're dropped at session end or with `ON COMMIT DROP`).

```sql
-- Test that a procedure creating temp tables works correctly
BEGIN;
SELECT plan(3);

-- Call the procedure that internally creates temp tables
SELECT lives_ok(
    $$CALL build_staging_data(100)$$,
    'procedure with temp tables executes without error'
);

-- Verify temp table was created and populated
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
-- Note: temp table persists until session ends (ROLLBACK doesn't drop it)
```

**If the procedure uses `ON COMMIT DROP`**, the temp table disappears at ROLLBACK:
```sql
-- Cannot verify temp table contents after ROLLBACK
-- Solution: Verify within the transaction, before ROLLBACK
```

### 7.3 Testing dynamic SQL (EXECUTE)

Functions/procedures using `EXECUTE` for dynamic SQL are tested the same way — test the observable behavior:

```sql
BEGIN;
SELECT plan(2);

-- Function that builds and executes dynamic SQL
SELECT is(
    dynamic_count('users', 'active = true'),
    3::bigint,
    'dynamic count should return correct result'
);

-- Test SQL injection prevention
SELECT throws_ok(
    $$SELECT dynamic_count('users; DROP TABLE users; --', 'true')$$,
    NULL, NULL,
    'SQL injection attempt should fail'
);

SELECT * FROM finish();
ROLLBACK;
```

### 7.4 Mocking with transactional DDL

PostgreSQL's transactional DDL enables clean mocking:

```sql
BEGIN;
SELECT plan(1);

-- Replace external dependency with deterministic mock
CREATE OR REPLACE FUNCTION get_exchange_rate(currency text)
RETURNS numeric AS $$
BEGIN RETURN 1.25; END;
$$ LANGUAGE plpgsql;

-- Test function that depends on exchange rates
SELECT is(
    convert_price(100, 'EUR'),
    125.00::numeric,
    'price conversion should use exchange rate'
);

SELECT * FROM finish();
ROLLBACK;  -- Original get_exchange_rate() is restored!
```

### 7.5 Testing SECURITY DEFINER functions

SECURITY DEFINER functions run with the privileges of the function owner, not the caller. Test that unprivileged users can execute them:

```sql
BEGIN;
SELECT plan(3);

SELECT is_definer('public', 'secure_lookup',
    ARRAY['integer'], 'should be SECURITY DEFINER');

-- Test as unprivileged user
SET ROLE app_readonly;

SELECT lives_ok(
    $$SELECT secure_lookup(1)$$,
    'unprivileged user can call SECURITY DEFINER function'
);

-- Verify direct table access is blocked
SELECT throws_ok(
    $$SELECT * FROM sensitive_data$$,
    '42501', NULL,
    'unprivileged user cannot access table directly'
);

RESET ROLE;
SELECT * FROM finish();
ROLLBACK;
```

### 7.6 Migration equivalence testing

For SQL Server → PostgreSQL migrations, test that the PostgreSQL version produces the same results as the original:

```sql
-- tests/migration/test_reconcile_m_upstream.sql
BEGIN;
SELECT plan(8);

-- ============================================
-- STRUCTURE: Verify migrated procedure signature
-- ============================================
SELECT has_function('perseus', 'reconcile_m_upstream',
    ARRAY['integer', 'varchar'],
    'migrated procedure should exist');
SELECT is_procedure('perseus', 'reconcile_m_upstream',
    ARRAY['integer', 'varchar']);

-- ============================================
-- EQUIVALENCE: Known inputs → expected outputs
-- (Expected values derived from SQL Server execution)
-- ============================================

-- Seed: replicate known SQL Server test dataset
INSERT INTO perseus.m_upstream (material_id, parent_id, status)
VALUES (1, 100, 'Active'), (2, 100, 'Inactive'), (3, NULL, 'Active');

-- Execute migrated procedure
SELECT lives_ok(
    $$CALL perseus.reconcile_m_upstream(100, 'RECON_001')$$,
    'migrated procedure executes without error'
);

-- Verify: same row counts as SQL Server
SELECT is(
    (SELECT count(*)::integer FROM perseus.reconciliation_log
     WHERE batch_id = 'RECON_001'),
    2,
    'should process same number of records as SQL Server (2)'
);

-- Verify: same business logic outcome
SELECT is(
    (SELECT status FROM perseus.m_upstream WHERE material_id = 2),
    'Reconciled',
    'inactive material should be marked Reconciled (matching SQL Server)'
);

-- ============================================
-- REGRESSION: Patterns identified in AWS SCT analysis
-- ============================================

-- P0: Transaction control works correctly
SELECT lives_ok(
    $$CALL perseus.reconcile_m_upstream(999, 'EMPTY_001')$$,
    'procedure handles empty dataset without error'
);

-- P0: RAISE replaces SQL Server RAISERROR
SELECT throws_ok(
    $$CALL perseus.reconcile_m_upstream(NULL, 'NULL_001')$$,
    'P0001', NULL,
    'NULL material_id should raise exception (was RAISERROR in SQL Server)'
);

-- P1: No excessive LOWER() usage (performance)
-- Verify case-insensitive comparison uses citext or ILIKE, not LOWER()
SELECT isnt_empty(
    $$SELECT 1 FROM pg_catalog.pg_proc
      WHERE proname = 'reconcile_m_upstream'
      AND prosrc NOT ILIKE '%lower(%'$$,
    'procedure should not use LOWER() (P1 performance issue)'
);

SELECT * FROM finish();
ROLLBACK;
```

---

## 8. AI agent-driven TDD workflow

### 8.1 The TDD Prompting Paradox (from TDAD paper)

Research finding: **Detailed TDD procedural instructions in agent prompts INCREASE regressions** (from 6.08% to 9.94%). Verbose instructions consume context window space while failing to tell the agent which tests to run.

**Resolution: Context beats procedure.** Tell the agent WHICH tests to verify, not HOW to do TDD. A 20-line prompt with specific test targets quadrupled resolution rates compared to a 107-line detailed workflow.

### 8.2 Three-agent architecture for database TDD

| Agent | Phase | Input | Output | Critical Rule |
|-------|-------|-------|--------|---------------|
| **Test Writer** | RED | Requirements/specs ONLY | Failing test file | Has NO knowledge of implementation approach |
| **Implementer** | GREEN | Failing test file | Minimal SQL to pass | Does NOT modify tests |
| **Refactorer** | REFACTOR | Passing code + tests | Optimized SQL | Runs ALL tests after each change |

**Context isolation is mandatory.** The test writer must not know how the code will be implemented. Otherwise, it unconsciously writes tests that match the planned implementation rather than the requirement.

### 8.3 Agent decision matrix: choosing assertions

When an AI agent receives a requirement, use this matrix to determine which assertions to write:

```
IF object_type = TABLE:
    → has_table, columns_are, col_type_is (for each column)
    → col_not_null (for required columns)
    → has_pk, col_is_pk
    → fk_ok (for each foreign key)
    → col_is_unique (for unique columns)
    → has_check (for CHECK constraints)

IF object_type = FUNCTION:
    → has_function (with parameter types)
    → function_returns
    → function_lang_is
    → is() for happy path results
    → is() for NULL parameter handling
    → throws_ok() for error cases
    → performs_ok() if performance SLA exists

IF object_type = PROCEDURE:
    → has_function + is_procedure
    → lives_ok('CALL ...') for happy path
    → Verify side effects with is(), set_eq()
    → throws_ok() for error cases
    → Check transaction control strategy (section 7.1)

IF object_type = TRIGGER:
    → has_trigger
    → trigger_is (correct function name)
    → Verify trigger fires: perform action, check side effect
    → Verify trigger does NOT fire for excluded events

IF object_type = VIEW:
    → has_view, columns_are
    → set_eq or results_eq for query results
    → Test with empty data (is_empty)
    → Test filter conditions

IF object_type = INDEX:
    → has_index
    → index_is_type ('btree', 'gin', 'gist', etc.)
    → index_is_unique (if applicable)
    → index_is_partial (if applicable)
    → performs_ok (verify query uses index)

IF object_type = RLS_POLICY:
    → policies_are (exact set)
    → policy_cmd_is
    → SET ROLE + verify access (is_empty for blocked, isnt_empty for allowed)
    → throws_ok for blocked INSERT/UPDATE/DELETE
```

### 8.4 Agent test file template

```sql
-- =============================================================================
-- pgTAP Test: [SCHEMA].[OBJECT_NAME]
-- Type: [TABLE|FUNCTION|PROCEDURE|TRIGGER|VIEW|INDEX|RLS]
-- Generated: [TIMESTAMP]
-- Requirement: [BRIEF_DESCRIPTION]
-- =============================================================================
BEGIN;
SELECT plan([N]);

-- =============================================================================
-- SECTION 1: Structure / Existence Tests
-- =============================================================================
-- Verify the object exists with correct properties

-- =============================================================================
-- SECTION 2: Setup Test Data
-- =============================================================================
-- Seed minimal data required for behavior tests

-- =============================================================================
-- SECTION 3: Happy Path Behavior Tests
-- =============================================================================
-- Test expected successful operations

-- =============================================================================
-- SECTION 4: Edge Cases
-- =============================================================================
-- NULL handling, empty datasets, boundary values

-- =============================================================================
-- SECTION 5: Error Cases
-- =============================================================================
-- Invalid inputs, constraint violations, permission denials

-- =============================================================================
-- SECTION 6: Cleanup
-- =============================================================================
-- DEALLOCATE any prepared statements
SELECT * FROM finish();
ROLLBACK;
```

### 8.5 CLAUDE.md directives for TDD enforcement

```markdown
# TDD Rules for Database Development

## Mandatory Workflow
1. NEVER write CREATE FUNCTION/PROCEDURE/TRIGGER without a failing pgTAP test first.
2. Read test output to CONFIRM failure before implementing.
3. Write the SIMPLEST code that passes the current test.
4. Refactor ONLY after all tests pass.
5. Run `pg_prove` after EVERY code change.

## pgTAP Specific Rules
- Always use explicit plan(N), never no_plan().
- Always DEALLOCATE prepared statements before finish().
- Always use ORDER BY with results_eq().
- Always cast values explicitly in is() assertions.
- Never assert auto-generated IDs (SERIAL/IDENTITY).
- Never test PostgreSQL built-in behavior.
- Test NULL parameters for EVERY function and procedure.
- Test at least one error case (throws_ok) for every function.

## Test File Rules
- One file per object type or per concern.
- Maximum 30 assertions per file.
- File naming: test_[schema]_[object_name].sql
- Always include structure tests AND behavior tests.

## When Modifying Existing Code
- Ensure pgTAP test exists FIRST.
- If no test exists, CREATE one before modifying.
- Run full test suite after modification.
```

---

## 9. Complete pgTAP assertion reference

### 9.1 Core assertions

| Function | Purpose | NULL behavior |
|----------|---------|---------------|
| `ok(boolean, desc)` | Basic boolean | NULL = fail |
| `is(have, want, desc)` | Equality (IS NOT DISTINCT FROM) | NULL = NULL passes |
| `isnt(have, want, desc)` | Inequality | NULL ≠ NULL fails |
| `matches(have, regex, desc)` | Regex match | |
| `imatches(have, regex, desc)` | Case-insensitive regex | |
| `doesnt_match(have, regex, desc)` | Negative regex | |
| `alike(have, pattern, desc)` | SQL LIKE | |
| `ialike(have, pattern, desc)` | Case-insensitive LIKE | |
| `cmp_ok(have, op, want, desc)` | Any binary operator | |
| `pass(desc)` / `fail(desc)` | Always pass/fail | |
| `isa_ok(have, regtype, name)` | Type check | |

### 9.2 Exception and performance

| Function | Purpose |
|----------|---------|
| `throws_ok(sql, errcode, errmsg, desc)` | Verify specific exception |
| `throws_like(sql, pattern, desc)` | Exception message matches LIKE |
| `throws_ilike(sql, pattern, desc)` | Case-insensitive LIKE |
| `throws_matching(sql, regex, desc)` | Exception message matches regex |
| `lives_ok(sql, desc)` | No exception thrown |
| `performs_ok(sql, ms, desc)` | Completes within N ms |
| `performs_within(sql, avg_ms, deviation, iterations, desc)` | Average within window |

### 9.3 Result set comparison

| Function | Order Matters? | Duplicates Matter? | Use When |
|----------|---------------|-------------------|----------|
| `results_eq(sql, sql)` | YES | YES | Exact ordered comparison |
| `results_ne(sql, sql)` | YES | YES | Results differ |
| `set_eq(sql, sql)` | NO | NO | Unordered set equality |
| `set_ne(sql, sql)` | NO | NO | Sets differ |
| `set_has(sql, sql)` | NO | NO | Subset check |
| `set_hasnt(sql, sql)` | NO | NO | Exclusion check |
| `bag_eq(sql, sql)` | NO | YES | Unordered, duplicates count |
| `bag_ne(sql, sql)` | NO | YES | Bags differ |
| `bag_has(sql, sql)` | NO | YES | Bag subset |
| `bag_hasnt(sql, sql)` | NO | YES | Bag exclusion |
| `is_empty(sql)` | N/A | N/A | Zero rows |
| `isnt_empty(sql)` | N/A | N/A | At least one row |
| `row_eq(sql, row)` | N/A | N/A | Single row match |

### 9.4 Schema existence (has/hasnt pairs)

Every `has_*` has a corresponding `hasnt_*`:

`has_table`, `has_view`, `has_materialized_view`, `has_sequence`, `has_schema`, `has_extension`, `has_foreign_table`, `has_column`, `has_index`, `has_trigger`, `has_function`, `has_type`, `has_composite`, `has_domain`, `has_enum`, `has_role`, `has_user`, `has_group`, `has_language`, `has_rule`, `has_cast`, `has_operator`, `has_tablespace`

### 9.5 Schema enumeration (_are functions)

Verify **exact sets** — no more, no less:

`tables_are`, `views_are`, `materialized_views_are`, `columns_are`, `indexes_are`, `triggers_are`, `functions_are`, `schemas_are`, `sequences_are`, `roles_are`, `users_are`, `groups_are`, `languages_are`, `types_are`, `domains_are`, `enums_are`, `extensions_are`, `operators_are`, `rules_are`, `foreign_tables_are`, `partitions_are`, `tablespaces_are`

### 9.6 Column and constraint testing

`col_not_null`, `col_is_null`, `col_type_is`, `col_has_default`, `col_hasnt_default`, `col_default_is`, `has_pk`, `hasnt_pk`, `col_is_pk`, `col_isnt_pk`, `has_fk`, `hasnt_fk`, `col_is_fk`, `col_isnt_fk`, `fk_ok`, `has_unique`, `col_is_unique`, `has_check`, `col_has_check`

### 9.7 Index testing

`index_is_unique`, `index_is_primary`, `index_is_partial`, `is_indexed`, `index_is_type`, `is_clustered`

### 9.8 Function metadata

`function_returns`, `function_lang_is`, `is_definer`, `isnt_definer`, `is_strict`, `isnt_strict`, `is_normal_function`, `isnt_normal_function`, `is_aggregate`, `isnt_aggregate`, `is_window`, `isnt_window`, `is_procedure`, `isnt_procedure`, `volatility_is`, `trigger_is`, `can`

### 9.9 Ownership and privileges

`db_owner_is`, `schema_owner_is`, `table_owner_is`, `view_owner_is`, `function_owner_is`, `sequence_owner_is`, `index_owner_is`, `type_owner_is`

`database_privs_are`, `schema_privs_are`, `table_privs_are`, `sequence_privs_are`, `column_privs_are`, `function_privs_are`, `language_privs_are`, `fdw_privs_are`, `server_privs_are`

### 9.10 RLS policy testing

`policies_are`, `policy_roles_are`, `policy_cmd_is`

### 9.11 Diagnostics and flow control

| Function | Purpose |
|----------|---------|
| `diag(text)` | Print diagnostic (# prefix in TAP output) |
| `skip(why, count)` | Skip next N tests |
| `todo(why, count)` | Mark next N as TODO (expected to fail) |
| `todo_start(why)` | Begin TODO block |
| `todo_end()` | End TODO block |
| `in_todo()` | Check if inside TODO block |
| `collect_tap(...)` | Collect multiple assertions for conditional execution |

---

## 10. Test organization and CI/CD

### 10.1 Directory structure

```
project/
├── sql/
│   ├── migrations/
│   ├── functions/
│   ├── procedures/
│   ├── triggers/
│   └── views/
├── tests/
│   ├── structure/
│   │   ├── test_schemas.sql          # 00-level: schema existence
│   │   ├── test_tables.sql           # 01-level: table structure
│   │   └── test_constraints.sql      # 02-level: FK, UNIQUE, CHECK
│   ├── functions/
│   │   ├── test_calculate_total.sql
│   │   └── test_validate_email.sql
│   ├── procedures/
│   │   ├── test_process_batch.sql
│   │   └── test_reconcile_upstream.sql
│   ├── triggers/
│   │   └── test_audit_trigger.sql
│   ├── views/
│   │   └── test_active_users.sql
│   ├── rls/
│   │   └── test_post_policies.sql
│   ├── integration/
│   │   └── test_order_workflow.sql
│   └── migration/
│       └── test_sql_server_equivalence.sql
├── docker-compose.test.yml
└── Makefile
```

**Naming convention:** `test_[schema_]object_name.sql`

**Execution order:** `pg_prove` runs files alphabetically within directories. Use directory structure to control order: structure → functions → procedures → triggers → views → rls → integration.

### 10.2 GitHub Actions

```yaml
name: pgTAP Tests
on: [push, pull_request]

jobs:
  pgtap:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:17
        env:
          POSTGRES_PASSWORD: postgres
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432

    steps:
      - uses: actions/checkout@v4

      - name: Install pgTAP and pg_prove
        run: |
          sudo apt-get update
          sudo apt-get install -y postgresql-17-pgtap
          sudo cpan TAP::Parser::SourceHandler::pgTAP

      - name: Apply schema
        run: |
          PGPASSWORD=postgres psql -h localhost -U postgres -d postgres \
            -c "CREATE EXTENSION IF NOT EXISTS pgtap;"
          PGPASSWORD=postgres psql -h localhost -U postgres -d postgres \
            -f sql/schema.sql

      - name: Run pgTAP tests
        run: |
          pg_prove -h localhost -d postgres -U postgres \
            --ext .sql -r -v tests/
        env:
          PGPASSWORD: postgres
```

### 10.3 Makefile

```makefile
.PHONY: test test-verbose test-failed test-docker

test:
	pg_prove -d testdb -U postgres --ext .sql -r tests/

test-verbose:
	pg_prove -d testdb -U postgres -v --ext .sql -r tests/

test-failed:
	pg_prove -d testdb -U postgres --state failed,save --ext .sql -r tests/

test-shuffle:
	pg_prove -d testdb -U postgres --shuffle --ext .sql -r tests/

test-docker:
	docker compose -f docker-compose.test.yml up \
	  --abort-on-container-exit --exit-code-from tests
```

---

## 11. The testable surface: what CAN and CANNOT be tested

### 11.1 Fully testable with pgTAP

- Schema structure (tables, columns, types, constraints, indexes)
- Function/procedure existence and signatures
- Function return values and side effects
- Trigger firing and behavioral effects
- View query results
- RLS policy enforcement
- Constraint violations (NOT NULL, UNIQUE, FK, CHECK, EXCLUSION)
- Permission grants and denials
- Extension presence and configuration
- Performance thresholds (performs_ok)
- Custom RAISE EXCEPTION messages and codes

### 11.2 Partially testable (with workarounds)

- Procedures with internal COMMIT/ROLLBACK (see section 7.1)
- Temporary table contents (see section 7.2)
- Dynamic SQL behavior (see section 7.3)
- Materialized view refresh timing
- Connection-level settings (SET statements)

### 11.3 Not testable with pgTAP

- Execution plans (use EXPLAIN ANALYZE separately)
- Lock contention and deadlock behavior
- Replication lag
- Vacuum and autovacuum behavior
- Connection pooling (PgBouncer)
- Operating system interactions (file I/O, cron jobs)
- Network-level FDW connectivity (test the query results, not the connection)

---

## 12. References

- [pgTAP Official Documentation (v1.3.4)](https://pgtap.org/documentation.html)
- [pg_prove Documentation](https://pgtap.org/pg_prove.html)
- [pgTAP Integration Guide](https://pgtap.org/integration.html)
- [Practicing pgTAP Repository](https://github.com/ufukkulahli/practicing-pgTAP)
- [AWS pgTAP Guide](https://aws.amazon.com/blogs/database/create-a-unit-testing-framework-for-postgresql-using-the-pgtap-extension/)
- [PostgreSQL Error Codes](https://www.postgresql.org/docs/current/errcodes-appendix.html)
- [PostgreSQL Transaction Management](https://www.postgresql.org/docs/current/plpgsql-transactions.html)
- [TDAD Paper: Test-Driven Agentic Development](https://arxiv.org/html/2603.17973)
- Test-Driven Development: A Complete Methodology Reference (companion document)
- TDD Reference Library (curated sources)

---

**Maintained by:** Pierre Ribeiro (DBA/DBRE)
**Last Updated:** 2026-03-26
**Version:** 2.0.0
