# REFACTOR — Decision Checklist

> Walk this checklist when evaluating a GREEN implementation. Each item is a
> *candidate* refactor, not a mandate. **Apply only when the change is
> behavior-preserving, low-risk, and adds clear value.** Tick `[Y]`, `[N]`, or
> `[N/A]` per row. Run the full test suite after **each** applied change. If
> any test fails, revert that single change and stop.
>
> Source: `references/role-refactor-refactorer.md` and `references/database-patterns.md`.

---

## Decision rules — refactor or skip?

**Refactor when** ANY of these is true:
- [ ] Clear duplication exists (within or across objects).
- [ ] A name actively misleads (`flag1`, `tmp`, `data2`).
- [ ] An imperative pattern can become declarative (CHECK / DEFAULT / GENERATED / FK / EXCLUDE).
- [ ] A schema-level anti-pattern is present AND the fix is local (no data migration).

**Skip when** ANY of these is true:
- [ ] Code is already minimal and idiomatic.
- [ ] The improvement would require new tests (= new behavior, not refactor).
- [ ] The improvement spans many files / risks several test failures (split into a follow-up cycle, flag).
- [ ] No test coverage exists for the area being touched (refactor without coverage = guess).

If you are skipping all candidates, return *"no refactoring needed"* with reasoning. That is a valid outcome.

---

## A. Schema-level candidates

| # | Candidate | Apply? | Notes |
|---|-----------|--------|-------|
| A1 | Rename column / table / function with misleading name (engine rename mechanism, tests updated together) | [ ] | |
| A2 | Tighten column type (TEXT → DOMAIN / ENUM-equivalent / INTEGER / BOOLEAN / specific NUMERIC precision) | [ ] | |
| A3 | Replace trigger-based default with `DEFAULT` clause | [ ] | |
| A4 | Replace trigger-based derived column with `GENERATED` column | [ ] | |
| A5 | Replace application-level invariant check with `CHECK` constraint | [ ] | |
| A6 | Replace duplicated value list with lookup table + FK (Values-in-DDL anti-pattern) | [ ] | |
| A7 | Split compound attribute (CSV-in-column) into atomic columns or child table | [ ] | |
| A8 | Replace multicolumn repeating attribute (`color1, color2, color3`) with child table | [ ] | |
| A9 | Add missing FK now that referenced table exists | [ ] | |
| A10 | Add missing NOT NULL / UNIQUE / CHECK that current tests already cover | [ ] | |
| A11 | Drop redundant surrogate key on a junction table (Superfluous-key anti-pattern) | [ ] | |

> Schema-level refactors that require **data migration** (touching live rows) are NOT
> in scope for the REFACTOR phase. Flag them and return to the orchestrator.

---

## B. Code-level candidates (functions / procedures / triggers / views)

| # | Candidate | Apply? | Notes |
|---|-----------|--------|-------|
| B1 | Extract repeated logic into a helper function or view | [ ] | |
| B2 | Flatten nested IFs; replace cascading IFs with CASE | [ ] | |
| B3 | Replace imperative loop with set-based SQL (when engine supports it) | [ ] | |
| B4 | Improve variable / parameter / label names | [ ] | |
| B5 | Remove copy-pasted blocks within a function or across functions | [ ] | |
| B6 | Split a side-effecting "function" into a pure function + a separate procedure | [ ] | |
| B7 | Replace `SELECT *` with explicit column list (Implicit-columns anti-pattern) | [ ] | |
| B8 | Replace polymorphic FK column-pair with proper structure (only if local + safe) | [ ] | |

---

## C. Test-level candidates

| # | Candidate | Apply? | Notes |
|---|-----------|--------|-------|
| C1 | Rename test to describe behavior (drop numbering, drop "test_001") | [ ] | |
| C2 | Extract setup duplication into a fixture / helper | [ ] | |
| C3 | Replace magic numbers in assertions with named constants (`EXPECTED_TOTAL = 40`) | [ ] | |
| C4 | Split a test whose name contains "and" into two tests | [ ] | |
| C5 | Remove a test that asserts internals (function body / plan choice) where behavior coverage already exists elsewhere | [ ] | |

> **NEVER weaken or delete a test** to make a refactor pass. If the refactor cannot keep
> tests green, it is changing behavior — escalate, do not push through.

---

## Hard constraints — violations revert your work

- [ ] Behavior preservation: full suite was green BEFORE every change AND green AFTER.
- [ ] One change at a time: no bundled refactors, suite run between each.
- [ ] No new behavior introduced (no new column / index / parameter / branch).
- [ ] No tests deleted or weakened.
- [ ] Plan written before acting.
- [ ] Final full-suite run is captured in the report (even when no change was applied).

---

## Final outcome — pick exactly one

- [ ] **Refactor applied** — list the candidates ticked above; suite green; details in
  the report.
- [ ] **No refactoring needed** — implementation is minimal, idiomatic, and clean;
  reasoning in the report.
- [ ] **Flagged** — improvement opportunity exists but is out of REFACTOR scope (data
  migration / cross-cutting / no test coverage); details + recommendation in the report.

Whichever outcome, run the full suite at the end and capture the result in the report.

---

## See also

- `references/role-refactor-refactorer.md` — the role guide
- `references/database-patterns.md` — the patterns to reach for
- `references/database-anti-patterns.md` — what to fix when local + safe
- `assets/templates/role-report-template.md` — where to record the outcome
