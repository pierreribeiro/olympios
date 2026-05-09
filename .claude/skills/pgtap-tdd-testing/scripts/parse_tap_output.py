#!/usr/bin/env python3
"""
parse_tap_output.py — Parse pg_prove (TAP) output into structured data.

The Test Anything Protocol (TAP) is a simple line-based format. pgTAP and
pg_prove emit it on stdout. This script reads TAP from stdin (or a file)
and produces either a human-readable summary or machine-readable JSON,
making it easy to surface failures in CI logs, scripts, or chat.

USAGE
=====
    pg_prove -d mydb test/*.sql | python parse_tap_output.py
    pg_prove -d mydb test/*.sql | python parse_tap_output.py --json
    python parse_tap_output.py --input pgprove.log
    python parse_tap_output.py --input pgprove.log --json --fail-on-error

EXIT CODES
==========
    0 — All tests passed.
    1 — One or more tests failed (or plan mismatch). Only enforced with
        --fail-on-error; otherwise exit is always 0 so the script is safe
        to chain in pipelines that should not abort.
    2 — Could not parse input (no plan found, malformed TAP).

WHAT IT EXTRACTS
================
- Plan line:                "1..N"
- Test results:              "ok N - description" / "not ok N - description"
- Diagnostic lines:          "# diag text" (attached to the previous test)
- TODO and SKIP directives:  "ok N - desc # SKIP reason"
- Subtests (indented blocks): "    ok 1 - sub-desc"
- Bail out:                   "Bail out! reason"

OUTPUT (text mode)
==================
Prints a summary table: total / passed / failed / skipped / todo, then
a list of failed tests with their attached diagnostic lines (so you can
see "have/want", "Extra records:", "caught/wanted: ...", etc.).
"""

import argparse
import json
import re
import sys
from dataclasses import dataclass, field, asdict
from typing import List, Optional


# TAP grammar — line patterns we care about.
RE_PLAN = re.compile(r"^\s*(\d+)\.\.(\d+)\s*(?:#\s*(.*))?$")
RE_TEST = re.compile(
    r"^(?P<indent>\s*)"
    r"(?P<status>ok|not ok)"
    r"\s+(?P<num>\d+)"
    r"(?:\s*-?\s*(?P<desc>[^#]*?))?"
    r"(?:\s*#\s*(?P<directive>.*))?"
    r"\s*$"
)
RE_DIAG = re.compile(r"^(?P<indent>\s*)#\s?(?P<text>.*)$")
RE_BAIL = re.compile(r"^Bail out!\s*(?P<reason>.*)$", re.IGNORECASE)


@dataclass
class TestResult:
    """One TAP test line, plus any diagnostic lines that followed it."""
    number: int
    passed: bool
    description: str = ""
    directive: Optional[str] = None        # "SKIP reason" / "TODO reason"
    skip: bool = False
    todo: bool = False
    diagnostics: List[str] = field(default_factory=list)


@dataclass
class TapReport:
    plan_start: Optional[int] = None
    plan_end: Optional[int] = None
    plan_skip_reason: Optional[str] = None
    tests: List[TestResult] = field(default_factory=list)
    bail_out: Optional[str] = None

    @property
    def planned(self) -> int:
        if self.plan_start is None or self.plan_end is None:
            return 0
        return self.plan_end - self.plan_start + 1

    @property
    def total(self) -> int:
        return len(self.tests)

    @property
    def passed(self) -> int:
        return sum(1 for t in self.tests if t.passed and not t.skip)

    @property
    def failed_tests(self) -> List[TestResult]:
        # A SKIP'd test that says "not ok" is *not* a failure — TAP says SKIP
        # passes regardless. TODO failures are expected and don't count either.
        return [t for t in self.tests if not t.passed and not t.skip and not t.todo]

    @property
    def failed(self) -> int:
        return len(self.failed_tests)

    @property
    def skipped(self) -> int:
        return sum(1 for t in self.tests if t.skip)

    @property
    def todo_count(self) -> int:
        return sum(1 for t in self.tests if t.todo)

    @property
    def all_passed(self) -> bool:
        if self.bail_out is not None:
            return False
        if self.planned and self.total != self.planned:
            return False
        return self.failed == 0


def parse_tap(stream) -> TapReport:
    """Read TAP lines from `stream` and return a structured report."""
    report = TapReport()
    last_test: Optional[TestResult] = None

    for raw_line in stream:
        line = raw_line.rstrip("\n").rstrip("\r")
        if not line.strip():
            continue

        # Bail out — abort, nothing else matters.
        m_bail = RE_BAIL.match(line)
        if m_bail:
            report.bail_out = m_bail.group("reason").strip()
            break

        # Plan: "1..N" or "1..0 # SKIP reason"
        m_plan = RE_PLAN.match(line)
        if m_plan and report.plan_start is None:
            start, end, comment = m_plan.groups()
            report.plan_start = int(start)
            report.plan_end = int(end)
            if comment:
                report.plan_skip_reason = comment.strip()
            continue

        # Test result: "ok N - desc" / "not ok N - desc # SKIP/TODO ..."
        m_test = RE_TEST.match(line)
        if m_test and not m_test.group("indent"):
            # Top-level only — indented results are subtests, ignored for
            # the summary count (the wrapping non-indented ok/not-ok carries
            # the verdict).
            directive = m_test.group("directive")
            skip = bool(directive) and directive.upper().startswith("SKIP")
            todo = bool(directive) and directive.upper().startswith("TODO")
            t = TestResult(
                number=int(m_test.group("num")),
                passed=(m_test.group("status") == "ok"),
                description=(m_test.group("desc") or "").strip(),
                directive=directive.strip() if directive else None,
                skip=skip,
                todo=todo,
            )
            report.tests.append(t)
            last_test = t
            continue

        # Diagnostic: "# something" — attach to previous test.
        m_diag = RE_DIAG.match(line)
        if m_diag and last_test is not None:
            last_test.diagnostics.append(m_diag.group("text"))
            continue
        # Anything else is harmless noise (e.g. pg_prove headers); drop it.

    return report


def render_text(r: TapReport) -> str:
    out = []
    out.append("=" * 60)
    out.append("pgTAP / pg_prove summary")
    out.append("=" * 60)

    if r.bail_out is not None:
        out.append(f"BAIL OUT: {r.bail_out}")
        return "\n".join(out)

    if r.plan_start is None:
        out.append("WARNING: no plan line ('1..N') found — output may be incomplete.")
    else:
        out.append(f"Plan:    {r.plan_start}..{r.plan_end}  (planned {r.planned})")

    out.append(f"Total:   {r.total}")
    out.append(f"Passed:  {r.passed}")
    out.append(f"Failed:  {r.failed}")
    if r.skipped:
        out.append(f"Skipped: {r.skipped}")
    if r.todo_count:
        out.append(f"TODO:    {r.todo_count}")

    if r.planned and r.total != r.planned:
        out.append(
            f"⚠️  Plan mismatch: planned {r.planned}, ran {r.total}"
        )

    if r.failed_tests:
        out.append("")
        out.append("Failures:")
        out.append("-" * 60)
        for t in r.failed_tests:
            label = t.description or "(no description)"
            out.append(f"  ✗ #{t.number}: {label}")
            for d in t.diagnostics:
                out.append(f"      {d}")

    out.append("")
    out.append("Result: " + ("PASS ✅" if r.all_passed else "FAIL ❌"))
    return "\n".join(out)


def render_json(r: TapReport) -> str:
    payload = {
        "plan": {
            "start": r.plan_start,
            "end": r.plan_end,
            "planned": r.planned,
            "skip_reason": r.plan_skip_reason,
        },
        "summary": {
            "total": r.total,
            "passed": r.passed,
            "failed": r.failed,
            "skipped": r.skipped,
            "todo": r.todo_count,
            "all_passed": r.all_passed,
        },
        "bail_out": r.bail_out,
        "tests": [asdict(t) for t in r.tests],
    }
    return json.dumps(payload, indent=2)


def main():
    p = argparse.ArgumentParser(
        description="Parse pg_prove (TAP) output into a summary or JSON.",
    )
    p.add_argument(
        "--input", "-i",
        help="Read TAP from this file. Default: stdin.",
    )
    p.add_argument(
        "--json", action="store_true",
        help="Emit machine-readable JSON instead of text summary.",
    )
    p.add_argument(
        "--fail-on-error", action="store_true",
        help="Exit non-zero if any test failed or plan mismatched.",
    )
    args = p.parse_args()

    if args.input:
        with open(args.input, "r", encoding="utf-8", errors="replace") as f:
            report = parse_tap(f)
    else:
        report = parse_tap(sys.stdin)

    if report.plan_start is None and not report.tests and report.bail_out is None:
        sys.stderr.write("ERROR: no TAP content recognized on input.\n")
        sys.exit(2)

    print(render_json(report) if args.json else render_text(report))

    if args.fail_on_error and not report.all_passed:
        sys.exit(1)


if __name__ == "__main__":
    main()
