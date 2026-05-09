# TDD Principles — Condensed Reference

Read this when you need a methodology refresher. This file is the same for any role —
RED, GREEN, REFACTOR. It is intentionally short. The full reference is the
*Test-Driven Development: A Complete Methodology Reference* (Beck, Martin, Fowler,
Opalic, Alonso & Yovine) summarized into the rules an agent needs.

---

## 1. The Red-Green-Refactor cycle

The cycle is the heartbeat of TDD. A skilled practitioner completes 20–40 cycles per hour.

- **RED** — write a small failing test (≈ 5 lines) for behavior that does not yet exist.
  Run the suite. Confirm the new test fails *for the right reason*.
- **GREEN** — write the **absolute minimum** production code to make the failing test
  pass. Elegance does not matter; effectiveness is the only goal. Beck:
  *"Write a test, make it run, make it right. To make it run, one is allowed to violate
  principles of good design."*
- **REFACTOR** — improve structure without changing behavior. Tests are your safety net.
  Fowler: *"The most common way to screw up TDD is neglecting the third step."*

Martin: *"Our limited minds cannot pursue correct behavior and correct structure at the
same time. RGR splits the goal in two."*

---

## 2. The Three Laws of TDD (Robert C. Martin)

Operate at the **second-by-second nano-cycle** level:

1. You are **not allowed to write any production code** unless it is to make a failing
   unit test pass.
2. You are **not allowed to write any more of a unit test than is sufficient to fail** —
   compilation/parse failures count as failures.
3. You are **not allowed to write any more production code than is sufficient to pass**
   the one failing unit test.

For database work this means: no CREATE TABLE, no CREATE FUNCTION, no ALTER, no INSERT,
no UPDATE before a test that demands the object/behavior exists. No "while I'm here, I
might as well also add this column" — that is a separate cycle.

---

## 3. Baby steps, YAGNI, KISS

- **Baby steps**: cycles ≤ 5 minutes / ≤ 5 lines of code (Shore). The point is constant
  hypothesis-checking — the bar should turn red now... now it should turn green. Mistakes
  surface within a few lines, making them trivial to find.
- **YAGNI** (*You Ain't Gonna Need It*): the test defines exactly what is needed.
  Everything else is unnecessary. No anticipated columns, no "just in case" indexes, no
  speculative parameters in functions.
- **KISS** (*Keep It Simple, Stupid*): GREEN demands the simplest possible passing code;
  REFACTOR simplifies structure. Together they prevent over-engineering.

---

## 4. Emergent design

Design materializes incrementally from the cycles. During REFACTOR, listen to feedback:

- Was the test painful to name? → the behavior may be ill-defined.
- Did setup require tedious boilerplate? → the schema may be over-complicated.
- Is there duplication across tests or implementations? → an abstraction is hiding.
- Is the test asserting on internals? → the interface may be wrong.

Patterns are applied when problems appear, not speculatively. Emergent design does **not**
replace design knowledge — it provides a structured context for applying it.

---

## 5. The Arrange-Act-Assert (AAA) pattern

Every test is structured in three phases:

- **Arrange** — set prerequisites (create test schema, seed rows, set role/session,
  declare expected values).
- **Act** — execute the single behavior (call function, run DML, fire trigger).
- **Assert** — verify exactly one observable outcome.

Critical rule: it is **not** Arrange-Act-Assert-Act-Assert. A second action belongs in a
separate test. (BDD calls this Given-When-Then; same shape.) Full DB-flavored examples
in `aaa-pattern-database.md`.

---

## 6. The FIRST properties of a good test

- **F**ast — runs in milliseconds (unit) to seconds (integration).
- **I**solated — does not depend on or affect other tests; independent of execution order.
- **R**epeatable — same result every run, every environment.
- **S**elf-verifying — clear pass/fail without human inspection.
- **T**imely — written **before** the production code (i.e., it exists because TDD
  demanded it).

For database tests specifically: each test wraps in a transaction and rolls back, OR
truncates known tables in teardown, OR uses a fresh schema. Tests that mutate shared
state without cleanup are not isolated.

---

## 7. Tests as living documentation

TDD tests are *"design documents that are hideously detailed, utterly unambiguous, so
formal that they execute, and they cannot get out of sync with the production code"*
(Martin). A new contributor should be able to read the tests and understand the
database's behavior. This requires:

- Clear test names that describe behavior, not implementation
  (e.g., `test_email_constraint_rejects_missing_at_sign`, not `test_constraint_001`).
- Readable AAA sections with comments separating them.
- Setup that tells a story, not a reverse-engineering puzzle.

---

## 8. Subagent context isolation (Opalic)

When all phases run in **one** context window, the LLM cannot truly do TDD. The test
writer's analysis bleeds into the implementer's thinking; the implementer's exploration
pollutes the refactorer's evaluation. The agent designs tests around an implementation it
is already planning — it *cheats without meaning to*.

Solution — three sub-agents with separate context:

- **Test Writer (RED)** — has no idea how the feature will be implemented.
- **Implementer (GREEN)** — sees only the failing test; cannot be biased by test-writing.
- **Refactorer (REFACTOR)** — evaluates with fresh eyes, no implementation baggage.

Each sub-agent starts with exactly the context it needs and nothing more. This is **not**
organizational tidiness — it is the only way to achieve genuine test-first development
from an LLM. This skill exists to give each sub-agent that minimal, role-specific context.

---

## 9. The TDAD finding — context beats procedure (Alonso & Yovine)

A counter-intuitive empirical result: adding TDD procedural instructions to an AI agent
("write tests first, then implement") **without telling it which specific tests to check**
**increased regressions** from 6.08% to 9.94%. Worse than baseline.

Providing graph-derived context about which tests to verify dropped regressions to
**1.82% — a 70% reduction**. The central insight:

> Agents do not need to be told **how** to do TDD; they need to be told **which tests to
> check**.

Implication for this skill: keep instructions concise. The role files tell the sub-agent
its mandate and the **exact deliverables**, not a 9-step ritual. Each role file is short
on purpose. If you find yourself reading more than two files, you are over-loading.

---

## 10. Seven misconceptions to avoid

1. *TDD means writing all tests first.* — No. **One test at a time.**
2. *TDD replaces QA.* — No. TDD is regression + design; QA is exploratory + non-functional.
3. *TDD is unit testing.* — No. TDD is a development methodology; the cycle works at unit,
   integration, and acceptance scope.
4. *TDD skips architecture.* — No. Step back hourly to look at boundaries.
5. *TDD is slower.* — Adds 10–30% upfront, returns 40–90% defect reduction. Total
   lifecycle cost is lower.
6. *TDD guarantees no bugs.* — No. It is falsification, not proof.
7. *Tests after code is TDD.* — Emphatically **no**. Coverage of post-hoc tests sits
   between 10–60%; TDD coverage averages 95%.

---

## 11. The bottom line for a database sub-agent

```
Production DDL/DML/PSM → a failing test exists for this exact behavior, AND I watched it fail
Otherwise              → not TDD; stop, write the test first
```

If you ever find yourself thinking *"I'll add the test after — it's faster"*, that is the
rationalization the methodology was built to defeat. Stop. Start over with the test.

---

## See also (load only when needed)

- `aaa-pattern-database.md` — AAA in DB context with pseudo-code examples.
- `database-patterns.md` — what good DB design looks like.
- `database-anti-patterns.md` — what to refuse to bake into tests.
- `engine-skill-discovery.md` — how to find the engine-specific test skill.
- Role files: `role-red-test-writer.md`, `role-green-implementer.md`, `role-refactor-refactorer.md`.
