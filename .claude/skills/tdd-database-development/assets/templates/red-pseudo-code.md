# RED — Failing Test Pseudo-Code Skeleton

> Engine-agnostic skeleton. The RED sub-agent translates this to the engine's syntax
> using the engine-specific TDD skill. Each test follows AAA strictly. **One** behavior,
> **one** action, **one** outcome.

---

## Skeleton — single behavior

```
BEGIN_TEST "<descriptive_name_describing_the_behavior>"

  -- ARRANGE -----------------------------------------------------
  -- prerequisites: schema/table/seed rows/session state/expected values
  -- example:
  --   INSERT INTO <table> (<cols>) VALUES (<values>)
  --   SET_SESSION_USER(<role>, <user_id>)
  --   EXPECTED_<thing> = <value>

  -- ACT ---------------------------------------------------------
  -- exactly one observable behavior
  -- example:
  --   <result> = CALL <function>(<args>)
  --   UPDATE <table> SET <col> = <new> WHERE <key> = <value>
  --   TRY ... CATCH AS <error_thrown> END_TRY  (when expecting an error)

  -- ASSERT ------------------------------------------------------
  -- exactly one observable outcome (one or more lines, but ONE outcome)
  -- example:
  --   ASSERT <result> = EXPECTED_<thing>
  --   ASSERT EXISTS(SELECT 1 FROM <table> WHERE <predicate>)
  --   ASSERT <error_thrown>.code = EXPECTED_ERROR_CODE

END_TEST
```

---

## Skeleton — degenerate / boundary case (start here per baby steps)

```
BEGIN_TEST "<function/object> handles the empty/null/zero case"

  -- ARRANGE -----------------------------------------------------
  -- minimal setup — just enough to invoke the behavior on emptiness
  EXPECTED_RESULT = <0 | NULL | empty set | specific error code>

  -- ACT ---------------------------------------------------------
  <result> = <invoke the behavior on the empty/null/zero input>

  -- ASSERT ------------------------------------------------------
  ASSERT <result> = EXPECTED_RESULT

END_TEST
```

---

## Skeleton — error / rejection case

```
BEGIN_TEST "<object> rejects <invalid input> with <expected error code>"

  -- ARRANGE -----------------------------------------------------
  -- whatever rows / state must exist for the rejection to happen
  EXPECTED_ERROR_CODE = '<engine-neutral name; engine skill maps to actual code>'

  -- ACT ---------------------------------------------------------
  TRY
    <statement that should be rejected>
  CATCH AS error_thrown
  END_TRY

  -- ASSERT ------------------------------------------------------
  ASSERT error_thrown.code = EXPECTED_ERROR_CODE

END_TEST
```

---

## Skeleton — side-effect verification (procedure / trigger)

```
BEGIN_TEST "<procedure/trigger> produces <expected side effect>"

  -- ARRANGE -----------------------------------------------------
  -- pre-state of the table that should be mutated
  rows_before = SELECT count(*) FROM <target_table> WHERE <predicate>

  -- ACT ---------------------------------------------------------
  <call the procedure | perform the DML that fires the trigger>

  -- ASSERT ------------------------------------------------------
  rows_after = SELECT count(*) FROM <target_table> WHERE <predicate>
  ASSERT rows_after = rows_before + <expected delta>
  -- (optional second assertion line: same outcome, more detail)
  ASSERT EXISTS(SELECT 1 FROM <target_table> WHERE <fields the side effect should set>)

END_TEST
```

---

## Skeleton — set equality (view / query / function returning a set)

```
BEGIN_TEST "<view/function> returns expected rows for known seed"

  -- ARRANGE -----------------------------------------------------
  -- seed exactly the rows needed
  INSERT INTO <table> (<cols>) VALUES (<row 1>), (<row 2>)
  EXPECTED_ROWS = [(<row a>), (<row b>)]   -- in deterministic order

  -- ACT ---------------------------------------------------------
  actual_rows = SELECT <cols> FROM <view/function> ORDER BY <deterministic_key>

  -- ASSERT ------------------------------------------------------
  ASSERT actual_rows = EXPECTED_ROWS

END_TEST
```

---

## Checklist — before claiming the test is ready

- [ ] Test name describes the behavior (no numbers, no "test_001").
- [ ] No "and" in the test name (split if it does).
- [ ] Three labeled sections: ARRANGE, ACT, ASSERT.
- [ ] Exactly **one** action in ACT.
- [ ] Exactly **one** logical outcome in ASSERT (one or more lines, one outcome).
- [ ] No assertions on internals (function body, plan choice — unless that IS the test).
- [ ] No reliance on previous tests' state.
- [ ] Wrapped in the engine isolation envelope (the engine skill specifies how).
- [ ] Test currently **fails** when run, AND fails for the right reason.

If any box is unchecked, the test is not ready. Iterate before sending the report.
