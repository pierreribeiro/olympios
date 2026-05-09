# TDD Workflow — Mandatory for All Database Code

These rules apply to every session. TDD is a constitutional mandate (Constitution v2.0, Preamble).

## The Three Laws (Non-Negotiable)

1. NEVER write `CREATE FUNCTION`, `CREATE PROCEDURE`, `CREATE TRIGGER`, `CREATE VIEW`, or `ALTER TABLE` without a **failing pgTAP test first**.
2. Confirm the test **actually fails** (RED) before writing any implementation.
3. Write the **simplest code** that makes the test pass (GREEN). Do not anticipate future requirements.

## Red-Green-Refactor Cycle

- **RED**: Write pgTAP test → run `pg_prove` → ALL new tests MUST fail.
- **GREEN**: Write minimal SQL → run `pg_prove` → ALL tests MUST pass.
- **REFACTOR**: Optimize (indexes, query rewrites, naming) → run `pg_prove` after EACH change → stay GREEN.

## Execution Commands

```bash
# Run all tests
pg_prove -d testdb -U postgres --ext .sql -r tests/

# Run specific test file
pg_prove -d testdb -U postgres -v tests/functions/test_my_function.sql

# Run only previously failed tests
pg_prove -d testdb -U postgres --state failed,save --ext .sql -r tests/
```

## When Modifying Existing Code

1. Verify a pgTAP test exists for the object being modified.
2. If NO test exists → write one FIRST (test current behavior).
3. Modify the test to reflect desired new behavior → confirm RED.
4. Modify implementation → confirm GREEN.
5. Run FULL test suite to check for regressions.

## Commit Discipline

- Commit failing test BEFORE implementation (message: `test: add failing test for X`).
- Commit passing implementation separately (message: `feat: implement X`).
- Commit refactoring separately (message: `refactor: optimize X`).
