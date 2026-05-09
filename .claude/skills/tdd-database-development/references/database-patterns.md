# Database Patterns — What Good Looks Like

Read this when you are the GREEN sub-agent (deciding the simplest correct implementation)
or the REFACTOR sub-agent (deciding what local improvement is safe). The patterns are
**engine-agnostic** and **declarative-first**. Translate to dialect with the engine-
specific TDD skill.

The principle running through every pattern: **the database is a tool for protecting
invariants, not a dumb data dump.** Constraints and types carry the semantics. Application
code should never have to re-check what the database already guarantees.

---

## 1. Schema patterns

### 1.1 Atomic columns (1NF)

Every column holds a single, indivisible value of a single type. No comma-separated
lists, no JSON-as-relations, no "first_name middle_name last_name" mashed into one
column.

```
-- ✅ atomic
CREATE TABLE users (
  id        BIGINT PRIMARY KEY,
  email     TEXT   NOT NULL UNIQUE,
  full_name TEXT   NOT NULL
);

-- ❌ non-atomic — see anti-patterns: Compound attribute
CREATE TABLE users (
  id    BIGINT PRIMARY KEY,
  tags  TEXT   -- "admin,billing,readonly"
);
```

If you need a list, use a child table or an array type — not a delimited string.

### 1.2 Strong primary keys

Every table has a primary key. Pick one of:

- A **natural key** if it is stable, non-NULL, and singular (rare in practice).
- A **surrogate key** (auto-generated `id`) when no good natural key exists.
- A **composite key** for intersection / junction tables — and **do not** also add a
  redundant surrogate `id` (see anti-pattern: Superfluous key).

```
-- ✅ junction table — composite PK is the natural key
CREATE TABLE employees_departments (
  emp_id    BIGINT NOT NULL REFERENCES employees(id),
  dept_id   BIGINT NOT NULL REFERENCES departments(id),
  PRIMARY KEY (emp_id, dept_id)
);
```

### 1.3 Referential integrity is not optional

Every logical foreign relationship is a declared FK. The database enforces it. Tests
must verify the FK exists.

```
-- ✅ FK declared, ON DELETE / ON UPDATE chosen consciously
CREATE TABLE orders (
  id          BIGINT PRIMARY KEY,
  customer_id BIGINT NOT NULL
              REFERENCES customers(id) ON DELETE RESTRICT,
  total       NUMERIC(12,2) NOT NULL CHECK (total >= 0)
);
```

If your engine cannot enforce FKs (some columnar/distributed systems), document the
gap and write integration tests that verify the invariant another way.

### 1.4 Declarative beats imperative

A database constraint beats a trigger. A trigger beats application code. A view beats
a stored summary table. A generated column beats a value computed in two places.

| Need | Reach for first | Avoid if possible |
|------|-----------------|-------------------|
| Reject invalid value | `CHECK` constraint, type, domain | Trigger |
| Set default value | `DEFAULT` clause | Trigger / app code |
| Compute derived value | `GENERATED` column, view | Trigger / denormalized column |
| Enforce uniqueness | `UNIQUE` constraint | App-level pre-check |
| Cascade on delete | `ON DELETE CASCADE` (when intent matches) | Trigger / app loop |

Use a trigger only when the engine cannot express the rule declaratively.

### 1.5 Normalization first, denormalize with intent

Start with 3NF / BCNF. Denormalize **only** as a deliberate, measured response to a
real performance problem — and document the redundancy with a CHECK or trigger that
keeps the copies in sync. Premature denormalization creates the *god table* anti-pattern.

### 1.6 Tree data — choose the right model

The naïve adjacency list (`parent_id`) does not scale to "give me all descendants" queries
without recursive CTEs or repeated joins. For tree-heavy use cases, evaluate:

- **Recursive CTE on adjacency list** — simplest, OK for shallow / small trees.
- **Path enumeration** (`/1/4/12/`) — fast ancestor queries, hard to move subtrees.
- **Nested sets** (`lft`, `rgt`) — fast subtree reads, slow writes.
- **Closure table** (separate ancestor/descendant table) — flexible, more storage.

The right choice depends on read/write ratio. The pattern is: pick **one** explicitly,
test for the operations that matter (descendants, ancestors, subtree move, depth).

### 1.7 Soft delete with explicit semantics

If you soft-delete (`deleted_at TIMESTAMP NULL`), every "live data" view filters it out
**and** is the only object the application reads from. Mixing live and deleted in the
same base table without a view is a recurring bug.

```
CREATE VIEW v_active_users AS
SELECT * FROM users WHERE deleted_at IS NULL;
```

Tests verify both the view filters correctly and that updates use the view (or filter
identically).

---

## 2. Function / procedure patterns

### 2.1 Pure functions are testable

A pure function depends only on inputs and returns only outputs — no SELECT from session
state, no UPDATE, no INSERT, no clock/random/sequence reads inside the function.

```
-- ✅ pure
CREATE FUNCTION calculate_total(items ITEM_TABLE) RETURNS NUMERIC
  ...

-- ⚠️ side-effecting — split into a procedure or accept the impurity explicitly
CREATE FUNCTION place_order(customer_id BIGINT) RETURNS BIGINT
  -- writes to orders, audit_log, ...
```

Pure functions test in microseconds. Side-effecting code requires arrange-and-verify
patterns — not wrong, just slower. Keep them separate.

### 2.2 Idempotent operations

Operations that can be retried safely (a network blip, a job retry) without producing
duplicates. Achieve idempotency by:

- A natural unique key per operation (request_id, idempotency_key).
- `INSERT ... ON CONFLICT DO NOTHING` (or engine equivalent) keyed on that unique key.
- A status field that the operation transitions monotonically (PENDING → DONE).

Test that a second invocation with the same key produces no second row and no second
side effect.

### 2.3 Explicit error contracts

Functions and procedures raise specific, documented errors. Tests assert on the **error
class/code**, not on a free-text message (which may be localized).

```
-- ✅ raise with a stable code
RAISE 'foreign_key_violation' USING errcode = '23503'

-- ❌ raise free-text only
RAISE 'something went wrong'
```

### 2.4 Set-based, not row-by-row

When the engine supports SQL set operations, prefer them to PL loops. A loop hides
behavior from the planner, makes the function harder to test, and rarely outperforms
set-based code at scale.

```
-- ✅ set-based
INSERT INTO archive_orders SELECT * FROM orders WHERE archived_at IS NOT NULL

-- ❌ row-by-row
FOR row IN SELECT * FROM orders WHERE archived_at IS NOT NULL LOOP
  INSERT INTO archive_orders VALUES (row.*)
END LOOP
```

---

## 3. Trigger patterns

Triggers are powerful and over-used. Use them when:

- The behavior is a side effect (audit log, derived count, notification).
- The behavior MUST happen on every write path, including ad-hoc DML, bulk loads, and
  out-of-band fixes — i.e., it must live where the data lives.

Avoid them when:

- A CHECK constraint, GENERATED column, or DEFAULT can express the rule.
- The behavior is business logic that benefits from being explicit in application code.

When you do write a trigger, test:

- It fires on the events you intended (INSERT/UPDATE/DELETE, AFTER/BEFORE).
- It does **not** fire on the events you excluded.
- It produces the exact side effect you specified.
- It is idempotent under duplicate or retried events if the side effect is observable.

---

## 4. Index patterns

### 4.1 Index every FK column unless you have a reason not to

Most engines do not auto-index foreign-key columns. Joins, ON DELETE CASCADE, and
constraint validation all suffer without it.

### 4.2 Match index column order to query predicates

A composite index `(customer_id, order_date)` serves predicates on
`customer_id` alone and `(customer_id, order_date)` together. It does NOT serve
predicates on `order_date` alone — that needs a separate index.

### 4.3 Partial / filtered indexes for sparse predicates

If 95% of rows have `deleted_at IS NULL` and queries always filter on it, a partial
index `WHERE deleted_at IS NULL` is small, fast, and write-cheap.

### 4.4 Test the **existence and shape** of the index, not its plan use

```
ASSERT index_exists(table='orders', name='idx_orders_customer_date')
ASSERT index_columns(table='orders', name='idx_orders_customer_date')
     = ['customer_id', 'order_date']
```

If you really need to test that a query *uses* the index (a performance test), do so
explicitly with the engine's plan-inspection mechanism — and accept the test will be
brittle across engine versions.

---

## 5. Concurrency patterns

### 5.1 Pick an isolation level — explicitly

Default isolation differs across engines (READ COMMITTED, REPEATABLE READ, SNAPSHOT).
For any transaction that performs a check-then-act (read a row, decide, write a row),
you need at least REPEATABLE READ or SERIALIZABLE — or row-level locking.

### 5.2 Lock acquisition order

If transactions can acquire multiple locks, all transactions acquire them in the same
order. Otherwise: deadlocks. Tests cannot easily catch this; reviews can.

### 5.3 No application-side referential integrity

Application code should never SELECT to verify a parent row exists, then INSERT a child.
Either declare a FK or accept the inevitable race condition. (See anti-pattern: Missing
referential integrity constraints.)

---

## 6. Migration patterns

### 6.1 Forward-only, idempotent

Migrations move forward. Down-migrations are useful for development but rarely run in
production. Each migration is idempotent (`IF NOT EXISTS` / engine equivalent) so a
partial-failure retry does not break.

### 6.2 Backward-compatible deploy in steps

Schema changes that an old application version cannot tolerate must be split:

1. **Expand**: add the new column / table, populate, double-write from the application.
2. **Deploy** the new application code that reads/writes the new shape.
3. **Contract**: drop the old column / table after the old application is gone.

Tests cover each step independently.

### 6.3 Migrations have tests too

Test:

- New objects exist after migration.
- Existing rows are preserved (count, key set).
- Computed values match a known oracle (pre-migration view = post-migration view).

See the AAA reference: *Migration equivalence*.

---

## 7. Test data patterns

### 7.1 Tests own their data

Each test arranges its own fixture inside its isolation envelope. No shared seed file
that tests inherit from. (Shared schema is fine; shared **rows** are not.)

### 7.2 Realistic minimums

Use the smallest fixture that exercises the behavior. One row when one row is enough.
Two when comparison matters. Hundreds only when the test is explicitly about scale.

### 7.3 Named expected values

Magic numbers in assertions become bugs. Declare:

```
EXPECTED_TOTAL = 40
ASSERT actual_total = EXPECTED_TOTAL
```

Not:

```
ASSERT actual_total = 40   -- 40 what? why?
```

---

## 8. The "reach for declarative" hierarchy — pick from the top

When deciding how to enforce a rule, scan this list top-down and stop at the first item
your engine supports:

1. **Type / domain** (the column literally cannot hold an invalid value).
2. **NOT NULL / DEFAULT** (the column cannot be empty / always has a sensible value).
3. **CHECK constraint** (the value passes a single-row predicate).
4. **UNIQUE / PRIMARY KEY** (no duplicates).
5. **FOREIGN KEY** (referential integrity).
6. **EXCLUDE constraint** (mutual-exclusion across rows; engine-specific).
7. **GENERATED column / VIEW** (the value is derived, not stored independently).
8. **Trigger** (last resort for declarative rules; first resort for side effects).
9. **Stored procedure / application code** (when the rule is genuinely procedural).

Most "I need a trigger" instincts terminate at step 1, 2, 3, or 7.

---

## See also

- `database-anti-patterns.md` — what NOT to do (the inverse of this file)
- `aaa-pattern-database.md` — how to test these patterns
- `role-green-implementer.md` — the role that reaches for these patterns
- `role-refactor-refactorer.md` — the role that fixes when these are missing
