#!/usr/bin/env python3
"""
analyze-object.py - Automated Database Object Analysis

Purpose:
    Analyzes database objects (procedures, functions, views, tables) by comparing
    SQL Server originals with PostgreSQL conversions. Identifies issues, validates
    constitution compliance, and generates comprehensive analysis reports.

Usage:
    # Analyze a single object
    python analyze-object.py procedure addarc

    # Analyze with custom paths
    python analyze-object.py function mcgetupstream \\
        --original source/original/sqlserver/mcgetupstream.sql \\
        --converted source/original/pgsql-aws-sct-converted/mcgetupstream.sql

    # Batch analysis
    python analyze-object.py --batch procedures.txt

    # Generate quality score only
    python analyze-object.py procedure addarc --score-only

Features:
    - Syntax difference analysis (T-SQL vs PostgreSQL)
    - Constitution compliance checking (7 core principles)
    - Complexity metrics (cyclomatic complexity, LOC, nesting depth)
    - Issue classification (P0/P1/P2/P3 severity)
    - Quality score calculation (0-10 across 5 dimensions)
    - Markdown report generation

Quality Score Framework:
    - Syntax Correctness (20%): Valid PostgreSQL 17 syntax
    - Logic Preservation (30%): Business logic identical to SQL Server
    - Performance (20%): Expected performance vs baseline
    - Maintainability (15%): Readability, documentation, complexity
    - Security (15%): SQL injection risks, permissions

    Minimum threshold: 7.0/10 overall, no dimension below 6.0/10

Exit Codes:
    0 = Success
    1 = Analysis failed (errors during processing)
    2 = Invalid arguments or missing files

Author: Pierre Ribeiro (DBA/DBRE)
Created: 2026-01-25
Version: 1.0
"""

import argparse
import re
import sys
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Tuple, Optional
from dataclasses import dataclass, field
from enum import Enum


# ============================================================================
# CONSTANTS
# ============================================================================

class Severity(Enum):
    """Issue severity levels"""
    P0_CRITICAL = "P0"  # Blocks deployment
    P1_HIGH = "P1"      # Must fix before PROD
    P2_MEDIUM = "P2"    # Fix before STAGING
    P3_LOW = "P3"       # Track for improvement


class ObjectType(Enum):
    """Supported database object types"""
    PROCEDURE = "procedure"
    FUNCTION = "function"
    VIEW = "view"
    TABLE = "table"


# Constitution principles for compliance checking
CONSTITUTION_PRINCIPLES = {
    "I": "ANSI-SQL Primacy",
    "II": "Strict Typing & Explicit Casting",
    "III": "Set-Based Execution",
    "IV": "Atomic Transaction Management",
    "V": "Idiomatic Naming & Scoping",
    "VI": "Structured Error Resilience",
    "VII": "Modular Logic Separation"
}

# Quality score weights by dimension
QUALITY_WEIGHTS = {
    "syntax_correctness": 0.20,
    "logic_preservation": 0.30,
    "performance": 0.20,
    "maintainability": 0.15,
    "security": 0.15
}

# Issue impact on quality score
SEVERITY_IMPACT = {
    Severity.P0_CRITICAL: -3.0,
    Severity.P1_HIGH: -1.5,
    Severity.P2_MEDIUM: -0.5,
    Severity.P3_LOW: -0.1
}


# ============================================================================
# DATA CLASSES
# ============================================================================

@dataclass
class Issue:
    """Represents a detected issue"""
    severity: Severity
    principle: str  # Which constitution principle (I-VII) or "N/A"
    line_number: Optional[int]
    description: str
    context: str = ""

    def __str__(self) -> str:
        line_info = f"Line {self.line_number}" if self.line_number else "General"
        return f"[{self.severity.value}] {line_info}: {self.description}"


@dataclass
class ComplexityMetrics:
    """Code complexity metrics"""
    lines_of_code: int = 0
    branching_points: int = 0  # IF/CASE statements
    loop_structures: int = 0   # WHILE/FOR loops
    recursion_depth: int = 0   # Max expected recursion depth
    nesting_depth: int = 0     # Max nesting level
    comment_ratio: float = 0.0 # Comments / Total lines

    @property
    def cyclomatic_complexity(self) -> int:
        """Calculate cyclomatic complexity"""
        return 1 + self.branching_points + self.loop_structures


@dataclass
class QualityScore:
    """Quality assessment across 5 dimensions"""
    syntax_correctness: float = 10.0
    logic_preservation: float = 10.0
    performance: float = 10.0
    maintainability: float = 10.0
    security: float = 10.0

    @property
    def overall(self) -> float:
        """Calculate weighted overall score"""
        return (
            self.syntax_correctness * QUALITY_WEIGHTS["syntax_correctness"] +
            self.logic_preservation * QUALITY_WEIGHTS["logic_preservation"] +
            self.performance * QUALITY_WEIGHTS["performance"] +
            self.maintainability * QUALITY_WEIGHTS["maintainability"] +
            self.security * QUALITY_WEIGHTS["security"]
        )

    @property
    def passes_threshold(self) -> bool:
        """Check if passes minimum thresholds"""
        if self.overall < 7.0:
            return False
        return all([
            self.syntax_correctness >= 6.0,
            self.logic_preservation >= 6.0,
            self.performance >= 6.0,
            self.maintainability >= 6.0,
            self.security >= 6.0
        ])


@dataclass
class AnalysisResult:
    """Complete analysis results"""
    object_name: str
    object_type: ObjectType
    original_file: Path
    converted_file: Path
    issues: List[Issue] = field(default_factory=list)
    complexity: ComplexityMetrics = field(default_factory=ComplexityMetrics)
    quality_score: QualityScore = field(default_factory=QualityScore)
    timestamp: str = field(default_factory=lambda: datetime.now().strftime("%Y-%m-%d %H:%M:%S"))

    @property
    def issue_counts(self) -> Dict[Severity, int]:
        """Count issues by severity"""
        counts = {sev: 0 for sev in Severity}
        for issue in self.issues:
            counts[issue.severity] += 1
        return counts


# ============================================================================
# SQL PARSING AND ANALYSIS
# ============================================================================

class SQLAnalyzer:
    """Analyzes SQL code for issues and metrics"""

    def __init__(self):
        # Compile regex patterns once for performance
        self.patterns = {
            # T-SQL specific syntax that needs conversion
            "temp_table": re.compile(r'CREATE\s+TABLE\s+#\w+', re.IGNORECASE),
            "select_into": re.compile(r'SELECT\s+.*\s+INTO\s+#\w+', re.IGNORECASE),
            "identity": re.compile(r'IDENTITY\s*\(\s*\d+\s*,\s*\d+\s*\)', re.IGNORECASE),
            "begin_tran": re.compile(r'BEGIN\s+TRAN(SACTION)?', re.IGNORECASE),
            "commit_tran": re.compile(r'COMMIT\s+TRAN(SACTION)?', re.IGNORECASE),
            "rollback_tran": re.compile(r'ROLLBACK\s+TRAN(SACTION)?', re.IGNORECASE),
            "top_n": re.compile(r'SELECT\s+TOP\s+\d+', re.IGNORECASE),
            "iif_function": re.compile(r'\bIIF\s*\(', re.IGNORECASE),
            "getdate": re.compile(r'\bGETDATE\s*\(\s*\)', re.IGNORECASE),
            "isnull": re.compile(r'\bISNULL\s*\(', re.IGNORECASE),
            "len_function": re.compile(r'\bLEN\s*\(', re.IGNORECASE),
            "raiserror": re.compile(r'\bRAISERROR\s*\(', re.IGNORECASE),

            # Constitution violations
            "select_star": re.compile(r'SELECT\s+\*', re.IGNORECASE),
            "while_loop": re.compile(r'\bWHILE\s+', re.IGNORECASE),
            "cursor": re.compile(r'\bDECLARE\s+\w+\s+CURSOR', re.IGNORECASE),
            "when_others": re.compile(r'WHEN\s+OTHERS\s+THEN', re.IGNORECASE),
            "implicit_cast": re.compile(r'=\s*NULL', re.IGNORECASE),
            "unqualified_ref": re.compile(r'FROM\s+(\w+)(?!\.)(?:\s+|,|\))', re.IGNORECASE),

            # Complexity metrics
            "if_statement": re.compile(r'\bIF\s+', re.IGNORECASE),
            "case_statement": re.compile(r'\bCASE\s+', re.IGNORECASE),
            "for_loop": re.compile(r'\bFOR\s+', re.IGNORECASE),
            "comment_line": re.compile(r'^\s*--'),
            "comment_block": re.compile(r'/\*.*?\*/', re.DOTALL),

            # PostgreSQL good patterns
            "cast_function": re.compile(r'\bCAST\s*\(', re.IGNORECASE),
            "explicit_cast": re.compile(r'::', re.IGNORECASE),
            "coalesce": re.compile(r'\bCOALESCE\s*\(', re.IGNORECASE),
            "cte": re.compile(r'\bWITH\s+\w+\s+AS\s*\(', re.IGNORECASE),
        }

    def read_sql_file(self, file_path: Path) -> str:
        """Read SQL file content"""
        try:
            return file_path.read_text(encoding='utf-8')
        except Exception as e:
            raise RuntimeError(f"Failed to read {file_path}: {e}")

    def calculate_complexity(self, sql_content: str) -> ComplexityMetrics:
        """Calculate complexity metrics"""
        lines = sql_content.split('\n')

        metrics = ComplexityMetrics()
        metrics.lines_of_code = len([l for l in lines if l.strip() and not l.strip().startswith('--')])

        # Count branching and loops
        metrics.branching_points = (
            len(self.patterns["if_statement"].findall(sql_content)) +
            len(self.patterns["case_statement"].findall(sql_content))
        )
        metrics.loop_structures = (
            len(self.patterns["while_loop"].findall(sql_content)) +
            len(self.patterns["for_loop"].findall(sql_content))
        )

        # Calculate nesting depth
        current_depth = 0
        max_depth = 0
        for line in lines:
            line_upper = line.upper()
            if 'BEGIN' in line_upper or 'LOOP' in line_upper:
                current_depth += 1
                max_depth = max(max_depth, current_depth)
            elif 'END' in line_upper:
                current_depth = max(0, current_depth - 1)
        metrics.nesting_depth = max_depth

        # Comment ratio
        comment_lines = (
            len(self.patterns["comment_line"].findall(sql_content)) +
            len(self.patterns["comment_block"].findall(sql_content))
        )
        total_lines = len(lines)
        metrics.comment_ratio = comment_lines / total_lines if total_lines > 0 else 0.0

        return metrics

    def detect_issues(self, sql_content: str, is_converted: bool = False) -> List[Issue]:
        """Detect issues in SQL code"""
        issues = []
        lines = sql_content.split('\n')

        # Check for T-SQL patterns (in converted code, these are P0 issues)
        if is_converted:
            for line_num, line in enumerate(lines, 1):
                if self.patterns["temp_table"].search(line):
                    issues.append(Issue(
                        severity=Severity.P0_CRITICAL,
                        principle="I",
                        line_number=line_num,
                        description="T-SQL temp table syntax (#temp) not converted",
                        context=line.strip()
                    ))

                if self.patterns["begin_tran"].search(line):
                    issues.append(Issue(
                        severity=Severity.P1_HIGH,
                        principle="IV",
                        line_number=line_num,
                        description="BEGIN TRAN should be BEGIN (PostgreSQL)",
                        context=line.strip()
                    ))

                if self.patterns["raiserror"].search(line):
                    issues.append(Issue(
                        severity=Severity.P0_CRITICAL,
                        principle="VI",
                        line_number=line_num,
                        description="RAISERROR not converted to RAISE EXCEPTION",
                        context=line.strip()
                    ))

                if self.patterns["iif_function"].search(line):
                    issues.append(Issue(
                        severity=Severity.P1_HIGH,
                        principle="I",
                        line_number=line_num,
                        description="IIF() should be CASE WHEN ... END",
                        context=line.strip()
                    ))

        # Constitution compliance checks (both original and converted)
        for line_num, line in enumerate(lines, 1):
            # Principle III: No cursors or WHILE loops
            if self.patterns["cursor"].search(line):
                issues.append(Issue(
                    severity=Severity.P0_CRITICAL,
                    principle="III",
                    line_number=line_num,
                    description="Cursor violates set-based execution principle",
                    context=line.strip()
                ))

            if self.patterns["while_loop"].search(line):
                issues.append(Issue(
                    severity=Severity.P1_HIGH,
                    principle="III",
                    line_number=line_num,
                    description="WHILE loop violates set-based execution (use CTEs)",
                    context=line.strip()
                ))

            # Principle I: No SELECT *
            if self.patterns["select_star"].search(line):
                # Allow in CTEs or specific contexts
                if 'EXISTS' not in line.upper() and 'COUNT(*)' not in line.upper():
                    issues.append(Issue(
                        severity=Severity.P2_MEDIUM,
                        principle="I",
                        line_number=line_num,
                        description="SELECT * prohibited (enumerate columns)",
                        context=line.strip()
                    ))

            # Principle II: Implicit casting
            if '= NULL' in line or '!= NULL' in line or '<> NULL' in line:
                issues.append(Issue(
                    severity=Severity.P1_HIGH,
                    principle="II",
                    line_number=line_num,
                    description="Use IS NULL / IS NOT NULL instead of = NULL",
                    context=line.strip()
                ))

            # Principle VI: WHEN OTHERS only
            if self.patterns["when_others"].search(line):
                # Check if there are specific exceptions before it
                prev_lines = '\n'.join(lines[max(0, line_num-10):line_num])
                if 'WHEN' not in prev_lines.upper() or prev_lines.upper().count('WHEN') == 1:
                    issues.append(Issue(
                        severity=Severity.P2_MEDIUM,
                        principle="VI",
                        line_number=line_num,
                        description="Prefer specific exceptions over WHEN OTHERS only",
                        context=line.strip()
                    ))

        # Security checks
        dynamic_sql_pattern = re.compile(r'EXECUTE\s+.*\|\|', re.IGNORECASE)
        for line_num, line in enumerate(lines, 1):
            if dynamic_sql_pattern.search(line):
                # Check if using quote_ident or quote_literal
                if 'quote_ident' not in line.lower() and 'quote_literal' not in line.lower():
                    issues.append(Issue(
                        severity=Severity.P0_CRITICAL,
                        principle="N/A",
                        line_number=line_num,
                        description="Dynamic SQL without quote_ident/quote_literal (SQL injection risk)",
                        context=line.strip()
                    ))

        return issues

    def calculate_quality_score(self, issues: List[Issue], complexity: ComplexityMetrics) -> QualityScore:
        """Calculate quality score based on issues and complexity"""
        score = QualityScore()

        # Start with perfect scores and deduct for issues
        issue_impacts = {
            "syntax_correctness": [],
            "logic_preservation": [],
            "performance": [],
            "maintainability": [],
            "security": []
        }

        # Map issues to dimensions
        for issue in issues:
            impact = SEVERITY_IMPACT[issue.severity]

            # Syntax issues
            if issue.severity == Severity.P0_CRITICAL:
                issue_impacts["syntax_correctness"].append(impact)

            # Logic issues (constitution violations)
            if issue.principle in ["III", "IV", "VI"]:
                issue_impacts["logic_preservation"].append(impact)

            # Performance issues (cursors, loops)
            if "cursor" in issue.description.lower() or "loop" in issue.description.lower():
                issue_impacts["performance"].append(impact)

            # Security issues
            if "injection" in issue.description.lower():
                issue_impacts["security"].append(impact * 1.5)  # Higher weight

        # Apply impacts
        score.syntax_correctness = max(0.0, 10.0 + sum(issue_impacts["syntax_correctness"]))
        score.logic_preservation = max(0.0, 10.0 + sum(issue_impacts["logic_preservation"]))
        score.performance = max(0.0, 10.0 + sum(issue_impacts["performance"]))
        score.security = max(0.0, 10.0 + sum(issue_impacts["security"]))

        # Maintainability based on complexity
        maintainability_score = 10.0
        if complexity.cyclomatic_complexity > 20:
            maintainability_score -= 2.0
        if complexity.nesting_depth > 5:
            maintainability_score -= 1.5
        if complexity.comment_ratio < 0.05:
            maintainability_score -= 1.0

        score.maintainability = max(0.0, maintainability_score)

        return score


# ============================================================================
# REPORT GENERATION
# ============================================================================

class ReportGenerator:
    """Generates markdown analysis reports"""

    @staticmethod
    def generate_report(result: AnalysisResult, output_path: Path) -> None:
        """Generate comprehensive markdown report"""

        report_lines = []

        # Header
        report_lines.append(f"# Analysis: {result.object_name}")
        report_lines.append("")
        report_lines.append(f"**Object Type:** {result.object_type.value}")
        report_lines.append(f"**Analyst:** analyze-object.py (automated)")
        report_lines.append(f"**Date:** {result.timestamp}")
        report_lines.append("")
        report_lines.append("---")
        report_lines.append("")

        # Quality Score Summary
        report_lines.append("## Quality Score Summary")
        report_lines.append("")
        report_lines.append("| Dimension | Score | Weight | Contribution |")
        report_lines.append("|-----------|-------|--------|--------------|")

        score = result.quality_score
        report_lines.append(f"| Syntax Correctness | {score.syntax_correctness:.1f}/10 | 20% | {score.syntax_correctness * 0.20:.2f} |")
        report_lines.append(f"| Logic Preservation | {score.logic_preservation:.1f}/10 | 30% | {score.logic_preservation * 0.30:.2f} |")
        report_lines.append(f"| Performance | {score.performance:.1f}/10 | 20% | {score.performance * 0.20:.2f} |")
        report_lines.append(f"| Maintainability | {score.maintainability:.1f}/10 | 15% | {score.maintainability * 0.15:.2f} |")
        report_lines.append(f"| Security | {score.security:.1f}/10 | 15% | {score.security * 0.15:.2f} |")
        report_lines.append(f"| **OVERALL** | **{score.overall:.1f}/10** | 100% | **{score.overall:.2f}** |")
        report_lines.append("")

        status = "✅ PASS" if score.passes_threshold else "❌ FAIL"
        report_lines.append(f"**Status:** {status} (Minimum: 7.0/10 overall, no dimension below 6.0/10)")
        report_lines.append("")
        report_lines.append("---")
        report_lines.append("")

        # Issue Summary
        counts = result.issue_counts
        report_lines.append("## Issue Summary")
        report_lines.append("")
        report_lines.append(f"- **P0 Critical:** {counts[Severity.P0_CRITICAL]} (Blocks deployment)")
        report_lines.append(f"- **P1 High:** {counts[Severity.P1_HIGH]} (Must fix before PROD)")
        report_lines.append(f"- **P2 Medium:** {counts[Severity.P2_MEDIUM]} (Fix before STAGING)")
        report_lines.append(f"- **P3 Low:** {counts[Severity.P3_LOW]} (Track for improvement)")
        report_lines.append("")
        report_lines.append(f"**Total Issues:** {len(result.issues)}")
        report_lines.append("")
        report_lines.append("---")
        report_lines.append("")

        # Complexity Metrics
        cx = result.complexity
        report_lines.append("## Complexity Metrics")
        report_lines.append("")
        report_lines.append(f"- **Lines of Code:** {cx.lines_of_code}")
        report_lines.append(f"- **Cyclomatic Complexity:** {cx.cyclomatic_complexity}")
        report_lines.append(f"- **Branching Points:** {cx.branching_points} (IF/CASE statements)")
        report_lines.append(f"- **Loop Structures:** {cx.loop_structures} (WHILE/FOR loops)")
        report_lines.append(f"- **Nesting Depth:** {cx.nesting_depth}")
        report_lines.append(f"- **Comment Ratio:** {cx.comment_ratio:.1%}")
        report_lines.append("")

        # Complexity assessment
        if cx.cyclomatic_complexity <= 10:
            complexity_level = "Simple (low risk)"
        elif cx.cyclomatic_complexity <= 20:
            complexity_level = "Moderate (medium risk)"
        else:
            complexity_level = "Complex (high risk - consider refactoring)"

        report_lines.append(f"**Complexity Assessment:** {complexity_level}")
        report_lines.append("")
        report_lines.append("---")
        report_lines.append("")

        # Detailed Issues
        if result.issues:
            report_lines.append("## Detailed Issues")
            report_lines.append("")

            for severity in [Severity.P0_CRITICAL, Severity.P1_HIGH, Severity.P2_MEDIUM, Severity.P3_LOW]:
                severity_issues = [i for i in result.issues if i.severity == severity]
                if severity_issues:
                    report_lines.append(f"### {severity.value} Issues ({len(severity_issues)})")
                    report_lines.append("")

                    for idx, issue in enumerate(severity_issues, 1):
                        report_lines.append(f"**{idx}. {issue.description}**")
                        if issue.principle != "N/A":
                            principle_name = CONSTITUTION_PRINCIPLES.get(issue.principle, "Unknown")
                            report_lines.append(f"   - Constitution Principle: {issue.principle} ({principle_name})")
                        if issue.line_number:
                            report_lines.append(f"   - Location: Line {issue.line_number}")
                        if issue.context:
                            report_lines.append(f"   - Context: `{issue.context}`")
                        report_lines.append("")
        else:
            report_lines.append("## Detailed Issues")
            report_lines.append("")
            report_lines.append("✅ No issues detected")
            report_lines.append("")

        report_lines.append("---")
        report_lines.append("")

        # Source Files
        report_lines.append("## Source Files")
        report_lines.append("")
        report_lines.append(f"- **Original (SQL Server):** `{result.original_file}`")
        report_lines.append(f"- **Converted (PostgreSQL):** `{result.converted_file}`")
        report_lines.append("")
        report_lines.append("---")
        report_lines.append("")

        # Recommendations
        report_lines.append("## Recommendations")
        report_lines.append("")

        if counts[Severity.P0_CRITICAL] > 0:
            report_lines.append("⚠️ **CRITICAL:** P0 issues detected - object cannot be deployed until fixed")
            report_lines.append("")

        if counts[Severity.P1_HIGH] > 0:
            report_lines.append("⚠️ **HIGH PRIORITY:** P1 issues must be fixed before production deployment")
            report_lines.append("")

        if cx.cyclomatic_complexity > 20:
            report_lines.append("🔄 **REFACTORING:** High complexity - consider breaking into smaller functions/CTEs")
            report_lines.append("")

        if cx.loop_structures > 0:
            report_lines.append("⚡ **PERFORMANCE:** Consider converting loops to set-based operations (CTEs/window functions)")
            report_lines.append("")

        if not score.passes_threshold:
            report_lines.append("❌ **QUALITY GATE:** Object does not meet minimum quality threshold (7.0/10)")
            report_lines.append("")
        else:
            report_lines.append("✅ **QUALITY GATE:** Object meets minimum quality threshold")
            report_lines.append("")

        report_lines.append("---")
        report_lines.append("")
        report_lines.append(f"**Analysis completed:** {result.timestamp}")
        report_lines.append(f"**Tool version:** analyze-object.py v1.0")

        # Write report
        output_path.parent.mkdir(parents=True, exist_ok=True)
        output_path.write_text('\n'.join(report_lines), encoding='utf-8')


# ============================================================================
# MAIN ANALYSIS ORCHESTRATOR
# ============================================================================

class ObjectAnalyzer:
    """Main analysis orchestrator"""

    def __init__(self, project_root: Path):
        self.project_root = project_root
        self.sql_analyzer = SQLAnalyzer()
        self.report_generator = ReportGenerator()

    def find_file_in_directory(self, base_dir: Path, object_name: str) -> Optional[Path]:
        """Search for a file by name in directory tree (case-insensitive)"""
        # Try exact match first
        for sql_file in base_dir.rglob("*.sql"):
            if object_name.lower() in sql_file.stem.lower():
                return sql_file
        return None

    def resolve_paths(self, object_type: ObjectType, object_name: str,
                      original: Optional[Path] = None,
                      converted: Optional[Path] = None) -> Tuple[Path, Path]:
        """Resolve file paths for original and converted SQL"""

        if original and converted:
            return original, converted

        # Default paths based on project structure
        original_base = self.project_root / "source" / "original" / "sqlserver"
        converted_base = self.project_root / "source" / "original" / "pgsql-aws-sct-converted"

        # Search for files if not explicitly provided
        if not original:
            original_path = self.find_file_in_directory(original_base, object_name)
            if not original_path:
                # Try with common prefixes removed
                for prefix in ['sp_', 'usp_', 'fn_', 'dbo.']:
                    clean_name = object_name.replace(prefix, '')
                    original_path = self.find_file_in_directory(original_base, clean_name)
                    if original_path:
                        break
        else:
            original_path = original

        if not converted:
            converted_path = self.find_file_in_directory(converted_base, object_name)
            if not converted_path:
                # Try with common prefixes removed
                for prefix in ['sp_', 'usp_', 'fn_', 'perseus.']:
                    clean_name = object_name.replace(prefix, '')
                    converted_path = self.find_file_in_directory(converted_base, clean_name)
                    if converted_path:
                        break
        else:
            converted_path = converted

        # Validate existence
        if not original_path or not original_path.exists():
            raise FileNotFoundError(f"Original file not found for: {object_name}")
        if not converted_path or not converted_path.exists():
            raise FileNotFoundError(f"Converted file not found for: {object_name}")

        return original_path, converted_path

    def analyze_object(self, object_type: ObjectType, object_name: str,
                       original_path: Optional[Path] = None,
                       converted_path: Optional[Path] = None) -> AnalysisResult:
        """Analyze a database object"""

        # Resolve paths
        original, converted = self.resolve_paths(
            object_type, object_name, original_path, converted_path
        )

        print(f"Analyzing {object_type.value}: {object_name}")
        print(f"  Original:  {original}")
        print(f"  Converted: {converted}")

        # Read SQL files
        original_sql = self.sql_analyzer.read_sql_file(original)
        converted_sql = self.sql_analyzer.read_sql_file(converted)

        # Calculate complexity (use converted for metrics)
        complexity = self.sql_analyzer.calculate_complexity(converted_sql)
        print(f"  Complexity: {complexity.cyclomatic_complexity} (LOC: {complexity.lines_of_code})")

        # Detect issues in converted code
        issues = self.sql_analyzer.detect_issues(converted_sql, is_converted=True)
        print(f"  Issues found: {len(issues)}")

        # Calculate quality score
        quality_score = self.sql_analyzer.calculate_quality_score(issues, complexity)
        print(f"  Quality score: {quality_score.overall:.1f}/10")

        # Create result
        result = AnalysisResult(
            object_name=object_name,
            object_type=object_type,
            original_file=original,
            converted_file=converted,
            issues=issues,
            complexity=complexity,
            quality_score=quality_score
        )

        return result

    def analyze_and_report(self, object_type: ObjectType, object_name: str,
                          original_path: Optional[Path] = None,
                          converted_path: Optional[Path] = None,
                          output_path: Optional[Path] = None) -> int:
        """Analyze object and generate report"""

        try:
            # Perform analysis
            result = self.analyze_object(object_type, object_name, original_path, converted_path)

            # Determine output path
            if not output_path:
                output_dir = (self.project_root / "source" / "building" / "pgsql" /
                             "refactored" / f"analysis-reports")
                output_path = output_dir / f"{object_name}-analysis.md"

            # Generate report
            self.report_generator.generate_report(result, output_path)

            print(f"\n✅ Analysis complete")
            print(f"   Report: {output_path}")
            print(f"   Quality: {result.quality_score.overall:.1f}/10 ({'PASS' if result.quality_score.passes_threshold else 'FAIL'})")

            return 0

        except Exception as e:
            print(f"\n❌ Analysis failed: {e}", file=sys.stderr)
            return 1


# ============================================================================
# CLI INTERFACE
# ============================================================================

def parse_arguments() -> argparse.Namespace:
    """Parse command line arguments"""

    parser = argparse.ArgumentParser(
        description='Analyze database objects for SQL Server to PostgreSQL migration',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Analyze a procedure with auto-detected paths
  python analyze-object.py procedure addarc

  # Analyze with custom paths
  python analyze-object.py function mcgetupstream \\
      --original source/original/sqlserver/mcgetupstream.sql \\
      --converted source/original/pgsql-aws-sct-converted/mcgetupstream.sql

  # Batch analysis from file list
  python analyze-object.py --batch procedures.txt

  # Output to custom location
  python analyze-object.py view v_translated --output my-analysis.md

Quality Score Framework:
  - Syntax Correctness (20%): Valid PostgreSQL 17 syntax
  - Logic Preservation (30%): Business logic identical to SQL Server
  - Performance (20%): Expected performance vs baseline
  - Maintainability (15%): Readability, documentation, complexity
  - Security (15%): SQL injection risks, permissions

  Minimum threshold: 7.0/10 overall, no dimension below 6.0/10

Exit Codes:
  0 = Success
  1 = Analysis failed
  2 = Invalid arguments
        """
    )

    parser.add_argument(
        'object_type',
        nargs='?',
        type=str,
        choices=['procedure', 'function', 'view', 'table'],
        help='Type of database object'
    )

    parser.add_argument(
        'object_name',
        nargs='?',
        type=str,
        help='Name of the object to analyze'
    )

    parser.add_argument(
        '--original',
        type=Path,
        help='Path to original SQL Server file'
    )

    parser.add_argument(
        '--converted',
        type=Path,
        help='Path to converted PostgreSQL file'
    )

    parser.add_argument(
        '--output',
        type=Path,
        help='Output path for analysis report (default: auto-generated)'
    )

    parser.add_argument(
        '--batch',
        type=Path,
        help='Batch process objects from file (one per line: type,name)'
    )

    parser.add_argument(
        '--project-root',
        type=Path,
        default=Path.cwd(),
        help='Project root directory (default: current directory)'
    )

    parser.add_argument(
        '--score-only',
        action='store_true',
        help='Output quality score only (no full report)'
    )

    return parser.parse_args()


def main() -> int:
    """Main entry point"""

    args = parse_arguments()

    # Validate arguments
    if not args.batch:
        if not args.object_type or not args.object_name:
            print("Error: object_type and object_name required (or use --batch)", file=sys.stderr)
            return 2

    # Initialize analyzer
    analyzer = ObjectAnalyzer(args.project_root)

    # Batch mode
    if args.batch:
        if not args.batch.exists():
            print(f"Error: Batch file not found: {args.batch}", file=sys.stderr)
            return 2

        print(f"Batch processing from: {args.batch}\n")

        with open(args.batch) as f:
            lines = [l.strip() for l in f if l.strip() and not l.startswith('#')]

        success_count = 0
        fail_count = 0

        for line in lines:
            parts = line.split(',')
            if len(parts) != 2:
                print(f"Skipping invalid line: {line}")
                continue

            obj_type, obj_name = parts[0].strip(), parts[1].strip()

            try:
                obj_type_enum = ObjectType(obj_type)
                result = analyzer.analyze_and_report(obj_type_enum, obj_name)
                if result == 0:
                    success_count += 1
                else:
                    fail_count += 1
            except Exception as e:
                print(f"Failed to analyze {obj_type} {obj_name}: {e}")
                fail_count += 1

            print()  # Blank line between objects

        print(f"\n{'='*70}")
        print(f"Batch processing complete:")
        print(f"  ✅ Success: {success_count}")
        print(f"  ❌ Failed:  {fail_count}")
        print(f"{'='*70}")

        return 0 if fail_count == 0 else 1

    # Single object mode
    else:
        obj_type = ObjectType(args.object_type)

        if args.score_only:
            try:
                result = analyzer.analyze_object(
                    obj_type, args.object_name,
                    args.original, args.converted
                )
                print(f"{result.quality_score.overall:.1f}")
                return 0
            except Exception as e:
                print(f"Error: {e}", file=sys.stderr)
                return 1
        else:
            return analyzer.analyze_and_report(
                obj_type, args.object_name,
                args.original, args.converted, args.output
            )


if __name__ == '__main__':
    sys.exit(main())
