# GREEN — Minimum Implementation Pseudo-Code Skeleton

> Engine-agnostic skeleton. The GREEN sub-agent translates this to the engine's syntax
> using the engine-specific TDD skill. The Iron Law: **write the absolute minimum** to
> pass the one failing test. No anticipation. No "while I'm here". No future-proofing.

---

## Choosing the simplest path

For each common test type, the minimum implementation looks like this:

| Failing test asserts… | Minimum implementation |
|------------------------|------------------------|
| `object_exists(table='X')` | `CREATE TABLE X (id <pk_type> PRIMARY KEY)` — one column, the PK |
| `column_exists(table='X', column='Y')` | `ALTER TABLE X ADD COLUMN Y <minimal type>` |
| `column_not_null(table='X', column='Y')` | `ALTER TABLE X ALTER COLUMN Y SET NOT NULL` (after backfill if needed) |
| `column_unique(table='X', column='Y')` | Add `UNIQUE` constraint or `CREATE UNIQUE INDEX` |
| `fk_ok('X','Y','Ref','RefCol')` | `ALTER TABLE X ADD FOREIGN KEY (Y) REFERENCES Ref(RefCol)` |
| `result_eq(<query>, <expected>)` | Whatever DDL/DML produces that exact result for the seed |
| `function_returns_<value>(<args>)` | Function body that returns that value — even if hardcoded for the one input |
| `procedure_inserts_row` | Procedure that inserts the minimum row that satisfies the assertion |
| `trigger_fires_on_<event>` | Trigger that performs the minimum side effect on the asserted event |
| `error_raised_with_code <C>` | Constraint / RAISE that produces error code `C` |

If the test asserts a single specific case, hardcoding for that case is acceptable in
GREEN. The next RED cycle (with a second test case) will force you to generalize.

This is intentional. Beck: *"Make it run. To make it run, one is allowed to violate
principles of good design."*

---

## Skeleton — table

```
CREATE TABLE <name> (
  <pk_col>   <pk_type>   PRIMARY KEY
  <,         <only the columns the test asserts on>>
);
```

Do **not** add columns the test does not assert on. Do **not** add NOT NULL, DEFAULT,
UNIQUE, FK unless the test asserts the constraint. Each constraint is its own test.

---

## Skeleton — function

```
CREATE FUNCTION <schema>.<name>(<args>) RETURNS <type> AS
BEGIN
  -- the minimum body that passes the one current test
  -- e.g.:
  --   RETURN 0;                                 -- if test seeds empty input
  --   RETURN <hardcoded value>;                 -- if test seeds one specific input
  --   RETURN SUM(...) FROM <seeded table>;      -- if test seeds a sum-able set
END;
```

Generalization comes from the next RED cycle, not from anticipation.

---

## Skeleton — procedure

```
CREATE PROCEDURE <schema>.<name>(<args>) AS
BEGIN
  -- the minimum side effect the test asserts on, nothing more
  INSERT INTO <table> (<cols>) VALUES (<values from args>);
  -- no audit, no logging, no validation — unless a test asserts each
END;
```

---

## Skeleton — trigger

```
-- separate trigger function (when the engine separates them)
CREATE FUNCTION <schema>.<trigger_fn_name>() RETURNS TRIGGER AS
BEGIN
  -- the minimum side effect the asserted-on event should produce
  INSERT INTO <side_effect_table> (<cols>) VALUES (<values>);
  RETURN NEW;   -- or appropriate engine-specific return
END;

CREATE TRIGGER <trigger_name>
  AFTER <INSERT | UPDATE | DELETE> ON <table>
  FOR EACH ROW
  EXECUTE FUNCTION <schema>.<trigger_fn_name>();
```

If a separate test asserts the trigger does NOT fire on excluded events, do nothing
extra — the trigger's `AFTER <event> ON <table>` declaration already gives you that.

---

## Skeleton — view

```
CREATE VIEW <schema>.<view_name> AS
SELECT <only the columns asserted on>
  FROM <source>
  WHERE <only the predicate the test demands>;
```

---

## Skeleton — constraint (added to existing table)

```
ALTER TABLE <table>
  ADD CONSTRAINT <name>
  <CHECK (<predicate>) | UNIQUE (<cols>) | FOREIGN KEY (<cols>) REFERENCES <ref>(<refcols>)>;
```

---

## Skeleton — index

```
CREATE <UNIQUE | empty> INDEX <name>
  ON <table> (<col>, <col>, ...)
  <WHERE <partial-index predicate>>;     -- only if a test asserts the partial nature
```

---

## Anti-checklist — what would mean you over-engineered

If, after writing the minimum implementation, you find any of these, **revert the
extras** before reporting:

- [ ] You added a column the failing test does not reference.
- [ ] You added a NOT NULL / DEFAULT / UNIQUE / CHECK / FK that no test asserts.
- [ ] You added an index that no test asserts.
- [ ] You added a parameter, branch, or loop that the failing test does not exercise.
- [ ] You added a "helper" function or view that no test calls.
- [ ] You added logging, comments-as-documentation, or "TODO" notes (those go in the
      report, not the code).
- [ ] You "improved" pre-existing code that the failing test does not touch.

Each unchecked item is a future RED cycle, not a GREEN cycle.

---

## Run-the-suite reminder

After writing the minimum implementation, run the **full** test suite, not just the new
test. Three outcomes:

| Outcome | Action |
|---------|--------|
| New passes, all pass | Done. Write report. Hand off to REFACTOR. |
| New passes, others fail | You broke something. Fix your code, not the failing tests. Iterate. |
| New still fails | Wrong code. Iterate. Do not modify the test. |

If you genuinely believe the failing test is wrong (would never pass for a correct
implementation), STOP and escalate to the orchestrator. Do not silently edit the test.

---

## See also

- `references/role-green-implementer.md` — the role guide
- `references/database-patterns.md` — declarative-first hierarchy
- `references/database-anti-patterns.md` — what your minimum code must NOT be
