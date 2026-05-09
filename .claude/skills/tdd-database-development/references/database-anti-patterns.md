# Database Anti-Patterns — What NOT to Bake Into Tests

Read this when:

- You are RED and the orchestrator's spec smells off — does it bake in an anti-pattern?
- You are GREEN and the simplest path tempts you into one.
- You are REFACTOR and you have local, safe license to fix one.

This catalog is **engine-agnostic** and draws from the academic survey by Alshemaimri
et al. (2021) on problematic database code fragments, plus Karwin's *SQL Antipatterns*.
The categories and impacts are the established taxonomy.

**Iron rule for any sub-agent: if the test or implementation under your hand requires an
anti-pattern below, STOP and flag it in your report.** Do not silently encode the
anti-pattern. The orchestrator decides whether to override.

---

## 1. Schema anti-patterns (logical design)

### 1.1 Compound attribute (CSV-in-column / multi-value string)

Storing multiple values in one column as a delimited string.

```
-- ❌ anti-pattern
CREATE TABLE products (
  id    BIGINT PRIMARY KEY,
  tags  TEXT       -- "red,large,sale"  ← compound
);
```

**Impacts**: performance (no index on individual values, full-text scans), maintainability
(parsing in every query), portability (delimiter / pattern-matching syntax differs across
engines), data integrity (no validation of individual values, ambiguous separators).

**Fix**: child table or array type with element-level constraints.

### 1.2 Adjacency list as the only tree model

Tree stored only as `parent_id`, with no recursive CTE strategy or alternative model
(path enumeration, nested sets, closure table) for descendant queries.

**Impact**: each level of depth is another join. Production systems with deep hierarchies
(comment threads, org charts, BOMs) drown in N-level joins.

**Fix**: Recursive CTE for moderate trees; closure table for deep / write-heavy trees;
nested set for read-heavy / static trees. **Pick consciously.**

### 1.3 Superfluous key (ID column on a junction table)

A junction (intersection) table whose natural composite key is `(emp_id, dept_id)`, with
a redundant auto-incrementing `id` column added "because every table has an id".

```
-- ❌ anti-pattern
CREATE TABLE employees_departments (
  id        BIGINT PRIMARY KEY,         -- redundant
  emp_id    BIGINT NOT NULL,
  dept_id   BIGINT NOT NULL
  -- no UNIQUE on (emp_id, dept_id) → duplicate (1,2),(1,2) is allowed!
);
```

**Impact**: data integrity (allows duplicate logical rows), maintainability (joins
become ambiguous).

**Fix**: composite PK on `(emp_id, dept_id)`. Drop the surrogate.

### 1.4 Missing referential integrity constraint

Foreign-key relationships exist in the application's mental model but are not declared
in the schema. The code "knows" `orders.customer_id` references `customers.id` — but the
database does not enforce it.

**Impacts**: data integrity (orphan rows under any concurrency), maintainability (every
INSERT requires app-level pre-check; every DELETE requires app-level cleanup), and
production systems acquire orphaned-row repair scripts.

**Fix**: declare the FK. If you cannot (legacy data violations), declare it `NOT VALID`
where the engine supports it, then validate after cleanup.

### 1.5 Metadata as data (Entity-Attribute-Value / EAV / "open schema")

A generic `attributes` table storing `entity_id, attr_name, attr_value` as rows.

```
-- ❌ anti-pattern
CREATE TABLE entity_attributes (
  entity_id  BIGINT,
  attr_name  TEXT,
  attr_value TEXT,
  PRIMARY KEY (entity_id, attr_name)
);
```

**Impacts**: performance (Chen et al. measured 3–5× slower than conventional design in a
clinical DB), data integrity (no per-attribute typing, no per-attribute NOT NULL, no FK
on values), maintainability (every read is a horror of self-joins).

**Fix**: model the actual entity types. Use single-table inheritance, concrete-table
inheritance, or class-table inheritance. Reach for native JSON/XML *only* when the
schema is genuinely open-ended and constraint enforcement is acceptable as a loss.

### 1.6 Polymorphic association (FK that points to "one of several tables")

A column that conceptually FKs to one of several tables, with a discriminator column
indicating which table.

```
-- ❌ anti-pattern
CREATE TABLE comments (
  id              BIGINT PRIMARY KEY,
  parent_id       BIGINT NOT NULL,
  parent_type     TEXT   NOT NULL  -- 'post' or 'photo' or 'video'
  -- no FK possible: parent_id can target 3 different tables
);
```

**Impacts**: performance (no FK index optimization across types), maintainability
(joins are 3-way unions), data integrity (no FK enforcement at all).

**Fix**: separate FK column per parent type with a CHECK that exactly one is non-NULL,
or a supertype table that all child tables FK into, or distinct tables per
relationship.

### 1.7 Multicolumn repeating attribute

Multiple columns for what is logically a list.

```
-- ❌ anti-pattern
CREATE TABLE products (
  id     BIGINT PRIMARY KEY,
  color1 TEXT,
  color2 TEXT,
  color3 TEXT
);
```

**Impacts**: performance (locking on schema change to add color4), maintainability
(every "where is this color" query unions three columns), data integrity (no UNIQUE
across the three).

**Fix**: child table `product_colors`.

### 1.8 Clone tables (manual sharding via duplicated tables)

Hand-rolled horizontal partitioning via duplicated tables: `orders_2023`, `orders_2024`,
`orders_2025`. Application code unions them.

**Impacts**: maintainability (new table every time period), portability (UNION ALL
support varies; engine-native partitioning would be standard), data integrity (no FK
can target N different tables).

**Fix**: engine-native partitioning (declarative partitioning, partitioned tables) where
available; otherwise a single table with appropriate indexes.

### 1.9 Values in attribute definition (CHECK constraint as an enum)

Hard-coding a small set of allowed values into a CHECK constraint.

```
-- ❌ anti-pattern (when the set is expected to evolve)
CHECK (status IN ('FULL_TIME', 'PART_TIME', 'INTERN'))
```

**Impacts**: maintainability (every new value requires `ALTER TABLE`), portability
(some engines lock the table for the alter), discoverability (the set lives in DDL,
not in a queryable table).

**Fix**: lookup table with FK. The constraint becomes the FK, the values become rows.

### 1.10 Implicit columns (`SELECT *`)

Application or stored code that uses `SELECT *` and depends on column order or count.

**Impacts**: maintainability (a new column added breaks downstream code that bound by
position), portability (column-order semantics differ across engines), data integrity
(silent shifts when a column is added or removed).

**Fix**: enumerate columns explicitly in every SELECT that ships beyond an interactive
shell.

---

## 2. Schema anti-patterns (physical design)

### 2.1 Index shotgun

Indexes added without measuring. Three flavors:

- **Too few**: a heavily filtered column with no index — every read is a scan.
- **Too many**: every column indexed "just in case" — writes pay for indexes nobody
  reads from.
- **Wrong**: indexes that no query plan can use (column-order mismatch, function-based
  query without functional index, etc.).

**Impact**: performance — both directions. Tests that "an index exists" are necessary
but not sufficient. Reviews (and the REFACTOR phase, when warranted) catch index
shotgun.

**Fix**: index every FK; index every frequent equality predicate; measure before adding
more.

### 2.2 God table / denormalized base

One table with 50+ columns, mixing concepts (customer + order + product + invoice all
flattened together).

**Impacts**: data integrity (update anomalies — change a customer name in one row,
forget the others), maintainability (every form maps to half the columns), performance
(rows balloon; cache hit rate falls).

**Fix**: normalize first. Denormalize for measured read performance only, keeping the
normalized source of truth.

---

## 3. Query anti-patterns

### 3.1 Reference non-grouped columns (single-value rule violation)

```
-- ❌ anti-pattern (some engines accept this and return arbitrary values)
SELECT student_id, student_name, MAX(grade)
FROM scores
GROUP BY student_id    -- student_name is non-grouped, non-aggregated
```

**Impact**: portability — strict engines reject; loose engines (older MySQL, SQLite)
accept and return *any* row for non-grouped columns.

**Fix**: include all non-aggregated columns in `GROUP BY`, or aggregate them, or
restructure with a derived/lateral subquery.

### 3.2 Joining data in memory (application-side join)

The application fetches table A, fetches table B, then loops in app code to combine
them — instead of letting the database JOIN.

**Impacts**: performance (network bandwidth for two full extracts), scalability (memory
caps), maintainability (the join logic lives in app code, far from the data).

**Fix**: write the JOIN. If data is in two different databases, the cross-database
mechanism (federated tables, foreign data wrapper, materialized projection) is still
better than two extracts and a hand loop.

### 3.3 Buried NULL

Operating on NULL with arithmetic or `=`.

```
-- ❌ NULL + 10 = NULL, not 10
UPDATE students SET salary = salary + 10

-- ❌ '=' with NULL is NULL, not TRUE/FALSE
WHERE manager_id = NULL          -- always returns 0 rows
```

**Impact**: data integrity (silent miscomputation), maintainability (subtle bugs in
arithmetic and predicates).

**Fix**: explicit `IS NULL`, `COALESCE(...)`, three-valued logic awareness.

### 3.4 Pattern-matching predicates (leading wildcard)

```
-- ❌ leading % defeats the index
WHERE email LIKE '%@example.com'
```

**Impact**: performance — full-table scan on every query.

**Fix**: full-text index where the engine supports it; reverse-string column with
trailing-wildcard match; pre-extracted column (`email_domain`).

### 3.5 Spaghetti query (one SELECT does too much)

A 600-line SELECT with 12 joins, 4 subqueries, 8 CASE expressions, mixing concerns
that the planner cannot reason about.

**Impacts**: performance (the planner gives up and picks a poor plan), maintainability
(no human can reason about it).

**Fix**: split into clearly named CTEs / views / temp tables, each handling one concept.
Often this surfaces a missing aggregate / dimension table.

### 3.6 Random selection — `ORDER BY random() LIMIT 1`

```
-- ❌ scans the entire table to sort it randomly
SELECT * FROM very_large_table ORDER BY random() LIMIT 1
```

**Impact**: performance — O(N) every call.

**Fix**: store and increment counters, sample by ID range, use engine-native sampling
(`TABLESAMPLE`).

### 3.7 Poor man's search engine

Building free-text search out of `LIKE '%term%'` chains.

**Fix**: full-text indexes (engine-native or external).

### 3.8 Implicit columns via `SELECT *` in stored code

Stored procedures, views, triggers that use `SELECT *` from a table whose shape may
change.

**Fix**: enumerate columns. (Already covered as a schema anti-pattern; it shows up at
query level too.)

---

## 4. Application-level anti-patterns

### 4.1 N+1 query (a query per row)

The application asks for N rows, then loops asking for related data per row, producing
N+1 round-trips.

**Fix**: a single JOIN; or batched IN-list query; ORM eager-loading.

### 4.2 Missing transactions for multi-statement invariants

Multiple writes that must succeed or fail together, not wrapped in a transaction.

**Fix**: explicit `BEGIN ... COMMIT` (or savepoint) for any multi-statement invariant.

### 4.3 SQL injection via string concatenation

Building queries by concatenating user input.

**Fix**: parameterized queries / prepared statements / engine-native bind variables.
**No exceptions.**

### 4.4 Connection-per-request without pooling

Opening and closing a database connection for each app request.

**Fix**: connection pooling at the application or sidecar layer.

### 4.5 Read replicas read-after-write surprise

Application writes to primary, immediately reads from replica, gets stale data.

**Fix**: route reads-after-write back to primary, or wait for replica catch-up, or
accept eventual consistency consciously and design for it.

---

## 5. Test anti-patterns (specific to the TDD cycle)

These are things the RED, GREEN, or REFACTOR sub-agent might do that violate TDD.

### 5.1 Test that asserts on the implementation, not the behavior

```
-- ❌ test of internals
ASSERT function_body_contains(name='calculate_total', text='WITH cte AS')

-- ✅ test of behavior
ASSERT calculate_total(order_id => 1) = 40
```

### 5.2 Test that depends on another test's state

State must be arranged inside each test's envelope. The engine isolation strategy
(transactional rollback / ephemeral schema / TRUNCATE) makes this safe.

### 5.3 Test that passes immediately on first run (RED phase failure)

If RED writes a test that passes without writing any production code, either the
behavior already exists (cycle is unnecessary) or the test is not asserting what it
should. **Stop and flag**, do not proceed to GREEN.

### 5.4 Multiple acts and asserts in one test (Arrange-Act-Assert-Act-Assert)

Splits to two tests. See `aaa-pattern-database.md`.

### 5.5 Magic numbers in assertions

Replace with named constants (`EXPECTED_TOTAL = 40`).

### 5.6 Modifying tests to make a refactor pass

REFACTOR must not weaken or delete tests. If the refactor cannot keep tests green, it
is changing behavior — escalate, don't push through.

### 5.7 Disabling existing tests to "unblock" a new one

Hard violation. If the new test contradicts an existing test, escalate.

### 5.8 Writing implementation in the RED phase

Writing CREATE/ALTER/INSERT/UPDATE in the RED phase. Hard violation; the test is the
deliverable.

### 5.9 Writing more code than the test demands (GREEN over-engineering)

Adding columns, indexes, parameters, branches that no current test asserts on. By the
Iron Law, that code should not exist yet.

### 5.10 Writing a passing test alongside the implementation (in GREEN)

Tests written after the code is the post-hoc test anti-pattern, not TDD. Coverage
collapses to 10–60%; test design is biased by implementation. Delete and let the next
RED cycle drive it.

---

## 6. Quick scan checklist (apply before writing test or impl)

- [ ] Does the column store a list as text? → **Compound attribute**
- [ ] Does an intersection table have a redundant auto-id? → **Superfluous key**
- [ ] Is a logical FK declared in code but absent in DDL? → **Missing RI**
- [ ] Is there an EAV-style key/value table? → **Metadata as data**
- [ ] Does a `parent_type` column accompany a `parent_id`? → **Polymorphic FK**
- [ ] Are there `color1, color2, color3` style columns? → **Multicolumn repeating**
- [ ] Is there a hand-partitioned table family? → **Clone tables**
- [ ] Is a value-set encoded in a CHECK constraint expected to grow? → **Values in DDL**
- [ ] Does a stored object `SELECT *`? → **Implicit columns**
- [ ] 50+ column table mixing concepts? → **God table**
- [ ] Free-text search via `LIKE '%x%'`? → **Poor man's search engine**
- [ ] Does the test name contain "and"? → **AAA-A-A** — split it
- [ ] Does the test pass on first run? → **RED phase failure** — stop and flag

---

## See also

- `database-patterns.md` — the inverse: what to do
- `aaa-pattern-database.md` — how to test for / avoid these
- `role-red-test-writer.md` — flag instead of test
- `role-refactor-refactorer.md` — fix when local + safe
- Source: Alshemaimri et al. (2021) *A survey of problematic database code fragments
  in software systems*, Engineering Reports (Wiley); Karwin, *SQL Antipatterns*.
