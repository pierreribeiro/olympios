# Role Plan — `<RED | GREEN | REFACTOR>` — Run 1

> **Mandatory** before any sub-agent acts. Keep ≤ 1 page. Pseudo-code only.
> If you re-run this role on the same behavior, **append** a `## Run 2` section
> rather than overwriting. See `references/plan-and-report-protocol.md`.

---

## Behavior

> One sentence describing the behavior under test (RED), under implementation (GREEN),
> or under refactor (REFACTOR).

<one-sentence behavior statement>

---

## Inputs received

- Behavior description from orchestrator: `<...>`
- Test artifact path (GREEN/REFACTOR only): `<...>`
- Implementation paths (REFACTOR only): `<...>`
- Prior reports referenced: `<paths or "none">`

---

## Engine + engine-specific skill

- Engine: `<PostgreSQL 16 | Oracle 23ai | SQL Server 2022 | …>`
- Engine-specific skill: `<name>` — loaded: `<yes | no>`
- Fallback applied: `<none | native framework | application-level | pseudo-code only>`
- Pseudo-code only: `<yes | no>`

---

## Plan steps (≤ 5)

1. <step>
2. <step>
3. <step>
4. <step>
5. <step>

---

## What I will explicitly NOT do this cycle (anti-YAGNI guard rail)

- <related change deferred for a future cycle>
- <related change deferred for a future cycle>

---

## Anti-pattern check (`references/database-anti-patterns.md`)

- Any anti-pattern would be introduced by this cycle? `<no | yes — see flags>`
- Flagged anti-patterns: `<name + section number, or "none">`

---

## Open questions / blockers for the orchestrator

- `<question, or "none">`

---

## Expected outcome

- RED: test exists at `<path>` and FAILS with `<expected failure mode>`.
- GREEN: test at `<path>` passes; full suite is green.
- REFACTOR: `<list of improvements applied | "no refactoring needed">`; full suite stays green.

---

## Sign-off

Plan author: `<sub-agent role>` — `<ISO timestamp>`
